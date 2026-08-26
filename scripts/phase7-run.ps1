$ErrorActionPreference = 'Stop'

$mt5Dir = $env:MT5_DIR
$workspace = $env:GITHUB_WORKSPACE
$evidence = Join-Path $workspace 'phase7-evidence'

New-Item -ItemType Directory -Force -Path $evidence | Out-Null
New-Item -ItemType Directory -Force -Path "$evidence\Tester-Logs" | Out-Null
New-Item -ItemType Directory -Force -Path "$evidence\MT5-Logs" | Out-Null

Write-Host '========== PHASE 7 START =========='

# ------------------------------------------------------------
# FIND MT5 TERMINAL
# ------------------------------------------------------------

$terminal = Get-ChildItem -Path $mt5Dir -Filter 'terminal64.exe' -File -Recurse -ErrorAction SilentlyContinue |
    Select-Object -First 1

if ($null -eq $terminal) {
    $terminal = Get-ChildItem -Path 'C:\' -Filter 'terminal64.exe' -File -Recurse -ErrorAction SilentlyContinue |
        Select-Object -First 1
}

if ($null -eq $terminal) {
    throw 'terminal64.exe could not be found.'
}

$terminalPath = $terminal.FullName
$terminalDir = Split-Path $terminalPath -Parent

Write-Host "MT5 TERMINAL: $terminalPath"

# ------------------------------------------------------------
# FIND METAEDITOR
# ------------------------------------------------------------

$editor = Get-ChildItem -Path $mt5Dir -Filter 'metaeditor64.exe' -File -Recurse -ErrorAction SilentlyContinue |
    Select-Object -First 1

if ($null -eq $editor) {
    throw 'metaeditor64.exe could not be found.'
}

$editorPath = $editor.FullName
Write-Host "MT5 EDITOR: $editorPath"

# ------------------------------------------------------------
# FIND SOURCE
# ------------------------------------------------------------

$source = Get-ChildItem `
    -Path $workspace `
    -Filter $env:BOT_SOURCE_NAME `
    -File `
    -Recurse `
    -ErrorAction SilentlyContinue |
    Select-Object -First 1

if ($null -eq $source) {
    throw "SOURCE NOT FOUND: $env:BOT_SOURCE_NAME"
}

Write-Host "SOURCE: $($source.FullName)"

# ------------------------------------------------------------
# PREPARE EXPERT DIRECTORY
# ------------------------------------------------------------

$expertDir = Join-Path $mt5Dir 'MQL5\Experts\KingsBot'

New-Item -ItemType Directory -Force -Path $expertDir | Out-Null

Copy-Item `
    -Path (Join-Path (Split-Path $source.FullName -Parent) '*') `
    -Destination $expertDir `
    -Recurse `
    -Force

$expertSource = Join-Path $expertDir $env:BOT_SOURCE_NAME

if (-not (Test-Path -LiteralPath $expertSource)) {
    throw "EA source was not copied: $expertSource"
}

# ------------------------------------------------------------
# COMPILE
# ------------------------------------------------------------

Write-Host '========== COMPILING KING''S BOT =========='

$compileLog = Join-Path $evidence 'compile.log'

& $editorPath '/portable' "/compile:$expertSource" "/log:$compileLog"

if ($LASTEXITCODE -ne 0) {
    throw "MetaEditor compilation failed with exit code $LASTEXITCODE"
}

if (Test-Path -LiteralPath $compileLog) {
    Copy-Item $compileLog "$evidence\compile.log" -Force
}

# ------------------------------------------------------------
# VERIFY EX5
# ------------------------------------------------------------

Write-Host '========== VERIFYING EX5 =========='

$finalEx5 = Join-Path $expertDir $env:EX5_NAME

$foundEx5 = Get-ChildItem `
    -Path $mt5Dir `
    -Filter $env:EX5_NAME `
    -File `
    -Recurse `
    -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if ($null -eq $foundEx5) {
    throw "EX5 NOT FOUND: $env:EX5_NAME"
}

Write-Host "FOUND EX5: $($foundEx5.FullName)"
Write-Host "SIZE: $($foundEx5.Length) bytes"

$foundPath = [System.IO.Path]::GetFullPath($foundEx5.FullName)
$finalPath = [System.IO.Path]::GetFullPath($finalEx5)

if ($foundPath -ne $finalPath) {
    Copy-Item -LiteralPath $foundEx5.FullName -Destination $finalEx5 -Force
}
else {
    Write-Host 'EX5 already in final location.'
}

# ------------------------------------------------------------
# CHECK TESTER CREDENTIALS
# ------------------------------------------------------------

if ([string]::IsNullOrWhiteSpace($env:MT5_LOGIN)) {
    throw 'MT5_LOGIN GitHub secret is missing.'
}

if ([string]::IsNullOrWhiteSpace($env:MT5_SERVER)) {
    throw 'MT5_SERVER GitHub secret is missing.'
}

if ([string]::IsNullOrWhiteSpace($env:MT5_PASSWORD)) {
    throw 'MT5_PASSWORD GitHub secret is missing.'
}

# ------------------------------------------------------------
# CREATE TESTER CONFIG
# ------------------------------------------------------------

Write-Host '========== CREATING TESTER CONFIG =========='

$config = Join-Path $mt5Dir 'KingsBot_Phase7_Tester.ini'

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
ExecutionMode=0
Report=KingsBot_Phase7_Tester
ReplaceReport=1
ShutdownTerminal=1
Visual=0
UseCloud=0
"@ | Set-Content -LiteralPath $config -Encoding ASCII

Copy-Item -LiteralPath $config -Destination "$evidence\KingsBot_Phase7_Tester.ini" -Force

# ------------------------------------------------------------
# START MT5
# ------------------------------------------------------------

Write-Host '========== STARTING MT5 TESTER =========='
Write-Host "MT5 TERMINAL: $terminalPath"
Write-Host "TESTER CONFIG: $config"
Write-Host "EA: $finalEx5"

Get-Process terminal64,metatester64,metatester -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

Start-Sleep -Seconds 3

$arguments = @(
    '/portable'
    "/config:$config"
    "/login:$env:MT5_LOGIN"
)

$process = Start-Process `
    -FilePath $terminalPath `
    -ArgumentList $arguments `
    -WorkingDirectory $terminalDir `
    -PassThru

Write-Host "MT5 PID: $($process.Id)"

# ------------------------------------------------------------
# WAIT FOR REPORT
# ------------------------------------------------------------

$report = $null
$elapsed = 0

while ($elapsed -lt 1200) {

    Start-Sleep -Seconds 10
    $elapsed += 10

    $report = Get-ChildItem `
        -Path $mt5Dir `
        -Filter 'KingsBot_Phase7_Tester*.htm' `
        -File `
        -Recurse `
        -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($null -ne $report -and $report.Length -gt 500) {
        Write-Host '========== TESTER REPORT FOUND =========='
        Write-Host "REPORT: $($report.FullName)"

        Copy-Item `
            -LiteralPath $report.FullName `
            -Destination "$evidence\KingsBot_Phase7_Tester.htm" `
            -Force

        break
    }

    if (($elapsed % 30) -eq 0) {

        Write-Host "Tester running: $elapsed seconds"

        $testerLog = Get-ChildItem `
            -Path "$mt5Dir\Tester\logs" `
            -Filter '*.log' `
            -File `
            -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

        if ($null -ne $testerLog) {

            Copy-Item `
                -LiteralPath $testerLog.FullName `
                -Destination "$evidence\Tester-Logs\latest.log" `
                -Force

            $logText = Get-Content `
                -LiteralPath $testerLog.FullName `
                -Raw `
                -ErrorAction SilentlyContinue

            if ($logText -match 'account is not specified') {
                throw 'MT5 Tester rejected the account configuration.'
            }

            if ($logText -match 'invalid account|invalid password|authorization failed') {
                throw 'MT5 Tester rejected the supplied account credentials.'
            }
        }
    }
}

# ------------------------------------------------------------
# FINAL RESULT
# ------------------------------------------------------------

if ($null -eq $report) {
    throw 'MT5 Strategy Tester did not produce a report.'
}

# ------------------------------------------------------------
# COLLECT LOGS
# ------------------------------------------------------------

if (Test-Path -LiteralPath "$mt5Dir\logs") {
    Copy-Item `
        -Path "$mt5Dir\logs\*" `
        -Destination "$evidence\MT5-Logs" `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue
}

if (Test-Path -LiteralPath "$mt5Dir\Tester\logs") {
    Copy-Item `
        -Path "$mt5Dir\Tester\logs\*" `
        -Destination "$evidence\Tester-Logs" `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue
}

Write-Host '========== PHASE 7 COMPLETE =========$ErrorActionPreference = 'Stop'

$mt5Dir = $env:MT5_DIR
$workspace = $env:GITHUB_WORKSPACE
$evidence = Join-Path $workspace 'phase7-evidence'

New-Item -ItemType Directory -Force -Path $evidence | Out-Null
New-Item -ItemType Directory -Force -Path "$evidence\Tester-Logs" | Out-Null
New-Item -ItemType Directory -Force -Path "$evidence\MT5-Logs" | Out-Null

Write-Host '========== PHASE 7 START =========='

# ------------------------------------------------------------
# FIND MT5 TERMINAL
# ------------------------------------------------------------

$terminal = Get-ChildItem -Path $mt5Dir -Filter 'terminal64.exe' -File -Recurse -ErrorAction SilentlyContinue |
    Select-Object -First 1

if ($null -eq $terminal) {
    $terminal = Get-ChildItem -Path 'C:\' -Filter 'terminal64.exe' -File -Recurse -ErrorAction SilentlyContinue |
        Select-Object -First 1
}

if ($null -eq $terminal) {
    throw 'terminal64.exe could not be found.'
}

$terminalPath = $terminal.FullName
$terminalDir = Split-Path $terminalPath -Parent

Write-Host "MT5 TERMINAL: $terminalPath"

# ------------------------------------------------------------
# FIND METAEDITOR
# ------------------------------------------------------------

$editor = Get-ChildItem -Path $mt5Dir -Filter 'metaeditor64.exe' -File -Recurse -ErrorAction SilentlyContinue |
    Select-Object -First 1

if ($null -eq $editor) {
    throw 'metaeditor64.exe could not be found.'
}

$editorPath = $editor.FullName
Write-Host "MT5 EDITOR: $editorPath"

# ------------------------------------------------------------
# FIND SOURCE
# ------------------------------------------------------------

$source = Get-ChildItem `
    -Path $workspace `
    -Filter $env:BOT_SOURCE_NAME `
    -File `
    -Recurse `
    -ErrorAction SilentlyContinue |
    Select-Object -First 1

if ($null -eq $source) {
    throw "SOURCE NOT FOUND: $env:BOT_SOURCE_NAME"
}

Write-Host "SOURCE: $($source.FullName)"

# ------------------------------------------------------------
# PREPARE EXPERT DIRECTORY
# ------------------------------------------------------------

$expertDir = Join-Path $mt5Dir 'MQL5\Experts\KingsBot'

New-Item -ItemType Directory -Force -Path $expertDir | Out-Null

Copy-Item `
    -Path (Join-Path (Split-Path $source.FullName -Parent) '*') `
    -Destination $expertDir `
    -Recurse `
    -Force

$expertSource = Join-Path $expertDir $env:BOT_SOURCE_NAME

if (-not (Test-Path -LiteralPath $expertSource)) {
    throw "EA source was not copied: $expertSource"
}

# ------------------------------------------------------------
# COMPILE
# ------------------------------------------------------------

Write-Host '========== COMPILING KING''S BOT =========='

$compileLog = Join-Path $evidence 'compile.log'

& $editorPath '/portable' "/compile:$expertSource" "/log:$compileLog"

if ($LASTEXITCODE -ne 0) {
    throw "MetaEditor compilation failed with exit code $LASTEXITCODE"
}

if (Test-Path -LiteralPath $compileLog) {
    Copy-Item $compileLog "$evidence\compile.log" -Force
}

# ------------------------------------------------------------
# VERIFY EX5
# ------------------------------------------------------------

Write-Host '========== VERIFYING EX5 =========='

$finalEx5 = Join-Path $expertDir $env:EX5_NAME

$foundEx5 = Get-ChildItem `
    -Path $mt5Dir `
    -Filter $env:EX5_NAME `
    -File `
    -Recurse `
    -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if ($null -eq $foundEx5) {
    throw "EX5 NOT FOUND: $env:EX5_NAME"
}

Write-Host "FOUND EX5: $($foundEx5.FullName)"
Write-Host "SIZE: $($foundEx5.Length) bytes"

$foundPath = [System.IO.Path]::GetFullPath($foundEx5.FullName)
$finalPath = [System.IO.Path]::GetFullPath($finalEx5)

if ($foundPath -ne $finalPath) {
    Copy-Item -LiteralPath $foundEx5.FullName -Destination $finalEx5 -Force
}
else {
    Write-Host 'EX5 already in final location.'
}

# ------------------------------------------------------------
# CHECK TESTER CREDENTIALS
# ------------------------------------------------------------

if ([string]::IsNullOrWhiteSpace($env:MT5_LOGIN)) {
    throw 'MT5_LOGIN GitHub secret is missing.'
}

if ([string]::IsNullOrWhiteSpace($env:MT5_SERVER)) {
    throw 'MT5_SERVER GitHub secret is missing.'
}

if ([string]::IsNullOrWhiteSpace($env:MT5_PASSWORD)) {
    throw 'MT5_PASSWORD GitHub secret is missing.'
}

# ------------------------------------------------------------
# CREATE TESTER CONFIG
# ------------------------------------------------------------

Write-Host '========== CREATING TESTER CONFIG =========='

$config = Join-Path $mt5Dir 'KingsBot_Phase7_Tester.ini'

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
ExecutionMode=0
Report=KingsBot_Phase7_Tester
ReplaceReport=1
ShutdownTerminal=1
Visual=0
UseCloud=0
"@ | Set-Content -LiteralPath $config -Encoding ASCII

Copy-Item -LiteralPath $config -Destination "$evidence\KingsBot_Phase7_Tester.ini" -Force

# ------------------------------------------------------------
# START MT5
# ------------------------------------------------------------

Write-Host '========== STARTING MT5 TESTER =========='
Write-Host "MT5 TERMINAL: $terminalPath"
Write-Host "TESTER CONFIG: $config"
Write-Host "EA: $finalEx5"

Get-Process terminal64,metatester64,metatester -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

Start-Sleep -Seconds 3

$arguments = @(
    '/portable'
    "/config:$config"
    "/login:$env:MT5_LOGIN"
)

$process = Start-Process `
    -FilePath $terminalPath `
    -ArgumentList $arguments `
    -WorkingDirectory $terminalDir `
    -PassThru

Write-Host "MT5 PID: $($process.Id)"

# ------------------------------------------------------------
# WAIT FOR REPORT
# ------------------------------------------------------------

$report = $null
$elapsed = 0

while ($elapsed -lt 1200) {

    Start-Sleep -Seconds 10
    $elapsed += 10

    $report = Get-ChildItem `
        -Path $mt5Dir `
        -Filter 'KingsBot_Phase7_Tester*.htm' `
        -File `
        -Recurse `
        -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($null -ne $report -and $report.Length -gt 500) {
        Write-Host '========== TESTER REPORT FOUND =========='
        Write-Host "REPORT: $($report.FullName)"

        Copy-Item `
            -LiteralPath $report.FullName `
            -Destination "$evidence\KingsBot_Phase7_Tester.htm" `
            -Force

        break
    }

    if (($elapsed % 30) -eq 0) {

        Write-Host "Tester running: $elapsed seconds"

        $testerLog = Get-ChildItem `
            -Path "$mt5Dir\Tester\logs" `
            -Filter '*.log' `
            -File `
            -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

        if ($null -ne $testerLog) {

            Copy-Item `
                -LiteralPath $testerLog.FullName `
                -Destination "$evidence\Tester-Logs\latest.log" `
                -Force

            $logText = Get-Content `
                -LiteralPath $testerLog.FullName `
                -Raw `
                -ErrorAction SilentlyContinue

            if ($logText -match 'account is not specified') {
                throw 'MT5 Tester rejected the account configuration.'
            }

            if ($logText -match 'invalid account|invalid password|authorization failed') {
                throw 'MT5 Tester rejected the supplied account credentials.'
            }
        }
    }
}

# ------------------------------------------------------------
# FINAL RESULT
# ------------------------------------------------------------

if ($null -eq $report) {
    throw 'MT5 Strategy Tester did not produce a report.'
}

# ------------------------------------------------------------
# COLLECT LOGS
# ------------------------------------------------------------

if (Test-Path -LiteralPath "$mt5Dir\logs") {
    Copy-Item `
        -Path "$mt5Dir\logs\*" `
        -Destination "$evidence\MT5-Logs" `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue
}

if (Test-Path -LiteralPath "$mt5Dir\Tester\logs") {
    Copy-Item `
        -Path "$mt5Dir\Tester\logs\*" `
        -Destination "$evidence\Tester-Logs" `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue
}

Write-Host '========== PHASE 7 COMPLETE ==========' 
