WITH email_impressions_snapshot as (
SELECT
e.ds as date,
e.sg_message_id,
fe_id as artist_event_int_id,
category
FROM featured_events.email_real_opens as e
CROSS JOIN UNNEST(e.featured_events_ids) AS t(fe_id)
),

impression_carousels as (
SELECT  ds, nonce, source, fe_id as artist_event_int_id, came_from
FROM featured_events.pixel_impressions_v2 as p
CROSS JOIN UNNEST(p.featured_event_ids) AS t(fe_id)
),


fe_source_by_event as (
SELECT
artist_event_int_id, count(distinct fe_source) as nb
FROM
(
SELECT distinct artist_event_int_id, fe_source
FROM featured_events.all_time_featured_events_list
UNION
SELECT
distinct
artist_event_int_id, fe_source
FROM featured_events.ticketclicks
)
GROUP BY
artist_event_int_id
),

unique_featured_events_list as (
SELECT a.artist_event_int_id, a.fe_source
FROM fe_source_by_event as f
JOIN featured_events.all_time_featured_events_list as a on a.artist_event_int_id = f.artist_event_int_id
WHERE nb = 2
AND subscription_starts_at is NOT  NULL
AND subscription_ends_at is NOT NULL

UNION

SELECT a.*
FROM fe_source_by_event as f
JOIN (
SELECT distinct artist_event_int_id, fe_source
FROM featured_events.all_time_featured_events_list
UNION
SELECT
distinct
artist_event_int_id, fe_source
FROM featured_events.ticketclicks
) as a on a.artist_event_int_id = f.artist_event_int_id
WHERE nb = 1
),


event_id_with_fe_souce as (
SELECT
artist_event_int_id, min(fe_source) fe_source
FROM unique_featured_events_list
GROUP BY artist_event_int_id
),

kpis_by_day as (
SELECT
'Impressions' as source,
date,
category,
es.fe_source as type,
NULL as ticket_seller_host,
'Email' as sub_source,
e.artist_event_int_id,
'Email ' || category as property,
--sg_machine_open,
count(sg_message_id) as nb
FROM email_impressions_snapshot as e
LEFT JOIN event_id_with_fe_souce as es on cast(es.artist_event_int_id as varchar) = e.artist_event_int_id
--WHERE sg_machine_open = 'false'
GROUP BY
category,
es.fe_source,
e.artist_event_int_id,
'Email ' || category,
--sg_machine_open,
date

UNION ALL


SELECT
'TicketClicks' as source,
substr(cast(ds as varchar),1,10) as date,
NULL category,
t.fe_source as type,
ticket_seller_host,
json_extract_scalar(t.json, '$.utm_source') AS sub_source,
cast(artist_event_int_id as varchar) as artist_event_int_id,
CASE
WHEN cast(t.came_from as varchar)  = '240' OR cast(t.came_from as varchar)  = '237' THEN 'Email Post To Trackers or RSVPs'
WHEN cast(t.came_from as varchar) = '342' THEN 'Email Builder'
WHEN cast(t.came_from as varchar) = '248' THEN 'Email Artist with Widget'
WHEN cast(t.came_from as varchar) = '301' THEN 'Promoter Email'
WHEN cast(t.came_from as varchar) = '302' THEN 'Promoter Mobile Push'
WHEN cast(t.came_from as varchar) = '287' THEN 'Partner API'
WHEN cast(t.came_from as varchar) = '280' THEN 'MSN Direct'
WHEN cast(t.came_from as varchar) = '2800' THEN 'MSN Driven'
WHEN cast(t.came_from as varchar) = '283' THEN 'Shazam Direct'
WHEN cast(t.came_from as varchar) = '2830' THEN 'Shazam Driven'
WHEN cast(t.came_from as varchar) = '281' THEN 'Spotify Direct'
WHEN cast(t.came_from as varchar) = '2810' THEN 'Spotify Driven'
WHEN cast(t.came_from as varchar) = '289' THEN 'GOOGLE Direct'
WHEN cast(t.came_from as varchar) = '2890' THEN 'GOOGLE Driven'
WHEN cast(t.came_from as varchar) = '286' THEN 'YOUTUBE Direct'
WHEN cast(t.came_from as varchar) = '2860' THEN 'YOUTUBE Driven'
WHEN cast(t.came_from as varchar) = '285' THEN 'Amazon Direct'
WHEN cast(t.came_from as varchar) = '2850' THEN 'Amazon Driven'
WHEN cast(t.came_from as varchar) = '269' OR cast(t.came_from as varchar) = '702' THEN 'Smart Link'
WHEN cast(t.came_from as varchar) = '704' THEN 'Release'
WHEN cast(t.came_from as varchar) = '712' THEN 'Presale'
WHEN c.source = 'email' THEN concat('Email ',
 CASE
 WHEN cast(t.came_from as varchar) = '162' THEN 'Just Announced'
 WHEN cast(t.came_from as varchar) = '292' THEN 'Last Chance Sold Out'
 WHEN cast(t.came_from as varchar) = '291' THEN 'Low Inventory'
 WHEN cast(t.came_from as varchar) = '163' THEN 'RSVP Reminder'
 WHEN cast(t.came_from as varchar) = '290' THEN 'On Sale'
 WHEN cast(t.came_from as varchar) = '316' THEN '7 Days Reminder'
 WHEN cast(t.came_from as varchar) in ('380', '381', '382', '383', '384', '385') THEN 'Venue Premium'
 WHEN cast(t.came_from as varchar) = '310' THEN 'Email Festival Premium - Just Announced'
 ELSE 'Others'
END)
WHEN c.source = 'twitter' or c.source = 'tumblr' THEN 'Tumbler/Twitter'
WHEN c.source != 'NA' THEN c.source
ELSE 'Non Attributed'
END  AS property,
count(click_datetime) as nb
FROM featured_events.ticketclicks as t
LEFT JOIN tableau_db.came_from as c on cast(c.came_from as varchar) = cast(t.came_from as varchar)
GROUP BY
cast(artist_event_int_id as varchar),
substr(cast(ds as varchar),1,10),
t.fe_source,
json_extract_scalar(t.json, '$.utm_source'),
ticket_seller_host,
CASE
WHEN cast(t.came_from as varchar)  = '240' OR cast(t.came_from as varchar)  = '237' THEN 'Email Post To Trackers or RSVPs'
WHEN cast(t.came_from as varchar) = '342' THEN 'Email Builder'
WHEN cast(t.came_from as varchar) = '248' THEN 'Email Artist with Widget'
WHEN cast(t.came_from as varchar) = '301' THEN 'Promoter Email'
WHEN cast(t.came_from as varchar) = '302' THEN 'Promoter Mobile Push'
WHEN cast(t.came_from as varchar) = '287' THEN 'Partner API'
WHEN cast(t.came_from as varchar) = '280' THEN 'MSN Direct'
WHEN cast(t.came_from as varchar) = '2800' THEN 'MSN Driven'
WHEN cast(t.came_from as varchar) = '283' THEN 'Shazam Direct'
WHEN cast(t.came_from as varchar) = '2830' THEN 'Shazam Driven'
WHEN cast(t.came_from as varchar) = '281' THEN 'Spotify Direct'
WHEN cast(t.came_from as varchar) = '2810' THEN 'Spotify Driven'
WHEN cast(t.came_from as varchar) = '289' THEN 'GOOGLE Direct'
WHEN cast(t.came_from as varchar) = '2890' THEN 'GOOGLE Driven'
WHEN cast(t.came_from as varchar) = '286' THEN 'YOUTUBE Direct'
WHEN cast(t.came_from as varchar) = '2860' THEN 'YOUTUBE Driven'
WHEN cast(t.came_from as varchar) = '285' THEN 'Amazon Direct'
WHEN cast(t.came_from as varchar) = '2850' THEN 'Amazon Driven'
WHEN cast(t.came_from as varchar) = '269' OR cast(t.came_from as varchar) = '702' THEN 'Smart Link'
WHEN cast(t.came_from as varchar) = '704' THEN 'Release'
WHEN cast(t.came_from as varchar) = '712' THEN 'Presale'
WHEN c.source = 'email' THEN concat('Email ',
 CASE
 WHEN cast(t.came_from as varchar) = '162' THEN 'Just Announced'
 WHEN cast(t.came_from as varchar) = '292' THEN 'Last Chance Sold Out'
 WHEN cast(t.came_from as varchar) = '291' THEN 'Low Inventory'
 WHEN cast(t.came_from as varchar) = '163' THEN 'RSVP Reminder'
 WHEN cast(t.came_from as varchar) = '290' THEN 'On Sale'
 WHEN cast(t.came_from as varchar) = '316' THEN '7 Days Reminder'
 WHEN cast(t.came_from as varchar) in ('380', '381', '382', '383', '384', '385') THEN 'Venue Premium'
 WHEN cast(t.came_from as varchar) = '310' THEN 'Email Festival Premium - Just Announced'
 ELSE 'Others'
END)
WHEN c.source = 'twitter' or c.source = 'tumblr' THEN 'Tumbler/Twitter'
WHEN c.source != 'NA' THEN c.source
ELSE 'Non Attributed'
END

UNION ALL


SELECT
'Impressions' as source,
substr(cast(p.ds as varchar),1,10) as date,
NULL as category,
p.fe_source as type,
NULL ticket_seller_host,
p.source as sub_source,
cast(p.artist_event_int_id as varchar) as artist_event_int_id,
CASE
WHEN json_extract_scalar(p.json, '$.came_from_code')  = '240' OR json_extract_scalar(p.json, '$.came_from_code')  = '237' THEN 'Email Post To Trackers or RSVPs'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '342' THEN 'Email Builder'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '248' THEN 'Email Artist with Widget'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '301' THEN 'Promoter Email'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '302' THEN 'Promoter Mobile Push'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '287' THEN 'Partner API'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '280' THEN 'MSN Direct'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '2800' THEN 'MSN Driven'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '283' THEN 'Shazam Direct'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '2830' THEN 'Shazam Driven'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '281' THEN 'Spotify Direct'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '2810' THEN 'Spotify Driven'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '289' THEN 'GOOGLE Direct'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '2890' THEN 'GOOGLE Driven'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '286' THEN 'YOUTUBE Direct'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '2860' THEN 'YOUTUBE Driven'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '285' THEN 'Amazon Direct'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '2850' THEN 'Amazon Driven'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '269' OR json_extract_scalar(p.json, '$.came_from_code') = '702' THEN 'Smart Link'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '704' THEN 'Release'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '712' THEN 'Presale'
WHEN c.source = 'email' THEN concat('Email ',
 CASE
 WHEN json_extract_scalar(p.json, '$.came_from_code') = '162' THEN 'Just Announced'
 WHEN json_extract_scalar(p.json, '$.came_from_code') = '292' THEN 'Last Chance Sold Out'
 WHEN json_extract_scalar(p.json, '$.came_from_code') = '291' THEN 'Low Inventory'
 WHEN json_extract_scalar(p.json, '$.came_from_code') = '163' THEN 'RSVP Reminder'
 WHEN json_extract_scalar(p.json, '$.came_from_code') = '290' THEN 'On Sale'
 WHEN json_extract_scalar(p.json, '$.came_from_code') = '316' THEN '7 Days Reminder'
 WHEN json_extract_scalar(p.json, '$.came_from_code') in ('380', '381', '382', '383', '384', '385') THEN 'Venue Premium'
 WHEN json_extract_scalar(p.json, '$.came_from_code') = '310' THEN 'Email Festival Premium - Just Announced'
 ELSE 'Others'
END)
WHEN c.source = 'twitter' or c.source = 'tumblr' THEN 'Tumbler/Twitter'
WHEN c.source != 'NA' THEN c.source
ELSE 'Non Attributed'
END AS property,
count(nonce) as nb
FROM featured_events.pixelactivities as p
LEFT JOIN tableau_db.came_from as c on cast(c.came_from as varchar) = json_extract_scalar(p.json, '$.came_from_code')
GROUP BY
substr(cast(p.ds as varchar),1,10),
p.fe_source,
p.source,
cast(p.artist_event_int_id as varchar),
CASE
WHEN json_extract_scalar(p.json, '$.came_from_code')  = '240' OR json_extract_scalar(p.json, '$.came_from_code')  = '237' THEN 'Email Post To Trackers or RSVPs'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '342' THEN 'Email Builder'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '248' THEN 'Email Artist with Widget'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '301' THEN 'Promoter Email'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '302' THEN 'Promoter Mobile Push'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '287' THEN 'Partner API'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '280' THEN 'MSN Direct'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '2800' THEN 'MSN Driven'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '283' THEN 'Shazam Direct'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '2830' THEN 'Shazam Driven'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '281' THEN 'Spotify Direct'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '2810' THEN 'Spotify Driven'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '289' THEN 'GOOGLE Direct'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '2890' THEN 'GOOGLE Driven'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '286' THEN 'YOUTUBE Direct'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '2860' THEN 'YOUTUBE Driven'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '285' THEN 'Amazon Direct'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '2850' THEN 'Amazon Driven'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '269' OR json_extract_scalar(p.json, '$.came_from_code') = '702' THEN 'Smart Link'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '704' THEN 'Release'
WHEN json_extract_scalar(p.json, '$.came_from_code') = '712' THEN 'Presale'
WHEN c.source = 'email' THEN concat('Email ',
 CASE
 WHEN json_extract_scalar(p.json, '$.came_from_code') = '162' THEN 'Just Announced'
 WHEN json_extract_scalar(p.json, '$.came_from_code') = '292' THEN 'Last Chance Sold Out'
 WHEN json_extract_scalar(p.json, '$.came_from_code') = '291' THEN 'Low Inventory'
 WHEN json_extract_scalar(p.json, '$.came_from_code') = '163' THEN 'RSVP Reminder'
 WHEN json_extract_scalar(p.json, '$.came_from_code') = '290' THEN 'On Sale'
 WHEN json_extract_scalar(p.json, '$.came_from_code') = '316' THEN '7 Days Reminder'
 WHEN json_extract_scalar(p.json, '$.came_from_code') in ('380', '381', '382', '383', '384', '385') THEN 'Venue Premium'
 WHEN json_extract_scalar(p.json, '$.came_from_code') = '310' THEN 'Email Festival Premium - Just Announced'
 ELSE 'Others'
END)
WHEN c.source = 'twitter' or c.source = 'tumblr' THEN 'Tumbler/Twitter'
WHEN c.source != 'NA' THEN c.source
ELSE 'Non Attributed'
END

UNION ALL


SELECT
'Impressions' as source,
substr(cast(p.ds as varchar),1,10) as date,
NULL as category,
e.fe_source as type,
NULL ticket_seller_host,
p.source as sub_source,
cast(p.artist_event_int_id as varchar) as artist_event_int_id,
CASE
WHEN cast(p.came_from as varchar)  = '240' OR cast(p.came_from as varchar)  = '237' THEN 'Email Post To Trackers or RSVPs'
WHEN cast(p.came_from as varchar) = '342' THEN 'Email Builder'
WHEN cast(p.came_from as varchar) = '248' THEN 'Email Artist with Widget'
WHEN cast(p.came_from as varchar) = '301' THEN 'Promoter Email'
WHEN cast(p.came_from as varchar) = '302' THEN 'Promoter Mobile Push'
WHEN cast(p.came_from as varchar) = '287' THEN 'Partner API'
WHEN cast(p.came_from as varchar) = '280' THEN 'MSN Direct'
WHEN cast(p.came_from as varchar) = '2800' THEN 'MSN Driven'
WHEN cast(p.came_from as varchar) = '283' THEN 'Shazam Direct'
WHEN cast(p.came_from as varchar) = '2830' THEN 'Shazam Driven'
WHEN cast(p.came_from as varchar) = '281' THEN 'Spotify Direct'
WHEN cast(p.came_from as varchar) = '2810' THEN 'Spotify Driven'
WHEN cast(p.came_from as varchar) = '289' THEN 'GOOGLE Direct'
WHEN cast(p.came_from as varchar) = '2890' THEN 'GOOGLE Driven'
WHEN cast(p.came_from as varchar) = '286' THEN 'YOUTUBE Direct'
WHEN cast(p.came_from as varchar) = '2860' THEN 'YOUTUBE Driven'
WHEN cast(p.came_from as varchar) = '285' THEN 'Amazon Direct'
WHEN cast(p.came_from as varchar) = '2850' THEN 'Amazon Driven'
WHEN cast(p.came_from as varchar) = '269' OR cast(p.came_from as varchar) = '702' THEN 'Smart Link'
WHEN cast(p.came_from as varchar) = '704' THEN 'Release'
WHEN cast(p.came_from as varchar) = '712' THEN 'Presale'
WHEN c.source = 'email' THEN concat('Email ',
 CASE
 WHEN cast(p.came_from as varchar) = '162' THEN 'Just Announced'
 WHEN cast(p.came_from as varchar) = '292' THEN 'Last Chance Sold Out'
 WHEN cast(p.came_from as varchar) = '291' THEN 'Low Inventory'
 WHEN cast(p.came_from as varchar) = '163' THEN 'RSVP Reminder'
 WHEN cast(p.came_from as varchar) = '290' THEN 'On Sale'
 WHEN cast(p.came_from as varchar) = '316' THEN '7 Days Reminder'
 WHEN cast(p.came_from as varchar) in ('380', '381', '382', '383', '384', '385') THEN 'Venue Premium'
 WHEN cast(p.came_from as varchar) = '310' THEN 'Email Festival Premium - Just Announced'
 ELSE 'Others'
END)
WHEN c.source = 'twitter' or c.source = 'tumblr' THEN 'Tumbler/Twitter'
WHEN c.source != 'NA' THEN c.source
ELSE 'Non Attributed'
END AS property,
count(nonce) as nb
FROM impression_carousels as p
LEFT JOIN tableau_db.came_from as c on cast(c.came_from as varchar) = cast(p.came_from as varchar)
LEFT JOIN event_id_with_fe_souce as e on p.artist_event_int_id = e.artist_event_int_id
GROUP BY
substr(cast(p.ds as varchar),1,10),
e.fe_source,
p.source,
cast(p.artist_event_int_id as varchar),
CASE
WHEN cast(p.came_from as varchar)  = '240' OR cast(p.came_from as varchar)  = '237' THEN 'Email Post To Trackers or RSVPs'
WHEN cast(p.came_from as varchar) = '342' THEN 'Email Builder'
WHEN cast(p.came_from as varchar) = '248' THEN 'Email Artist with Widget'
WHEN cast(p.came_from as varchar) = '301' THEN 'Promoter Email'
WHEN cast(p.came_from as varchar) = '302' THEN 'Promoter Mobile Push'
WHEN cast(p.came_from as varchar) = '287' THEN 'Partner API'
WHEN cast(p.came_from as varchar) = '280' THEN 'MSN Direct'
WHEN cast(p.came_from as varchar) = '2800' THEN 'MSN Driven'
WHEN cast(p.came_from as varchar) = '283' THEN 'Shazam Direct'
WHEN cast(p.came_from as varchar) = '2830' THEN 'Shazam Driven'
WHEN cast(p.came_from as varchar) = '281' THEN 'Spotify Direct'
WHEN cast(p.came_from as varchar) = '2810' THEN 'Spotify Driven'
WHEN cast(p.came_from as varchar) = '289' THEN 'GOOGLE Direct'
WHEN cast(p.came_from as varchar) = '2890' THEN 'GOOGLE Driven'
WHEN cast(p.came_from as varchar) = '286' THEN 'YOUTUBE Direct'
WHEN cast(p.came_from as varchar) = '2860' THEN 'YOUTUBE Driven'
WHEN cast(p.came_from as varchar) = '285' THEN 'Amazon Direct'
WHEN cast(p.came_from as varchar) = '2850' THEN 'Amazon Driven'
WHEN cast(p.came_from as varchar) = '269' OR cast(p.came_from as varchar) = '702' THEN 'Smart Link'
WHEN cast(p.came_from as varchar) = '704' THEN 'Release'
WHEN cast(p.came_from as varchar) = '712' THEN 'Presale'
WHEN c.source = 'email' THEN concat('Email ',
 CASE
 WHEN cast(p.came_from as varchar) = '162' THEN 'Just Announced'
 WHEN cast(p.came_from as varchar) = '292' THEN 'Last Chance Sold Out'
 WHEN cast(p.came_from as varchar) = '291' THEN 'Low Inventory'
 WHEN cast(p.came_from as varchar) = '163' THEN 'RSVP Reminder'
 WHEN cast(p.came_from as varchar) = '290' THEN 'On Sale'
 WHEN cast(p.came_from as varchar) = '316' THEN '7 Days Reminder'
 WHEN cast(p.came_from as varchar) in ('380', '381', '382', '383', '384', '385') THEN 'Venue Premium'
 WHEN cast(p.came_from as varchar) = '310' THEN 'Email Festival Premium - Just Announced'
 ELSE 'Others'
END)
WHEN c.source = 'twitter' or c.source = 'tumblr' THEN 'Tumbler/Twitter'
WHEN c.source != 'NA' THEN c.source
ELSE 'Non Attributed'
END

),

evl as (
SELECT distinct
artist_event_int_id,
artist.id as artist_id,
artist.name as artist_name,
venue.id as venue_id,
venue.name as venue_name,
venue.country as venue_country,
date_info.event_date
FROM tableau_db.daily_snapshot_events_parquet AS e
WHERE lower(e.status) IN ('published','autopublished')
),

events_tag as (
SELECT
artist_event_int_id,
tag
FROM tableau_db.daily_snapshot_events_parquet as e
CROSS JOIN unnest(tags) as t(tag)
WHERE actor='artist'
AND status in ('PUBLISHED','AUTOPUBLISHED')
AND artist.id is not null
AND artist.id !='-1'
),

events_of_festival_premium as (
SELECT
artist_event_int_id,
festival_name,
festival_edition_id
FROM (
SELECT
distinct
et.artist_event_int_id,
t.festival_name,
t.festival_edition_id
FROM events_tag as et
JOIN (SELECT
festival_name,
tag, id as festival_edition_id from tableau_db.festival_editions as f
        WHERE (status is null or status not in ( 'CANCELLED', 'DELETED'))
	) as t on et.tag=t.tag
) as a
),


venues_managed as (
SELECT
distinct venue_id
FROM tableau_db.venue_admin_parquet
WHERE status_manager=1
AND status_relation=1
AND status_managed_actor=1
),

venues_dataset as
(
SELECT
distinct id as venue_id,
capacity,
verified,
IF(vs.venue_id is null, 'not premium venue', 'premium venue') as premium_flag,
IF(vm.venue_id is null, 'not managed venue', 'managed venue') as managed_flag,
type as venue_type
FROM tableau_db.daily_snapshot_venues_parquet as av
LEFT JOIN (SELECT distinct venue_id FROM bit_venues.venue_subscriptions WHERE is_subscription_active =1) as vs on cast (vs.venue_id as varchar) = av.id
LEFT JOIN venues_managed as vm on vm.venue_id = av.id
WHERE av.address_is_primary = 1
AND av.name_is_primary=1
),

campaign_events as (
SELECT distinct de.bit_event_id as event_id
FROM promoter.email_campaign c
JOIN promoter.email_campaign_details de ON de.email_campaign_id = c.id
WHERE c.came_from = 'BIT4A'
AND de.bit_event_id <> 0
AND c.created_by_Admin = 0
),

package_with_event_info as (
SELECT
DISTINCT
e.event_id
FROM featured_artist_events.packages as p
LEFT JOIN featured_artist_events.events as e on e.package_id = p.id
WHERE p.deleted = 0
AND e.deleted = 0
AND p.status != 'cancelled'
AND e.status != 'pending'
AND p.price is not NULL
),

bit4a_event as (
--SELECT event_id FROM campaign_events
--UNION
SELECT event_id FROM package_with_event_info
)


SELECT i.*,
evl.artist_id,
evl.artist_name,
al.tracker_count,
evl.venue_id,
evl.venue_name,
evl.venue_country,
v.capacity,
v.premium_flag,
v.managed_flag,
evl.event_date,
ef.festival_name,
ef.festival_edition_id,
IF(b.event_id is NULL, 'OTHER SOURCE', 'BIT4A') purchase_source
FROM kpis_by_day as i
JOIN evl on cast(evl.artist_event_int_id as varchar) = i.artist_event_int_id
LEFT JOIN events_of_festival_premium as ef on cast(ef.artist_event_int_id as varchar)= i.artist_event_int_id
LEFT JOIN tableau_db.artist_list_parquet as al on cast(al.artist_id as varchar) = evl.artist_id
LEFT JOIN venues_dataset as v on v.venue_id = evl.venue_id
LEFT JOIN bit4a_event as b on cast(b.event_id as varchar) = i.artist_event_int_id

