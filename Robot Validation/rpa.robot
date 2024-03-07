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
    # check if the first two characters are letters and the length is 22
    ${correct}=    Evaluate    "${iban}"[:2].isalpha() and "${iban}"[:2].isupper() and len("${iban}") == 22
    [Return]    ${correct}
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


Is Total Amount Valid
    [Arguments]    ${invoiceNumber}    ${headerTotal}
    ${calculatedTotal}=    Calculate Total Amount From Rows    ${invoiceNumber}
    ${isValid}=    Evaluate    float(${calculatedTotal}) == float(${headerTotal})
    [Return]    ${isValid}

Insert Invoice Header To DB
    [Arguments]    ${header}    ${calculatedTotal}
    Make Connection

    @{headerDetails}=    Split String    ${header}    ;
    Log    ${headerDetails}
    ${refResult}=    Is Reference Number Correct    ${headerDetails[2]}
    ${ibanResult}=    Check IBAN    ${headerDetails[6]}
    ${amountValid}=    Is Total Amount Valid    ${headerDetails[0]}    ${headerDetails[9]}
    ${statusOfInvoice}=    Set Variable    0

    # Initialize error counter
    ${errorCount}=    Set Variable    0
    ${comment}=       Set Variable    All ok

    # Check for reference number error
    IF    not ${refResult}
        ${errorCount}=    Evaluate    ${errorCount} + 1
        ${comment}=    Set Variable    Reference number error
        ${statusOfInvoice}=    Set Variable    1
    END

    # Check for IBAN error
    IF    not ${ibanResult}
        ${errorCount}=    Evaluate    ${errorCount} + 1
        ${comment}=    Set Variable If    ${errorCount} > 1    ${comment} + and IBAN number error    IBAN number error
        ${statusOfInvoice}=    Set Variable If    ${errorCount} == 1    2    ${statusOfInvoice}
    END

    # Check for total amount mismatch
    IF    not ${amountValid}
        ${errorCount}=    Evaluate    ${errorCount} + 1
        ${comment}=    Set Variable If    ${errorCount} > 1    ${comment} + and Total amount mismatch: Expected=${headerDetails[9]}, Calculated=${calculatedTotal}    Total amount mismatch: Expected=${headerDetails[9]}, Calculated=${calculatedTotal}
        # Set status to 3 if it is the first error, otherwise keep the previous status
        ${statusOfInvoice}=    Set Variable If    ${errorCount} == 1    3    ${statusOfInvoice}
    END

    # If multiple errors, update status and prepend comment with "Multiple errors"
    IF    ${errorCount} > 1
        ${statusOfInvoice}=    Set Variable    4
        ${comment}=    Set Variable    Multiple errors: ${comment}
    ELSE IF    ${errorCount} == 0
        ${statusOfInvoice}=    Set Variable    0
        ${comment}=    Set Variable    All ok
    END



    ${query}=    Catenate    SEPARATOR=    INSERT INTO invoiceheader (invoicenumber, companyname, referencenumber, invoicedate, duedate, companycode, bankaccountnumber, amountexclvat, vat, totalamount, comment, InvoiceStatus_id) VALUES ('${headerDetails[0]}', '${headerDetails[1]}', '${headerDetails[2]}', '${headerDetails[3]}', '${headerDetails[4]}', '${headerDetails[5]}', '${headerDetails[6]}', ${headerDetails[7]}, ${headerDetails[8]}, ${headerDetails[9]}, '${comment}', '${statusOfInvoice}')
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
Test Database Connection Close and Clean
    [Documentation]    Tests if the database connection can be closed and the data cleaned effectively.
    Make Connection
    Clear Existing Data
Process Invoice Data
    [Documentation]    Process invoice data by inserting header and row information into the database
    ${headerLines}=    Read CSV File    ${header_csv}
    ${rows}=    Read CSV File    ${row_csv}
    FOR    ${header}    IN    @{headerLines}[1:]
        ${calculatedTotal}=    Calculate Total Amount From Rows    ${header[0]}
        Insert Invoice Header To DB    ${header}    ${calculatedTotal}   # Pass calculatedTotal here
    END
    Insert Invoice Rows To DB    @{rows[1:]}
