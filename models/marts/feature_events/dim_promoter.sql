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
with promoter_latest as (
    select
        cast('promoter' as varchar) as purchaser_type,
        promoter_id as source_id,
        name as promoter_name,
        row_number() over (
            partition by promoter_id
            order by updated_at desc
        ) as row_num
    from {{ ref('stg_alacarte_promoter_packages') }}
    where deleted = false
),

artist_latest as (
    select
        cast('artist' as varchar) as purchaser_type,
        ap.artist_id as source_id,
        ab.name as promoter_name,
        row_number() over (
            partition by ap.artist_id
            order by ap.updated_at desc
        ) as row_num
    from {{ ref('stg_alacarte_artists_packages') }} ap
    left join {{ ref('stg_artist_batch') }} ab
        on ab.artist_id = ap.artist_id
    where ap.deleted = 0
),

unioned as (
    select purchaser_type, source_id, promoter_name
    from promoter_latest
    where row_num = 1

    union all

    select purchaser_type, source_id, promoter_name
    from artist_latest
    where row_num = 1
)

select
    {{ dbt_utils.generate_surrogate_key(['purchaser_type', 'source_id']) }} as promoter_id,
    purchaser_type,
    source_id,
    promoter_name
from unioned

