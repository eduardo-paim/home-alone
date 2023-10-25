with transactions as (
    select * from {{ref('stripe_mrr')}}
),

core_metrics as (
    select
        date_month,
        sum(active_customer) as customers,
        sum(mrr) as mrr,
        sum(subscription_amount) as subscription_amount,
        sum(accrual_amount) as accrual_amount,
        sum(addon_amount) as addon_amount,

        coalesce(sum(case when change_category = 'new' then mrr_change end), 0) as new_mrr,
        coalesce(sum(case when change_category = 'upgrade' then mrr_change end), 0) as upgrade_mrr,
        coalesce(sum(case when change_category = 'churn' then mrr_change end), 0) as churned_mrr,
        coalesce(sum(case when change_category = 'reactivation' then mrr_change end), 0) as reactivation_mrr,
        coalesce(sum(case when change_category = 'downgrade' then mrr_change end), 0) as downgrade_mrr,

        coalesce(sum(case when change_category = 'new' then 1 end), 0) as new_customers,
        coalesce(sum(case when change_category = 'upgrade' then 1 end), 0) as upgrade_customers,
        coalesce(sum(case when change_category = 'churn' then 1 end), 0) as churned_customers,
        coalesce(sum(case when change_category = 'reactivation' then 1 end), 0) as reactivation_customers,
        coalesce(sum(case when change_category = 'downgrade' then 1 end), 0) as downgrade_customers

    from transactions
    group by date_month
),

lagged as (
    select *,
        lag(mrr) over (order by date_month) as beginning_mrr
    from core_metrics
),

composite as (
    select
        *,
        new_mrr + reactivation_mrr as total_new_mrr,
        new_mrr + upgrade_mrr + churned_mrr + reactivation_mrr + downgrade_mrr as net_change_in_mrr,
        new_customers - churned_customers + reactivation_customers as net_change_in_customers,
        upgrade_mrr + downgrade_mrr as net_upgrade_mrr
    from lagged
),

ratios as (
    select
        *,
        safe_divide(churned_mrr, beginning_mrr) * -1 as gross_churn_rate,
        safe_divide(churned_mrr + upgrade_mrr + downgrade_mrr, beginning_mrr) * -1 as net_churn_rate,
        safe_divide(mrr, customers) as arpa,
        safe_divide(new_mrr, new_customers) as new_customer_arpa,
        safe_divide(churned_mrr, churned_customers) * -1 as churned_customer_arpa,
        safe_divide(upgrade_mrr, upgrade_customers) as avg_upgrade,
        safe_divide(downgrade_mrr, downgrade_customers) * -1 as avg_downgrade,
        safe_divide(net_upgrade_mrr, beginning_mrr) as net_upgrade_rate
    from composite
)

select *
from ratios
where date_month < date_trunc('month', current_date)
order by date_month;

-- This is a helper function to handle division by zero.
create or replace function safe_divide(numerator float, denominator float) returns float as $$
begin
    if denominator = 0 then
        return null;
    else
        return numerator / denominator;
    end if;
end;
$$ language plpgsql;
