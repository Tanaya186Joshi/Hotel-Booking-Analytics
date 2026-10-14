# SQL analysis: queries, results and what I read from them

All queries run on the cleaned table `hotel_bookings` (119,389 rows, SQLite). Every result below was produced by running the query on the data. Each section is: **Business question -> SQL -> Result -> Interpretation**.

Reminders: `is_canceled = 1` includes no-shows. Revenue figures are *estimates* (ADR x nights). The main analysis keeps all rows, including the 31,994 flagged duplicates.


## Basic SQL

### Q1. Total, cancelled and confirmed bookings

**Business question:** How many bookings are in the data, and what percentage were cancelled (including no-shows)?

```sql
SELECT COUNT(*)                                           AS total_bookings,
       SUM(is_canceled)                                   AS cancelled_bookings,
       COUNT(*) - SUM(is_canceled)                        AS confirmed_bookings,
       ROUND(100.0 * SUM(is_canceled) / COUNT(*), 2)      AS cancellation_rate_pct
FROM hotel_bookings;
```

**Result:**

|   total_bookings |   cancelled_bookings |   confirmed_bookings |   cancellation_rate_pct |
|-----------------:|---------------------:|---------------------:|------------------------:|
|          119,389 |               44,224 |               75,165 |                   37.04 |

**Interpretation:** 44,224 of the 119,389 bookings are cancelled or no-shows, a 37.04% rate. This is the headline number. It includes 1,207 no-shows, and it uses every row (Query 20 shows what happens without the duplicate rows).

### Q2. Bookings by hotel

**Business question:** How are bookings split between the City Hotel and the Resort Hotel?

```sql
SELECT hotel,
       COUNT(*) AS bookings,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM hotel_bookings), 1) AS pct_of_all_bookings
FROM hotel_bookings
GROUP BY hotel
ORDER BY bookings DESC;
```

**Result:**

| hotel        |   bookings |   pct_of_all_bookings |
|:-------------|-----------:|----------------------:|
| City Hotel   |     79,330 |                  66.4 |
| Resort Hotel |     40,059 |                  33.6 |

**Interpretation:** City Hotel is two-thirds of the bookings (66.4%), so anything that happens at City Hotel moves the overall numbers most.

### Q3. Bookings by customer type

**Business question:** Which customer types make up most of the bookings?

```sql
SELECT customer_type,
       COUNT(*) AS bookings,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM hotel_bookings), 1) AS pct_of_all_bookings
FROM hotel_bookings
GROUP BY customer_type
ORDER BY bookings DESC;
```

**Result:**

| customer_type   |   bookings |   pct_of_all_bookings |
|:----------------|-----------:|----------------------:|
| Transient       |     89,613 |                  75.1 |
| Transient-Party |     25,123 |                  21   |
| Contract        |       4076 |                   3.4 |
| Group           |        577 |                   0.5 |

**Interpretation:** Transient guests are 75.1% of bookings. Group bookings are only 577 rows (0.5%), so any Group-type percentage is based on very few bookings.

### Q4. Top 10 countries by bookings

**Business question:** Which countries send the most bookings, and how many of those were cancelled?

```sql
SELECT country,
       COUNT(*)         AS bookings,
       SUM(is_canceled) AS cancelled_bookings
FROM hotel_bookings
GROUP BY country
ORDER BY bookings DESC
LIMIT 10;
```

**Result:**

| country   |   bookings |   cancelled_bookings |
|:----------|-----------:|---------------------:|
| PRT       |     48,590 |               27,519 |
| GBR       |     12,128 |                 2453 |
| FRA       |     10,415 |                 1934 |
| ESP       |       8568 |                 2177 |
| DEU       |       7287 |                 1218 |
| ITA       |       3766 |                 1333 |
| IRL       |       3375 |                  832 |
| BEL       |       2342 |                  474 |
| BRA       |       2224 |                  830 |
| NLD       |       2104 |                  387 |

**Interpretation:** Portugal (PRT) sends 48,590 bookings and 27,519 of them were cancelled, far more than any other country. The second country, GBR, has 12,128 bookings. Portugal alone accounts for over 60% of all cancelled bookings.


## Intermediate SQL

### Q5. Average ADR, lead time and stay length by hotel

**Business question:** How do the two hotels differ on price, how far ahead guests book, and how long they stay?

```sql
-- ADR averages leave out ADR = 0 rows (adr_clean is also blank for the one 5,400 outlier, and AVG ignores blanks)
-- stay length leaves out zero-night bookings
SELECT hotel,
       ROUND(AVG(CASE WHEN adr_zero = 0 THEN adr_clean END), 2)               AS avg_adr,
       ROUND(AVG(lead_time), 1)                                               AS avg_lead_time_days,
       ROUND(AVG(CASE WHEN zero_stay_nights = 0 THEN total_stay_nights END), 2) AS avg_stay_nights
FROM hotel_bookings
GROUP BY hotel;
```

**Result:**

| hotel        |   avg_adr |   avg_lead_time_days |   avg_stay_nights |
|:-------------|----------:|---------------------:|------------------:|
| City Hotel   |    106.87 |                109.7 |              2.99 |
| Resort Hotel |     96.77 |                 92.7 |              4.36 |

**Interpretation:** City Hotel has the higher ADR (106.87 vs 96.77) and a longer average lead time (109.7 vs 92.7 days), but shorter stays (2.99 vs 4.36 nights). Looks like a business/short-city-stay vs a longer-leisure-stay pattern, though the data doesn't label the purpose of the trip.

### Q6. Lead time: cancelled vs confirmed bookings

**Business question:** Are cancelled bookings made further ahead than confirmed ones?

```sql
SELECT CASE WHEN is_canceled = 1 THEN 'Cancelled / no-show' ELSE 'Confirmed' END AS outcome,
       COUNT(*)                     AS bookings,
       ROUND(AVG(lead_time), 1)     AS avg_lead_time_days,
       MIN(lead_time)               AS min_lead_time,
       MAX(lead_time)               AS max_lead_time
FROM hotel_bookings
GROUP BY is_canceled;
```

**Result:**

| outcome             |   bookings |   avg_lead_time_days |   min_lead_time |   max_lead_time |
|:--------------------|-----------:|---------------------:|----------------:|----------------:|
| Confirmed           |     75,165 |                 80   |               0 |             737 |
| Cancelled / no-show |     44,224 |                144.8 |               0 |             629 |

**Interpretation:** Cancelled bookings were made about 145 days ahead on average, confirmed ones about 80 days ahead. So the answer to "are cancelled bookings made earlier?" is yes. The averages are pulled up by long-lead bookings, which is why the notebook also checks medians (113 vs 45 days).

### Q7. Cancellation rate by hotel

**Business question:** Which hotel has the higher cancellation rate?

```sql
SELECT hotel,
       COUNT(*)                                       AS bookings,
       SUM(is_canceled)                               AS cancelled_bookings,
       ROUND(100.0 * SUM(is_canceled) / COUNT(*), 2)  AS cancellation_rate_pct
FROM hotel_bookings
GROUP BY hotel
ORDER BY cancellation_rate_pct DESC;
```

**Result:**

| hotel        |   bookings |   cancelled_bookings |   cancellation_rate_pct |
|:-------------|-----------:|---------------------:|------------------------:|
| City Hotel   |     79,330 |               33,102 |                   41.73 |
| Resort Hotel |     40,059 |               11,122 |                   27.76 |

**Interpretation:** City Hotel cancels at 41.73% and Resort Hotel at 27.76%, a gap of nearly 14 percentage points.

### Q8. Cancellation rate by market segment

**Business question:** Which market segments cancel the most?

```sql
SELECT market_segment,
       COUNT(*)                                       AS bookings,
       SUM(is_canceled)                               AS cancelled_bookings,
       ROUND(100.0 * SUM(is_canceled) / COUNT(*), 2)  AS cancellation_rate_pct
FROM hotel_bookings
GROUP BY market_segment
ORDER BY cancellation_rate_pct DESC;
```

**Result:**

| market_segment   |   bookings |   cancelled_bookings |   cancellation_rate_pct |
|:-----------------|-----------:|---------------------:|------------------------:|
| Unknown          |          2 |                    2 |                  100    |
| Groups           |     19,810 |               12,097 |                   61.07 |
| Online TA        |     56,477 |               20,739 |                   36.72 |
| Offline TA/TO    |     24,219 |                 8311 |                   34.32 |
| Aviation         |        237 |                   52 |                   21.94 |
| Corporate        |       5295 |                  992 |                   18.73 |
| Direct           |     12,606 |                 1934 |                   15.34 |
| Complementary    |        743 |                   97 |                   13.06 |

**Interpretation:** Groups has the highest rate among sizeable segments (61.07%), followed by Online TA (36.72%) and Offline TA/TO (34.32%). The 'Unknown' segment is 2 bookings and should be ignored. Remember that the Groups number is heavily influenced by the odd Non Refund bookings and by duplicate rows (see Query 13, and Q3 in the notebook).

### Q9. Cancellation rate by distribution channel

**Business question:** Which booking channels have the highest cancellation rates?

```sql
SELECT distribution_channel,
       COUNT(*)                                       AS bookings,
       SUM(is_canceled)                               AS cancelled_bookings,
       ROUND(100.0 * SUM(is_canceled) / COUNT(*), 2)  AS cancellation_rate_pct
FROM hotel_bookings
GROUP BY distribution_channel
ORDER BY cancellation_rate_pct DESC;
```

**Result:**

| distribution_channel   |   bookings |   cancelled_bookings |   cancellation_rate_pct |
|:-----------------------|-----------:|---------------------:|------------------------:|
| Unknown                |          5 |                    4 |                   80    |
| TA/TO                  |     97,870 |               40,152 |                   41.03 |
| Corporate              |       6677 |                 1474 |                   22.08 |
| GDS                    |        193 |                   37 |                   19.17 |
| Direct                 |     14,644 |                 2557 |                   17.46 |

**Interpretation:** TA/TO bookings cancel at 41.03% against 17.46% for Direct. TA/TO is 97,870 of the 119,389 bookings, so it's the channel that determines the overall rate. The 'Unknown' channel has 5 rows.

### Q10. Monthly booking trend

**Business question:** How many bookings arrive each month across the whole period?

```sql
SELECT arrival_year_month,
       COUNT(*)         AS bookings,
       SUM(is_canceled) AS cancelled_bookings
FROM hotel_bookings
GROUP BY arrival_year_month
ORDER BY arrival_year_month;
```

**Result:**

| arrival_year_month   |   bookings |   cancelled_bookings |
|:---------------------|-----------:|---------------------:|
| 2015-07              |       2776 |                 1259 |
| 2015-08              |       3889 |                 1598 |
| 2015-09              |       5114 |                 2094 |
| 2015-10              |       4957 |                 1732 |
| 2015-11              |       2340 |                  486 |
| 2015-12              |       2920 |                  973 |
| 2016-01              |       2248 |                  557 |
| 2016-02              |       3891 |                 1337 |
| 2016-03              |       4824 |                 1477 |
| 2016-04              |       5428 |                 2061 |
| 2016-05              |       5478 |                 1915 |
| 2016-06              |       5292 |                 2096 |
| 2016-07              |       4572 |                 1499 |
| 2016-08              |       5063 |                 1825 |
| 2016-09              |       5394 |                 2022 |
| 2016-10              |       6203 |                 2514 |
| 2016-11              |       4454 |                 1636 |
| 2016-12              |       3860 |                 1398 |
| 2017-01              |       3681 |                 1250 |
| 2017-02              |       4177 |                 1359 |
| 2017-03              |       4969 |                 1672 |
| 2017-04              |       5661 |                 2463 |
| 2017-05              |       6313 |                 2762 |
| 2017-06              |       5647 |                 2439 |
| 2017-07              |       5313 |                 1984 |
| 2017-08              |       4925 |                 1816 |

**Interpretation:** Volume ranges from 2,248 (Jan 2016) to 6,313 (May 2017) bookings per arrival month. 2015 starts in July and 2017 stops in August, so the totals for a calendar year are not comparable across 2015, 2016 and 2017.

### Q11. Monthly cancellation rate in 2016

**Business question:** How does the cancellation rate change by month in the only full year (2016)?

```sql
SELECT arrival_month_num AS month,
       COUNT(*)                                       AS bookings,
       SUM(is_canceled)                               AS cancelled_bookings,
       ROUND(100.0 * SUM(is_canceled) / COUNT(*), 2)  AS cancellation_rate_pct
FROM hotel_bookings
WHERE arrival_date_year = 2016
GROUP BY arrival_month_num
ORDER BY arrival_month_num;
```

**Result:**

|   month |   bookings |   cancelled_bookings |   cancellation_rate_pct |
|--------:|-----------:|---------------------:|------------------------:|
|       1 |       2248 |                  557 |                   24.78 |
|       2 |       3891 |                 1337 |                   34.36 |
|       3 |       4824 |                 1477 |                   30.62 |
|       4 |       5428 |                 2061 |                   37.97 |
|       5 |       5478 |                 1915 |                   34.96 |
|       6 |       5292 |                 2096 |                   39.61 |
|       7 |       4572 |                 1499 |                   32.79 |
|       8 |       5063 |                 1825 |                   36.05 |
|       9 |       5394 |                 2022 |                   37.49 |
|      10 |       6203 |                 2514 |                   40.53 |
|      11 |       4454 |                 1636 |                   36.73 |
|      12 |       3860 |                 1398 |                   36.22 |

**Interpretation:** In 2016, January has the lowest rate (24.78%) and October the highest (40.53%). Most other months are between 33% and 40%. It's one year, so I treat it as a hint and not as a seasonal rule.

### Q12. Estimated booking value and revenue at risk by hotel

**Business question:** How much estimated booking value is attached to cancelled bookings at each hotel? (an estimate, not accounting revenue)

```sql
-- estimated_booking_value = adr_clean x total_stay_nights (blank for the ADR outlier, so it is left out of the sums)
SELECT hotel,
       ROUND(SUM(estimated_booking_value), 0)                                                   AS estimated_booking_value,
       ROUND(SUM(CASE WHEN is_canceled = 1 THEN estimated_booking_value ELSE 0 END), 0)         AS estimated_revenue_at_risk,
       ROUND(100.0 * SUM(CASE WHEN is_canceled = 1 THEN estimated_booking_value ELSE 0 END)
                   / SUM(estimated_booking_value), 1)                                           AS at_risk_pct_of_value
FROM hotel_bookings
GROUP BY hotel;
```

**Result:**

| hotel        |   estimated_booking_value |   estimated_revenue_at_risk |   at_risk_pct_of_value |
|:-------------|--------------------------:|----------------------------:|-----------------------:|
| City Hotel   |                25,274,070 |                  10,879,660 |                   43   |
| Resort Hotel |                17,444,091 |                   5,842,177 |                   33.5 |

**Interpretation:** The estimated value attached to cancelled bookings is about 10.9 million at City Hotel (43.0% of its estimated value) and 5.8 million at Resort Hotel (33.5%). These are estimates of ADR x nights, not revenue lost; the data has no payments, refunds or cancellation fees.

### Q13. Cancellation rate by deposit type

**Business question:** Does deposit type go with cancellation? (reported as observed, see the note on Non Refund)

```sql
SELECT deposit_type,
       COUNT(*)                                       AS bookings,
       SUM(is_canceled)                               AS cancelled_bookings,
       ROUND(100.0 * SUM(is_canceled) / COUNT(*), 2)  AS cancellation_rate_pct
FROM hotel_bookings
GROUP BY deposit_type
HAVING COUNT(*) >= 100          -- ignore tiny groups
ORDER BY cancellation_rate_pct DESC;
```

**Result:**

| deposit_type   |   bookings |   cancelled_bookings |   cancellation_rate_pct |
|:---------------|-----------:|---------------------:|------------------------:|
| Non Refund     |     14,587 |               14,494 |                   99.36 |
| No Deposit     |    104,640 |               29,694 |                   28.38 |
| Refundable     |        162 |                   36 |                   22.22 |

**Interpretation:** Non Refund bookings cancel 99.36% of the time, which is the opposite of what a non-refundable rate should do. I'm reporting it as observed and not drawing a business conclusion; it may be a dataset-specific issue. Refundable has only 162 bookings, so I wouldn't read much into its 22.22%.

### Q14. Cancellation rate by lead-time group

**Business question:** Does the cancellation rate increase as lead time gets longer?

```sql
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
```

**Result:**

| lead_time_group   |   bookings |   cancelled_bookings |   cancellation_rate_pct |
|:------------------|-----------:|---------------------:|------------------------:|
| 1) 0-7 days       |     19,746 |                 1902 |                    9.63 |
| 2) 8-30 days      |     18,960 |                 5283 |                   27.86 |
| 3) 31-90 days     |     29,553 |               11,141 |                   37.7  |
| 4) 91-180 days    |     26,439 |               11,821 |                   44.71 |
| 5) 181-365 days   |     21,543 |               11,947 |                   55.46 |
| 6) 365+ days      |       3148 |                 2130 |                   67.66 |

**Interpretation:** The rate climbs at every step: 9.63% for 0-7 days up to 67.66% for 365+ days. This is the cleanest pattern in the dataset. (When Non Refund bookings are removed, the 365+ group falls back to about 21%, so the very top of the scale is partly a deposit-type effect. The notebook shows this.)

### Q15. Previous cancellation history

**Business question:** Do guests with earlier cancellations on record cancel more often?

```sql
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
```

**Result:**

| previous_cancellations_group   |   bookings |   cancelled_bookings |   cancellation_rate_pct |
|:-------------------------------|-----------:|---------------------:|------------------------:|
| 0                              |    112,905 |               38,282 |                   33.91 |
| 1                              |       6051 |                 5714 |                   94.43 |
| 2                              |        116 |                   38 |                   32.76 |
| 3 or more                      |        317 |                  190 |                   59.94 |

**Interpretation:** One previous cancellation goes with a 94.43% rate, but two previous cancellations go with only 32.76%, so it's not a steady pattern. About 58% of the 'one previous cancellation' group are Non Refund bookings, so this probably overlaps with the Non Refund issue. I'd treat it as unreliable.


## Analytical SQL

### Q16. Rank countries by cancellation rate vs the overall rate

**Business question:** Among countries with at least 1,000 bookings, which have cancellation rates well above or below the overall rate?

```sql
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
```

**Result:**

|   rank_by_rate | country   |   bookings |   cancelled_bookings |   cancellation_rate_pct |   points_vs_overall_rate |
|---------------:|:----------|-----------:|---------------------:|------------------------:|-------------------------:|
|              1 | PRT       |     48,590 |               27,519 |                   56.64 |                    19.59 |
|              2 | BRA       |       2224 |                  830 |                   37.32 |                     0.28 |
|              3 | ITA       |       3766 |                 1333 |                   35.4  |                    -1.65 |
|              4 | ESP       |       8568 |                 2177 |                   25.41 |                   -11.63 |
|              5 | CHE       |       1730 |                  428 |                   24.74 |                   -12.3  |
|              6 | IRL       |       3375 |                  832 |                   24.65 |                   -12.39 |
|              7 | USA       |       2097 |                  501 |                   23.89 |                   -13.15 |
|              8 | SWE       |       1024 |                  227 |                   22.17 |                   -14.87 |
|              9 | BEL       |       2342 |                  474 |                   20.24 |                   -16.8  |
|             10 | GBR       |     12,128 |                 2453 |                   20.23 |                   -16.82 |
|             11 | CN        |       1279 |                  254 |                   19.86 |                   -17.18 |
|             12 | FRA       |     10,415 |                 1934 |                   18.57 |                   -18.47 |
|             13 | NLD       |       2104 |                  387 |                   18.39 |                   -18.65 |
|             14 | AUT       |       1263 |                  230 |                   18.21 |                   -18.83 |
|             15 | DEU       |       7287 |                 1218 |                   16.71 |                   -20.33 |

**Interpretation:** Portugal is 19.6 points above the overall rate (56.64%). Every other large country is within about 20 points below, with Brazil and Italy the nearest (37.32% and 35.40%). GBR, FRA and DEU all sit around 17-20%. Using HAVING COUNT(*) >= 1000 keeps tiny countries out of the ranking.

### Q17. High-volume segment and hotel combinations with above-average cancellation

**Business question:** Which segment/hotel combinations have a lot of bookings AND a cancellation rate above the overall rate?

```sql
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
```

**Result:**

| market_segment   | hotel        |   bookings |   cancelled_bookings |   cancellation_rate_pct |
|:-----------------|:-------------|-----------:|---------------------:|------------------------:|
| Online TA        | City Hotel   |     38,748 |               14,491 |                   37.4  |
| Groups           | City Hotel   |     13,975 |                 9623 |                   68.86 |
| Offline TA/TO    | City Hotel   |     16,747 |                 7173 |                   42.83 |
| Groups           | Resort Hotel |       5835 |                 2474 |                   42.4  |

**Interpretation:** Four segment/hotel combinations with 5,000+ bookings are above the overall rate. Online TA at City Hotel is the biggest by volume (38,748 bookings, 14,491 cancelled, 37.40%). Groups at City Hotel has the highest rate (68.86%). Offline TA/TO at City Hotel is 42.83%. Online TA at Resort Hotel (35.24%) is just below the overall rate, so it doesn't appear here.

### Q18. Rank market segments by estimated booking value and revenue at risk

**Business question:** Which segments carry the most estimated booking value, and how much of the total revenue at risk comes from each?

```sql
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
```

**Result:**

| market_segment   |   value_rank |   estimated_booking_value |   estimated_revenue_at_risk |   at_risk_pct_of_segment_value |   share_of_total_at_risk_pct |
|:-----------------|-------------:|--------------------------:|----------------------------:|-------------------------------:|-----------------------------:|
| Online TA        |            1 |                23,942,048 |                  10,227,646 |                           42.7 |                         61.2 |
| Offline TA/TO    |            2 |                 8,146,513 |                   2,486,958 |                           30.5 |                         14.9 |
| Direct           |            3 |                 5,093,028 |                     993,410 |                           19.5 |                          5.9 |
| Groups           |            4 |                 4,669,701 |                   2,800,544 |                           60   |                         16.7 |
| Corporate        |            5 |                   774,295 |                     196,383 |                           25.4 |                          1.2 |
| Aviation         |            6 |                    87,446 |                      16,578 |                           19   |                          0.1 |
| Complementary    |            7 |                     5,083 |                         270 |                            5.3 |                          0   |
| Unknown          |            8 |                        48 |                          48 |                          100   |                          0   |

**Interpretation:** Online TA ranks first by estimated booking value and also carries 61.2% of the total estimated revenue at risk (about 10.2 million). Groups has a much higher at-risk share of its own value (60.0%) but a smaller overall share (16.7%). These are estimates, not accounting figures.

### Q19. Monthly estimated value and cancellation rate in 2016, with change from previous month

**Business question:** How do estimated booking value, revenue at risk and the cancellation rate move month to month in 2016?

```sql
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
```

**Result:**

|   month |   bookings |   estimated_booking_value |   estimated_revenue_at_risk |   cancellation_rate_pct |   change_vs_previous_month |
|--------:|-----------:|--------------------------:|----------------------------:|------------------------:|---------------------------:|
|       1 |       2248 |                   403,695 |                     139,173 |                   24.78 |                            |
|       2 |       3891 |                   788,225 |                     304,055 |                   34.36 |                       9.58 |
|       3 |       4824 |                 1,221,528 |                     454,190 |                   30.62 |                      -3.74 |
|       4 |       5428 |                 1,522,984 |                     626,393 |                   37.97 |                       7.35 |
|       5 |       5478 |                 1,655,740 |                     582,462 |                   34.96 |                      -3.01 |
|       6 |       5292 |                 1,898,485 |                     753,684 |                   39.61 |                       4.65 |
|       7 |       4572 |                 2,307,893 |                     782,874 |                   32.79 |                      -6.82 |
|       8 |       5063 |                 2,897,536 |                   1,088,211 |                   36.05 |                       3.26 |
|       9 |       5394 |                 2,065,762 |                     776,119 |                   37.49 |                       1.44 |
|      10 |       6203 |                 1,839,343 |                     767,242 |                   40.53 |                       3.04 |
|      11 |       4454 |                 1,137,167 |                     448,324 |                   36.73 |                      -3.8  |
|      12 |       3860 |                 1,126,844 |                     468,973 |                   36.22 |                      -0.51 |

**Interpretation:** In 2016 the estimated booking value peaks in August (about 2.9 million) and the estimated value at risk peaks the same month (about 1.1 million). The month-to-month change in rate moves up and down (for example +9.6 points from January to February, -6.8 from June to July), which is another sign that single months are noisy.

### Q20. Sensitivity check: hotel cancellation rate with and without duplicate rows

**Business question:** Do the hotel results change if exact duplicate rows are removed?

```sql
SELECT hotel,
       COUNT(*)                                                                AS bookings_all_rows,
       ROUND(100.0 * SUM(is_canceled) / COUNT(*), 2)                           AS rate_all_rows_pct,
       SUM(CASE WHEN is_duplicate_row = 0 THEN 1 ELSE 0 END)                   AS bookings_no_duplicates,
       ROUND(100.0 * SUM(CASE WHEN is_duplicate_row = 0 THEN is_canceled END)
                   / SUM(CASE WHEN is_duplicate_row = 0 THEN 1 END), 2)        AS rate_no_duplicates_pct
FROM hotel_bookings
GROUP BY hotel;
```

**Result:**

| hotel        |   bookings_all_rows |   rate_all_rows_pct |   bookings_no_duplicates |   rate_no_duplicates_pct |
|:-------------|--------------------:|--------------------:|-------------------------:|-------------------------:|
| City Hotel   |              79,330 |               41.73 |                   53,428 |                    30.04 |
| Resort Hotel |              40,059 |               27.76 |                   33,967 |                    23.48 |

**Interpretation:** After removing exact duplicate rows City Hotel falls from 41.73% to 30.04% and Resort Hotel from 27.76% to 23.48%. City Hotel is still higher, but the gap shrinks from about 14 points to about 6.5. So the City vs Resort conclusion survives, the size of the gap depends on the duplicates.
