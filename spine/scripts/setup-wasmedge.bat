@echo off
echo Running WasmEdge and LLVM setup script...
powershell -ExecutionPolicy Bypass -File "%~dp0setup-wasmedge.ps1"
if errorlevel 1 (
    echo Setup failed. Please check the error messages above.
    exit /b 1
)
echo Setup completed successfully.

REM Export environment variables to the current CMD session
for /f "tokens=*" %%a in ('powershell -Command "[Environment]::GetEnvironmentVariable('WASMEDGE_INCLUDE_DIR', 'Process')"') do set WASMEDGE_INCLUDE_DIR=%%a
for /f "tokens=*" %%a in ('powershell -Command "[Environment]::GetEnvironmentVariable('WASMEDGE_LIB_DIR', 'Process')"') do set WASMEDGE_LIB_DIR=%%a
for /f "tokens=*" %%a in ('powershell -Command "[Environment]::GetEnvironmentVariable('LIBCLANG_PATH', 'Process')"') do set LIBCLANG_PATH=%%a

echo Environment variables set:
echo WASMEDGE_INCLUDE_DIR=%WASMEDGE_INCLUDE_DIR%
echo WASMEDGE_LIB_DIR=%WASMEDGE_LIB_DIR%
echo LIBCLANG_PATH=%LIBCLANG_PATH% 