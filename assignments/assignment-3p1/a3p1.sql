
SET SERVEROUTPUT ON;

DECLARE

    CURSOR c_transactions IS
        SELECT DISTINCT transaction_no, transaction_date, description
        FROM   new_transactions;

    CURSOR c_details (p_transaction_no NUMBER) IS
        SELECT account_no, transaction_type, transaction_amount
        FROM   new_transactions
        WHERE  transaction_no = p_transaction_no;

    r_transaction   c_transactions%ROWTYPE;
    r_detail        c_details%ROWTYPE;

    v_default_trans_type   account_type.default_trans_type%TYPE;
    v_balance_adjustment   account.account_balance%TYPE;

    v_transaction_count    PLS_INTEGER := 0;

BEGIN

    OPEN c_transactions;
    LOOP
        FETCH c_transactions INTO r_transaction;
        EXIT WHEN c_transactions%NOTFOUND;

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

        v_transaction_count := v_transaction_count + 1;

    END LOOP;
    CLOSE c_transactions;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE(v_transaction_count || ' transaction(s) processed and removed from NEW_TRANSACTIONS.');

END;
/