@echo off
setlocal EnableExtensions

rem Build LibreSSL as static libraries for the Eiffel openssl binding, and install them into
rem     spec\<platform>\include and spec\<platform>\lib
rem as expected by C_library\openssl\clibs_openssl.ecf when the ECF custom variable "libressl" is "true".
rem
rem Usage: build.bat [win64^|windows]
rem     The platform defaults to %ISE_PLATFORM%, or win64 if it is not set.
rem
rem Requirements:
rem     - CMake 3.16 or later, in the PATH.
rem     - Visual Studio with the C++ workload: CMake uses the most recent one found.
rem     - curl.exe and tar.exe, included in Windows 10 and later.
rem No Perl is needed.

set LIBRESSL_VERSION=4.4.0
rem SHA-256 of libressl-4.4.0.tar.gz, from the release SHA256 file (checked with its signify signature).
set LIBRESSL_SHA256=7d02522ad5070b9adb32eb253ecabce181184a3750cf65abac0675ee908687c1
set LIBRESSL_ARCHIVE=libressl-%LIBRESSL_VERSION%.tar.gz

set "TARGET_PLATFORM=%~1"
if "%TARGET_PLATFORM%"=="" set "TARGET_PLATFORM=%ISE_PLATFORM%"
if "%TARGET_PLATFORM%"=="" set "TARGET_PLATFORM=win64"
if /i "%TARGET_PLATFORM%"=="win64" (
	set CMAKE_ARCH=x64
) else if /i "%TARGET_PLATFORM%"=="windows" (
	set CMAKE_ARCH=Win32
) else (
	echo Unsupported platform "%TARGET_PLATFORM%": use win64 or windows.
	exit /b 1
)

set "CURRENT_DIR=%~dp0"
set "BUILD_DIR=%CURRENT_DIR%builds"
set "ARCHIVE=%BUILD_DIR%\%LIBRESSL_ARCHIVE%"
set "SOURCE_DIR=%BUILD_DIR%\libressl-%LIBRESSL_VERSION%"
set "CMAKE_DIR=%BUILD_DIR%\cmake_%TARGET_PLATFORM%"
set "INSTALL_DIR=%CURRENT_DIR%spec\%TARGET_PLATFORM%"

where cmake >nul 2>nul
if errorlevel 1 (
	echo CMake is required, and was not found in the PATH.
	exit /b 1
)

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

rem Download the release archive, if not already there.
if exist "%ARCHIVE%" goto :check_archive
echo Downloading %LIBRESSL_ARCHIVE% ...
curl -fsSL -o "%ARCHIVE%" "https://cdn.openbsd.org/pub/OpenBSD/LibreSSL/%LIBRESSL_ARCHIVE%"
if not errorlevel 1 goto :check_archive
echo Download from cdn.openbsd.org failed, trying github.com ...
curl -fsSL -o "%ARCHIVE%" "https://github.com/libressl/portable/releases/download/v%LIBRESSL_VERSION%/%LIBRESSL_ARCHIVE%"
if errorlevel 1 (
	if exist "%ARCHIVE%" del "%ARCHIVE%"
	echo Could not download %LIBRESSL_ARCHIVE%.
	goto :error
)

:check_archive
rem Check the archive against the expected SHA-256.
set "ACTUAL_SHA256="
for /f "skip=1 delims=" %%h in ('certutil -hashfile "%ARCHIVE%" SHA256') do if not defined ACTUAL_SHA256 set "ACTUAL_SHA256=%%h"
if not defined ACTUAL_SHA256 (
	echo Could not compute the SHA-256 of %ARCHIVE%.
	goto :error
)
set "ACTUAL_SHA256=%ACTUAL_SHA256: =%"
if /i not "%ACTUAL_SHA256%"=="%LIBRESSL_SHA256%" (
	echo SHA-256 mismatch for %ARCHIVE%
	echo     expected: %LIBRESSL_SHA256%
	echo     actual:   %ACTUAL_SHA256%
	del "%ARCHIVE%"
	goto :error
)
echo SHA-256 verified for %LIBRESSL_ARCHIVE%.

rem Extract a fresh copy of the sources.
if exist "%SOURCE_DIR%" rmdir /s /q "%SOURCE_DIR%"
tar -xzf "%ARCHIVE%" -C "%BUILD_DIR%"
if errorlevel 1 goto :error

rem Configure: static libraries, static C runtime /MT as EiffelStudio, no apps and no tests.
if exist "%CMAKE_DIR%" rmdir /s /q "%CMAKE_DIR%"
if exist "%INSTALL_DIR%" rmdir /s /q "%INSTALL_DIR%"
cmake -S "%SOURCE_DIR%" -B "%CMAKE_DIR%" -A %CMAKE_ARCH% -DBUILD_SHARED_LIBS=OFF -DUSE_STATIC_MSVC_RUNTIMES=ON -DLIBRESSL_APPS=OFF -DLIBRESSL_TESTS=OFF "-DCMAKE_INSTALL_PREFIX=%INSTALL_DIR%"
if errorlevel 1 goto :error

cmake --build "%CMAKE_DIR%" --config Release
if errorlevel 1 goto :error

cmake --install "%CMAKE_DIR%" --config Release
if errorlevel 1 goto :error

if not exist "%INSTALL_DIR%\lib\ssl.lib" goto :missing_lib
if not exist "%INSTALL_DIR%\lib\crypto.lib" goto :missing_lib
if not exist "%INSTALL_DIR%\include\openssl\ssl.h" goto :missing_lib

echo.
echo LibreSSL %LIBRESSL_VERSION% is installed in %INSTALL_DIR%
echo To use it, set the custom variable "libressl" to "true" in the application ECF target.
exit /b 0

:missing_lib
echo The LibreSSL libraries or headers are missing in %INSTALL_DIR%.

:error
echo.
echo Build of LibreSSL failed.
exit /b 1
