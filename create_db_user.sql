-- Luodaan käyttäjä
CREATE USER 'robotuser'@'localhost' IDENTIFIED BY 'password';

-- Luodaan rooli
create role robotrole;

-- Annetaan roolin oikeus käyttäjälle
grant robotrole to 'robotuser'@'localhost';

-- Asetetaan käyttäjälle oletuskena roolit käyttöön, kun kirjaudutaan
set default role all to 'robotuser'@'localhost';

-- Annetaan oikeudet roolille haluttuun tietokantaan
use rpakurssi;

grant select, insert, update on invoiceheader to robotrole;
grant select, insert, update on invoicerow to robotrole;
grant select on invoicestatus to robotrole;