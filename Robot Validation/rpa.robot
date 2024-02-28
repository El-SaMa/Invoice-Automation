*** Settings ***
Library           DatabaseLibrary
Library           OperatingSystem
Library           Collections
Library           String
Library           total.py

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

Check IBAN
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
        ${rowAmount}=    Run Keyword If    '${rowDetails[7]}' == '${invoiceNumber}'
        ...    Convert To Number    ${rowDetails[6]}
        ...    ELSE    Set Variable    0
        ${totalAmount}=    Evaluate    ${totalAmount} + ${rowAmount}
    END
    [Return]    ${totalAmount}


Insert Invoice Header To DB
    [Arguments]    ${header}    ${calculatedTotal}
    Make Connection

    @{headerDetails}=    Split String    ${header}    ;
    ${refResult}=    Is Reference Number Correct    ${headerDetails[2]}
    ${ibanResult}=    Check IBAN    ${headerDetails[6]}
    ${amountValid}=    Is Total Amount Valid    ${headerDetails[0]}    ${headerDetails[9]}

    ${statusOfInvoice}=    Set Variable If    not ${refResult}    1    0
    ${statusOfInvoice}=    Set Variable If    not ${ibanResult}    2    ${statusOfInvoice}
    ${statusOfInvoice}=    Set Variable If    not ${amountValid}    3    ${statusOfInvoice}

    ${comment}=    Set Variable If    ${statusOfInvoice}==0    All ok
    ${comment}=    Set Variable If    ${statusOfInvoice}==1    Reference number error    ${comment}
    ${comment}=    Set Variable If    ${statusOfInvoice}==2    ${comment}, + IBAN number error    ${comment}
    ${comment}=    Set Variable If    ${statusOfInvoice}==3    ${comment}, + Total amount mismatch: Expected=${headerDetails[9]}, Calculated=${calculatedTotal}    ${comment}

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
    Close Connection

*** Test Cases ***
Process Invoice Data
    [Documentation]    Process invoice data by inserting header and row information into the database
    Clear Existing Data
    ${headerLines}=    Read CSV File    ${header_csv}
    ${rows}=    Read CSV File    ${row_csv}
    FOR    ${header}    IN    @{headerLines}[1:]
        ${calculatedTotal}=    Calculate Total Amount From Rows    ${header[0]}
        Insert Invoice Header To DB    ${header}    ${calculatedTotal}   # Pass calculatedTotal here
    END
    Insert Invoice Rows To DB    @{rows[1:]}
