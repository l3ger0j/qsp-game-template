# Installs everything this game folder needs on Windows, into tools\:
# a portable VSCodium (the editor) with the QSP extension, the classic QSP
# player and qSpider. Running it again updates to the versions in
# versions.env and keeps the author's editor settings and game.
#
#   powershell -ExecutionPolicy Bypass -File setup\setup.ps1 [-Lang ru|en] [-Yes] [-NoQspider] [-QspVsix FILE]
#
# Windows PowerShell 5.1 (in every Windows 10/11). Saved as UTF-8 with a
# BOM: without it PowerShell 5.1 reads the Russian messages as ANSI.
param(
  [ValidateSet('', 'ru', 'en')][string]$Lang = '',
  [switch]$Yes,
  [switch]$NoQspider,
  [string]$QspVsix = ''
)
$ErrorActionPreference = 'Stop'
# Invoke-WebRequest is many times slower while drawing its progress bar.
$ProgressPreference = 'SilentlyContinue'
# The editor's CLI prints Node deprecation warnings that only alarm authors.
$env:NODE_NO_WARNINGS = '1'
# Run from another VS Code's terminal, these would make the editor's CLI
# install extensions through that other editor.
Get-ChildItem env: | Where-Object { $_.Name -eq 'ELECTRON_RUN_AS_NODE' -or $_.Name -like 'VSCODE_*' } |
  ForEach-Object { Remove-Item "env:$($_.Name)" }
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [Text.Encoding]::UTF8
Add-Type -AssemblyName System.IO.Compression.FileSystem

$Root = Split-Path -Parent $PSScriptRoot
$Tools = Join-Path $Root 'tools'
$Downloads = Join-Path $Tools 'downloads'
New-Item -ItemType Directory -Force -Path $Downloads | Out-Null
Start-Transcript -Path (Join-Path $Tools 'setup.log') -Append | Out-Null

# ── Language ────────────────────────────────────────────────────────
$LangFile = Join-Path $Tools 'lang.txt'
if (-not $Lang -and (Test-Path $LangFile)) { $Lang = (Get-Content $LangFile -Raw).Trim() }
if (-not $Lang) {
  if ($Yes) { $Lang = 'en' } else {
    Write-Host 'Выберите язык / Choose a language:'
    Write-Host '  1 — Русский'
    Write-Host '  2 — English'
    $answer = Read-Host '>'
    $Lang = if ($answer -match '^(2|en|e)$') { 'en' } else { 'ru' }
  }
}
Set-Content -Path $LangFile -Value $Lang -Encoding ASCII

function T([string]$ru, [string]$en) { if ($Lang -eq 'ru') { $ru } else { $en } }

function Pause-IfInteractive {
  if (-not $Yes) { Read-Host (T 'Нажмите Enter, чтобы завершить' 'Press Enter to finish') | Out-Null }
}

function Fail([string]$ru, [string]$en) {
  Write-Host ''
  Write-Host (T "Установка не удалась: $ru" "Setup failed: $en") -ForegroundColor Red
  Write-Host (T "Подробности записаны в файл: $Tools\setup.log" "Details are in this file: $Tools\setup.log")
  Stop-Transcript | Out-Null
  Pause-IfInteractive
  exit 1
}

# ── Versions ────────────────────────────────────────────────────────
$V = @{}
foreach ($line in Get-Content (Join-Path $PSScriptRoot 'versions.env')) {
  if ($line -match '^\s*([A-Z0-9_]+)=(.*)$') { $V[$Matches[1]] = $Matches[2].Trim() }
}

# The file's path in tools\downloads, reused when already there and intact.
function Get-Download([string]$url, [string]$sum) {
  $file = Join-Path $Downloads ([IO.Path]::GetFileName(([Uri]$url).AbsolutePath))
  if ((Test-Path $file) -and (-not $sum -or (Get-FileHash $file -Algorithm SHA256).Hash -eq $sum)) { return $file }
  Write-Host (T "Скачиваю $([IO.Path]::GetFileName($file))…" "Downloading $([IO.Path]::GetFileName($file))…")
  try {
    Invoke-WebRequest -Uri $url -OutFile "$file.part" -UseBasicParsing
  } catch {
    Fail "не удалось скачать $url. Проверьте подключение к интернету и запустите установку ещё раз." `
         "could not download $url. Check the internet connection and run the setup again."
  }
  if ($sum -and (Get-FileHash "$file.part" -Algorithm SHA256).Hash -ne $sum) {
    Remove-Item "$file.part"
    Fail "файл $([IO.Path]::GetFileName($file)) скачался повреждённым. Запустите установку ещё раз." `
         "$([IO.Path]::GetFileName($file)) arrived damaged. Run the setup again."
  }
  Move-Item -Force "$file.part" $file
  return $file
}

function Test-Installed([string]$name, [string]$version) {
  $marker = Join-Path $Tools "$name\.version"
  (Test-Path $marker) -and ((Get-Content $marker -Raw).Trim() -eq $version)
}

function Set-Installed([string]$name, [string]$version) {
  Set-Content -Path (Join-Path $Tools "$name\.version") -Value $version -Encoding ASCII
}

try {
  # ── Editor ────────────────────────────────────────────────────────
  Write-Host (T "1/5. Редактор VSCodium $($V.VSCODIUM_VERSION)" "1/5. VSCodium editor $($V.VSCODIUM_VERSION)")
  $EditorDir = Join-Path $Tools 'vscodium'
  $Data = Join-Path $EditorDir 'data'
  $Cli = Join-Path $EditorDir 'bin\codium.cmd'
  if (-not (Test-Installed 'vscodium' $V.VSCODIUM_VERSION)) {
    $archive = Get-Download $V.VSCODIUM_WIN_URL $V.VSCODIUM_WIN_SHA256
    # The portable data (settings, extensions) survives an update of the editor.
    $kept = $null
    if (Test-Path $Data) { $kept = Join-Path $Tools 'vscodium-data.keep'; Move-Item -Force $Data $kept }
    if (Test-Path $EditorDir) { Remove-Item -Recurse -Force $EditorDir }
    [IO.Compression.ZipFile]::ExtractToDirectory($archive, $EditorDir)
    if ($kept) { Move-Item $kept $Data }
    Set-Installed 'vscodium' $V.VSCODIUM_VERSION
  }
  # This folder makes VSCodium portable: settings and extensions live here.
  New-Item -ItemType Directory -Force -Path (Join-Path $Data 'user-data\User'), (Join-Path $Data 'extensions') | Out-Null

  # ── Editor settings ───────────────────────────────────────────────
  Write-Host (T '2/5. Настройки редактора' '2/5. Editor settings')
  $settings = Join-Path $Data 'user-data\User\settings.json'
  # Only the first time: after that they are the author's.
  if (-not (Test-Path $settings)) { Copy-Item (Join-Path $PSScriptRoot 'user-settings.json') $settings }
  Set-Content -Path (Join-Path $Data 'argv.json') -Value "{`n  `"locale`": `"$Lang`"`n}" -Encoding ASCII

  # ── Extensions ────────────────────────────────────────────────────
  Write-Host (T '3/5. Расширение QSP для редактора' '3/5. QSP extension for the editor')
  $vsix = if ($QspVsix) { $QspVsix } else { Get-Download $V.QSP_LSP_URL $V.QSP_LSP_SHA256 }
  & $Cli --install-extension $vsix --force
  if ($LASTEXITCODE -ne 0) { Fail 'не удалось установить расширение QSP.' 'could not install the QSP extension.' }
  if ($Lang -eq 'ru') {
    & $Cli --install-extension (Get-Download $V.LANGPACK_RU_URL $V.LANGPACK_RU_SHA256) --force
    if ($LASTEXITCODE -ne 0) { Fail 'не удалось установить русский язык редактора.' 'could not install the Russian language pack.' }
  }

  # ── Players ───────────────────────────────────────────────────────
  Write-Host (T "4/5. Плеер QSP $($V.QSPGUI_VERSION)" "4/5. QSP player $($V.QSPGUI_VERSION)")
  if (-not (Test-Installed 'qspgui' $V.QSPGUI_VERSION)) {
    $zip = Get-Download $V.QSPGUI_WIN_URL $V.QSPGUI_WIN_SHA256
    $dir = Join-Path $Tools 'qspgui'
    if (Test-Path $dir) { Remove-Item -Recurse -Force $dir }
    [IO.Compression.ZipFile]::ExtractToDirectory($zip, $dir)
    Set-Installed 'qspgui' $V.QSPGUI_VERSION
  }

  if (-not $NoQspider) {
    Write-Host "      qSpider $($V.QSPIDER_VERSION)"
    if (-not (Test-Installed 'qspider' $V.QSPIDER_VERSION)) {
      $installer = Get-Download $V.QSPIDER_WIN_URL $V.QSPIDER_WIN_SHA256
      $dir = Join-Path $Tools 'qspider'
      # qSpider ships only as an installer. /S installs silently for the
      # current user (no administrator rights); /D= must come last, unquoted.
      $p = Start-Process -FilePath $installer -ArgumentList '/S', "/D=$dir" -Wait -PassThru
      if ($p.ExitCode -ne 0 -or -not (Test-Path (Join-Path $dir 'qSpider.exe'))) {
        Fail 'не удалось установить qSpider.' 'could not install qSpider.'
      }
      Set-Installed 'qspider' $V.QSPIDER_VERSION
    }
  }

  # ── Game ──────────────────────────────────────────────────────────
  Write-Host (T '5/5. Игра' '5/5. Game')
  $game = Join-Path $Root 'game'
  if (-not (Get-ChildItem -Path $game -Filter '*.qsps' -File -ErrorAction SilentlyContinue)) {
    Copy-Item (Join-Path $PSScriptRoot "samples\$Lang\main.qsps") (Join-Path $game 'main.qsps')
    Write-Host (T '      Добавлена стартовая игра: game\main.qsps' '      Added a starter game: game\main.qsps')
  }
} catch {
  Fail "$($_.Exception.Message)" "$($_.Exception.Message)"
}

# The archives are unpacked now; a later run downloads only what changed.
Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $Downloads '*')

Write-Host ''
Write-Host (T 'Готово! Теперь дважды щёлкните файл «open-game-windows.cmd».' 'Done! Now double-click the file “open-game-windows.cmd”.') -ForegroundColor Green
Stop-Transcript | Out-Null
Pause-IfInteractive
