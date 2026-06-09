{{
  config(
    materialized='table',
    tags=['feature_events', 'marts', 'kpi']
  )
}}

-- Fact: one row per deduplicated impression (nonce grain)
-- KPIs: event_impressions, event_unique_fans_reached
with featured_events as (
    select
        event_id,
        artist_id,
        fe_sources as fe_source,
        boost_start_date,
        boost_end_date
    from {{ ref('dim_featured_event') }}
)

select
    d.nonce,
    d.artist_event_int_id as event_id,
    fe.artist_id,
    d.ds as date,
    coalesce(fe.fe_source, array[coalesce(d.fe_source, 'unknown')]) as fe_source,
    d.impression_channel,
    d.user_id,
    cast(current_timestamp as timestamp) as updated_at
from {{ ref('dim_event_impression') }} d
left join featured_events fe
    on fe.event_id = d.artist_event_int_id
where fe.boost_start_date is null
   or cast(d.ds as varchar) >= cast(fe.boost_start_date as varchar)
