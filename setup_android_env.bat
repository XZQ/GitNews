@echo off
rem Double-click to set ANDROID_HOME and add adb to user PATH.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\setup_android_env.ps1"
pause
