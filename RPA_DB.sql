-- Create the RPA-DB database
CREATE DATABASE RPA_DB;

-- Switch to the RPA-DB database context
USE RPA_DB;

-- Create the InvoiceHeader table
CREATE TABLE  InvoiceHeader (
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

-- Create the InvoiceRow table
CREATE TABLE  InvoiceRow (
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

-- Create the invoicestatus table
CREATE TABLE  invoicestatus (
  id INT NOT NULL,
  status VARCHAR(100) NOT NULL,
  PRIMARY KEY (id)
);

-- Purpose: This file contains the initial data that is required for the application to work properly.
INSERT INTO invoicestatus (id, status) VALUES (0, 'All ok'); 
INSERT INTO invoicestatus (id, status) VALUES (1, 'ref error');
INSERT INTO invoicestatus (id, status) VALUES (2, 'iban error');
INSERT INTO invoicestatus (id, status) VALUES (3, 'amount error');

-- Create the robocop login
CREATE LOGIN robocop WITH PASSWORD = 'password';

-- Create a user for robocop in the RPA-DB database
CREATE USER robocop FOR LOGIN robocop WITH DEFAULT_SCHEMA = dbo;

-- Create the robotrole role
CREATE ROLE robotrole;

-- Assign the robotrole role to the robocop user
ALTER ROLE robotrole ADD MEMBER robocop;

-- Grant permissions to the robotrole role
GRANT SELECT, INSERT, UPDATE ON InvoiceHeader TO robotrole; 
GRANT SELECT, INSERT, UPDATE ON InvoiceRow TO robotrole;
GRANT SELECT ON invoicestatus TO robotrole;
