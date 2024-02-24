*** Settings ***
Library           DatabaseLibrary

*** Variables ***
${dbname}        RPA_DB
${dbuser}        robocop
${dbpass}        RPA.Password
${dbhost}        localhost
${dbport}        3306

*** Keywords ***
Make Connection
    [Arguments]    ${dbname}
    Connect To Database    pymysql    ${dbname}    ${dbuser}    ${dbpass}    ${dbhost}    ${dbport}
    Log To Console    Database connection attempted.

*** Test Cases ***
Test Make Connection Keyword
    Make Connection    ${dbname}
    ${query_result}=    Query    SELECT VERSION()
    Log To Console    Query executed. Result: ${query_result}
    Disconnect From Database
