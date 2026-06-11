{{
  config(
    materialized='table',
    tags=['feature_events', 'marts', 'kpi']
  )
}}

-- Fact: one row per event × date
-- KPIs: boost_ctr_email
with impression_daily as (
    select
        event_id,
        artist_id,
        cast(impression_logged_at as date) as date,
        count_if(surface != 'email') as pixel_impressions,
        count_if(surface = 'email') as email_impressions,
        count(*) as total_impressions,
        count(distinct nonce) as unique_impressions,
        count(distinct fan_id) as unique_users_impression
    from {{ ref('fct_event_impression') }}
    group by 1, 2, 3
),

clicks_daily as (
    select
        event_id,
        date,
        count(*) as ticket_clicks,
        count(distinct user_id) as unique_users_click,
        count(distinct ticket_seller_host) as distribution_partners,
        count_if(lower(coalesce(fe_source, '')) = 'email') as email_clicks
    from {{ ref('fct_event_click') }}
    group by 1, 2
),

rsvp_daily as (
    select
        artist_event_int_id as event_id,
        ds as date,
        count(*) as rsvp_events,
        count(distinct user_id) as unique_users_rsvp
    from {{ ref('dim_featured_events_rsvps') }}
    group by 1, 2
)

select
    i.event_id,
    i.artist_id,
    i.date,
    i.pixel_impressions,
    i.email_impressions,
    i.total_impressions,
    i.unique_impressions,
    i.unique_users_impression,
    coalesce(c.ticket_clicks, 0) as ticket_clicks,
    coalesce(c.unique_users_click, 0) as unique_users_click,
    coalesce(c.distribution_partners, 0) as distribution_partners,
    coalesce(c.email_clicks, 0) as email_clicks,
    coalesce(r.rsvp_events, 0) as rsvp_events,
    coalesce(r.unique_users_rsvp, 0) as unique_users_rsvp,
    case
        when i.email_impressions > 0
        then cast(coalesce(c.email_clicks, 0) as double) / cast(i.email_impressions as double)
        else 0.0
    end as boost_ctr_email,
    cast(current_timestamp as timestamp) as updated_at
from impression_daily i
left join clicks_daily c
    on c.event_id = i.event_id
   and c.date = i.date
left join rsvp_daily r
    on r.event_id = i.event_id
   and r.date = i.date
