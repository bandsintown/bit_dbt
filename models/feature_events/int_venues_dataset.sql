with venues_managed as (
    select distinct
        venue_id
    from {{ source('tableau_db', 'venue_admin_parquet') }}
    where status_manager = 1
      and status_relation = 1
      and status_managed_actor = 1
)
select distinct
    av.id as venue_id,
    av.capacity,
    av.verified,
    if(vs.venue_id is null, 'not premium venue', 'premium venue') as premium_flag,
    if(vm.venue_id is null, 'not managed venue', 'managed venue') as managed_flag,
    av.type as venue_type
from {{ source('tableau_db', 'daily_snapshot_venues_parquet') }} as av
left join (
    select distinct venue_id
    from {{ source('bit_venues', 'venue_subscriptions') }}
    where is_subscription_active = 1
) as vs on cast(vs.venue_id as varchar) = av.id
left join venues_managed as vm
    on vm.venue_id = av.id
where av.address_is_primary = 1
  and av.name_is_primary = 1

