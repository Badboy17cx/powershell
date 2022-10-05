@echo off
color 17
set IS_ELEVATED=0
whoami /groups | find "S-1-16-12288" > NUL && set IS_ELEVATED=1
if %IS_ELEVATED%==0 (
    echo Dieses Script benîtigt Administratorrechte!
    echo.
    pause
    exit /b 1
)
cd /d %~dp0


REM ### Aktivierung sichern
echo.
echo Aktivierung wird gesichert...
start /WAIT /B .\gatherosstate\gatherosstate.exe
timeout /T 3 > NUL
if exist .\gatherosstate\GenuineTicket.xml (
	ren .\gatherosstate\GenuineTicket.xml GenuineTicket_%Date:~-4%-%Date:~-7,2%-%Date:~-10,2%_%Time:~0,2%-%Time:~3,2%-%Time:~6,2%.xml
	echo Der Vorgang wurde erfolgreich beendet.
) else (
	echo Aktivierung konnte nicht gesichert werden. Windows ist evtl. nicht aktiviert.
)


REM ### Benutzerkontensteuerung deaktivieren
echo.
echo Benutzerkontensteuerung wird deaktiviert...
reg.exe ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f


REM ### Remotesdesktop ohne Auth auf Netzwerkebene aktivieren
echo.
echo Remotesdesktop ohne Authentifizierung auf Netzwerkebene wird aktiviert...
reg.exe ADD "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 0 /f
wmic RDToggle where ServerName="%computername%" call SetAllowTSConnections 1, 1


REM ### Energiesparmodus ‰ndern
echo Energiesparmodus wird geÑndert...
POWERCFG /CHANGE monitor-timeout-ac 0
POWERCFG /CHANGE monitor-timeout-dc 30
POWERCFG /CHANGE standby-timeout-ac 0
POWERCFG /CHANGE standby-timeout-dc 45
echo Der Vorgang wurde erfolgreich beendet.


REM ### Updates f¸r andere Microsoft-Produkte
echo.
echo Updates fÅr andere Microsoft-Produkte bereitstellen...
reg.exe ADD HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU /v NoAutoUpdate /t REG_DWORD /d 0 /f > NUL
reg.exe ADD HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU /v AllowMUUpdateService /t REG_DWORD /d 1 /f


REM ### Lenovo System Update installieren
echo.
choice /M "Lenovo System Update installieren"
if errorlevel 2 goto NOLSU
start /WAIT .\"Lenovo System Update\system_update_5.07.0136"
:NOLSU


REM ### Browser installieren
echo.
choice /M "Browser installieren"
if errorlevel 2 goto NOCHRM
start /WAIT .\Browser\NiniteChromeFirefox.exe
:NOCHRM


REM ### Internetverbindung pr¸fen
PING -n 1 141.1.1.1 > NUL
IF %errorlevel% EQU 0 GOTO WITHINET
echo.
echo Keine Internetverbindung! Bitte Verbindung herstellen und Installation fÅr Adobe Reader, Chrome und Edge manuell w‰hlen.
GOTO WITHOUTINET


:WITHINET
REM ### Adobe Reader installieren
echo.
choice /M "Adobe Reader installieren"
if errorlevel 2 goto NOADR
start /WAIT .\"Adobe Reader\readerdc_de_xa_install.exe"
:NOADR


:WITHOUTINET
REM ### Kennwort f¸r admin ‰ndern
echo.
choice /M "Kennwort fÅr Benutzer admin vergeben"
if errorlevel 2 goto NOPWD
net user admin !Obelix
if %errorlevel% equ 0 echo Kennwort !Obelix wurde gesetzt.
:NOPWD

REM ### Office365 installieren
echo.
choice /M "Office365 installieren"
if errorlevel 2 goto NOCHRM
start /WAIT .\Office365\OfficeSetup.exe
:NOCHRM


REM ### Computernamen ‰ndern
echo.
choice /M "Computernamen Ñndern"
if errorlevel 2 (
	echo.
	goto NOCPNM
)
set /P ComputernameNew=Bitte neuen Computernamen eingeben:
wmic computersystem where name="%computername%" call rename name="%ComputernameNew%"
:NOCPNM


REM ### Neustart
choice /M "Computer jetzt neu starten"
if errorlevel 2 goto NORBT
shutdown /r /t 0
:NORBT