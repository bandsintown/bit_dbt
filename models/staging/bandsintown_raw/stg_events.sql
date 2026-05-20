{{
    config(
        materialized='view',
        tags=['staging', 'events']
    )
}}

with source as (

    select * from {{ source('bandsintown_raw', 'events') }}

),

renamed as (

    select
        -- Primary key
        event_id,

        -- Foreign keys
        artist_id,
        venue_id,

        -- Event details
        event_date,
        event_status,
        ticket_url,

        -- Metadata
        created_at,
        updated_at,

        -- Calculated fields
        cast(event_date as date) as event_date_only,
        date_format(event_date, '%Y-%m') as event_month,
        year(event_date) as event_year,

        -- Data quality flags
        case
            when event_status in ('upcoming', 'cancelled', 'postponed', 'past') then true
            else false
        end as is_valid_status

    from source

    -- Filter out test/invalid data
    where event_id is not null
        and artist_id is not null
        and event_date is not null

)

select * from renamed

