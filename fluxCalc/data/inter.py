#!/usr/bin/env python

## read in the CCD/Telescope/Flux curves and provide a join efficiency
from scipy.interpolate import splrep, splev
import numpy


x=[]
y=[]
rfile='gBkTh'
sfile='gBkTh.smooth'

for line in file(rfile).readlines():
    if line[0]== "#":
        continue
    v = line.split()
    x.append(float(v[0]))
    y.append(float(v[1]))
x=numpy.array(x)
y=numpy.array(y)
tck = splrep(x,y)

x2=[]
for line in file('t20000p00.norm.form').readlines():
   if line[0]=="#":
       continue
   v = line.split()
   x2.append(float(v[0]))
x2=numpy.array(x2)


y2 = splev(x2,tck)

smooth=file(sfile,'w')
for i in range(len(x2)):
   smooth.write("%5.3f %5.3f\n" % (x2[i],y2[i]))

smooth.close()
