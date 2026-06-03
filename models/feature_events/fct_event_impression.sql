{{
  config(
    materialized='table',
    tags=['feature_events', 'marts', 'kpi']
  )
}}

with featured_events as (
    select
        event_id,
        sources as fe_source,
        boost_start_date,
        boost_end_date
    from (
        select
            *,
            row_number() over (
                partition by event_id
                order by tracked_at desc
            ) as row_num
        from {{ source('featured_events', 'featured_events_changelog') }}
    ) fe
    where row_num = 1
),
base_impressions as (
    select
        i.nonce,
        i.artist_event_int_id as event_id,
        i.ds as date,
        coalesce(fe.fe_source, array[coalesce(i.fe_source, 'unknown')]) as fe_source,
        i.impression_channel,
        i.user_id
    from {{ ref('int_featured_event_impressions') }} i
    left join featured_events fe
        on fe.event_id = i.artist_event_int_id
    where fe.boost_start_date is null
       or cast(i.ds as varchar) >= cast(fe.boost_start_date as varchar)
),
deduped as (
    select
        *,
        row_number() over (
            partition by nonce
            order by date desc, event_id desc
        ) as rn
    from base_impressions
)

select
    nonce,
    event_id,
    date,
    fe_source,
    impression_channel,
    user_id,
    cast(current_timestamp as timestamp) as updated_at
from deduped
where rn = 1
