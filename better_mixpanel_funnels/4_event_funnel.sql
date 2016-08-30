/*
For a given EVENTS_TABLE build a 4 step "funnel" for events A, B, C, and D to show conversion rates between the FUNNEL_START_DATE and FUNNEL_END_DATE.  Specify a CONVERSION_WINDOW to decide how much time you want to allow after the first event for other events to occur.
*/
--Build set of first events
with first_events as (
  SELECT
    user_id as first_event_user_id,
    MIN(created_at) as first_event_created_at
  FROM EVENTS_TABLE
  WHERE event_type = A
  and created_at between FUNNEL_START_DATE and FUNNEL_END_DATE
  group by user_id)
--Use first events to gather other events that happened in that period
SELECT
  user_id,
  first_event_created_at as event1_time,
  --MIN/CASEWHEN is an efficient way to gather and flatten the first of each event type
  --that took place after the first event
  MIN(CASE WHEN event_type = B THEN created_at ELSE NULL END) as event2_time,
  MIN(CASE WHEN event_type = C THEN created_at ELSE NULL END) as event3_time,
  MIN(CASE WHEN event_type = D THEN created_at ELSE NULL END) as event4_time
FROM EVENTS_TABLE
  inner join first_events
    on user_id = first_event_user_id
WHERE created_at >= first_event_created_at
  and datediff(day, first_event_created_at, created_at) <= CONVERSION WINDOW
GROUP BY user_id, first_event_created_at