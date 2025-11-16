-- Set a seed for reproducible random data (optional)
-- SELECT setseed(0.5);

-- ===========================================================
-- 1. Insert 50 Customers (Base Data)
-- ===========================================================
INSERT INTO customers (full_name, mobile_number, email, pan_number, aadhaar_number, cibil_score, monthly_income)
SELECT
    -- full_name: Generate a random name
    array_to_string(ARRAY(
        SELECT chr((97 + round(random() * 25)) :: integer)
        FROM generate_series(1, 10)
    ), '') || ' ' || array_to_string(ARRAY(
        SELECT chr((97 + round(random() * 25)) :: integer)
        FROM generate_series(1, 12)
    ), ''),
    -- mobile_number: Random 10-digit number as string
    (floor(random() * 9000000000 + 1000000000))::VARCHAR,
    -- email: Simple random email
    array_to_string(ARRAY(
        SELECT chr((97 + round(random() * 25)) :: integer)
        FROM generate_series(1, 8)
    ), '') || floor(random() * 1000)::VARCHAR || '@' || CASE floor(random() * 3)
        WHEN 0 THEN 'mail.com'
        WHEN 1 THEN 'test.org'
        ELSE 'demo.net'
    END,
    -- pan_number: Random 10-char PAN-like string
    'ABCDE' || array_to_string(ARRAY(
        SELECT chr((48 + round(random() * 9)) :: integer)
        FROM generate_series(1, 4)
    ), '') || chr((65 + round(random() * 25)) :: integer),
    -- aadhaar_number: Random 12-digit number as string
    (floor(random() * 900000000000 + 100000000000))::VARCHAR,
    -- cibil_score: Random score between 600 and 850
    floor(random() * 251 + 600)::INT,
    -- monthly_income: Random income between 20000 and 200000
    floor(random() * 180001 + 20000)::NUMERIC(12,2)
FROM generate_series(1, 50);


-- ===========================================================
-- 2. Insert Customer Banking Details (One per Customer, assuming primary)
-- ===========================================================
INSERT INTO customer_bank_details (customer_id, bank_name, account_number, ifsc_code, account_type, is_primary)
SELECT
    c.id,
    -- bank_name: Random bank
    CASE floor(random() * 4)
        WHEN 0 THEN 'State Bank of India'
        WHEN 1 THEN 'HDFC Bank'
        WHEN 2 THEN 'ICICI Bank'
        ELSE 'Axis Bank'
    END,
    -- account_number: Random 12-digit number as string
    (floor(random() * 900000000000 + 100000000000))::VARCHAR,
    -- ifsc_code: Random IFSC-like code
    'IFSC' || floor(random() * 9000000 + 1000000)::VARCHAR,
    -- account_type: Random account type
    CASE floor(random() * 2) WHEN 0 THEN 'Savings' ELSE 'Current' END,
    TRUE
FROM customers c
ORDER BY c.created_at; -- Process in order of creation


-- ===========================================================
-- 3. Insert 50 Loan Leads (One per Customer)
-- ===========================================================
INSERT INTO loan_leads (unique_identifier, product_type, loan_amount_requested, loan_tenure_months, loan_purpose_desc, lead_source, status)
SELECT
    -- unique_identifier: Use a combination of a prefix and customer ID part
    'LEAD-' || RIGHT(c.id::VARCHAR, 12),
    -- product_type: Random loan product
    CASE floor(random() * 3) WHEN 0 THEN 'PL' WHEN 1 THEN 'BL' ELSE 'HL' END,
    -- loan_amount_requested: Random amount between 50000 and 5000000
    (floor(random() * 4950001 + 50000) / 10000) * 10000::NUMERIC(15,2), -- Rounded to nearest 10000
    -- loan_tenure_months: Random tenure in months (12, 24, 36, 48, 60)
    (ARRAY[12, 24, 36, 48, 60])[floor(random() * 5) + 1]::INT,
    -- loan_purpose_desc: Random purpose
    CASE floor(random() * 3)
        WHEN 0 THEN 'Home Renovation'
        WHEN 1 THEN 'Business Expansion'
        ELSE 'Wedding Expenses'
    END,
    -- lead_source: Random enum value
    (ARRAY['DSA', 'BRANCH', 'REFERRAL', 'CHATBOT', 'DIGITAL_AD'])[floor(random() * 5) + 1]::lead_source_enum,
    -- status: 90% new, 10% converted to application
    CASE WHEN random() < 0.9 THEN 'new' ELSE 'converted' END
FROM customers c
ORDER BY c.created_at;


-- ===========================================================
-- 4. Insert Loan Applications (For converted leads, approx 45 leads)
-- ===========================================================
INSERT INTO loan_applications (lead_id, branch_name, sanction_amount, stage, status, disbursal_account_id, created_at)
SELECT
    ll.id,
    -- branch_name: Random branch
    CASE floor(random() * 3) WHEN 0 THEN 'Central' WHEN 1 THEN 'East' ELSE 'West' END || ' Branch',
    -- sanction_amount: Randomly lower than requested amount (80% to 100%)
    ll.loan_amount_requested * (random() * 0.2 + 0.8)::NUMERIC(15,2),
    -- stage: Random stage (weighted towards earlier stages)
    (ARRAY['KYC', 'KYC', 'DDE', 'DDE', 'CREDIT', 'SANCTION'])[floor(random() * 6) + 1]::loan_stage_enum,
    -- status: Random status based on stage
    CASE
        WHEN random() < 0.2 THEN 'rejected'
        WHEN random() < 0.3 THEN 'withdrawn'
        ELSE 'in-process'
    END,
    -- disbursal_account_id: Link to a bank detail
    cbd.id,
    -- created_at: Slightly after lead creation
    ll.created_at + INTERVAL '1 day' * random() * 10
FROM loan_leads ll
JOIN customers c ON ll.unique_identifier = 'LEAD-' || RIGHT(c.id::VARCHAR, 12)
JOIN customer_bank_details cbd ON c.id = cbd.customer_id
WHERE ll.status = 'converted';


-- ===========================================================
-- 5. Insert Loan Participants (Applicant role for all applications)
-- ===========================================================
INSERT INTO loan_participants (application_id, customer_id, role)
SELECT
    la.id,
    c.id,
    'APPLICANT'::participant_role_enum
FROM loan_applications la
JOIN loan_leads ll ON la.lead_id = ll.id
JOIN customers c ON ll.unique_identifier = 'LEAD-' || RIGHT(c.id::VARCHAR, 12);


-- ===========================================================
-- 6. Insert Loan Accounts (For a subset of applications that are 'SANCTION' or later)
-- ===========================================================
INSERT INTO loan_accounts (application_id, loan_number, disbursed_amount, interest_rate, start_date, end_date, current_balance)
SELECT
    la.id,
    -- loan_number: Simple sequential number for demo
    'L' || lpad(ROW_NUMBER() OVER(ORDER BY la.created_at)::TEXT, 4, '0'),
    la.sanction_amount,
    -- interest_rate: Random rate between 8.0 and 18.0
    (random() * 10 + 8)::NUMERIC(5,2),
    -- start_date: Random date in the last year
    (NOW() - INTERVAL '1 year' * random())::DATE,
    -- end_date: Calculated from start_date and random tenure (3-5 years)
    (NOW() - INTERVAL '1 year' * random() + (ARRAY[3, 4, 5])[floor(random() * 3) + 1] * INTERVAL '1 year')::DATE,
    -- current_balance: Randomly less than or equal to disbursed amount
    la.sanction_amount * random()::NUMERIC(15,2)
FROM loan_applications la
WHERE la.stage IN ('SANCTION', 'DISBURSAL', 'POST_DISBURSAL', 'CLOSED')
AND random() < 0.8; -- Only 80% of eligible applications get an account (simulate pre-disbursal drop)


-- ===========================================================
-- 7. Insert Loan Repayments (For existing loan accounts)
-- ===========================================================
INSERT INTO loan_repayments (account_id, due_date, paid_date, amount_due, amount_paid, status)
SELECT
    la.id,
    -- due_date: Generate a series of dates starting from 1 month after start_date
    (la.start_date + (n * INTERVAL '1 month'))::DATE AS due_date,
    -- paid_date: 80% paid on time (same as due_date), 10% late, 10% pending
    CASE
        WHEN random() < 0.8 THEN (la.start_date + (n * INTERVAL '1 month'))::DATE
        WHEN random() < 0.9 THEN (la.start_date + (n * INTERVAL '1 month') + INTERVAL '10 days' * random())::DATE
        ELSE NULL
    END AS paid_date,
    -- amount_due: Random due amount between 5000 and 20000
    floor(random() * 15001 + 5000)::NUMERIC(15,2),
    -- amount_paid: Paid amount is equal to due amount if paid_date is not null
    CASE
        WHEN random() < 0.9 THEN floor(random() * 15001 + 5000)::NUMERIC(15,2)
        ELSE NULL
    END,
    -- status: Set status based on paid_date
    CASE
        WHEN random() < 0.8 THEN 'paid'
        WHEN random() < 0.9 THEN 'late'
        ELSE 'pending'
    END
FROM loan_accounts la
CROSS JOIN generate_series(1, 12) AS n(n); -- Generate 12 repayments per loan account

-- Update amount_paid for 'paid' status for consistency
UPDATE loan_repayments
SET amount_paid = amount_due
WHERE status = 'paid';