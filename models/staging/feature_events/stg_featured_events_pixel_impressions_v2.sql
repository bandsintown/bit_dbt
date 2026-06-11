{{
  config(
    materialized='view',
    tags=['feature_events', 'impressions', 'staging']
  )
}}

select
    cast(fe_id as integer) as artist_event_int_id,
    cast(substr(cast(ds as varchar), 1, 10) as date) as ds,
    cast(source as varchar) as fe_source,
    cast(source as varchar) as source,
    cast(nonce as varchar) as nonce,
    cast(null as integer) as user_id,
    cast(user_agent as varchar) as user_agent,
    cast(replace(cast("timestamp" as varchar), 'T', ' ') as timestamp) as pixel_datetime,
    cast(referer as varchar) as referer,
    cast(ip_address as varchar) as ip_address,
    cast(property as varchar) as property,
    cast(request_uid as varchar) as request_uid,
    cast(status_code as integer) as status_code,
    cast(path as varchar) as path,
    cast(query_string as varchar) as query_string,
    cast(is_valid as boolean) as is_valid,
    cast(param_json as varchar) as param_json,
    custom,
    cast(came_from as integer) as came_from,
    featured_event_ids,
    cast(date as varchar) as date
from {{ source('featured_events', 'pixel_impressions_v2') }}
cross join unnest(featured_event_ids) as t(fe_id)
