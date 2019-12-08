#!/usr/bin/python3

import sys
import serial
import time
import numpy as np

port = sys.argv[1]
s = serial.Serial(port, 2000000, timeout=.5, rtscts=1)
N = 92
dat = [0]*3*N
T = 0.01
# order: red,blue,green


cnt = 0
while True:
	if cnt % 10 == 0:
		print("write %d ... " % cnt, end="")
	t1 = time.time()
	#dat[-3] = 0xff * (cnt%3 == 0)
	#dat[-2] = 0xff * (cnt%3 == 1)
	#dat[-1] = 0xff * (cnt%3 == 2)

	x = np.linspace(0,N-1,N)
	k = 20
	dt = cnt/40
	r = np.sin(2*np.pi*(x/k+0.0+dt))
	#print(r[:10])
	g = np.sin(2*np.pi*(x/k+0.333+dt))
	b = np.sin(2*np.pi*(x/k+0.666+dt))
	dat = (np.reshape(np.vstack([r,b,g]), (1,3*N), "F") + 1)*0.5
	by = bytes(int(v) for v in (np.squeeze(dat)*30))
	
	t2 = time.time()
	s.write(by)
	s.flush()
	t3 = time.time()
	twait = T-(t3-t1)
	if twait > 0:
		time.sleep(twait)
	t4 = time.time()
	if cnt % 10 == 0:
		print("done gen %.1f ms load %.1f ms total %.1f ms" \
		   % ((t2-t1)*1e3, (t3-t2)*1e3, (t4-t1)*1e3))


	cnt += 1
