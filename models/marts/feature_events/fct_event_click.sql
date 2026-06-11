{{
  config(
    materialized='table',
    tags=['feature_events', 'marts', 'kpi']
  )
}}

-- Fact: one row per click_id. All clicks, all sources.
-- placement_type reliable for email only.
-- Carries artist_id (raw FK to dim_artist). No package_id or promoter_id columns.
select
    row_number() over (
        order by tc.click_datetime, tc.artist_event_int_id, tc.user_id
    ) as click_id,
    tc.artist_event_int_id as event_id,
    fe.artist_id,
    tc.user_id as fan_id,

    -- surface: web, app_ios, app_android, email
    case
        when lower(coalesce(tc.fe_source, '')) = 'email' then 'email'
        when lower(coalesce(tc.utm_medium, '')) like '%ios%' then 'app_ios'
        when lower(coalesce(tc.utm_medium, '')) like '%android%' then 'app_android'
        when lower(coalesce(tc.utm_medium, '')) like '%web%' then 'web'
        else 'other'
    end as surface,

    -- placement_type: boosted, organic, or unknown
    case
        when lower(coalesce(tc.fe_source, '')) = 'email' then 'boosted'
        when lower(coalesce(tc.utm_campaign, '')) like '%feature_event%' then 'boosted'
        when lower(coalesce(tc.utm_medium, '')) not like '%ios%'
         and lower(coalesce(tc.utm_medium, '')) not like '%android%'
         and lower(coalesce(tc.utm_medium, '')) not like '%web%'
         and lower(coalesce(tc.utm_campaign, '')) not like '%feature_event%' then 'organic'
        else 'other'
    end as placement_type,

    -- traffic_source_category
    case
        when tc.came_from in (242, 267, 269, 700, 702) then 'artist_property'
        when tc.came_from in (280, 281, 282, 283, 284, 285, 286, 287, 288, 289, 990) then 'distribution_partner'
        when tc.came_from is null then 'unknown'
        else 'bandsintown_owned'
    end as traffic_source_category,

    -- nonce: email only, null for web/app/partner
    cast(null as varchar) as nonce,

    tc.click_datetime as clicked_at,

    -- is_ticket_link_click
    case
        when tc.ticket_seller_url is not null and tc.ticket_seller_url != '' then true
        else false
    end as is_ticket_link_click,

    cast(current_timestamp as timestamp) as updated_at
from {{ ref('dim_featured_events_ticket_clicks') }} tc
left join {{ ref('dim_featured_event') }} fe
    on fe.event_id = tc.artist_event_int_id
