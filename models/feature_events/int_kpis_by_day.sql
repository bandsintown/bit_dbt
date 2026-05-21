with email_impressions_snapshot as (
    select * from {{ ref('stg_email_impressions_snapshot') }}
),
impression_carousels as (
    select * from {{ ref('stg_impression_carousels') }}
),
event_id_with_fe_source as (
    select * from {{ ref('int_event_id_with_fe_source') }}
)

select
    'Impressions' as source,
    e.date,
    e.category,
    es.fe_source as type,
    null as ticket_seller_host,
    'Email' as sub_source,
    e.artist_event_int_id,
    'Email ' || e.category as property,
    count(e.sg_message_id) as nb
from email_impressions_snapshot as e
left join event_id_with_fe_source as es
    on cast(es.artist_event_int_id as varchar) = e.artist_event_int_id
group by
    e.category,
    es.fe_source,
    e.artist_event_int_id,
    'Email ' || e.category,
    e.date

union all

select
    'TicketClicks' as source,
    substr(cast(t.ds as varchar), 1, 10) as date,
    null as category,
    t.fe_source as type,
    t.ticket_seller_host,
    json_extract_scalar(t.json, '$.utm_source') as sub_source,
    cast(t.artist_event_int_id as varchar) as artist_event_int_id,
    case
        when cast(t.came_from as varchar) in ('240', '237') then 'Email Post To Trackers or RSVPs'
        when cast(t.came_from as varchar) = '342' then 'Email Builder'
        when cast(t.came_from as varchar) = '248' then 'Email Artist with Widget'
        when cast(t.came_from as varchar) = '301' then 'Promoter Email'
        when cast(t.came_from as varchar) = '302' then 'Promoter Mobile Push'
        when cast(t.came_from as varchar) = '287' then 'Partner API'
        when cast(t.came_from as varchar) = '280' then 'MSN Direct'
        when cast(t.came_from as varchar) = '2800' then 'MSN Driven'
        when cast(t.came_from as varchar) = '283' then 'Shazam Direct'
        when cast(t.came_from as varchar) = '2830' then 'Shazam Driven'
        when cast(t.came_from as varchar) = '281' then 'Spotify Direct'
        when cast(t.came_from as varchar) = '2810' then 'Spotify Driven'
        when cast(t.came_from as varchar) = '289' then 'GOOGLE Direct'
        when cast(t.came_from as varchar) = '2890' then 'GOOGLE Driven'
        when cast(t.came_from as varchar) = '286' then 'YOUTUBE Direct'
        when cast(t.came_from as varchar) = '2860' then 'YOUTUBE Driven'
        when cast(t.came_from as varchar) = '285' then 'Amazon Direct'
        when cast(t.came_from as varchar) = '2850' then 'Amazon Driven'
        when cast(t.came_from as varchar) in ('269', '702') then 'Smart Link'
        when cast(t.came_from as varchar) = '704' then 'Release'
        when cast(t.came_from as varchar) = '712' then 'Presale'
        when c.source = 'email' then concat('Email ',
            case
                when cast(t.came_from as varchar) = '162' then 'Just Announced'
                when cast(t.came_from as varchar) = '292' then 'Last Chance Sold Out'
                when cast(t.came_from as varchar) = '291' then 'Low Inventory'
                when cast(t.came_from as varchar) = '163' then 'RSVP Reminder'
                when cast(t.came_from as varchar) = '290' then 'On Sale'
                when cast(t.came_from as varchar) = '316' then '7 Days Reminder'
                when cast(t.came_from as varchar) in ('380', '381', '382', '383', '384', '385') then 'Venue Premium'
                when cast(t.came_from as varchar) = '310' then 'Email Festival Premium - Just Announced'
                else 'Others'
            end
        )
        when c.source in ('twitter', 'tumblr') then 'Tumbler/Twitter'
        when c.source != 'NA' then c.source
        else 'Non Attributed'
    end as property,
    count(t.click_datetime) as nb
from {{ source('featured_events', 'ticketclicks') }} as t
left join {{ source('tableau_db', 'came_from') }} as c
    on cast(c.came_from as varchar) = cast(t.came_from as varchar)
group by
    cast(t.artist_event_int_id as varchar),
    substr(cast(t.ds as varchar), 1, 10),
    t.fe_source,
    json_extract_scalar(t.json, '$.utm_source'),
    t.ticket_seller_host,
    case
        when cast(t.came_from as varchar) in ('240', '237') then 'Email Post To Trackers or RSVPs'
        when cast(t.came_from as varchar) = '342' then 'Email Builder'
        when cast(t.came_from as varchar) = '248' then 'Email Artist with Widget'
        when cast(t.came_from as varchar) = '301' then 'Promoter Email'
        when cast(t.came_from as varchar) = '302' then 'Promoter Mobile Push'
        when cast(t.came_from as varchar) = '287' then 'Partner API'
        when cast(t.came_from as varchar) = '280' then 'MSN Direct'
        when cast(t.came_from as varchar) = '2800' then 'MSN Driven'
        when cast(t.came_from as varchar) = '283' then 'Shazam Direct'
        when cast(t.came_from as varchar) = '2830' then 'Shazam Driven'
        when cast(t.came_from as varchar) = '281' then 'Spotify Direct'
        when cast(t.came_from as varchar) = '2810' then 'Spotify Driven'
        when cast(t.came_from as varchar) = '289' then 'GOOGLE Direct'
        when cast(t.came_from as varchar) = '2890' then 'GOOGLE Driven'
        when cast(t.came_from as varchar) = '286' then 'YOUTUBE Direct'
        when cast(t.came_from as varchar) = '2860' then 'YOUTUBE Driven'
        when cast(t.came_from as varchar) = '285' then 'Amazon Direct'
        when cast(t.came_from as varchar) = '2850' then 'Amazon Driven'
        when cast(t.came_from as varchar) in ('269', '702') then 'Smart Link'
        when cast(t.came_from as varchar) = '704' then 'Release'
        when cast(t.came_from as varchar) = '712' then 'Presale'
        when c.source = 'email' then concat('Email ',
            case
                when cast(t.came_from as varchar) = '162' then 'Just Announced'
                when cast(t.came_from as varchar) = '292' then 'Last Chance Sold Out'
                when cast(t.came_from as varchar) = '291' then 'Low Inventory'
                when cast(t.came_from as varchar) = '163' then 'RSVP Reminder'
                when cast(t.came_from as varchar) = '290' then 'On Sale'
                when cast(t.came_from as varchar) = '316' then '7 Days Reminder'
                when cast(t.came_from as varchar) in ('380', '381', '382', '383', '384', '385') then 'Venue Premium'
                when cast(t.came_from as varchar) = '310' then 'Email Festival Premium - Just Announced'
                else 'Others'
            end
        )
        when c.source in ('twitter', 'tumblr') then 'Tumbler/Twitter'
        when c.source != 'NA' then c.source
        else 'Non Attributed'
    end

union all

select
    'Impressions' as source,
    substr(cast(p.ds as varchar), 1, 10) as date,
    null as category,
    p.fe_source as type,
    null as ticket_seller_host,
    p.source as sub_source,
    cast(p.artist_event_int_id as varchar) as artist_event_int_id,
    case
        when json_extract_scalar(p.json, '$.came_from_code') in ('240', '237') then 'Email Post To Trackers or RSVPs'
        when json_extract_scalar(p.json, '$.came_from_code') = '342' then 'Email Builder'
        when json_extract_scalar(p.json, '$.came_from_code') = '248' then 'Email Artist with Widget'
        when json_extract_scalar(p.json, '$.came_from_code') = '301' then 'Promoter Email'
        when json_extract_scalar(p.json, '$.came_from_code') = '302' then 'Promoter Mobile Push'
        when json_extract_scalar(p.json, '$.came_from_code') = '287' then 'Partner API'
        when json_extract_scalar(p.json, '$.came_from_code') = '280' then 'MSN Direct'
        when json_extract_scalar(p.json, '$.came_from_code') = '2800' then 'MSN Driven'
        when json_extract_scalar(p.json, '$.came_from_code') = '283' then 'Shazam Direct'
        when json_extract_scalar(p.json, '$.came_from_code') = '2830' then 'Shazam Driven'
        when json_extract_scalar(p.json, '$.came_from_code') = '281' then 'Spotify Direct'
        when json_extract_scalar(p.json, '$.came_from_code') = '2810' then 'Spotify Driven'
        when json_extract_scalar(p.json, '$.came_from_code') = '289' then 'GOOGLE Direct'
        when json_extract_scalar(p.json, '$.came_from_code') = '2890' then 'GOOGLE Driven'
        when json_extract_scalar(p.json, '$.came_from_code') = '286' then 'YOUTUBE Direct'
        when json_extract_scalar(p.json, '$.came_from_code') = '2860' then 'YOUTUBE Driven'
        when json_extract_scalar(p.json, '$.came_from_code') = '285' then 'Amazon Direct'
        when json_extract_scalar(p.json, '$.came_from_code') = '2850' then 'Amazon Driven'
        when json_extract_scalar(p.json, '$.came_from_code') in ('269', '702') then 'Smart Link'
        when json_extract_scalar(p.json, '$.came_from_code') = '704' then 'Release'
        when json_extract_scalar(p.json, '$.came_from_code') = '712' then 'Presale'
        when c.source = 'email' then concat('Email ',
            case
                when json_extract_scalar(p.json, '$.came_from_code') = '162' then 'Just Announced'
                when json_extract_scalar(p.json, '$.came_from_code') = '292' then 'Last Chance Sold Out'
                when json_extract_scalar(p.json, '$.came_from_code') = '291' then 'Low Inventory'
                when json_extract_scalar(p.json, '$.came_from_code') = '163' then 'RSVP Reminder'
                when json_extract_scalar(p.json, '$.came_from_code') = '290' then 'On Sale'
                when json_extract_scalar(p.json, '$.came_from_code') = '316' then '7 Days Reminder'
                when json_extract_scalar(p.json, '$.came_from_code') in ('380', '381', '382', '383', '384', '385') then 'Venue Premium'
                when json_extract_scalar(p.json, '$.came_from_code') = '310' then 'Email Festival Premium - Just Announced'
                else 'Others'
            end
        )
        when c.source in ('twitter', 'tumblr') then 'Tumbler/Twitter'
        when c.source != 'NA' then c.source
        else 'Non Attributed'
    end as property,
    count(p.nonce) as nb
from {{ source('featured_events', 'pixelactivities') }} as p
left join {{ source('tableau_db', 'came_from') }} as c
    on cast(c.came_from as varchar) = json_extract_scalar(p.json, '$.came_from_code')
group by
    substr(cast(p.ds as varchar), 1, 10),
    p.fe_source,
    p.source,
    cast(p.artist_event_int_id as varchar),
    case
        when json_extract_scalar(p.json, '$.came_from_code') in ('240', '237') then 'Email Post To Trackers or RSVPs'
        when json_extract_scalar(p.json, '$.came_from_code') = '342' then 'Email Builder'
        when json_extract_scalar(p.json, '$.came_from_code') = '248' then 'Email Artist with Widget'
        when json_extract_scalar(p.json, '$.came_from_code') = '301' then 'Promoter Email'
        when json_extract_scalar(p.json, '$.came_from_code') = '302' then 'Promoter Mobile Push'
        when json_extract_scalar(p.json, '$.came_from_code') = '287' then 'Partner API'
        when json_extract_scalar(p.json, '$.came_from_code') = '280' then 'MSN Direct'
        when json_extract_scalar(p.json, '$.came_from_code') = '2800' then 'MSN Driven'
        when json_extract_scalar(p.json, '$.came_from_code') = '283' then 'Shazam Direct'
        when json_extract_scalar(p.json, '$.came_from_code') = '2830' then 'Shazam Driven'
        when json_extract_scalar(p.json, '$.came_from_code') = '281' then 'Spotify Direct'
        when json_extract_scalar(p.json, '$.came_from_code') = '2810' then 'Spotify Driven'
        when json_extract_scalar(p.json, '$.came_from_code') = '289' then 'GOOGLE Direct'
        when json_extract_scalar(p.json, '$.came_from_code') = '2890' then 'GOOGLE Driven'
        when json_extract_scalar(p.json, '$.came_from_code') = '286' then 'YOUTUBE Direct'
        when json_extract_scalar(p.json, '$.came_from_code') = '2860' then 'YOUTUBE Driven'
        when json_extract_scalar(p.json, '$.came_from_code') = '285' then 'Amazon Direct'
        when json_extract_scalar(p.json, '$.came_from_code') = '2850' then 'Amazon Driven'
        when json_extract_scalar(p.json, '$.came_from_code') in ('269', '702') then 'Smart Link'
        when json_extract_scalar(p.json, '$.came_from_code') = '704' then 'Release'
        when json_extract_scalar(p.json, '$.came_from_code') = '712' then 'Presale'
        when c.source = 'email' then concat('Email ',
            case
                when json_extract_scalar(p.json, '$.came_from_code') = '162' then 'Just Announced'
                when json_extract_scalar(p.json, '$.came_from_code') = '292' then 'Last Chance Sold Out'
                when json_extract_scalar(p.json, '$.came_from_code') = '291' then 'Low Inventory'
                when json_extract_scalar(p.json, '$.came_from_code') = '163' then 'RSVP Reminder'
                when json_extract_scalar(p.json, '$.came_from_code') = '290' then 'On Sale'
                when json_extract_scalar(p.json, '$.came_from_code') = '316' then '7 Days Reminder'
                when json_extract_scalar(p.json, '$.came_from_code') in ('380', '381', '382', '383', '384', '385') then 'Venue Premium'
                when json_extract_scalar(p.json, '$.came_from_code') = '310' then 'Email Festival Premium - Just Announced'
                else 'Others'
            end
        )
        when c.source in ('twitter', 'tumblr') then 'Tumbler/Twitter'
        when c.source != 'NA' then c.source
        else 'Non Attributed'
    end

union all

select
    'Impressions' as source,
    substr(cast(p.ds as varchar), 1, 10) as date,
    null as category,
    e.fe_source as type,
    null as ticket_seller_host,
    p.source as sub_source,
    cast(p.artist_event_int_id as varchar) as artist_event_int_id,
    case
        when cast(p.came_from as varchar) in ('240', '237') then 'Email Post To Trackers or RSVPs'
        when cast(p.came_from as varchar) = '342' then 'Email Builder'
        when cast(p.came_from as varchar) = '248' then 'Email Artist with Widget'
        when cast(p.came_from as varchar) = '301' then 'Promoter Email'
        when cast(p.came_from as varchar) = '302' then 'Promoter Mobile Push'
        when cast(p.came_from as varchar) = '287' then 'Partner API'
        when cast(p.came_from as varchar) = '280' then 'MSN Direct'
        when cast(p.came_from as varchar) = '2800' then 'MSN Driven'
        when cast(p.came_from as varchar) = '283' then 'Shazam Direct'
        when cast(p.came_from as varchar) = '2830' then 'Shazam Driven'
        when cast(p.came_from as varchar) = '281' then 'Spotify Direct'
        when cast(p.came_from as varchar) = '2810' then 'Spotify Driven'
        when cast(p.came_from as varchar) = '289' then 'GOOGLE Direct'
        when cast(p.came_from as varchar) = '2890' then 'GOOGLE Driven'
        when cast(p.came_from as varchar) = '286' then 'YOUTUBE Direct'
        when cast(p.came_from as varchar) = '2860' then 'YOUTUBE Driven'
        when cast(p.came_from as varchar) = '285' then 'Amazon Direct'
        when cast(p.came_from as varchar) = '2850' then 'Amazon Driven'
        when cast(p.came_from as varchar) in ('269', '702') then 'Smart Link'
        when cast(p.came_from as varchar) = '704' then 'Release'
        when cast(p.came_from as varchar) = '712' then 'Presale'
        when c.source = 'email' then concat('Email ',
            case
                when cast(p.came_from as varchar) = '162' then 'Just Announced'
                when cast(p.came_from as varchar) = '292' then 'Last Chance Sold Out'
                when cast(p.came_from as varchar) = '291' then 'Low Inventory'
                when cast(p.came_from as varchar) = '163' then 'RSVP Reminder'
                when cast(p.came_from as varchar) = '290' then 'On Sale'
                when cast(p.came_from as varchar) = '316' then '7 Days Reminder'
                when cast(p.came_from as varchar) in ('380', '381', '382', '383', '384', '385') then 'Venue Premium'
                when cast(p.came_from as varchar) = '310' then 'Email Festival Premium - Just Announced'
                else 'Others'
            end
        )
        when c.source in ('twitter', 'tumblr') then 'Tumbler/Twitter'
        when c.source != 'NA' then c.source
        else 'Non Attributed'
    end as property,
    count(p.nonce) as nb
from impression_carousels as p
left join {{ source('tableau_db', 'came_from') }} as c
    on cast(c.came_from as varchar) = cast(p.came_from as varchar)
left join event_id_with_fe_source as e
    on p.artist_event_int_id = e.artist_event_int_id
group by
    substr(cast(p.ds as varchar), 1, 10),
    e.fe_source,
    p.source,
    cast(p.artist_event_int_id as varchar),
    case
        when cast(p.came_from as varchar) in ('240', '237') then 'Email Post To Trackers or RSVPs'
        when cast(p.came_from as varchar) = '342' then 'Email Builder'
        when cast(p.came_from as varchar) = '248' then 'Email Artist with Widget'
        when cast(p.came_from as varchar) = '301' then 'Promoter Email'
        when cast(p.came_from as varchar) = '302' then 'Promoter Mobile Push'
        when cast(p.came_from as varchar) = '287' then 'Partner API'
        when cast(p.came_from as varchar) = '280' then 'MSN Direct'
        when cast(p.came_from as varchar) = '2800' then 'MSN Driven'
        when cast(p.came_from as varchar) = '283' then 'Shazam Direct'
        when cast(p.came_from as varchar) = '2830' then 'Shazam Driven'
        when cast(p.came_from as varchar) = '281' then 'Spotify Direct'
        when cast(p.came_from as varchar) = '2810' then 'Spotify Driven'
        when cast(p.came_from as varchar) = '289' then 'GOOGLE Direct'
        when cast(p.came_from as varchar) = '2890' then 'GOOGLE Driven'
        when cast(p.came_from as varchar) = '286' then 'YOUTUBE Direct'
        when cast(p.came_from as varchar) = '2860' then 'YOUTUBE Driven'
        when cast(p.came_from as varchar) = '285' then 'Amazon Direct'
        when cast(p.came_from as varchar) = '2850' then 'Amazon Driven'
        when cast(p.came_from as varchar) in ('269', '702') then 'Smart Link'
        when cast(p.came_from as varchar) = '704' then 'Release'
        when cast(p.came_from as varchar) = '712' then 'Presale'
        when c.source = 'email' then concat('Email ',
            case
                when cast(p.came_from as varchar) = '162' then 'Just Announced'
                when cast(p.came_from as varchar) = '292' then 'Last Chance Sold Out'
                when cast(p.came_from as varchar) = '291' then 'Low Inventory'
                when cast(p.came_from as varchar) = '163' then 'RSVP Reminder'
                when cast(p.came_from as varchar) = '290' then 'On Sale'
                when cast(p.came_from as varchar) = '316' then '7 Days Reminder'
                when cast(p.came_from as varchar) in ('380', '381', '382', '383', '384', '385') then 'Venue Premium'
                when cast(p.came_from as varchar) = '310' then 'Email Festival Premium - Just Announced'
                else 'Others'
            end
        )
        when c.source in ('twitter', 'tumblr') then 'Tumbler/Twitter'
        when c.source != 'NA' then c.source
        else 'Non Attributed'
    end

