#!/bin/bash 
# A very simple Bash script to download a YouTube video 
# and extract the music file from it. 
address=$1 
regex='v=(.*)' 
if [[ $address =~ $regex ]]; then 
	video_id=${BASH_REMATCH[1]}
	video_id=$(echo $video_id | cut -d'&' -f1) 
	video_title="$(youtube-dl --get-title $address)" 
	youtube-dl --output "%(id)s.%(ext)s" $address 
	ext=$(ls $video_id.* |cut -f2 -d'.')
	ffmpeg -i $video_id.$ext "$video_title".wav 
	lame "$video_title".wav "$video_title".mp3 
	rm $video_id.$ext "$video_title".wav 
else 
	echo "Error... is this a youtube url?" 
fi
