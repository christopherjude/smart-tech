# PowerShell Script: vm-transcode-monitor.ps1

# --- CONFIGURATION ---
$vmName = "vm-env-ubuntu"
$vmIp = "10.128.132.50"            
$vmUser = "s4325535"
$sshKeyPath = "$env:USERPROFILE\.ssh\vm-sit"   
$remoteScript = "~/CSI_6_SIT/transcode_runner.sh" 
$logFolder = "$PSScriptRoot\monitor_logs"

# --- TIMING STAMPS ---
$transcode1024Start = "$logFolder\transcode_1024_start.marker"
$transcode1024End   = "$logFolder\transcode_1024_end.marker"
$transcode2048Start = "$logFolder\transcode_2048_start.marker"
$transcode2048End   = "$logFolder\transcode_2048_end.marker"

$vmStartMarker = "$logFolder\vm_start.marker"
$vmStopMarker = "$logFolder\vm_stop.marker"

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

# --- RECORD VM START MARKER ---
(Get-Date).ToString('o') | Out-File $vmStartMarker

Write-Host "[+] Starting VM using VBoxManage..."
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" startvm $vmName --type headless

# Allow VM to boot fully
Start-Sleep -Seconds 20

# --- Wait 5s before starting transcoding ---
Start-Sleep -Seconds 5

# --- 1024 TRANSCODE ---
(Get-Date).ToString('o') | Out-File $transcode1024Start
Write-Host "[+] Starting 1024p transcoding..."
ssh -i $sshKeyPath "$vmUser@$vmIp" "cd CSI_6_SIT && bash $remoteScript 1024"
(Get-Date).ToString('o') | Out-File $transcode1024End

Start-Sleep -Seconds 5

# --- 2048 TRANSCODE ---
(Get-Date).ToString('o') | Out-File $transcode2048Start
Write-Host "[+] Starting 2048p transcoding..."
ssh -i $sshKeyPath "$vmUser@$vmIp" "cd CSI_6_SIT && bash $remoteScript 2048"
(Get-Date).ToString('o') | Out-File $transcode2048End


Write-Host "[✓] Transcoding complete. Shutting down VM using VBoxManage..."
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" controlvm $vmName acpipowerbutton

# Wait for VM to shut down gracefully
Start-Sleep -Seconds 10

# --- RECORD VM STOP MARKER ---
(Get-Date).ToString('o') | Out-File $vmStopMarker

Write-Host "[✓] Capturing 5s post-monitoring..."
Start-Sleep -Seconds 5

Write-Host "[✓] Stopping monitoring processes..."
Get-Process typeperf | Stop-Process -Force

Write-Host "✅ Logs and markers saved in $logFolder"

# --- PLOT RESULTS ---
Write-Host "[+] Generating plots..."
python "$PSScriptRoot\plot.py" --prefix "vm" --cpu "$cpuLog" --mem "$memLog" --power "$powerLog" `
    --vmstart $vmStartMarker --transcode1024start $transcode1024Start --transcode1024end $transcode1024End `
    --transcode2048start $transcode2048Start --transcode2048end $transcode2048End --vmstop $vmStopMarker `
    --output "$PSScriptRoot"


Write-Host "📊 Plots saved to $PSScriptRoot"
