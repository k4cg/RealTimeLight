#!/usr/bin/python3

import serial
import time
import numpy as np

s = serial.Serial('/dev/ttyUSB0', 2000000, timeout=0, rtscts=1)
N = 92
dat = [0]*3*N

# order: red,blue,green


cnt = 0
while True:
	print("write %d ... " % cnt, end="")
	#dat[-3] = 0xff * (cnt%3 == 0)
	#dat[-2] = 0xff * (cnt%3 == 1)
	#dat[-1] = 0xff * (cnt%3 == 2)

	x = np.linspace(0,N-1,N)
	k = 20
	dt = cnt/20
	r = np.sin(2*np.pi*(x/k+0.0+dt))
	print(r[0:10])
	g = np.sin(2*np.pi*(x/k+0.333+dt))
	b = np.sin(2*np.pi*(x/k+0.666+dt))
	dat = (np.reshape(np.vstack([r,g,b]), (1,3*N), "F") + 1)*0.5

	by = bytes(int(v) for v in (np.squeeze(dat)*50))
	s.write(by)
	s.flush()
	print("done")
	time.sleep(0.1)
	cnt += 1
