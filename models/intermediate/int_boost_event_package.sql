{{
  config(
    materialized='view',
    tags=['feature_events', 'alacarte', 'intermediate']
  )
}}

-- Intermediate: join promoter events to their packages
-- Grain: one row per event × package (active only)
select
    pe.id as promoter_event_id,
    pe.event_id,
    pe.package_id,
    pe.start_date as event_boost_start_date,
    pp.promoter_id,
    pp.name as package_name,
    pp.status as package_status,
    pp.type as package_type,
    pp.activated_at as package_activated_at
from {{ ref('stg_alacarte_promoter_events') }} pe
inner join {{ ref('stg_alacarte_promoter_packages') }} pp
    on pp.id = pe.package_id
where pe.deleted = false
  and pp.deleted = false

