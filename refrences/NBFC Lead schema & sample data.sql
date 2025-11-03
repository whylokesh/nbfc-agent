-- PostgreSQL Schema for NBFC Loan Leads
-- This table is designed to store the critical, flattened data points from a loan application
-- for use in RAG (Retrieval-Augmented Generation) and Agentic AI applications.

DROP TABLE IF EXISTS nbfc_loan_leads;

CREATE TABLE nbfc_loan_leads (
    -- Primary Identification
    lead_id TEXT PRIMARY KEY,                       -- Corresponds to requestReferenceNumber
    unique_identifier TEXT NOT NULL,                -- Unique technical ID
    
    -- Loan Details
    product_type VARCHAR(10) NOT NULL,              -- e.g., LAP, HL, PL
    loan_amount_requested NUMERIC(15, 2) NOT NULL,  -- Loan requested in INR
    loan_tenure_months INTEGER NOT NULL,            -- Tenure in months
    loan_purpose_desc TEXT,                         -- Descriptive purpose of the loan
    sourcing_channel VARCHAR(50),                   -- e.g., DIRECT, DSA
    
    -- Applicant Details (Main Applicant / Hirer)
    applicant_name VARCHAR(100),
    applicant_monthly_income NUMERIC(12, 2),        -- Monthly income (HRA in this case)
    applicant_cibil_score VARCHAR(10),              -- Primary risk indicator (The string '000-1' means no history)
    
    -- Collateral Details (for LAP/HL)
    collateral_type VARCHAR(50),                    -- e.g., Property, Gold
    property_market_value NUMERIC(15, 2),           -- Fair Market Value of the asset
    property_pincode VARCHAR(10),
    
    -- Risk & Status
    next_followup_date DATE,                        -- Date for the next planned action/contact
    has_co_applicant BOOLEAN DEFAULT FALSE
);

-- ---------------------------------------------
-- Sample Data Insertion
-- ---------------------------------------------

-- Record 1: Derived from the provided JSON data (Raj Ram / Jaisa Ram)
INSERT INTO nbfc_loan_leads (
    lead_id, unique_identifier, product_type, loan_amount_requested, loan_tenure_months, 
    loan_purpose_desc, sourcing_channel, applicant_name, applicant_monthly_income, 
    applicant_cibil_score, collateral_type, property_market_value, property_pincode, 
    next_followup_date, has_co_applicant
) VALUES (
    '777777777777',
    '55555555555629',
    'LAP',
    200000.00,
    48,
    'Applicant Need Fund For House Renovation Purpose.',
    'DIRECT',
    'Raj Ram', -- Primary applicant name
    15250.00,
    '000-1',
    'Property',
    732300.00,
    '335703',
    '2025-11-04',
    TRUE
);

-- Record 2: Sample High-Value Loan, Good CIBIL
INSERT INTO nbfc_loan_leads (
    lead_id, unique_identifier, product_type, loan_amount_requested, loan_tenure_months, 
    loan_purpose_desc, sourcing_channel, applicant_name, applicant_monthly_income, 
    applicant_cibil_score, collateral_type, property_market_value, property_pincode, 
    next_followup_date, has_co_applicant
) VALUES (
    '888888888888',
    '600000000001',
    'HL',
    5000000.00,
    240,
    'Purchase of New Residential Flat in Metro City.',
    'DSA',
    'Amit Sharma',
    185000.00,
    '00810',
    'Property',
    7500000.00,
    '400001',
    '2025-11-06',
    TRUE
);

-- Record 3: Sample Small Business Loan, Low CIBIL
INSERT INTO nbfc_loan_leads (
    lead_id, unique_identifier, product_type, loan_amount_requested, loan_tenure_months, 
    loan_purpose_desc, sourcing_channel, applicant_name, applicant_monthly_income, 
    applicant_cibil_score, collateral_type, property_market_value, property_pincode, 
    next_followup_date, has_co_applicant
) VALUES (
    '999999999999',
    '600000000002',
    'PL',
    150000.00,
    36,
    'Working capital for small manufacturing unit.',
    'BRANCH',
    'Priya Singh',
    45000.00,
    '00615',
    'N/A', -- Personal Loan does not require collateral
    NULL,
    '110007',
    '2025-11-10',
    FALSE
);

-- Record 4: Sample Gold Loan (GL)
INSERT INTO nbfc_loan_leads (
    lead_id, unique_identifier, product_type, loan_amount_requested, loan_tenure_months, 
    loan_purpose_desc, sourcing_channel, applicant_name, applicant_monthly_income, 
    applicant_cibil_score, collateral_type, property_market_value, property_pincode, 
    next_followup_date, has_co_applicant
) VALUES (
    '111111111111',
    '600000000003',
    'GL',
    50000.00,
    12,
    'Urgent medical expense.',
    'WALK-IN',
    'Mohan Kuma',
    35000.00,
    '00780',
    'Gold',
    60000.00,
    '560002',
    '2025-11-05',
    FALSE
);

-- Record 5: Sample High-Income Personal Loan (PL)
INSERT INTO nbfc_loan_leads (
    lead_id, unique_identifier, product_type, loan_amount_requested, loan_tenure_months, 
    loan_purpose_desc, sourcing_channel, applicant_name, applicant_monthly_income, 
    applicant_cibil_score, collateral_type, property_market_value, property_pincode, 
    next_followup_date, has_co_applicant
) VALUES (
    '222222222222',
    '600000000004',
    'PL',
    500000.00,
    60,
    'Consolidation of existing high-interest debts.',
    'DIRECT',
    'Suman Rao',
    98000.00,
    '00825',
    'N/A', 
    NULL,
    '411001',
    '2025-11-07',
    TRUE
);


INSERT INTO nbfc_loan_leads (
    lead_id, unique_identifier, product_type, loan_amount_requested, loan_tenure_months, 
    loan_purpose_desc, sourcing_channel, applicant_name, applicant_monthly_income, 
    applicant_cibil_score, collateral_type, property_market_value, property_pincode, 
    next_followup_date, has_co_applicant
) VALUES 
('888888888888', '600000000001', 'HL', 5000000.00, 240, 'Purchase of New Residential Flat in Metro City.', 'DSA', 'Amit Sharma', 185000.00, '00810', 'Property', 7500000.00, '400001', '2025-11-06', TRUE),
('999999999999', '600000000002', 'PL', 150000.00, 36, 'Working capital for small manufacturing unit.', 'BRANCH', 'Priya Singh', 45000.00, '00615', 'N/A', NULL, '110007', '2025-11-10', FALSE),
('111111111111', '600000000003', 'GL', 50000.00, 12, 'Urgent medical expense.', 'WALK-IN', 'Mohan Kuma', 35000.00, '00780', 'Gold', 60000.00, '560002', '2025-11-05', FALSE),
('222222222222', '600000000004', 'PL', 500000.00, 60, 'Consolidation of existing high-interest debts.', 'DIRECT', 'Suman Rao', 98000.00, '00825', 'N/A', NULL, '411001', '2025-11-07', TRUE),
('1000000001', '7000000001', 'PL', 450000.00, 48, 'Education fees for children.', 'ONLINE', 'Deepak Jain', 72000.00, '00750', 'N/A', NULL, '600020', '2025-11-08', FALSE),
('1000000002', '7000000002', 'HL', 6500000.00, 300, 'New home construction.', 'DSA', 'Meena Varma', 195000.00, '00820', 'Property', 9000000.00, '400080', '2025-11-06', TRUE),
('1000000003', '7000000003', 'LAP', 1200000.00, 180, 'Business expansion capital.', 'BRANCH', 'Sameer Khan', 85000.00, '00680', 'Property', 2500000.00, '500034', '2025-11-12', TRUE),
('1000000004', '7000000004', 'GL', 150000.00, 12, 'Wedding expenses.', 'WALK-IN', 'Kavita Reddy', 30000.00, '000-1', 'Gold', 200000.00, '110085', '2025-11-05', FALSE),
('1000000005', '7000000005', 'PL', 80000.00, 24, 'Purchase of new electronic equipment.', 'DIRECT', 'Alok Tripathi', 42000.00, '00710', 'N/A', NULL, '335703', '2025-11-09', FALSE),
('1000000006', '7000000006', 'PL', 600000.00, 60, 'Travel and vacation fund.', 'ONLINE', 'Riya Deshmukh', 110000.00, '00790', 'N/A', NULL, '700015', '2025-11-11', TRUE),
('1000000007', '7000000007', 'HL', 3500000.00, 240, 'Refinance existing high-interest housing loan.', 'DSA', 'Rohan Bansal', 160000.00, '00835', 'Property', 5000000.00, '400053', '2025-11-06', FALSE),
('1000000008', '7000000008', 'LAP', 2500000.00, 120, 'Medical facility upgrade for clinic.', 'BRANCH', 'Sneha Patil', 140000.00, '00740', 'Property', 4000000.00, '560066', '2025-11-04', TRUE),
('1000000009', '7000000009', 'GL', 75000.00, 6, 'Clear utility bills.', 'WALK-IN', 'Vijay Yadav', 25000.00, '000-1', 'Gold', 100000.00, '600003', '2025-11-05', FALSE),
('1000000010', '7000000010', 'PL', 1000000.00, 60, 'Funding a startup venture.', 'DIRECT', 'Neha Aggarwal', 150000.00, '00650', 'N/A', NULL, '110055', '2025-11-10', TRUE),
('1000000011', '7000000011', 'HL', 9000000.00, 300, 'Vacation home purchase.', 'DSA', 'Kunal Shah', 250000.00, '00800', 'Property', 12000000.00, '400078', '2025-11-07', TRUE),
('1000000012', '7000000012', 'LAP', 4000000.00, 180, 'Purchase of commercial office space.', 'ONLINE', 'Pooja Iyer', 180000.00, '00770', 'Property', 6000000.00, '500001', '2025-11-08', FALSE),
('1000000013', '7000000013', 'GL', 30000.00, 12, 'Small emergency fund.', 'BRANCH', 'Suresh Rao', 28000.00, '00700', 'Gold', 40000.00, '560004', '2025-11-12', FALSE),
('1000000014', '7000000014', 'PL', 250000.00, 36, 'New car down payment.', 'WALK-IN', 'Fatima Begum', 55000.00, '000-1', 'N/A', NULL, '110018', '2025-11-05', TRUE),
('1000000015', '7000000015', 'PL', 900000.00, 60, 'Home appliance purchase.', 'DIRECT', 'Ganesh Nair', 125000.00, '00815', 'N/A', NULL, '411009', '2025-11-07', FALSE),
('1000000016', '7000000016', 'HL', 4200000.00, 300, 'Adding a new floor to existing house.', 'ONLINE', 'Harpreet Kaur', 155000.00, '00760', 'Property', 6000000.00, '700091', '2025-11-08', TRUE),
('1000000017', '7000000017', 'LAP', 1800000.00, 120, 'Consolidating business debts.', 'DSA', 'Imran Qureshi', 115000.00, '00730', 'Property', 3000000.00, '500081', '2025-11-09', FALSE),
('1000000018', '7000000018', 'GL', 450000.00, 12, 'Investment in stock market.', 'BRANCH', 'Jasmine Dsouza', 65000.00, '000-1', 'Gold', 550000.00, '400064', '2025-11-10', TRUE),
('1000000019', '7000000019', 'PL', 150000.00, 36, 'Purchase of musical instruments.', 'WALK-IN', 'Kartik Menon', 48000.00, '00690', 'N/A', NULL, '560008', '2025-11-11', FALSE),
('1000000020', '7000000020', 'HL', 7000000.00, 240, 'New luxury apartment purchase.', 'DIRECT', 'Latika Kapoor', 210000.00, '00840', 'Property', 9500000.00, '110008', '2025-11-04', TRUE),
('1000000021', '7000000021', 'LAP', 3000000.00, 180, 'Daughter''s higher education funding.', 'ONLINE', 'Manish Verma', 130000.00, '00755', 'Property', 5000000.00, '411045', '2025-11-06', TRUE),
('1000000022', '7000000022', 'GL', 120000.00, 6, 'Seasonal business inventory purchase.', 'DSA', 'Nandini Joshi', 40000.00, '00725', 'Gold', 150000.00, '500007', '2025-11-09', FALSE),
('1000000023', '7000000023', 'PL', 400000.00, 48, 'Renovation of parent''s home.', 'BRANCH', 'Omkar Singh', 78000.00, '00805', 'N/A', NULL, '700001', '2025-11-10', FALSE),
('1000000024', '7000000024', 'HL', 5500000.00, 300, 'First-time home buyer.', 'WALK-IN', 'Preeti Sharma', 170000.00, '00785', 'Property', 7500000.00, '400014', '2025-11-07', TRUE),
('1000000025', '7000000025', 'LAP', 500000.00, 60, 'Small scale machine purchase.', 'DIRECT', 'Qasim Ali', 60000.00, '00670', 'Property', 1000000.00, '335703', '2025-11-08', FALSE),
('1000000026', '7000000026', 'GL', 90000.00, 12, 'Travel expenses for international trip.', 'ONLINE', 'Rashmi Pillai', 38000.00, '000-1', 'Gold', 120000.00, '600006', '2025-11-05', FALSE),
('1000000027', '7000000027', 'PL', 300000.00, 36, 'Car repair and maintenance.', 'DSA', 'Sanjay Gupta', 62000.00, '00705', 'N/A', NULL, '110049', '2025-11-06', TRUE),
('1000000028', '7000000028', 'HL', 2500000.00, 180, 'Residential plot purchase.', 'BRANCH', 'Tanvi Kulkarni', 120000.00, '00830', 'Property', 4000000.00, '411028', '2025-11-12', TRUE),
('1000000029', '7000000029', 'LAP', 2200000.00, 120, 'Renovation of rental property.', 'WALK-IN', 'Umesh Bhatt', 95000.00, '00745', 'Property', 3500000.00, '560001', '2025-11-04', FALSE),
('1000000030', '7000000030', 'GL', 60000.00, 6, 'School fee payment.', 'DIRECT', 'Varun Kumar', 32000.00, '00715', 'Gold', 80000.00, '400001', '2025-11-09', FALSE),
('1000000031', '7000000031', 'PL', 700000.00, 60, 'Starting a coaching center.', 'ONLINE', 'Walia Khan', 105000.00, '00825', 'N/A', NULL, '700088', '2025-11-10', TRUE),
('1000000032', '7000000032', 'HL', 4800000.00, 300, 'Home extension project.', 'DSA', 'Xavier Dsouza', 165000.00, '00765', 'Property', 6500000.00, '400020', '2025-11-06', TRUE),
('1000000033', '7000000033', 'LAP', 3500000.00, 180, 'Purchase of heavy machinery for factory.', 'BRANCH', 'Yasmin Ahmed', 145000.00, '00735', 'Property', 5500000.00, '500033', '2025-11-07', FALSE),
('1000000034', '7000000034', 'GL', 200000.00, 12, 'Daughter''s college admission.', 'WALK-IN', 'Zara Singh', 50000.00, '000-1', 'Gold', 250000.00, '110002', '2025-11-08', TRUE),
('1000000035', '7000000035', 'PL', 550000.00, 48, 'Home office setup.', 'DIRECT', 'Abhay Mishra', 88000.00, '00685', 'N/A', NULL, '411001', '2025-11-11', FALSE),
('1000000036', '7000000036', 'HL', 8500000.00, 300, 'Second property investment.', 'ONLINE', 'Bipasha Basu', 240000.00, '00845', 'Property', 11000000.00, '600010', '2025-11-12', TRUE),
('1000000037', '7000000037', 'LAP', 1500000.00, 120, 'Working capital for retail store.', 'DSA', 'Cyrus Poonawalla', 90000.00, '00795', 'Property', 2800000.00, '500045', '2025-11-04', FALSE),
('1000000038', '7000000038', 'GL', 250000.00, 6, 'Agricultural machinery purchase.', 'BRANCH', 'Divya Goswami', 58000.00, '00720', 'Gold', 320000.00, '560006', '2025-11-09', TRUE),
('1000000039', '7000000039', 'PL', 100000.00, 24, 'Debt settlement.', 'WALK-IN', 'Eshaan Shetty', 40000.00, '00710', 'N/A', NULL, '110020', '2025-11-05', FALSE),
('1000000040', '7000000040', 'HL', 3000000.00, 240, 'Inherited property renovation.', 'DIRECT', 'Farhan Ali', 135000.00, '00810', 'Property', 4500000.00, '400001', '2025-11-10', TRUE),
('1000000041', '7000000041', 'LAP', 4500000.00, 180, 'Expansion of IT consultancy.', 'ONLINE', 'Geeta Shah', 190000.00, '00750', 'Property', 7000000.00, '411002', '2025-11-06', TRUE),
('1000000042', '7000000042', 'GL', 100000.00, 12, 'Travel for elderly parents.', 'DSA', 'Hari Patel', 30000.00, '000-1', 'Gold', 130000.00, '500050', '2025-11-07', FALSE),
('1000000043', '7000000043', 'PL', 200000.00, 36, 'Purchase of two-wheeler vehicle.', 'BRANCH', 'Indira Bose', 52000.00, '00690', 'N/A', NULL, '700005', '2025-11-08', FALSE),
('1000000044', '7000000044', 'HL', 6000000.00, 300, 'Joint family home purchase.', 'WALK-IN', 'Javed Mirza', 188000.00, '00830', 'Property', 8500000.00, '400018', '2025-11-09', TRUE),
('1000000045', '7000000045', 'LAP', 800000.00, 60, 'Daughter''s wedding expenses.', 'DIRECT', 'Kalpana Rao', 75000.00, '00770', 'Property', 1500000.00, '335703', '2025-11-10', FALSE),
('1000000046', '7000000046', 'PL', 350000.00, 48, 'Emergency car replacement.', 'ONLINE', 'Lalit Mishra', 65000.00, '00740', 'N/A', NULL, '110005', '2025-11-11', TRUE),
('1000000047', '7000000047', 'HL', 5200000.00, 240, 'Relocation to new city.', 'DSA', 'Mona Gupta', 175000.00, '00800', 'Property', 7000000.00, '560010', '2025-11-04', TRUE),
('1000000048', '7000000048', 'LAP', 2800000.00, 180, 'Upgrade machinery for textile business.', 'BRANCH', 'Naresh Tandon', 122000.00, '00720', 'Property', 4200000.00, '400070', '2025-11-05', FALSE),
('1000000049', '7000000049', 'GL', 180000.00, 12, 'Investment in mutual funds.', 'WALK-IN', 'Pooja Bhatt', 40000.00, '000-1', 'Gold', 240000.00, '700025', '2025-11-12', TRUE),
('1000000050', '7000000050', 'PL', 650000.00, 60, 'Medical procedure funding.', 'DIRECT', 'Rahul Sharma', 92000.00, '00780', 'N/A', NULL, '411030', '2025-11-07', FALSE);