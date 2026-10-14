# Power BI build guide

This guide records how I built the dashboard (`powerbi/hotel_booking_dashboard.pbix`): the data model, the Power Query steps, the DAX measures and columns, what is on each page, and the numbers I checked it against. Screenshots of the three pages are in `powerbi/screenshots/`.

## 1. Data model

One table is enough here. Everything I need (hotel, segment, channel, dates, flags) is already a column, and splitting it into dimension tables would add complexity without helping any visual. I'd mention in an interview that for a bigger, live dataset I'd use a star schema with a date table.

- Table name: `hotel_bookings` (rename on import)
- Source: `data/cleaned/hotel_bookings_cleaned.csv` (Get Data > Text/CSV)
- Rows: 119,389. Columns: 52.

## 2. Power Query (Transform Data)

| Column(s) | Type |
|---|---|
| `arrival_date`, `estimated_booking_date`, `reservation_status_date` | Date |
| `adr`, `adr_clean`, `estimated_booking_value`, `agent`, `company` | Decimal number |
| all the flag columns (`is_canceled`, `adr_zero`, `zero_stay_nights`, `is_duplicate_row`, ...), counts, lead time | Whole number |
| `hotel`, `country`, `market_segment`, `distribution_channel`, `deposit_type`, `customer_type`, `reserved_room_type`, text columns | Text |

Check that the blank values in `adr_clean` and `estimated_booking_value` stay **blank** (null) and don't turn into 0. Then Close & Apply.

## 3. Column settings (Data view)

| Column | Setting |
|---|---|
| `arrival_date_month` | Sort by column > `arrival_month_num` |
| `lead_time_bucket` | Sort by column > `lead_time_bucket_order` |
| `adr`, `adr_clean`, `estimated_booking_value` | Summarization: Don't summarize (all numbers come from measures) |
| `estimated_booking_value` | Format: whole number with thousands separator |
| Hide from report view | `agent`, `company`, `reservation_status`, `estimated_booking_date`, `adr` (keep `adr_clean`), `*_order` columns |

## 4. Calculated columns (DAX)

```dax
Stay Length Group =
SWITCH (
    TRUE (),
    hotel_bookings[total_stay_nights] = 0, "0 nights",
    hotel_bookings[total_stay_nights] = 1, "1 night",
    hotel_bookings[total_stay_nights] <= 3, "2-3 nights",
    hotel_bookings[total_stay_nights] <= 7, "4-7 nights",
    "8+ nights"
)

Stay Length Order =
SWITCH (
    TRUE (),
    hotel_bookings[total_stay_nights] = 0, 1,
    hotel_bookings[total_stay_nights] = 1, 2,
    hotel_bookings[total_stay_nights] <= 3, 3,
    hotel_bookings[total_stay_nights] <= 7, 4,
    5
)
```
Then set `Stay Length Group` to sort by `Stay Length Order`.

## 5. Measures (DAX)

Create a separate empty table called `_Measures` (Enter Data) and put these in it so they're easy to find.

```dax
Total Bookings = COUNTROWS ( hotel_bookings )

Cancelled Bookings =
CALCULATE ( [Total Bookings], hotel_bookings[is_canceled] = 1 )

Confirmed Bookings =
CALCULATE ( [Total Bookings], hotel_bookings[is_canceled] = 0 )

Cancellation Rate =
DIVIDE ( [Cancelled Bookings], [Total Bookings] )

Average ADR =
CALCULATE ( AVERAGE ( hotel_bookings[adr_clean] ), hotel_bookings[adr_zero] = 0 )

Average Lead Time = AVERAGE ( hotel_bookings[lead_time] )

Average Stay Length =
CALCULATE ( AVERAGE ( hotel_bookings[total_stay_nights] ), hotel_bookings[zero_stay_nights] = 0 )

Estimated Booking Value = SUM ( hotel_bookings[estimated_booking_value] )

Estimated Revenue at Risk =
CALCULATE ( [Estimated Booking Value], hotel_bookings[is_canceled] = 1 )

Revenue at Risk % =
DIVIDE ( [Estimated Revenue at Risk], [Estimated Booking Value] )

Repeat Guest % =
DIVIDE ( CALCULATE ( [Total Bookings], hotel_bookings[is_repeated_guest] = 1 ), [Total Bookings] )

Average Special Requests = AVERAGE ( hotel_bookings[total_of_special_requests] )

```

**Explaining one measure in an interview (`Cancellation Rate`):** `DIVIDE(Cancelled, Total)`. `Cancelled Bookings` is a `CALCULATE` that counts rows where `is_canceled = 1`. When a visual is split by market segment, each bar gets its own filter context, so the same measure gives a different rate per segment without writing anything new. `DIVIDE` is used instead of `/` so an empty group shows blank instead of an error.

**Why `Average ADR` uses CALCULATE with `adr_zero = 0`:** zero-ADR rows (some are complimentary stays) would pull the average down. The one 5,400 outlier is already blank in `adr_clean`, and `AVERAGE` ignores blanks.

## 6. Dashboard canvas

Canvas: 16:9 (1280 x 720). Import `hotel_theme.json` (View > Themes > Browse for themes). Page background light grey, visuals white with a thin grey border. One font. Blue for normal values, red only for cancellation or risk. No images, no logos, no shadows.

Number formats: Cancellation Rate `0.0%`, bookings `#,0`, revenue figures `#,0.0,,"M"` (millions), ADR `0.00`.

Every page gets a small footnote text box:
> "Cancelled = cancelled bookings + no-shows. Estimated Revenue at Risk = ADR x nights for cancelled bookings; it is an estimate, not actual revenue. 2015 covers Jul-Dec and 2017 covers Jan-Aug."

### Page 1: Executive Overview ("How is the booking business performing?")

- Title text box: "Hotel Booking Cancellations: Overview"
- Slicer (dropdown): `hotel`
- Five cards: `[Total Bookings]`, `[Cancelled Bookings]`, `[Cancellation Rate]`, `[Estimated Revenue at Risk]`, `[Average ADR]`
- Line chart "Bookings by arrival month": X `arrival_year_month`, Y `[Total Bookings]`
- Line chart "Cancellation rate by arrival month": X `arrival_year_month`, Y `[Cancellation Rate]`
- Column chart "Cancellation rate by hotel": X `hotel`, Y `[Cancellation Rate]`
- Table "Hotel comparison": `hotel`, `[Total Bookings]`, `[Cancelled Bookings]`, `[Cancellation Rate]`, `[Estimated Booking Value]`, `[Estimated Revenue at Risk]`, `[Average ADR]`. I renamed the long column headers for this visual ("Est. Booking Value", "Est. Revenue at Risk") and set the money columns to display in millions so the numbers match the cards.
- Footnote text box (text above)

### Page 2: Cancellation Analysis

Slicers across the top (dropdown style): `hotel`, `arrival_date_year`, `arrival_date_month`, `market_segment`, `customer_type`.

- Bar chart "Cancellation rate by market segment": Y `market_segment`, X `[Cancellation Rate]` (data labels on, sorted by rate)
- Bar chart "Cancellation rate by distribution channel": Y `distribution_channel`, X `[Cancellation Rate]`
- Column chart "Cancellation rate by customer type": X `customer_type`, Y `[Cancellation Rate]`
- Column chart "Cancellation rate by lead time": X `lead_time_bucket`, Y `[Cancellation Rate]`
- Column chart "Cancellation rate by deposit type": X `deposit_type`, Y `[Cancellation Rate]`, with a small text box under it: "Non Refund bookings cancel about 99%. Looks like a dataset issue; no conclusion drawn."
- Line chart "Cancellation rate by month": X `arrival_date_month`, Legend `arrival_date_year`, Y `[Cancellation Rate]`
- Footnote text box (text above)

Tooltip tip: add `[Total Bookings]` to the tooltips of the bar charts. A 100% rate on 2 bookings (the `Unknown` segment) shouldn't look like a finding. A visual-level filter `[Total Bookings] >= 100` also works.

### Page 3: Revenue & Customers

Slicers: `hotel`, `arrival_date_year`.

- Clustered bar "Booking value and revenue at risk by hotel": Y `hotel`, X `[Estimated Booking Value]`, `[Estimated Revenue at Risk]`
- Clustered column "Average ADR by reserved room type": X `reserved_room_type`, Legend `hotel`, Y `[Average ADR]`. Visual-level filter `[Total Bookings] >= 300`, so room types with very few bookings in a hotel are left out. This filter counts all bookings, while the notebook (Q10) counts only bookings with an ADR above 0, so the two can differ slightly for room types close to 300.
- Bar chart "Top 10 countries by bookings": Y `country`, X `[Total Bookings]`, Top N filter 10 by `[Total Bookings]`
- Column chart "Bookings by stay length": X `Stay Length Group`, Y `[Total Bookings]`
- Bar chart "Estimated booking value by segment": Y `market_segment`, X `[Estimated Booking Value]`, `[Estimated Revenue at Risk]`
- Footnote text box (text above) plus one extra sentence: "Room types with fewer than 300 bookings in a hotel are left out."

Layout: 3 + 2 grid on a 1280 x 720 canvas, 20 px gaps, footnote directly under the last row.

## 7. Numbers to check before you trust the report

With **no slicers selected**, you should see:

| Measure | Expected |
|---|---|
| Total Bookings | 119,389 |
| Cancelled Bookings | 44,224 |
| Cancellation Rate | 37.04% |
| Estimated Booking Value | about 42.72M |
| Estimated Revenue at Risk | about 16.72M |
| Average ADR | 103.49 |
| City Hotel / Resort Hotel cancellation rate | 41.73% / 27.76% |

If your numbers differ, check the column types in Power Query first (most often blanks turned into 0).

## 8. What I'd change for a hotel manager

- Add a "last 7 days" cancellation view (needs the cancellation date, which I only approximate with `reservation_status_date`).
- Replace the month-by-month view with a rolling 4-week rate, so a manager sees a recent trend, not history.
- Add a table of the rate plans or agents with the highest cancellation rate, which I can't do with these columns.
