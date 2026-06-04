{{
  config(
    materialized='view',
    tags=['feature_events', 'impressions', 'intermediate']
  )
}}

with pixel as (
    select
        artist_event_int_id,
        ds,
        fe_source,
        nonce,
        user_id,
        'pixel' as impression_channel
    from {{ ref('stg_featured_events_pixel_impressions') }}
),
email as (
    select
        artist_event_int_id,
        ds,
        fe_source,
        nonce,
        user_id,
        'email' as impression_channel
    from {{ ref('stg_featured_events_email_impressions') }}
)

select * from pixel
union all
select * from email
