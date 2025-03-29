# PowerShell Script: docker-transcode-monitor.ps1

# --- CONFIGURATION ---
$containerName = "docker-env-ubuntu"
$logFolder = "$PSScriptRoot\monitor_logs"
$transcodeScriptPath = "/home/s4325535/CSI_6_SIT/transcode_runner.sh"

# --- TIMING STAMPS ---
$transcode1024StartMarker = "$logFolder\transcode_1024_start.marker"
$transcode1024EndMarker   = "$logFolder\transcode_1024_end.marker"
$transcode2048StartMarker = "$logFolder\transcode_2048_start.marker"
$transcode2048EndMarker   = "$logFolder\transcode_2048_end.marker"
$vmStartMarker = "$logFolder\docker_start.marker"
$vmStopMarker  = "$logFolder\docker_stop.marker"

$vmStartMarker = "$logFolder\docker_start.marker"
$vmStopMarker = "$logFolder\docker_stop.marker"

# --- SETUP ---
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$cpuLog = "$logFolder\cpu_$timestamp.csv"
$memLog = "$logFolder\mem_$timestamp.csv"
$powerLog = "$logFolder\power_$timestamp.csv"

# Create log directory
New-Item -ItemType Directory -Path $logFolder -Force | Out-Null

Write-Host "[+] Starting system monitoring on HOST..."

# Start CPU logging
Start-Process -FilePath "typeperf.exe" -ArgumentList '"\Processor(_Total)\% Processor Time"', "-si", "1", "-f", "CSV", "-o", "$cpuLog" -WindowStyle Hidden

# Start Memory logging
Start-Process -FilePath "typeperf.exe" -ArgumentList '"\Memory\Available MBytes"', "-si", "1", "-f", "CSV", "-o", "$memLog" -WindowStyle Hidden

# Start Power logging (if supported)
Start-Process -FilePath "typeperf.exe" -ArgumentList '"\Power Meter(_Total)\Power"', "-si", "1", "-f", "CSV", "-o", "$powerLog" -WindowStyle Hidden

Write-Host "[✓] Monitoring started. Waiting 5 seconds for baseline..."
Start-Sleep -Seconds 5

# --- RECORD DOCKER START MARKER ---
(Get-Date).ToString('o') | Out-File $vmStartMarker

Write-Host "[+] Starting Docker container..."
docker start $containerName | Out-Null

# Wait for container to be fully up
Start-Sleep -Seconds 5

# Wait for container to be fully up
Start-Sleep -Seconds 5

# --- RECORD TRANSCODE 1024 START MARKER ---
(Get-Date).ToString('o') | Out-File $transcode1024StartMarker

Write-Host "[+] Running 1024kbps transcoding inside Docker container..."
docker exec -u s4325535 $containerName bash $transcodeScriptPath 1024

# --- RECORD TRANSCODE 1024 END MARKER ---
(Get-Date).ToString('o') | Out-File $transcode1024EndMarker

# Wait 5 seconds between runs
Start-Sleep -Seconds 5

# --- RECORD TRANSCODE 2048 START MARKER ---
(Get-Date).ToString('o') | Out-File $transcode2048StartMarker

Write-Host "[+] Running 2048kbps transcoding inside Docker container..."
docker exec -u s4325535 $containerName bash $transcodeScriptPath 2048

# --- RECORD TRANSCODE 2048 END MARKER ---
(Get-Date).ToString('o') | Out-File $transcode2048EndMarker


Write-Host "[✓] Transcoding complete. Stopping Docker container..."
docker stop $containerName | Out-Null

# --- RECORD DOCKER STOP MARKER ---
(Get-Date).ToString('o') | Out-File $vmStopMarker

Write-Host "[✓] Capturing 5s post-monitoring..."
Start-Sleep -Seconds 5

Write-Host "[✓] Stopping monitoring processes..."
Get-Process typeperf | Stop-Process -Force

Write-Host "✅ Logs and markers saved in $logFolder"

# --- PLOT RESULTS ---
Write-Host "[+] Generating plots..."
python "$PSScriptRoot\plot.py" --prefix "docker" --cpu "$cpuLog" --mem "$memLog" --power "$powerLog" `
    --vmstart $vmStartMarker `
    --transcode1024start $transcode1024StartMarker --transcode1024end $transcode1024EndMarker `
    --transcode2048start $transcode2048StartMarker --transcode2048end $transcode2048EndMarker `
    --vmstop $vmStopMarker --output "$PSScriptRoot"


Write-Host "📊 Plots saved to $PSScriptRoot"
