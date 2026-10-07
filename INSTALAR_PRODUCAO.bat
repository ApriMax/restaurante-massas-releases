@echo off
setlocal EnableExtensions
chcp 65001 >nul
title Instalador Oficial - Sistema Restaurante Massas - PRODUCAO

set "PS1=%TEMP%\INSTALAR_PRODUCAO_SISTEMA_RESTAURANTE.ps1"
set "URL=https://raw.githubusercontent.com/ApriMax/restaurante-massas-releases/main/INSTALAR_PRODUCAO.ps1"

echo ============================================================
echo  INSTALADOR OFICIAL - SISTEMA RESTAURANTE MASSAS - PRODUCAO
echo ============================================================
echo.
echo Este instalador usa SOMENTE o canal estavel de PRODUCAO.
echo Computadores marcados como HOMOLOGACAO sao bloqueados.
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -UseBasicParsing -Uri '%URL%' -OutFile '%PS1%'"
if errorlevel 1 (
  echo.
  echo ERRO: nao foi possivel baixar o instalador oficial.
  pause
  exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
set "RC=%ERRORLEVEL%"
del /q "%PS1%" >nul 2>&1
exit /b %RC%
