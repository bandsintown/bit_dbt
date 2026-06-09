{{
  config(
    materialized='table',
    tags=['feature_events', 'dims']
  )
}}

-- Dimension: one row per featured event (latest state from changelog)
with latest as (
    select
        *,
        row_number() over (
            partition by event_id
            order by tracked_at desc
        ) as row_num
    from {{ ref('stg_featured_events_changelog') }}
)

select
    event_id,
    sources as fe_sources,
    boost_start_date,
    boost_end_date,
    tracked_at as last_tracked_at
from latest
where row_num = 1

