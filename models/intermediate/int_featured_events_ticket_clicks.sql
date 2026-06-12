{{
  config(
    materialized='view',
    tags=['feature_events', 'clicks', 'intermediate']
  )
}}

-- Intermediate: ticket clicks with utm fields extracted from json
select
    artist_event_int_id,
    ds,
    fe_source,
    click_datetime,
    user_id,
    user_agent,
    artist,
    event_region,
    event_country,
    event_city,
    ticket_seller_url,
    ticket_seller_host,
    mobile,
    referer_host,
    referer,
    app_id,
    affil_code,
    ip,
    came_from,
    cast(json_extract_scalar(json, '$.utm_medium') as varchar) as utm_medium,
    cast(json_extract_scalar(json, '$.utm_campaign') as varchar) as utm_campaign
from {{ ref('stg_featured_events_ticket_clicks') }}
where artist_event_int_id is not null

