# Cleaned dataset: columns I added or changed

The cleaned file is `data/cleaned/hotel_bookings_cleaned.csv`. It keeps the original columns (apart from the cleaning described in the notebook) and adds these.

| Column | What it is | How it's calculated |
|---|---|---|
| `is_no_show` | 1 if the booking was a no-show | `reservation_status = 'No-Show'` |
| `total_guests` | Party size | adults + children + babies |
| `total_stay_nights` | Nights booked | stays_in_weekend_nights + stays_in_week_nights |
| `adr_clean` | ADR used for analysis | `adr`, left blank for the one outlier (5,400) |
| `estimated_booking_value` | ADR x nights, an estimate | `adr_clean` x `total_stay_nights` (blank for the outlier) |
| `lead_time_bucket`, `lead_time_bucket_order` | Lead-time group and a number for sorting | 0-7, 8-30, 31-90, 91-180, 181-365, 365+ days |
| `arrival_date` | Arrival date | built from year, month name and day |
| `arrival_month_num`, `arrival_year_month` | Month number and 'YYYY-MM' text | from `arrival_date` |
| `estimated_booking_date` | Approximate booking date | `arrival_date` minus `lead_time` days |
| `has_agent`, `has_company` | 1 if an agent / company ID exists | `agent` / `company` not missing |
| `room_changed` | Assigned room differs from reserved | `reserved_room_type != assigned_room_type` |
| `adr_zero` | ADR = 0 | flag |
| `adr_outlier` | ADR over 1,000 (one row) | flag |
| `zero_guests` | No guests recorded (180 rows) | flag |
| `zero_stay_nights` | No nights recorded (715 rows) | flag |
| `extreme_guest_count` | adults >= 10, children >= 5 or babies >= 5 (16 rows) | flag |
| `is_duplicate_row` | Extra copy of an identical row (31,994 rows) | `duplicated()` on the original 32 columns, first copy not flagged |

Changed values: `children` missing -> 0; `country` missing -> `Unknown`; `Undefined` in meal, market_segment and distribution_channel -> `Unknown`; `reservation_status_date` converted to a date. One row with a negative ADR was removed (119,390 -> 119,389 rows).

`reservation_status` is kept in the file only to identify no-shows. It restates the outcome, so it is **not** used as a predictor.
