{{
  config(
    materialized='table',
    tags=['feature_events', 'boost', 'inventory']
  )
}}

-- Fact: one row per event
-- Size buckets locked at first flight start
with event_lifetime as (
    select
        event_id,
        count(*) as lifetime_impressions,
        count(distinct user_id) as lifetime_unique_users
    from {{ ref('fct_event_impression') }}
    group by 1
)

select
    fe.event_id,
    fe.artist_id,
    fe.boost_start_date,
    fe.boost_end_date,
    fe.campaign_state,
    fe.campaign_flat_fee,
    coalesce(el.lifetime_impressions, 0) as lifetime_impressions,
    coalesce(el.lifetime_unique_users, 0) as lifetime_unique_users,
    ntile(5) over (
        order by coalesce(el.lifetime_impressions, 0)
    ) as size_quintile,
    case
        when coalesce(el.lifetime_impressions, 0) = 0     then 'no_activity'
        when coalesce(el.lifetime_impressions, 0) < 100    then 'xs'
        when coalesce(el.lifetime_impressions, 0) < 1000   then 'small'
        when coalesce(el.lifetime_impressions, 0) < 10000  then 'medium'
        when coalesce(el.lifetime_impressions, 0) < 100000 then 'large'
        else 'xl'
    end as size_bucket,
    cast(current_timestamp as timestamp) as updated_at
from {{ ref('dim_featured_event') }} fe
left join event_lifetime el
    on el.event_id = fe.event_id

