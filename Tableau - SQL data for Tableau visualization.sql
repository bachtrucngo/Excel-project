




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
WHERE transaction_type IS NOT NULL
ORDER BY number_trans DESC;





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





--Calculate the number of successful transactions of each month in 2019 and 2020 using GROUP BY and WINDOWN FUNCTIONS
WITH table_trans AS
(
SELECT YEAR (transaction_time) AS [year]
    , MONTH (transaction_time) AS [month]
    , COUNT (transaction_id) AS number_successful_trans
FROM (SELECT * FROM fact_transaction_2019 UNION SELECT * FROM fact_transaction_2020) AS trans
 LEFT JOIN dim_status AS [status]
ON trans.status_id = status.status_id
WHERE status_description = 'success'
GROUP BY YEAR (transaction_time) , MONTH (transaction_time)
)
, table_total_year AS
(
SELECT *
    , SUM (number_successful_trans) OVER (PARTITION BY [YEAR] ) AS total_trans_year
    FROM table_trans
)
SELECT *
    , FORMAT (CAST ([number_successful_trans] AS FLOAT) / total_trans_year, 'P' ) AS pct
FROM table_total_year





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