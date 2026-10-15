# UISP-Connectivity_Tools
PowerShell utilities for UISP network management and connectivity monitoring.

***UISP-Reboot.ps1*** - Finds a UISP-managed device by IP, requests a reboot through the UISP API, and monitors connectivity until the device comes back online or times out

***Ping-Device.ps1*** - Monitors a device's connectivity at a configurable interval and notifies the user when it responds or the timeout expires.

## Usage

Each utility includes a Windows batch `.bat` launcher that executes its corresponding PowerShell `.ps1` script.

Keep each `.bat` file in the same directory as its corresponding `.ps1` script.

Run the desired `.bat` file to launch the utility.

*Optionally, create Windows shortcuts to the batch files for quick access from your desktop.*
