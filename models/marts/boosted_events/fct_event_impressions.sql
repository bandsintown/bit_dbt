{{
  config(
    materialized='table',
    tags=['feature_events', 'marts', 'kpi']
  )
}}

-- Fact: one row per nonce. Boosted events only.
-- Carries artist_id (raw upstream FK to dim_artist).
-- Does NOT carry package_id — join through dim_boost_package_events on event_id.
-- Does NOT carry promoter_id — join through dim_boost_package_events.package_id ->
--   fct_boost_package.promoter_id (surrogate) -> dim_promoter.
with featured_events as (
    select
        event_id,
        artist_id,
        boost_start_date,
        boost_end_date
    from {{ ref('stg_featured_events') }}
)

select
    d.nonce,
    d.artist_event_int_id as event_id,
    fe.artist_id,
    d.user_id as fan_id,

    -- surface: web, app_ios, app_android, email
    case
        when d.impression_channel = 'email' then 'email'
        when lower(coalesce(d.property, '')) = 'ios_fan_app'     then 'app_ios'
        when lower(coalesce(d.property, '')) = 'android_fan_app' then 'app_android'
        else 'web'
    end as surface,

    -- placement_type: boosted or organic
    case
        when d.impression_channel in ('pixel_v2', 'email') then 'boosted'
        else 'organic'
    end as placement_type,

    -- traffic_source_category


    coalesce(d.impression_logged_at, cast(d.ds as timestamp)) as impression_logged_at

from {{ ref('int_featured_event_impressions') }} d
inner join featured_events fe
    on fe.event_id = d.artist_event_int_id
where fe.boost_start_date is not null
  and (fe.boost_end_date is null
       or cast(d.ds as date) >= cast(fe.boost_start_date as date))
