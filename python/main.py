import pywintypes
import pywinauto
import dropbox

import subprocess
import argparse
import inspect
import shutil
import time
import os

from datetime import datetime
from util import utility, monitor


def set_dropbox_clipboard():
  dbx = dropbox.Dropbox(utility.get_setting('access_token'))

  clipboard_string = utility.get_clipboard()
  if not clipboard_string: return

  try:
    dbx.files_upload(f=clipboard_string.encode(),
                     path=utility.get_setting('dropbox_clipboard_path'),
                     mute=True,
                     mode=dropbox.files.WriteMode.overwrite)

    print('Upload succeeded')

  except Exception as err:
    print("Failed to upload\n{0}".format(err))


def get_dropbox_clipboard():
  dbx = dropbox.Dropbox(utility.get_setting('access_token'))
  metadata, f = dbx.files_download(utility.get_setting('dropbox_clipboard_path'))
  utility.set_clipboard(f.content)


def toggle_input_source():
  monitor.toggle_input_source()


def get_monitor_model():
  monitor.get_monitor_model()


def set_input_to_displayport():
  monitor.set_input_source(0x0F)


def set_input_to_hdmi_1():
  monitor.set_input_source(0x11)


def set_input_to_hdmi_2():
  monitor.set_input_source(0x12)


def backup_hades_save():

  saved_games_directory = os.path.join(os.path.expanduser('~'), 'Documents', 'Saved Games')
  hades_directory       = os.path.join(saved_games_directory, 'Hades')
  backups_directory     = os.path.join(saved_games_directory, 'Hades Backups')

  if not os.path.isdir(backups_directory):
    os.mkdir(backups_directory)

  current_time = datetime.now().isoformat(timespec='seconds').replace(':','-')
  backup_name = 'Hades {0}'.format(current_time)
  backup_directory = os.path.join(backups_directory, backup_name)

  shutil.copytree(hades_directory, backup_directory)


def load_hades_backup(restart="y"):

  os.system("TASKKILL /F /IM hades.exe")
  time.sleep(1)

  saved_games_directory = os.path.join(os.path.expanduser('~'), 'Documents', 'Saved Games')
  hades_directory       = os.path.join(saved_games_directory, 'Hades')
  backups_directory     = os.path.join(saved_games_directory, 'Hades Backups')

  if not os.path.isdir(backups_directory): return

  walk_results = sorted(os.walk(top=backups_directory), reverse=True)

  if not walk_results: return

  backup_directory = walk_results[0][0]

  if os.path.isdir(hades_directory):
    shutil.rmtree(hades_directory)
    time.sleep(1)

  shutil.copytree(backup_directory, hades_directory)

  if restart == 'y':
    subprocess.call(r"C:\Program Files (x86)\Steam\Steam.exe -applaunch 1145360")


def exit_hades():
  os.system("TASKKILL /F /IM hades.exe")



def delete_last_hades_backup():

  saved_games_directory = os.path.join(os.path.expanduser('~'), 'Documents', 'Saved Games')
  backups_directory     = os.path.join(saved_games_directory, 'Hades Backups')

  if not os.path.isdir(backups_directory): return

  walk_results = sorted(os.walk(top=backups_directory), reverse=True)

  if not walk_results: return

  backup_directory = walk_results[0][0]

  shutil.rmtree(backup_directory)



def main():
  parser = argparse.ArgumentParser()
  parser.add_argument('-script', type=str)
  parser.add_argument('-restart', type=str)
  args = parser.parse_args()

  script = globals()[args.script]
  parameter_names = inspect.signature(script).parameters.keys()

  return script(**{x: vars(args)[x] for x in parameter_names if x in vars(args)})


if __name__ == '__main__': main()