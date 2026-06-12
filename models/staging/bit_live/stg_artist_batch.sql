{{
  config(
    materialized='view',
    tags=['bit_live', 'artists', 'staging']
  )
}}

select
    cast(id as integer) as artist_id,
    cast(name as varchar) as name,
    name_variations,
    cast(media_id as integer) as media_id,
    cast(upcoming_event_count as integer) as upcoming_event_count,
    cast(tracker_count as integer) as tracker_count,
    cast(verified as boolean) as verified,
    cast(tour_trailer_media_id as integer) as tour_trailer_media_id,
    cast(music_brainz_id as varchar) as music_brainz_id,
    cast(facebook_page_url as varchar) as facebook_page_url,
    cast(facebook_page_id as bigint) as facebook_page_id,
    cast(formation as varchar) as formation,
    cast(bio as varchar) as bio,
    cast(members as varchar) as members,
    cast(active_since as varchar) as active_since,
    cast(hometown as varchar) as hometown,
    genres,
    cast(links as varchar) as links,
    cast(created_at as varchar) as created_at,
    cast(updated_at as varchar) as updated_at,
    cast(disambig_flag as boolean) as disambig_flag,
    aliases,
    urls,
    cast(show_performers_on_tab as boolean) as show_performers_on_tab,
    cast(auto_publish_new_events as boolean) as auto_publish_new_events,
    cast(apple_play_whitelist as boolean) as apple_play_whitelist,
    cast(bt_ticketlink as boolean) as bt_ticketlink,
    cast(on_tour as boolean) as on_tour,
    cast(testing as boolean) as testing,
    cast(status as varchar) as status,
    relations,
    cast(custom_contents as varchar) as custom_contents,
    tracking,
    cast(artist_optin_show_phone_number as boolean) as artist_optin_show_phone_number,
    cast(show_multi_ticket as boolean) as show_multi_ticket,
    cast(label_id as integer) as label_id,
    cast(label_name as varchar) as label_name,
    cast(label_optin as integer) as label_optin,
    cast(label_parent_id as integer) as label_parent_id,
    cast(label_parent_name as varchar) as label_parent_name,
    cast(is_managed as boolean) as is_managed,
    cast(is_premium as boolean) as is_premium
from {{ source('bit_live', 'artist_batch') }}

