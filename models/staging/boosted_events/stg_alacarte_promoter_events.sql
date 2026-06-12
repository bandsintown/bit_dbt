{{
  config(
    materialized='view',
    tags=['feature_events', 'alacarte', 'staging']
  )
}}

select
    cast(cast(id as varchar) as integer) as id,
    cast(event_id as varchar) as event_id,
    cast(reason as varchar) as reason,
    from_unixtime(start_date) as start_date,
    pixels,
    cast(info as varchar) as info,
    cast(cast(package_id as varchar) as integer) as package_id,
    cast(created_by as varchar) as created_by,
    cast(updated_by as varchar) as updated_by,
    from_unixtime(created_at) as created_at,
    from_unixtime(updated_at) as updated_at,
    cast(deleted as boolean) as deleted,
    cast(genres as varchar) as genres
from {{ source('featured_events', 'alacarte_promoter_events') }}
