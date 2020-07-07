from ctypes import windll, byref, Structure, WinError, POINTER, WINFUNCTYPE
from ctypes.wintypes import BOOL, HMONITOR, HDC, RECT, LPARAM, DWORD, BYTE, WCHAR, HANDLE

import os
import sys
import time
import csv
import subprocess


_MONITORENUMPROC = WINFUNCTYPE(BOOL, HMONITOR, HDC, POINTER(RECT), LPARAM)


class _PHYSICAL_MONITOR(Structure):
  _fields_ = [('handle', HANDLE),
        ('description', WCHAR * 128)]


def _iter_physical_monitors(close_handles=True):
  """Iterates physical monitors.
  The handles are closed automatically whenever the iterator is advanced.
  This means that the iterator should always be fully exhausted!
  If you want to keep handles e.g. because you need to store all of them and
  use them later, set `close_handles` to False and close them manually."""

  def callback(hmonitor, hdc, lprect, lparam):
    monitors.append(hmonitor)
    return True

  monitors = []
  if not windll.user32.EnumDisplayMonitors(None, None, _MONITORENUMPROC(callback), None):
    raise WinError('EnumDisplayMonitors failed')

  for monitor in monitors:
    # Get physical monitor count
    count = DWORD()
    if not windll.dxva2.GetNumberOfPhysicalMonitorsFromHMONITOR(monitor, byref(count)):
      raise WinError()
    # Get physical monitor handles
    physical_array = (_PHYSICAL_MONITOR * count.value)()
    if not windll.dxva2.GetPhysicalMonitorsFromHMONITOR(monitor, count.value, physical_array):
      raise WinError()
    for physical in physical_array:
      yield physical.handle
      if close_handles:
        if not windll.dxva2.DestroyPhysicalMonitor(physical.handle):
          raise WinError()


def get_vcp_feature_and_vcp_feature_reply(monitor, code):
  """Get current and maximun values for continuous VCP codes"""
  current_value = DWORD()
  maximum_value = DWORD()

  if not windll.dxva2.GetVCPFeatureAndVCPFeatureReply(
                   HANDLE(monitor), BYTE(code), None,
                   byref(current_value),
                   byref(maximum_value)):
    raise WinError()
  return current_value.value, maximum_value.value


def set_vcp_feature(monitor, code, value):
  """Sends a DDC command to the specified monitor.
  See this link for a list of commands:
  ftp://ftp.cis.nctu.edu.tw/pub/csie/Software/X11/private/VeSaSpEcS/VESA_Document_Center_Monitor_Interface/mccsV3.pdf
  """
  success = windll.dxva2.SetVCPFeature(HANDLE(monitor), BYTE(code), DWORD(value))
  with open('log.txt', 'a') as f: f.write(str(success))
  if not success:
    raise WinError()


def set_input_source(input_source_code):
  input_source_mccs_code = 0x60

  for handle in _iter_physical_monitors():
    current_source, _ = get_vcp_feature_and_vcp_feature_reply(handle, input_source_mccs_code)
    if current_source != input_source_code:
      set_vcp_feature(handle, input_source_mccs_code, input_source_code)


def get_current_source():
  input_source_mccs_code = 0x60
  for handle in _iter_physical_monitors():
    current_source, _ = get_vcp_feature_and_vcp_feature_reply(handle, input_source_mccs_code)
    print(current_source)


def toggle_work_input_source():
  """
  On my LG 27UK650_600, DDC/CI seems to work for a computer connected to
  DisplayPort, but not for computers connected to HDMI ports 1 or 2

  """

  input_source_mccs_code = 0x60
  hdmi_1 = 0x11
  hdmi_2 = 0x12
  display_port = 0x0F

  for handle in _iter_physical_monitors():

    current_source, _ = get_vcp_feature_and_vcp_feature_reply(handle, input_source_mccs_code)

    with open('log.txt', 'a+') as f: f.write('\n' + str(current_source))

    if current_source == display_port:
      with open('log.txt', 'a+') as f: f.write('\nAttempting to switch input to HDMI 1')
      set_vcp_feature(handle, input_source_mccs_code, hdmi_1)
    else:
      print('Attempting to set display_port')
      with open('log.txt', 'a+') as f: f.write('\nAttempting to switch input to display_port')
      set_vcp_feature(handle, input_source_mccs_code, display_port)


def toggle_dell_s2716dg_input_source():
  # Damn. The S2716DG does not support DDC/CI
  # https://www.dell.com/community/Monitors/S2716DG-Dell-DDM-is-not-supported/td-p/6072319
  input_source_mccs_code = 0x60
  hdmi_1 = 0x12
  display_port = 0x0F

  package_directory = os.path.abspath(os.path.join(os.path.dirname(__file__)))
  log_filepath = os.path.join(package_directory, 'log.txt')

  with open(log_filepath, 'a+') as f: f.write('\nIn toggle_dell_s2716dg_input_source')

  for handle in _iter_physical_monitors():

    current_source, _ = get_vcp_feature_and_vcp_feature_reply(handle, input_source_mccs_code)

    with open(log_filepath, 'a+') as f: f.write(str(current_source))

    if current_source == hdmi_1:
      print('Attempting to set display_port')
      set_vcp_feature(handle, input_source_mccs_code, display_port)
    else:
      print('Attempting to set hdmi_1')
      set_vcp_feature(handle, input_source_mccs_code, hdmi_1)

    # 0x04 is SOFT-OFF, 0x01 is ON
    # set_vcp_feature(handle, 0xd6, 0x04)
    # time.sleep(2)
    # set_vcp_feature(handle, 0xd6, 0x01)


def toggle_input_source():
  monitor_model = get_monitor_model()

  package_directory = os.path.abspath(os.path.join(os.path.dirname(__file__)))
  log_filepath = os.path.join(package_directory, 'log.txt')

  with open(log_filepath, 'a+') as f: f.write('\n'+monitor_model)

  monitor_model = get_monitor_model()

  if monitor_model == 'Dell S2716DG':
    toggle_dell_s2716dg_input_source()
  elif monitor_model == 'LG HDR 4K':
    toggle_work_input_source()


def run_get_wmiobject():
  package_directory = os.path.abspath(os.path.join(os.path.dirname(__file__)))
  # with open('log.txt', 'a+') as f: f.write(str(package_directory))
  cmd = ' '.join(["powershell.exe", "./get_wmiobject.ps1"])
  proc = subprocess.Popen(cmd, cwd=package_directory)
  proc.communicate()
  retcode = proc.returncode


def get_monitor_model():
  run_get_wmiobject()
  package_directory = os.path.abspath(os.path.join(os.path.dirname(__file__)))
  txt_filepath = os.path.join(package_directory, 'monitors.txt')
  with open(txt_filepath, mode='r', encoding='utf-16') as txt_file:
    monitor = txt_file.read()
  return monitor.strip()


if __name__ == '__main__':
  monitor = get_monitor_model()
  print(monitor)