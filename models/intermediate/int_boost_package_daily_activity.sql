{{
  config(
    materialized='view',
    tags=['feature_events', 'boost', 'intermediate']
  )
}}

-- Intermediate: per-package per-day aggregation
-- SUM of clicks and impressions across all events still active on activity_date
with package_events as (
    select
        package_id,
        cast(event_id as integer) as event_id
    from {{ ref('stg_alacarte_promoter_events') }}
    where deleted = false

    union all

    select
        package_id,
        event_id
    from {{ ref('stg_alacarte_artists_events') }}
    where deleted = 0
),

daily_impressions as (
    select
        artist_event_int_id as event_id,
        ds as activity_date,
        count(*) as daily_impressions,
        count_if(impression_channel = 'email') as daily_email_impressions
    from {{ ref('int_featured_event_impressions') }}
    where artist_event_int_id is not null
    group by 1, 2
),

daily_clicks as (
    select
        artist_event_int_id as event_id,
        ds as activity_date,
        count(*) as daily_clicks,
        count_if(lower(coalesce(fe_source, '')) = 'email') as daily_email_clicks
    from {{ ref('stg_featured_events_ticket_clicks') }}
    where artist_event_int_id is not null
    group by 1, 2
),

-- Spine of all (event_id, activity_date) combinations
event_dates as (
    select event_id, activity_date from daily_impressions
    union
    select event_id, activity_date from daily_clicks
),

event_daily as (
    select
        pe.package_id,
        ed.event_id,
        ed.activity_date,
        coalesce(dc.daily_clicks, 0) as daily_clicks,
        coalesce(dc.daily_email_clicks, 0) as daily_email_clicks,
        coalesce(di.daily_impressions, 0) as daily_impressions,
        coalesce(di.daily_email_impressions, 0) as daily_email_impressions
    from event_dates ed
    inner join package_events pe
        on pe.event_id = ed.event_id
    left join daily_clicks dc
        on dc.event_id = ed.event_id
       and dc.activity_date = ed.activity_date
    left join daily_impressions di
        on di.event_id = ed.event_id
       and di.activity_date = ed.activity_date
)

select
    package_id,
    activity_date,
    count(distinct event_id) as active_event_count,
    cast(sum(daily_clicks) as bigint) as daily_clicks,
    cast(sum(daily_impressions) as bigint) as daily_impressions,
    cast(sum(daily_email_clicks) as bigint) as daily_email_clicks,
    cast(sum(daily_email_impressions) as bigint) as daily_email_impressions
from event_daily
where activity_date is not null
group by 1, 2


