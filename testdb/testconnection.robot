*** Settings ***
Library    DatabaseLibrary

*** Variables ***
${dbname}    rpa_db
${dbuser}    robocop
${dbpass}    RPA.Password
${dbhost}    127.0.0.1
${dbport}    3306

*** Keywords ***
Make Connection
    [Documentation]    Establishes a database connection.
    Connect To Database    pymysql    ${dbname}    ${dbuser}    ${dbpass}    ${dbhost}    ${dbport}
    [Return]    ${TRUE}

Simple Insert Test
    [Documentation]    Performs a simple insert operation to test database connectivity and permissions.
    ${insertStmt}=    Set Variable    INSERT INTO invoiceheader (invoicenumber, companyname, companycode, referencenumber, invoicedate, duedate, bankaccountnumber, amountexclvat, vat, totalamount, comment) VALUES (1, 'Test Company', 'COMP123', 'REF123', '2024-01-01', '2024-02-01', 'ACC123456', 100.00, 20.00, 120.00, 'All good');
    Execute Sql String    ${insertStmt}
    [Return]    ${TRUE}

*** Test Cases ***
Test Database Insert
    Make Connection
    Simple Insert Test
    Disconnect From Database
