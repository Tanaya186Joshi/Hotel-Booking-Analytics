/* =====================================================================
   Hotel Booking Cancellation & Revenue Analytics  -  SQL analysis
   Table: hotel_bookings  (cleaned data, one row per booking)

   How I ran it: SQLite. The notebook (Section 7) loads
   data/cleaned/hotel_bookings_cleaned.csv into data/cleaned/hotel_bookings.db.
   Open that file in DB Browser for SQLite, or run:  sqlite3 data/cleaned/hotel_bookings.db < sql/hotel_booking_analysis.sql
   The syntax is standard SQL, so it should run in MySQL / PostgreSQL with small changes
   (mainly ROUND on integers and the 100.0 * ... divisions).

   Things to remember about the data:
   - is_canceled = 1 means cancelled OR no-show
   - estimated_booking_value = adr_clean x total_stay_nights is an ESTIMATE, not actual revenue
   - adr_clean is blank for the one 5,400 outlier; adr_zero = 1 marks ADR = 0 rows
   - is_duplicate_row = 1 marks the 31,994 extra copies of identical rows (kept in the main analysis)
   - reservation_status is NOT used as a predictor (it restates the outcome)
   ===================================================================== */

/* Reference only: the table the notebook creates (pandas to_sql builds it automatically).
   If you import the CSV by hand, make sure blank cells are loaded as NULL, not as empty text.

CREATE TABLE hotel_bookings (
    hotel TEXT, is_canceled INTEGER, is_no_show INTEGER,
    lead_time INTEGER, lead_time_bucket TEXT, lead_time_bucket_order INTEGER,
    arrival_date TEXT, arrival_date_year INTEGER, arrival_month_num INTEGER, arrival_date_month TEXT,
    arrival_year_month TEXT, arrival_date_week_number INTEGER, arrival_date_day_of_month INTEGER,
    estimated_booking_date TEXT,
    stays_in_weekend_nights INTEGER, stays_in_week_nights INTEGER, total_stay_nights INTEGER,
    adults INTEGER, children INTEGER, babies INTEGER, total_guests INTEGER,
    meal TEXT, country TEXT, market_segment TEXT, distribution_channel TEXT,
    is_repeated_guest INTEGER, previous_cancellations INTEGER, previous_bookings_not_canceled INTEGER,
    reserved_room_type TEXT, assigned_room_type TEXT, room_changed INTEGER, booking_changes INTEGER,
    deposit_type TEXT, agent REAL, company REAL, has_agent INTEGER, has_company INTEGER,
    days_in_waiting_list INTEGER, customer_type TEXT,
    adr REAL, adr_clean REAL, adr_zero INTEGER, adr_outlier INTEGER, estimated_booking_value REAL,
    required_car_parking_spaces INTEGER, total_of_special_requests INTEGER,
    reservation_status TEXT, reservation_status_date TEXT,
    zero_guests INTEGER, zero_stay_nights INTEGER, extreme_guest_count INTEGER, is_duplicate_row INTEGER
);
*/


/* ================= BASIC SQL ================= */

-- Q1. Total, cancelled and confirmed bookings
-- Business question: How many bookings are in the data, and what percentage were cancelled (including no-shows)?
SELECT COUNT(*)                                           AS total_bookings,
       SUM(is_canceled)                                   AS cancelled_bookings,
       COUNT(*) - SUM(is_canceled)                        AS confirmed_bookings,
       ROUND(100.0 * SUM(is_canceled) / COUNT(*), 2)      AS cancellation_rate_pct
FROM hotel_bookings;

-- Q2. Bookings by hotel
-- Business question: How are bookings split between the City Hotel and the Resort Hotel?
SELECT hotel,
       COUNT(*) AS bookings,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM hotel_bookings), 1) AS pct_of_all_bookings
FROM hotel_bookings
GROUP BY hotel
ORDER BY bookings DESC;

-- Q3. Bookings by customer type
-- Business question: Which customer types make up most of the bookings?
SELECT customer_type,
       COUNT(*) AS bookings,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM hotel_bookings), 1) AS pct_of_all_bookings
FROM hotel_bookings
GROUP BY customer_type
ORDER BY bookings DESC;

-- Q4. Top 10 countries by bookings
-- Business question: Which countries send the most bookings, and how many of those were cancelled?
SELECT country,
       COUNT(*)         AS bookings,
       SUM(is_canceled) AS cancelled_bookings
FROM hotel_bookings
GROUP BY country
ORDER BY bookings DESC
LIMIT 10;


/* ================= INTERMEDIATE SQL ================= */

-- Q5. Average ADR, lead time and stay length by hotel
-- Business question: How do the two hotels differ on price, how far ahead guests book, and how long they stay?
-- ADR averages leave out ADR = 0 rows (adr_clean is also blank for the one 5,400 outlier, and AVG ignores blanks)
-- stay length leaves out zero-night bookings
SELECT hotel,
       ROUND(AVG(CASE WHEN adr_zero = 0 THEN adr_clean END), 2)               AS avg_adr,
       ROUND(AVG(lead_time), 1)                                               AS avg_lead_time_days,
       ROUND(AVG(CASE WHEN zero_stay_nights = 0 THEN total_stay_nights END), 2) AS avg_stay_nights
FROM hotel_bookings
GROUP BY hotel;

-- Q6. Lead time: cancelled vs confirmed bookings
-- Business question: Are cancelled bookings made further ahead than confirmed ones?
SELECT CASE WHEN is_canceled = 1 THEN 'Cancelled / no-show' ELSE 'Confirmed' END AS outcome,
       COUNT(*)                     AS bookings,
       ROUND(AVG(lead_time), 1)     AS avg_lead_time_days,
       MIN(lead_time)               AS min_lead_time,
       MAX(lead_time)               AS max_lead_time
FROM hotel_bookings
GROUP BY is_canceled;

-- Q7. Cancellation rate by hotel
-- Business question: Which hotel has the higher cancellation rate?
SELECT hotel,
       COUNT(*)                                       AS bookings,
       SUM(is_canceled)                               AS cancelled_bookings,
       ROUND(100.0 * SUM(is_canceled) / COUNT(*), 2)  AS cancellation_rate_pct
FROM hotel_bookings
GROUP BY hotel
ORDER BY cancellation_rate_pct DESC;

-- Q8. Cancellation rate by market segment
-- Business question: Which market segments cancel the most?
SELECT market_segment,
       COUNT(*)                                       AS bookings,
       SUM(is_canceled)                               AS cancelled_bookings,
       ROUND(100.0 * SUM(is_canceled) / COUNT(*), 2)  AS cancellation_rate_pct
FROM hotel_bookings
GROUP BY market_segment
ORDER BY cancellation_rate_pct DESC;

-- Q9. Cancellation rate by distribution channel
-- Business question: Which booking channels have the highest cancellation rates?
SELECT distribution_channel,
       COUNT(*)                                       AS bookings,
       SUM(is_canceled)                               AS cancelled_bookings,
       ROUND(100.0 * SUM(is_canceled) / COUNT(*), 2)  AS cancellation_rate_pct
FROM hotel_bookings
GROUP BY distribution_channel
ORDER BY cancellation_rate_pct DESC;

-- Q10. Monthly booking trend
-- Business question: How many bookings arrive each month across the whole period?
SELECT arrival_year_month,
       COUNT(*)         AS bookings,
       SUM(is_canceled) AS cancelled_bookings
FROM hotel_bookings
GROUP BY arrival_year_month
ORDER BY arrival_year_month;

-- Q11. Monthly cancellation rate in 2016
-- Business question: How does the cancellation rate change by month in the only full year (2016)?
SELECT arrival_month_num AS month,
       COUNT(*)                                       AS bookings,
       SUM(is_canceled)                               AS cancelled_bookings,
       ROUND(100.0 * SUM(is_canceled) / COUNT(*), 2)  AS cancellation_rate_pct
FROM hotel_bookings
WHERE arrival_date_year = 2016
GROUP BY arrival_month_num
ORDER BY arrival_month_num;

-- Q12. Estimated booking value and revenue at risk by hotel
-- Business question: How much estimated booking value is attached to cancelled bookings at each hotel? (an estimate, not accounting revenue)
-- estimated_booking_value = adr_clean x total_stay_nights (blank for the ADR outlier, so it is left out of the sums)
SELECT hotel,
       ROUND(SUM(estimated_booking_value), 0)                                                   AS estimated_booking_value,
       ROUND(SUM(CASE WHEN is_canceled = 1 THEN estimated_booking_value ELSE 0 END), 0)         AS estimated_revenue_at_risk,
       ROUND(100.0 * SUM(CASE WHEN is_canceled = 1 THEN estimated_booking_value ELSE 0 END)
                   / SUM(estimated_booking_value), 1)                                           AS at_risk_pct_of_value
FROM hotel_bookings
GROUP BY hotel;

-- Q13. Cancellation rate by deposit type
-- Business question: Does deposit type go with cancellation? (reported as observed, see the note on Non Refund)
SELECT deposit_type,
       COUNT(*)                                       AS bookings,
       SUM(is_canceled)                               AS cancelled_bookings,
       ROUND(100.0 * SUM(is_canceled) / COUNT(*), 2)  AS cancellation_rate_pct
FROM hotel_bookings
GROUP BY deposit_type
HAVING COUNT(*) >= 100          -- ignore tiny groups
ORDER BY cancellation_rate_pct DESC;

-- Q14. Cancellation rate by lead-time group
-- Business question: Does the cancellation rate increase as lead time gets longer?
SELECT CASE WHEN lead_time <= 7   THEN '1) 0-7 days'
            WHEN lead_time <= 30  THEN '2) 8-30 days'
            WHEN lead_time <= 90  THEN '3) 31-90 days'
            WHEN lead_time <= 180 THEN '4) 91-180 days'
            WHEN lead_time <= 365 THEN '5) 181-365 days'
            ELSE                       '6) 365+ days' END AS lead_time_group,
       COUNT(*)                                       AS bookings,
       SUM(is_canceled)                               AS cancelled_bookings,
       ROUND(100.0 * SUM(is_canceled) / COUNT(*), 2)  AS cancellation_rate_pct
FROM hotel_bookings
GROUP BY lead_time_group
ORDER BY lead_time_group;

-- Q15. Previous cancellation history
-- Business question: Do guests with earlier cancellations on record cancel more often?
SELECT CASE WHEN previous_cancellations = 0 THEN '0'
            WHEN previous_cancellations = 1 THEN '1'
            WHEN previous_cancellations = 2 THEN '2'
            ELSE '3 or more' END                      AS previous_cancellations_group,
       COUNT(*)                                       AS bookings,
       SUM(is_canceled)                               AS cancelled_bookings,
       ROUND(100.0 * SUM(is_canceled) / COUNT(*), 2)  AS cancellation_rate_pct
FROM hotel_bookings
GROUP BY previous_cancellations_group
ORDER BY previous_cancellations_group;


/* ================= ANALYTICAL SQL ================= */

-- Q16. Rank countries by cancellation rate vs the overall rate
-- Business question: Among countries with at least 1,000 bookings, which have cancellation rates well above or below the overall rate?
WITH country_stats AS (
    SELECT country,
           COUNT(*)                                  AS bookings,
           SUM(is_canceled)                          AS cancelled_bookings,
           100.0 * SUM(is_canceled) / COUNT(*)       AS cancel_rate
    FROM hotel_bookings
    GROUP BY country
    HAVING COUNT(*) >= 1000          -- avoids tiny countries with 100% rates
)
SELECT RANK() OVER (ORDER BY cancel_rate DESC)       AS rank_by_rate,
       country,
       bookings,
       cancelled_bookings,
       ROUND(cancel_rate, 2)                         AS cancellation_rate_pct,
       ROUND(cancel_rate - (SELECT 100.0 * SUM(is_canceled) / COUNT(*)
                            FROM hotel_bookings), 2) AS points_vs_overall_rate
FROM country_stats
ORDER BY rank_by_rate;

-- Q17. High-volume segment and hotel combinations with above-average cancellation
-- Business question: Which segment/hotel combinations have a lot of bookings AND a cancellation rate above the overall rate?
WITH combo AS (
    SELECT market_segment, hotel,
           COUNT(*)                              AS bookings,
           SUM(is_canceled)                      AS cancelled_bookings,
           100.0 * SUM(is_canceled) / COUNT(*)   AS cancel_rate
    FROM hotel_bookings
    GROUP BY market_segment, hotel
    HAVING COUNT(*) >= 5000
)
SELECT market_segment, hotel, bookings, cancelled_bookings,
       ROUND(cancel_rate, 2) AS cancellation_rate_pct
FROM combo
WHERE cancel_rate > (SELECT 100.0 * SUM(is_canceled) / COUNT(*) FROM hotel_bookings)
ORDER BY cancelled_bookings DESC;

-- Q18. Rank market segments by estimated booking value and revenue at risk
-- Business question: Which segments carry the most estimated booking value, and how much of the total revenue at risk comes from each?
SELECT market_segment,
       RANK() OVER (ORDER BY SUM(estimated_booking_value) DESC)                              AS value_rank,
       ROUND(SUM(estimated_booking_value), 0)                                                AS estimated_booking_value,
       ROUND(SUM(CASE WHEN is_canceled = 1 THEN estimated_booking_value ELSE 0 END), 0)      AS estimated_revenue_at_risk,
       ROUND(100.0 * SUM(CASE WHEN is_canceled = 1 THEN estimated_booking_value ELSE 0 END)
                   / SUM(estimated_booking_value), 1)                                        AS at_risk_pct_of_segment_value,
       ROUND(100.0 * SUM(CASE WHEN is_canceled = 1 THEN estimated_booking_value ELSE 0 END)
                   / SUM(SUM(CASE WHEN is_canceled = 1 THEN estimated_booking_value ELSE 0 END)) OVER (), 1)
                                                                                             AS share_of_total_at_risk_pct
FROM hotel_bookings
GROUP BY market_segment
ORDER BY value_rank;

-- Q19. Monthly estimated value and cancellation rate in 2016, with change from previous month
-- Business question: How do estimated booking value, revenue at risk and the cancellation rate move month to month in 2016?
WITH monthly AS (
    SELECT arrival_month_num                                                          AS month,
           COUNT(*)                                                                   AS bookings,
           SUM(estimated_booking_value)                                               AS est_value,
           SUM(CASE WHEN is_canceled = 1 THEN estimated_booking_value ELSE 0 END)    AS est_at_risk,
           100.0 * SUM(is_canceled) / COUNT(*)                                        AS cancel_rate
    FROM hotel_bookings
    WHERE arrival_date_year = 2016
    GROUP BY arrival_month_num
)
SELECT month,
       bookings,
       ROUND(est_value, 0)                                    AS estimated_booking_value,
       ROUND(est_at_risk, 0)                                  AS estimated_revenue_at_risk,
       ROUND(cancel_rate, 2)                                  AS cancellation_rate_pct,
       ROUND(cancel_rate - LAG(cancel_rate) OVER (ORDER BY month), 2) AS change_vs_previous_month
FROM monthly
ORDER BY month;

-- Q20. Sensitivity check: hotel cancellation rate with and without duplicate rows
-- Business question: Do the hotel results change if exact duplicate rows are removed?
SELECT hotel,
       COUNT(*)                                                                AS bookings_all_rows,
       ROUND(100.0 * SUM(is_canceled) / COUNT(*), 2)                           AS rate_all_rows_pct,
       SUM(CASE WHEN is_duplicate_row = 0 THEN 1 ELSE 0 END)                   AS bookings_no_duplicates,
       ROUND(100.0 * SUM(CASE WHEN is_duplicate_row = 0 THEN is_canceled END)
                   / SUM(CASE WHEN is_duplicate_row = 0 THEN 1 END), 2)        AS rate_no_duplicates_pct
FROM hotel_bookings
GROUP BY hotel;
