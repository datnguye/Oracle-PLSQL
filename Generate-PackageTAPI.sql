/*
    BASE TABLE STRUCTURE
    + ID NUMBER(1) IDENTITY
    + CREATE_BY VARCHAR2(20)
    + CREATE_DATE TIMESTAMP(3)
    + UPDATE_BY VARCHAR2(20)
    + UPDATE_DATE TIMESTAMP(3)
    + VERSION NUMBER(10)
*/
SELECT  REPLACE(TEMPLATE,'{COLUMNS}', LISTAGG(COL_TYPE, CHR(10)) WITHIN GROUP (ORDER BY COLUMN_ID)) AS INTERFACES,
        REPLACE(TEMPLATE_INSERT,'{COLUMNS}', LISTAGG(COL, CHR(10)) WITHIN GROUP (ORDER BY COLUMN_ID)) AS INSERTS,
        REPLACE(TEMPLATE_UPDATE,'{COLUMNS}', LISTAGG(COL, CHR(10)) WITHIN GROUP (ORDER BY COLUMN_ID)) AS UPDATES,
        TEMPLATE_DELETE as DELETES,
        TEMPLATE_IMPLEMENT as IMPLEMENTS,
        REPLACE(REPLACE(REPLACE(
            TEMPLATE_IMPLEMENT_INSERT,'{COLUMNS}', LISTAGG(COL, CHR(10)) WITHIN GROUP (ORDER BY COLUMN_ID)),
                                      '{COLUMNS_LIST}', LISTAGG(COL_LIST, CHR(10)) WITHIN GROUP (ORDER BY COLUMN_ID)),
                                      '{PCOLUMNS_LIST}', LISTAGG(PCOL_LIST, CHR(10)) WITHIN GROUP (ORDER BY COLUMN_ID)) AS IMPLEMENT_INSERTS,
        REPLACE(REPLACE(
            TEMPLATE_IMPLEMENT_UPDATE,'{COLUMNS}', LISTAGG(COL, CHR(10)) WITHIN GROUP (ORDER BY COLUMN_ID)),
                                      '{COLUMNS_PCOLUMNS_LIST}', LISTAGG(COL_PCOL_LIST, CHR(10)) WITHIN GROUP (ORDER BY COLUMN_ID)) AS IMPLEMENT_UPDATES,
        TEMPLATE_IMPLEMENT_DELETE as IMPLEMENT_DELETES
FROM 
(
SELECT 
TABLE_NAME,
COLUMN_NAME,
COLUMN_ID,
---------------------
--PACKAGE INTERFACE--
---------------------
REPLACE('CREATE OR REPLACE PACKAGE {TABLE_NAME}_TAPI
IS
TYPE {TABLE_NAME}_TAPI_REC IS RECORD (
    ID {TABLE_NAME}.ID%TYPE,
{COLUMNS}
);
TYPE {TABLE_NAME}_TAPI_TAB IS TABLE OF {TABLE_NAME}_TAPI_REC;
', '{TABLE_NAME}', TABLE_NAME) AS TEMPLATE,
REPLACE('-- INSERT
PROCEDURE INS (
    O_ID OUT {TABLE_NAME}.ID%TYPE,
{COLUMNS}
    P_CREATE_BY IN {TABLE_NAME}.CREATE_BY%TYPE
);', '{TABLE_NAME}',TABLE_NAME) AS TEMPLATE_INSERT,
REPLACE('-- UPDATE
PROCEDURE UPD (
    P_ID IN {TABLE_NAME}.ID%TYPE,
{COLUMNS}
    P_UPDATE_BY IN {TABLE_NAME}.UPDATE_BY%TYPE
);','{TABLE_NAME}', TABLE_NAME) AS TEMPLATE_UPDATE,
REPLACE('-- DELETE
PROCEDURE DEL (
    P_ID IN {TABLE_NAME}.ID%TYPE,
    P_DELETE_BY IN {TABLE_NAME}.UPDATE_BY%TYPE
);
END {TABLE_NAME}_TAPI;
/','{TABLE_NAME}', TABLE_NAME) AS TEMPLATE_DELETE,
--------------------------
--PACKAGE IMPLEMENTATION--
--------------------------
REPLACE('CREATE OR REPLACE PACKAGE BODY {TABLE_NAME}_TAPI
IS', '{TABLE_NAME}', TABLE_NAME) as TEMPLATE_IMPLEMENT,
REPLACE('-- INSERT
PROCEDURE INS (
    O_ID OUT {TABLE_NAME}.ID%TYPE,
{COLUMNS}
    P_CREATE_BY IN {TABLE_NAME}.CREATE_BY%TYPE
) IS
BEGIN
    INSERT 
    INTO 	{TABLE_NAME}(
{COLUMNS_LIST}
			CREATE_BY,
            UPDATE_BY
	)
    VALUES (
{PCOLUMNS_LIST}
			P_CREATE_BY,
            P_CREATE_BY
    )
    RETURNING ID INTO O_ID
;END;', '{TABLE_NAME}', TABLE_NAME) AS TEMPLATE_IMPLEMENT_INSERT,
REPLACE('-- UPDATE
PROCEDURE UPD (
    P_ID IN {TABLE_NAME}.ID%TYPE,
{COLUMNS}
    P_UPDATE_BY IN {TABLE_NAME}.UPDATE_BY%TYPE
) IS
BEGIN
    UPDATE  {TABLE_NAME} 
    SET     
{COLUMNS_PCOLUMNS_LIST}
            UPDATE_BY = P_UPDATE_BY,
            UPDATE_DATE = SYSTIMESTAMP
    WHERE   ID = P_ID;
END;', '{TABLE_NAME}', TABLE_NAME) AS TEMPLATE_IMPLEMENT_UPDATE,
REPLACE('-- DELETE
PROCEDURE DEL (
    P_ID IN {TABLE_NAME}.ID%TYPE,
    P_DELETE_BY IN {TABLE_NAME}.UPDATE_BY%TYPE
) IS
BEGIN
    UPDATE  {TABLE_NAME} 
    SET     IS_ACTIVE = 0,
            UPDATE_BY = P_DELETE_BY,
			UPDATE_DATE = SYSTIMESTAMP
    WHERE   ID = P_ID;
END;
END {TABLE_NAME}_TAPI;
/', '{TABLE_NAME}', TABLE_NAME) AS TEMPLATE_IMPLEMENT_DELETE,
----------
--OTHERS--
----------
REPLACE(REPLACE('    {COLUMN_NAME} {TABLE_NAME}.{COLUMN_NAME}%TYPE,','{TABLE_NAME}',TABLE_NAME),'{COLUMN_NAME}',COLUMN_NAME) AS COL_TYPE,
REPLACE(REPLACE(REPLACE('    P_{COLUMN_NAME} IN {TABLE_NAME}.{COLUMN_NAME}%TYPE{DFNULL},','{TABLE_NAME}',TABLE_NAME),'{COLUMN_NAME}',COLUMN_NAME),'{DFNULL}',CASE WHEN NULLABLE = 'Y' THEN ' DEFAULT NULL' ELSE '' END) AS COL,
REPLACE('			{COLUMN_NAME},','{COLUMN_NAME}',COLUMN_NAME) AS COL_LIST,
REPLACE('			P_{COLUMN_NAME},','{COLUMN_NAME}',COLUMN_NAME) AS PCOL_LIST,
REPLACE('			{COLUMN_NAME} = P_{COLUMN_NAME},','{COLUMN_NAME}',COLUMN_NAME) AS COL_PCOL_LIST

FROM    USER_TAB_COLS
WHERE   COLUMN_NAME NOT IN ('ID','UPDATE_DATE', 'CREATE_DATE','VERSION', 'UPDATE_BY', 'CREATE_BY')
)
GROUP BY    TEMPLATE, 
            TEMPLATE_INSERT, 
            TEMPLATE_UPDATE,
            TEMPLATE_DELETE,
            TEMPLATE_IMPLEMENT,
            TEMPLATE_IMPLEMENT_INSERT,
            TEMPLATE_IMPLEMENT_UPDATE,
            TEMPLATE_IMPLEMENT_DELETE;

