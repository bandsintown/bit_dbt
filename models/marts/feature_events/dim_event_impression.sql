{{
  config(
    materialized='table',
    tags=['feature_events', 'dims']
  )
}}

-- Dimension: deduplicated impressions (one row per nonce)
with filtered as (
    select
        artist_event_int_id,
        ds,
        fe_source,
        nonce,
        user_id,
        pixel_source,
        property,
        impression_logged_at,
        impression_channel
    from {{ ref('int_featured_event_impressions') }}
    where nonce is not null
      and artist_event_int_id is not null
),
deduped as (
    select
        *,
        row_number() over (
            partition by nonce
            order by ds desc, artist_event_int_id desc
        ) as row_num
    from filtered
)

select
    artist_event_int_id,
    ds,
    fe_source,
    nonce,
    user_id,
    pixel_source,
    property,
    impression_logged_at,
    impression_channel
from deduped
where row_num = 1
