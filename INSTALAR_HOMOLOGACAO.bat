@echo off
setlocal EnableExtensions
chcp 65001 >nul
title Instalador Oficial - Sistema Restaurante Massas - HOMOLOGACAO

set "PS1=%TEMP%\INSTALAR_HOMOLOGACAO_SISTEMA_RESTAURANTE.ps1"
set "URL=https://raw.githubusercontent.com/ApriMax/restaurante-massas-releases/main/INSTALAR_HOMOLOGACAO.ps1"

echo ============================================================
echo  INSTALADOR OFICIAL - SISTEMA RESTAURANTE MASSAS - HOMOLOGACAO
echo ============================================================
echo.
echo Este instalador usa SOMENTE o canal de HOMOLOGACAO.
echo Computadores marcados como PRODUCAO sao bloqueados.
echo Os dados locais existentes sao preservados.
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -UseBasicParsing -Uri '%URL%' -OutFile '%PS1%'"
if errorlevel 1 (
  echo.
  echo ERRO: nao foi possivel baixar o instalador oficial de Homologacao.
  pause
  exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
set "RC=%ERRORLEVEL%"
del /q "%PS1%" >nul 2>&1
exit /b %RC%
