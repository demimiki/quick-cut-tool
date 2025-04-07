#PS 5.1+

# Changelog
#
# Compare I-frame before cut, so video and audio stays in sync. If not cut on I-frame, a reencode is necessary
# Added default tracks option
# Now uses opus for audio instead of vorbis
#

#Receive arguments from batch file
param (
    [string]$path
)

#############OPTIONS#############

$tracks = "1,2,3" # Default tracks to keep

#################################

#Check if mp4 file format
if ((Test-Path $path -PathType Leaf) -ne $True){
	if((([System.IO.Path]::GetExtension($path)) -ne ".mp4") -or (([System.IO.Path]::GetExtension($path)) -ne ".mkv")){
		Write-Host "Input:",$path
		Write-Host "Invalid input file, exiting..."
		pause
		Stop-Process -ID $PID -Force
	}
}

#Generate new filenames
$directory = Split-Path -Path $path
$original_name = [System.IO.Path]::GetFileNameWithoutExtension($path)
if (([System.IO.Path]::GetExtension($path)) -eq ".mp4"){
	$modified_name = $original_name + "_o.mp4"
}
else{
	$modified_name = $original_name + "_o.mkv"
}

$output = $directory + "\" + $modified_name

#Check if ffmpeg present
$ffmpeg = (Split-Path -Parent $pwd) + "\ffmpeg.exe"
if ((Test-Path $ffmpeg -PathType Leaf) -ne $True){
	$ffmpeg = [String]($pwd) + "\ffmpeg.exe"
	if ((Test-Path $ffmpeg -PathType Leaf) -ne $True){
		if (Get-Command ffmpeg -ErrorAction SilentlyContinue){
			$ffmpeg="ffmpeg"
		}else{
			Write-Host "No ffmpeg found, exiting..."
			pause
			Stop-Process -ID $PID -Force
		}
	}
}

#Check if ffprobe present
$ffprobe = (Split-Path -Parent $pwd) + "\ffprobe.exe"
if ((Test-Path $ffprobe -PathType Leaf) -ne $True){
	$ffprobe = [String]($pwd) + "\ffprobe.exe"
	if ((Test-Path $ffprobe -PathType Leaf) -ne $True){
		if (Get-Command ffmpeg -ErrorAction SilentlyContinue){
			$ffprobe="ffprobe"
		}else{
			Write-Host "No ffprobe found, exiting..."
			pause
			Stop-Process -ID $PID -Force
		}
	}
}

$ffmpeg_input = '"' + $path + '"'
$ffmpeg_output = '"' + $output + '"'
$temp_output = ""
$start = Read-Host "Cut from (0:00)"
$end = Read-Host "End (0:00) or leave blank"
$track = Read-Host "Save audio tracks ($tracks)"
if($track -ne ""){
	$tracks = $track.split(",")
}else{
	$tracks = $tracks.split(",")
}
$ends = ""

if($end -ne ""){
	$ends = "-copyts -to $end"
}

#Checking if cut is on I-frame, otherwise audio won't be in sync with video

$iframe_array = @(Invoke-Expression "$ffprobe -v error -skip_frame nokey -select_streams v:0 -show_frames -show_entries frame=best_effort_timestamp_time -of csv=print_section=0 $ffmpeg_input")
$iframe_array = $iframe_array | ForEach-Object{[double]$_}
$parts = $start -split ":"
$parts = $parts | ForEach-Object{[double]$_}
if ($parts.count -eq 1){$start = [double]($parts[0])}
if ($parts.count -eq 2){$start = [double]($parts[0] * 60 + $parts[1])}
if ($parts.count -eq 3){$start = [double]($parts[0] * 3600 + $parts[1] * 60 + $parts[2])}

if (-not $iframe_array.Contains($start)) {
    $iframe_array += $start
    $iframe_array = $iframe_array | Sort-Object
    $index = $iframe_array.IndexOf($start)
	$prev = if ($index -gt 0) {$iframe_array[$index - 1]} else {$null}
    $prev2 = if ($index -gt 1) {$iframe_array[$index - 2]} else {$null}
    $next = if ($index -lt ($iframe_array.Count - 1)) {$iframe_array[$index + 1]} else {$null}
    $next2 = if ($index -lt ($iframe_array.Count - 2)) {$iframe_array[$index + 2]} else {$null}
	Write-Output "The cut is not on an I-frame (keyframe), choose another position otherwise a reencode is necessary!"
	
	if ($index -eq 0) {
        if ($next -ne $null) {$ts = [Timespan]::fromseconds($next); $ts = ("{0:hh\:mm\:ss\,ffffff}" -f $ts); Write-Output "Next: $next s ($ts)"}
        if ($next2 -ne $null) {$ts = [Timespan]::fromseconds($next2); $ts = ("{0:hh\:mm\:ss\,ffffff}" -f $ts); Write-Output "Next 2: $next2 s ($ts)"}
    } elseif ($index -eq ($iframe_array.Count - 1)) {
        if ($prev -ne $null) {$ts = [Timespan]::fromseconds($prev); $ts = ("{0:hh\:mm\:ss\,ffffff}" -f $ts); Write-Output "Previous: $prev s ($ts)"}
        if ($prev2 -ne $null) {$ts = [Timespan]::fromseconds($prev2); $ts = ("{0:hh\:mm\:ss\,ffffff}" -f $ts); Write-Output "Previous 2: $prev2 s ($ts)"}
    } else {
        if ($prev -ne $null) {$ts = [Timespan]::fromseconds($prev); $ts = ("{0:hh\:mm\:ss\,ffffff}" -f $ts); Write-Output "Previous: $prev s ($ts)"}
        if ($next -ne $null) {$ts = [Timespan]::fromseconds($next); $ts = ("{0:hh\:mm\:ss\,ffffff}" -f $ts); Write-Output "Next: $next s ($ts)"}
    }
	$answer = Read-Host "Input a recommended cut position in seconds or leave empty to re-encode"
	if (($answer -ne "") -and (($answer -ne $next) -and ($answer -ne $next2) -and ($answer -ne $prev) -and ($answer -ne $prev2))){
		Write-Host "Invalid timestamp, exiting..."
		pause
		Stop-Process -ID $PID -Force
	}
	if ($answer -eq ""){
		#reencode and cut
		$temp_output = $directory + "\" + "reencode.mkv"
		Invoke-Expression "$ffmpeg -hide_banner -loglevel error -ss $start -i $ffmpeg_input -map 0 -c:v libx264 -preset ultrafast -qp 12 -c:a copy $ends $temp_output"
		$ffmpeg_input = $temp_output
		$start = $null
		$ends = ""
	}
	$answer = [double]$answer
	if (($answer -eq $next) -or ($answer -eq $next2) -or ($answer -eq $prev) -or ($answer -eq $prev2)){
		$start = $answer
	}
}else{
	Write-Output "Cut is on keyframe, OK"
}


$track_count = Invoke-Expression "($ffmpeg -i $ffmpeg_input 2>&1 | Select-String 'Stream #0:.*Audio:' | Measure-Object).Count"
$mapArgs = ""
$audioMix = ""
$index = 1
$mixCount = 0
while($index -le $track_count){
	$i = $index | Out-String
	$i = $i.subString(0,$i.Length-2)
	if(-not $tracks.Contains($i)){
		$mapArgs += "-map -0:a:$($index-1) " #select what to remove
	}else{
		$audioMix += "[0:a:$($mixCount)]" #select what to keep
		$mixCount = $mixCount + 1
	}		
	$index = $index + 1
}

if ($start -ne $null){
	$starts = " -ss " + $start + " "
}



#Extract needed audio tracks
$ffmpegCommand = @(
	"-hide_banner",
	"-loglevel error",
	"-i $ffmpeg_input",
	"-map 0",
	"-map -0:v",
	$mapArgs,
	"-c:a copy"
	$starts,
	$ends,
	"a1.mkv"
) -join " "

Start-Process -FilePath $ffmpeg -ArgumentList $ffmpegCommand -Wait -NoNewWindow	

#Extract only video
$ffmpegCommand = @(
	"-hide_banner",
	"-loglevel error",
	"-i $ffmpeg_input",
	"-an",
	"-c:v copy",
	$starts,
	$ends,
	"v1.mkv"
) -join " "

Start-Process -FilePath $ffmpeg -ArgumentList $ffmpegCommand -Wait -NoNewWindow	

#Mix audio tracks into single track
$ffmpegCommand = @(
	"-hide_banner",
	"-loglevel error",
	"-i a1.mkv",
	"-filter_complex `"$audioMix amerge=inputs=$($tracks.count) [audioOut]`"",
	"-map `"[audioOut]`"",
	"-c:a libopus",
	"-b:a 128k",
	"-ac 2 -ar 48000", #force stereo and 48kHz sample rate
	"a2.mkv"
) -join " "

Start-Process -FilePath $ffmpeg -ArgumentList $ffmpegCommand -Wait -NoNewWindow	

#Add audio to video
$ffmpegCommand = @(
	"-hide_banner",
	"-loglevel error",
	"-i v1.mkv",
	"-i a2.mkv",
	"-c copy",
	"-map 0:v:0",
	"-map 1:a:0",
	"-shortest",
	$ffmpeg_output
) -join " "

Start-Process -FilePath $ffmpeg -ArgumentList $ffmpegCommand -Wait -NoNewWindow	

#Rename old and new files
$old_item = "old_"+$original_name
if (([System.IO.Path]::GetExtension($path)) -eq ".mp4"){
	$old_item = $old_item + ".mp4"
}
else{
	$old_item = $old_item + ".mkv"
}
$new_item = $original_name
if (([System.IO.Path]::GetExtension($path)) -eq ".mp4"){
	$new_item = $new_item + ".mp4"
}
else{
	$new_item = $new_item + ".mkv"
}
Rename-Item -Path $path -NewName $old_item
Rename-Item -Path $output -NewName $new_item
if ($temp_output -ne ""){
	Remove-Item $temp_output
}
Remove-Item "a1.mkv"
Remove-Item "a2.mkv"
Remove-Item "v1.mkv"
Stop-Process -ID $PID -Force