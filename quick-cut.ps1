#PS 5.1+

#Receive arguments from batch file
param (
    [string]$path
)

#Check if mp4 file format
if (((Test-Path $path -PathType Leaf) -ne $True) -or (([System.IO.Path]::GetExtension($path)) -ne ".mp4")){
	Write-Host "Input:",$path
	Write-Host "Invalid input file, exiting..."
	pause
	Stop-Process -ID $PID -Force
}

#Generate new filenames
$directory = Split-Path -Path $path
$original_name = [System.IO.Path]::GetFileNameWithoutExtension($path)
$modified_name = $original_name + "_o.mp4"
$output = $directory + "\" + $modified_name

#Check if ffmpeg present
$ffmpeg = (Split-Path -Parent $pwd) + "\ffmpeg.exe"
if ((Test-Path $ffmpeg -PathType Leaf) -ne $True){
	$ffmpeg = [String]($pwd) + "\ffmpeg.exe"
	if ((Test-Path $ffmpeg -PathType Leaf) -ne $True){
		Write-Host "No ffmpeg found, exiting..."
		pause
		Stop-Process -ID $PID -Force
	}
}

$ffmpeg_input = '"' + $path + '"'
$ffmpeg_output = '"' + $output + '"'
$start = Read-Host "Cut from (0:00)"
$end = Read-Host "End (0:00) or leave blank"
$mic = Read-Host "Save microphone (y/[n])"

#Separate if statements run faster, than checking for track length
#Cut until end
if ($end -eq ""){
	if ($mic -eq "y"){
		#Mix game audio with microphone
		Start-Process -FilePath $ffmpeg -ArgumentList "-hide_banner", "-loglevel error", "-i $ffmpeg_input", "-filter_complex", "amix=inputs=2:duration=longest", "-c:v copy", "-ss $start", "$ffmpeg_output" -Wait -NoNewWindow
	}
	if (($mic -eq "n") -or (($mic -eq ""))){
		#Only save game audio (audio track 0)
		Start-Process -FilePath $ffmpeg -ArgumentList "-hide_banner", "-loglevel error", "-i $ffmpeg_input", "-map 0", "-map -0:a:1", "-c copy", "-ss $start", "$ffmpeg_output" -Wait -NoNewWindow
	}
}
#Cut until specified
if ($end -ne ""){
	if ($mic -eq "y"){
		#Mix game audio with microphone
		Start-Process -FilePath $ffmpeg -ArgumentList "-hide_banner", "-loglevel error", "-copyts", "-i $ffmpeg_input", "-filter_complex", "amix=inputs=2:duration=longest", "-c:v copy", "-ss $start", "-to $end", "$ffmpeg_output" -Wait -NoNewWindow
	}
	if (($mic -eq "n") -or (($mic -eq ""))){
		#Only save game audio (audio track 0)
		Start-Process -FilePath $ffmpeg -ArgumentList "-hide_banner", "-loglevel error", "-copyts", "-i $ffmpeg_input", "-map 0", "-map -0:a:1", "-c copy", "-ss $start", "-to $end", "$ffmpeg_output" -Wait -NoNewWindow
	}
}

#Rename old and new files
$old_item = "old_"+$original_name+".mp4"
$new_item = $original_name+".mp4"
Rename-Item -Path $path -NewName $old_item
Rename-Item -Path $output -NewName $new_item
Stop-Process -ID $PID -Force
