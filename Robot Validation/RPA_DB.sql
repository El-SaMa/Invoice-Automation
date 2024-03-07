-- Create the rpa_db database
CREATE DATABASE rpa_db;
USE rpa_db;

-- Create InvoiceStatus table with status ID and description
CREATE TABLE invoicestatus (
    id INT NOT NULL,
    status VARCHAR(100) NOT NULL,
    PRIMARY KEY (id)
);
-- Create InvoiceHeader table with an added InvoiceStatus_id column for status reference
CREATE TABLE InvoiceHeader (
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
    InvoiceStatus_id INT NOT NULL,
    PRIMARY KEY (invoicenumber),
    CONSTRAINT fk_InvoiceHeader_InvoiceStatus
        FOREIGN KEY (InvoiceStatus_id)
        REFERENCES invoicestatus(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);

-- Create InvoiceRow table with specified fields and foreign key to InvoiceHeader
CREATE TABLE InvoiceRow (
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
        REFERENCES InvoiceHeader(invoicenumber)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);
INSERT INTO invoicestatus(id, status)
VALUES
    (0, 'All ok'),
    (1, 'Reference number error'),
    (2, 'IBAN number error'),
    (3, 'Total amount mismatch'),
    (4, 'Multiple issues detected');

-- User and role configuration
-- Create the user 'robocop' with the specified password
CREATE USER IF NOT EXISTS 'robocop'@'localhost' IDENTIFIED BY 'RPA.Password';

-- Apply privileges to the user robocop
GRANT ALL PRIVILEGES ON rpa_db.* TO 'robocop'@'localhost';

-- Apply the changes
FLUSH PRIVILEGES;
