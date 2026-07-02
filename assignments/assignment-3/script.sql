/*==============================================================================
  ASSIGNMENT 3 - PART 2: WKIS TRANSACTION PROCESSING (WITH EXCEPTION HANDLING)
  ------------------------------------------------------------------------------
  Purpose:
    Extends the Part 1 solution to work with a mix of good and bad data.
    Every transaction (a group of rows in NEW_TRANSACTIONS that share the
    same TRANSACTION_NO, TRANSACTION_DATE and DESCRIPTION) is validated
    before it is posted. A transaction that passes validation is processed
    exactly as in Part 1:

      1. One row inserted into TRANSACTION_HISTORY.
      2. One row inserted into TRANSACTION_DETAIL per account line.
      3. ACCOUNT_BALANCE updated for every account touched (increased when
         the line's TRANSACTION_TYPE matches the account's
         DEFAULT_TRANS_TYPE, decreased otherwise).
      4. All of its rows removed from NEW_TRANSACTIONS.

    A transaction that FAILS validation is instead:
      1. Left completely untouched in NEW_TRANSACTIONS.
      2. Given exactly ONE descriptive entry in WKIS_ERROR_LOG explaining
         the first problem found with it.
    Processing then moves on to the next transaction - one bad transaction
    never stops the rest of the batch from being processed.

  Errors handled (business rules, each given a custom descriptive message):
    - Missing transaction number (NULL TRANSACTION_NO).
    - Debits not equal to credits within a transaction.
    - Invalid account number (ACCOUNT_NO not found in ACCOUNT).
    - Negative TRANSACTION_AMOUNT.
    - Invalid TRANSACTION_TYPE (anything other than 'D' or 'C').
    Any other, unanticipated error is also caught (WHEN OTHERS) so the
    program never crashes; it is logged using Oracle's own system-generated
    message (SQLERRM), per the assignment - no custom message is required
    or expected for this category.

  Assumptions:
    - Every row belonging to the same transaction shares the same
      TRANSACTION_NO, TRANSACTION_DATE and DESCRIPTION.
    - A transaction always consists of more than one row, and no two
      transactions share a (non-null) TRANSACTION_NO.

  Design notes:
    - Two nested EXPLICIT cursors are used, as suggested by the assignment:
        c_transactions   - outer cursor, one row per distinct, non-null
                            transaction number waiting in the holding table.
        c_details        - inner cursor, one row per account line for the
                            transaction currently being processed.
      A third explicit cursor, c_missing_txn_no, is used only to detect
      rows that are missing a transaction number altogether (they cannot
      be grouped by c_transactions since they have no TRANSACTION_NO).
      Every read against NEW_TRANSACTIONS is performed through one of
      these three explicit cursors - no SELECT INTO or subquery is ever
      issued directly against NEW_TRANSACTIONS.
    - Each transaction is validated in two passes over c_details:
        Pass 1 (validation) - open c_details, check every line for a row
          level error (invalid type, negative amount, invalid account),
          and, if none is found, accumulate debit/credit totals. Once the
          transaction-level debit/credit balance is checked, at most one
          error message is kept - the first problem found.
        Pass 2 (posting) - only runs when pass 1 found no error; re-opens
          c_details and posts the transaction exactly as in Part 1.
      This two-pass structure keeps the Part 1 posting logic completely
      unchanged for clean transactions, as required.
    - Each transaction's processing (both passes) is wrapped in its own
      nested BEGIN...EXCEPTION...END block. Catching WHEN OTHERS here
      means an unanticipated error on one transaction is logged and the
      OUTER loop simply continues to the next FETCH - the main looping
      structure is never left because of an error.
    - Every cursor is fetched with a basic LOOP / EXIT WHEN %NOTFOUND
      pattern (no bare EXIT, GOTO or SAVEPOINT is used anywhere).
    - Only single-row records (cursor%ROWTYPE) are used to hold fetched
      data - no table of records or other collection type is used.
    - This entire solution is a single anonymous PL/SQL block; no stored
      procedures, functions or packages are created.
    - The only hard-coded data values in this program are the literals
      'D' and 'C', and they are declared once as CONSTANTs (c_debit,
      c_credit) and referenced everywhere else - as permitted (and
      required, to be able to detect an invalid transaction type) by the
      Part 2 guidelines. Every other comparison (e.g. deciding whether to
      add or subtract from an account balance) is still driven entirely
      by data read from the tables, exactly as in Part 1.
    - Changes are only committed once, after every transaction in the
      holding table has been processed (successfully or not).
==============================================================================*/

SET SERVEROUTPUT ON;

DECLARE

    -- The only hard-coded data values allowed in this program, per the
    -- Part 2 guidelines - used to recognize/validate debit and credit
    -- transaction types.
    c_debit     CONSTANT CHAR(1) := 'D';
    c_credit    CONSTANT CHAR(1) := 'C';

    -- Outer cursor: one row per distinct transaction waiting in the
    -- holding table that actually has a transaction number. DISTINCT is
    -- safe here because every row that shares a TRANSACTION_NO is
    -- guaranteed to also share the same TRANSACTION_DATE and DESCRIPTION.
    CURSOR c_transactions IS
        SELECT DISTINCT transaction_no, transaction_date, description
        FROM   new_transactions
        WHERE  transaction_no IS NOT NULL
        ORDER  BY transaction_no;

    -- Inner cursor: every account line (detail row) that belongs to the
    -- transaction currently being processed by the outer cursor.
    -- Parameterized so it can be opened/closed for each transaction, and
    -- reopened for the posting pass once validation has passed.
    CURSOR c_details (p_transaction_no NUMBER) IS
        SELECT account_no, transaction_type, transaction_amount
        FROM   new_transactions
        WHERE  transaction_no = p_transaction_no;

    -- Used only to check whether any row is missing a transaction number
    -- altogether. Such rows cannot be grouped by TRANSACTION_NO, so they
    -- are handled separately, before the main transaction loop.
    CURSOR c_missing_txn_no IS
        SELECT transaction_date, description
        FROM   new_transactions
        WHERE  transaction_no IS NULL;

    -- Single-row records to hold the data fetched by each cursor.
    r_transaction   c_transactions%ROWTYPE;
    r_detail        c_details%ROWTYPE;
    r_missing_txn   c_missing_txn_no%ROWTYPE;

    -- The normal (default) transaction type of the account currently
    -- being posted to, and the signed amount to apply to its balance.
    v_default_trans_type   account_type.default_trans_type%TYPE;
    v_balance_adjustment   account.account_balance%TYPE;

    -- Working variables used while validating a single transaction.
    v_account_count     PLS_INTEGER;
    v_debit_total        NUMBER;
    v_credit_total        NUMBER;
    v_has_error         BOOLEAN;
    v_error_message      VARCHAR2(500);

    -- Simple counters for a summary message at the end of the run.
    v_processed_count    PLS_INTEGER := 0;
    v_error_count        PLS_INTEGER := 0;

BEGIN

    -- ------------------------------------------------------------------
    -- Rows missing a transaction number cannot belong to any transaction
    -- group, so they are handled once, up front, rather than inside the
    -- main loop below. Per the assignment, a single error log entry
    -- covering all such rows is sufficient.
    -- ------------------------------------------------------------------
    OPEN c_missing_txn_no;
    FETCH c_missing_txn_no INTO r_missing_txn;
    IF c_missing_txn_no%FOUND THEN
        INSERT INTO wkis_error_log (transaction_no, transaction_date, description, error_msg)
        VALUES (NULL, r_missing_txn.transaction_date, r_missing_txn.description,
                SUBSTR('One or more rows in NEW_TRANSACTIONS are missing a transaction number ' ||
                       '(TRANSACTION_NO is NULL) and could not be processed.', 1, 200));
        v_error_count := v_error_count + 1;
    END IF;
    CLOSE c_missing_txn_no;

    -- ------------------------------------------------------------------
    -- Main loop: one iteration per distinct, non-null transaction number.
    -- ------------------------------------------------------------------
    OPEN c_transactions;
    LOOP
        FETCH c_transactions INTO r_transaction;
        EXIT WHEN c_transactions%NOTFOUND;

        -- Everything for this one transaction is wrapped in its own
        -- nested block so that any unanticipated error only affects this
        -- transaction - the outer loop above is never left because of it.
        BEGIN

            v_has_error     := FALSE;
            v_error_message := NULL;
            v_debit_total   := 0;
            v_credit_total  := 0;

            -- ----------------------------------------------------------
            -- PASS 1: validate every line of the transaction. At most
            -- one problem is kept - the first one found - checked in the
            -- order: invalid type, negative amount, invalid account. If
            -- a line passes all three, its amount is added to the
            -- running debit or credit total for the balance check below.
            -- ----------------------------------------------------------
            OPEN c_details(r_transaction.transaction_no);
            LOOP
                FETCH c_details INTO r_detail;
                EXIT WHEN c_details%NOTFOUND;

                IF NOT v_has_error THEN
                    IF r_detail.transaction_type NOT IN (c_debit, c_credit) THEN
                        v_has_error     := TRUE;
                        v_error_message := 'Invalid transaction type ''' || r_detail.transaction_type ||
                                            ''' for account ' || r_detail.account_no ||
                                            ' in transaction ' || r_transaction.transaction_no ||
                                            ' (must be ''' || c_debit || ''' or ''' || c_credit || ''').';
                    ELSIF r_detail.transaction_amount < 0 THEN
                        v_has_error     := TRUE;
                        v_error_message := 'Negative transaction amount (' || r_detail.transaction_amount ||
                                            ') for account ' || r_detail.account_no ||
                                            ' in transaction ' || r_transaction.transaction_no || '.';
                    ELSE
                        SELECT COUNT(*)
                        INTO   v_account_count
                        FROM   account
                        WHERE  account_no = r_detail.account_no;

                        IF v_account_count = 0 THEN
                            v_has_error     := TRUE;
                            v_error_message := 'Account number ' || r_detail.account_no ||
                                                ' referenced in transaction ' || r_transaction.transaction_no ||
                                                ' does not exist in the ACCOUNT table.';
                        ELSIF r_detail.transaction_type = c_debit THEN
                            v_debit_total := v_debit_total + r_detail.transaction_amount;
                        ELSE
                            v_credit_total := v_credit_total + r_detail.transaction_amount;
                        END IF;
                    END IF;
                END IF;

            END LOOP;
            CLOSE c_details;

            -- Transaction-level check: only meaningful once every line
            -- has been confirmed individually valid above.
            IF NOT v_has_error AND v_debit_total != v_credit_total THEN
                v_has_error     := TRUE;
                v_error_message := 'Total debits (' || v_debit_total || ') do not equal total credits (' ||
                                    v_credit_total || ') for transaction ' || r_transaction.transaction_no || '.';
            END IF;

            IF v_has_error THEN

                -- Leave every row of this transaction untouched in
                -- NEW_TRANSACTIONS - only log why it failed.
                INSERT INTO wkis_error_log (transaction_no, transaction_date, description, error_msg)
                VALUES (r_transaction.transaction_no, r_transaction.transaction_date,
                        r_transaction.description, SUBSTR(v_error_message, 1, 200));
                v_error_count := v_error_count + 1;

            ELSE

                -- ------------------------------------------------------
                -- PASS 2: identical to the Part 1 posting logic - runs
                -- only for a transaction that passed every check above.
                -- ------------------------------------------------------
                INSERT INTO transaction_history (transaction_no, transaction_date, description)
                VALUES (r_transaction.transaction_no, r_transaction.transaction_date, r_transaction.description);

                OPEN c_details(r_transaction.transaction_no);
                LOOP
                    FETCH c_details INTO r_detail;
                    EXIT WHEN c_details%NOTFOUND;

                    INSERT INTO transaction_detail (account_no, transaction_no, transaction_type, transaction_amount)
                    VALUES (r_detail.account_no, r_transaction.transaction_no, r_detail.transaction_type, r_detail.transaction_amount);

                    SELECT atyp.default_trans_type
                    INTO   v_default_trans_type
                    FROM   account act
                    JOIN   account_type atyp ON act.account_type_code = atyp.account_type_code
                    WHERE  act.account_no = r_detail.account_no;

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

                DELETE FROM new_transactions
                WHERE  transaction_no = r_transaction.transaction_no;

                v_processed_count := v_processed_count + 1;

            END IF;

        EXCEPTION
            WHEN OTHERS THEN
                -- Defensive cleanup: if the inner cursor was left open by
                -- whatever failed above, close it so the next iteration's
                -- OPEN does not raise ORA-06511 (cursor already open).
                IF c_details%ISOPEN THEN
                    CLOSE c_details;
                END IF;

                -- Unanticipated error - use Oracle's own system-generated
                -- message, exactly as the assignment specifies. The
                -- transaction is left in NEW_TRANSACTIONS since none of
                -- its rows were successfully posted.
                INSERT INTO wkis_error_log (transaction_no, transaction_date, description, error_msg)
                VALUES (r_transaction.transaction_no, r_transaction.transaction_date,
                        r_transaction.description, SUBSTR(SQLERRM, 1, 200));
                v_error_count := v_error_count + 1;
        END;

    END LOOP;
    CLOSE c_transactions;

    -- Save every change made above in a single, complete commit.
    COMMIT;

    DBMS_OUTPUT.PUT_LINE(v_processed_count || ' transaction(s) processed successfully.');
    DBMS_OUTPUT.PUT_LINE(v_error_count || ' transaction(s)/row group(s) logged to WKIS_ERROR_LOG.');

END;
/