{{
  config(
    materialized='table',
    tags=['feature_events', 'marts', 'kpi']
  )
}}

with featured_events as (
    select
        cast(artist_event_int_id as integer) as event_id,
        cast(coalesce(fe_source, 'unknown') as varchar) as fe_source,
        cast(subscription_starts_at as date) as subscription_starts_at
    from {{ source('featured_events', 'featured_events_list') }}
),
base_impressions as (
    select
        i.nonce,
        i.artist_event_int_id as event_id,
        i.ds as date,
        coalesce(i.fe_source, fe.fe_source, 'unknown') as fe_source,
        i.impression_channel,
        i.user_id
    from {{ ref('int_featured_event_impressions') }} i
    left join featured_events fe
        on fe.event_id = i.artist_event_int_id
    where fe.subscription_starts_at is null
       or i.ds >= fe.subscription_starts_at
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


