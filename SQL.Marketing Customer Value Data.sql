-- https://www.kaggle.com/datasets/pankajjsh06/ibm-watson-marketing-customer-value-data

SELECT *
FROM customers;

CREATE TABLE cus AS
SELECT *
FROM customers;

SELECT * 
FROM cus;

-- Identifying NULL values

SELECT * 
FROM cus
	WHERE Customer IS NULL OR Customer = ''
    OR State IS NULL OR Customer = ''
	OR `Customer Lifetime Value` IS NULL OR `Customer Lifetime Value` = ''
    OR Response IS NULL OR Response = ''
    OR Coverage IS NULL OR Coverage = ''
    OR Education IS NULL OR Education = ''
    OR `Effective To Date` IS NULL OR `Effective To Date` = ''
    OR EmploymentStatus IS NULL OR EmploymentStatus = ''
    OR Gender IS NULL OR  Gender = ''
    OR Income IS NULL OR Income = ''
    OR `Location Code` IS NULL OR `Location Code` = ''
    OR `Marital Status` IS NULL OR `Marital Status` = ''
    OR `Monthly Premium Auto` IS NULL OR `Monthly Premium Auto` = ''
    OR `Months Since Last Claim` IS NULL OR `Months Since Last Claim` = ''
    OR `Months Since Policy Inception` IS NULL OR `Months Since Policy Inception` = ''
    OR `Number of Open Complaints` IS NULL OR `Number of Open Complaints` = ''
    OR `Number of Policies` IS NULL OR `Number of Policies` = ''
    OR `Policy Type` IS NULL OR `Policy Type` = ''
    OR Policy IS NULL OR Policy = ''
    OR `Renew Offer Type` IS NULL OR  `Renew Offer Type` = ''
    OR `Sales Channel` IS NULL OR `Sales Channel` = ''
    OR `Total Claim Amount` IS NULL OR `Total Claim Amount` = ''
    OR `Vehicle Class` IS NULL OR `Vehicle Class` = ''
    OR `Vehicle Size` IS NULL OR `Vehicle Size` = ''
    ;
    
    -- It's allright. There are 0s only in Number of Open Complaints, which is logical.
    
    -- Let's check duplicates. 
    SELECT * 
    FROM cus
   ;
   
   WITH ranked_cus AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY 
               Customer, State, `Customer Lifetime Value`, Response, Coverage, Education, 
               `Effective To Date`, EmploymentStatus, Gender, Income, 
               `Location Code`, `Marital Status`, `Monthly Premium Auto`, 
               `Months Since Last Claim`, `Months Since Policy Inception`, 
               `Number of Open Complaints`, `Number of Policies`, `Policy Type`, 
               Policy, `Renew Offer Type`, `Sales Channel`, `Total Claim Amount`, 
               `Vehicle Class`, `Vehicle Size` 
           ORDER BY Customer) AS rn
    FROM cus
)
SELECT * FROM ranked_cus WHERE rn > 1;

-- No duplicates. 
   
   SELECT * 
   FROM cus;
   
   
   
   -- Want to check if there are mistypes or inconsistencies in the "State" column.
   
   SELECT DISTINCT State 
   FROM cus
   ORDER BY State;
   
   -- All clean. 
   
   -- I dont like the format of "Effective To Date" column. Lets change it.
   
UPDATE cus
SET `Effective To Date` = DATE_FORMAT(STR_TO_DATE(`Effective To Date`, '%m/%d/%y'), '%d-%m-%Y');

SELECT DISTINCT `Effective To Date`
FROM cus;


-- Done with Data cleaning, next to EDA

-- Lets play around with theories. 
-- I have a theory that higher income customers might have a higher CLV, lets check

-- Calculating averages:
SELECT 
    AVG(Income) AS AvgIncome, 
    AVG(`Customer Lifetime Value`) AS AvgCLV
FROM cus;

-- Calculating the covariance and standart deviations:
SELECT 
    SUM((Income - @AvgIncome) * (`Customer Lifetime Value` - @AvgCLV)) AS Covariance,
    SQRT(SUM(POW(Income - @AvgIncome, 2))) AS StdDevIncome,
    SQRT(SUM(POW(`Customer Lifetime Value` - @AvgCLV, 2))) AS StdDevCLV
FROM cus
CROSS JOIN (
    SELECT 
        AVG(Income) AS AvgIncome, 
        AVG(`Customer Lifetime Value`) AS AvgCLV
    FROM cus
) AS Averages;

-- Getting NULL values
-- Let's try to do it manually:
SET @AvgIncome = 37657.3800;
SET @AvgCLV = 8004.9405;

SELECT 
    SUM((Income - @AvgIncome) * (`Customer Lifetime Value` - @AvgCLV)) AS Covariance
FROM cus;

-- Getting NULL values 
-- Lets check again gor NULLs in Income and Customer Lifetime Value

SELECT 
    COUNT(*) AS TotalRecords,
    SUM(Income IS NULL) AS NullIncome,
    SUM(`Customer Lifetime Value` IS NULL) AS NullCLV
FROM cus;

-- Output: NullIncome NULL, NullCLV NULL. All OK 
-- Trying to fix this:

SELECT 
    AVG(Income) AS AvgIncome, 
    AVG(`Customer Lifetime Value`) AS AvgCLV
FROM cus;

SET @AvgIncome = (SELECT AVG(Income) FROM cus);
SET @AvgCLV = (SELECT AVG(`Customer Lifetime Value`) FROM cus);

SELECT 
    SUM((Income - @AvgIncome) * (`Customer Lifetime Value` - @AvgCLV)) AS Covariance
FROM cus;

-- Got it. Covariance = 46451095361.273155
-- Now I need to calculate standart deviations of Income and CLV

SELECT 
    SQRT(SUM(POW(Income - @AvgIncome, 2)) / COUNT(*)) AS StdDevIncome
FROM cus;


SELECT 
    SQRT(SUM(POW(`Customer Lifetime Value` - @AvgCLV, 2)) / COUNT(*)) AS StdDevCLV
FROM cus;

-- Output: StdDevIncome 30378.241676243688, StdDevCLV 6870.591477654129
-- Calculating Correlation:

SELECT 
    46451095361.273155 / (30378.241676243688 * 6870.591477654129) AS Income_CLV_Correlation;

-- Output: 222.5559452668
-- However, this value seems unusually high because the Pearson correlation 
-- coefficient is typically a value between -1 and 1
-- Lets try to fix this. Correcting calculation formula:

SET @AvgIncome = 37657.3800;
SET @AvgCLV = 8004.9404749870755;

SELECT 
    SUM((Income - @AvgIncome) * (`Customer Lifetime Value` - @AvgCLV)) / COUNT(*) AS Covariance
FROM cus;

-- Covariance 5085515.147938857. Much more reasonable.
-- Recalculating correlation: 

SELECT 
    5085515.147938857 / (30378.241676243688 * 6870.591477654129) AS Income_CLV_Correlation;
    
-- The slight positive value suggests that there might be a tiny, almost negligible positive
-- relationship between Income and Customer Lifetime Value. However, it's so small that it 
-- can be considered practically insignificant.

-- Lets dig further
-- Lets try to see the relation between Sales Channel and CLV 

-- Lets calculate the average CLV for each channel:

SELECT 
    `Sales Channel`,
    AVG(`Customer Lifetime Value`) AS Avg_CLV
FROM 
    cus
GROUP BY 
    `Sales Channel`
ORDER BY 
    Avg_CLV DESC;

-- Output: Branch: 8119.71, Call Center: 8100.09, Agent: 7957.71, Web: 7779.79
-- This suggests that customers who interact directly at physical locations might 
-- have more loyalty or spend more over time.
-- The Web channel has the lowest average CLV at 7779.79. This might indicate that 
-- customers acquired online either have less engagement, lower spending, or possibly 
-- churn faster compared to other channels.

-- BUSINESS IMPLICATIONS: 1) optimizing branch and call center channels
-- 2) improving web and agent channels

-- Lets try to understand why the Web channel has a lower CLV.
-- Income distribution: 
SELECT 
    `Sales Channel`,
    AVG(Income) AS Avg_Income,
    MIN(Income) AS Min_Income,
    MAX(Income) AS Max_Income
FROM 
    cus
GROUP BY 
    `Sales Channel`;

-- Output: Sales Chanel - Agent, Avg_Income 37179.9494, Min_income 0, Max_income 99961
-- Sales Chanel - Call Center, Avg_Income 38424.9331, Min_income 0, Max_income 99875
-- Sales Chanel - Web, Avg_Income 38030.7275, Min_income 0, Max_income 99981
-- Sales Chanel - Branch, Avg_Income 37583.6011, Min_income 0, Max_income 99845

--  The income differences across sales channels are relatively small. 
-- Therefore, income alone may not be a significant factor in explaining 
-- the variation in CLV across channels.


-- Lets analyze CLV by Policy type within the Web sales channel

SELECT 
    `Policy Type`,
    AVG(`Customer Lifetime Value`) AS Avg_CLV
FROM 
    cus
WHERE 
    `Sales Channel` = 'Web'
GROUP BY 
    `Policy Type`
ORDER BY 
    Avg_CLV DESC;
    
-- Output: Special Auto: 8441.39, Personal Auto: 7783.60, Corporate Auto: 7622.80
-- BUSINESS IMPLICATIONS: 1) focus on high CLV policies, 2) investigate low CLV policies (why?)
-- 3) tailor strategies: special auto (offer additional incentives), 
-- personal and corporate auto (improvements)


-- Lets compare CLV by Policy type across all sales channels

SELECT 
    `Sales Channel`,
    `Policy Type`,
    AVG(`Customer Lifetime Value`) AS Avg_CLV
FROM 
    cus
GROUP BY 
    `Sales Channel`,
    `Policy Type`
ORDER BY 
    `Sales Channel`,
    `Policy Type`;


-- Special Auto tends to have the highest CLV across channels, with the highest being 
-- in the Agent channel. This indicates that customers who purchase Special Auto policies 
-- generally have higher lifetime values, especially when acquired through Agents.

-- Lets try to analyse CLV by demographic factors:
-- Analyze CLV by Income and Policy Type in each Sales Channel

-- Analyze CLV by Gender and Policy Type in each Sales Channel
SELECT
    `Sales Channel`,
    `Policy Type`,
    `Gender`,
    AVG(`Customer Lifetime Value`) AS Avg_CLV
FROM
    cus
GROUP BY
    `Sales Channel`,
    `Policy Type`,
    `Gender`
ORDER BY
    `Sales Channel`,
    `Policy Type`,
    `Gender`;
    
    -- What we see: 
    -- Male vs. Female CLV Trends:
-- Special Auto: Male customers generally have a higher CLV across most channels, except 
-- in the Web channel where female customers have a notably higher CLV.
-- Personal Auto: Female customers have higher CLV in the Call Center and Branch channels, 
-- while male customers have slightly higher CLV in the Web channel.
-- Corporate Auto: Males typically have higher CLV in the Branch and Call Center channels, 
-- but females have higher CLV in the Web channel.
-- Channel-Specific Trends:
-- Agents: Higher CLV for Special Auto policies, particularly for male customers.
-- Branch: Generally higher CLV for male customers in Corporate Auto and Special Auto policies.
-- Call Center: Higher CLV for females in Personal Auto, but males have slightly higher CLV for 
-- Special Auto.
-- Web: Female customers show significantly higher CLV for Special Auto and Corporate Auto 
-- policies.

-- !CHECK MY VISUALISATION IN TABLEAU 
