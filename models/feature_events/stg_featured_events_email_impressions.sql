{{
  config(
    materialized='view',
    tags=['feature_events', 'impressions', 'staging']
  )
}}

with src as (
    select
        cast(fe_id as integer) as artist_event_int_id,
        cast(ds as date) as ds,
        cast('email' as varchar) as fe_source,
        cast(nonce as varchar) as nonce,
        cast(user_id as integer) as user_id,
        cast(useragent as varchar) as user_agent,
        cast(category as varchar) as category
    from {{ source('featured_events', 'email_real_opens') }}
    cross join unnest(featured_events_ids) as t(fe_id)
    where nonce is not null
      and lower(coalesce(event, '')) = 'real_open'
      and cardinality(filter(featured_events_ids, x -> x is not null and x != '')) > 0
)

select *
from src

