CREATE OR REPLACE FUNCTION NEWGUID RETURN VARCHAR2 IS 
    P_VALUE VARCHAR2(36);
/*
PURPOSE
------------------------------------------------------------------------------------------------------
This is to return GUID

MODIFICATION HISTORY
------------------------------------------------------------------------------------------------------
Date		Author 		Description
2019-06-28	DN			Initial
*/
BEGIN
  SELECT 	REGEXP_REPLACE(SYS_GUID(), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')
  INTO 		P_VALUE
  FROM 		DUAL;
  
  RETURN P_VALUE;
END NEWGUID;