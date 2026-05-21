{{
  config(
    materialized='table',
    tags=['feature_events', 'marts']
  )
}}

select
    i.*,
    evl.artist_id,
    evl.artist_name,
    al.tracker_count,
    evl.venue_id,
    evl.venue_name,
    evl.venue_country,
    v.capacity,
    v.premium_flag,
    v.managed_flag,
    evl.event_date,
    ef.festival_name,
    ef.festival_edition_id,
    if(b.event_id is null, 'OTHER SOURCE', 'BIT4A') as purchase_source
from {{ ref('int_kpis_by_day') }} as i
join {{ ref('int_evl') }} as evl
    on cast(evl.artist_event_int_id as varchar) = i.artist_event_int_id
left join {{ ref('int_events_of_festival_premium') }} as ef
    on cast(ef.artist_event_int_id as varchar) = i.artist_event_int_id
left join {{ source('tableau_db', 'artist_list_parquet') }} as al
    on cast(al.artist_id as varchar) = evl.artist_id
left join {{ ref('int_venues_dataset') }} as v
    on v.venue_id = evl.venue_id
left join {{ ref('int_bit4a_event') }} as b
    on cast(b.event_id as varchar) = i.artist_event_int_id

