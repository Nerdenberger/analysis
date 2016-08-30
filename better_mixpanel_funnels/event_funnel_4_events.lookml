###LOOKML VIEW FILE FOR MIXPANEL FUNNELS###

- view: event_funnel_4_events
  derived_table:
    sql: |
      with first_events as (
        SELECT
          user_id as first_event_user_id,
          MIN(created_at) as first_event_created_at
        FROM postgres_public.stats_user_events left join public.event_type_enum
        on postgres_public.stats_user_events.event_type = public.event_type_enum.enum
        where {% condition funnel_event_1 %} event_name {% endcondition %}
        and {% condition datefilter1 %} created_at::date {% endcondition %}
        group by user_id)
      SELECT
        user_id,
        first_event_created_at as event1_time,
        MIN(CASE WHEN {% condition funnel_event_2 %} event_name {% endcondition %} THEN created_at ELSE NULL END) as event2_time,
        MIN(CASE WHEN {% condition funnel_event_3 %} event_name {% endcondition %} THEN created_at ELSE NULL END) as event3_time,
        MIN(CASE WHEN {% condition funnel_event_4 %} event_name {% endcondition %} THEN created_at ELSE NULL END) as event4_time
      FROM postgres_public.stats_user_events left join public.event_type_enum
        on postgres_public.stats_user_events.event_type = public.event_type_enum.enum
        inner join first_events on user_id = first_event_user_id
      where created_at >= first_event_created_at
      and {% condition conversion_window_days %} datediff(day, first_event_created_at, created_at) {% endcondition %}
      group by user_id, first_event_created_at

  fields:
    - filter: funnel_event_1
      suggest_explore: event_type_enum
      suggest_dimension: event_name

    - filter: funnel_event_2
      suggest_explore: event_type_enum
      suggest_dimension: event_name

    - filter: funnel_event_3
      suggest_explore: event_type_enum
      suggest_dimension: event_name

    - filter: funnel_event_4
      suggest_explore: event_type_enum
      suggest_dimension: event_name

    - filter: conversion_window_days
      type: number
      label: 'Conversion Window (Days)'

    - filter: datefilter1
      label: 'First Event Occured'
      type: date

    - dimension: user_id
      type: string
      primary_key: TRUE
      hidden: true
      sql: ${TABLE}.user_id

    - dimension: past_window
      type: yesno
      sql: |
        NOT {% condition conversion_window_days %} datediff(day,${event1_date},current_date) {% endcondition %}

    - dimension: event1
      label: 'First Event'
      type: time
      timeframes: [time, date, week, month, day_of_week, year, quarter]
      sql: ${TABLE}.event1_time

    - dimension: event2
      type: time
      timeframes: [time]
      hidden: true
      sql: ${TABLE}.event2_time

    - dimension: event3
      type: time
      timeframes: [time]
      hidden: true
      sql: ${TABLE}.event3_time

    - dimension: event4
      type: time
      timeframes: [time]
      hidden: true
      sql: ${TABLE}.event4_time

    - measure: event_1_count
      type: count_distinct
      sql: ${user_id}
      filters:
        event1_time: NOT NULL

    - measure: event_2_count
      type: count_distinct
      sql: ${user_id}
      filters:
        event1_time: NOT NULL
        event2_time: NOT NULL

    - measure: event_3_count
      type: count_distinct
      sql: ${user_id}
      filters:
        event1_time: NOT NULL
        event2_time: NOT NULL
        event3_time: NOT NULL

    - measure: event_4_count
      type: count_distinct
      sql: ${user_id}
      filters:
        event1_time: NOT NULL
        event2_time: NOT NULL
        event3_time: NOT NULL
        event4_time: NOT NULL

    - measure: conversion_rate1
      label: 'Conversion Rate (All Steps)'
      type: number
      sql: 1.00 * ${event_4_count} / ${event_1_count}
      value_format: '0.00%'

    - measure: conversion_rate2
      label: 'Conversion Rate (Through Step 3)'
      type: number
      sql: 1.00 * ${event_3_count} / ${event_1_count}
      value_format: '0.00%'

    - measure: conversion_rate3
      label: 'Conversion Rate (Through Step 2)'
      type: number
      sql: 1.00 * ${event_2_count} / ${event_1_count}
      value_format: '0.00%'

    - measure: conversion_rate4
      label: 'Conversion Rate (Step 2 to Step 3)'
      type: number
      sql: 1.00 * ${event_3_count} / ${event_2_count}
      value_format: '0.00%'

    - measure: conversion_rate5
      label: 'Conversion Rate (Step 2 to Step 4)'
      type: number
      sql: 1.00 * ${event_4_count} / ${event_2_count}
      value_format: '0.00%'

    - measure: conversion_rate6
      label: 'Conversion Rate (Step 3 to Step 4)'
      type: number
      sql: 1.00 * ${event_4_count} / ${event_3_count}
      value_format: '0.00%'










