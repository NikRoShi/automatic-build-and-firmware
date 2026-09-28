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

for %%f in (lib\*.c) do (

    echo [BUILD] Compiling library file: %%~nxf

    sdcc -mstm8 -c -I. -Ilib "%%f" -o "build\%%~nf.rel"

    if errorlevel 1 goto error_end

    call set "REL_FILES=%%REL_FILES%% "build\%%~nf.rel""

)



:: Компиляция главного файла main.c в объектный файл main.rel

echo [BUILD] Compiling main.c...

sdcc -mstm8 -c -I. -Ilib main.c -o build\main.rel

if errorlevel 1 goto error_end



:: Линковка всех объектных файлов .rel в единую прошивку main.ihx

echo [BUILD] Linking all files together...

sdcc -mstm8 build\main.rel %REL_FILES% -o main.ihx
if errorlevel 1 goto error_end



:: Убираем лишние файлы линкера (.lk и .map) в папку build, чтобы очистить корень

if exist main.lk move /y main.lk build\ > nul

if exist main.map move /y main.map build\ > nul

echo [BUILD] Compilation successfully done.

echo.



:: 3. Прошивка микроконтроллера

echo [FLASH] Starting flash device...



:: Вызываем утилиту STVP через полный путь для прошивки микроконтроллера
%STVP_PATH% -BoardName=%PROGRAMMER% -Device=%MCU% -Port=USB -ProgMode=%INTERFACE% -FileProg="main.ihx"



if errorlevel 1 (

    echo.

    echo [ERROR] Device could not be flashed!

) else (

    echo.

    echo [SUCCESS] Firmware done!

    if exist main.ihx move /y main.ihx build\ > nul
)

goto end



:: Точка перехода в случае ошибки сборки

:error_end

echo.
echo [ERROR] build is crushed!



:end

echo.
pause
