{{
  config(
    materialized='table',
    tags=['feature_events', 'boost', 'marts']
  )
}}

-- Fact: one row per package × date
-- KPIs: boost_ecpc_cumulative, boost_ecpm_cumulative, projection KPIs
with daily_metrics as (
    select
        package_id,
        promoter_id,
        package_name,
        date,
        sum(total_impressions) as daily_impressions,
        sum(unique_impressions) as daily_unique_impressions,
        sum(ticket_clicks) as daily_clicks,
        sum(rsvp_events) as daily_rsvps,
        sum(unique_users_impression) as daily_unique_users
    from {{ ref('fct_boost_package_event_daily') }}
    group by 1, 2, 3, 4
),

package_revenue as (
    select
        package_id,
        sum(boost_revenue_allocated) as boost_revenue_recognized
    from {{ ref('fct_boost_package_event') }}
    group by 1
),

package_start as (
    select
        package_id,
        min(date) as first_date
    from {{ ref('fct_boost_package_event_daily') }}
    group by 1
)

select
    dm.package_id,
    dm.promoter_id,
    dm.package_name,
    pp.status as package_status,
    pp.type as package_type,
    dm.date,
    dm.daily_impressions,
    dm.daily_unique_impressions,
    dm.daily_clicks,
    dm.daily_rsvps,
    dm.daily_unique_users,
    -- Cumulative totals
    sum(dm.daily_impressions) over (
        partition by dm.package_id order by dm.date
    ) as cumulative_impressions,
    sum(dm.daily_clicks) over (
        partition by dm.package_id order by dm.date
    ) as cumulative_clicks,
    -- Cumulative eCPC / eCPM
    case
        when sum(dm.daily_clicks) over (
            partition by dm.package_id order by dm.date
        ) > 0
        then pr.boost_revenue_recognized
             / cast(sum(dm.daily_clicks) over (
                 partition by dm.package_id order by dm.date
             ) as double)
        else cast(null as double)
    end as boost_ecpc_cumulative,
    case
        when sum(dm.daily_impressions) over (
            partition by dm.package_id order by dm.date
        ) > 0
        then (pr.boost_revenue_recognized
             / cast(sum(dm.daily_impressions) over (
                 partition by dm.package_id order by dm.date
             ) as double)) * 1000
        else cast(null as double)
    end as boost_ecpm_cumulative,
    -- Projection helpers
    date_diff('day', ps.first_date, dm.date) + 1 as days_elapsed,
    cast(sum(dm.daily_impressions) over (
        partition by dm.package_id order by dm.date
    ) as double)
        / cast(nullif(date_diff('day', ps.first_date, dm.date) + 1, 0) as double)
        as avg_daily_impressions,
    cast(sum(dm.daily_clicks) over (
        partition by dm.package_id order by dm.date
    ) as double)
        / cast(nullif(date_diff('day', ps.first_date, dm.date) + 1, 0) as double)
        as avg_daily_clicks,
    cast(current_timestamp as timestamp) as updated_at
from daily_metrics dm
left join {{ ref('stg_alacarte_promoter_packages') }} pp
    on pp.id = dm.package_id
left join package_revenue pr
    on pr.package_id = dm.package_id
left join package_start ps
    on ps.package_id = dm.package_id

