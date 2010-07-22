#!/bin/bash
#hdvideo2ipod.sh Converts h264 DVB-T recordings from to an iPod friendly format

#get video format info
VideoFormat=`nice -n 15 ffmpeg -i "$1" 2>&1 | grep Stream`

#report details to console
echo "Input Filename: $1"
echo "$VideoFormat"

#check for compatible audio
if `echo ${VideoFormat} | grep "Audio: mp2" 1>/dev/null 2>&1`
then
  #ok audio is compatible, able to use original file
  VideoFilename="$1"
else
  #incompatible latm audio use cvlc to convert audio to mp4a
  VideoFilename="videotemp.mp4"

  #renice the audio conversion task, and grep to reduce ammount of garbage
  nice -n 15 cvlc "$1" --sout="#transcode{acodec=a52, ab=384, channels=2, samplerate=48000}:standard{mux=ps, dst=videotemp.mp4, access=file}:sout-transcode-soverlay=0" vlc://quit 2>&1 | grep packetizer
fi

# Aspect 		iPod Res	Max iPod Res
# 1.85:1 		640x385		752x400
# 2.39:1 		640x267		864x352
# 4:3    		640x480		640x480
# 16:9   1920x1080	640x360		736x416
#	 1280x720
#	 720x576

#set default resolution and aspect ratio
VideoSize="736x416"
VideoAspect="16:9"

#select correct aspect ratio, based on original clip details
if `echo ${VideoFormat} | grep 1280x720 1>/dev/null 2>&1`
then
  VideoSize="736x416"
  VideoAspect="16:9"
fi

if `echo ${VideoFormat} | grep 720x576 1>/dev/null 2>&1`
then
  VideoSize="640x480"
  VideoAspect="4:3"
fi

#convert audio+video
nice -n 15 ffmpeg -i "$VideoFilename" -vcodec libxvid -b 512kb -qmin 3 -qmax 5 -bufsize 4096 -g 300 -vsync 1 -acodec libfaac -ab 192kb -async 44100 -s "$VideoSize" -aspect "$VideoAspect" "`basename "$1" .mpg`.mp4" 2>&1

#clean up temporary files as necessary
if [ -e "videotemp.mp4" ]
then
  #Cleanup
  rm videotemp.mp4
fi
