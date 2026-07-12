@echo off
REM Genera el App Bundle (.aab) firmado que exige Google Play.
REM (Para instalar en tu telefono usa COMPILAR-ANDROID.bat; este archivo
REM  es solo para SUBIR a la consola de Play.)
cd /d "%~dp0app"
echo Compilando App Bundle firmado para Play Store...
call flutter build appbundle --release
if errorlevel 1 (
  echo.
  echo  ERROR al compilar. Copia el mensaje y pegalo en el chat de Claude.
  pause
  exit /b 1
)
echo.
echo  Listo: app\build\app\outputs\bundle\release\app-release.aab
start "" "%~dp0app\build\app\outputs\bundle\release"
