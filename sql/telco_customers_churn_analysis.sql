--database has created
--create the table
create table telco_churn (
    customerID       VARCHAR(20)     PRIMARY KEY,
    gender           VARCHAR(10),
    SeniorCitizen    SMALLINT,
    Partner          VARCHAR(5),
    Dependents       VARCHAR(5),
    tenure           INT,
    PhoneService     VARCHAR(5),
    MultipleLines    VARCHAR(30),
    InternetService  VARCHAR(30),
    OnlineSecurity   VARCHAR(30),
    OnlineBackup     VARCHAR(30),
    DeviceProtection VARCHAR(30),
    TechSupport      VARCHAR(30),
    StreamingTV      VARCHAR(30),
    StreamingMovies  VARCHAR(30),
    Contract         VARCHAR(20),
    PaperlessBilling VARCHAR(5),
    PaymentMethod    VARCHAR(50),
    MonthlyCharges   DECIMAL(8,2),
    TotalCharges     VARCHAR(20),    -- imported as TEXT, converted later
    Churn            VARCHAR(5)
);
--verify the data
select * from telco_churn limit 10;
--verify the import of all data
select count(*) as total_rows from telco_churn;--should be 7043 rows
/*
Data Cleaning Setup:-
Identified and Handled dirty columns
*/
--Add a Cleaned Numeric Column for TotalCharges
	--add a proper numeric column
alter table telco_churn add column TotalCharges_num decimal(10,2);
	--Convert TEXT  to numeric(empty string becomes NULL)
update telco_churn
set TotalCharges_num= case 
	when trim(TotalCharges)='' then null
	else cast(trim(TotalCharges) as decimal(10,2))
					  end;
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'telco_churn';
--renaming all columns to lowercase with _ between two words for easy to use
-- Identifiers & Demographics
ALTER TABLE telco_churn RENAME COLUMN "customerID" TO customer_id;
ALTER TABLE telco_churn RENAME COLUMN "SeniorCitizen" TO senior_citizen;

-- Services
ALTER TABLE telco_churn RENAME COLUMN "PhoneService" TO phone_service;
ALTER TABLE telco_churn RENAME COLUMN "MultipleLines" TO multiple_lines;
ALTER TABLE telco_churn RENAME COLUMN "InternetService" TO internet_service;
ALTER TABLE telco_churn RENAME COLUMN "OnlineSecurity" TO online_security;
ALTER TABLE telco_churn RENAME COLUMN "OnlineBackup" TO online_backup;
ALTER TABLE telco_churn RENAME COLUMN "DeviceProtection" TO device_protection;
ALTER TABLE telco_churn RENAME COLUMN "TechSupport" TO tech_support;
ALTER TABLE telco_churn RENAME COLUMN "StreamingTV" TO streaming_tv;
ALTER TABLE telco_churn RENAME COLUMN "StreamingMovies" TO streaming_movies;

-- Billing & Contract
ALTER TABLE telco_churn RENAME COLUMN "PaperlessBilling" TO paperless_billing;
ALTER TABLE telco_churn RENAME COLUMN "PaymentMethod" TO payment_method;
ALTER TABLE telco_churn RENAME COLUMN "MonthlyCharges" TO monthly_charges;
ALTER TABLE telco_churn RENAME COLUMN "TotalCharges" TO total_charges;
ALTER TABLE telco_churn RENAME COLUMN "Churn" TO churn; -- (Optional, for consistency)
ALTER TABLE telco_churn RENAME COLUMN "Partner" TO partner;
ALTER TABLE telco_churn RENAME COLUMN "Dependents" TO dependents;
ALTER TABLE telco_churn RENAME COLUMN "Contract" TO contract;

--verify
select customer_id,
	   total_charges,
	   totalcharges_num
from telco_churn
where totalcharges_num is null;-- 11 rows have blank totalcharges_num — these are new customers with 0 tenure
-- Explore the Data Before Writing Business Queries
--Overall Shape
select count(*) as total_customers,
	   count(case when churn='Yes' then 1 end) as churned,
	   count(case when churn='No' then 1 end) as retianed,
	   round(count(case when churn='Yes' then 1 end)*100.0
	   				/count(*),2) as churn_rate_pct
from telco_churn;

-- Check distinct values in key categorical columns:
select distinct contract from telco_churn order by 1;
/*
contract
"Month-to-month"
"One year"
"Two year"
*/
select distinct internet_service from telco_churn order by 1;
/*
internet_service
"DSL"
"Fiber optic"
"No"
*/
select distinct payment_method from telco_churn order by 1;
/*
payment_method
"Bank transfer (automatic)"
"Credit card (automatic)"
"Electronic check"
"Mailed check"
*/

-- Tenure distribution
select min(tenure)||' months' as min_tenure,
	   max(tenure)||' months' as max_tenure,
	   round(avg(tenure),2)||' months' as avg_tenure,
	   percentile_cont(0.5) within group(order by tenure)||' months' as median_tenure
from telco_churn;


