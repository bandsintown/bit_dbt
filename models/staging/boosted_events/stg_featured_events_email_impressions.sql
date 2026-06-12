{{
  config(
    materialized='view',
    tags=['feature_events', 'impressions', 'staging']
  )
}}

select
    cast(fe_id as varchar) as artist_event_int_id,
    cast(ds as date) as ds,
    cast('email' as varchar) as fe_source,
    cast(nonce as varchar) as nonce,
    cast(cast(user_id as varchar) as integer) as user_id,
    cast(useragent as varchar) as user_agent,
    cast(category as varchar) as category,
    cast(event as varchar) as event,
    cast(email as varchar) as email,
    cast(sg_machine_open as varchar) as sg_machine_open,
    cast(ip as varchar) as ip,
    cast(sg_content_type as varchar) as sg_content_type,
    cast(sg_event_id as varchar) as sg_event_id,
    cast(sg_message_id as varchar) as sg_message_id,
    cast(sg_template_id as varchar) as sg_template_id,
    cast(sg_template_name as varchar) as sg_template_name,
    cast(response as varchar) as response,
    cast(correlation_id as varchar) as correlation_id,
    cast(reason as varchar) as reason,
    cast(status as varchar) as status,
    cast(type as varchar) as type,
    cast(smtp_id as varchar) as smtp_id,
    cast(last_opened_at as varchar) as last_opened_at,
    cast(activity_id as bigint) as activity_id,
    cast(message_id as bigint) as message_id,
    cast(url as varchar) as url,
    cast(venue_id as integer) as venue_id,
    cast(timestamp_str as varchar) as timestamp_str,
    cast("timestamp" as bigint) as event_timestamp,
    artist_ids,
    event_ids,
    featured_events_ids,
    upcoming_event_ids
from {{ source('featured_events', 'email_real_opens') }}
cross join unnest(featured_events_ids) as t(fe_id)
