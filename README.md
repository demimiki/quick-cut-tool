# Quick-Cut Tool
A handy tool for cutting videos shorter without the need to re-encode your video. Simply Drag&Drop your video into <b>cut.bat</b>. Designed to work with Nvidia's recorder. It's recommended to record your microphone in a separate track, you can set this inside Nvidia's overlay.

## Usage
1. Download the latest ffmpeg package from https://www.gyan.dev/ffmpeg/builds/ffmpeg-git-essentials.7z</br>
   <i>or build your own ffmpeg for slightly faster processing (no flags are needed)</i>
2. Extract ffmpeg.exe
3. Place the scripts and ffmpeg.exe to the same folder
4. Drag&drop the video into cut.bat
5. Select startpoint (in 0:00 format), endpoint (in 0:00 format or leave empty if you don't want to cut the end) and microphone (y for yes and n or <i>empty</i> for no)
6. After cut you will find your <i>video.mp4</i> and <i>old_video.mp4</i> files in the same place

## Tips
Instead of the 0:00 time format, you can write it down in second's format too.</br>
The 0:00.000 time format is also accepted.</br>
The endpoint is defaulted to the <b>end of the video</b> and the microphone is defaulted to <b>NOT</b> save the microphone.</br>
If you don't record your microphone or record it to the same track, then select no for <i>save microphone</i>.
If you do record your microphone and save it for a separate track, then after saving your microphone the new file will have the 2 tracks merged.

## FAQ
<i>- Error: can't rename file</i></br>
Video is still open, close it first</br>
<i>- At least one output file must be specified</i></br>
No start time was specified or was incorrectly inputted</br>
<i>- No ffmpeg found, exiting...</i></br>
Place the ffmpeg.exe next to cut.bat and cut.ps1</br>
<i>- Why do I need both files?</i></br>
Without modifying Windows you can't drag&drop files into powershell scripts (blame MS for that)</br>
