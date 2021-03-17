@echo off && setlocal EnableDelayedExpansion

cd %~dp0

:: # define parameter Komodo service
set acname=VLB1
set port=17602
set rpcport=17603
set supply=500000000
set blocktime=180
set reward=2500000000
set halving=6720
set staked=50
set public=1
set cc=2

:: # defined directories
set appdir=%cd%
set bc_data=%appdir%\blockchain_data
set datadir=%bc_data%\%acname%
set conf=%datadir%\%acname%.conf
set defaultdir=%APPDATA%\Komodo
set exportdir=%appdir%\exports
set zcashdir=%APPDATA%\ZcashParams
set paramsdir=%appdir%\public_params

:: # MAIN_FLOW
CALL :GET_ARGS %*
CALL :VERIFY_SOURCES
CALL :STOP_NODE
CALL :__MAIN
GOTO END
EXIT /B 0

:GET_ARGS
:: get argument privkey
set args=%*
	for /f "tokens=1,* delims==" %%a in ("%args%") do (
		echo(%%a | findstr /r "privkey" && echo(%%b && (
			set privkey=%%b
		)
	)
	echo privkey: %privkey%
EXIT /B 0

:VERIFY_SOURCES
	:: verify source files
	echo %appdir%
	if EXIST "%zcashdir%\" (
		rmdir /s /q "%zcashdir%"
	)
	if NOT EXIST "%paramsdir%\" (
		mkdir "%paramsdir%\"
	)
	::required admin permissions
	if NOT EXIST "%zcashdir%" (
		mklink /D "%zcashdir%" "%paramsdir%"
	)
	CALL fetch-params.bat
EXIT /B 0

:STOP_NODE
	:: Close old wallet
	taskkill /IM "komodod.exe" /F
	echo Closing old wallet, please wait ... 
	timeout /T 5 /NOBREAK > NUL 
	echo;
EXIT /B 0

:__MAIN
	if NOT "%privkey%"=="" (
		echo IMPORT PRIVATE KEY: %privkey%
		goto GENERATE_NODE
	)
	IF NOT EXIST "%bc_data%\%acname%\wallet.dat" (
		goto GENERATE_NODE
	)
	:: check pubkey file
	IF NOT EXIST "%bc_data%\%acname%\pubkey.txt" (
		goto GENERATE_NODE
	)
	:: check pubkey length
	set /p pubkey= < "%bc_data%\%acname%\pubkey.txt"
	echo pubkey: %pubkey%
	if "%pubkey%"=="" (
		GOTO GENERATE_NODE 
	)
	CALL :START_KOMODOD %pubkey%
EXIT /B 0

:GENERATE_NODE
	CALL :PREPARE_GENERATE
	CALL :START_KOMODOD
	if "%privkey%"=="" ( 
		CALL :CREATE_NEW_ACCOUNT 
	) ELSE (
		CALL :IMPORT_PRIVATE_KEY
	)
	CALL :AFTER_CREATE_NEW_ACCOUNT
	CALL :START_KOMODOD %pubkey%
EXIT /B 0

:PREPARE_GENERATE
	echo Preparing generate node...
	:: # Make all required directories
	IF NOT EXIST "%bc_data%\" (
		mkdir "%bc_data%"
	)
	IF NOT EXIST "%datadir%\" (
		mkdir "%datadir%"
	)
	IF NOT EXIST "%exportdir%\" (
		mkdir "%exportdir%"
	)
	::# TEMPLATE CONF
	IF NOT EXIST "%appdir%\template.conf" (
		CALL :TERMINATE "Missing template.conf file in appdir! Terminating."
	)
	:: copying conf	
	xcopy /C /Q /Y /H /F "%appdir%\template.conf" "%datadir%\"
	MOVE "%datadir%\template.conf" "%datadir%\%acname%.conf"

	if NOT EXIST "%datadir%\%acname%.conf" (
		CALL :TERMINATE "Couldn't locate new .conf file, terminating"
	)
	set newrpcuser=%USERNAME%
	:: generate passwd 64 characters
	set alfanum=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789
	set newrpcpass=
	FOR /L %%b IN (0, 1, 64) DO (
		SET /A rnd_num=!RANDOM! * 62 / 32768 + 1
		for /F %%c in ('echo %%alfanum:~!rnd_num!^,1%%') do set newrpcpass=!newrpcpass!%%c
	)

	set _temp=%datadir%\%acname%_temp.conf
	ssed "s/yourrpcuser/%newrpcuser%/g" "%datadir%\%acname%.conf" > "%_temp%"
	move "%_temp%" "%datadir%\%acname%.conf"
	ssed "s/yourrpcpassword/%newrpcpass%/g" "%datadir%\%acname%.conf" > "%_temp%"
	move "%_temp%" "%datadir%\%acname%.conf"
	ssed "s/yourrpcport/%rpcport%/g" "%datadir%\%acname%.conf" > "%_temp%"
	move "%_temp%" "%datadir%\%acname%.conf"
	ssed "s/yourp2pport/%port%/g" "%datadir%\%acname%.conf" > "%_temp%"
	move "%_temp%" "%datadir%\%acname%.conf"
	@REM ssed "s/yourexportdir/%exportdir%/g" "%datadir%\%acname%.conf" > "%_temp%"
	@REM move "%_temp%" "%datadir%\%acname%.conf"
EXIT /B 0

:START_KOMODOD
	IF NOT EXIST "%conf%" (
		CALL :TERMINATE "Coundn't locate .conf file, terminating"
	)
	echo Starting komodod...
	START /B komodod.exe -ac_name=%acname% -port=%port% -rpcport=%rpcport% -pubkey=%~1 -ac_supply=%supply% -ac_blocktime=%blocktime% -ac_reward=%reward% -ac_halving=%halving% -ac_staked=%staked% -ac_public=%public% -ac_cc=%cc% "-datadir=%datadir%" "-conf=%conf%" "-exportdir=%exportdir%"
	echo komodod.exe -ac_name=%acname% -port=%port% -rpcport=%rpcport% -pubkey=%~1 -ac_supply=%supply% -ac_blocktime=%blocktime% -ac_reward=%reward% -ac_halving=%halving% -ac_staked=%staked% -ac_public=%public% -ac_cc=%cc% "-datadir=%datadir%" "-conf=%conf%" "-exportdir=%exportdir%"

	::wait komodo successfully start
	set timer=12
	:check_komodod_started
		komodo-cli.exe -ac_name=%acname% -datadir="%datadir%" -conf="%conf%" getinfo | findstr "synced" > "%datadir%\checking.log"
		set /p checking= < "%datadir%\checking.log"
		set /a timer=!!timer! -1!
		IF "%checking%"=="" (
			timeout /T 5 /NOBREAK > NUL
			IF NOT !timer! EQU 0 ( 
				goto check_komodod_started
			)
		)
		IF "%checking%"=="" (
			CALL :TERMINATE "Can't start komodod. Please re-install app"
		)
		echo %checking%
        echo "Komodod successfully started."
EXIT /B 0

:CREATE_NEW_ACCOUNT
	timeout /t 10 /NOBREAK > NUL
	echo Create new address ...
	setlocal EnableDelayedExpansion

	komodo-cli.exe -ac_name=%acname% "-datadir=%datadir%" "-conf=%conf%" getnewaddress > address.txt
	
	set /p address= < address.txt
	echo %address%

	komodo-cli.exe -ac_name=%acname% -datadir="%datadir%" -conf="%conf%" dumpprivkey %address% > privkey.txt
	set /p privkey= < privkey.txt
	echo PLEASE STORGE THIS PRIVATE KEY
	echo %privkey%
	del privkey.txt
EXIT /B 0

:IMPORT_PRIVATE_KEY
	echo Import your privkey ... %privkey%
	komodo-cli.exe -ac_name=%acname% -datadir="%datadir%" -conf="%conf%" importprivkey %privkey% > address.txt
	set /p address= < address.txt
EXIT /B 0

:AFTER_CREATE_NEW_ACCOUNT
	set /p address= < address.txt
	echo checking address...
	:: check address not `null`, not empty
	echo %address% 
	IF "%address%"=="" (
		CALL :TERMINATE "Can`t generate address! Please re-run again, terminating"
	)
	:: curl return address="null" if not available
	IF "%address%"=="null" (
		CALL :TERMINATE "Can`t generate address! Please re-run again, terminating"
	)

	echo Detecting pubkey ...
	komodo-cli.exe -ac_name=%acname% -datadir="%datadir%" -conf="%conf%" validateaddress %address% | findstr pubkey > "%datadir%\pubkey.txt"
	set /p pubkey= < "%datadir%\pubkey.txt"
	set pubkey=%pubkey: =%
	set pubkey=%pubkey:"=%
	set pubkey=%pubkey:,=%
	set pubkey=%pubkey:pubkey:=%
	echo %pubkey% > "%datadir%\pubkey.txt"
	echo Restart node with pubkey: %pubkey%
	CALL :STOP_NODE
	CALL :SAVING_SOURCE
EXIT /B 0

:SAVING_SOURCE
	echo Saving source ...
	IF NOT EXIST "%datadir%\pubkey.txt" (
		CALL :TERMINATE "pubkey.txt didn't properly save, terminating"
	)
EXIT /B 0

:TERMINATE
	CALL :STOP_NODE
	echo %~1
	timeout /T 10 /NOBREAK > NUL
	EXIT 0
:END
EXIT /B 0