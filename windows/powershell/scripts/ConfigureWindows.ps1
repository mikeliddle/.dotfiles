# Set Windows theme to dark
Write-Host "Setting Windows theme to dark mode..."
try {
    # Set app theme to dark
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Type DWord -Force

    # Set system theme to dark
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Type DWord -Force

    Write-Host "Windows theme set to dark mode successfully."
}
catch {
    Write-Error "Failed to set Windows theme to dark mode: $_"
}

# Configure Taskbar settings
Write-Host "Configuring Taskbar settings..."
try {
    # Remove Task View button
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0 -Type DWord -Force
    # Remove Search box from taskbar
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0 -Type DWord -Force

    Write-Host "Taskbar configuration completed."
}
catch {
    Write-Error "Failed to configure taskbar settings: $_"
}

# Enable Long file paths and query params
Write-Host "Enabling long file paths..."
try {
    # Enable long file paths
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -Type DWord -Force
    Write-Host "Long file paths have been enabled. A restart may be required for the changes to take effect."
}
catch {
    Write-Error "Failed to enable long file paths: $_"
}

$httpSysRegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\HTTP\Parameters"
$urlSegmentMaxLengthDword = "UrlSegmentMaxLength"
$urlSegmentMaxLengthValue = 1024
if (-not (Test-Path $httpSysRegistryPath)) {
    Write-End "HTTP registry path not found."
}
$registryValue = (Get-ItemProperty -Path $httpSysRegistryPath -Name $urlSegmentMaxLengthDword -ErrorAction SilentlyContinue)
if ($null -eq $registryValue -or $registryValue.UrlSegmentMaxLength -lt $urlSegmentMaxLengthValue) {
    Write-Host "UrlSegmentMaxLength isn't long enough. Setting to appropriate length..."
    if (New-ItemProperty -Path $httpSysRegistryPath -Name $urlSegmentMaxLengthDword -Value $urlSegmentMaxLengthValue -PropertyType DWORD -Force) {
        Write-Host "UrlSegmentMaxLength set to $urlSegmentMaxLengthValue. Please restart your machine for the changes to take effect." -ForegroundColor Yellow
    }
    else {
        Write-Host "Failed to set UrlSegmentMaxLength."

    }
}

# Set Windows Terminal as default terminal application
Write-Host "Setting Windows Terminal as default terminal application..."
try {
    # Check if Windows Terminal is installed
    $wtPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe"
    if (Test-Path $wtPath) {
        # For Windows 11
        if ([Environment]::OSVersion.Version.Build -ge 22000) {
            $terminalSettingsPath = "HKCU:\Console\%%Startup"

            # Create the path if it doesn't exist
            if (-not (Test-Path $terminalSettingsPath)) {
                New-Item -Path $terminalSettingsPath -Force | Out-Null
            }

            # Set Windows Terminal as default
            Set-ItemProperty -Path $terminalSettingsPath -Name "DelegationTerminal" -Value "{2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}" -Type String -Force
            Write-Host "Windows Terminal set as default terminal application."
        }
        else {
            # For Windows 10 or earlier
            Write-Host "Automatic setting of default terminal is only supported in Windows 11."
            Write-Host "Please set Windows Terminal as default manually through Settings > Privacy & Security > For developers > Terminal."
        }
    }
    else {
        Write-Warning "Windows Terminal not found. Please install it first."
    }
}
catch {
    Write-Error "Failed to set Windows Terminal as default: $_"
}

# Enable Developer Mode on Windows
$DeveloperModeKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
try {
    if (-not (Test-Path $DeveloperModeKey)) {
        New-Item -Path $DeveloperModeKey -Force | Out-Null
    }
    Set-ItemProperty -Path $DeveloperModeKey -Name "AllowDevelopmentWithoutDevLicense" -Value 1
    Write-Host "Developer Mode has been enabled."
}
catch {
    Write-Error "Failed to enable Developer Mode: $_"
}

# Create a VHD file with ReFS if D:\ does not exist
if (-not (Test-Path "D:\")) {
    $VhdPath = "C:\DevDisk.vhdx"
    $VhdSize = 50GB  # Adjust the size as needed

    try {
        New-VHD -Path $VhdPath -Dynamic -SizeBytes $VhdSize | Out-Null
        Mount-VHD -Path $VhdPath | Out-Null
        $Disk = Get-Disk | Where-Object { $_.Location -like "*$VhdPath*" }
        Initialize-Disk -Number $Disk.Number -PartitionStyle GPT -Confirm:$false
        New-Partition -DiskNumber $Disk.Number -UseMaximumSize -AssignDriveLetter | Out-Null
        $Partition = Get-Partition -DiskNumber $Disk.Number | Where-Object { $_.DriveLetter }
        Format-Volume -DriveLetter $Partition.DriveLetter -FileSystem ReFS -Confirm:$false | Out-Null
        Set-Partition -DriveLetter $Partition.DriveLetter -NewDriveLetter D
        Write-Host "Dev disk created at $VhdPath and mounted to D:"
    }
    catch {
        Write-Error "Failed to create or mount VHD: $_"
    }
}
else {
    Write-Host "D:\ already exists. Skipping VHD creation."
}

# Enable Hyper-V and virtualization
if (-not (Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online).State -eq "Enabled") {
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -All -NoRestart
    Write-Host "Hyper-V has been enabled. A restart is required to complete the installation."
}
else {
    Write-Host "Hyper-V is already enabled."
}

if ($env:USERDOMAIN -eq "NORTHAMERICA") {
    # Enable Containers feature
    if (-not (Get-WindowsOptionalFeature -FeatureName Containers -Online).State -eq "Enabled") {
        Write-Host "Enabling Windows Containers feature..."
        Enable-WindowsOptionalFeature -Online -FeatureName Containers -All -NoRestart
        Write-Host "Windows Containers feature has been enabled. A restart is required to complete the installation."
    }
    else {
        Write-Host "Windows Containers feature is already enabled."
    }
}

# Enable Windows Subsystem for Linux (WSL)
if (-not (Get-WindowsOptionalFeature -FeatureName Microsoft-Windows-Subsystem-Linux -Online).State -eq "Enabled") {
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All -NoRestart
    Write-Host "WSL has been enabled. A restart is required to complete the installation."
}
else {
    Write-Host "WSL is already enabled."
}

