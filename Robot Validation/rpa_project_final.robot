*** Settings ***
Library           DatabaseLibrary
Library           OperatingSystem
Library           Collections
Library           String

*** Variables ***
${dbname}         rpa_db
${dbuser}         robocop
${dbpass}         RPA.Password
${dbhost}         localhost
${dbport}         3306
${HEADER_CSV}     InvoiceHeaderData.csv
${ROW_CSV}        InvoiceRowData.csv

*** Keywords ***
Make Connection
    Connect To Database    pymysql    ${dbname}    ${dbuser}    ${dbpass}    ${dbhost}    ${dbport}

Clear Existing Data
    [Documentation]    Clear existing data from the database for testing purposes
    Make Connection
    ${deleteRowsQuery}=    Set Variable    DELETE FROM invoicerow
    Execute Sql String    ${deleteRowsQuery}
    ${deleteHeadersQuery}=    Set Variable    DELETE FROM invoiceheader
    Execute Sql String    ${deleteHeadersQuery}

Read CSV File
    # Read the file and return the lines as a list
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

Calculate Total Amount From Rows
    [Arguments]    ${invoiceNumber}
    ${totalAmount}=    Set Variable    ${0}
    @{rows}=    Read CSV File    ${ROW_CSV}
    FOR    ${row}    IN    @{rows[1:]}
        @{rowDetails}=    Split String    ${row}    ;
        ${rowAmount}=    Convert To Number    ${rowDetails[6]}
        Run Keyword If    '${rowDetails[7]}' == '${invoiceNumber}'
        ...    Evaluate    ${totalAmount} + ${rowAmount}
        ...    ELSE    Set Variable    ${totalAmount}
    END
    [Return]    ${totalAmount}


Insert Invoice Header To DB
    [Arguments]    ${header}
    Make Connection
    @{headerDetails}=    Split String    ${header}    ;
    ${isRefCorrect}=    Is Reference Number Correct    ${headerDetails[2]}
    ${ibanValid}=    Is IBAN Correct    ${headerDetails[6]}
    ${headerTotal}=    Convert To Number    ${headerDetails[9]}  # Assuming this is the total amount in header
    ${calculatedTotal}=    Calculate Total Amount From Rows    ${headerDetails[0]}
    Run Keyword If    ${calculatedTotal} != ${headerTotal}
    ...    Log    Total amount mismatch for invoice ${headerDetails[0]}: Expected=${headerTotal}, Actual=${calculatedTotal}
    ...    ELSE    No Operation   


    ${amountMismatch}=    Evaluate    ${calculatedTotal} != ${headerTotal}

    ${statusOfInvoice}=    Evaluate    0 if ${isRefCorrect} and ${ibanValid} and not ${amountMismatch} else 1 if not ${isRefCorrect} else 2 if not ${ibanValid} else 3

    ${commentOfInvoice}=    Set Variable If    ${statusOfInvoice}==0    All ok
    ${commentOfInvoice}=    Set Variable If    ${statusOfInvoice}==1    Reference number error    ${commentOfInvoice}
    ${commentOfInvoice}=    Set Variable If    ${statusOfInvoice}==2    IBAN number error    ${commentOfInvoice}
    ${commentOfInvoice}=    Set Variable If    ${statusOfInvoice}==3    Total amount mismatch: Expected=${headerTotal}, Actual=${calculatedTotal}    ${commentOfInvoice}


    
    ${query}=    Catenate    SEPARATOR=    INSERT INTO invoiceheader (invoicenumber, companyname, referencenumber, invoicedate, duedate, companycode, bankaccountnumber, amountexclvat, vat, totalamount, comment) VALUES ('${headerDetails[0]}', '${headerDetails[1]}', '${headerDetails[2]}', '${headerDetails[3]}', '${headerDetails[4]}', '${headerDetails[5]}', '${headerDetails[6]}', ${headerDetails[7]}, ${headerDetails[8]}, ${headerDetails[9]}, '${commentOfInvoice}')
    Execute Sql String    ${query}

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
    ${headerLines}=    Read CSV File    ${HEADER_CSV}
    ${rowLines}=    Read CSV File    ${ROW_CSV}
    FOR    ${header}    IN    @{headerLines[1:]}
        Insert Invoice Header To DB    ${header}
    END
    Insert Invoice Rows To DB    @{rowLines[1:]}
