-- Run as SYS with role SYSDBA, connected to PDB (XEPDB1).
-- If needed: ALTER SESSION SET CONTAINER = XEPDB1;
-- Purpose: create the LENDING schema (Oracle user) and grant required privileges.

-- Creates a schema named LENDING. In Oracle, a user is a schema; all tables created by LENDING will belong to this user.
CREATE USER LENDING IDENTIFIED BY "12345"
  DEFAULT TABLESPACE USERS
  QUOTA UNLIMITED ON USERS;

-- Grant the privileges needed by the LENDING account
GRANT CREATE SESSION, CREATE TABLE, CREATE SEQUENCE, CREATE VIEW, CREATE TRIGGER TO LENDING;
--  CREATE SESSION: allows the user to connect (log in).
--  CREATE TABLE / SEQUENCE / VIEW / TRIGGER: needed to create the schema objects in schema.sql.
--  Optionally grant CREATE PROCEDURE if you plan to add PL/SQL procedures.

-- Verify (optional):
-- SELECT USERNAME, ACCOUNT_STATUS FROM DBA_USERS WHERE USERNAME='LENDING';