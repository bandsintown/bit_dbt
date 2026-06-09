{{
  config(
    materialized='table',
    tags=['feature_events', 'marts', 'kpi']
  )
}}

-- Fact: one row per ticket click (click_id grain)
-- KPIs: event_clicks, boost_clicks_distribution_partners
select
    row_number() over (
        order by tc.click_datetime, tc.artist_event_int_id, tc.user_id
    ) as click_id,
    tc.artist_event_int_id as event_id,
    fe.artist_id,
    tc.ds as date,
    tc.fe_source,
    tc.click_datetime,
    tc.user_id,
    tc.user_agent,
    tc.ticket_seller_host,
    tc.ticket_seller_url,
    tc.referer_host,
    tc.mobile,
    tc.app_id,
    tc.affil_code,
    cast(current_timestamp as timestamp) as updated_at
from {{ ref('dim_featured_events_ticket_clicks') }} tc
left join {{ ref('dim_featured_event') }} fe
    on fe.event_id = tc.artist_event_int_id

