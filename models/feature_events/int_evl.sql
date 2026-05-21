select distinct
    e.artist_event_int_id,
    e.artist.id as artist_id,
    e.artist.name as artist_name,
    e.venue.id as venue_id,
    e.venue.name as venue_name,
    e.venue.country as venue_country,
    e.date_info.event_date
from {{ source('tableau_db', 'daily_snapshot_events_parquet') }} as e
where lower(e.status) in ('published', 'autopublished')

