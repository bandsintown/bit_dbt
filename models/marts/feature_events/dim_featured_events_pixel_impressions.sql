{{
  config(
    materialized='table',
    tags=['feature_events', 'dims']
  )
}}

-- Dimension: deduplicated pixel impressions (one row per nonce)
with deduped as (
    select
        *,
        row_number() over (
            partition by nonce
            order by ds desc
        ) as row_num
    from {{ ref('stg_featured_events_pixel_impressions') }}
    where nonce is not null
      and artist_event_int_id is not null
)

select
    artist_event_int_id,
    ds,
    fe_source,
    nonce,
    user_id,
    user_agent
from deduped
where row_num = 1

