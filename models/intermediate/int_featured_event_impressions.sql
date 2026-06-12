{{
  config(
    materialized='view',
    tags=['feature_events', 'impressions', 'intermediate']
  )
}}

with pixel as (
    select
        cast(trim(cast(artist_event_int_id as varchar)) as bigint) as artist_event_int_id,
        ds,
        fe_source,
        nonce,
        user_id,
        source as pixel_source,
        property,
        pixel_datetime as impression_logged_at,
        'pixel' as impression_channel
    from {{ ref('stg_featured_events_pixel_impressions') }}
),
pixel_v2 as (
    select
        cast(trim(cast(artist_event_int_id as varchar)) as bigint) as artist_event_int_id,
        ds,
        fe_source,
        nonce,
        user_id,
        source as pixel_source,
        property,
        pixel_datetime as impression_logged_at,
        'pixel_v2' as impression_channel
    from {{ ref('stg_featured_events_pixel_impressions_v2') }}
),
email as (
    select
        cast(trim(cast(artist_event_int_id as varchar)) as bigint) as artist_event_int_id,
        ds,
        fe_source,
        nonce,
        user_id,
        cast(null as varchar) as pixel_source,
        cast(null as varchar) as property,
        cast(from_iso8601_timestamp(timestamp_str) as timestamp) as impression_logged_at,
        'email' as impression_channel
    from {{ ref('stg_featured_events_email_impressions') }}
    where lower(coalesce(event, '')) = 'real_open'
      and cardinality(filter(featured_events_ids, x -> x is not null and x != '')) > 0
)

select * from pixel
union all
select * from pixel_v2
union all
select * from email
