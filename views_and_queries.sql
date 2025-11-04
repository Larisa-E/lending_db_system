-- rovide ready-to-use read-only layers (views) for the assignment requirements
-- When to run: as LENDING after schema.sql has created the LOAN, STUDENT, COMPUTER, COMPUTER_MODEL and BRAND tables.

--------------------------------------------------------------------------------
-- V_ACTIVE_LOANS
-- list all currently active loans (not yet returned).
-- Explanation of logic:
--  - FROM LOAN l: core loan rows.
--  - JOIN STUDENT s: fetch student details (number, name, email).
--  - JOIN COMPUTER c -> COMPUTER_MODEL m -> BRAND b: fetch computer number, model and brand for friendly display.
--  - WHERE l.RETURN_DATE IS NULL: only active loans (no return recorded).
-- Typical use:
--  - Show "who has which laptop right now" and the due date.
--  - Base for overdue reminders and for filling UI tables.
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW V_ACTIVE_LOANS AS
SELECT
  l.LOAN_ID,            -- Primary key of the loan record
  l.LOAN_DATE,          -- When the laptop was loaned out
  l.DUE_DATE,           -- When the laptop should be returned
  s.STUDENT_ID,         -- Internal student PK
  s.STUDENT_NUMBER,     -- School-specific student identifier (natural key)
  s.FULL_NAME AS STUDENT_NAME,
  s.EMAIL AS STUDENT_EMAIL,
  c.COMPUTER_ID,        -- Internal computer PK
  c.COMPUTER_NUMBER,    -- Visible ID used by staff (e.g. PC-0722)
  b.NAME AS BRAND,      -- Manufacturer name (DELL, HP)
  m.MODEL_NAME          -- Model name (Inspiron 9300)
FROM LOAN l
JOIN STUDENT s ON s.STUDENT_ID = l.STUDENT_ID
JOIN COMPUTER c ON c.COMPUTER_ID = l.COMPUTER_ID
JOIN COMPUTER_MODEL m ON m.MODEL_ID = c.MODEL_ID
JOIN BRAND b ON b.BRAND_ID = m.BRAND_ID
WHERE l.RETURN_DATE IS NULL;

--------------------------------------------------------------------------------
-- V_OVERDUE_LOANS
-- Purpose: show active loans where the DUE_DATE is before today (overdue borrowers).
-- Explanation:
--  - Built on top of V_ACTIVE_LOANS so we reuse the readable result set.
--  - DAYS_OVERDUE: calculated as TRUNC(SYSDATE) - DUE_DATE -> integer number of days overdue.
-- Typical use:
--  - Generate reminder emails, escalation reports, or blacklisting candidates.
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW V_OVERDUE_LOANS AS
SELECT
  a.*,                                      -- all columns from V_ACTIVE_LOANS
  (TRUNC(SYSDATE) - a.DUE_DATE) AS DAYS_OVERDUE  -- days past due (integer)
FROM V_ACTIVE_LOANS a
WHERE a.DUE_DATE < TRUNC(SYSDATE);

--------------------------------------------------------------------------------
-- V_AVAILABLE_COMPUTERS
-- Purpose: list computers that are currently NOT on an active loan.
-- Explanation:
--  - For each COMPUTER row, check NOT EXISTS an active LOAN (RETURN_DATE IS NULL).
--  - This is a safe and clear SQL pattern; for very large data sets you can optimize with indexes
--    (the schema already creates IX_LOAN_COMPUTER and the function-based index prevents duplicates).
-- Typical use:
--  - When registering a new loan, present staff a list of available computers to choose from.
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW V_AVAILABLE_COMPUTERS AS
SELECT
  c.COMPUTER_ID,
  c.COMPUTER_NUMBER,
  b.NAME AS BRAND,
  m.MODEL_NAME,
  c.MOUSE_TYPE_CODE
FROM COMPUTER c
JOIN COMPUTER_MODEL m ON m.MODEL_ID = c.MODEL_ID
JOIN BRAND b ON b.BRAND_ID = m.BRAND_ID
WHERE NOT EXISTS (
  SELECT 1
  FROM LOAN l
  WHERE l.COMPUTER_ID = c.COMPUTER_ID
    AND l.RETURN_DATE IS NULL   -- active loan check
);

--------------------------------------------------------------------------------
-- V_LOAN_HISTORY
-- Purpose: provide a historical view of ALL loans (both active and returned).
-- Explanation:
--  - Shows LOAN_DATE, DUE_DATE, RETURN_DATE and a friendly LOAN_STATUS ('ACTIVE' or 'RETURNED').
--  - Useful for reports, statistics, and audit trails.
-- Typical use:
--  - Build graphs of loans over time, or show a student's past loans.
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW V_LOAN_HISTORY AS
SELECT
  l.LOAN_ID,
  s.STUDENT_NUMBER,
  s.FULL_NAME AS STUDENT_NAME,
  c.COMPUTER_NUMBER,
  b.NAME AS BRAND,
  m.MODEL_NAME,
  l.LOAN_DATE,
  l.DUE_DATE,
  l.RETURN_DATE,
  CASE WHEN l.RETURN_DATE IS NULL THEN 'ACTIVE' ELSE 'RETURNED' END AS LOAN_STATUS
FROM LOAN l
JOIN STUDENT s ON s.STUDENT_ID = l.STUDENT_ID
JOIN COMPUTER c ON c.COMPUTER_ID = l.COMPUTER_ID
JOIN COMPUTER_MODEL m ON m.MODEL_ID = c.MODEL_ID
JOIN BRAND b ON b.BRAND_ID = m.BRAND_ID;