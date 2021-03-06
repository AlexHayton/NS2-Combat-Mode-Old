############################################################################################
#      NSIS Installation Script created by NSIS Quick Setup Script Generator v1.09.18
#               Entirely Edited with NullSoft Scriptable Installation System                
#              by Vlasis K. Barkas aka Red Wine red_wine@freemail.gr Sep 2006               
############################################################################################

!define APP_NAME "NS2 Combat Mode"
!define COMP_NAME "MCMLXXXIV"
!define WEB_SITE "http://www.unknownworlds.com/forums/index.php?showtopic=111818&st=0#entry1813965"
!define VERSION "1.7.7.0"
!define COPYRIGHT "Free-as-in-Beer"
!define DESCRIPTION "Natural Selection 2 Combat Mode"
!define LICENSE_TXT "LICENSE.txt"
!define INSTALLER_NAME "CombatMode-${VERSION}-Setup.exe"
!define MAIN_APP_EXE "Launch Combat Mode.lnk"
!define MAIN_APP_ICON "..\NS2.exe"
!define INSTALL_TYPE "SetShellVarContext all"
!define REG_ROOT "HKLM"
!define REG_APP_PATH "Software\Microsoft\Windows\CurrentVersion\App Paths\${MAIN_APP_EXE}"
!define UNINSTALL_PATH "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"
!define SM_FOLDER "NS2 Combat Mode"
!define MOD_FOLDER "Combat"

######################################################################

VIProductVersion  "${VERSION}"
VIAddVersionKey "ProductName"  "${APP_NAME}"
VIAddVersionKey "CompanyName"  "${COMP_NAME}"
VIAddVersionKey "LegalCopyright"  "${COPYRIGHT}"
VIAddVersionKey "FileDescription"  "${DESCRIPTION}"
VIAddVersionKey "FileVersion"  "${VERSION}"

######################################################################

#SetCompressor ZLIB
Name "${APP_NAME}"
Caption "${APP_NAME}"
OutFile "${INSTALLER_NAME}"
BrandingText "${APP_NAME}"
XPStyle on
InstallDir "$PROGRAMFILES\Steam\steamapps\common\natural selection 2\${MOD_FOLDER}"
InstallDirRegKey "${REG_ROOT}" "${REG_APP_PATH}" ""
Var OVERMINDDIR
Var MAINNS2FOLDER

######################################################################

!include "MUI.nsh"

!define MUI_ABORTWARNING
!define MUI_UNABORTWARNING

!insertmacro MUI_PAGE_WELCOME

!ifdef LICENSE_TXT
!insertmacro MUI_PAGE_LICENSE "${LICENSE_TXT}"
!endif

#!insertmacro MUI_PAGE_COMPONENTS

!insertmacro MUI_PAGE_DIRECTORY

!ifdef REG_START_MENU
!define MUI_STARTMENUPAGE_NODISABLE
!define MUI_STARTMENUPAGE_DEFAULTFOLDER "${SM_FOLDER}"
!define MUI_STARTMENUPAGE_REGISTRY_ROOT "${REG_ROOT}"
!define MUI_STARTMENUPAGE_REGISTRY_KEY "${UNINSTALL_PATH}"
!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "${REG_START_MENU}"
!insertmacro MUI_PAGE_STARTMENU Application ${SM_FOLDER}
!endif

!insertmacro MUI_PAGE_INSTFILES

!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT "Launch ${SM_FOLDER}"
!define MUI_FINISHPAGE_RUN_FUNCTION "LaunchLink"
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM

!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_UNPAGE_FINISH

!insertmacro MUI_LANGUAGE "English"

######################################################################

Function .onInit
  
  # Get the steam installation folder and default to that.
  Push $0
  ReadRegStr $0 HKLM SOFTWARE\Wow6432Node\Valve\Steam "InstallPath"
  StrCmp $0 "" 0 GotInstallDir
  ReadRegStr $0 HKLM SOFTWARE\Valve\Steam "InstallPath"
  StrCmp $0 "" NotGotInstallDir GotInstallDir
  GotInstallDir:
  StrCpy $INSTDIR "$0\steamapps\common\natural selection 2\${MOD_FOLDER}"
  StrCpy $OVERMINDDIR "$0\steamapps\common\natural selection 2\NS2GmOvrmind"
  StrCpy $MAINNS2FOLDER "$0\steamapps\common\natural selection 2"
  Goto AllFinished
  
  NotGotInstallDir:
  StrCpy $OVERMINDDIR "$PROGRAMFILES\Steam\steamapps\common\natural selection 2\NS2GmOvrmind"
  StrCpy $MAINNS2FOLDER "$PROGRAMFILES\Steam\steamapps\common\natural selection 2"
  AllFinished:
  Pop $0
  
  InitPluginsDir
  #File /oname=$PLUGINSDIR\splash.bmp "splash.bmp"

  File /oname=$PLUGINSDIR\splash.bmp "splash.bmp"
  advsplash::show 1000 600 400 0x04025C $PLUGINSDIR\splash
  Pop $0 

  Delete $PLUGINSDIR\splash.bmp

FunctionEnd

######################################################################

Function LaunchLink
  ExecShell "" "$SMPROGRAMS\${SM_FOLDER}\${APP_NAME}.lnk"
FunctionEnd

######################################################################

Section "NS2 Combat Mode" MainProgram
${INSTALL_TYPE}
SetOverwrite ifnewer
SetOutPath "$INSTDIR"
File "..\editor_setup.xml"
File "..\game_setup.xml"
File "LICENSE.txt"
File "..\README"
SetOutPath "$INSTDIR\ui"
File "..\ui\experience.dds"
SetOutPath "$INSTDIR\lua"
File "..\lua\AlienTeam.lua"
File "..\lua\Alien_Client.lua"
File "..\lua\Balance.lua"
File "..\lua\BalanceHealth.lua"
File "..\lua\BalanceMisc.lua"
File "..\lua\BindingsDialog.lua"
File "..\lua\CombatModeVersionCheck.lua"
File "..\lua\CommandStructure_Server.lua"
File "..\lua\ConsoleCommands_Client.lua"
File "..\lua\ConsoleCommands_Server.lua"
File "..\lua\CreateServer.lua"
File "..\lua\Globals.lua"
File "..\lua\Gorge.lua"
File "..\lua\GUIFeedback.lua"
File "..\lua\GUIMarineHUD.lua"
File "..\lua\GUIScoreboard.lua"
File "..\lua\InfantryPortal.lua"
File "..\lua\LiveMixin.lua"
File "..\lua\LiveScriptActor_Server.lua"
File "..\lua\Main.lua"
File "..\lua\MainMenu.lua"
File "..\lua\Marine.lua"
File "..\lua\MedPack.lua"
File "..\lua\NetworkMessages.lua"
File "..\lua\NetworkMessages_Server.lua"
File "..\lua\NS2Gamerules.lua"
File "..\lua\Player.lua"
File "..\lua\PlayerEffects.lua"
File "..\lua\Player_Client.lua"
File "..\lua\Player_Server.lua"
File "..\lua\PlayingTeam.lua"
File "..\lua\PowerPoint.lua"
File "..\lua\PowerPoint_Server.lua"
File "..\lua\Scan.lua"
File "..\lua\Scoreboard.lua"
File "..\lua\ScoreDisplay.lua"
File "..\lua\Server.lua"
File "..\lua\Structure_Server.lua"
File "..\lua\TechData.lua"
File "..\lua\TechNode.lua"
File "..\lua\TechPoint_Server.lua"
File "..\lua\TechTree.lua"
File "..\lua\TechTree_Server.lua"
File "..\lua\TechTreeConstants.lua"
File "..\lua\AlienTeamCombat.lua"
File "..\lua\CombatBalance.lua"
File "..\lua\Experience.lua"
File "..\lua\GUIExperience.lua"
File "..\lua\GUITechUpgrade.lua"
File "..\lua\MarineTeamCombat.lua"
SetOutPath "$INSTDIR\lua\Weapons\Marine"
File "..\lua\Weapons\Marine\Welder.lua"
SetOutPath "$INSTDIR\lua\Weapons\Alien"
File "..\lua\Weapons\Alien\HydraAbility.lua"
File "..\lua\Weapons\Alien\SpitSpray.lua"
SetOutPath "$INSTDIR\cinematics"
File "..\cinematics\level_up.cinematic"
SetOutPath "$INSTDIR\maps"
File "..\maps\ns2_junction_combat.level"
SetOutPath "$INSTDIR\maps\overviews"
File "..\maps\overviews\ns2_junction_combat.hmp"
File "..\maps\overviews\ns2_junction_combat.tga"
File "..\maps\overviews\ns2_junction_combat_hmp.tga"
SectionEnd

Section "NS2GmOvrMind" NS2GmOvrMind
## NS2GmOvrMind stuff
#SetOverwrite off
SetOutPath "$MAINNS2FOLDER"
File "..\msvcp100.dll"
File "..\msvcr100.dll"
File "..\QtCore4.dll"
File "..\QtNetwork4.dll"
File "..\QtXml4.dll"
File "..\LibIRCClientQt.dll"
File "..\libmysql.dll"
File "..\QtSql4.dll"
SetOutPath "$OVERMINDDIR"
File "..\NS2GmOvrMind\Do_not_modify.txt"
File "..\NS2GmOvrMind\Editor_Setup.xml"
File "..\NS2GmOvrMind\Email_Author.url"
File "..\NS2GmOvrMind\Game_Setup.xml"
File "..\NS2GmOvrMind\LaunchPlatform.xml"
File "..\NS2GmOvrMind\License_Boost_BSL.txt"
File "..\NS2GmOvrMind\License_LibIRCClientQt_LGPL.txt"
File "..\NS2GmOvrMind\License_Luabind_MIT.txt"
File "..\NS2GmOvrMind\License_Lua_MIT.txt"
File "..\NS2GmOvrMind\License_Murmur_GPL.txt"
File "..\NS2GmOvrMind\License_MySQL_GPL.txt"
File "..\NS2GmOvrMind\License_Qt_LGPL.txt"
File "..\NS2GmOvrMind\License_TeamSpeak_GPL.txt"
File "..\NS2GmOvrMind\msvcp100.dll"
File "..\NS2GmOvrMind\msvcr100.dll"
File "..\NS2GmOvrMind\OwnerRestrictions.lua"
File "..\NS2GmOvrMind\QtCore4.dll"
File "..\NS2GmOvrMind\QtXml4.dll"
File "..\NS2GmOvrMind\Readme.url"
SetOutPath "$OVERMINDDIR\Binaries_x86"
File "..\NS2GmOvrMind\Binaries_x86\Do_not_modify.txt"
File "..\NS2GmOvrMind\Binaries_x86\NS2GmOvrmind.dll"
SetOutPath "$OVERMINDDIR\Configuration"
SetOverwrite off
File "..\NS2GmOvrMind\Configuration\ActiveBans.xml"
File "..\NS2GmOvrMind\Configuration\ActiveUsers.xml"
File "..\NS2GmOvrMind\Configuration\NS2GmOvrmind_ClientConfiguration.lua"
File "..\NS2GmOvrMind\Configuration\NS2GmOvrmind_Configuration.deproj"
File "..\NS2GmOvrMind\Configuration\NS2GmOvrmind_Configuration.deuser"
File "..\NS2GmOvrMind\Configuration\NS2GmOvrmind_ServerConfiguration.example.lua"
File "..\NS2GmOvrMind\Configuration\NS2GmOvrmind_ServerConfiguration.lua"
File "..\NS2GmOvrMind\Configuration\NS2GmOvrmind_ServerConfiguration_Bans.lua"
File "..\NS2GmOvrMind\Configuration\NS2GmOvrmind_ServerConfiguration_Gameplay.lua"
File "..\NS2GmOvrMind\Configuration\NS2GmOvrmind_ServerConfiguration_Ingame.lua"
File "..\NS2GmOvrMind\Configuration\NS2GmOvrmind_ServerConfiguration_Interconnect.lua"
File "..\NS2GmOvrMind\Configuration\NS2GmOvrmind_ServerConfiguration_IRC.lua"
File "..\NS2GmOvrMind\Configuration\NS2GmOvrmind_ServerConfiguration_Log.lua"
File "..\NS2GmOvrMind\Configuration\NS2GmOvrmind_ServerConfiguration_Murmur.lua"
File "..\NS2GmOvrMind\Configuration\NS2GmOvrmind_ServerConfiguration_RCon.lua"
File "..\NS2GmOvrMind\Configuration\NS2GmOvrmind_ServerConfiguration_Server.lua"
File "..\NS2GmOvrMind\Configuration\NS2GmOvrmind_ServerConfiguration_ServerQuery.lua"
File "..\NS2GmOvrMind\Configuration\NS2GmOvrmind_ServerConfiguration_TeamSpeak.lua"
File "..\NS2GmOvrMind\Configuration\NS2GmOvrmind_ServerConfiguration_Users.lua"
File "..\NS2GmOvrMind\Configuration\NS2GmOvrmind_ServerConfiguration_WebAdmin.lua"
File "..\NS2GmOvrMind\Configuration\NS2GmOvrmind_ServerConfiguration_WebStats.lua"
SetOverwrite on
SetOutPath "$OVERMINDDIR\Internal_Data"
File "..\NS2GmOvrMind\Internal_Data\ActiveBans.xml"
File "..\NS2GmOvrMind\Internal_Data\ActiveUsers.xml"
File "..\NS2GmOvrMind\Internal_Data\Bans.xml"
File "..\NS2GmOvrMind\Internal_Data\Do_not_modify.txt"
File "..\NS2GmOvrMind\Internal_Data\Users.xml"
SetOutPath "$OVERMINDDIR\Languages"
File "..\NS2GmOvrMind\Languages\Do_not_modify.txt"
File "..\NS2GmOvrMind\Languages\English.xml"
File "..\NS2GmOvrMind\Languages\French.xml"
File "..\NS2GmOvrMind\Languages\German.xml"
CreateDirectory "$OVERMINDDIR\Logs"
SetOutPath "$OVERMINDDIR\Lua"
File "..\NS2GmOvrMind\Lua\Do_not_modify.txt"
File "..\NS2GmOvrMind\Lua\NS2GmOvrmind.deproj"
File "..\NS2GmOvrMind\Lua\NS2GmOvrmind.deuser"
File "..\NS2GmOvrMind\Lua\NS2GmOvrmind.lua"
File "..\NS2GmOvrMind\Lua\NS2GmOvrmind_Client.lua"
File "..\NS2GmOvrMind\Lua\NS2GmOvrmind_Server.lua"

SectionEnd

######################################################################

Section -Icons_Reg
SetOutPath "$INSTDIR"
WriteUninstaller "$INSTDIR\uninstall.exe"

!ifdef REG_START_MENU
!insertmacro MUI_STARTMENU_WRITE_BEGIN Application
CreateDirectory "$SMPROGRAMS\${SM_FOLDER}"
CreateShortCut "$SMPROGRAMS\${SM_FOLDER}\${APP_NAME}.lnk" "%windir%\system32\cmd.exe" '/c "cd $INSTDIR\.. && start NS2.exe -game ${MOD_FOLDER}"' "$INSTDIR\..\NS2.exe"
CreateShortCut "$SMPROGRAMS\${SM_FOLDER}\${APP_NAME} Dedicated Server.lnk" "%windir%\system32\cmd.exe" '/c "cd $INSTDIR\.. && start Server.exe -game ${MOD_FOLDER} -map ns2_junction_combat"' "$INSTDIR\..\NS2.exe"
CreateShortCut "$SMPROGRAMS\${SM_FOLDER}\Uninstall ${APP_NAME}.lnk" "$INSTDIR\uninstall.exe"
CreateShortCut "$DESKTOP\${APP_NAME}.lnk" "%windir%\system32\cmd.exe" '/c "cd $INSTDIR\.. && start NS2.exe -game ${MOD_FOLDER}"' "$INSTDIR\..\NS2.exe"
!ifdef WEB_SITE
WriteIniStr "$INSTDIR\${APP_NAME} website.url" "InternetShortcut" "URL" "${WEB_SITE}"
CreateShortCut "$SMPROGRAMS\${SM_FOLDER}\${APP_NAME} Website.lnk" "$INSTDIR\${APP_NAME} website.url"
!endif
!insertmacro MUI_STARTMENU_WRITE_END
!endif

!ifndef REG_START_MENU
CreateDirectory "$SMPROGRAMS\${SM_FOLDER}"
CreateShortCut "$SMPROGRAMS\${SM_FOLDER}\${APP_NAME}.lnk" "%windir%\system32\cmd.exe" '/c "cd $INSTDIR\.. && start NS2.exe -game ${MOD_FOLDER}"' "$INSTDIR\..\NS2.exe"
CreateShortCut "$SMPROGRAMS\${SM_FOLDER}\${APP_NAME} Dedicated Server.lnk" "%windir%\system32\cmd.exe" '/c "cd $INSTDIR\.. && start Server.exe -game ${MOD_FOLDER} -map ns2_junction_combat"' "$INSTDIR\..\NS2.exe"
CreateShortCut "$SMPROGRAMS\${SM_FOLDER}\Uninstall ${APP_NAME}.lnk" "$INSTDIR\uninstall.exe"
CreateShortCut "$DESKTOP\${APP_NAME}.lnk" "%windir%\system32\cmd.exe" '/c "cd $INSTDIR\.. && start NS2.exe -game ${MOD_FOLDER}"' "$INSTDIR\..\NS2.exe"
!ifdef WEB_SITE
WriteIniStr "$INSTDIR\${APP_NAME} website.url" "InternetShortcut" "URL" "${WEB_SITE}"
CreateShortCut "$SMPROGRAMS\${SM_FOLDER}\${APP_NAME} Website.lnk" "$INSTDIR\${APP_NAME} website.url"
!endif
!endif

WriteRegStr ${REG_ROOT} "${REG_APP_PATH}" "" "$INSTDIR\${MAIN_APP_EXE}"
WriteRegStr ${REG_ROOT} "${UNINSTALL_PATH}"  "DisplayName" "${APP_NAME}"
WriteRegStr ${REG_ROOT} "${UNINSTALL_PATH}"  "UninstallString" "$INSTDIR\uninstall.exe"
WriteRegStr ${REG_ROOT} "${UNINSTALL_PATH}"  "DisplayIcon" "$INSTDIR\..\NS2.exe"
WriteRegStr ${REG_ROOT} "${UNINSTALL_PATH}"  "DisplayVersion" "${VERSION}"
WriteRegStr ${REG_ROOT} "${UNINSTALL_PATH}"  "Publisher" "${COMP_NAME}"

!ifdef WEB_SITE
WriteRegStr ${REG_ROOT} "${UNINSTALL_PATH}"  "URLInfoAbout" "${WEB_SITE}"
!endif
SectionEnd

######################################################################

Section Uninstall
${INSTALL_TYPE}
Delete "$INSTDIR\editor_setup.xml"
Delete "$INSTDIR\game_setup.xml"
Delete "$INSTDIR\LICENSE.txt"
Delete "$INSTDIR\README"
Delete "$INSTDIR\ui\experience.dds"
Delete "$INSTDIR\lua\Alien_Client.lua"
Delete "$INSTDIR\lua\AlienTeam.lua"
Delete "$INSTDIR\lua\Balance.lua"
Delete "$INSTDIR\lua\BalanceHealth.lua"
Delete "$INSTDIR\lua\BalanceMisc.lua"
Delete "$INSTDIR\lua\BindingsDialog.lua"
Delete "$INSTDIR\lua\CombatModeVersionCheck.lua"
Delete "$INSTDIR\lua\CommandStructure_Server.lua"
Delete "$INSTDIR\lua\ConsoleCommands_Client.lua"
Delete "$INSTDIR\lua\ConsoleCommands_Server.lua"
Delete "$INSTDIR\lua\CreateServer.lua"
Delete "$INSTDIR\lua\Globals.lua"
Delete "$INSTDIR\lua\Gorge.lua"
Delete "$INSTDIR\lua\GUIFeedback.lua"
Delete "$INSTDIR\lua\GUIMarineHUD.lua"
Delete "$INSTDIR\lua\GUIScoreboard.lua"
Delete "$INSTDIR\lua\InfantryPortal.lua"
Delete "$INSTDIR\lua\LiveMixin.lua"
Delete "$INSTDIR\lua\LiveScriptActor_Server.lua"
Delete "$INSTDIR\lua\Main.lua"
Delete "$INSTDIR\lua\MainMenu.lua"
Delete "$INSTDIR\lua\Marine.lua"
Delete "$INSTDIR\lua\MedPack.lua"
Delete "$INSTDIR\lua\NetworkMessages.lua"
Delete "$INSTDIR\lua\NetworkMessages_Server.lua"
Delete "$INSTDIR\lua\NS2Gamerules.lua"
Delete "$INSTDIR\lua\Player.lua"
Delete "$INSTDIR\lua\PlayerEffects.lua"
Delete "$INSTDIR\lua\Player_Client.lua"
Delete "$INSTDIR\lua\Player_Server.lua"
Delete "$INSTDIR\lua\PlayingTeam.lua"
Delete "$INSTDIR\lua\PowerPoint.lua"
Delete "$INSTDIR\lua\PowerPoint_Server.lua"
Delete "$INSTDIR\lua\Scan.lua"
Delete "$INSTDIR\lua\Scoreboard.lua"
Delete "$INSTDIR\lua\ScoreDisplay.lua"
Delete "$INSTDIR\lua\Server.lua"
Delete "$INSTDIR\lua\Structure_Server.lua"
Delete "$INSTDIR\lua\TechData.lua"
Delete "$INSTDIR\lua\TechNode.lua"
Delete "$INSTDIR\lua\TechPoint_Server.lua"
Delete "$INSTDIR\lua\TechTree.lua"
Delete "$INSTDIR\lua\TechTree_Server.lua"
Delete "$INSTDIR\lua\TechTreeConstants.lua"
Delete "$INSTDIR\lua\AlienTeamCombat.lua"
Delete "$INSTDIR\lua\CombatBalance.lua"
Delete "$INSTDIR\lua\Experience.lua"
Delete "$INSTDIR\lua\GUIExperience.lua"
Delete "$INSTDIR\lua\GUITechUpgrade.lua"
Delete "$INSTDIR\lua\MarineTeamCombat.lua"
Delete "$INSTDIR\lua\Weapons\Marine\Welder.lua"
Delete "$INSTDIR\lua\Weapons\Alien\HydraAbility.lua"
Delete "$INSTDIR\lua\Weapons\Alien\SpitSpray.lua"
Delete "$INSTDIR\cinematics\level_up.cinematic"
Delete "$INSTDIR\maps\ns2_junction_combat.level"
Delete "$INSTDIR\maps\overviews\ns2_junction_combat.hmp"
Delete "$INSTDIR\maps\overviews\ns2_junction_combat.tga"
Delete "$INSTDIR\maps\overviews\ns2_junction_combat_hmp.tga"

RmDir "$INSTDIR\maps\overviews"
RmDir "$INSTDIR\maps"
RmDir "$INSTDIR\cinematics" 
RmDir "$INSTDIR\lua\Weapons\Marine"
RmDir "$INSTDIR\lua\Weapons\Alien"
RmDir "$INSTDIR\lua\Weapons"
RmDir "$INSTDIR\lua"
RmDir "$INSTDIR\ui"

#NS2GmOvrMind stuff
#Don't uninstall it, just in case!
 
Delete "$INSTDIR\uninstall.exe"
!ifdef WEB_SITE
Delete "$INSTDIR\${APP_NAME} website.url"
!endif

RmDir "$INSTDIR"

!ifdef REG_START_MENU
!insertmacro MUI_STARTMENU_GETFOLDER "Application" ${SM_FOLDER}
Delete "$SMPROGRAMS\${SM_Folder}\${APP_NAME}.lnk"
!ifdef WEB_SITE
Delete "$SMPROGRAMS\${SM_FOLDER}\${APP_NAME} Website.lnk"
!endif
Delete "$DESKTOP\${APP_NAME}.lnk"

RmDir "$SMPROGRAMS\${SM_FOLDER}"
!endif

!ifndef REG_START_MENU
Delete "$SMPROGRAMS\${SM_FOLDER}\${APP_NAME}.lnk"
!ifdef WEB_SITE
Delete "$SMPROGRAMS\${SM_FOLDER}\${APP_NAME} Website.lnk"
!endif
Delete "$DESKTOP\${APP_NAME}.lnk"

RmDir "$SMPROGRAMS\${SM_FOLDER}"
!endif

DeleteRegKey ${REG_ROOT} "${REG_APP_PATH}"
DeleteRegKey ${REG_ROOT} "${UNINSTALL_PATH}"
SectionEnd

LangString DESC_MainProgram ${LANG_ENGLISH} "NS2 Combat Mode"
LangString DESC_NS2GmOvrMind ${LANG_ENGLISH} "NS2GmOvrMind"

######################################################################

