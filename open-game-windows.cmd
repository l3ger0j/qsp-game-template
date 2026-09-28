@echo off
rem Double-click to open the game folder in the editor installed by install-windows.cmd.
chcp 65001 >nul
if not exist "%~dp0tools\vscodium\VSCodium.exe" (
  echo Сначала запустите install-windows.cmd. / Run install-windows.cmd first.
  pause
  exit /b 1
)
rem Launched from another VS Code's terminal, these would make the editor run
rem as plain Node or hand the folder to that other editor.
set ELECTRON_RUN_AS_NODE=
set VSCODE_IPC_HOOK_CLI=
start "" "%~dp0tools\vscodium\VSCodium.exe" "%~dp0game"
