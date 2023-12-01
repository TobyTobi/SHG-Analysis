/* DATA CLEANING AND WRANGLING */


-- View the data table
SELECT * FROM SHG;

-- Unique values in Hotel column
SELECT DISTINCT Hotel
FROM SHG;
-- Resort and City

-- Unique values in Distribution Channel column
SELECT DISTINCT [Distribution Channel]
FROM SHG;
/* Online Travel Agent, Corporate,
Offline Travel Agent, Direct, Undefined */

-- Unique values in Customer Type column
SELECT DISTINCT [Customer Type]
FROM SHG;
/* Group, Contract, Transient, Transient-Party */

-- Unique values in Country column
SELECT DISTINCT Country
FROM SHG;
-- There are null values in country

-- Set null values in Country to 'Unknown'
UPDATE SHG
SET Country = 'Unknown'
WHERE Country IS NULL;
-- This affected 488 rows

-- Unique values in Deposit Type column
SELECT DISTINCT [Deposit Type]
FROM SHG;
/* No Deposit, Refundable, Non Refundable*/

-- Unique values in Status column
SELECT DISTINCT Status
FROM SHG;
/* Check-Out, No-Show, Canceled*/

-- Correct spellings of Check-Out and No-Show
UPDATE SHG
SET Status = 'Check Out'
WHERE Status = 'Check-Out';

UPDATE SHG
SET Status = 'No Show'
WHERE Status = 'No-Show';

-- Unique values in Canceled
SELECT DISTINCT [Cancelled (0/1)]
FROM SHG;
/* 0 and 1*/

-- Convert Booking Date, Arrival Date, Status Update to Date format
ALTER TABLE SHG
ALTER COLUMN [Booking Date] Date
ALTER TABLE SHG
ALTER COLUMN [Arrival Date] Date
ALTER TABLE SHG
ALTER COLUMN [Status Update] Date;


-- Combine Revenue and Revenue Loss columns since no need
UPDATE SHG
SET Revenue = [Revenue Loss]
WHERE [Revenue Loss] != 0;
-- 29617 rows affected


-- Drop Revenue Loss Column
ALTER TABLE SHG
DROP COLUMN [Revenue Loss];

-- Check for missing values
SELECT *
FROM SHG
WHERE [Booking Date] IS NULL
	OR [Arrival Date] IS NULL
	OR [Lead Time] IS NULL
	OR Nights IS NULL
	OR Guests IS NULL
	OR [Avg Daily Rate] IS NULL
	OR [Status Update] IS NULL
	OR Revenue IS NULL;
-- No NULL values

-- Check for invalid values in certain columns
SELECT *
FROM SHG
WHERE [Lead Time] < 0
	OR Nights < 0
	OR [Avg Daily Rate] < 0
	OR Guests <= 0
	AND Status NOT IN ('Canceled', 'No Show');
-- There was only one case (Booking ID 14970) where guests showed up and stayed and revenue was negative.
-- We have to correct that to make it positive because this was clearly an error

UPDATE SHG
SET Revenue = Revenue * -1, [Avg Daily Rate] = [Avg Daily Rate] * -1
WHERE [Lead Time] < 0
	OR Nights < 0
	OR [Avg Daily Rate] < 0
	OR Guests <= 0
	AND Status NOT IN ('Check Out', 'Canceled', 'No Show');
-- The row has been changed

-- Check Booking ID 14970
SELECT *
FROM SHG
WHERE [Booking ID] = 14970;
-- It has been corrected

-- Check to see that money was lost only where the guest did not arrive
SELECT DISTINCT Status
FROM SHG
WHERE Revenue < 0;
/* No Show and Canceled*/

-- Check for duplicates
SELECT [Booking ID],
	   COUNT(*)
FROM SHG
GROUP BY [Booking ID]
HAVING COUNT(*) > 1;
-- No duplicate booking ids




/* DATA ANALYSIS - ANSWERING BUSINESS QUESTIONS */

/* BOOKING PATTERNS */
-- Q1: What is the trend in booking patterns over time, and are there
-- specific seasons or months with increased booking activity?
SELECT YEAR([Booking Date]) AS Booking_Year,
	   COUNT([Booking ID]) AS Bookings
FROM SHG
GROUP BY YEAR([Booking Date])
ORDER BY YEAR([Booking Date])

SELECT MIN([Booking Date]) AS Earliest_booking,
	   MAX([Booking Date]) AS Latest_booking
FROM SHG;

-- 2016 had the highest number of bookings 58543
-- 2013 had only one booking despite the earliest record being in June 2013
-- 2107 had less than 2016 but this could be because the data ends in August 2017

SELECT MONTH([Booking Date]) AS Booking_Month,
	   COUNT([Booking ID])  AS Bookings
FROM SHG
GROUP BY MONTH([Booking Date])
ORDER BY Bookings;

-- May and June had the lower number of bookings with 7853 and 6063 bookings
-- respectively while January and February had the highest number of bookings
-- with 16688 and 13468 bookings respectively


-- Check for the most common customer type in May, June, January, February
WITH Top_customers AS (
    SELECT 
        MONTH([Booking Date]) AS Booking_month,
        [Customer Type],
        COUNT([Customer Type]) AS Customer_count,
        ROW_NUMBER() OVER (PARTITION BY MONTH([Booking Date])
			ORDER BY COUNT([Customer Type]) DESC) AS RowNums
    FROM SHG
    WHERE MONTH([Booking Date]) IN (1, 2, 5, 6)
    GROUP BY MONTH([Booking Date]), [Customer Type]
)
SELECT Booking_month,
	   [Customer Type],
	   Customer_count
FROM Top_customers
WHERE RowNums = 1
ORDER BY Booking_month, Customer_count DESC;
-- The Transient customer type was the customer type with the highest
-- frequency in both the top and bottom months


-- Q2: How does lead time vary across different booking channels and customer types?
SELECT [Distribution Channel],
	   CONVERT(VARCHAR, ROUND(AVG([Lead Time]), 0)) + ' days' AS average_lead_time
FROM SHG
GROUP BY [Distribution Channel]
ORDER BY AVG([Lead Time]) DESC;
-- Offline Travel agent was the distribution channel with the longest average lead time (136 days)
-- while Corporate was the defined agent with the shortest average lead time (45 days)

SELECT [Customer Type],
	   CONVERT(VARCHAR, ROUND(AVG([Lead Time]), 0)) + ' days' AS average_lead_time
FROM SHG
GROUP BY [Customer Type]
ORDER BY AVG([Lead Time]) DESC;
-- Contract customer type have the highest lead time (143 days)
-- Group customer type had the lowest lead time (55 days)



/* CUSTOMER BEHAVIOR ANALYSIS */
-- Q3: Which distribution channels contribute the most to bookings, and
-- how does the average daily rate (ADR) differ across these channels?
SELECT [Distribution channel],
	   COUNT(*) AS Count_dist
FROM SHG
GROUP BY [Distribution channel]
ORDER BY Count_dist DESC;

-- People made use of the Online Travel Agent channel most often (74072)
-- while they made use of the Corporate channel least often (6677)
-- Also, it appears that the most commonly used distribution channels 
-- also had the longest average lead time

-- Since ADR is using Revenue/Nights, find the average of sums
SELECT [Distribution Channel],
	   ROUND(SUM(Revenue)/SUM(Nights), 2) AS Calc_ADR
FROM SHG
GROUP BY [Distribution Channel]
ORDER BY Calc_ADR DESC;
-- Direct distribution channel had the highest ADR ($72.67) while
-- Online travel agent was the defined dist channel with the lowest ADR ($25.64)

-- Q4: Can we identify any patterns in the distribution of guests based
-- on their country of origin, and how does this impact revenue?
SELECT Country,
	   COUNT(*) AS country_count,
	   SUM(Revenue) AS total_revenue
FROM SHG
GROUP BY Country
ORDER BY country_count DESC;
-- 8 out of the top 10 countries of origin for guest are European
-- with Portugal having the highest number of guests


/* CANCELLATION ANALYSIS */
-- Q6: How does the revenue loss from cancellations compare across
-- different customer segments and distribution channels?
SELECT [Customer Type],
	   SUM(Revenue) AS total_loss
FROM SHG
WHERE [Cancelled (0/1)] = 1
GROUP BY [Customer Type]
ORDER BY total_loss

SELECT [Distribution Channel],
	   SUM(Revenue) AS total_loss
FROM SHG
WHERE [Cancelled (0/1)] = 1
GROUP BY [Distribution Channel]
ORDER BY total_loss;
-- The Transient customer type cost the hotel the most losing -$8,138,113.10
-- while the Group customer type cost the hotel the least losing -$17,325.19
-- Online Travel agent channel cost the hotel the most losing -$8,744,453.83
-- while the company made back some money from the Offline Travel Agent in
-- the sum of $257,189.61 probably because there are no refunds for offline booking



/* REVENUE OPTIMIZATION */
-- What is the overall revenue trend, and are there specific customer
-- segments or countries contributing significantly to revenue?
SELECT
    SUM(CASE WHEN Revenue > 0 THEN Revenue ELSE 0 END) AS total_revenue,
    SUM(CASE WHEN Revenue < 0 THEN Revenue ELSE 0 END) AS total_loss,
    SUM(Revenue) AS total_profit
FROM SHG;

-- Total revenue is $29,600,725.04 and total revenue loss is -$13,122,900.09.
-- During the considered period, the company made a total profit of $16,477,824.95

SELECT [Customer Type],
	   COUNT(*) AS frequency,
	   SUM(CASE WHEN Revenue > 0 THEN Revenue ELSE 0 END) AS total_revenue,
	   SUM(CASE WHEN Revenue < 0 THEN Revenue ELSE 0 END) AS total_loss,
	   SUM(Revenue) AS total_profit
FROM SHG
GROUP BY [Customer Type]
ORDER BY total_profit DESC;
-- Transient customers had the highest total revenue, loss, and profit by a margin
-- likely because of the high frequency in the total number of guests in that customer type

SELECT [Distribution Channel],
	   COUNT(*) AS frequency,
	   ROUND(AVG(CASE WHEN Revenue > 0 THEN Revenue ELSE 0 END), 2) AS avg_revenue,
	   ROUND(AVG(CASE WHEN Revenue < 0 THEN Revenue ELSE 0 END), 2) AS avg_loss,
	   ROUND(AVG(Revenue), 2) AS avg_profit
FROM SHG
GROUP BY [Distribution Channel]
ORDER BY avg_profit DESC;
-- Offline Travel agent had the highest average profit ($245.22) while online travel agent
-- had the lowest ($87.38).
-- Direct channel had the highest average revenue ($302.69) while corporate channel had
-- the lowest ($137.56)



/* OPERATIONAL EFFICIENCY */
-- What is the average length of stay for guests, and how does it differ based on
-- booking channels or customer types?
SELECT ROUND(AVG(Nights), 0) AS average_length_of_stay
FROM SHG
WHERE Status = 'Check Out';
-- On average guests stayed for 3 nights

SELECT [Distribution Channel],
	   ROUND(AVG(Nights), 0) AS average_length_of_stay
FROM SHG
WHERE Status = 'Check Out'
GROUP BY [Distribution Channel];
-- Among the defined channels, Corporate had the shortest average length of stay (2)
-- while offline travel agent had the longest average length of stay (4)

SELECT [Customer Type],
	   ROUND(AVG(Nights), 0) AS average_length_of_stay
FROM SHG
WHERE Status = 'Check Out'
GROUP BY [Customer Type];
-- Contract customer type had the longest length of stay on average with 6 nights
-- while the other three types of customers had the same average (3 nights)

-- Check for booking channels and customer types
SELECT 
    [Distribution Channel],
    ROUND(AVG(CASE WHEN [Customer Type] = 'Group' THEN [Nights] END), 0) AS Groups,
    ROUND(AVG(CASE WHEN [Customer Type] = 'Contract' THEN [Nights] END), 0) AS Contract,
    ROUND(AVG(CASE WHEN [Customer Type] = 'Transient' THEN [Nights] END), 0) AS Transient,
    ROUND(AVG(CASE WHEN [Customer Type] = 'Transient-Party' THEN [Nights] END), 0) AS Transient_Party
FROM SHG
GROUP BY [Distribution Channel];
-- The contract guests who come through the offline travel agent channel have the longest average length
-- of stay (8 nights) while there are several guest types and distribution channels that have the shortest average
-- length of stay (2 nights)

-- Let us also check the count of booking channels and customer types
SELECT 
    [Distribution Channel],
    COUNT(CASE WHEN [Customer Type] = 'Group' THEN [Nights] END) AS Groups,
    COUNT(CASE WHEN [Customer Type] = 'Contract' THEN [Nights] END) AS Contract,
    COUNT(CASE WHEN [Customer Type] = 'Transient' THEN [Nights] END) AS Transient,
    COUNT(CASE WHEN [Customer Type] = 'Transient-Party' THEN [Nights] END) AS Transient_Party
FROM SHG
GROUP BY [Distribution Channel];

-- Are there patterns in check-out dates that can inform staffing and resource allocation strategies?
SELECT A.Status,
	   A.Nights,
	   A.[Arrival Date],
	   A.[Status Update],
	   DATEADD(dd, A.Nights, A.[Arrival Date]) AS Check_out_date
FROM SHG A
JOIN SHG B
ON A.[Booking ID] = B.[Booking ID]
WHERE A.Status = 'Check Out' AND A.[Status Update] != DATEADD(dd, A.Nights, A.[Arrival Date]);
-- The Status Update column is not always accurate in determining the number of nights
--  that the guests stayed. So we will stick with the result of the DATEADD function



/* IMPACT OF DEPOSIT */
-- How does the presence or absence of a deposit impact the
-- likelihood of cancellations and revenue generation?
SELECT 
    [Deposit Type],
    COUNT(*) AS Total,
    LEFT(ROUND(100.0 * SUM(CASE WHEN [Cancelled (0/1)] = 0 THEN 1 ELSE 0 END) / COUNT(*), 2), 5) AS Not_canceled,
    LEFT(ROUND(100.0 * SUM(CASE WHEN [Cancelled (0/1)] = 1 THEN 1 ELSE 0 END) / COUNT(*), 2), 5) AS Canceled
FROM SHG
GROUP BY [Deposit Type];

SELECT 
    [Deposit Type],
    COUNT(*) AS Total,
    SUM(CASE WHEN [Cancelled (0/1)] = 0 THEN Revenue END) AS Revenue_not_canceled,
    SUM(CASE WHEN [Cancelled (0/1)] = 1 THEN Revenue END) AS Revenue_canceled
FROM SHG
GROUP BY [Deposit Type];
-- Where there were no deposits, there was a 71.62% cancellation rate, when there were refundable deposits, there was
-- 77.78% cancellation rate, however, when there were non-refundable deposits, there was a 0.64% cancellation rate.
-- In the same light, for non-refundable deposit, the hotel did not lose any money on cancellations, there was instead
-- a total profit of $3,604,337.03 while there was a total loss of $13,104,900.09 for other cancellations

-- Can we identify any patterns in the use of deposit types across different customer segments?
SELECT 
    [Customer Type],
    COUNT(*) AS Total,
    ROUND(100.0 * SUM(CASE WHEN [Deposit Type] = 'No Deposit' THEN 1.00 END) / (SELECT COUNT(*) FROM SHG), 2) AS No_deposit,
    ROUND(100.0 * SUM(CASE WHEN [Deposit Type] = 'Refundable' THEN 1.00 END) / (SELECT COUNT(*) FROM SHG), 2) AS Refundable,
    ROUND(100.0 * SUM(CASE WHEN [Deposit Type] = 'Non Refundable' THEN 1.00 END) / (SELECT COUNT(*) FROM SHG), 2) AS Non_refundable
FROM SHG
GROUP BY [Customer Type];
-- Transient guests who did not pay deposits occupy 64.23% of the total number of guest, followed by Transient party with no deposit
-- (19.98%) and Transient with non refundable deposit (10.81%)

-- Check for those that arrived and checked out
SELECT 
    [Customer Type],
    COUNT(*) AS Total,
    ROUND(100.0 * SUM(CASE WHEN [Deposit Type] = 'No Deposit' THEN 1.00 END) / (SELECT COUNT(*) FROM SHG), 2) AS No_deposit,
    ROUND(100.0 * SUM(CASE WHEN [Deposit Type] = 'Refundable' THEN 1.00 END) / (SELECT COUNT(*) FROM SHG), 2) AS Refundable,
    ROUND(100.0 * SUM(CASE WHEN [Deposit Type] = 'Non Refundable' THEN 1.00 END) / (SELECT COUNT(*) FROM SHG), 2) AS Non_refundable
FROM SHG
WHERE Status = 'Check Out'
GROUP BY [Customer Type];
-- 44.48% of transient guest who didn't pay a deposit showed up, 15.52% of transient-party guests who didn't pay deposit
-- showed up and 2.36% of contract guests who didn't pay a deposit showed up.
-- Only 0.08% of transient-party guests who paid a non-refundable deposit showed up.



/* ANALYSIS OF CORPORATE BOOKINGS */
-- What is the proportion of corporate bookings, and how does their Average Daily Rate (ADR) compare to other customer types?
SELECT 
    [Distribution Channel],
	COUNT(*) AS total_count,
    ROUND(100.0 * COUNT(*)/ SUM(COUNT(*)) OVER (), 3) AS count_percentage,
	ROUND(SUM(Revenue)/SUM(Nights), 2) AS Calc_ADR
FROM SHG
GROUP BY [Distribution Channel];
-- Corporate distribution channel had the lowest representation with only 5.59% of guests making use of this distribution channel,
-- amounting to 6677 guests. The average daily rate for corporate distribution was also $45.48
