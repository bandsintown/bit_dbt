with fe_source_by_event as (
    select
        artist_event_int_id,
        count(distinct fe_source) as nb
    from (
        select distinct artist_event_int_id, fe_source
        from {{ source('featured_events', 'all_time_featured_events_list') }}

        union

        select distinct artist_event_int_id, fe_source
        from {{ source('featured_events', 'ticketclicks') }}
    )
    group by artist_event_int_id
),
unique_featured_events_list as (
    select
        a.artist_event_int_id,
        a.fe_source
    from fe_source_by_event as f
    join {{ source('featured_events', 'all_time_featured_events_list') }} as a
        on a.artist_event_int_id = f.artist_event_int_id
    where f.nb = 2
      and a.subscription_starts_at is not null
      and a.subscription_ends_at is not null

    union

    select
        a.artist_event_int_id,
        a.fe_source
    from fe_source_by_event as f
    join (
        select distinct artist_event_int_id, fe_source
        from {{ source('featured_events', 'all_time_featured_events_list') }}

        union

        select distinct artist_event_int_id, fe_source
        from {{ source('featured_events', 'ticketclicks') }}
    ) as a
        on a.artist_event_int_id = f.artist_event_int_id
    where f.nb = 1
)
select
    artist_event_int_id,
    min(fe_source) as fe_source
from unique_featured_events_list
group by artist_event_int_id

