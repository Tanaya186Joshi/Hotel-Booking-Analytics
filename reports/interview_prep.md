# Questions a Data Analyst interviewer may ask

Answers are written the way I'd say them out loud, using the numbers from this project. If a number is asked for, I know where it comes from (notebook, SQL query, or dashboard measure).

---

## About the project and the choices I made

**1. Why did you choose this dataset?**
I wanted a business problem I could explain to anyone in one sentence: bookings get cancelled and the hotel loses the chance to sell that room. The dataset has two hotels, about 119,000 bookings and columns for things I could actually test, like lead time, channel and deposit type. It's also messy, with duplicates, missing values and some strange rows, so I had to make real cleaning decisions.

**2. What was the biggest data-cleaning issue?**
The 31,994 identical rows, about 27% of the file. There's no booking ID, so I couldn't tell whether they were the same booking entered twice or separate bookings with the same details. They also weren't random: they cancel much more often (63% against 27% for the other rows) and sit mostly in Groups and Offline TA/TO. If I'd deleted them, the cancellation rate would have gone from 37.04% to 27.49%. Deleting them would have been a guess, so I kept them, flagged them with `is_duplicate_row`, and wrote it down as a limitation.

**3. How did you handle missing values?**
It depended on the column. `children` had 4 missing values, all on bookings with two or more adults, so I filled them with 0. `country` had 488 missing, which I labelled `Unknown` because those bookings cancel at a very different rate (about 14%) and dropping them would have hidden that. `agent` and `company` are mostly empty because many bookings simply don't have one, so I kept them missing and made `has_agent` and `has_company` flags.

**4. How did you handle outliers?**
There was one ADR of 5,400 when the next highest is 510. It's a real booking (it was cancelled), so I kept it in the booking and cancellation counts but blanked its ADR in a separate column so it doesn't affect ADR averages or value totals. One negative ADR was clearly invalid and I removed it. ADR = 0 rows I kept, because some are complimentary stays, and just left them out of average ADR. The 16 rows with very big parties (for example 10 to 55 adults) are all cancelled Group bookings, so I flagged them and left them in.

**5. Why did you use Python, SQL and Power BI?**
Each did a different job. Python (pandas) for cleaning and exploring, because I could check things quickly and draw charts. SQL for the structured questions a business would ask repeatedly, like rates by segment or country. Power BI so someone who doesn't code can filter the results and see the numbers themselves.

**6. Why SQL specifically? You already had pandas.**
Most analyst jobs have the data in a database, so I wanted to show I can answer the same questions there. I also used it as a check: the SQL totals and the main rates match my pandas results.

**7. Why didn't you build a machine learning model?**
The questions were about *which* bookings cancel and what to do about it, not about predicting individual bookings. Descriptive analysis answers that. A model would also be risky here: some columns already contain the answer (like `reservation_status`, which just repeats the outcome) and would leak it. I'd rather show clean analysis than add a model for the sake of it.

---

## KPIs and definitions

**8. How did you calculate the cancellation rate?**
Cancelled bookings divided by total bookings. Cancelled means `is_canceled = 1`, which includes no-shows. So 44,224 out of 119,389 is 37.04%. 1,207 of those are no-shows.

**9. What is ADR?**
Average Daily Rate: the average price per room per night on a booking. A 3-night stay at an ADR of 100 is worth about 300.

**10. What do you mean by "revenue at risk" or "revenue loss"?**
I only use "estimated revenue at risk". It's ADR times nights for bookings that were cancelled or no-shows. For this data that's about 16.7 million out of an estimated 42.7 million. It's a way of sizing the exposure, not a loss figure.

**11. What's the difference between booking value and actual revenue?**
Booking value is what the stay would be worth at the recorded rate. Actual revenue depends on what was paid. The data doesn't have payments, deposits kept, refunds, cancellation fees, or whether a cancelled room was resold. A cancelled booking might have brought in a fee, or the room might have been rebooked, so the real loss could be smaller (or occasionally different). That's why I call it an estimate and use it to compare segments, not to quote a loss.

**12. Why did you choose these KPIs?**
They answer the business questions directly: how many bookings and how many cancelled (volume and rate), how much value is exposed (estimated booking value and revenue at risk), and context metrics a hotel manager already uses (ADR, lead time, stay length). I also defined repeat guest % and average special requests in the notebook, but I treat the repeat guest number cautiously because the flag is inconsistent, and I left both off the dashboard.

**13. Why do you exclude ADR = 0 from average ADR but not from the counts?**
A free stay would drag the average price down, which would misstate the typical price. But it's still a booking, and it can still be cancelled, so it belongs in the counts.

---

## Findings

**14. What was your most important finding?**
Lead time. The cancellation rate goes from 9.6% for bookings made within a week of arrival to 67.7% for bookings made more than a year ahead. It rises at every step and shows up in both hotels. One caution: the top group (365+ days) is partly Non Refund bookings, and for No Deposit only it is 20.6%. It's also useful because the hotel knows the lead time on the day of booking.

**15. Which finding surprised you?**
Two. First, Non Refund bookings cancelling 99.4% of the time, which is the opposite of what you'd expect. Second, how much of the file is identical rows, and that they cancel at 63% against 27% for the other rows. Also that Groups looks like the worst segment (61.1%) but drops to 28.3% for No Deposit bookings only.

**16. What would you recommend to the hotel?**
Three ideas, none of them tested: treat bookings made far in advance as less certain (for example a reminder or reconfirmation closer to arrival); look at the cancellation terms with Online TA partners, since that segment is 47% of bookings and holds about 61% of the estimated revenue at risk, and check whether more direct bookings would help because Direct cancels less; and plan for more cancellations at City Hotel than at Resort Hotel when forecasting occupancy.

**17. What would you do if the hotel rejected your recommendation?**
I'd ask why, because they may know something the data doesn't, like contract terms with agents. Then I'd offer a smaller test: try the reconfirmation message on one rate plan for a few weeks and compare it with a similar group of bookings. That way they get evidence from their own business instead of relying on my analysis of old data.

**18. Did you find anything you chose NOT to recommend?**
Yes. I didn't make a deposit recommendation because of the Non Refund result, since a 99% cancellation rate is not believable behaviour and I can't explain it with this data. I also didn't say Groups is the problem segment, because almost half of Groups is Non Refund bookings (28.3% for No Deposit only). And I didn't say anything about seasons, because the same month changes a lot between years.

**19. Are you claiming that long lead times cause cancellations?**
No. I'm saying they go together. It makes sense that plans change more over a longer time, but I can't prove it from this data. Other things could be involved, like the channel or the rate plan.

**20. Why didn't you claim a seasonal pattern?**
The data starts in July 2015 and ends in August 2017, so 2016 is the only full year, and the same month changes a lot between years (July was 45.4% in 2015, 32.8% in 2016, 37.3% in 2017). I show the monthly numbers but I don't say summer is riskier.

**21. Explain the Groups segment result.**
Groups had the highest rate (61.07%), but nearly half of those bookings are Non Refund bookings that cancel about 99% of the time. For bookings with No Deposit only, Groups drops to 28.3%. So I'm not claiming Groups is the problem segment. I'd ask the hotel what those bookings are first.

---

## Limitations and validation

**22. What limitations does the dataset have?**
No booking ID, so the duplicates can't be confirmed; no payment or refund data, so revenue is an estimate; `is_canceled` mixes cancellations and no-shows; the repeat-guest flag disagrees with the previous-bookings columns on thousands of rows; the Non Refund pattern is odd; there's one full year; and the data ends in 2017.

**23. How did you validate your analysis?**
I checked the SQL totals against the pandas totals, and the main rates (hotel, segment, channel, deposit type, lead time) against the notebook. I measured how much the identical rows change the overall rate (37.04% vs 27.49%). I checked the Groups and Non Refund results from a few angles (by deposit type, by country). I also looked at the raw rows behind the odd results instead of trusting the summary.

**24. What would you improve if you had more data?**
A booking ID to settle the duplicates; payment, refund and fee data so I could measure real revenue impact; the reason for each cancellation; rate plan and cancellation policy per booking; and more full years for seasonality. With those I'd be able to say a lot more about causes.

**25. Did you accidentally claim causation anywhere?**
I tried not to. I wrote "goes with", "associated with" and "possible reason" and kept possible reasons separate from evidence. The lead-time result is a good example: it's easy to say "long lead times cause cancellations", but all I know is that the two go together. Other things, like the channel or the rate plan, could be involved.

**26. What is data leakage and where did it show up?**
Using information that already contains the answer. `reservation_status` is literally Canceled, Check-Out or No-Show, so using it to explain cancellation would be circular. I checked it against `is_canceled` in the notebook and only used it to mark the no-shows.

---

## SQL

**27. What SQL concepts did you use?**
`GROUP BY` with aggregates (COUNT, SUM, AVG), `CASE WHEN` for lead-time groups and conditional sums, `HAVING` to ignore small groups, subqueries for the overall rate, CTEs for multi-step logic, window functions (`RANK`, `LAG`, and `SUM() OVER ()` for shares), and conditional aggregation for the duplicate comparison.

**28. Explain one of your SQL queries.**
The country ranking (Query 16). A CTE called `country_stats` groups bookings by country, counts bookings and cancellations, and works out the rate, keeping only countries with at least 1,000 bookings through `HAVING` so tiny countries with a 100% rate don't take over. The final `SELECT` ranks them with `RANK() OVER (ORDER BY cancel_rate DESC)` and uses a subquery to calculate the overall rate, so I can show how many percentage points each country is above or below it. Portugal comes first at 56.64%, 19.6 points above the overall rate.

**29. Why `HAVING COUNT(*) >= 1000` instead of `WHERE`?**
`WHERE` filters rows before grouping, and I need to filter on the group's size, which only exists after grouping. That's what `HAVING` is for.

**30. Why 100.0 in `100.0 * SUM(is_canceled) / COUNT(*)`?**
In SQLite (and some other databases) dividing two integers gives an integer, so the result would be cut to 0. Multiplying by 100.0 first makes it a decimal.

---

## Power BI

**31. Explain one Power BI measure.**
`Cancellation Rate = DIVIDE([Cancelled Bookings], [Total Bookings])`. `Cancelled Bookings` is a `CALCULATE` that counts rows with `is_canceled = 1`. In a chart split by market segment, each bar has its own filter context, so one measure gives a different rate for each segment. `DIVIDE` returns blank instead of an error when a group is empty.

**32. Why did you use measures instead of calculated columns for the KPIs?**
Measures are calculated when the visual is drawn and respond to slicers. A column holds a value per row and doesn't. A rate has to be recalculated from the filtered counts, so it must be a measure. I used calculated columns only for labels like stay length group.

**33. Why does the ADR by room type chart only show some room types?**
I filtered it to room types with at least 300 bookings in a hotel, because an average from a handful of bookings isn't reliable. The footnote on the page says so.

**34. What would you change in the dashboard for a hotel manager?**
Add a rolling 4-week cancellation rate in place of the full history, a last-7-days cancellation view, and a table of the rate plans or agents with the highest rates (which I can't build from this data).

**35. Why only 2 to 3 pages?**
So that each page answers one question: how is business doing, where do cancellations come from, and where is the value. More pages would just repeat the same charts.

---

## The extra analysis and how I worked

**36. What was your extra analysis about?**
I asked whether bookings with children cancel less. My guess was yes. With all rows the rates were almost the same (37.09% without children, 36.39% with children). Without the identical rows, bookings with children cancelled more (35.69% vs 26.62%), because almost all the identical rows are bookings without children. So my guess wasn't supported, and since I can't tell if those rows are real duplicates, I can't say either way.

**37. Did you use AI tools for this project?**
Yes, quite a lot. I used Claude to write the first drafts of most of the code and the written notes, and to guide me step by step through the Power BI dashboard. The project idea, the choices about the messy data (keeping the duplicates, blanking the ADR outlier, not trusting Non Refund) and the extra analysis question were mine. I ran every cell and built the dashboard myself, and I asked for the notebook to be cut down to simple questions I could follow. Where I'm not sure about something, I say so.

---

# Resume bullets

Use the numbers exactly as they appear in the project.

- Cleaned and analysed 119K+ hotel booking records (32 columns) using Python and Pandas, handling missing values, an extreme ADR outlier, zero-guest and zero-night records, and 31,994 identical rows; documented each decision in a reproducible notebook.
- Wrote 20 SQL queries (CASE WHEN, CTEs, window functions, subqueries) to compare cancellation rates by hotel, market segment, channel, country and lead-time group; showed that 37.0% of bookings were cancelled or no-shows and that the rate rises from 9.6% (booked 0-7 days ahead) to 67.7% (booked over a year ahead).
- Defined KPIs and an estimated booking value (ADR x nights) to size cancellation exposure (about 16.7M of 42.7M estimated value), found that Online TA bookings carried about 61% of it, and flagged patterns I did not trust (Groups, Non Refund) instead of building recommendations on them.
- Designed a 3-page Power BI dashboard with DAX measures and slicers (hotel, year, month, segment, customer type) tracking cancellation rate, estimated revenue at risk, ADR and booking trends.
