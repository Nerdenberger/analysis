--Subscription versions takes many plans for a given subscription version and reduces to just one subscription version row by aggregating plan-discounts
select
--Subscription Version Fields
subscription.id as id,
subscription.previous_subscription_id as previous_version_id,
NVL(a1.effective_date,subscription.contract_effective_date) as start,
a1.type as start_amendment_type,
a2.effective_date as end,
a2.type as end_amendment_type,
subscription.version as version,
subscription.status as status,
subscription.incorrect_cancellation_date_c as incorrect_cancellation_date,

--Original Subscription Fields
subscription.name as subscription_name,
subscription.original_id as subscription_id,
subscription.contract_effective_date as subscription_start,
subscription.cancelled_date as subscription_end,
subscription_rank.subscription_rank,
subscription.account_id as account_id,

--Plan Fields
listagg(plan_discounts.name,',') within group (order by subscription.id) as plans,
count(plan_discounts.name) as plan_count,
sum(plan_discounts.quantity) as seats,
listagg(plan_discounts.billing_period,',') within group (order by subscription.id) as billing_periods,
sum(plan_discounts.mrr_no_discount) as mrr_no_discount,

--Discount Fields
listagg(plan_discounts.discounts,',') within group (order by subscription.id) as discounts,
sum(plan_discounts.discount_count) as discount_count,
sum(plan_discounts.discount_impact) as discount_impacts,
CASE 
  WHEN sum(plan_discounts.mrr_no_discount - plan_discounts.discount_impact) > 0 
    THEN sum(plan_discounts.mrr_no_discount - plan_discounts.discount_impact)
  ELSE 0.00
END as mrr,

--Rank Functions
row_number() over (
  partition by
  subscription.original_id,
  NVL(a1.effective_date,subscription.contract_effective_date)
  order by subscription.status ASC, NVL(a1.effective_date,subscription.contract_effective_date) DESC, version DESC 
  ) as version_date_rank,

row_number() over (
  partition by
  subscription.id,
  version  
  ) as version_rank

from zuora_production._subscription subscription

left join (
  select id,
  dense_rank() over (partition by account_id order by contract_effective_date ASC, name ASC) as subscription_rank
  from zuora_production._subscription
  ) subscription_rank
on subscription.id = subscription_rank.id

left join zuora_production._amendment a1
  on subscription.previous_subscription_id = a1.subscription_id

left join zuora_production._amendment a2 
  on subscription.id = a2.subscription_id

left join ${subscription_plan_discounts.SQL_TABLE_NAME} plan_discounts
  on subscription.id = plan_discounts.subscription_id

where (not subscription.is_deleted or subscription.is_deleted IS NULL)
  and (a1.status = 'Completed' OR a1.status IS NULL)
  and (a2.status = 'Completed' OR a2.status IS NULL)

group by 
subscription.id,
subscription.original_id,
subscription.previous_subscription_id,
subscription.name,
subscription.account_id,
NVL(a1.effective_date,subscription.contract_effective_date),
a1.type,
a2.effective_date,
a2.type,
subscription.version,
subscription.contract_effective_date,
subscription.cancelled_date,
subscription.status,
subscription.incorrect_cancellation_date_c,
subscription_rank