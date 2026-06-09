{{
  config(
    materialized='view',
    tags=['feature_events', 'alacarte', 'staging']
  )
}}

select
    cast(cast(id as varchar) as integer) as id,
    cast(cast(event_id as varchar) as integer) as event_id,
    cast(reason as varchar) as reason,
    cast(start_date as timestamp) as start_date,
    cast(pixels as varchar) as pixels,
    cast(info as varchar) as info,
    cast(cast(package_id as varchar) as integer) as package_id,
    cast(created_by as varchar) as created_by,
    cast(updated_by as varchar) as updated_by,
    cast(created_at as timestamp) as created_at,
    cast(updated_at as timestamp) as updated_at,
    cast(deleted as boolean) as deleted
from {{ source('featured_events', 'alacarte_promoter_events') }}

