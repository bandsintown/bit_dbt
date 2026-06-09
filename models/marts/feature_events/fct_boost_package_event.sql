{{
  config(
    materialized='table',
    tags=['feature_events', 'boost', 'marts']
  )
}}

-- Fact: one row per package × event
-- KPIs: boost_revenue_allocated, boost_ecpc_event, boost_ecpm_event
with event_totals as (
    select
        event_id,
        sum(total_impressions) as total_impressions,
        sum(unique_impressions) as total_unique_impressions,
        sum(ticket_clicks) as total_clicks,
        sum(rsvp_events) as total_rsvps,
        sum(unique_users_impression) as total_unique_users,
        min(date) as first_activity_date,
        max(date) as last_activity_date,
        count(distinct date) as active_days
    from {{ ref('fct_event_daily') }}
    group by 1
)

select
    bp.package_id,
    bp.event_id,
    bp.promoter_id,
    bp.package_name,
    fe.artist_id,
    fe.boost_start_date,
    fe.boost_end_date,
    fe.campaign_flat_fee as boost_revenue_allocated,
    coalesce(et.total_impressions, 0) as total_impressions,
    coalesce(et.total_unique_impressions, 0) as total_unique_impressions,
    coalesce(et.total_clicks, 0) as total_clicks,
    coalesce(et.total_rsvps, 0) as total_rsvps,
    coalesce(et.total_unique_users, 0) as total_unique_users,
    et.first_activity_date,
    et.last_activity_date,
    coalesce(et.active_days, 0) as active_days,
    case
        when coalesce(et.total_clicks, 0) > 0
        then fe.campaign_flat_fee / cast(et.total_clicks as double)
        else cast(null as double)
    end as boost_ecpc_event,
    case
        when coalesce(et.total_impressions, 0) > 0
        then (fe.campaign_flat_fee / cast(et.total_impressions as double)) * 1000
        else cast(null as double)
    end as boost_ecpm_event,
    cast(current_timestamp as timestamp) as updated_at
from {{ ref('int_boost_event_package') }} bp
inner join {{ ref('dim_featured_event') }} fe
    on fe.event_id = bp.event_id
left join event_totals et
    on et.event_id = bp.event_id

