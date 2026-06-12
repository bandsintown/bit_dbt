{{
  config(
    materialized='view',
    tags=['feature_events', 'clicks', 'staging']
  )
}}

select
    cast(cast(artist_event_int_id as varchar) as integer) as artist_event_int_id,
    cast(substr(cast(ds as varchar), 1, 10) as date) as ds,
    cast(fe_source as varchar) as fe_source,
    cast(replace(cast(click_datetime as varchar), 'T', ' ') as timestamp) as click_datetime,
    cast(cast(user_id as varchar) as integer) as user_id,
    cast(user_agent as varchar) as user_agent,
    cast(artist as varchar) as artist,
    cast(event_region as varchar) as event_region,
    cast(event_country as varchar) as event_country,
    cast(event_city as varchar) as event_city,
    cast(ticket_seller_url as varchar) as ticket_seller_url,
    cast(ticket_seller_host as varchar) as ticket_seller_host,
    cast(mobile as varchar) as mobile,
    cast(referer_host as varchar) as referer_host,
    cast(referer as varchar) as referer,
    cast(extended_affil_code as varchar) as extended_affil_code,
    cast(cast(came_from as varchar) as integer) as came_from,
    cast(app_id as varchar) as app_id,
    cast(affil_code as varchar) as affil_code,
    cast(ip as varchar) as ip,
    cast(json as varchar) as json
from {{ source('featured_events', 'ticketclicks') }}
