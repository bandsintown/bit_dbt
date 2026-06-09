{{
  config(
    materialized='table',
    tags=['feature_events', 'marts', 'summary']
  )
}}

-- Mart: lifetime performance per featured event
select
    d.event_id,
    d.fe_sources,
    d.boost_start_date,
    d.boost_end_date,
    sum(f.pixel_impressions) as total_pixel_impressions,
    sum(f.email_impressions) as total_email_impressions,
    sum(f.total_impressions) as total_impressions,
    sum(f.unique_impressions) as total_unique_impressions,
    sum(f.ticket_clicks) as total_ticket_clicks,
    sum(f.rsvp_events) as total_rsvps,
    min(f.date) as first_activity_date,
    max(f.date) as last_activity_date,
    count(distinct f.date) as active_days
from {{ ref('dim_featured_event') }} d
left join {{ ref('fct_event_daily') }} f
    on f.event_id = d.event_id
group by 1, 2, 3, 4

