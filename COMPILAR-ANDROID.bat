@echo off
REM Compila el APK de Enigmatrix y abre la carpeta donde queda.
REM Usalo despues de cada ronda de correcciones para reinstalar en el telefono.
cd /d "%~dp0app"
echo Compilando APK de Enigmatrix (2-4 minutos)...
call flutter build apk --release
if errorlevel 1 (
  echo.
  echo  ERROR al compilar. Copia el mensaje de arriba y pegalo en el chat de Claude.
  pause
  exit /b 1
)
echo.
echo  APK listo: app-release.apk
start "" "%~dp0app\build\app\outputs\flutter-apk"
