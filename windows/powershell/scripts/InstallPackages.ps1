# Check if winget is installed, if not install it
function Install-Winget {
    try {
        Get-Command winget -ErrorAction Stop
        Write-Host "Winget is already installed."
        return $true
    }
    catch {
        Write-Host "Winget is not installed. Installing winget..."
        try {
            # Install App Installer from Microsoft Store (contains winget)
            $progressPreference = 'silentlyContinue'
            $storeAppName = "Microsoft.DesktopAppInstaller"
            $storeApp = Get-AppxPackage -Name $storeAppName -ErrorAction SilentlyContinue

            if (-not $storeApp) {
                Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction Stop
                Write-Host "Winget has been installed successfully."
                return $true
            }
            else {
                Write-Host "App Installer package exists but winget command not found. Attempting to repair..."
                Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction Stop
                return $true
            }
        }
        catch {
            Write-Error "Failed to install winget: $_"
            return $false
        }
    }
}

# Function to install a package using winget
function Install-Package {
    param (
        [string]$PackageName,
        [string]$Source = "winget"
    )
    $InstalledPackage = winget list | Where-Object { $_ -match $PackageName }
    if (-not $InstalledPackage) {
        Write-Host "Installing $PackageName from $Source..."
        if ($Source -eq "winget") {
            winget install --id $PackageName # Probably shouldn't use this anymore...
        }
        else {
            Write-Warning "Unknown source $Source for package $PackageName. Skipping..."
        }
    }
    else {
        Write-Host "$PackageName is already installed."
    }
}

# Ensure winget is available before continuing
if (-not (Install-Winget)) {
    Write-Error "Winget is required to continue. Installation failed."
    exit 1
}

winget configure -f windows/powershell/dsc/shared.winget --disable-interactivity --accept-configuration-agreements --suppress-initial-details --nowarn

if ($env:USERDOMAIN -eq "NORTHAMERICA") {
    winget configure -f windows/powershell/dsc/work.winget --disable-interactivity --accept-configuration-agreements --suppress-initial-details --nowarn
}
else {
    winget configure -f windows/powershell/dsc/personal.winget --disable-interactivity --accept-configuration-agreements --suppress-initial-details --nowarn
}

# Load the packages from windows/packages.json
$PackagesFile = "windows/packages.json"
if (Test-Path $PackagesFile) {
    $Packages = Get-Content $PackagesFile | ConvertFrom-Json

    foreach ($Package in $Packages.Shared) {
        Install-Package -PackageName $Package.package -Source $Package.src
    }

    if ($env:USERDOMAIN -eq "NORTHAMERICA") {
        foreach ($Package in $Packages.work) {
            Install-Package -PackageName $Package.package -Source $Package.src
        }
    }
    else {
        foreach ($Package in $Packages.personal) {
            Install-Package -PackageName $Package.package -Source $Package.src
        }
    }

    Start-Job -ScriptBlock {
        winget update
        winget upgrade --all --silent --accept-source-agreements --accept-package-agreements
    } | Out-Null
}
else {
    Write-Error "Packages file $PackagesFile not found."
}

# Add Node.js and npm to the user PATH
$NodePath = "C:\Program Files\nodejs"
if (Test-Path $NodePath) {
    $EnvPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)
    if (-not $EnvPath.Contains($NodePath)) {
        Write-Host "Adding Node.js and npm to the user PATH..."
        [System.Environment]::SetEnvironmentVariable("Path", "$EnvPath;$NodePath", [System.EnvironmentVariableTarget]::User)
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)
    }
    else {
        Write-Host "Node.js and npm are already in the user PATH."
    }
}
else {
    Write-Error "Node.js installation not found at $NodePath."
}

Start-Job -ScriptBlock {
    # Install npm packages globally from shared/npm/packages.json
    $NpmPackagesFile = "shared/npm/packages.json"
    if (Test-Path $NpmPackagesFile) {
        $NpmPackages = Get-Content $NpmPackagesFile | ConvertFrom-Json

        foreach ($Package in $NpmPackages.global) {
            $PackageName = $Package.name
            $PackageVersion = $Package.version

            if ($PackageVersion -eq "latest" -or [string]::IsNullOrEmpty($PackageVersion)) {
                Write-Host "Installing npm package: $PackageName@latest globally..."
                npm install -g $PackageName
            }
            else {
                Write-Host "Installing npm package: $PackageName@$PackageVersion globally..."
                npm install -g "$PackageName@$PackageVersion"
            }
        }
    }
    else {
        Write-Error "Npm packages file $NpmPackagesFile not found."
    }
} | Out-Null

# Work packages which aren't in winget
if ($env:USERDOMAIN -eq "NORTHAMERICA") {

    # Setup IntunePS modules
    if (-not (Get-Module -Name IntunePS)) {
        mkdir tmp
        Push-Location tmp
        Copy-Item \\ecm\Teams\INTUNE\EngineeringSystems\InstallIntunePS.ps1 ./InstallIntunePS.ps1
        ./InstallIntunePS.ps1
        Pop-Location
        Remove-Item tmp -Recurse -Force
        Import-Module IntunePS
    }

    $localAppDataPath = [System.Environment]::GetFolderPath('LocalApplicationData')

    $kustoExplorerPath = "$localAppDataPath\Kusto.Explorer"
    if (-not (Test-Path $kustoExplorerPath)) {
        Start-Process "https://aka.ms/ke"
    }

    $TMTPath = "$localAppDataPath\TMT7"
    if (-not (Test-Path $TMTPath)) {
        Start-Process "https://aka.ms/threatmodelingtool"
    }
}

if (Get-Command -Name "lua5.1" -ErrorAction SilentlyContinue) {
    Write-Host "Lua is already installed."
}
else {
    Write-Host "Lua is not installed. Installing Lua..."
    $LuaBinariesUrl = "https://phoenixnap.dl.sourceforge.net/project/luabinaries/5.1.4/Tools%20Executables/lua5_1_4_Win64_bin.zip?viasf=1"
    $LuaBinariesPath = "$env:TEMP\lua\"
    $LuaRocksUrl = "https://luarocks.github.io/luarocks/releases/luarocks-3.11.1-windows-64.zip"

    New-Item -Path "$LuaBinariesPath" -ItemType Directory -Force
    Invoke-WebRequest -Uri $LuaBinariesUrl -OutFile "$LuaBinariesPath\lua5_1_4_Win64_bin.zip"
    Expand-Archive -Path "$LuaBinariesPath\lua5_1_4_Win64_bin.zip" -DestinationPath "$LuaBinariesPath" -Force

    $LuaBinariesDest = "$env:ProgramFiles\LuaRocks"
    if (-not (Test-Path $LuaBinariesDest)) {
        New-Item -Path $LuaBinariesDest -ItemType Directory
    }
    Copy-Item -Path "$LuaBinariesPath\*.exe" -Destination $LuaBinariesDest -Recurse -Force
    Copy-Item -Path "$LuaBinariesPath\*.dll" -Destination $LuaBinariesDest -Recurse -Force


    Invoke-WebRequest -Uri $LuaRocksUrl -OutFile "$LuaBinariesPath\luarocks-3.11.1-windows-64.zip"
    Expand-Archive -Path "$LuaBinariesPath\luarocks-3.11.1-windows-64.zip" -DestinationPath "$LuaBinariesPath" -Force
    $LuaRocksPath = "$LuaBinariesPath\luarocks-3.11.1-windows-64"
    Copy-Item -Path "$LuaRocksPath\*.exe" -Destination $LuaBinariesDest -Recurse -Force

    $EnvPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)
    if (-not $EnvPath.Contains($LuaBinariesDest)) {
        Write-Host "Adding LuaRocks to the user PATH..."
        [System.Environment]::SetEnvironmentVariable("Path", "$EnvPath;$LuaBinariesDest", [System.EnvironmentVariableTarget]::User)
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)
    }
    else {
        Write-Host "LuaRocks is already in the user PATH."
    }

    Remove-Item -Path "$LuaBinariesPath" -Recurse -Force
}


