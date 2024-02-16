-- create db user
CREATE USER 'robotuser'@'localhost' IDENTIFIED BY 'password';

-- create role
create role robotrole;

-- grant role to user
grant robotrole to 'robotuser'@'localhost';

-- set default role
set default role all to 'robotuser'@'localhost';

use rpakurssi;

grant select, insert, update on invoiceheader to robotrole;
grant select, insert, update on invoicerow to robotrole;
grant select on invoicestatus to robotrole;