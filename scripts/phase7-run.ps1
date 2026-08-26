$ErrorActionPreference = 'Stop'

$mt5 = 'C:\MT5'
$workspace = $env:GITHUB_WORKSPACE
$evidence = Join-Path $workspace 'phase7-evidence'

New-Item -ItemType Directory -Force -Path $evidence | Out-Null
New-Item -ItemType Directory -Force -Path "$evidence\Tester-Logs" | Out-Null

Write-Host '========== PHASE 7 TESTER =========='

# Find MT5
$terminal = Get-ChildItem -Path $mt5 -Filter 'terminal64.exe' -File -Recurse -ErrorAction SilentlyContinue |
    Select-Object -First 1

if ($null -eq $terminal) {
    throw 'terminal64.exe not found under C:\MT5'
}

$terminalPath = $terminal.FullName
$terminalDir = Split-Path $terminalPath -Parent

Write-Host "MT5 TERMINAL: $terminalPath"

# Find EX5
$ex5 = Get-ChildItem -Path $mt5 -Filter 'KingsBot_Phase6_Integration.ex5' -File -Recurse -ErrorAction SilentlyContinue |
    Select-Object -First 1

if ($null -eq $ex5) {
    throw 'KingsBot_Phase6_Integration.ex5 not found.'
}

Write-Host "EA: $($ex5.FullName)"
Write-Host "SIZE: $($ex5.Length) bytes"

# Required credentials
if ([string]::IsNullOrWhiteSpace($env:MT5_LOGIN)) {
    throw 'MT5_LOGIN secret is missing.'
}

if ([string]::IsNullOrWhiteSpace($env:MT5_SERVER)) {
    throw 'MT5_SERVER secret is missing.'
}

if ([string]::IsNullOrWhiteSpace($env:MT5_PASSWORD)) {
    throw 'MT5_PASSWORD secret is missing.'
}

# Tester configuration
$config = Join-Path $mt5 'KingsBot_Phase7_Tester.ini'

@"
[Common]
Login=$env:MT5_LOGIN
Password=$env:MT5_PASSWORD
Server=$env:MT5_SERVER

[Tester]
Expert=KingsBot\KingsBot_Phase6_Integration.ex5
Symbol=EURUSD
Period=M15
Model=0
Optimization=0
FromDate=2025.01.01
ToDate=2026.08.01
ForwardMode=0
Deposit=10000
Currency=USD
Leverage=1:100
Report=KingsBot_Phase7_Tester
ReplaceReport=1
ShutdownTerminal=1
Visual=0
UseCloud=0
"@ | Set-Content -Path $config -Encoding ASCII

Copy-Item $config "$evidence\KingsBot_Phase7_Tester.ini" -Force

Write-Host '========== STARTING MT5 TESTER =========='
Write-Host "CONFIG: $config"

Get-Process terminal64,metatester64,metatester -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

Start-Sleep -Seconds 3

$process = Start-Process `
    -FilePath $terminalPath `
    -ArgumentList @('/portable', "/config:$config", "/login:$env:MT5_LOGIN") `
    -WorkingDirectory $terminalDir `
    -PassThru

Write-Host "MT5 PID: $($process.Id)"

# Wait up to 20 minutes
for ($i = 1; $i -le 120; $i++) {

    Start-Sleep -Seconds 10

    $report = Get-ChildItem `
        -Path $mt5 `
        -Filter 'KingsBot_Phase7_Tester*.htm' `
        -File `
        -Recurse `
        -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($null -ne $report -and $report.Length -gt 500) {

        Write-Host '========== TESTER REPORT FOUND =========='
        Write-Host "REPORT: $($report.FullName)"
        Write-Host "SIZE: $($report.Length) bytes"

        Copy-Item `
            $report.FullName `
            "$evidence\KingsBot_Phase7_Tester.htm" `
            -Force

        Write-Host '========== PHASE 7 TESTER SUCCESS =========='
        exit 0
    }

    if (($i % 3) -eq 0) {

        $log = Get-ChildItem `
            -Path "$mt5\Tester\logs" `
            -Filter '*.log' `
            -File `
            -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

        if ($null -ne $log) {

            Copy-Item `
                $log.FullName `
                "$evidence\Tester-Logs\latest.log" `
                -Force

            $text = Get-Content $log.FullName -Raw -ErrorAction SilentlyContinue

            if ($text -match 'account is not specified') {
                throw 'MT5 Tester rejected the account configuration.'
            }

            if ($text -match 'invalid account|invalid password|authorization failed') {
                throw 'MT5 Tester rejected the supplied credentials.'
            }
        }

        Write-Host "Tester running: $($i * 10) seconds"
    }
}

throw 'MT5 Strategy Tester did not produce a report within 20 minutes.'
