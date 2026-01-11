# [ Python is used to interact with the Spotify API and extract music data in an automated way. 
  The Spotify client is initialized in Python, after which album URLs are used to retrieve album IDs.
  Using these IDs, detailed album information is collected, and individual track details are extracted from each album.
  All track-level data is then loaded into a Pandas DataFrame for easy handling and analysis. 
  Finally, the popularity of tracks is visualized using Matplotlib, helping to compare and understand trends in track popularity across different albums. 
  This Python-based approach enables efficient data collection, structured analysis, and clear visual representation of Spotify music data.]

from spotipy.oauth2 import SpotifyClientCredentials
import spotipy
import pandas as pd
import re
import math
import matplotlib.pyplot as plt
import os


# Setting up Client Credentials

## Initialize Spotify client
sp = spotipy.Spotify(auth_manager=SpotifyClientCredentials(
    client_id='0c726fb585374b768838343e23dfb078', 
    client_secret='f49bf27631934f1789fd9dc279913bdb'))

file_path = "album_urls.coffee"
with open(file_path, 'r') as file:
    album_urls = file.readlines()
# Processing each album url
for album_url in album_urls:
    album_url = album_url.strip() 

## Extract Album ID from URL using regex
    album_id = re.search(r'album/([a-zA-Z0-9]+)', album_url).group(1)

# Fetch Album Information
    album_info = sp.album(album_id)
    print(album_info)

# Getting the metadata of the tracks in the album
    results = sp.album_tracks(album_id)
    items = results['items']

# collect all tracks so we can save them later
    all_tracks = []
    for idx, item in enumerate(items, start = 1):
        track_name = item['name']
        track_url = item['external_urls']['spotify']
        print(f"{idx}. {item['name']} - {item['external_urls']['spotify']}")

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

        all_tracks.append(track_data)

    # Display Track Metadata
        print(f"\nTrack Name: {track_data['Track Name']}")
        print(f"Album Name: {track_data['Album Name']}")
        print(f"Artists: {track_data['Artists']}")
        print(f"Popularity: {track_data['Popularity']}")
        print(f"Duration (min): {track_data['Duration (min)']:.2f}")
        print(f"Release Date: {track_data['Release Date']}\n")
    # store values for later plotting in a grid

# After collecting all tracks, build DataFrame and save CSV
        df = pd.DataFrame(all_tracks)
        print("Track Metadata DataFrame:")
        print(df)

# Plot popularity of all tracks in a single bar chart
    n = len(all_tracks)
    if n > 0:
        track_names = [item['Track Name'] for item in all_tracks]
        popularities = [item['Popularity'] if item['Popularity'] is not None else 0 for item in all_tracks]

        plt.figure(figsize=(15, 7))
        plt.xticks(rotation=45, ha='right')
        plt.xticks(range(n), track_names, ha='center')
        plt.subplots_adjust(bottom=0.3)
        bars = plt.bar(range(n), popularities, color='orange', edgecolor='black')
        plt.xlabel('Track')
        plt.ylabel('Popularity')
        plt.ylim(0, 100)
        plt.title(f"Popularity of tracks in '{album_info.get('name', '')}'")

    # annotate bars with popularity values
        for bar, val in zip(bars, popularities):
            height = bar.get_height()
            plt.text(bar.get_x() + bar.get_width() / 2, height + 1, f"{int(val)}", ha='center', va='bottom', fontsize=10)

        plt.tight_layout()
        plt.show()

# (CSV already saved before showing the plot)



