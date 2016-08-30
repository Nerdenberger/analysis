--Plan-Discounts builds the set of rate_plans (aka products) with the aggregate discount fields built in.
--The goal is to reduce plans with many discount impacts to a single row

select
rate_plan_charge.name as name,
rate_plan_charge.subscription_id as subscription_id,
rate_plan_charge.quantity as quantity,
rate_plan_charge.billing_period as billing_period,
rate_plan_charge.mrr as mrr_no_discount,
listagg(discount_rate_plan_charge.name,',') within group (order by rate_plan_charge.id) as discounts,
count(discount_rate_plan_charge.name) as discount_count,
sum(
CASE 
  WHEN rate_plan_charge.billing_period = 'Month' 
  THEN (rate_plan_charge.mrr * NVL(discount_rate_plan_charge_tier.discount_percentage, 0.0) * .01) + NVL(discount_rate_plan_charge_tier.discount_amount, 0.0)
  WHEN rate_plan_charge.billing_period = 'Annual' 
  THEN (rate_plan_charge.mrr * NVL(discount_rate_plan_charge_tier.discount_percentage, 0.0) * .01) + NVL(discount_rate_plan_charge_tier.discount_amount, 0.0)/12.00
  WHEN rate_plan_charge.billing_period = 'Quarter' 
  THEN (rate_plan_charge.mrr * NVL(discount_rate_plan_charge_tier.discount_percentage, 0.0) * .01) + NVL(discount_rate_plan_charge_tier.discount_amount, 0.0)/3.00
  ELSE 0.0
END) as discount_impact

from zuora_production._rate_plan_charge rate_plan_charge

inner join zuora_production._subscription subscription
 on subscription.id = rate_plan_charge.subscription_id

left join zuora_production._amendment a1
  on subscription.previous_subscription_id = a1.subscription_id
  and (a1.status = 'Completed' OR a1.status IS NULL)

left join zuora_production._amendment a2 
  on subscription.id = a2.subscription_id
  and (a2.status = 'Completed' OR a2.status IS NULL)

left join zuora_production._rate_plan_charge discount_rate_plan_charge
  on rate_plan_charge.subscription_id = discount_rate_plan_charge.subscription_id
  and discount_rate_plan_charge.charge_model IN ('Discount-Percentage', 'Discount-Fixed Amount')
  and (NVL(a1.contract_effective_date,subscription.contract_effective_date) < discount_rate_plan_charge.effective_end_date or discount_rate_plan_charge.effective_end_date is null)
  and (a2.effective_date >= discount_rate_plan_charge.effective_start_date or a2.effective_date is null)

left join zuora_production._rate_plan_charge_tier discount_rate_plan_charge_tier
  on discount_rate_plan_charge.id = discount_rate_plan_charge_tier.rate_plan_charge_id

where (not subscription.is_deleted or subscription.is_deleted IS NULL)
  and rate_plan_charge.charge_model IN ('Flat Fee Pricing', 'Tiered Pricing', 'Per Unit Pricing', 'Volume Pricing')
  and rate_plan_charge.charge_type = 'Recurring'
  and (rate_plan_charge.effective_end_date > a1.effective_date OR rate_plan_charge.effective_end_date IS NULL) 
  
group by 
  rate_plan_charge.id,
  rate_plan_charge.name,
  rate_plan_charge.subscription_id,
  rate_plan_charge.quantity,
  rate_plan_charge.billing_period,
  rate_plan_charge.mrr