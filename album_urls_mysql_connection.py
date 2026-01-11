import re
from mysql.connector import cursor
from spotipy.oauth2 import SpotifyClientCredentials
import spotipy
import pandas as pd
import os
import mysql.connector

# Spotify API credentials

sp = spotipy.Spotify(auth_manager=SpotifyClientCredentials(
    client_id='0c726fb585374b768838343e23dfb078', 
    client_secret='f49bf27631934f1789fd9dc279913bdb'))

# MySQL database connection
db_details = {
    "host" :"localhost",
    "user" :"root",
    "password" :"Jeeva@2003",
    "database" :"spotify_db"
}

# Connecting to the database
connection = mysql.connector.connect(**db_details)
cursor = connection.cursor()

# Reading multiple album urls from file

file_path = "album_urls.coffee"
with open(file_path, 'r') as file:
    album_urls = file.readlines()
# Processing each album url
for album_url in album_urls:
    album_url = album_url.strip()   
    try:

## Extract Album ID from URL using regex
        album_id = re.search(r'album/([a-zA-Z0-9]+)', album_url).group(1)

        # Fetch Album Information
        album_info = sp.album(album_id)

# Getting the metadata of the tracks in the album
        results = sp.album_tracks(album_id)
        items = results['items']

# collect all tracks so we can save them later
        all_tracks = []
        for idx, item in enumerate(items, start = 1):
            track_name = item['name']
            track_url = item['external_urls']['spotify']

    # Fetch full track object once to get popularity and release date
            full_track = sp.track(item['id'])

    # Extracting metadata of the tracks
            track_data = {
                'Track Name': item['name'],
                'Album Name': album_info['name'],
                'Artists': ', '.join([artist['name'] for artist in item['artists']]),
                'Popularity': full_track.get('popularity'),
                'Duration (min)': item['duration_ms'] / 60000,
                'Release Date': full_track.get('album', {}).get('release_date')
            }

            # Append to aggregate list
            all_tracks.append(track_data)

    # Inserting trackdata into MySQL database

            insert_query = """
                INSERT INTO spotify_tracks (track_name, album_name, artists, popularity, duration_in_min, release_date)
                VALUES (%s, %s, %s, %s, %s, %s)
            """
    
            cursor.execute(insert_query, (
                track_data['Track Name'],
                track_data['Album Name'],
                track_data['Artists'],
                track_data['Popularity'],
                track_data['Duration (min)'],
                track_data['Release Date']
            ))

            connection.commit()

            print(f" Track '{track_data['Track Name']}' from {track_data['Album Name']} inserted into database successfully.")



    except Exception as e:
        print(f"Error processing album URL {album_url}: {e}")

    # After processing all tracks for this album, append them to a CSV file
    try:
        csv_file = "spotify_album_tracks.csv"
        if all_tracks:
            df = pd.DataFrame(all_tracks)
            if not os.path.exists(csv_file):
                df.to_csv(csv_file, index=False, encoding='utf-8-sig')
            else:
                df.to_csv(csv_file, mode='a', index=False, header=False, encoding='utf-8-sig')
            print(f"Saved {len(all_tracks)} tracks from {album_info['name']} to {csv_file}")
    except Exception as e:
        print(f"Error saving CSV for album {album_url}: {e}")
# Closing the database connection
cursor.close()
connection.close()