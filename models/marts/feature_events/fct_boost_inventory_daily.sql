{{
  config(
    materialized='table',
    tags=['feature_events', 'boost', 'inventory']
  )
}}

-- Fact: one row per date
-- KPIs: boost_events_active, boost_events_new, boost_promoter_count_active
with active_dates as (
    select distinct date
    from {{ ref('fct_event_daily') }}
),

event_range as (
    select
        fe.event_id,
        fe.boost_start_date,
        fe.boost_end_date,
        bp.promoter_id,
        bp.package_id
    from {{ ref('dim_featured_event') }} fe
    left join {{ ref('int_boost_event_package') }} bp
        on bp.event_id = fe.event_id
    where fe.boost_start_date is not null
),

daily_status as (
    select
        ad.date,
        er.event_id,
        er.promoter_id,
        er.package_id,
        case
            when cast(ad.date as varchar) >= er.boost_start_date
             and (er.boost_end_date is null
                  or cast(ad.date as varchar) <= er.boost_end_date)
            then true else false
        end as is_active,
        case
            when cast(ad.date as varchar) = er.boost_start_date
            then true else false
        end as is_new
    from active_dates ad
    cross join event_range er
)

select
    date,
    count(distinct case when is_active then event_id end) as boost_events_active,
    count(distinct case when is_new then event_id end) as boost_events_new,
    count(distinct case when is_active then promoter_id end) as boost_promoter_count_active,
    count(distinct case when is_active then package_id end) as boost_packages_active,
    cast(current_timestamp as timestamp) as updated_at
from daily_status
group by 1

