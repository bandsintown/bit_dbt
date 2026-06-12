{{
  config(
    materialized='view',
    tags=['feature_events', 'alacarte', 'staging']
  )
}}

select
    cast(id as integer) as id,
    cast(artist_id as integer) as artist_id,
    cast(manager_id as integer) as manager_id,
    cast(description as varchar) as description,
    cast(checkout_id as varchar) as checkout_id,
    cast(invoice_id as varchar) as invoice_id,
    cast(sf_opportunity_id as varchar) as sf_opportunity_id,
    cast(price as varchar) as price,
    cast(source as varchar) as source,
    cast(status as varchar) as status,
    from_unixtime(start_date_time) as start_date_time,
    from_unixtime(end_date_time) as end_date_time,
    from_unixtime(created_at) as created_at,
    from_unixtime(updated_at) as updated_at,
    cast(deleted as integer) as deleted,
    cast(created_by as varchar) as created_by,
    cast(updated_by as varchar) as updated_by,
    from_unixtime(activated_at) as activated_at
from {{ source('featured_events', 'alacarte_artists_packages') }}

