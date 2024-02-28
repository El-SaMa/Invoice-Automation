*** Settings ***
Library           DatabaseLibrary
Library           OperatingSystem
Library           Collections
Library           String
Library           Total.py

*** Variables ***
${dbname}         rpa_db
${dbuser}         robocop
${dbpass}         RPA.Password
${dbhost}         localhost
${dbport}         3306
${header_csv}     InvoiceHeaderData.csv
${row_csv}        InvoiceRowData.csv

*** Keywords ***
Make Connection
    Connect To Database    pymysql    ${dbname}    ${dbuser}    ${dbpass}    ${dbhost}    ${dbport}

Close Connection
    Disconnect From Database

Clear Existing Data
    [Documentation]    Clear existing data from the database for testing purposes
    Make Connection
    ${delete_rows_query}=    Set Variable    DELETE FROM invoicerow
    Execute Sql String    ${delete_rows_query}
    ${delete_headers_query}=    Set Variable    DELETE FROM invoiceheader
    Execute Sql String    ${delete_headers_query}
    Close Connection

Read CSV File
    [Arguments]    ${filename}
    ${file_path}=    Get File    ${filename}
    @{lines}=    Split To Lines    ${file_path}
    [Return]    @{lines}

Is Reference Number Correct
    [Arguments]    ${refNumber}
    ${correct}=    Evaluate    len("${refNumber}") == 7 and "${refNumber}".isdigit()
    [Return]    ${correct}

Is IBAN Correct
    [Arguments]    ${iban}
    ${correct}=    Evaluate    "${iban}"[:2].isalpha() and "${iban}"[:2].isupper() and len("${iban}") == 22
    [Return]    ${correct}

Is Total Amount Valid
    [Arguments]    ${invoiceNumber}    ${headerTotal}
    ${calculatedTotal}=    Calculate Total Amount From Rows    ${invoiceNumber}
    ${isValid}=    Evaluate    ${calculatedTotal} == ${headerTotal}
    [Return]    ${isValid}

Calculate Total Amount From Rows
    [Arguments]    ${invoiceNumber}
    ${totalAmount}=    Set Variable    ${0}
    @{rows}=    Read CSV File    ${row_csv}
    FOR    ${row}    IN    @{rows}[1:]
        @{rowDetails}=    Split String    ${row}    ;
        ${rowAmount}=    Convert To Number    ${rowDetails[6]}
        Run Keyword If    '${rowDetails[7]}' == '${invoiceNumber}'
        ...    Evaluate    ${totalAmount} + ${rowAmount}
    END
    [Return]    ${totalAmount}

Insert Invoice Header To DB
    [Arguments]    ${header}    ${calculatedTotal}
    Make Connection
    @{headerDetails}=    Split String    ${header}    ;
    ${isRefCorrect}=    Is Reference Number Correct    ${headerDetails[2]}
    ${ibanValid}=    Is IBAN Correct    ${headerDetails[6]}
    ${headerTotal}=    Convert To Number    ${headerDetails[9]}  # Assuming this is the total amount in header
    ${amountValid}=    Is Total Amount Valid    ${headerDetails[0]}    ${headerTotal}
    ${comment}=    Set Variable If    ${amountValid}    All ok    Total amount mismatch: Expected=${headerTotal}, Calculated=${calculatedTotal}
    ${statusOfInvoice}=    Evaluate    0 if ${isRefCorrect} and ${ibanValid} and ${amountValid} else 1 if not ${isRefCorrect} else 2 if not ${ibanValid} else 3
    ${query}=    Catenate    SEPARATOR=    INSERT INTO invoiceheader (invoicenumber, companyname, referencenumber, invoicedate, duedate, companycode, bankaccountnumber, amountexclvat, vat, totalamount, comment) VALUES ('${headerDetails[0]}', '${headerDetails[1]}', '${headerDetails[2]}', '${headerDetails[3]}', '${headerDetails[4]}', '${headerDetails[5]}', '${headerDetails[6]}', ${headerDetails[7]}, ${headerDetails[8]}, ${headerDetails[9]}, '${comment}')
    Execute Sql String    ${query}
    Close Connection

Insert Invoice Rows To DB
    [Arguments]    @{rows}
    Make Connection
    FOR    ${row}    IN    @{rows}
        @{rowDetails}=    Split String    ${row}    ;
        ${query}=    Catenate    SEPARATOR=    INSERT INTO invoicerow (invoicenumber, rownumber, description, quantity, unit, unitprice, vatpercent, vat, total) VALUES ('${rowDetails[7]}', '${rowDetails[8]}', '${rowDetails[0]}', ${rowDetails[1]}, '${rowDetails[2]}', ${rowDetails[3]}, ${rowDetails[4]}, ${rowDetails[5]}, ${rowDetails[6]})
        Execute Sql String    ${query}
    END

*** Test Cases ***
Process Invoice Data
    Clear Existing Data
    ${headerLines}=    Read CSV File    ${header_csv}
    ${rows}=    Read CSV File    ${row_csv}
    FOR    ${header}    IN    @{headerLines}[1:]
        ${calculatedTotal}=    Calculate Total Amount From Rows    ${header[0]}
        Insert Invoice Header To DB    ${header}    ${calculatedTotal}
    END
    Insert Invoice Rows To DB    @{rows[1:]}
