*** Settings ***
Library    String
Library    Collections
Library    OperatingSystem
Library    DatabaseLibrary
Library    DateTime
Library    validate.py

*** Variables ***
# Global variables
@{ListToDB}
${InvoiceNumber}    empty
@{rows}    
@{headers}
${ListToDB}
${InvoiceNumber}
${innvoiceDate}

# database related variables
${dbname}    rpa_db
${dbuser}    robocop
${dbpass}    RPA.Password
${dbhost}    127.0.0.1
${dbport}    3306

*** Keywords ***
Add Row Data to List
    [Arguments]    ${items}
    @{AddInvoiceRowData}=    Create List
    Append To List    ${AddInvoiceRowData}    ${InvoiceNumber}
    Append To List    ${AddInvoiceRowData}    ${items}[8]
    Append To List    ${AddInvoiceRowData}    ${items}[0]
    Append To List    ${AddInvoiceRowData}    ${items}[1]
    Append To List    ${AddInvoiceRowData}    ${items}[2]
    Append To List    ${AddInvoiceRowData}    ${items}[3]
    Append To List    ${AddInvoiceRowData}    ${items}[4]
    Append To List    ${AddInvoiceRowData}    ${items}[5]
    Append To List    ${AddInvoiceRowData}    ${items}[6]
    Append To List    ${ListToDB}    ${AddInvoiceRowData}

Make Connection
    Connect To Database    pymysql    ${dbname}    ${dbuser}    ${dbpass}    ${dbhost}    ${dbport}

Add Invoice Header To DB
    [Arguments]    ${items}    ${rows}
    Make Connection    
    
    # 1) Convert dates to correct format
    ${innvoiceDate}=    Convert Date    ${items}[3]    date_format=%d.%m.%Y    result_format=%Y-%m-%d
    ${dueDate}=    Convert Date    ${items}[4]    date_format=%d.%m.%Y    result_format=%Y-%m-%d

    # 2) Validate reference number
    ${refResult}=    Is Ref Correct    ${items}[2]
    ${statusOfInvoice}=    Set Variable If    not ${refResult}    1    0
    ${commentOfInvoice}=    Set Variable If    not ${refResult}    "Reference number error"    "All ok"

    # 3) Validate IBAN
    ${ibanResult}=    Check IBAN    ${items}[6]
    ${statusOfInvoice}=    Set Variable If    not ${ibanResult}    2    ${statusOfInvoice}
    ${commentOfInvoice}=    Set Variable If    not ${ibanResult}    "IBAN number error"    ${commentOfInvoice}

    # 4) Validate total amount
    ${sumResult}=    Check Amounts From Invoice    ${items}[6]    ${rows}
    ${statusOfInvoice}=    Set Variable If    not ${sumResult}    3    ${statusOfInvoice}
    ${commentOfInvoice}=    Set Variable If    not ${sumResult}    "Amount difference"    ${commentOfInvoice}

    # Construct invoice header SQL statement
    ${insertHeaderStmt}=    Set Variable    INSERT INTO invoiceheader (invoicenumber, companyname, referencenumber, invoicedate, duedate, companycode, bankaccountnumber, amountexclvat, vat, totalamount, comment) VALUES (${items}[0], '${items}[1]', '${items}[2]', '${items}[3]', '${items}[4]', '${items}[5]', '${items}[6]', ${items}[7], ${items}[8], ${items}[6], '${commentOfInvoice}');
    
    Log    ${insertHeaderStmt}    # Log the SQL string before executing it

    # Execute the SQL statement and handle any errors
    ${result}=    Execute Sql String    ${insertHeaderStmt}
    Run Keyword If    '${result}' == 'FAIL'    Log    Error executing SQL: ${result}

Add Invoice Row To DB
    [Arguments]    ${items}
    Make Connection   # Connect to database
    # Construct invoice row SQL statement
    ${insertRowStmt}=    Set Variable    INSERT INTO invoicerow (invoicenumber, rownumber, description, quantity, unit, unitprice, vatpercent, vat, total) VALUES (${items}[7], ${items}[8], '${items}[0]', ${items}[1], '${items}[2]', ${items}[3], ${items}[4], ${items}[5], ${items}[6]);

    Log    ${insertRowStmt}    # Log the SQL string before executing it
    Execute Sql String    ${insertStmt}

*** Test Cases ***
Test Make Connection Keyword
    Make Connection  
    ${query_result}=    Query    SELECT VERSION()
    Log To Console    Query executed. Result: ${query_result}
    Disconnect From Database

Read CSV file to list
    # Read CSV files to variables
    ${outputHeader}=    Get File    InvoiceHeaderData.csv
    ${outputRows}=    Get File    InvoiceRowData.csv
    Log    ${outputHeader}
    Log    ${outputRows}

    #   Split CSV data to lists
    @{headers}=    Split String    ${outputHeader}    \n
    @{rows}=    Split String    ${outputRows}    \n
    
    #   Remove first and last element from lists
    ${length}=    Get Length    ${headers}
    ${length}=    Evaluate    ${length}-1
    ${index}=    Convert To Integer    0
    
    Remove From List    ${headers}    ${length}
    Remove From List    ${headers}    ${index}

    ${length}=    Get Length    ${rows}
    ${length}=    Evaluate    ${length}-1

    Remove From List    ${rows}    ${length}
    Remove From List    ${rows}    ${index}

Loop all invoicerows
    # Loop through all elements in row list
    FOR    ${element}    IN    @{rows}
        Log    ${element}
        
        # Read all different values as an element from CSV row to items-list
        @{items}=    Split String    ${element}    ;

        # Invoice number can be found from index 7
        ${rowInvoiceNumber}=    Set Variable    ${items}[7]

        Log    ${rowInvoiceNumber}
        Log    ${InvoiceNumber}
        # Check IF invoice number is same as previous row invoice number
        IF    '${rowInvoiceNumber}' == '${InvoiceNumber}'
            Log     add row to invoice
            # Add data to global list using own keyword
            #           0           1           2           3           4           5           6           7           8
            Add Row Data to List    ${items}

        ELSE
            #    check if there is rows to be written to list
            Log    check if there is rows to be written to list
            ${length}=    Get Length    ${ListToDB}
            IF    ${length} == ${0}
                Log    first invoice
                # update invoice number to be handled and set as global
                ${InvoiceNumber}=    Set Variable    ${rowInvoiceNumber}
                  

                # Add data to global list using own keyword
                Add Row Data to List    ${items}
            ELSE
                Log    invoice changing
                # If invoice is changing we need to find header data




                # loop through all elements in header list
                FOR    ${headerElement}    IN    @{headers}
                    ${headerItems}=    Split String    ${headerElement}    ;
                    IF    '${headerItems}[0]' == '${InvoiceNumber}'
                        Log    invoice found

                        

                        # Add header data to database using own keyword
                        Add Invoice Header To DB    ${headerItems}    ${ListToDB}

                        # Add row data to database using own keyword
                        FOR    ${rowElement}    IN    @{ListToDB}
                            Add Invoice Row To DB    ${rowElement}
                        END                
                    END
                    
                END            
               
                # Set process for new round
                @{ListToDB}    Create List
                ${InvoiceNumber}=    Set Variable    ${rowInvoiceNumber}   

                # Add data to global list using own keyword
                Add Row Data to List    ${items}
            END

        END

    END

    # Last invoice handling
    ${length}=    Get Length    ${ListToDB}
    IF    ${length} > ${0}
        Log    last invoice handling
        # Fins invoice header
        FOR    ${headerElement}    IN    @{headers}
            ${headerItems}=    Split String    ${headerElement}    ;
            IF    '${headerItems}[0]' == '${InvoiceNumber}'
                Log    invoice found

                # Add header data to database using own keyword
                Add Invoice Header To DB    ${headerItems}    ${ListToDB}

                # Add row data to database using own keyword
                FOR    ${rowElement}    IN    @{ListToDB}
                    Add Invoice Row To DB    ${rowElement}
                END                
            END
            
        END
    END
