$ErrorActionPreference = 'Stop'

$workspace = $env:GITHUB_WORKSPACE
$mt5Dir = $env:MT5_DIR
$evidence = Join-Path $workspace 'phase7-evidence'

New-Item -ItemType Directory -Force -Path $evidence | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $evidence 'MT5-Logs') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $evidence 'Tester-Logs') | Out-Null

Write-Host '========== PHASE 7 START =========='

# ============================================================
# 1. FIND OR INSTALL MT5
# ============================================================

Write-Host '========== LOCATING MT5 =========='

$terminal = Get-ChildItem `
    -Path $mt5Dir `
    -Filter 'terminal64.exe' `
    -File `
    -Recurse `
    -ErrorAction SilentlyContinue |
    Select-Object -First 1

if ($null -eq $terminal) {

    Write-Host 'MT5 not found under C:\MT5.'
    Write-Host '========== INSTALLING MT5 =========='

    $installer = Join-Path $env:RUNNER_TEMP 'mt5setup.exe'

    Invoke-WebRequest `
        -Uri 'https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe' `
        -OutFile $installer `
        -UseBasicParsing

    if (-not (Test-Path -LiteralPath $installer)) {
        throw 'MT5 installer download failed.'
    }

    New-Item `
        -ItemType Directory `
        -Force `
        -Path $mt5Dir |
        Out-Null

    $installerProcess = Start-Process `
        -FilePath $installer `
        -ArgumentList @('/auto', "/path:$mt5Dir") `
        -Wait `
        -PassThru

    Write-Host "MT5 installer exit code: $($installerProcess.ExitCode)"

    Start-Sleep -Seconds 10

    $terminal = Get-ChildItem `
        -Path $mt5Dir `
        -Filter 'terminal64.exe' `
        -File `
        -Recurse `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1
}

if ($null -eq $terminal) {

    Write-Host 'MT5 not found in C:\MT5.'
    Write-Host 'Searching runner for terminal64.exe.'

    $terminal = Get-ChildItem `
        -Path 'C:\' `
        -Filter 'terminal64.exe' `
        -File `
        -Recurse `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1
}

if ($null -eq $terminal) {
    throw 'terminal64.exe could not be found.'
}

$terminalPath = $terminal.FullName
$terminalDir = Split-Path -Path $terminalPath -Parent

Write-Host "MT5 TERMINAL: $terminalPath"

$editor = Get-ChildItem `
    -Path $terminalDir `
    -Filter 'metaeditor64.exe' `
    -File `
    -Recurse `
    -ErrorAction SilentlyContinue |
    Select-Object -First 1

if ($null -eq $editor) {

    $editor = Get-ChildItem `
        -Path $mt5Dir `
        -Filter 'metaeditor64.exe' `
        -File `
        -Recurse `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1
}

if ($null -eq $editor) {
    throw 'metaeditor64.exe could not be found.'
}

$editorPath = $editor.FullName

Write-Host "MT5 EDITOR: $editorPath"

# ============================================================
# 2. FIND SOURCE
# ============================================================

Write-Host '========== FINDING KING''S BOT SOURCE =========='

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

# ============================================================
# 3. PREPARE EA
# ============================================================

$expertDir = Join-Path $mt5Dir 'MQL5\Experts\KingsBot'

New-Item `
    -ItemType Directory `
    -Force `
    -Path $expertDir |
    Out-Null

$sourceDir = Split-Path -Path $source.FullName -Parent

Copy-Item `
    -Path (Join-Path $sourceDir '*') `
    -Destination $expertDir `
    -Recurse `
    -Force

$expertSource = Join-Path $expertDir $env:BOT_SOURCE_NAME

if (-not (Test-Path -LiteralPath $expertSource)) {
    throw "EA source was not copied: $expertSource"
}

# ============================================================
# 4. COMPILE
# ============================================================

Write-Host '========== COMPILING KING''S BOT =========='

$compileLog = Join-Path $evidence 'compile.log'

& $editorPath `
    '/portable' `
    "/compile:$expertSource" `
    "/log:$compileLog"

$compileExit = $LASTEXITCODE

Write-Host "MetaEditor exit code: $compileExit"

if (Test-Path -LiteralPath $compileLog) {
    Get-Content -LiteralPath $compileLog
}

if ($compileExit -ne 0) {
    throw "MetaEditor compilation failed with exit code $compileExit"
}

# ============================================================
# 5. VERIFY EX5
# ============================================================

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

    Copy-Item `
        -LiteralPath $foundEx5.FullName `
        -Destination $finalEx5 `
        -Force
}
else {
    Write-Host 'EX5 already in final location; no copy required.'
}

if (-not (Test-Path -LiteralPath $final
