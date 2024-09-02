@echo off
:: author neatgz @ GitHub

cd /d %~dp0

set SAVEDIR=%~dp0Downloads
if not exist %SAVEDIR% (
	md %SAVEDIR%
)

:: set BUSYBOX="%~dp0Utils\busybox.exe"
set CURL_PATH="%~dp0Utils\curl.exe"
set JQ_PATH="%~dp0Utils\jq.exe"
set ARIA2C_PATH="%~dp0Utils\aria2c.exe"
set URL_LIST="%SAVEDIR%\urls.txt"

mode con cols=100 lines=30
color 0b
title Github Release Assets downloader v1.2
echo Github Release Assets downloader v1.2
echo ===============================================================================
echo Please read and config the config.txt file Before continue!
echo ===============================================================================
pause

:: Read the 2nd line in config.txt and config whether use proxy
setlocal enabledelayedexpansion
set lineNumber=0
for /f "usebackq delims=" %%a in ("config.txt") do (
    set /a lineNumber+=1
    if !lineNumber! equ 2 (
        if "%%a"=="0" (
            set proxy_parameter_aria2=
			echo You choose NOT to use proxy when downloading
        ) else (
            set proxy_address=%%a
			set proxy_parameter_aria2=--all-proxy="!proxy_address!"
			echo You choose to USE proxy !proxy_address! when downloading
        )
    )
)
:: echo %proxy_address%
:: echo %proxy_parameter_aria2%
:: pause

:: Read the 4th line in config.txt and config the repo name to download
setlocal enabledelayedexpansion
set lineNumber=0
for /f "usebackq delims=" %%a in ("config.txt") do (
    set /a lineNumber+=1
    if !lineNumber! equ 4 (
        if "%%a"=="0" (
			echo You did NOT fill in the repository name, exiting
			pause
			exit
        ) else (
        	set REPO_address=%%a
			echo The name of the repository to be downloaded is !REPO_address!
        )
    )
)
:: echo %REPO_address%
:: pause

:: Read the 6th line in config.txt and config the version to download
setlocal enabledelayedexpansion
set lineNumber=0
for /f "usebackq delims=" %%a in ("config.txt") do (
    set /a lineNumber+=1
    if !lineNumber! equ 6 (
        if "%%a"=="latest" (
			echo You choose to download the latest version
			goto get_latest_version
        ) else (
			set target_version=%%a
			echo You choose to download the specified version
			goto target_or_current
        )
    )
)

:: get the latest version tag from github
:get_latest_version

%CURL_PATH% -s https://api.github.com/repos/%REPO_address%/releases/latest | %JQ_PATH% -r ".tag_name" > %SAVEDIR%\latest.txt
set /P latest_version=<%SAVEDIR%\latest.txt
:: echo Latest version: %latest_version%
set target_version=%latest_version%
:: pause

:target_or_current
if exist "%SAVEDIR%\current.txt" set /P current_version=<%SAVEDIR%\current.txt > NUL
:: echo Current version %current_version%
:: pause
if "%current_version%" == "%target_version%" (
  echo You have Already downloaded this version last time: %current_version%, exiting
    goto end
) else echo Target version: %target_version%
pause

:: :process1

:: 	%CURL_PATH% -s https://api.github.com/repos/%REPO_address%/releases/latest | %JQ_PATH% -r ".assets[].browser_download_url" > %URL_LIST%
:: 	%ARIA2C_PATH% %proxy_parameter_aria2% -c -s 16 -x 16 -k 1M -d %SAVEDIR%\%target_version% -i %URL_LIST%

:: goto end

:process
%CURL_PATH% -s https://api.github.com/repos/%REPO_address%/releases/tags/%target_version% | %JQ_PATH% -r ".assets[].browser_download_url" > %URL_LIST%
%CURL_PATH% -s https://api.github.com/repos/%REPO_address%/releases/tags/%target_version% | %JQ_PATH% -r ".tarball_url" >> %URL_LIST%

%ARIA2C_PATH% %proxy_parameter_aria2% -c -s 16 -x 16 -k 1M -d %SAVEDIR%\%target_version% -i %URL_LIST%

goto end

:end
:: if exist "%SAVEDIR%\current.txt" del "%SAVEDIR%\current.txt" > NUL
if exist "%SAVEDIR%\latest.txt" del "%SAVEDIR%\latest.txt" > NUL
echo %target_version%>"%SAVEDIR%\current.txt"
move "%SAVEDIR%\urls.txt" "%SAVEDIR%\%target_version%" > NUL
pause
