/* ****************************************************************************
**									                                         **
**	Script Name:  Drop_CPRG307_Users.sql		                             **
**	Purpose:  Remove two user accounts (CPRG307 and CPRG307a)                **
**									                                         **
***************************************************************************  */

ALTER SESSION SET "_ORACLE_SCRIPT"=TRUE;

DROP USER cprg307 CASCADE;
DROP USER cprg307a CASCADE;




