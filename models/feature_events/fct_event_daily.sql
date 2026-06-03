{{
  config(
    materialized='table',
    tags=['feature_events', 'marts', 'kpi']
  )
}}

with impression_daily as (
    select
        event_id,
        date,
        count_if(impression_channel = 'pixel') as pixel_impressions,
        count_if(impression_channel = 'email') as email_impressions,
        count(*) as total_impressions,
        count(distinct nonce) as unique_impressions,
        count(distinct user_id) as unique_users_impression
    from {{ ref('fct_event_impression') }}
    group by 1, 2
),
clicks_daily as (
    select
        cast(artist_event_int_id as integer) as event_id,
        ds as date,
        count(*) as ticket_clicks,
        count(distinct user_id) as unique_users_click
    from {{ ref('stg_featured_events_ticket_clicks') }}
    group by 1, 2
),
rsvp_daily as (
    select
        cast(artist_event_int_id as integer) as event_id,
        ds as date,
        count(*) as rsvp_events,
        count(distinct cast(user_id as integer)) as unique_users_rsvp
    from {{ ref('stg_featured_events_rsvps') }}
    group by 1, 2
)

select
    i.event_id,
    i.date,
    i.pixel_impressions,
    i.email_impressions,
    i.total_impressions,
    i.unique_impressions,
    i.unique_users_impression,
    coalesce(c.ticket_clicks, 0) as ticket_clicks,
    coalesce(c.unique_users_click, 0) as unique_users_click,
    coalesce(r.rsvp_events, 0) as rsvp_events,
    coalesce(r.unique_users_rsvp, 0) as unique_users_rsvp,
    cast(current_timestamp as timestamp) as updated_at
from impression_daily i
left join clicks_daily c
    on c.event_id = i.event_id
   and c.date = i.date
left join rsvp_daily r
    on r.event_id = i.event_id
   and r.date = i.date
