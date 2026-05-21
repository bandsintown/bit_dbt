with events_tag as (
    select
        e.artist_event_int_id,
        tag
    from {{ source('tableau_db', 'daily_snapshot_events_parquet') }} as e
    cross join unnest(e.tags) as t(tag)
    where e.actor = 'artist'
      and e.status in ('PUBLISHED', 'AUTOPUBLISHED')
      and e.artist.id is not null
      and e.artist.id != '-1'
)
select distinct
    et.artist_event_int_id,
    f.festival_name,
    f.id as festival_edition_id
from events_tag as et
join {{ source('tableau_db', 'festival_editions') }} as f
    on et.tag = f.tag
where f.status is null
   or f.status not in ('CANCELLED', 'DELETED')

