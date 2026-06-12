{{
  config(
    materialized='table',
    tags=['feature_events', 'alacarte', 'intermediate']
  )
}}

-- Intermediate: artists that have at least one alacarte package.
-- Deduplicates by artist_id and carries the artist_size_bucket from seed.
with artists_with_packages as (
    select distinct artist_id
    from {{ ref('stg_alacarte_artists_packages') }}
    where deleted = 0
),

enriched as (
    select
        ab.artist_id,
        ab.name as artist_name,
        ab.tracker_count,
        asb.artist_size_bucket
    from {{ ref('stg_artist_batch') }} ab
    inner join artists_with_packages awp
        on awp.artist_id = ab.artist_id
    left join {{ ref('artist_size_buckets') }} asb
        on coalesce(ab.tracker_count, 0) >= asb.tracker_count_min
       and coalesce(ab.tracker_count, 0) <= asb.tracker_count_max
)

select
    artist_id,
    artist_name,
    tracker_count,
    artist_size_bucket
from enriched


