@echo off

pushd "%~dp0"

:: Install build dependencies
.\.paket\paket.exe install
if errorlevel 1 goto end

:: Run Invoke-Build, forwarding any arguments to it
powershell -NoProfile -ExecutionPolicy Bypass -Command "packages\Invoke-Build\tools\Invoke-Build.ps1 -File build.ps1" %*

:end
popd
exit /b %errorlevel%
