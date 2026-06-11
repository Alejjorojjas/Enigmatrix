@echo off
REM Banco de pruebas de Enigmatrix (Fase 1).
REM Sirve la version web ya compilada y abre el navegador.
cd /d "%~dp0app"
if not exist build\web\index.html (
  echo Compilando la app por primera vez ^(1-2 minutos^)...
  call flutter build web
)
start "" http://localhost:8123
echo.
echo  Enigmatrix corriendo en http://localhost:8123
echo  Cierra esta ventana para apagar el servidor.
echo.
dart pub global run dhttpd --path build\web --port 8123
