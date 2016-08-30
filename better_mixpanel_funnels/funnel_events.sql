/*
This is a workup file
*/

--Set path to avoid typing this bullshit all the time
set search_path to postgres_public

--See events
select *
from stats_user_events
limit 10;

--Count Events
select count(*)
from stats_user_events

--Count events for the events we want to funnel (created_user, created_account, bucketed_contact, created_message)
select count(*)
from stats_user_events
where event_type in (20,60,44,0);

--Count events for the events we want to funnel for a set of users
select count(*)
from stats_user_events
where event_type in (20,60,44,0)
and user_id in (1,2,3,4,5,6);

--Count events for the events we want to funnel for a set of users who did the first event (created_user)
select count(*)
from stats_user_events
where event_type in (20,60,44,0)
and user_id in (
	select distinct user_id
	from stats_user_events
	where event_type = 20);

--Count desired events, where user_id is part of group that performed first funnel event between Jan and March 2016
select count(*)
from stats_user_events
where event_type in (20,60,44,0)
and user_id in (
	select distinct user_id
	from stats_user_events
	where event_type = 20
	and created_at::date >= '2016-1-1'
	and created_at::date <= '2016-3-1');

--Find User Who Completed Funnel
select distinct user_id
from stats_user_events
where event_type in (0)
order by user_id desc;
limit 100
--> Uncovered a large chunk of users that are missing user_created_events

--Create 4 fields using a Case when for each event timestamp
SELECT user_id, id,
	CASE WHEN event_type = 20 THEN created_at ELSE NULL END as created_user_time,
	CASE WHEN event_type = 60 and created_at + 90 < created_user_time THEN created_at ELSE NULL END as created_account_time,
	CASE WHEN event_type = 44 THEN created_at ELSE NULL END as bucketed_contact_time,
	CASE WHEN event_type = 0 THEN created_at ELSE NULL END as created_message_time
FROM stats_user_events
where user_id = 107871
and event_type in (20,60,44,0)
-- Selects creates 4 records with 4 sparse fields

--Select the first event for each of the 4 activation funnel events and flatten into one record
SELECT user_id,
	MIN(CASE WHEN event_type = 20 THEN created_at ELSE NULL END) as created_user_time,
	MIN(CASE WHEN event_type = 60 THEN created_at ELSE NULL END) as created_account_time,
	MIN(CASE WHEN event_type = 44 THEN created_at ELSE NULL END) as bucketed_contact_time,
	MIN(CASE WHEN event_type = 0 THEN created_at ELSE NULL END) as created_message_time
FROM stats_user_events
where user_id = 107871
and event_type in (20,60,44,0)
group by user_id
-- Selected a single row with the event times

--Filtering to the event sets in where clause is unnesscary, but should probably check the event sets later
SELECT user_id,
	MIN(CASE WHEN event_type = 20 THEN created_at ELSE NULL END) as created_user_time,
	MIN(CASE WHEN event_type = 60 THEN created_at ELSE NULL END) as created_account_time,
	MIN(CASE WHEN event_type = 44 THEN created_at ELSE NULL END) as bucketed_contact_time,
	MIN(CASE WHEN event_type = 0 THEN created_at ELSE NULL END) as created_message_time
FROM stats_user_events
where user_id = 107871
group by user_id

--Select flattened event funnel for all users who completed first event in given time
SELECT user_id,
	MIN(CASE WHEN event_type = 20 THEN created_at ELSE NULL END) as created_user_time,
	MIN(CASE WHEN event_type = 60 THEN created_at ELSE NULL END) as created_account_time,
	MIN(CASE WHEN event_type = 44 THEN created_at ELSE NULL END) as bucketed_contact_time,
	MIN(CASE WHEN event_type = 0 THEN created_at ELSE NULL END) as created_message_time
FROM stats_user_events
where user_id in (
	select distinct user_id
	from stats_user_events
	where event_type = 20
	and created_at::date >= '2016-1-1'
	and created_at::date <= '2016-3-1')
group by user_id

--Select flattened event funnel for all users (performance test)
SELECT user_id,
	MIN(CASE WHEN event_type = 20 THEN created_at ELSE NULL END) as created_user_time,
	MIN(CASE WHEN event_type = 60 THEN created_at ELSE NULL END) as created_account_time,
	MIN(CASE WHEN event_type = 44 THEN created_at ELSE NULL END) as bucketed_contact_time,
	MIN(CASE WHEN event_type = 0 THEN created_at ELSE NULL END) as created_message_time
FROM stats_user_events
where user_id in (
	select distinct user_id
	from stats_user_events
	where event_type = 20)
group by user_id

---------------------------------------------------------------
--Building first event constraint into SQL (Round I. With Rank)
---------------------------------------------------------------

--Get a group of events for given user
SELECT *
FROM stats_user_events
where user_id = 107871
and event_type = 60

--Get the first event of a specific type for user
SELECT *
FROM stats_user_events
where user_id = 107871
and event_type = 60
ORDER BY created_at asc
limit 1

--Rank the events in created_at order for a user
SELECT *,
rank() over (partition by user_id order by created_at asc) as rank
FROM stats_user_events
where user_id = 107871
and event_type = 60

--Get only the first event for a specific user
with events as (
SELECT *,rank() over (partition by user_id order by created_at asc) as rank
FROM stats_user_events
where user_id = 107871
and event_type = 60)
select * from events
where rank = 1

--Get only the first event for all users
with events as (
	SELECT *,rank() over (partition by user_id order by created_at asc) as rank
	FROM stats_user_events
	where event_type = 60)
select * from events
where rank = 1
--33.4s

--Get only the first event for all users No With clause)
select *
from (
	SELECT *,rank() over (partition by user_id order by created_at asc) as rank
	FROM stats_user_events
	where event_type = 60)
where rank = 1
--34.5s

--Get First Event In With Clause
with events as (
	SELECT *,rank() over (partition by user_id order by created_at asc) as rank
	FROM stats_user_events
	where event_type = 20)
select
id as first_event_id,
user_id as first_event_user_id,
created_at as first_event_created_at
from events
where rank = 1
and user_id in (
	select distinct user_id
	from stats_user_events
	where event_type = 20
	and created_at::date >= '2016-1-1'
	and created_at::date <= '2016-3-1')


--Use newly created first_events table
with first_events as (
	with events as (
		SELECT *,rank() over (partition by user_id order by created_at asc) as rank
		FROM stats_user_events
		where event_type = 20)
	select
	id as first_event_id,
	user_id as first_event_user_id,
	created_at as first_event_created_at
	from events
	where rank = 1
	and user_id in (
		select distinct user_id
		from stats_user_events
		where event_type = 20
		and created_at::date >= '2016-1-1'
		and created_at::date <= '2016-3-1'))
SELECT user_id,
	MIN(CASE WHEN event_type = 20 THEN created_at ELSE NULL END) as created_user_time,
	MIN(CASE WHEN event_type = 60 THEN created_at ELSE NULL END) as created_account_time,
	MIN(CASE WHEN event_type = 44 THEN created_at ELSE NULL END) as bucketed_contact_time,
	MIN(CASE WHEN event_type = 0 THEN created_at ELSE NULL END) as created_message_time
FROM stats_user_events inner join first_events on user_id = first_event_user_id
group by user_id

--rank functions are incredibly slow in the with clause, this was stupid to try


---------------------------------------------------------------
--Building first event constraint into SQL (Round II. Using Group By / Min)
---------------------------------------------------------------

--Get a group of events for given user
SELECT *
FROM stats_user_events
where user_id = 107871
and event_type = 60

--Get the first event of a specific type for user (use group by)
SELECT user_id, MIN(CASE WHEN event_type = 60 THEN created_at ELSE NULL END)
FROM stats_user_events
where user_id = 107871
and event_type = 60
group by user_id

--Get the user_id and created_at for the first event for all users
SELECT user_id, MIN(CASE WHEN event_type = 60 THEN created_at ELSE NULL END)
FROM stats_user_events
where event_type = 60
group by user_id

--Get the user_id and created_at for the first event for all users who did that event within window
SELECT user_id,MIN(CASE WHEN event_type = 20 THEN created_at ELSE NULL END) as created_user_time
FROM stats_user_events
where user_id in (
	select distinct user_id
	from stats_user_events
	where event_type = 20
	and created_at::date >= '2016-1-1'
	and created_at::date <= '2016-3-1')
group by user_id

--Place first_event into with clause and draw for all events
with first_events as (
	SELECT
	user_id as first_event_user_id,
	MIN(CASE WHEN event_type = 20 THEN created_at ELSE NULL END) as first_event_created_at
	FROM stats_user_events
	where user_id in (
		select distinct user_id
		from stats_user_events
		where event_type = 20
		and created_at::date >= '2016-1-1'
		and created_at::date <= '2016-3-1')
	group by user_id)
select *
FROM stats_user_events inner join first_events on user_id = first_event_user_id
limit 100
--11s

--Use newly created first_events table to restrict to only first event
with first_events as (
	SELECT
		user_id as first_event_user_id,
		MIN(CASE WHEN event_type = 20 THEN created_at ELSE NULL END) as first_event_created_at
	FROM stats_user_events
	where user_id in (
		select distinct user_id
		from stats_user_events
		where event_type = 20
		and created_at::date >= '2016-1-1'
		and created_at::date <= '2016-3-1')
	group by user_id)
SELECT
	user_id,
	first_event_created_at,
	MIN(CASE WHEN (event_type = 60 and created_at >= first_event_created_at) THEN created_at ELSE NULL END) as created_account_time,
	MIN(CASE WHEN (event_type = 44 and created_at >= first_event_created_at) THEN created_at ELSE NULL END) as bucketed_contact_time,
	MIN(CASE WHEN (event_type = 0 and created_at >= first_event_created_at) THEN created_at ELSE NULL END) as created_message_time
FROM stats_user_events inner join first_events on user_id = first_event_user_id
group by user_id, first_event_created_at
--5.4s


--Dont actually need the subquery in the where clause
with first_events as (
	SELECT
		user_id as first_event_user_id,
		MIN(CASE WHEN event_type = 20 THEN created_at ELSE NULL END) as first_event_created_at
	FROM stats_user_events
	where event_type = 20
	and created_at::date >= '2016-1-1'
	and created_at::date <= '2016-3-1'
	group by user_id)
SELECT
	user_id,
	first_event_created_at,
	MIN(CASE WHEN (event_type = 60 and created_at >= first_event_created_at) THEN created_at ELSE NULL END) as created_account_time,
	MIN(CASE WHEN (event_type = 44 and created_at >= first_event_created_at) THEN created_at ELSE NULL END) as bucketed_contact_time,
	MIN(CASE WHEN (event_type = 0 and created_at >= first_event_created_at) THEN created_at ELSE NULL END) as created_message_time
FROM stats_user_events inner join first_events on user_id = first_event_user_id
group by user_id, first_event_created_at
--2.7s

--Dont actually need the subquery in the where clause
with first_events as (
	SELECT
		user_id as first_event_user_id,
		MIN(created_at) as first_event_created_at
	FROM stats_user_events
	where event_type = 20
	and created_at::date >= '2016-1-1'
	and created_at::date <= '2016-3-1'
	group by user_id)
SELECT
	user_id,
	first_event_created_at,
	MIN(CASE WHEN (event_type = 60 and created_at >= first_event_created_at) THEN created_at ELSE NULL END) as created_account_time,
	MIN(CASE WHEN (event_type = 44 and created_at >= first_event_created_at) THEN created_at ELSE NULL END) as bucketed_contact_time,
	MIN(CASE WHEN (event_type = 0 and created_at >= first_event_created_at) THEN created_at ELSE NULL END) as created_message_time
FROM stats_user_events inner join first_events on user_id = first_event_user_id
group by user_id, first_event_created_at
--1.8s

--Dont actually need the subquery in the where clause
with first_events as (
	SELECT
		user_id as first_event_user_id,
		MIN(created_at) as first_event_created_at
	FROM stats_user_events
	where event_type = 20
	and created_at between '2016-1-1' and '2016-3-1'
	group by user_id)
SELECT
	user_id,
	first_event_created_at,
	MIN(CASE WHEN (event_type = 60 and created_at >= first_event_created_at) THEN created_at ELSE NULL END) as created_account_time,
	MIN(CASE WHEN (event_type = 44 and created_at >= first_event_created_at) THEN created_at ELSE NULL END) as bucketed_contact_time,
	MIN(CASE WHEN (event_type = 0 and created_at >= first_event_created_at) THEN created_at ELSE NULL END) as created_message_time
FROM stats_user_events inner join first_events on user_id = first_event_user_id
group by user_id, first_event_created_at
--5.4s

--Replace two created_at's with between and remove
with first_events as (
	SELECT
		user_id as first_event_user_id,
		MIN(created_at) as first_event_created_at
	FROM stats_user_events
	where event_type = 20
	and created_at between '2016-1-1' and '2016-3-1'
	group by user_id)
SELECT
	user_id,
	first_event_created_at,
	MIN(CASE WHEN event_type = 60 THEN created_at ELSE NULL END) as created_account_time,
	MIN(CASE WHEN event_type = 44 THEN created_at ELSE NULL END) as bucketed_contact_time,
	MIN(CASE WHEN event_type = 0 THEN created_at ELSE NULL END) as created_message_time
FROM stats_user_events inner join first_events on user_id = first_event_user_id
where created_at >= first_event_created_at
group by user_id, first_event_created_at
--5.4s



















