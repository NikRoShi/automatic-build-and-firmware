@echo off



:: ================= НАСТРОЙКИ (Измените под себя) =================

set MCU=STM8S103F3

set PROGRAMMER=ST-LINK

set INTERFACE=SWIM

:: Путь к утилите прошивки STVP (проверьте, правильный ли у вас путь)

set STVP_PATH="C:\Program Files\STMicroelectronics\st_toolset\stvp\STVP_CmdLine.exe"

:: =================================================================



echo ===================================================

echo   BUILD and FLASH %MCU% with SDCC and STVP

echo ===================================================

echo.



:: 1. Создаем папку build, если её еще нет

if not exist build (

    echo [INFO] make build dir...

    md build

)

:: 2. Компиляция проекта

echo [BUILD] build all files in project...
:: Переменная для хранения путей к скомпилированным .rel файлам библиотек
set 
"REL_FILES="



:: Цикл по всем .c файлам в папке lib. Компилируем каждый файл по отдельности в папку build.

for %%f in (..\..\lib\*.c) do (

    echo [BUILD] Compiling library file: %%~nxf

    sdcc -mstm8 -c -I. -I..\..\lib "%%f" -o "build\%%~nf.rel"

    if errorlevel 1 goto build_error

    call set "REL_FILES=%%REL_FILES%% "build\%%~nf.rel""

)



:: Компиляция главного файла main.c в объектный файл main.rel

echo [BUILD] Compiling main.c...

sdcc -mstm8 -c -I. -I..\..\lib main.c -o build\main.rel

if errorlevel 1 goto build_error



:: Линковка всех объектных файлов .rel в единую прошивку main.ihx

echo [BUILD] Linking all files together...

sdcc -mstm8 build\main.rel %REL_FILES% -o main.ihx
if errorlevel 1 goto build_error



:: Убираем лишние файлы линкера (.lk и .map) в папку build, чтобы очистить корень

if exist main.lk move /y main.lk build\ > nul

if exist main.map move /y main.map build\ > nul

echo [BUILD] Compilation successfully done.

echo.



:: 3. Прошивка микроконтроллера

echo [FLASH] Starting flash device...



:: Вызываем утилиту STVP через полный путь для прошивки микроконтроллера
cmd /a /c "%STVP_PATH% -BoardName=%PROGRAMMER% -Device=%MCU% -Port=USB -ProgMode=%INTERFACE% -FileProg="main.ihx" -no_loop -verif" > flash_output.tmp
type flash_output.tmp

:: Ищем в файле лога маркер "Cannot" (без учета регистра букв)

findstr /I /C:"Cannot" flash_output.tmp > nul

if %errorlevel% equ 0 goto flash_error



:: Ищем в файле лога маркер "fail" (без учета регистра букв)

findstr /I /C:"fail" flash_output.tmp > nul

if %errorlevel% equ 0 goto flash_error

echo [SUCCESS] Firmware done!

goto end



:: Точка перехода в случае ошибки сборки

:build_error
color 4F
echo.
echo [ERROR] build is crushed!

pause


exit

:: Точка входа в случае ошибки прошивки
:flash_error
if exist main.ihx move /y main.ihx build\ > nul

:: Удаляем файл с результатами
if exist flash_output.tmp del /f /q flash_output.tmp
if exist Result.log del /f /q Result.log

color 4F
echo.

echo [ERROR] Device could not be flashed!
pause

exit

:: Точка входа если всё успешно
:end
if exist main.ihx move /y main.ihx build\ > nul

:: Удаляем файл с результатами
if exist flash_output.tmp del /f /q flash_output.tmp
if exist Result.log del /f /q Result.log

color 2F
echo.
pause
exit