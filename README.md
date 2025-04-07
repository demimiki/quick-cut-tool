# Quick-Cut Tool
A handy tool for cutting videos shorter without the need to re-encode your video. Simply Drag&Drop your video into <b>cut.bat</b>. Designed to work with Nvidia's recorder or with OBS. It's recommended to record your microphone in a separate track, you can set this inside Nvidia's overlay.

## Usage
1. Download the latest ffmpeg package from https://www.gyan.dev/ffmpeg/builds/ffmpeg-git-essentials.7z</br>
   <i>or build your own ffmpeg for slightly faster processing (no flags are needed)</i></br>
   <i>or <b>Recommended:</b> install ffmpeg with <code>winget install ffmpeg</code></i>
2. Extract ffmpeg.exe
3. Place the scripts and ffmpeg.exe to the same folder
4. Drag&drop the video into cut.bat
5. Select startpoint (in 0:00 format), endpoint (in 0:00 format or leave empty if you don't want to cut the end) and audio tracks (defaults to save the first 3 audio tracks)
6. After cut you will find your <i>video.mp4</i> and <i>old_video.mp4</i> files in the same place

## Tips
Instead of the 0:00 time format, you can write it down in second's format too.</br>
The 0:00.000 time format is also accepted.</br>
The endpoint is defaulted to the <b>end of the video</b> and by default it saves tracks 1,2 and 3, you can change this behavior in the <b>tracks</b> variable.</br>
If you don't record multiple tracks, then select track 1.
If you do record your microphone or other tracks, then after saving your audio tracks the new file will have all the tracks merged.

## FAQ
<i>- Error: can't rename file</i></br>
Video is still open, close it first</br>
<i>- At least one output file must be specified</i></br>
No start time was specified or was incorrectly inputted</br>
<i>- No ffmpeg found, exiting...</i></br>
Place the ffmpeg.exe next to cut.bat and cut.ps1</br>
<i>- Why do I need both files?</i></br>
Without modifying Windows you can't drag&drop files into powershell scripts (blame MS for that)</br>
