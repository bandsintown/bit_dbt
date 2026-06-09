{{
  config(
    materialized='table',
    tags=['feature_events', 'boost', 'marts']
  )
}}

-- Fact: one row per package × event × date
-- Per-event daily drill-down with running cumulative totals
select
    bp.package_id,
    bp.event_id,
    bp.promoter_id,
    bp.package_name,
    fe.artist_id,
    ed.date,
    ed.pixel_impressions,
    ed.email_impressions,
    ed.total_impressions,
    ed.unique_impressions,
    ed.ticket_clicks,
    ed.distribution_partners,
    ed.rsvp_events,
    ed.unique_users_impression,
    ed.unique_users_click,
    ed.boost_ctr_email,
    sum(ed.total_impressions) over (
        partition by bp.package_id, bp.event_id order by ed.date
    ) as cumulative_impressions,
    sum(ed.ticket_clicks) over (
        partition by bp.package_id, bp.event_id order by ed.date
    ) as cumulative_clicks,
    cast(current_timestamp as timestamp) as updated_at
from {{ ref('int_boost_event_package') }} bp
inner join {{ ref('dim_featured_event') }} fe
    on fe.event_id = bp.event_id
inner join {{ ref('fct_event_daily') }} ed
    on ed.event_id = bp.event_id

