CREATE DATABASE IF NOT EXISTS rpa_db;

USE rpa_db;

CREATE TABLE IF NOT EXISTS InvoiceHeader (
    invoicenumber INT NOT NULL,
    companyname VARCHAR(100) NULL,
    companycode VARCHAR(45) NOT NULL,
    referencenumber VARCHAR(45) NOT NULL,
    invoicedate DATE NOT NULL,
    duedate DATE NOT NULL,
    bankaccountnumber VARCHAR(30) NOT NULL,
    amountexclvat DECIMAL(10,2) NOT NULL,
    vat DECIMAL(10,2) NOT NULL,
    totalamount DECIMAL(10,2) NOT NULL,
    comment VARCHAR(100),
    PRIMARY KEY (invoicenumber)
);

CREATE TABLE IF NOT EXISTS InvoiceRow (
    invoicenumber INT NOT NULL,
    rownumber INT NOT NULL,
    description VARCHAR(100) NOT NULL,
    quantity INT NULL,
    unit VARCHAR(45) NULL,
    unitprice DECIMAL(10,2) NULL,
    vatpercent DECIMAL(10,2) NOT NULL,
    vat DECIMAL(10,2) NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (invoicenumber, rownumber),
    CONSTRAINT fk_InvoiceRow_InvoiceHeader
        FOREIGN KEY (invoicenumber)
        REFERENCES InvoiceHeader (invoicenumber)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS invoicestatus (
    id INT NOT NULL,
    status VARCHAR(100) NOT NULL,
    PRIMARY KEY (id)
);

CREATE USER 'robocop'@'localhost' IDENTIFIED BY 'password';

GRANT ALL PRIVILEGES ON rpa_db.* TO 'robocop'@'localhost';

FLUSH PRIVILEGES;
