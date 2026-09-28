@echo off
rem Double-click to install the editor and the QSP players into tools\.
chcp 65001 >nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup\setup.ps1" %*
