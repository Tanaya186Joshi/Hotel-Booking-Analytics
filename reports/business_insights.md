# Business insights

These are the findings I'm comfortable standing behind after the cleaning, SQL and EDA work. Every number comes from `data/cleaned/hotel_bookings_cleaned.csv` (119,389 rows, all rows kept, including the 31,994 flagged identical rows). I can't tell if those rows are real duplicates. Without them the overall cancellation rate would be about 27.5% instead of 37.04%, so every rate below is "in this file", and I come back to this in the limitations.

Two reminders that apply to everything below:

- `is_canceled = 1` means cancelled **or** no-show (1,207 of the 44,224 are no-shows).
- "Estimated revenue at risk" is ADR x nights for cancelled bookings. It is an analytical estimate. The data has no payments, refunds, cancellation fees, or information about whether a cancelled room was resold, so it is not the hotel's actual loss.

All of these are associations in observational data. None of them proves that a factor *causes* cancellations.

---

## Insight 1: Bookings made further ahead are cancelled more often

**Observation.** The cancellation rate goes up with every step of lead time.

**Evidence.**

| Lead time | Bookings | Cancellation rate |
|---|---|---|
| 0-7 days | 19,746 | 9.63% |
| 8-30 days | 18,960 | 27.86% |
| 31-90 days | 29,553 | 37.70% |
| 91-180 days | 26,439 | 44.71% |
| 181-365 days | 21,543 | 55.46% |
| 365+ days | 3,148 | 67.66% |

Cancelled bookings were made 144.8 days ahead on average (median 113), confirmed ones 80.0 days ahead (median 45). The notebook (Q7) shows the same pattern in both hotels.

**One caution.** For bookings with no deposit, the climb continues up to 181-365 days (39.83%) but the 365+ group drops to 20.62%. So the very top of the scale is partly the odd Non Refund bookings (Insight 7), not only lead time.

**Possible reason.** The further away a stay is, the more time there is for plans to change, and people may book several options early and drop some. The data doesn't contain reasons for cancellation, so this is a guess.

**Business implication.** Long-lead bookings are less certain than short-lead ones, and the hotel knows the lead time the day the booking is made.

**Suggested action (not tested).** Treat bookings made far in advance as less certain, for example with a reminder or reconfirmation message closer to arrival.

---

## Insight 2: Online travel agent bookings are where most of the cancellation sits

**Observation.** Online TA is the largest segment and cancels at a high rate. Direct bookings cancel far less.

**Evidence.**
- Online TA: 56,477 bookings (47% of all), 20,739 cancelled (47% of all cancellations), rate 36.72%.
- Channel view: TA/TO 41.03% (97,870 bookings) vs Direct 17.46% (14,644) vs Corporate 22.08% (6,677).
- If Portugal is excluded, Online TA is still 34.4%, while most other segments drop to single digits or low teens.

**Possible reason.** Guests who book through an intermediary may find it easier or cheaper to cancel, or may book several hotels at once. I can't see the cancellation terms attached to each booking, so I can't confirm that.

**Business implication.** Because Online TA is large and consistently high, it moves the total more than any other segment.

**Suggested action (not tested).** Look at the cancellation terms with Online TA partners. Direct bookings cancel less, so it could be worth checking whether more direct bookings would help.

---

## Insight 3: City Hotel cancels more than Resort Hotel

**Observation.** City Hotel has a higher rate and also most of the volume.

**Evidence.**
- City Hotel 41.73% (33,102 of 79,330) vs Resort Hotel 27.76% (11,122 of 40,059).
- City Hotel is 66% of bookings but 75% of all cancellations.
- Estimated revenue at risk: about 10.9 million at City Hotel (43% of its estimated booking value) vs about 5.8 million at Resort Hotel (33.5%).

**Possible reason.** Different guest mix (shorter city stays, more transient bookings, different channel mix). City Hotel contract bookings cancel at 48.0% against 8.8% at Resort Hotel, which hints that the two hotels use contracts differently. I haven't tested any of this.

**Business implication.** City Hotel is the first place to look, since changes there affect three-quarters of cancellations.

**Suggested action (not tested).** Plan for more cancellations at City Hotel than at Resort Hotel when forecasting occupancy.

---

## Insight 4: Portugal is a large share of cancellations

**Observation.** One country accounts for a big share of the cancellation volume.

**Evidence.** Portugal (PRT): 48,590 bookings (41% of the file), 27,519 cancelled (62% of all cancellations), rate 56.64%. Every other country combined is at 23.59%. GBR 20.23%, FRA 18.57%, ESP 25.41%, DEU 16.71%. PRT with no-deposit bookings only is still 38.86%.

**Possible reason.** Part of it is the Non Refund group, which is almost entirely Portuguese (14,176 of 14,587 bookings). The file doesn't say where the hotels are, so I can't confirm a "home market" explanation.

**Business implication.** Overall cancellation figures are heavily shaped by one country. Rates for international guests are lower.

**Suggested action.** None yet. I'd look at domestic and international bookings separately before drawing conclusions from the overall rate.

---

## Insight 5: Where the estimated revenue at risk sits

**Observation.** The estimated booking value attached to cancelled bookings is large, and one segment carries most of it.

**Evidence.** Estimated booking value is about 42.7 million, of which about 16.7 million (39.1%) is attached to cancelled or no-show bookings. By segment, Online TA is about 10.2 million (61.2% of the total at risk), Groups 2.8 million (16.7%), Offline TA/TO 2.5 million (14.9%), Direct 1.0 million (5.9%).

**Possible reason.** It follows from Insight 2: Online TA is the biggest segment and also has a high cancellation rate, so even a moderate rate adds up to the largest value.

**Business implication.** If the hotel only had time to look into one segment, Online TA is the one where the estimated exposure is biggest.

**Suggested action.** Same as Insight 2. For planning, use the revenue-at-risk figure only to compare segments and hotels, not as a loss number.

**Limit.** This is ADR x nights. No payments, refunds, cancellation fees or resale information are in the data.

---

## Insight 6: Stay length

**Observation.** The cancellation rate doesn't just go up with the length of the stay.

**Evidence.** Most bookings are for 2-3 nights (54,719 bookings, about 46%). 2-3 nights has the highest cancellation rate (42.97%), then 4-7 nights (35.90%) and 8+ nights (35.75%). 1 night has the lowest (25.08%). The 0 nights group has only 715 bookings and a rate of 4.90%, so I don't read much into it.

**Possible reason.** I don't know. I haven't checked it against hotel, channel or lead time.

**Business implication.** None that I'd act on yet.

**Suggested action.** None. I'd look at stay length together with hotel and channel first.

---

## Insight 7: Some patterns I decided not to build recommendations on

I found several results that look dramatic but that I don't trust enough to turn into advice.

**Groups segment (61.07%).** Almost half of Groups bookings (9,172 of 19,810) are Non Refund bookings that cancel at about 99%. For No Deposit bookings only, Groups is 28.3%. So "Groups is the worst segment" depends on the odd rows. I'd want the hotel to explain those bookings first.

**Non Refund deposit type (99.36%).** A non-refundable booking should be the least likely to be cancelled, so a 99% rate is not what I'd expect. It could be a dataset-specific issue (for example, how the field was recorded). Non Refund bookings are almost all Portuguese, make up about a third of all cancelled bookings, and drop from 14,587 to only 1,038 rows once the identical rows are removed. I report it as observed and make no recommendation about deposits.

**Seasonality.** The same month isn't the same each year (July is 45.4% in 2015, 32.8% in 2016 and 37.3% in 2017), and the data starts and ends mid-year. I can't say summer is riskier.

**Bookings with children.** My extra notebook asks whether they cancel less. With all rows the rates are almost the same (37.09% vs 36.39%). Without the identical rows, bookings with children cancel more (35.69% vs 26.62%). Almost all the identical rows are bookings without children, so the answer depends on how those rows are treated, and I can't say either way.

**Repeat guests.** The repeat-guest flag disagrees with the previous-bookings columns (590 rows flagged repeat with no previous bookings, 6,237 not flagged with previous bookings), so I treat anything about repeat guests as approximate.

---

## Summary of suggestions

| # | Suggestion | Based on | How sure I am about the pattern |
|---|---|---|---|
| 1 | Reminder or reconfirmation for bookings made far in advance | Insight 1 | High (rises at every step, both hotels), but the 365+ group is partly Non Refund |
| 2 | Look at cancellation terms with Online TA partners, and check whether more direct bookings would help | Insights 2, 5 | Medium-High (the action itself is untested) |
| 3 | Plan for more cancellations at City Hotel when forecasting | Insight 3 | High for the gap, but I don't know why |
| 4 | Ask the hotel how `deposit_type` is recorded before any deposit decision | Insight 7 | n/a (a question, not an action) |

## If the hotel rejects a suggestion

I'd go back to a smaller test. For example, trial the reconfirmation message on one rate plan or one hotel for a few weeks and compare the cancellation rate with a similar group of bookings. That gives the hotel its own evidence, and it respects that I only have observational data.

## Limitations

- No booking ID, so identical rows can't be confirmed as duplicates. They're 26.8% of the file and would change the headline rate from 37.04% to 27.49%.
- No actual payments, refunds, fees or resale information. All revenue figures are estimates.
- `is_canceled` mixes cancellations and no-shows.
- The repeat-guest flag and the previous-bookings columns disagree for several thousand rows.
- The Non Refund deposit pattern is unexplained.
- 2015 has only July to December and 2017 only January to August, so year-on-year comparisons aren't valid.
- Observational data: I can describe which things go together with cancellations, not what causes them.
- The dataset covers two hotels and a period that ended in 2017, so it may not describe a hotel today.
