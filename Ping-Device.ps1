param(
    [string]$ip,
    [int]$interval,       # Ping interval and 
    [int]$set_timeout     # Timeout limit is set by user
)

$timeout = (Get-Date).AddMinutes($set_timeout)
$t = $interval + 3
Write-Host "Interval is: $($t)s"
Write-Host "Timeout is at: $timeout"


while ((Get-Date) -lt $timeout) {

    if (Test-Connection $ip -Count 1 -Quiet -ErrorAction SilentlyContinue) {   # Ping to Check for connection

        Write-Host ""
        Write-Host "$ip is ONLINE!" -ForegroundColor Green   # Connection Notification

        try {
            [Console]::Beep(800,500)

            Add-Type -AssemblyName PresentationFramework -ErrorAction Stop  # Extra Window popup
            [System.Windows.MessageBox]::Show("$ip is back online!")
        }
        catch {
            Write-Warning "Notification failed: $_"
        }

        break
    }

    Write-Host "$(Get-Date -Format HH:mm:ss): Waiting for $ip..."
    Start-Sleep -Seconds $interval
}

if ((Get-Date) -ge $timeout) {
    Write-Host ""
    Write-Host "Timed out waiting for $ip." -ForegroundColor Red
}
