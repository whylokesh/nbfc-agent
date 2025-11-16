-- ===========================================================
-- 🏦 NBFC Loan Origination System (POC)
-- ===========================================================

-- Enable UUID and crypto extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ===========================================================
-- ENUMS
-- ===========================================================
CREATE TYPE loan_stage_enum AS ENUM (
  'KYC',
  'DDE',
  'CREDIT',
  'SANCTION',
  'DISBURSAL',
  'POST_DISBURSAL',
  'CLOSED'
);

CREATE TYPE lead_source_enum AS ENUM (
  'DSA',
  'BRANCH',
  'REFERRAL',
  'CHATBOT',
  'DIGITAL_AD'
);

CREATE TYPE participant_role_enum AS ENUM (
  'APPLICANT',
  'CO_APPLICANT',
  'GUARANTOR'
);

-- ===========================================================
-- TABLES
-- ===========================================================

-- 👤 Customers
CREATE TABLE customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name VARCHAR(100),
  mobile_number VARCHAR(15),
  email VARCHAR(100),
  pan_number VARCHAR(10),
  aadhaar_number VARCHAR(12),
  cibil_score INT,
  monthly_income NUMERIC(12,2),
  created_at TIMESTAMP DEFAULT NOW()
);

-- 🏦 Customer Banking Details
CREATE TABLE customer_bank_details (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  bank_name VARCHAR(100),
  account_number VARCHAR(20),
  ifsc_code VARCHAR(11),
  account_type VARCHAR(20),
  is_primary BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- 🧾 Loan Leads
CREATE TABLE loan_leads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  unique_identifier VARCHAR(100),
  product_type VARCHAR(10),
  loan_amount_requested NUMERIC(15,2),
  loan_tenure_months INT,
  loan_purpose_desc TEXT,
  lead_source lead_source_enum,
  status VARCHAR(20) DEFAULT 'new',
  created_at TIMESTAMP DEFAULT NOW()
);

-- 🗂️ Loan Applications
CREATE TABLE loan_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id UUID REFERENCES loan_leads(id) ON DELETE CASCADE,
  branch_name VARCHAR(100),
  sanction_amount NUMERIC(15,2),
  stage loan_stage_enum DEFAULT 'KYC',
  status VARCHAR(20) DEFAULT 'in-process',
  disbursal_account_id UUID REFERENCES customer_bank_details(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 👥 Loan Participants
CREATE TABLE loan_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID REFERENCES loan_applications(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  role participant_role_enum
);

-- 📘 Loan Accounts (Post-Disbursal)
CREATE TABLE loan_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID REFERENCES loan_applications(id) ON DELETE CASCADE,
  loan_number VARCHAR(20),
  disbursed_amount NUMERIC(15,2),
  interest_rate NUMERIC(5,2),
  start_date DATE,
  end_date DATE,
  current_balance NUMERIC(15,2)
);

-- 💸 Loan Repayments
CREATE TABLE loan_repayments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID REFERENCES loan_accounts(id) ON DELETE CASCADE,
  due_date DATE,
  paid_date DATE,
  amount_due NUMERIC(15,2),
  amount_paid NUMERIC(15,2),
  status VARCHAR(20) DEFAULT 'pending'
);

-- ===========================================================
-- GENERATE DEMO DATA (≈ 50 RECORDS EACH)
-- ===========================================================

-- 👤 Customers (50)
INSERT INTO customers (full_name, mobile_number, email, pan_number, aadhaar_number, cibil_score, monthly_income)
SELECT
  'Customer ' || i AS full_name,
  '98' || LPAD((1000000 + i)::text, 8, '0') AS mobile_number,
  'customer' || i || '@example.com' AS email,
  upper(substr(md5(random()::text), 1, 10)) AS pan_number,
  LPAD((100000000000 + i)::text, 12, '0') AS aadhaar_number,
  (650 + (random() * 200)::int) AS cibil_score,
  (40000 + (random() * 100000)::int)::numeric(12,2) AS monthly_income
FROM generate_series(1, 50) s(i);

-- 🏦 Customer Bank Details (≈1 per customer)
INSERT INTO customer_bank_details (customer_id, bank_name, account_number, ifsc_code, account_type)
SELECT
  c.id,
  (ARRAY['HDFC Bank','ICICI Bank','Axis Bank','SBI','Kotak Mahindra'])[floor(random()*5)+1],
  '50' || (1000000000 + s.i)::text AS account_number,
  'IFSC' || substr(md5(random()::text), 1, 7),
  (ARRAY['SAVINGS','CURRENT'])[floor(random()*2)+1]
FROM customers c
JOIN generate_series(1, 1) s(i) ON TRUE;

-- 🧾 Loan Leads (50)
INSERT INTO loan_leads (unique_identifier, product_type, loan_amount_requested, loan_tenure_months, loan_purpose_desc, lead_source)
SELECT
  'LEAD-' || LPAD(i::text, 3, '0'),
  (ARRAY['PL','LAP','HL'])[floor(random()*3)+1],
  (100000 + random() * 2000000)::numeric(15,2),
  (12 + (random() * 180)::int),
  'Loan purpose ' || i,
  (ARRAY['DSA','BRANCH','REFERRAL','CHATBOT','DIGITAL_AD'])[floor(random()*5)+1]
FROM generate_series(1, 50) s(i);

-- 🗂️ Loan Applications (50)
INSERT INTO loan_applications (lead_id, branch_name, sanction_amount, stage, status, disbursal_account_id)
SELECT
  ll.id,
  (ARRAY['Mumbai Central','Delhi South','Chennai North','Ahmedabad Main','Kolkata West'])[floor(random()*5)+1],
  (ll.loan_amount_requested * (0.9 + random()*0.1))::numeric(15,2),
  (ARRAY['KYC','DDE','CREDIT','SANCTION','DISBURSAL','POST_DISBURSAL'])[floor(random()*6)+1],
  (ARRAY['in-process','approved','disbursed','rejected'])[floor(random()*4)+1],
  (SELECT cbd.id FROM customer_bank_details cbd ORDER BY random() LIMIT 1)
FROM loan_leads ll;

-- 👥 Loan Participants (≈ 1–2 per application)
INSERT INTO loan_participants (application_id, customer_id, role)
SELECT
  la.id,
  (SELECT c.id FROM customers c ORDER BY random() LIMIT 1),
  (ARRAY['APPLICANT','CO_APPLICANT','GUARANTOR'])[floor(random()*3)+1]
FROM loan_applications la, generate_series(1, 2);

-- 📘 Loan Accounts (only for some applications)
INSERT INTO loan_accounts (application_id, loan_number, disbursed_amount, interest_rate, start_date, end_date, current_balance)
SELECT
  la.id,
  'LN-' || LPAD(row_number() OVER (), 4, '0'),
  (la.sanction_amount * 0.95)::numeric(15,2),
  (8 + random() * 5)::numeric(5,2),
  (CURRENT_DATE - (random()*365)::int),
  (CURRENT_DATE + (365 * 3))::date,
  (la.sanction_amount * (0.9 + random()*0.1))::numeric(15,2)
FROM loan_applications la
WHERE la.status IN ('disbursed','approved')
LIMIT 50;

-- 💸 Loan Repayments (3 per account)
INSERT INTO loan_repayments (account_id, due_date, paid_date, amount_due, amount_paid, status)
SELECT
  la.id,
  CURRENT_DATE + (s.i * 30),
  CASE WHEN random() > 0.3 THEN CURRENT_DATE + (s.i * 30 - 2) ELSE NULL END,
  (10000 + random() * 50000)::numeric(15,2),
  CASE WHEN random() > 0.3 THEN (10000 + random() * 50000)::numeric(15,2) ELSE 0 END,
  CASE WHEN random() > 0.3 THEN 'paid' ELSE 'pending' END
FROM loan_accounts la, generate_series(1, 3) s(i);
