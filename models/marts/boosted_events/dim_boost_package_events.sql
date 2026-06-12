{{
  config(
    materialized='table',
    tags=['feature_events', 'boost', 'dims']
  )
}}

-- Dimension: authoritative bridge table for package ↔ event.
-- One row per package_id × event_id (event_id is unique — 1:1).
-- Revenue split LOCKED at purchase time by venue capacity.
-- artist_size_bucket is HISTORICAL (locked at flight start).
with promoter_events as (
    select
        pe.package_id,
        cast(pe.event_id as integer) as event_id,
        pp.price as package_price,
        pe.start_date as flight_start_date
    from {{ ref('stg_alacarte_promoter_events') }} pe
    inner join {{ ref('stg_alacarte_promoter_packages') }} pp
        on pp.id = pe.package_id
    where pe.deleted = false
      and pp.deleted = false
),

artist_events as (
    select
        ae.package_id,
        ae.event_id,
        cast(ap.price as decimal(10,2)) as package_price,
        ae.activated_at as flight_start_date
    from {{ ref('stg_alacarte_artists_events') }} ae
    inner join {{ ref('stg_alacarte_artists_packages') }} ap
        on ap.id = ae.package_id
    where ae.deleted = 0
      and ap.deleted = 0
),

package_events as (
    select * from promoter_events
    union all
    select * from artist_events
),

event_details as (
    select
        artist_event_int_id as event_id,
        artist_id,
        cast(venue_id as integer) as venue_id,
        cast(starts_at as varchar) as event_date
    from {{ ref('stg_events_batch_v2') }}
),

venue_details as (
    select
        cast(venue_id as integer) as venue_id,
        coalesce(capacity, 0) as venue_capacity,
        country_name as country,
        region_code as region,
        city_name as city
    from {{ ref('stg_venues_batch') }}
),

artist_details as (
    select
        artist_id,
        artist_size_bucket
    from {{ ref('int_boost_artist') }}
),

enriched as (
    select
        pe.package_id,
        pe.event_id,
        ed.venue_id,
        vd.venue_capacity,
        pe.package_price,
        cast(pe.flight_start_date as date) as flight_start_date,
        cast(from_iso8601_timestamp(ed.event_date) as date) as flight_end_date,
        ed.artist_id,
        ad.artist_size_bucket,
        vt.venue_size_bucket,
        vt.tier_price,
        vd.country,
        vd.region,
        vd.city
    from package_events pe
    inner join event_details ed
        on ed.event_id = pe.event_id
    left join venue_details vd
        on vd.venue_id = ed.venue_id
    left join artist_details ad
        on ad.artist_id = ed.artist_id
    left join {{ ref('seed_venue_capacity_tiers') }} vt
        on coalesce(vd.venue_capacity, 0) >= vt.venue_capacity_min
       and coalesce(vd.venue_capacity, 0) <= vt.venue_capacity_max
),

with_allocation as (
    select
        *,
        tier_price / nullif(sum(tier_price) over (partition by package_id), 0)
            as revenue_allocation_pct
    from enriched
)

select
    package_id,
    event_id,
    venue_id,
    venue_capacity,
    revenue_allocation_pct,
    cast(package_price as double) * revenue_allocation_pct as revenue_allocated,
    flight_start_date,
    flight_end_date,
    artist_id,
    artist_size_bucket,
    venue_size_bucket,
    country,
    region,
    city
from with_allocation
