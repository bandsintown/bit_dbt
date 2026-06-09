{{
  config(
    materialized='view',
    tags=['feature_events', 'alacarte', 'staging']
  )
}}

select
    cast(cast(id as varchar) as integer) as id,
    cast(cast(promoter_id as varchar) as integer) as promoter_id,
    cast(name as varchar) as name,
    cast(description as varchar) as description,
    cast(sf_opportunity_id as varchar) as sf_opportunity_id,
    cast(invoice_id as varchar) as invoice_id,
    cast(status as varchar) as status,
    cast(activated_at as timestamp) as activated_at,
    cast(audience_sharing as boolean) as audience_sharing,
    cast(type as varchar) as type,
    cast(created_by as varchar) as created_by,
    cast(updated_by as varchar) as updated_by,
    cast(created_at as timestamp) as created_at,
    cast(updated_at as timestamp) as updated_at,
    cast(deleted as boolean) as deleted
from {{ source('featured_events', 'alacarte_promoter_packages') }}

