create database spotify_db;
use spotify_db;

truncate table spotify_tracks;
create table spotify_tracks(
	id int auto_increment primary key,
    track_name varchar(255),
    album_name varchar(255),
    artists varchar(255),
    popularity int,
    duration_in_min decimal(10,2),
    release_date date
    );
    
select * from spotify_tracks;
drop table spotify_tracks;

# Data cleaning and standardization

set sql_safe_updates = 0;

update spotify_tracks
set album_name = trim(substring_index(substring_index(album_name, '[', 1), '(', 1));

set sql_safe_updates = 1;

# Top 10 popular tracks

	select * from (select dense_rank() over (order by popularity desc) as track_ranking, track_name, album_name, artists, popularity, duration_in_min from spotify_tracks) as ranked_tracks
	where track_ranking <= 10
	order by track_ranking, popularity desc;

# Top 5 movie albums with the highest popularity average of their tracks

	select album_name, avg(popularity) as average_popularity from spotify_tracks
	group by album_name
	order by average_popularity desc limit 5;

# Top track of albums released in 2025 by popularity

	select album_name, max(popularity) as max_popularity from spotify_tracks
	group by album_name
	order by max_popularity desc limit 1;

# Number of tracks per album

	select album_name, count(*) as total_tracks from spotify_tracks
	group by album_name
	order by total_tracks desc;

# Average duration of tracks per album

	select album_name, round(avg(duration_in_min),2) as average_duration from spotify_tracks
	group by album_name
	order by average_duration desc;

# ALbums with atleast one popular track

	select album_name, count(*) as hit_tracks
	from spotify_tracks
	where popularity >= 60                      # Considering popularity value above 60 as popular for this dataset
	group by album_name
	having count(*) > 1;

# Long tracks but popular

	select track_name, album_name, popularity, duration_in_min
	from spotify_tracks
	where popularity >= 60 and duration_in_min > 4
	order by popularity desc;

# Average popularity by duration range

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

# Popularity Distribution

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

# Top track of albums by popularity

	select track_name, album_name, artists, popularity, duration_in_min from
	(select
		track_name,
		album_name,
		artists,
		popularity,
		duration_in_min,
		row_number() over (partition by album_name order by popularity desc) as track_rank
		from spotify_tracks)
		as ranked_tracks
	where track_rank = 1
	order by popularity desc;
    
	



