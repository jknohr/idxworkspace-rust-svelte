@echo off
echo Cleaning up build environment...
powershell -ExecutionPolicy Bypass -File "%~dp0cleanup-env.ps1"

REM Clear environment variables for the current CMD process
set WASMEDGE_INCLUDE_DIR=
set WASMEDGE_LIB_DIR=
set LIBCLANG_PATH=

echo Environment variables cleared:
echo WASMEDGE_INCLUDE_DIR=%WASMEDGE_INCLUDE_DIR%
echo WASMEDGE_LIB_DIR=%WASMEDGE_LIB_DIR%
echo LIBCLANG_PATH=%LIBCLANG_PATH%
echo Cleanup completed successfully. 