@echo off && setlocal EnableDelayedExpansion

taskkill /IM "komodod.exe" /F

cd %~dp0
set name=komodo-node
set builddir=%cd%\%name%

for /F "tokens=2" %%i in ('date /t') do set mydate=%%i
set mydate=%mydate:/=_%
echo Current time is %mydate%

set namezip=%name%-window-%mydate%.zip


if EXIST "%builddir%" (
	RMDIR /s /q "%builddir%"
)

mkdir "%builddir%"
echo Copying
xcopy /C /Q /Y /H fetch-params.bat "%builddir%"
xcopy /C /Q /Y /H komodo*.exe "%builddir%"
xcopy /C /Q /Y /H komodo.bat "%builddir%"
xcopy /C /Q /Y /H wget64.exe "%builddir%"
xcopy /C /Q /Y /H README.md "%builddir%"
xcopy /C /Q /Y /H template.conf "%builddir%"
xcopy /C /Q /Y /H ssed.exe "%builddir%"
echo move done
::backup
MOVE "%namezip%" "%namezip%-backup"
tar.exe -a -c -f %namezip% %name%
echo zip done
timeout /T 2 /NOBREAK > NUL

xcopy "%cd%\public_params" "%builddir%\public_params" /E /H /C /I
echo Done