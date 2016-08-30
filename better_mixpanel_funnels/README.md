#Overview
Mixpanel funnels are an awesome tool, but they have some drawbacks.
1. (Obvious) Sometimes you need to build funnels on event data you haven't gotten into mixpanel yet!  This could be data structured as events or non-eventy data that can be transformed/unioned into an event set
2. Its difficult to visualize changes to funnels over time
3. Mixpanel funnels allow for comparison of of incomplete cohorts

For example if specify a funnel for the last 90 days user A who signed up a week ago is included, but so is User B who signed up 1 day ago.  If your conversion window is 7 days user A has completed the funnel, but user b is still cooking.  By including users who had had varying amounts of time to complete the funnel mixpanel yields "incomplete" results and can confuse analysts who are comparing recent cohorts to older ones.  This lookml enforces that you can't view a cohort until its full cooked (past_window dimension). 

This model aims to recreate mixpanel funnel functionality in Looker while making some important functionality improvements.

#File Explanation

4_event_funnel.sql 
A simplified version you can easily adapt to any events table.  The output is a user_id and date/time for each of the events.

funnel_events.sql 
My notes/thought process that went into building this funnel.  Starting with simple queries, we build up to the final model (poor man's way of being "test driven").  If you want to understand the logic in how this was built you can check that out (this is pretty raw notes so some things might not run).

event_funnel_4_events.lookml 
Looker view file to parametrize the funnel so product managers can define the start/end dates, conversion window, event types, and a few other settings in Looker.  It uses a templated filter expressions to pass those values into the query.
 

