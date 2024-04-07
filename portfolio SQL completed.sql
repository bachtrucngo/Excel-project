

                        /*SQL practice with PayTM database*/

/* Skills used: Joins, CTE's, Subqueries, Aggregate Functions, Window Functions, Converting Data Type, Temp Table, Creating Views
--Database provider: @Mazhocdata https://madzynguyen.com/khoa-hoc-practical-sql-for-data-analytics/
Database explanation
Paytm is an Indian multinational financial technology company. It specializes in digital payment systems, e-commerce and financial services.
Paytm wallet is a secure and RBI (Reserve Bank of India)-approved digital/mobile wallet that provides a myriad of financial features to fulfill every consumer’s payment needs.
Paytm wallet can be topped up through UPI (Unified Payments Interface), internet banking, or credit/debit cards.
Users can also transfer money from a Paytm wallet to the recipient's bank account or their own Paytm wallet.
I have practiced on a small database of payment transactions from 2019 to 2020 of Paytm Wallet. The database includes 6 tables:
●   fact_transaction: Store information of all types of transactions: Payments, Top-up, Transfers, Withdrawals, with the list of columns: transaction_id, customer_id, scenario_id, payment_channel_id, promotion_id, platform_id, status_id, original_price, discount_value, charged_amount, transaction_time
●   dim_scenario: Detailed description of transaction types, with columns: scenario_id, transaction_type, sub_category, category
●   dim_payment_channel: Detailed description of payment methods, including columns: payment_channel_id, payment_method
●   dim_platform: Detailed description of payment devices, with columns: playform_id, payment_platform
●   dim_status: Detailed description of the results of the transaction: status_id, status_description
*/



-- JOIN tables
-- Retrieve a report that includes the following information: customer_id, transaction_id, scenario_id, transaction_type, sub_category, category which :
-- Were created in Jan 2019 and Transaction type is not payment

SELECT customer_id
    , transaction_id
    , tran2019.scenario_id
    , transaction_type
    , scenario.sub_category
    , scenario.category
FROM Fact_transaction_2019 AS tran2019 FULL JOIN Dim_scenario AS scenario
ON tran2019.scenario_id = scenario.scenario_id 
WHERE Transaction_type != 'payment';



--JOIN more than 2 tables 
--Retrieve a report that includes the following information: customer_id, transaction_id, scenario_id, transaction_type, category, payment_method. With following conditions: 
--(1)created from Jan to June 2019
--(2)category type is shopping
--(3)paid by Bank account

SELECT tran2019.customer_id    
	, tran2019.transaction_id    
	, tran2019.scenario_id    
	, scenario.transaction_type    
	, scenario.category    
	, payment_method
FROM Fact_transaction_2019 AS tran2019 
	INNER JOIN Dim_scenario AS scenario
ON tran2019.scenario_id = scenario.scenario_id
	INNER JOIN Dim_payment_channel AS channel
ON tran2019.payment_channel_id = channel.payment_channel_id
WHERE MONTH (transaction_time) BETWEEN 1 AND 6
AND scenario.category = 'shopping'
AND channel.payment_method = 'Bank account';



--Using CTES, Subquery, Aggregate functions, GROUP BY, ORDER BY
--Top 5 types with the highest percentage of each transaction type to total of transactions 
--Transaction type, number of transactions and proportion of each type in total, with these 2 requirements:
--(1) Created in 2019 
--(2) Successfully paid

WITH joined_table AS (
   SELECT fact_19.*
       , transaction_type
   FROM fact_transaction_2019 AS fact_19 
   LEFT JOIN dim_scenario AS scen
       ON fact_19.scenario_id = scen.scenario_id
   LEFT JOIN dim_status AS stat
       ON fact_19.status_id = stat.status_id
   WHERE status_description = 'success'
)

, total_table AS (
   SELECT transaction_type
       , COUNT (transaction_id) AS number_trans
       , ( SELECT COUNT (transaction_id) FROM  joined_table ) AS total_trans 
   FROM joined_table
   GROUP BY transaction_type
)

SELECT TOP 5 *
  , FORMAT ( CAST ( number_trans AS FLOAT ) / total_trans, 'p') as pct
FROM total_table
ORDER BY number_trans DESC;



--Top 10 highest total accumulate amount customers successfully made payment transactions in 2019
WITH table_join as (
   SELECT trans.*, transaction_type, category
   FROM fact_transaction_2019 as trans
   LEFT JOIN dim_scenario as sce
       ON sce.scenario_id = trans.scenario_id
   LEFT JOIN dim_status as stat
       ON trans.status_id = stat.status_id
   WHERE status_description = 'success'
       AND transaction_type = 'payment'
    
)
SELECT TOP 10 customer_id
   , COUNT (transaction_id) as number_trans
   , COUNT (distinct scenario_id) as number_sce
   , COUNT (distinct category) as number_category
   , SUM ( CAST(charged_amount AS BIGINT) ) as total_amount
FROM table_join
GROUP BY customer_id
ORDER BY total_amount DESC;

--Using Temp Table TOP_10_2019_successful from the previous query
WITH table_join AS (
   SELECT trans.*, transaction_type, category
   FROM fact_transaction_2019 AS trans
   LEFT JOIN dim_scenario AS sce ON sce.scenario_id = trans.scenario_id
   LEFT JOIN dim_status AS stat ON trans.status_id = stat.status_id
   WHERE status_description = 'success'
       AND transaction_type = 'payment'
)
SELECT TOP 10 
    customer_id,
    COUNT(transaction_id) AS number_trans,
    COUNT(DISTINCT scenario_id) AS number_sce,
    COUNT(DISTINCT category) AS number_category,
    SUM(CAST(charged_amount AS BIGINT)) AS total_amount
INTO #TOP_10_2019
FROM table_join
GROUP BY customer_id
ORDER BY total_amount DESC;

--Creating View TOP_10_2019_successful from the previous query to store data for later visualizations

CREATE VIEW TOP_10_2019 AS 
WITH table_join AS (
   SELECT trans.*, transaction_type, category
   FROM fact_transaction_2019 AS trans
   LEFT JOIN dim_scenario AS sce ON sce.scenario_id = trans.scenario_id
   LEFT JOIN dim_status AS stat ON trans.status_id = stat.status_id
   WHERE status_description = 'success'
       AND transaction_type = 'payment'
)
SELECT TOP 10 
    customer_id,
    COUNT(transaction_id) AS number_trans,
    COUNT(DISTINCT scenario_id) AS number_sce,
    COUNT(DISTINCT category) AS number_category,
    SUM(CAST(charged_amount AS BIGINT)) AS total_amount
FROM table_join
GROUP BY customer_id
ORDER BY total_amount DESC;

--Top 10 highest total accumulate amount customers who have unsuccessful payment and shown withdraw status in 2019

WITH table_join as (
   SELECT trans.*, transaction_type, category
   FROM fact_transaction_2019 as trans
   LEFT JOIN dim_scenario as sce
       ON sce.scenario_id = trans.scenario_id
   LEFT JOIN dim_status as stat
       ON trans.status_id = stat.status_id
   WHERE status_description != 'payment fail'
       AND transaction_type != 'withdraw'
    
)
SELECT TOP 10 customer_id
   , COUNT (transaction_id) as number_trans
   , COUNT (distinct scenario_id) as number_sce
   , COUNT (distinct category) as number_category
   , SUM ( CAST(charged_amount AS BIGINT) ) as total_amount
FROM table_join
GROUP BY customer_id
ORDER BY total_amount DESC;



--Using WINDOW FUNCTIONS to Calculate the number of success "Electricity" bill transactions and total charged amount per month in 2020
SELECT DISTINCT YEAR (transaction_time) AS [year]
   , MONTH (transaction_time) AS [month]
   , COUNT (transaction_id) OVER ( PARTITION BY MONTH (transaction_time) ) AS number_trans_month
   , SUM ( CAST (charged_amount AS BIGINT ) ) OVER ( PARTITION BY MONTH (transaction_time) ) AS total_amount
FROM fact_transaction_2020 AS trans
LEFT JOIN dim_scenario as sce
       ON sce.scenario_id = trans.scenario_id
LEFT JOIN dim_status as stat
       ON trans.status_id = stat.status_id
WHERE status_description = 'success'   
   AND sub_category = 'Electricity'





--Using WINDOW FUNCTIONS and CASE WHEN...THEN..END to calculate the number of successful transactions of each category (Electricity, Internet, and Water) in 2019 and 2020.
SELECT DISTINCT YEAR (transaction_time) [year]
	, MONTH (transaction_time) [month]
	, COUNT ( CASE WHEN sub_category = 'electricity' THEN transaction_id END ) OVER ( PARTITION BY YEAR (transaction_time), MONTH (transaction_time)) AS electricity_trans
	, COUNT ( CASE WHEN sub_category = 'water' THEN transaction_id END ) OVER ( PARTITION BY YEAR (transaction_time), MONTH (transaction_time)) AS water_trans
	, COUNT ( CASE WHEN sub_category = 'internet' THEN transaction_id END ) OVER ( PARTITION BY YEAR (transaction_time), MONTH (transaction_time))  AS internet_trans
FROM  ( select* from fact_transaction_2019 union select* from fact_transaction_2020) AS trans
LEFT JOIN dim_scenario as sce
      ON sce.scenario_id = trans.scenario_id
LEFT JOIN dim_status as stat
      ON trans.status_id = stat.status_id
WHERE sce.category = 'billing'
      AND stat.status_description = 'success'
      AND sub_category in ('electricity','water','internet')
ORDER BY [year] ASC, [month] ASC



--The number of successful payment transactions with promotion on Electricity bill on a weekly basis and account for how much of the total number of successful payment transactions in 2020

SELECT DATEPART ( week, transaction_time) AS week_number
	    , COUNT ( CASE WHEN promotion_id <> '0' THEN transaction_id END ) AS promotion_trans
	    , COUNT (transaction_id) AS total_trans
		, FORMAT ( CAST ( COUNT ( CASE WHEN promotion_id <> '0' THEN transaction_id END ) AS FLOAT ) / COUNT (transaction_id) , 'p') AS promotion_ratio
   From fact_transaction_2020 As fact20
   LEFT JOIN dim_scenario as sce
           ON sce.scenario_id = fact20.scenario_id
   Where sub_category = 'Electricity' and status_id = 1
   GROUP BY  DATEPART ( week, transaction_time)
   ORDER BY week_number

