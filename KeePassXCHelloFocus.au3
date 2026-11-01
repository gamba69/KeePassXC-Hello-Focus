#pragma compile(ExecLevel, asInvoker)
#pragma compile(FileDescription, KeePassXC Hello Focus - Windows Hello dialog foreground helper)
#pragma compile(ProductName, KeePassXC Hello Focus)
#pragma compile(InternalName, KeePassXCHelloFocus)
#pragma compile(OriginalFilename, KeePassXCHelloFocus.exe)
#pragma compile(FileVersion, 0.1.0.0)
#pragma compile(ProductVersion, 0.1.0.0)



; KeePassXC Hello Focus: Windows Hello / Windows Security dialog foreground helper.

; Does not read PINs, passwords or keystrokes, and does not use the network.

#include <AutoItConstants.au3>

#include <Misc.au3>

#include <GUIConstantsEx.au3>

#include <WindowsConstants.au3>

#include <TrayConstants.au3>



; Only one instance in a Windows logon session.

; Return 0 silently on a duplicate launch, without adding a second tray icon.

If _Singleton("KeePassXCHelloFocus", 1) = 0 Then Exit 0



Opt("TrayAutoPause", 0)

Opt("TrayMenuMode", 3) ; Hide AutoIt's default menu; no automatic item checkmarks.

; Event-driven UI: tray and About react immediately, independent of the 200 ms watcher.

Opt("TrayOnEventMode", 1)

Opt("GUIOnEventMode", 1)



; Opt into the native Windows dark popup-menu palette, following the Windows

; *apps* theme. This must run before TrayCreateItem() creates the first menu.

; Undocumented UxTheme ordinal exports may be missing on older builds;

; in that case the normal system tray menu is preserved.

_EnableNativeDarkMenus()



; Use a dedicated icon with fewer lines for the 16x16 tray display.

; FileInstall embeds KeePassXCHelloFocusTray.ico in the compiled EXE.

Global $g_sTrayIconPath = @ScriptDir & "\KeePassXCHelloFocusTray.ico"

Global $g_bTempTrayIcon = False

If @Compiled Then

    $g_sTrayIconPath = @TempDir & "\KeePassXCHelloFocusTray_" & @AutoItPID & ".ico"

    If FileInstall(".\KeePassXCHelloFocusTray.ico", $g_sTrayIconPath, 1) Then

        $g_bTempTrayIcon = True

        TraySetIcon($g_sTrayIconPath)

        TraySetPauseIcon($g_sTrayIconPath)

    Else

        ; The EXE icon remains a safe fallback if extraction is blocked.

        TraySetIcon(@ScriptFullPath, -1)

    EndIf

Else

    TraySetIcon($g_sTrayIconPath)

    TraySetPauseIcon($g_sTrayIconPath)

EndIf

OnAutoItExitRegister("_OnExit")



TraySetToolTip("KeePassXC Hello Focus - Windows Hello on top")

Global $g_idAboutMenu = TrayCreateItem("About...")

TrayCreateItem("")

Global $g_idExitMenu = TrayCreateItem("Exit")

TrayItemSetOnEvent($g_idAboutMenu, "_ShowAbout")

TrayItemSetOnEvent($g_idExitMenu, "_Quit")

; Recreate the cached menu theme after the tray items have been created.

_FlushNativeMenuThemes()

TraySetState($TRAY_ICONSTATE_SHOW)



Global $g_hAbout = 0

Global $g_idAboutClose = 0

Global $g_idAboutTitle = 0
Global $g_idAboutVersion = 0

Global $g_idAboutHeading = 0

Global $g_idAboutBody = 0

Global $g_idAboutDetails = 0

Global $g_idAboutDivider = 0

Global $g_iAppliedAboutTheme = -1

Global $g_bThemeRefreshNeeded = False



; Original window-identification and TOPMOST behavior kept unchanged.

Global Const $WINDOW = "[CLASS:Credential Dialog Xaml Host]"

Global Const $POLL_INTERVAL_MS = 200

Global Const $REASSERT_COUNT = 4   ; Retry TOPMOST for about 0.8 s.



; Build About once, hidden. Showing and hiding it never rebuilds its controls.

_CreateAbout()

; Windows broadcasts these messages when the app color theme changes.

; The callbacks only set a flag; UI changes are done safely in the main loop.

GUIRegisterMsg($WM_SETTINGCHANGE, "_OnWindowsThemeSignal")

GUIRegisterMsg($WM_THEMECHANGED, "_OnWindowsThemeSignal")



Local $lastWindow = 0

Local $reassertLeft = 0



While 1

    If $g_bThemeRefreshNeeded Then

        $g_bThemeRefreshNeeded = False

        _ApplyAboutTheme()

    EndIf



    ; Window detection remains on the original 200 ms schedule.

    ; Tray/GUI events are dispatched by AutoIt even while this loop sleeps.

    Local $hWnd = WinGetHandle($WINDOW)

    If @error Then $hWnd = 0



    Local $visible = False

    If $hWnd <> 0 Then

        Local $state = WinGetState($hWnd)

        $visible = (BitAND($state, $WIN_STATE_VISIBLE) <> 0)

    EndIf



    If $visible Then

        If $hWnd <> $lastWindow Then

            ; New dialog: put it on top and focus it once.

            $lastWindow = $hWnd

            $reassertLeft = $REASSERT_COUNT

            WinSetOnTop($hWnd, "", $WINDOWS_ONTOP)

            WinActivate($hWnd)

        ElseIf $reassertLeft > 0 Then

            ; Reassert TOPMOST while the system dialog is being initialized.

            ; Do not repeatedly steal keyboard focus.

            WinSetOnTop($hWnd, "", $WINDOWS_ONTOP)

            $reassertLeft -= 1

        EndIf

    Else

        $lastWindow = 0

        $reassertLeft = 0

    EndIf



    Sleep($POLL_INTERVAL_MS)

WEnd



Func _CreateAbout()
    ; Initialize once and reuse this window for each About invocation.
    $g_hAbout = GUICreate("About - KeePassXC Hello Focus", 570, 351, -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU))
    GUISetOnEvent($GUI_EVENT_CLOSE, "_HideAbout", $g_hAbout)
    GUISetFont(10, 400, 0, "Segoe UI", $g_hAbout)
    If @Compiled Then
        GUISetIcon(@ScriptFullPath, 0, $g_hAbout)
    Else
        GUISetIcon(@ScriptDir & "\KeePassXCHelloFocus.ico", 0, $g_hAbout)
    EndIf

    $g_idAboutTitle = GUICtrlCreateLabel("KeePassXC Hello Focus", 22, 18, 525, 32)
    GUICtrlSetFont($g_idAboutTitle, 15, 700, 0, "Segoe UI")

    $g_idAboutVersion = GUICtrlCreateLabel("Version " & _AppVersion(), 22, 50, 520, 19)
    GUICtrlSetFont($g_idAboutVersion, 9, 400, 0, "Segoe UI")

    $g_idAboutHeading = GUICtrlCreateLabel("What this program does", 22, 82, 520, 24)
    GUICtrlSetFont($g_idAboutHeading, 10, 700, 0, "Segoe UI")

    $g_idAboutBody = GUICtrlCreateLabel( _
        "Windows Hello / Windows Security authentication prompts can " & _
        "appear behind other windows, including when using KeePassXC. " & _
        "This utility detects those prompts, brings them to the foreground, " & _
        "and places them above regular windows.", _
        22, 111, 520, 75)

    $g_idAboutDetails = GUICtrlCreateLabel( _
        "Runs quietly in the system tray. Only one instance is allowed " & _
        "per Windows logon session." & @CRLF & @CRLF & _
        "Independent of KeePassXC; not an official KeePassXC component. " & _
        "Does not read PINs, passwords, or keystrokes, and does not use " & _
        "the network. Windows may restrict protected system dialogs.", _
        22, 192, 520, 103)

    GUICtrlSetBkColor($g_idAboutTitle, $GUI_BKCOLOR_TRANSPARENT)
    GUICtrlSetBkColor($g_idAboutVersion, $GUI_BKCOLOR_TRANSPARENT)
    GUICtrlSetBkColor($g_idAboutHeading, $GUI_BKCOLOR_TRANSPARENT)
    GUICtrlSetBkColor($g_idAboutBody, $GUI_BKCOLOR_TRANSPARENT)
    GUICtrlSetBkColor($g_idAboutDetails, $GUI_BKCOLOR_TRANSPARENT)

    $g_idAboutDivider = GUICtrlCreateLabel("", 22, 303, 524, 1)
    $g_idAboutClose = GUICtrlCreateButton("Close", 441, 313, 105, 28)
    GUICtrlSetOnEvent($g_idAboutClose, "_HideAbout")
    _ApplyAboutTheme()
EndFunc

; Read the version directly from the compiled executable metadata.
; The same FileVersion pragma is used to validate release tags during builds.
Func _AppVersion()
    If Not @Compiled Then Return "development"
    Local $sVersion = FileGetVersion(@ScriptFullPath)
    If @error Or $sVersion = "" Then Return "unknown"
    Return StringRegExpReplace($sVersion, "\.0$", "")
EndFunc

Func _ShowAbout()

    ; Check the current Windows app theme every time the window opens.

    _ApplyAboutTheme()

    GUISetState(@SW_SHOW, $g_hAbout)

    WinActivate($g_hAbout)

EndFunc



; 0 = dark, 1 = light in HKCU\...\Themes\Personalize\AppsUseLightTheme.

; Windows stores this as REG_DWORD. Missing settings default to light.

Func _WindowsAppsUseDarkTheme()

    Local $vValue = RegRead("HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")

    If @error Then Return False

    Return (Number($vValue) = 0)

EndFunc



; Use the system app mode for the entire dialog, including the title bar,

; window background, text and themed Close button. No new window is created.

Func _ApplyAboutTheme()

    If $g_hAbout = 0 Then Return

    Local $bDark = _WindowsAppsUseDarkTheme()

    Local $iTheme = 0

    If $bDark Then $iTheme = 1

    If $iTheme = $g_iAppliedAboutTheme Then Return



    Local $iBackground, $iForeground, $iSecondary, $iDivider, $sButtonTheme

    If $bDark Then

        $iBackground = 0x202124

        $iForeground = 0xF5F5F5

        $iSecondary = 0xD0D2D6

        $iDivider = 0x44464B

        $sButtonTheme = "DarkMode_Explorer"

    Else

        $iBackground = 0xF7F8FA

        $iForeground = 0x202124

        $iSecondary = 0x474C54

        $iDivider = 0xD9DEE5

        $sButtonTheme = "Explorer"

    EndIf



    GUISetBkColor($iBackground, $g_hAbout)

    GUICtrlSetColor($g_idAboutTitle, $iForeground)
    GUICtrlSetColor($g_idAboutVersion, $iSecondary)

    GUICtrlSetColor($g_idAboutHeading, $iForeground)

    GUICtrlSetColor($g_idAboutBody, $iSecondary)

    GUICtrlSetColor($g_idAboutDetails, $iSecondary)

    GUICtrlSetBkColor($g_idAboutDivider, $iDivider)



    ; Ask UxTheme for the system button style. Do not force classic buttons.

    ; The process has already opted into AllowDark through SetPreferredAppMode.

    DllCall("uxtheme.dll", "long", "SetWindowTheme", "hwnd", GUICtrlGetHandle($g_idAboutClose), "wstr", $sButtonTheme, "ptr", 0)



    ; DWM title-bar coloring is separate from client-area coloring.

    ; Windows 11 uses attribute 20; some Windows 10 builds require 19.

    Local $tDark = DllStructCreate("int")

    DllStructSetData($tDark, 1, $iTheme)

    Local $aResult = DllCall("dwmapi.dll", "long", "DwmSetWindowAttribute", "hwnd", $g_hAbout, "dword", 20, "ptr", DllStructGetPtr($tDark), "dword", 4)

    If Not @error Then

        If $aResult[0] <> 0 Then

            DllCall("dwmapi.dll", "long", "DwmSetWindowAttribute", "hwnd", $g_hAbout, "dword", 19, "ptr", DllStructGetPtr($tDark), "dword", 4)

        EndIf

    EndIf



    $g_iAppliedAboutTheme = $iTheme

    _FlushNativeMenuThemes()

EndFunc



; A Windows message handler must return promptly: never modify GUI here.

Func _OnWindowsThemeSignal($hWnd, $iMsg, $wParam, $lParam)

    $g_bThemeRefreshNeeded = True

    Return $GUI_RUNDEFMSG

EndFunc



Func _HideAbout()

    ; Do not destroy/rebuild the window on each click.

    GUISetState(@SW_HIDE, $g_hAbout)

EndFunc



Func _Quit()

    Exit 0

EndFunc



Func _OnExit()

    If $g_hAbout <> 0 Then GUIDelete($g_hAbout)

    If $g_bTempTrayIcon Then FileDelete($g_sTrayIconPath)

EndFunc



; --- Native dark-mode tray menu ---------------------------------------------

; UxTheme.dll ordinal 135 (Windows 10 1903+):

;   SetPreferredAppMode(1) = AllowDark. Unlike ForceDark(2), this follows the

;   user's Settings > Personalization > Colors > Choose your mode > App mode.

; UxTheme.dll ordinal 136: FlushMenuThemes(). Both are undocumented Windows

; exports. A failure must never prevent the tray/menu from working normally.

Func _EnableNativeDarkMenus()

    Local $aMode = DllCall("uxtheme.dll", "int", 135, "int", 1)

    If @error Then Return False

    _FlushNativeMenuThemes()

    Return True

EndFunc



Func _FlushNativeMenuThemes()

    Local $aFlush = DllCall("uxtheme.dll", "none", 136)

    Return (Not @error)

EndFunc

