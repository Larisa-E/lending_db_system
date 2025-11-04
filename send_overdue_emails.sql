-- simulate sending reminder emails by enqueuing messages into EMAIL_QUEUE.
-- When to run: as LENDING after you have at least one overdue loan (V_OVERDUE_LOANS returns rows).

--------------------------------------------------------------------------------
-- INSERT INTO EMAIL_QUEUE ... SELECT FROM V_OVERDUE_LOANS
-- Explanation:
--  - We select students from V_OVERDUE_LOANS (active loans past due).
--  - For each overdue loan, compose a SUBJECT and BODY text.
--  - Insert into EMAIL_QUEUE (RECIPIENT, SUBJECT, BODY), with QUEUED_AT defaulting to SYSDATE.
--  - A real mailer would later pick rows from EMAIL_QUEUE and send emails; this demonstrates the workflow.
--------------------------------------------------------------------------------
INSERT INTO EMAIL_QUEUE (RECIPIENT, SUBJECT, BODY)
SELECT
  STUDENT_EMAIL,                                 -- recipient email address from the view
  'Overdue laptop return reminder',              -- subject line
  'Dear ' || STUDENT_NAME ||                     -- body composed with student name and computer info
  ', your loan for computer ' || COMPUTER_NUMBER ||
  ' was due on ' || TO_CHAR(DUE_DATE, 'YYYY-MM-DD') ||
  '. Please return it immediately.'
FROM V_OVERDUE_LOANS;

COMMIT;

-- Show queued emails (newest first)
SELECT * FROM EMAIL_QUEUE ORDER BY QUEUED_AT DESC;