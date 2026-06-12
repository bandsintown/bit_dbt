{{
  config(
    materialized='table',
    tags=['feature_events', 'dims']
  )
}}

-- Dimension: promoter identity with surrogate primary key.
-- Resolves the collision between raw artist_id and raw promoter_id
-- (overlapping integer spaces) by generating a deterministic surrogate
-- from (purchaser_type, source_id).
with promoters as (
    select distinct
        cast('promoter' as varchar) as purchaser_type,
        promoter_id as source_id,
        name as promoter_name
    from {{ ref('stg_alacarte_promoter_packages') }}
    where deleted = false
),

artists as (
    select
        cast('artist' as varchar) as purchaser_type,
        artist_id as source_id,
        artist_name as promoter_name
    from {{ ref('int_boost_artist') }}
),

unioned as (
    select * from promoters
    union all
    select * from artists
)

select
    to_hex(md5(to_utf8(
        coalesce(cast(purchaser_type as varchar), '_null_')
        || '||'
        || coalesce(cast(source_id as varchar), '_null_')
    ))) as promoter_id,
    purchaser_type,
    source_id,
    promoter_name
from unioned
