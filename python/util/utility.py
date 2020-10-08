import pywintypes
import win32clipboard
import win32con
import os
import json


def get_setting(setting_name):
  settings_filepath = get_local_filepath('settings.json')
  with open(settings_filepath, 'rb') as json_file:
    settings = json.load(json_file)
    return settings.get(setting_name, None)


def get_script_directory():
  return os.path.dirname(os.path.realpath(__file__))


def get_local_filepath(filename):
  return os.path.join(get_script_directory(), filename)


def get_clipboard():
  win32clipboard.OpenClipboard()
  string = win32clipboard.GetClipboardData(win32con.CF_UNICODETEXT)
  win32clipboard.CloseClipboard()
  return string


def set_clipboard(clipboard_text):
  win32clipboard.OpenClipboard()
  win32clipboard.EmptyClipboard()
  win32clipboard.SetClipboardText(clipboard_text)
  win32clipboard.CloseClipboard()


def save_clipboard(filepath):
  string = get_clipboard()
  with open(filepath, 'w') as text_file:
    text_file.write(string)
