--  - Uses MERGE so repeated runs do not attempt duplicate inserts.
--  - When to run: as LENDING after schema.sql and views_and_queries.sql.

--------------------------------------------------------------------------------
-- 1) Ensure the sample computer exists (PC-0722) using MERGE (idempotent)
--    This selects a MODEL_ID from COMPUTER_MODEL (seeded by schema.sql).
--    If the model row is not present the MERGE will not insert the computer.
--------------------------------------------------------------------------------
MERGE INTO COMPUTER tgt
USING (
  SELECT MODEL_ID AS model_id,
         'PC-0722'       AS computer_number,
         'OPTICAL'       AS mouse_type_code
  FROM COMPUTER_MODEL
  WHERE MODEL_NAME = 'Inspiron 9300' AND ROWNUM = 1
) src
ON (tgt.COMPUTER_NUMBER = src.computer_number)
WHEN NOT MATCHED THEN
  INSERT (MODEL_ID, COMPUTER_NUMBER, MOUSE_TYPE_CODE)
  VALUES (src.model_id, src.computer_number, src.mouse_type_code);

--------------------------------------------------------------------------------
-- 2) Ensure the sample student exists (S-1001) using MERGE (idempotent)
--    - Uses a subquery to find CLASS_ID for class '1A' from seeded STUDENT_CLASS.
--    - When matched we optionally update a few non-key columns so the sample stays current.
--------------------------------------------------------------------------------
MERGE INTO STUDENT tgt
USING (
  SELECT 'S-1001'            AS student_number,
         'Anna Hansen'       AS full_name,
         'Examplevej 12'     AS address_line,
         '2100'              AS postal_code,
         '010203-1234'       AS cpr_number,
         'anna@example.com'  AS email,
         (SELECT CLASS_ID FROM STUDENT_CLASS WHERE CLASS_CODE='1A' AND ROWNUM = 1) AS class_id
  FROM dual
) src
ON (tgt.STUDENT_NUMBER = src.student_number)
WHEN MATCHED THEN
  UPDATE SET
    tgt.FULL_NAME    = src.full_name,
    tgt.ADDRESS_LINE = src.address_line,
    tgt.POSTAL_CODE  = src.postal_code,
    tgt.CPR_NUMBER   = src.cpr_number,
    tgt.EMAIL        = src.email,
    tgt.CLASS_ID     = src.class_id
  WHERE (tgt.FULL_NAME    IS NULL OR tgt.FULL_NAME    <> src.full_name)
     OR (tgt.ADDRESS_LINE IS NULL OR tgt.ADDRESS_LINE <> src.address_line)
     OR (tgt.POSTAL_CODE  IS NULL OR tgt.POSTAL_CODE  <> src.postal_code)
     OR (tgt.CPR_NUMBER   IS NULL OR tgt.CPR_NUMBER   <> src.cpr_number)
     OR (tgt.EMAIL        IS NULL OR tgt.EMAIL        <> src.email)
     OR (tgt.CLASS_ID     IS NULL OR tgt.CLASS_ID     <> src.class_id)
WHEN NOT MATCHED THEN
  INSERT (STUDENT_NUMBER, FULL_NAME, ADDRESS_LINE, POSTAL_CODE, CPR_NUMBER, EMAIL, CLASS_ID)
  VALUES (src.student_number, src.full_name, src.address_line, src.postal_code, src.cpr_number, src.email, src.class_id);

COMMIT;

--------------------------------------------------------------------------------
-- 3) Ensure an ACTIVE loan exists for the sample pair only if no active loan exists
--    - The MERGE matches any existing active loan (RETURN_DATE IS NULL) for that computer.
--    - If no active loan exists, we insert a new LOAN row.
--    - This avoids ORA-00001 and avoids creating multiple active loans for the same computer.
--------------------------------------------------------------------------------
MERGE INTO LOAN tgt
USING (
  SELECT s.STUDENT_ID, c.COMPUTER_ID
  FROM STUDENT s
  JOIN COMPUTER c ON c.COMPUTER_NUMBER = 'PC-0722'
  WHERE s.STUDENT_NUMBER = 'S-1001'
) src
ON (tgt.COMPUTER_ID = src.COMPUTER_ID AND tgt.RETURN_DATE IS NULL)
WHEN NOT MATCHED THEN
  INSERT (STUDENT_ID, COMPUTER_ID, LOAN_DATE, DUE_DATE)
  VALUES (src.STUDENT_ID, src.COMPUTER_ID, TRUNC(SYSDATE), TRUNC(SYSDATE) + 14);

COMMIT;

--------------------------------------------------------------------------------
-- 4) Verification selects (inspect these interactively)
--------------------------------------------------------------------------------
-- Who currently has laptops
SELECT * FROM V_ACTIVE_LOANS;

-- Available computers (should not list PC-0722 if active loan exists)
SELECT * FROM V_AVAILABLE_COMPUTERS;

-- Loan history (shows ACTIVE/RETURNED)
SELECT * FROM V_LOAN_HISTORY ORDER BY LOAN_DATE DESC;

SELECT user, sys_context('USERENV','CON_NAME') FROM dual;

