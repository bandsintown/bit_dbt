{{
  config(
    materialized='view',
    tags=['feature_events', 'alacarte', 'staging']
  )
}}

select
    cast(id as integer) as id,
    cast(event_id as integer) as event_id,
    cast(package_id as integer) as package_id,
    cast(description as varchar) as description,
    cast(event_data as varchar) as event_data,
    cast(status as varchar) as status,
    from_unixtime(created_at) as created_at,
    from_unixtime(updated_at) as updated_at,
    cast(created_by as varchar) as created_by,
    cast(updated_by as varchar) as updated_by,
    from_unixtime(activated_at) as activated_at,
    cast(deleted as integer) as deleted
from {{ source('featured_events', 'alacarte_artists_events') }}

