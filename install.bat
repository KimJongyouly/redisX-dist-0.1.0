@echo off
setlocal enabledelayedexpansion
rem redisX installer (Windows) — builds redisX from source and installs
rem standalone binaries. Requires a working Rust toolchain (cargo) already
rem installed on this machine: https://rustup.rs
rem
rem Usage:
rem   install.bat              builds + installs to %LOCALAPPDATA%\redisX
rem   set INSTALL_DIR=C:\redisX & install.bat

set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

if not defined INSTALL_DIR set "INSTALL_DIR=%LOCALAPPDATA%\redisX"

echo ==^> Building release binaries (cargo build --release --workspace --features redisx-server/python,redisx-server/polars)...
cargo build --release --workspace --features redisx-server/python,redisx-server/polars
if errorlevel 1 (
    echo.
    echo ==================================================================
    echo 오류: 빌드에 실패했습니다.
    echo redisX는 소스에서 직접 빌드되며, 이 컴퓨터에 Rust^(cargo^)가
    echo 설치되어 있지 않아서 발생한 오류일 가능성이 높습니다.
    echo https://rustup.rs 에서 Rust를 설치한 뒤 터미널을 새로 열고
    echo 다시 실행해주세요.
    echo ==================================================================
    exit /b 1
)

if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

echo ==^> Installing to %INSTALL_DIR% ...
copy /Y "target\release\redisx-server.exe" "%INSTALL_DIR%\redisx-server.exe" >nul
copy /Y "target\release\redisx-cli.exe" "%INSTALL_DIR%\redisx-cli.exe" >nul
copy /Y "target\release\redisx-benchmark.exe" "%INSTALL_DIR%\redisx-benchmark.exe" >nul

echo.
echo ==================================================================
echo redisX installed to: %INSTALL_DIR%
echo   redisx-server.exe, redisx-cli.exe, redisx-benchmark.exe
echo.
echo [1] 설정 파일^(redisx.conf^)은 redisx-server를 처음 실행할 때
echo     %INSTALL_DIR% 안에 기본값으로 자동 생성됩니다.
echo.
echo [2] cargo나 전체 경로 없이 실행하려면 %INSTALL_DIR% 을 PATH
echo     환경 변수에 추가하세요:
echo       시스템 속성 ^> 고급 ^> 환경 변수 ^> Path ^> 새로 만들기
echo       -^> %INSTALL_DIR%
echo ==================================================================

endlocal
