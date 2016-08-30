--Subscription version changes is a self join of a subscription version and the subscription version that came before it.
--This final step allows us to easily understand the changes to our subsriptions like MRR delta (version 2 mrr - version 1 mrr) etc

select
--Subscription Information
subscription.subscription_name as subscription_name,
subscription.subscription_id as subscription_id,
subscription.subscription_start as subscription_start,
subscription.subscription_end as subscription_end,
subscription.account_id as subscription_account_id,
subscription.subscription_rank,

--Subscription Version Information
subscription.id as id,
subscription.status as status,
subscription.version as version,
subscription.start as start,
subscription.start_amendment_type,
subscription.end as end,
subscription.end_amendment_type,

subscription.plans as plans,
subscription.plan_count as plan_count,
subscription.seats as seats,
subscription.billing_periods as billing_periods,
subscription.mrr_no_discount as mrr_no_discount,

subscription.discounts as discounts,
subscription.discount_count as discount_count,
subscription.discount_impacts as discount_impacts,
subscription.mrr as mrr,

--Previous subscription information
previous_subscription.plans as previous_plans,
previous_subscription.plan_count as previous_plan_count,
previous_subscription.seats as previous_seats,
previous_subscription.billing_periods as previous_billing_periods,
previous_subscription.mrr_no_discount as previous_mrr_no_discount,

previous_subscription.discounts as previous_discounts,
previous_subscription.discount_count as previous_discount_count,
previous_subscription.discount_impacts as previous_discount_impacts,
previous_subscription.mrr as previous_mrr

from ${subscription_versions.SQL_TABLE_NAME} subscription
left join ${subscription_versions.SQL_TABLE_NAME} previous_subscription 
  on subscription.previous_version_id = previous_subscription.id