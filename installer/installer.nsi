!include MUI2.nsh

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE license.rtf
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_STARTMENU pageid variable
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

Function .onInit
  SetOutPath $TEMP
  File /oname=spltmp.bmp "splash_image.bmp"

  advsplash::show 500 600 400 -1 $TEMP\spltmp

  Pop $0 ; $0 has '1' if the user closed the splash screen early,
         ; '0' if everything closed normally, and '-1' if some error occurred.

  Delete $TEMP\spltmp.bmp
FunctionEnd

Page Welcome
Page License
Page Components
Page Directory
UninstPage uninstConfirm
UninstPage Directory