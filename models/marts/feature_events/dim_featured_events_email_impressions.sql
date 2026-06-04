{{
  config(
    materialized='table',
    tags=['feature_events', 'dims']
  )
}}

-- Dimension: deduplicated email impressions (one row per nonce)
with deduped as (
    select
        *,
        row_number() over (
            partition by nonce
            order by ds desc
        ) as row_num
    from {{ ref('stg_featured_events_email_impressions') }}
    where nonce is not null
      and artist_event_int_id is not null
      and lower(coalesce(event, '')) = 'real_open'
      and cardinality(filter(featured_events_ids, x -> x is not null and x != '')) > 0
)

select
    artist_event_int_id,
    ds,
    fe_source,
    nonce,
    user_id,
    user_agent,
    category
from deduped
where row_num = 1

