; #Warn  ; Enable warnings to assist with detecting common errors.

#Include <JSON>

SetWorkingDir %A_ScriptDir%
SplitPath, A_ScriptDir,, hotkeys_directory

; SetTitleMatchMode, RegEx

; Capslock::Esc

; Finds monitor handle
getMonitorHandle()
{
  ; Initialize Monitor handle
  hMon := DllCall("MonitorFromPoint"
    , "int64", 0 ; point on monitor
    , "uint", 1) ; flag to return primary monitor on failure


  ; Get Physical Monitor from handle
  VarSetCapacity(Physical_Monitor, 8 + 256, 0)

  DllCall("dxva2\GetPhysicalMonitorsFromHMONITOR"
    , "int", hMon   ; monitor handle
    , "uint", 1   ; monitor array size
    , "int", &Physical_Monitor)   ; point to array with monitor

  return hPhysMon := NumGet(Physical_Monitor)
}

destroyMonitorHandle(handle)
{
  DllCall("dxva2\DestroyPhysicalMonitor", "int", handle)
}

; Used to change the monitor source
; DVI = 3
; HDMI = 4
; YPbPr = 12
setMonitorInputSource(source)
{
  handle := getMonitorHandle()
  DllCall("dxva2\SetVCPFeature"
    , "int", handle
    , "char", 0x60 ;VCP code for Input Source Select
    , "uint", source)
  destroyMonitorHandle(handle)
}

; Gets Monitor source
getMonitorInputSource()
{
  handle := getMonitorHandle()
  DllCall("dxva2\GetVCPFeatureAndVCPFeatureReply"
    , "int", handle
    , "char", 0x60 ;VCP code for Input Source Select
    , "Ptr", 0
    , "uint*", currentValue
    , "uint*", maximumValue)
  destroyMonitorHandle(handle)
  return currentValue
}


F12::

  WinGetActiveStats, title, current_window_width, current_window_height, current_window_left, current_window_top

  current_window_center_x := current_window_left + current_window_width  / 2
  current_window_center_y := current_window_top  + current_window_height / 2

  SysGet, MonitorCount, MonitorCount

  padding := 8

  Loop, %MonitorCount%
  {
    SysGet, Monitor%A_Index%, MonitorWorkArea, %A_Index%

    monitor_right  := Monitor%A_Index%Right
    monitor_left   := Monitor%A_Index%Left
    monitor_top    := Monitor%A_Index%Top
    monitor_bottom := Monitor%A_Index%Bottom

    monitor_width  := monitor_right  - monitor_left
    monitor_height := monitor_bottom - monitor_top

    if   ((current_window_center_x >= monitor_left
      and  current_window_center_x <  monitor_right)
      and (current_window_center_y >= monitor_top
      and  current_window_center_y <  monitor_bottom))
    {
      monitor_center_x := monitor_left + Floor(monitor_width /2)
      monitor_center_y := monitor_top  + Floor(monitor_height/2)

      new_window_left := monitor_center_x - current_window_width /2
      new_window_top  := monitor_center_y - current_window_height/2

      if    (Abs(new_window_left - current_window_left) < 3)
        and (Abs(new_window_top  - current_window_top)  < 3)
      {
        new_window_width  := Floor(current_window_width      )
        ; new_window_height := Floor(current_window_width / 1.5)
        new_window_height := monitor_height - 2*padding

        new_window_left := monitor_center_x - new_window_width /2
        ; new_window_top  := monitor_center_y - new_window_height/2
        new_window_top  := monitor_top + padding

      }
      else
      {
        new_window_width  := current_window_width
        new_window_height := current_window_height
      }

      WinMove, %title%,, new_window_left, new_window_top, new_window_width, new_window_height

      break
    }

  }

return

!F12::
  WinGetActiveStats, title, current_window_width, current_window_height, current_window_left, current_window_top

  current_window_center_x := current_window_left + current_window_width  / 2
  current_window_center_y := current_window_top  + current_window_height / 2

  SysGet, MonitorCount, MonitorCount

  new_window_left := 0
  new_window_top := 0
  new_window_width := 0
  new_window_height := 10000

  Loop, %MonitorCount%
  {
    SysGet, Monitor%A_Index%, MonitorWorkArea, %A_Index%

    monitor_right  := Monitor%A_Index%Right
    monitor_left   := Monitor%A_Index%Left
    monitor_top    := Monitor%A_Index%Top
    monitor_bottom := Monitor%A_Index%Bottom

    if (monitor_right > new_window_width) {
      new_window_width := monitor_right
    }

    if (monitor_bottom < new_window_height) {
      new_window_height := monitor_bottom
    }
  }

  WinMove, %title%,, new_window_left, new_window_top, new_window_width, new_window_height

return



^F12::

  WinGetActiveStats, title, current_window_width, current_window_height, current_window_left, current_window_top

  current_window_center_x := current_window_left + current_window_width  / 2
  current_window_center_y := current_window_top  + current_window_height / 2

  new_window_width  := Floor(current_window_width  * 1.1)
  new_window_height := Floor(current_window_height * 1.1)

  SysGet, MonitorCount, MonitorCount

  Loop, %MonitorCount%
  {
    SysGet, Monitor%A_Index%, MonitorWorkArea, %A_Index%

    monitor_right  := Monitor%A_Index%Right
    monitor_left   := Monitor%A_Index%Left
    monitor_top    := Monitor%A_Index%Top
    monitor_bottom := Monitor%A_Index%Bottom

    width  := monitor_right  - monitor_left
    height := monitor_bottom - monitor_top

    if (    (current_window_center_x > monitor_left and current_window_center_x < monitor_right)
      and (current_window_center_y > monitor_top  and current_window_center_y < monitor_bottom))
    {
      new_window_left := monitor_left + Floor(width /2 - new_window_width /2)
      new_window_top  := monitor_top  + Floor(height/2 - new_window_height/2)

      WinMove, %title%,, new_window_left, new_window_top, new_window_width, new_window_height

      break
    }
  }

return



^+F12::

  WinGetActiveStats, title, current_window_width, current_window_height, current_window_left, current_window_top

  current_window_center_x := current_window_left + current_window_width  / 2
  current_window_center_y := current_window_top  + current_window_height / 2

  new_window_width  := Floor(current_window_width  / 1.1)
  new_window_height := Floor(current_window_height / 1.1)

  SysGet, MonitorCount, MonitorCount

  Loop, %MonitorCount%
  {
    SysGet, Monitor%A_Index%, MonitorWorkArea, %A_Index%

    monitor_right  := Monitor%A_Index%Right
    monitor_left   := Monitor%A_Index%Left
    monitor_top    := Monitor%A_Index%Top
    monitor_bottom := Monitor%A_Index%Bottom

    width  := monitor_right  - monitor_left
    height := monitor_bottom - monitor_top

    if (    (current_window_center_x >= monitor_left and current_window_center_x < monitor_right)
      and (current_window_center_y >= monitor_top  and current_window_center_y < monitor_bottom))
    {
      new_window_left := monitor_left + Floor(width  / 2 - new_window_width  / 2)
      new_window_top  := monitor_top  + Floor(height / 2 - new_window_height / 2)

      WinMove, %title%,, new_window_left, new_window_top, new_window_width, new_window_height

      break
    }
  }

return



^Numpad8::

  SysGet, MonitorWorkArea, MonitorWorkArea

  WinGetActiveStats, title, current_window_width, current_window_height, current_window_left, current_window_top

  w_screen := MonitorWorkAreaRight
  h_screen := MonitorWorkAreaBottom

  new_window_height := current_window_height * 1.1
  new_window_top := h_screen/2 - new_window_height/2

  WinMove, %title%,, current_window_left, new_window_top, current_window_width, new_window_height

return



^Numpad2::

  SysGet, MonitorWorkArea, MonitorWorkArea

  WinGetActiveStats, title, current_window_width, current_window_height, current_window_left, current_window_top

  w_screen := MonitorWorkAreaRight
  h_screen := MonitorWorkAreaBottom

  new_window_height := current_window_height / 1.1
  new_window_top := h_screen/2 - new_window_height/2

  WinMove, %title%,, current_window_left, new_window_top, current_window_width, new_window_height

return



^Numpad6::

  SysGet, MonitorWorkArea, MonitorWorkArea

  WinGetActiveStats, title, current_window_width, current_window_height, current_window_left, current_window_top

  w_screen := MonitorWorkAreaRight
  h_screen := MonitorWorkAreaBottom

  new_window_width := current_window_width * 1.1
  new_window_left := w_screen/2 - new_window_width/2

  WinMove, %title%,, new_window_left, current_window_top, new_window_width, current_window_height

return



^Numpad4::

  SysGet, MonitorWorkArea, MonitorWorkArea

  WinGetActiveStats, title, current_window_width, current_window_height, current_window_left, current_window_top

  w_screen := MonitorWorkAreaRight
  h_screen := MonitorWorkAreaBottom

  new_window_width := current_window_width / 1.1
  new_window_left := w_screen/2 - new_window_width/2

  WinMove, %title%,, new_window_left, current_window_top, new_window_width, current_window_height

return


#c::
  WinGetActiveStats, title, current_window_width, current_window_height, current_window_left, current_window_top
  position := RegExMatch(title, "O).*(?= - )", match_obj)
  if (position > 0) {
    title := match_obj.Value(0)
  }
  position := RegExMatch(title, "O)(?<=(FW: |RE: )).*", match_obj)
  if (position > 0) {
    title := match_obj.Value(0)
  }
  Clipboard := title
  return
return


^#v::

  if (A_ComputerName = "HTE20190624") {
    run, %comspec% /c cd /d "%hotkeys_directory%" & .\venv\Scripts\activate & python .\python\main.py -script set_dropbox_clipboard & exit,,
  }
  else if (A_ComputerName = "SCOOPER17") {
    run, %comspec% /c cd /d "%hotkeys_directory%" & .\venv\Scripts\activate & python .\python\main.py -script set_dropbox_clipboard & exit,,
  }
  else if (A_ComputerName = "DESKTOP-8NEKA2M") {
    run, %comspec% /c cd /d "%hotkeys_directory%" & .\venv\Scripts\activate & python .\python\main.py -script set_dropbox_clipboard & exit,,
  }

return


^#c::

  if (A_ComputerName = "HTE20190624") {
    run, %comspec% /c cd /d "%hotkeys_directory%" & .\venv\Scripts\activate & python .\python\main.py -script get_dropbox_clipboard & exit,,
  }
  else if (A_ComputerName = "SCOOPER17") {
    run, %comspec% /c cd /d "%hotkeys_directory%" & .\venv\Scripts\activate & python .\python\main.py -script get_dropbox_clipboard & exit,,
  }
  else if (A_ComputerName = "DESKTOP-8NEKA2M") {
    run, %comspec% /c cd /d "%hotkeys_directory%" & .\venv\Scripts\activate & python .\python\main.py -script get_dropbox_clipboard & exit,,
  }

return


^#m::

  script_path := "C:\Users\scooper\OneDrive - Wolverine Pipe Line Company\Scripts\hotkeys\python\main.py"
  run, %comspec% /c py -3 "%script_path%" -script "get_monitor_model",,

return


0 & 1::
  if (A_ComputerName = "DESKTOP-8NEKA2M" and WinActive("Hades")) {
    script_path := "C:\Users\Steven Cooper\OneDrive\Scripts\hotkeys\python\main.py"
    run, %comspec% /c py -3 "%script_path%" -script "backup_hades_save",,hide
  }
return

0 & 2::

  if (A_ComputerName = "DESKTOP-8NEKA2M" and WinActive("Hades")) {
    script_path := "C:\Users\Steven Cooper\OneDrive\Scripts\hotkeys\python\main.py"
    run, %comspec% /c py -3 "%script_path%" -script "load_hades_backup" -restart "y",,hide
  }
return

0 & 3::
  if (A_ComputerName = "DESKTOP-8NEKA2M" and WinActive("Hades")) {
    script_path := "C:\Users\Steven Cooper\OneDrive\Scripts\hotkeys\python\main.py"
    run, %comspec% /c py -3 "%script_path%" -script "delete_last_hades_backup",,hide
  }
return

0 & 4::
  if (A_ComputerName = "DESKTOP-8NEKA2M" and WinActive("Hades")) {
    script_path := "C:\Users\Steven Cooper\OneDrive\Scripts\hotkeys\python\main.py"
    run, %comspec% /c py -3 "%script_path%" -script "exit_hades",,hide
  }
return

~0::
return


!^+Esc::
  script_path := "C:\Users\scooper\OneDrive - Wolverine Pipe Line Company\Scripts\hotkeys\python\main.py"

  if (A_ComputerName = "HTE20190624") {
    run, %comspec% /c py -3 "%script_path%" -script "toggle_input_source",,
  }
  else if (A_ComputerName = "SCOOPER17") {
    run, %comspec% /c py -3 "%script_path%" -script "toggle_input_source",,
  }
return




^#a::
  Send +{F10}
  Sleep 500G
  Send {a}
  ; Send {h}
  ; Sleep 100
  ; Send {c}
  ; Send {p}
return


^#l::
  Send ^#{Right}
return

^#h::
  Send ^#{Left}
return


; Hotstrings

::dwf::
  if (A_ComputerName = "HTE20190624") {
    sendinput, C:\Users\scooper\Working Files\
  }
return

::dw1::
  if (A_ComputerName = "HTE20190624") {
    sendinput, C:\Users\scooper\OneDrive - Wolverine Pipe Line Company\
  }
return

::ddd::
  if (A_ComputerName = "HTE20190624") {
    sendinput, C:\Users\scooper\Desktop
  }
return

::fuf::
  sendinput, followupflag:followup
return

#IfWinActive ahk_class MstnTop
space::XButton1

#IfWinActive ahk_class MstnTop
^space::Send {LButton down}{RButton down}{LButton up}{RButton up}

#IfWinActive ahk_class MstnTop
+Tab::WinActivate ahk_class WindowsForms10.Window.8.app.0.297b065
