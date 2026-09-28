@echo off
chcp 65001 >nul
if not exist "%~dp0tools\vscodium\VSCodium.exe" (
  echo Сначала запустите install-windows.cmd. / Run install-windows.cmd first.
  pause
  exit /b 1
)
set ELECTRON_RUN_AS_NODE=
set VSCODE_IPC_HOOK_CLI=
start "" "%~dp0tools\vscodium\VSCodium.exe" "%~dp0game"
