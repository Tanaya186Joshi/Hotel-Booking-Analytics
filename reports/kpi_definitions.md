# KPI definitions

Used the same way in Python, SQL and Power BI. Values are for the full cleaned dataset (119,389 rows, all rows kept).

| KPI | Definition | Value |
|---|---|---|
| Total Bookings | Number of rows | 119,389 |
| Cancelled Bookings | Rows with `is_canceled = 1` (cancellations and no-shows) | 44,224 |
| Confirmed Bookings | Rows with `is_canceled = 0` | 75,165 |
| Cancellation Rate | Cancelled Bookings / Total Bookings | 37.04% |
| Average ADR | Mean of `adr_clean`, leaving out `adr_zero = 1` rows (and the one blanked outlier) | 103.49 |
| Average Lead Time | Mean of `lead_time` (days) | 104.0 |
| Average Stay Length | Mean of `total_stay_nights`, leaving out zero-night bookings | 3.45 nights |
| Estimated Booking Value | Sum of `adr_clean` x `total_stay_nights` | about 42.72 million |
| Estimated Revenue at Risk | Estimated Booking Value of rows with `is_canceled = 1` | about 16.72 million (39.1% of value) |
| Repeat Guest % | Rows with `is_repeated_guest = 1` / Total Bookings (approximate, the flag is inconsistent) | 3.19% |
| Average Special Requests | Mean of `total_of_special_requests` | 0.57 |

## Why Estimated Revenue at Risk is an estimate

ADR is the average daily rate on a booking. ADR x nights gives what the booking would be worth *if the stay happened at that rate*. For a cancelled booking this is potential value that may not have been collected. It is **not** the hotel's accounting loss, because the dataset does not include:

- payments or deposits actually received,
- refunds or cancellation fees,
- whether the cancelled room was sold to someone else,
- taxes, extras, or the currency (the currency isn't stated).

The metric is useful for comparing segments, hotels and months against each other. It should not be quoted as money the hotel lost.

## How the awkward rows are handled

| Case | Rows | Treatment in KPIs |
|---|---|---|
| ADR = 0 | 1,959 | Counted in bookings and cancellations. Left out of Average ADR. Value is 0. |
| ADR outlier (5,400) | 1 | Counted in bookings and cancellations. `adr_clean` blank, so left out of ADR and value sums. |
| Zero stay nights | 715 | Counted in bookings. Left out of Average Stay Length. Value is 0. |
| Zero guests | 180 | Counted in bookings. Left out of guest-based analysis. |
| Negative ADR | 1 | Removed from the cleaned data. |
| Identical rows | 31,994 | Kept in the main KPIs and flagged with `is_duplicate_row`. Without them the cancellation rate would be about 27.5%. |
