{{
  config(
    materialized='table',
    tags=['feature_events', 'boost', 'marts']
  )
}}

-- Fact: one row per package
-- KPIs: boost_revenue_recognized, boost_ecpc_package, boost_ecpm_package,
--        boost_ecpc_meets_target, boost_repeat_exposure_rate
with package_metrics as (
    select
        package_id,
        promoter_id,
        package_name,
        sum(boost_revenue_allocated) as boost_revenue_recognized,
        sum(total_impressions) as total_impressions,
        sum(total_unique_impressions) as total_unique_impressions,
        sum(total_clicks) as total_clicks,
        sum(total_rsvps) as total_rsvps,
        count(distinct event_id) as event_count,
        min(first_activity_date) as first_activity_date,
        max(last_activity_date) as last_activity_date
    from {{ ref('fct_boost_package_event') }}
    group by 1, 2, 3
),

-- Users exposed to >1 event in the same package → repeat exposure
user_exposure as (
    select
        bp.package_id,
        fi.user_id,
        count(distinct fi.event_id) as events_exposed
    from {{ ref('fct_event_impression') }} fi
    inner join {{ ref('int_boost_event_package') }} bp
        on bp.event_id = fi.event_id
    where fi.user_id is not null
    group by 1, 2
),

repeat_rates as (
    select
        package_id,
        cast(count(*) as bigint) as total_unique_users,
        cast(count_if(events_exposed > 1) as bigint) as repeat_users
    from user_exposure
    group by 1
),

-- Aggregate CPC goal status across events in each package
goal_status as (
    select
        bp.package_id,
        min(case when coalesce(fe.cpc_goal_met, false) then 1 else 0 end) as min_cpc_goal
    from {{ ref('int_boost_event_package') }} bp
    inner join {{ ref('dim_featured_event') }} fe
        on fe.event_id = bp.event_id
    group by 1
)

select
    pm.package_id,
    pm.promoter_id,
    pm.package_name,
    pp.status as package_status,
    pp.type as package_type,
    pm.boost_revenue_recognized,
    pm.total_impressions,
    pm.total_unique_impressions,
    pm.total_clicks,
    pm.total_rsvps,
    pm.event_count,
    pm.first_activity_date,
    pm.last_activity_date,
    case
        when pm.total_clicks > 0
        then pm.boost_revenue_recognized / cast(pm.total_clicks as double)
        else cast(null as double)
    end as boost_ecpc_package,
    case
        when pm.total_impressions > 0
        then (pm.boost_revenue_recognized / cast(pm.total_impressions as double)) * 1000
        else cast(null as double)
    end as boost_ecpm_package,
    coalesce(gs.min_cpc_goal = 1, false) as boost_ecpc_meets_target,
    case
        when coalesce(rr.total_unique_users, 0) > 0
        then cast(rr.repeat_users as double) / cast(rr.total_unique_users as double)
        else 0.0
    end as boost_repeat_exposure_rate,
    cast(current_timestamp as timestamp) as updated_at
from package_metrics pm
left join {{ ref('stg_alacarte_promoter_packages') }} pp
    on pp.id = pm.package_id
left join repeat_rates rr
    on rr.package_id = pm.package_id
left join goal_status gs
    on gs.package_id = pm.package_id

