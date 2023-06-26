*** Settings ***
Documentation       Template robot main suite.

Library             RPA.Browser.Selenium    auto_close=${False}    implicit_wait=30 seconds
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive


*** Variables ***
${GLOBAL_RETRY_AMOUNT}=         3x
${GLOBAL_RETRY_INTERVAL}=       0.5s


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get Orders File
    FOR    ${row}    IN    @{orders}
        Log    Processing order ${row}[Order number]
        Close the annoying modal
        Fill the form    ${row}
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Wait Until Keyword Succeeds
        ...    ${GLOBAL_RETRY_AMOUNT}
        ...    ${GLOBAL_RETRY_INTERVAL}
        ...    Submit Robot Order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Click Button    id:order-another
    END
    Package the documents for sharing


*** Keywords ***
Open the robot order website
    Open Available Browser    url=https://robotsparebinindustries.com/#/robot-order

Get Orders File
    Download    url=https://robotsparebinindustries.com/orders.csv    overwrite=${True}
    ${order_table}=    Read table from CSV    path=orders.csv
    RETURN    ${order_table}

Close the annoying modal
    Click Button When Visible    locator=class:btn-danger

Fill the form
    [Arguments]    ${order}
    Select From List By Value    id:head    ${order}[Head]
    Select Radio Button    group_name=body    value=${order}[Body]
    Input Text    locator=xpath://input[@type="number"]    text=${order}[Legs]
    Input Text    locator=name:address    text=${order}[Address]

Take a screenshot of the robot
    [Arguments]    ${order_num}
    Click Button    locator=id:preview
    Screenshot    locator=id:robot-preview-image    filename=${OUTPUT_DIR}${/}${order_num}-robot-preview.png
    RETURN    ${OUTPUT_DIR}${/}${order_num}-robot-preview.png

Submit Robot Order
    Click Button    locator=id:order
    Page Should Contain Element    locator=id:receipt

Store the receipt as a PDF file
    [Arguments]    ${order_num}
    ${receipt_html}=    Get Element Attribute    locator=id:receipt    attribute=outerHTML
    Html To Pdf    content=${receipt_html}    output_path=${OUTPUT_DIR}${/}${order_num}-robot-receipt.pdf
    RETURN    ${OUTPUT_DIR}${/}${order_num}-robot-receipt.pdf

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${files}=    Create List    ${screenshot}
    Add Files To Pdf    files=${files}    target_document=${pdf}

Package the documents for sharing
    Archive Folder With Zip
    ...    folder=${OUTPUT_DIR}
    ...    archive_name=Robot Orders
    ...    recursive=${True}
    ...    include=*.pdf
