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

Insert Invoice Header To DB
    [Arguments]    ${header}
    Make Connection
    @{headerDetails}=    Split String    ${header}    ;
    ${isRefCorrect}=    Is Reference Number Correct    ${headerDetails[2]}
    ${ibanValid}=    Is IBAN Correct    ${headerDetails[6]}
    ${statusOfInvoice}=    Evaluate    0 if ${isRefCorrect} and ${ibanValid} else 1 if not ${isRefCorrect} else 2
    ${commentOfInvoice}=    Set Variable If    ${statusOfInvoice}==1    Reference number error    IBAN number error
    ${commentOfInvoice}=    Set Variable If    ${statusOfInvoice}==0    All ok    ${commentOfInvoice}
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
