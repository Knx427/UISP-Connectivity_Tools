param(
    [string]$ip,
    [int]$interval = 5,        # Ping every 5 seconds
    [int]$set_timeout = 5      # 5 minutes timeout limit
)

# --- Manual IP Entry Prompt ---
if (-not $ip) {
    $ip = Read-Host "Enter the customer radio IP address to reboot"
    if (-not $ip) { 
        Write-Host "No IP entered. Exiting." -ForegroundColor Red
        return 
    }
}

# --- UISP Configuration ---
$UispUrl   = "https://[Host]/nms/api/v2.1" # Example URI
$ApiToken  = "[API-Token]"    # Get Api from USIP Devices Settings

$Headers = @{                               
    "x-auth-token" = $ApiToken            # Set Payload Headers
    "Accept"       = "application/json"
}

# --- Step 1: Find Device ID by IP ---
Write-Host ""
Write-Host "[1/3] Searching UISP for device with IP: $ip..." -ForegroundColor Cyan

try {
    # Fetch the raw object list from endpoint
    $Devices = Invoke-RestMethod -Uri "$UispUrl/devices" -Method Get -Headers $Headers -ErrorAction Stop
    $EscapedIp = [regex]::Escape($ip)     # Strict IP Match 
    $RegexPattern = "^$EscapedIp(\b|/)"   # IP ends with end of ip|space|/24
    
    # Look for the target IP wherever it might hide in the schema
    $TargetDevice = $Devices | Where-Object { 
        $_.ipAddress -match $RegexPattern
    }

    # Validation
    if (-not $TargetDevice) {
        Write-Host "CRITICAL ERROR: Could not match IP $ip to any client in the returned JSON database." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        return
    }

    # If JSON query returns multiple matching items, selects only the first match
    if ($TargetDevice -is [array]) {
        $TargetDevice = $TargetDevice[0]
    }

    $DeviceId = $TargetDevice.identification.id
    $DeviceName = $TargetDevice.identification.site.name
    $ActualIP = $TargetDevice.ipAddress
    
    # Fail-safe to name the device if the name property path changes
    if (-not $DeviceName) { $DeviceName = "Discovered Antenna" }


    Write-Host "SUCCESS: Target verified!" -ForegroundColor Green
    Write-Host " -> Customer Radio Name : $DeviceName" -ForegroundColor Green
    Write-Host " -> Verified Management IP: $ActualIP" -ForegroundColor Green
    Write-Host " -> UISP Hardware ID    : $DeviceId" -ForegroundColor Green

} catch {
    Write-Host "CRITICAL ERROR: Failed to extract structural data from UISP API: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    return
}


# --- Confirmation Prompt ---
Write-Host ""
$Confirmation = Read-Host "Are you sure you want to reboot '$DeviceName' ($ip)? (y/n)"
if ($Confirmation -ne "y") {
    Write-Host "Reboot canceled by user. Exiting safely." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    return
}

# --- Trigger the Reboot ---
Write-Host ""
Write-Host "[2/3] Sending reboot command to UISP..." -ForegroundColor Yellow

try {
    $RebootUrl = "$UispUrl/devices/$DeviceId/restart"     # Sending the Reboot Comm to the Device
    $Response = Invoke-RestMethod -Uri $RebootUrl -Method Post -Headers $Headers -ErrorAction Stop
    
    Write-Host "Reboot command accepted successfully!" -ForegroundColor Green
    Write-Host "Waiting 15 seconds for the radio to drop offline..." -ForegroundColor Gray
    Start-Sleep -Seconds 15

} catch {
    Write-Host "CRITICAL ERROR: UISP rejected the reboot command: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    return
}

# --- Ping Loop ---
Write-Host ""
Write-Host "[3/3] Starting ping monitor..." -ForegroundColor Cyan
$timeout = (Get-Date).AddMinutes($set_timeout)
Write-Host "Timeout window ends at: ($($timeout.ToString('HH:mm:ss')))" -ForegroundColor Gray


while ((Get-Date) -lt $timeout) {

    if (Test-Connection $ip -Count 1 -Quiet -ErrorAction SilentlyContinue) {

        Write-Host ""
        Write-Host "ONLINE: $ip ($DeviceName) is ONLINE!" -ForegroundColor Green

        try {
            [Console]::Beep(800,500)

            Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
            [System.Windows.MessageBox]::Show("$ip ($DeviceName) is back online!", "UISP Reboot Complete")
        }
        catch {
            Write-Warning "Notification failed: $_"
        }

        break
    }

    Write-Host "$(Get-Date -Format HH:mm:ss): Waiting for radio to respond to pings..."
    Start-Sleep -Seconds $interval
}

if ((Get-Date) -ge $timeout) {
    Write-Host ""
    Write-Host "TIMED OUT: Device did not return online within $set_timeout minutes." -ForegroundColor Red
}

Read-Host ""
Read-Host "Task complete. Press Enter to close window"
