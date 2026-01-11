create database spotify_db;
use spotify_db;

select * from spotify_tracks;
drop table if exists spotify_tracks;
create table spotify_tracks(
	track_id int auto_increment primary key,
    track_name varchar(255),
    album_name varchar(255),
    artists varchar(255),
    popularity int,
    duration_in_min decimal(10,2),
    release_date date,
    unique(track_name)
    );

-- The MySQL Query upto this should be executed before the python code execution

# Data cleaning and standardization

	set sql_safe_updates = 0;

    ## Deleting the duplicate records from the dataset
    delete t from spotify_tracks t
    join
    (
	select album_name, track_name from spotify_tracks
    group by album_name, track_name
    having count(*) > 1
    ) as d
    on t.album_name = d.album_name and
    t.track_name = d.track_name;

# 
update spotify_tracks
set album_name = trim(substring_index(substring_index(album_name, '[', 1), '(', 1));

# Separating the artists column into music composer and singers using the comma delimiter
	alter table spotify_tracks add music_composer varchar(255);
	alter table spotify_tracks add singers varchar(255);
	update spotify_tracks
	set music_composer = trim(substring_index(artists, ',', 1));
	update spotify_tracks
	set singers = trim(substring(artists , locate(',',artists) +1));

	set sql_safe_updates = 1;

    

## 1. Top 5 popular tracks

		select * from (select dense_rank() over (order by popularity desc) as track_ranking, track_name, album_name, music_composer, singers, popularity, duration_in_min from spotify_tracks) as ranked_tracks
		where track_ranking <= 5
		order by track_ranking, popularity desc;

## 2. Top 5 movie albums with the highest popularity average of their tracks

		select album_name, avg(popularity) as average_popularity from spotify_tracks
		group by album_name
		order by average_popularity desc limit 5;


## 3. Number of tracks per album

		select album_name, count(*) as total_tracks from spotify_tracks
		group by album_name
		order by total_tracks desc;

## 4. Average duration of tracks per album

		select album_name, round(avg(duration_in_min),2) as average_duration from spotify_tracks
		group by album_name
		order by average_duration desc;

## 5. ALbums with atleast one popular track

		select album_name, count(*) as hit_tracks
		from spotify_tracks
		where popularity >= 60                                 # Considering popularity value above 60 as popular for this dataset
		group by album_name
		having count(*) > 1
		order by hit_tracks desc;

## 6. Long tracks but popular

	select track_name, album_name, popularity, duration_in_min
	from spotify_tracks
	where popularity >= 60 and duration_in_min > 4
	order by popularity desc;

## 7. Average popularity by duration range

		select
			case
				when duration_in_min < 3 then '0 - 3 mins'
				when duration_in_min < 6 then '3 - 6 mins'
				else 'Greater than 6 mins'
			end as duration_range,
			avg(popularity) as average_popularity,
			count(*) as track_count
			from spotify_tracks
		group by duration_range
		order by average_popularity desc;

## 8. Popularity Distribution

	select
		case
			when popularity >= 60 then 'Very Popular'
			when popularity >= 40 then 'Popular'
			else 'Less Popular'
		end as popularity_range,
		count(*) as track_count
	from spotify_tracks
	group by popularity_range
	order by popularity_range desc;

## 9. Top track of albums by popularity

	select album_name, track_name, music_composer, singers, popularity, duration_in_min from
	(select
		track_name,
		album_name,
		music_composer,
        singers,
		popularity,
		duration_in_min,
		dense_rank() over (partition by album_name order by popularity desc) as track_rank
		from spotify_tracks)
		as ranked_tracks
	where track_rank = 1
	order by popularity desc, album_name;
    
## 10. Composers with the most number of albums and tracks in 2025

	select music_composer, count(distinct album_name) as album_count, count(track_name) as track_count from spotify_tracks
    group by music_composer
    order by album_count desc, track_count desc
    limit 10;
    
## 11. Composers with the highest popularity in 2025

	select music_composer, avg(popularity) as avg_popularity from spotify_tracks
	where album_name in (
	select album_name from spotify_tracks
	group by album_name
	having count(distinct music_composer) = 1
	)
	group by music_composer
	order by avg_popularity desc limit 5;
    
## 12. Early and Late year comparison
	
    select case
		when month(release_date) <=6 then 'January - June'
        else 'July - December'
        end as year_split,
	count(distinct album_name) as album_count,
    count(track_name) as track_count,
    avg(popularity) as avg_popularity
    from spotify_tracks
    group by year_split
    order by avg_popularity;
    

    
    

    
	



