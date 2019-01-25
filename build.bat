@echo off
cls

Rem ******************************************************************************************
rem 			"enviroment Varibles"
Rem ******************************************************************************************

rem Release or Debug
set BUILD_TYPE=Release

if [%1] == "Release" (set BUILD_TYPE=%1)

set BUILD_DATE=%date:~10,4%%date:~4,2%%date:~7,2%
set VERSION_SUFFIX=techpreview
set TAG=virtual-drive-techpreview

echo "* BUILD_TYPE=%BUILD_TYPE%"
echo "* PROJECT_PATH=%VIRTUAL_DRIVE%"
echo "* VCINSTALLDIR=%VCINSTALLDIR%"
echo "* PATH=%PATH%"
echo "* Png2Ico_EXECUTABLE=%Png2Ico_EXECUTABLE%"
echo "* QTKEYCHAIN_INCLUDE_DIR=%QTKEYCHAIN_INCLUDE_DIR%"
echo "* QTKEYCHAIN_LIBRARY=%QTKEYCHAIN_LIBRARY%"
echo "* OPENSSL_INCLUDE_DIR=%OPENSSL_INCLUDE_DIR%"
echo "* OPENSSL_LIBRARIES=%OPENSSL_LIBRARIES%"
echo "* Build date %BUILD_DATE%"
echo "* VERSION_SUFFIX %VERSION_SUFFIX%"
echo "* TAG %TAG%"
echo "* DOKAN_LIB %DOKAN_LIB%"

Rem ******************************************************************************************
rem 			"clean up"
Rem ******************************************************************************************

echo "* Remove old installation files %VIRTUAL_DRIVE%/install from previous build."
start "rm-rf" /B /wait rm -rf %VIRTUAL_DRIVE%/install/*

echo "* Remove old dependencies files %VIRTUAL_DRIVE%/libs from previous build."
start "rm -rf" /B /wait rm -rf %VIRTUAL_DRIVE%/libs/*

echo "* Remove %VIRTUAL_DRIVE%/desktop/build/CMakeFiles from previous build."
start "rm -rf" /B /wait rm -rf %VIRTUAL_DRIVE%/desktop/build/*

Rem ******************************************************************************************
rem 			"git pull, build, collect dependencies"
Rem ******************************************************************************************

rem Reference: https://ss64.com/nt/start.html

echo "* git pull at %VIRTUAL_DRIVE%/desktop/."
start "git pull" /D "%VIRTUAL_DRIVE%/desktop/" /B /wait git pull

echo "* git checkout %TAG% at %VIRTUAL_DRIVE%/desktop/."
start "git checkout %TAG%" /D "%VIRTUAL_DRIVE%/desktop/" /B /wait git checkout %TAG%

echo "* save git HEAD commit hash from repo %VIRTUAL_DRIVE%/desktop/."
start "git rev-parse HEAD" /D "%VIRTUAL_DRIVE%/desktop/" /B /wait git rev-parse HEAD > tmp
set /p GIT_REVISION= < tmp
del tmp

echo "* Run cmake with CMAKE_INSTALL_PREFIX and CMAKE_BUILD_TYPE set at %VIRTUAL_DRIVE%/desktop/build."
start "cmake.." /D "%VIRTUAL_DRIVE%/desktop/build" /B /wait cmake "-GVisual Studio 15 2017 Win64" .. -DMIRALL_VERSION_SUFFIX="%VERSION_SUFFIX%" -DDOKAN_LIB="%DOKAN_LIB%" -DBUILD_SHELL_INTEGRATION=1 -DBUILD_SHELL_INTEGRATION_ICONS=1 -DWITH_CRASHREPORTER=OFF -DMIRALL_VERSION_BUILD="%BUILD_DATE%" -DCMAKE_INSTALL_PREFIX="%VIRTUAL_DRIVE%/install" -DCMAKE_BUILD_TYPE="%BUILD_TYPE%" -DNO_SHIBBOLETH=1 -DPng2Ico_EXECUTABLE="%Png2Ico_EXECUTABLE%" -DQTKEYCHAIN_LIBRARY="%QTKEYCHAIN_LIBRARY%" -DQTKEYCHAIN_INCLUDE_DIR="%QTKEYCHAIN_INCLUDE_DIR%" -DOPENSSL_ROOT_DIR="%OPENSSL_ROOT_DIR%" -DOPENSSL_INCLUDE_DIR="%OPENSSL_INCLUDE_DIR%" -DOPENSSL_LIBRARIES="%OPENSSL_LIBRARIES%"

echo "* Run cmake to compile and install."
start "cmake build" /D "%VIRTUAL_DRIVE%/desktop/build" /B /wait cmake --build . --config %BUILD_TYPE% --target install

echo "* Run windeployqt to collect all nextcloud.exe dependencies and output it to %VIRTUAL_DRIVE%/libs/."
start "windeployqt" /B /wait windeployqt.exe --release %VIRTUAL_DRIVE%/install/bin/nextcloud.exe --dir %VIRTUAL_DRIVE%/libs/

echo "* git checkout master at %VIRTUAL_DRIVE%/desktop/."
start "git checkout master" /D "%VIRTUAL_DRIVE%/desktop/" /B /wait git checkout master

echo "* Run NSIS script with parameters BUILD_TYPE=%BUILD_TYPE% and GIT_REVISION=%GIT_REVISION% to create installer."
start "NSIS" /B /wait makensis.exe /DBUILD_TYPE=%BUILD_TYPE% /DMIRALL_VERSION_SUFFIX=%VERSION_SUFFIX% /DMIRALL_VERSION_BUILD=%BUILD_DATE% /DGIT_REVISION=%GIT_REVISION:~0,6% nextcloud.nsi

exit