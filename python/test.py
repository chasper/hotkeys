from datetime import datetime
import time


times = []

for x in range(10):
  current_time = datetime.now().isoformat(timespec='seconds').replace(':','-')
  times.append(current_time)
  time.sleep(1)

print(sorted(times))