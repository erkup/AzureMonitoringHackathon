param (
    [string]$SQLServerName, 
    [string]$SQLpassword
)

# Install Microsoft .Net Core 2.1.0
$exeDotNetTemp = [System.IO.Path]::GetTempPath().ToString() + "dotnet-sdk-2.1.300-win-x64.exe"
if (Test-Path $exeDotNetTemp) { Remove-Item $exeDotNetTemp -Force }
# Download file from Microsoft Downloads and save to local temp file (%LocalAppData%/Temp/2)
$exeFileNetCore = [System.IO.Path]::GetTempFileName() | Rename-Item -NewName "dotnet-sdk-2.1.300-win-x64.exe" -PassThru
Invoke-WebRequest -Uri "https://download.microsoft.com/download/8/8/5/88544F33-836A-49A5-8B67-451C24709A8F/dotnet-sdk-2.1.300-win-x64.exe" -OutFile $exeFileNetCore
# Run the exe with arguments
$proc = (Start-Process -FilePath $exeFileNetCore.Name.ToString() -ArgumentList ('/install','/quiet') -WorkingDirectory $exeFileNetCore.Directory.ToString() -Passthru)
$proc | Wait-Process

# Disable Internet Explorer Enhanced Security Configuration
$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0 -Force
Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0 -Force
Stop-Process -Name Explorer -Force

# Download eShopOnWeb to c:\eShopOnWeb and extract contents
$zipFileeShopTemp = [System.IO.Path]::GetTempPath().ToString() + "eShopOnWeb-master.zip"
if (Test-Path $zipFileeShopTemp) { Remove-Item $zipFileeShopTemp -Force }
$zipFileeShop = [System.IO.Path]::GetTempFileName() | Rename-Item -NewName "eShopOnWeb-master.zip" -PassThru
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri "https://github.com/dotnet-architecture/eShopOnWeb/archive/master.zip" -OutFile $zipFileeShop
$BackUpPath = $zipFileeShop.FullName
New-Item -Path c:\eshoponweb -ItemType directory -Force
$Destination = "C:\eshoponweb"
Add-Type -assembly "system.io.compression.filesystem" -PassThru
[io.compression.zipfile]::ExtractToDirectory($BackUpPath, $destination)

#Update eShopOnWeb project to use SQL Server
#modify Startup.cs
$Startupfile = 'C:\eshoponweb\eShopOnWeb-master\src\Web\Startup.cs'
$find = '            ConfigureInMemoryDatabases(services);'
$replace = '            //ConfigureInMemoryDatabases(services);'
(Get-Content $Startupfile).replace($find, $replace) | Set-Content $Startupfile -Force
$find1 = '            // ConfigureProductionServices(services);'
$replace1 = '            ConfigureProductionServices(services);'
(Get-Content $Startupfile).replace($find1, $replace1) | Set-Content $Startupfile -Force

#modify appsettings.json
$SQLusername = "sqladmin"

$appsettingsfile = 'C:\eshoponweb\eShopOnWeb-master\src\Web\appsettings.json'
$find = '    "CatalogConnection": "Server=(localdb)\\mssqllocaldb;Integrated Security=true;Initial Catalog=Microsoft.eShopOnWeb.CatalogDb;",'
$replace = '    "CatalogConnection": "Server=' + $SQLServername + ';Integrated Security=false;User ID=' + $SQLusername + ';Password=' + $SQLpassword + ';Initial Catalog=Microsoft.eShopOnWeb.CatalogDb;",'
(Get-Content $appsettingsfile).replace($find, $replace) | Set-Content $appsettingsfile -Force
$find1 = '    "IdentityConnection": "Server=(localdb)\\mssqllocaldb;Integrated Security=true;Initial Catalog=Microsoft.eShopOnWeb.Identity;"'
$replace1 = '    "IdentityConnection": "Server=' + $SQLServername + ';Integrated Security=false;User ID=' + $SQLusername + ';Password=' + $SQLpassword + ';Initial Catalog=Microsoft.eShopOnWeb.Identity;"'
(Get-Content $appsettingsfile).replace($find1, $replace1) | Set-Content $appsettingsfile -Force
