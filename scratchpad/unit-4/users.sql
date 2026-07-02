/* ****************************************************************************
**									                                         **
**	Script Name:  Create_CPRG307_Users.sql		                             **
**	Purpose:  Create two new user accounts (CPRG307, CPRG307a)               **
**									                                         **
***************************************************************************  */

ALTER SESSION SET "_ORACLE_SCRIPT"=TRUE;

CREATE USER cprg307a IDENTIFIED BY password
DEFAULT TABLESPACE users
QUOTA UNLIMITED ON users;

GRANT connect, resource, dba TO cprg307a;

CREATE USER cprg307 IDENTIFIED BY password
DEFAULT TABLESPACE users
QUOTA UNLIMITED ON users;

GRANT connect, resource, create sequence, create view TO cprg307;




