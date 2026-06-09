{{
  config(
    materialized='table',
    tags=['feature_events', 'dims']
  )
}}

-- Dimension: one row per featured event
-- Base from the current-state table; campaign/goal fields from latest changelog entry
with changelog_latest as (
    select
        event_id,
        campaign_flat_fee,
        urgency_score,
        cpc_goal_met,
        cpm_goal_met,
        campaign_state,
        goal_achieved,
        tracked_at as last_tracked_at,
        row_number() over (
            partition by event_id
            order by tracked_at desc
        ) as row_num
    from {{ ref('stg_featured_events_changelog') }}
)

select
    fe.event_id,
    fe.artist_id,
    fe.venue_id,
    fe.festival_id,
    fe.sources as fe_sources,
    fe.boost_start_date,
    fe.boost_end_date,
    cl.campaign_flat_fee,
    cl.urgency_score,
    cl.cpc_goal_met,
    cl.cpm_goal_met,
    cl.campaign_state,
    cl.goal_achieved,
    cl.last_tracked_at
from {{ ref('stg_featured_events') }} fe
left join changelog_latest cl
    on cl.event_id = fe.event_id
   and cl.row_num = 1
