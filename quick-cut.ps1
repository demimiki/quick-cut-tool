#PS 5.1+

# Changelog
#
# Added mkv support
# Multi-track audio support added


#Receive arguments from batch file
param (
    [string]$path
)

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

$ffmpeg_input = '"' + $path + '"'
$ffmpeg_output = '"' + $output + '"'
$start = Read-Host "Cut from (0:00)"
$end = Read-Host "End (0:00) or leave blank"
$tracks = Read-Host "Save audio tracks (1,2,3)"
if ($tracks -eq ""){$tracks = "1,2,3"}
$tracks = $tracks.split(",")
$ends = ""

if($end -ne ""){
	$ends = "-copyts -to $end"
}

$track_count = Invoke-Expression "($ffmpeg -i $ffmpeg_input 2>&1 | Select-String 'Stream #0:.*Audio:' | Measure-Object).Count"
$mapArgs = ""
$index = 1
while($index -le $track_count){
	$i = $index | Out-String
	$i = $i.subString(0,$i.Length-2)
	if(-not $tracks.Contains($i)){
		$mapArgs += "-map -0:a:$($index-1) "
	}
	$index = $index + 1
}

#Extract all audio tracks and trim
$ffmpegCommand = @(
	"-hide_banner",
	"-loglevel error",
	"-i $ffmpeg_input",
	"-map 0",
	"-map -0:v",
	$mapArgs,
	"-c:a copy"
	"-ss $start",
	$ends,
	"a1.mkv"
) -join " "

Start-Process -FilePath $ffmpeg -ArgumentList $ffmpegCommand -Wait -NoNewWindow	

#Extract only video and trim
$ffmpegCommand = @(
	"-hide_banner",
	"-loglevel error",
	"-i $ffmpeg_input",
	"-an",
	"-c:v copy",
	"-ss $start",
	$ends,
	"v1.mkv"
) -join " "

Start-Process -FilePath $ffmpeg -ArgumentList $ffmpegCommand -Wait -NoNewWindow	

#Mix audio tracks into single track
$ffmpegCommand = @(
	"-hide_banner",
	"-loglevel error",
	"-i a1.mkv",
	"-filter_complex",
	"amix=inputs=$($tracks.count):duration=longest",
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
Remove-Item "a1.mkv"
Remove-Item "a2.mkv"
Remove-Item "v1.mkv"
Stop-Process -ID $PID -Force