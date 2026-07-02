/*==============================================================================
  ASSIGNMENT 3 - PART 1: WKIS TRANSACTION PROCESSING (CLEAN DATA)
  ------------------------------------------------------------------------------
  Purpose:
    Process every transaction currently sitting in the NEW_TRANSACTIONS
    holding table and post it into the permanent accounting tables.

    For every transaction (a group of rows that share the same
    TRANSACTION_NO, TRANSACTION_DATE and DESCRIPTION) this program will:

      1. Insert one row into TRANSACTION_HISTORY describing the transaction.
      2. Insert one row into TRANSACTION_DETAIL for every account line that
         makes up the transaction.
      3. Update ACCOUNT_BALANCE for every account touched by the
         transaction. The default transaction type of the account (its
         normal debit/credit behaviour, stored in ACCOUNT_TYPE) is compared
         to the transaction's own type: when they match, the balance is
         increased; when they differ, the balance is decreased. This is
         the standard double-entry accounting rule.
      4. Remove all rows belonging to the transaction from NEW_TRANSACTIONS
         once it has been fully posted.

  Assumptions (per assignment guidelines):
    - The data is clean, so no exception handling is required.
    - Every row belonging to the same transaction shares the same
      TRANSACTION_NO, TRANSACTION_DATE and DESCRIPTION.
    - A transaction always consists of more than one row, and no two
      transactions share a TRANSACTION_NO.

  Design notes:
    - Two nested EXPLICIT cursors are used, as suggested by the assignment:
        c_transactions - outer cursor, one row per distinct transaction.
        c_details      - inner cursor, one row per account line for the
                          transaction currently being processed by the
                          outer cursor.
    - Every read against NEW_TRANSACTIONS is performed through one of
      these two explicit cursors - no SELECT INTO or subquery is ever
      issued directly against NEW_TRANSACTIONS.
    - Each cursor is fetched with a basic LOOP / EXIT WHEN %NOTFOUND
      pattern (no bare EXIT, GOTO or SAVEPOINT is used anywhere).
    - Only single-row records (cursor%ROWTYPE) are used to hold fetched
      data - no table of records or other collection type is used.
    - This entire solution is a single anonymous PL/SQL block; no stored
      procedures, functions or packages are created.
    - Nothing is hard coded: the debit/credit decision is always made by
      comparing two values read from the data (the transaction's own type
      vs. the account's default type) rather than against literal 'D'/'C'.
    - Changes are only committed once, after every transaction in the
      holding table has been fully processed.
==============================================================================*/

SET SERVEROUTPUT ON;

DECLARE

    -- Outer cursor: one row per distinct transaction waiting in the
    -- holding table. DISTINCT is safe here because every row that shares
    -- a TRANSACTION_NO is guaranteed to also share the same
    -- TRANSACTION_DATE and DESCRIPTION.
    CURSOR c_transactions IS
        SELECT DISTINCT transaction_no, transaction_date, description
        FROM   new_transactions;

    -- Inner cursor: every account line (detail row) that belongs to the
    -- transaction currently being processed by the outer cursor.
    -- Parameterized so it can be re-opened for each transaction found.
    CURSOR c_details (p_transaction_no NUMBER) IS
        SELECT account_no, transaction_type, transaction_amount
        FROM   new_transactions
        WHERE  transaction_no = p_transaction_no;

    -- Single-row records to hold the data fetched by each cursor.
    r_transaction   c_transactions%ROWTYPE;
    r_detail        c_details%ROWTYPE;

    -- The normal (default) transaction type of the account currently
    -- being posted to, and the signed amount to apply to its balance.
    v_default_trans_type   account_type.default_trans_type%TYPE;
    v_balance_adjustment   account.account_balance%TYPE;

    -- Simple counter for a summary message at the end of the run.
    -- (Counters are explicitly allowed to be "hard coded" starting
    -- values, per the assignment guidelines.)
    v_transaction_count    PLS_INTEGER := 0;

BEGIN

    OPEN c_transactions;
    LOOP
        FETCH c_transactions INTO r_transaction;
        EXIT WHEN c_transactions%NOTFOUND;

        -- Step 1: record the transaction-level information once.
        INSERT INTO transaction_history (transaction_no, transaction_date, description)
        VALUES (r_transaction.transaction_no, r_transaction.transaction_date, r_transaction.description);

        -- Step 2 & 3: process every account line belonging to this
        -- transaction - post the detail row and update the account
        -- balance for the account referenced on that line.
        OPEN c_details(r_transaction.transaction_no);
        LOOP
            FETCH c_details INTO r_detail;
            EXIT WHEN c_details%NOTFOUND;

            EXCEPTION

            INSERT INTO transaction_detail (account_no, transaction_no, transaction_type, transaction_amount)
            VALUES (r_detail.account_no, r_transaction.transaction_no, r_detail.transaction_type, r_detail.transaction_amount);

            -- Look up the account's normal (default) transaction type so
            -- we know whether this line increases or decreases its
            -- balance. ACCOUNT and ACCOUNT_TYPE are not restricted, so we are assuming a
            -- SELECT INTO against them is allowed.
            SELECT atyp.default_trans_type
            INTO   v_default_trans_type
            FROM   account act
            JOIN   account_type atyp ON act.account_type_code = atyp.account_type_code
            WHERE  act.account_no = r_detail.account_no;

            -- Double-entry rule: if the transaction's type matches the
            -- account's default type, the balance goes up; otherwise it
            -- goes down. Both sides of this comparison come from data,
            -- never from a hard-coded literal.
            IF r_detail.transaction_type = v_default_trans_type THEN
                v_balance_adjustment := r_detail.transaction_amount;
            ELSE
                v_balance_adjustment := -r_detail.transaction_amount;
            END IF;

            UPDATE account
            SET    account_balance = account_balance + v_balance_adjustment
            WHERE  account_no = r_detail.account_no;

        END LOOP;
        CLOSE c_details;

        -- Step 4: the transaction has been fully posted - remove every
        -- row belonging to it from the holding table.
        DELETE FROM new_transactions
        WHERE  transaction_no = r_transaction.transaction_no;

        v_transaction_count := v_transaction_count + 1;

    END LOOP;
    CLOSE c_transactions;

    -- Save every change made above in a single, complete commit.
    COMMIT;

    DBMS_OUTPUT.PUT_LINE(v_transaction_count || ' transaction(s) processed and removed from NEW_TRANSACTIONS.');

END;
/