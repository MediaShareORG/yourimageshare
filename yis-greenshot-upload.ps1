# YourImageShare - Greenshot upload script
#
# Uploads a captured image to YourImageShare and copies the resulting
# direct link to the clipboard. Written for Windows PowerShell 5.1 (the
# version built into Windows 10/11), so it does not rely on the newer
# `Invoke-RestMethod -Form` parameter.
#
# Setup:
#   1. Set an environment variable YIS_API_KEY with your API key, or save
#      your key as plain text to: %APPDATA%\YourImageShare\api_key.txt
#   2. In Greenshot: Preferences > Destinations, enable "External command",
#      then click "Settings" and add a new command:
#        Command:   powershell.exe
#        Arguments: -ExecutionPolicy Bypass -File "C:\path\to\yis-greenshot-upload.ps1" "%1"
#   3. Set "External command" as your capture destination (or add it
#      alongside your existing ones).

param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath
)

$ApiUrl = "https://yourimageshare.com/api"

$ApiKey = $env:YIS_API_KEY
if (-not $ApiKey) {
    $configFile = Join-Path $env:APPDATA "YourImageShare\api_key.txt"
    if (Test-Path $configFile) {
        $ApiKey = (Get-Content $configFile -Raw).Trim()
    }
}

Add-Type -AssemblyName System.Windows.Forms

function Show-Notification {
    param([string]$Message)
    $notify = New-Object System.Windows.Forms.NotifyIcon
    $notify.Icon = [System.Drawing.SystemIcons]::Information
    $notify.Visible = $true
    $notify.ShowBalloonTip(4000, "YourImageShare", $Message, [System.Windows.Forms.ToolTipIcon]::Info)
    Start-Sleep -Seconds 4
    $notify.Dispose()
}

if (-not $ApiKey) {
    Show-Notification "No API key set. See the top of yis-greenshot-upload.ps1 for setup."
    exit 1
}

if (-not (Test-Path $FilePath)) {
    Show-Notification "File not found: $FilePath"
    exit 1
}

Add-Type -AssemblyName System.Net.Http

$httpClient = New-Object System.Net.Http.HttpClient
$httpClient.DefaultRequestHeaders.Add("X-API-Key", $ApiKey)

$fileStream = [System.IO.File]::OpenRead($FilePath)
try {
    $content = New-Object System.Net.Http.MultipartFormDataContent
    $fileContent = New-Object System.Net.Http.StreamContent($fileStream)
    $fileContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("application/octet-stream")
    $content.Add($fileContent, "uploads", [System.IO.Path]::GetFileName($FilePath))

    $response = $httpClient.PostAsync($ApiUrl, $content).GetAwaiter().GetResult()
    $body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
}
finally {
    $fileStream.Close()
    $httpClient.Dispose()
}

$json = $null
try {
    $json = $body | ConvertFrom-Json
}
catch {
    Show-Notification "Upload failed: unexpected server response."
    exit 1
}

if ($null -eq $json -or $json.type -ne "success") {
    $errorMessage = if ($json -and $json.errors) { $json.errors } else { "unknown error" }
    Show-Notification "Upload failed: $errorMessage"
    exit 1
}

$url = $json.data.src
Set-Clipboard -Value $url
Show-Notification "Uploaded! Link copied to clipboard:`n$url"
