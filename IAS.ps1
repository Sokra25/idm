$ErrorActionPreference = "Stop"

# Enable TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = `
    [Net.ServicePointManager]::SecurityProtocol -bor `
    [Net.SecurityProtocolType]::Tls12

$DownloadURL = 'https://raw.githubusercontent.com/lstprjct/IDM-Activation-Script/main/IAS.cmd'

$rand = Get-Random -Maximum 99999999

$isAdmin = [bool](
    [Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544'
)

$FilePath = if ($isAdmin) {
    "$env:SystemRoot\Temp\IAS_$rand.cmd"
} else {
    "$env:TEMP\IAS_$rand.cmd"
}

try {
    $response = Invoke-WebRequest -Uri $DownloadURL -UseBasicParsing
}
catch {
    Write-Host "Download failed: $($_.Exception.Message)"
    exit 1
}

if ([string]::IsNullOrWhiteSpace($response.Content)) {
    Write-Host "Downloaded file is empty."
    exit 1
}

$ScriptArgs = "$args"
$prefix = "@REM $rand`r`n"
$content = $prefix + $response.Content

Set-Content -Path $FilePath -Value $content -Encoding ASCII

Start-Process -FilePath $FilePath -ArgumentList $ScriptArgs -Wait

$FilePaths = @(
    "$env:TEMP\IAS*.cmd",
    "$env:SystemRoot\Temp\IAS*.cmd"
)

foreach ($Path in $FilePaths) {
    Get-Item $Path -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue
}
