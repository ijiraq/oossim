#!/usr/bin/env gnuplot
set terminal postscript eps dl 3 enhanced color "Helvetica" 24
set output "EPSFILE"

set size 2, 2

N=NPOINTS0
mean=MEAN0
median=MEDIAN0
rms=STDDEV0
skew=SKEWNESS0
kurt=KURTOSIS0
max=MAXVALUE0
min=MINVALUE0
hmax=HMAX0
kmax=KMAX0
chi2=CHISQUARED0
ymax=1.25*hmax

xmin=median - 7.0*rms
xmax=median + 5.0*rms
x2min=xmin/rms
x2max=xmax/rms
ymin=0

set key spacing 2.

set multiplot
set size 2,0.9
set origin 0,1.05
set xrange [xmin:xmax]
set x2range [x2min:x2max]
set yrange [ymin:ymax]

set xlabel 'XLABEL' 0,0.5
set x2label 'Std.Dev. units' 
set ylabel 'N' 0.5,0

set xtics nomirror
set ytics
set x2tics 1

labx = 0.05
labx2 = 0.2
laby = 0.09

set grid

set style line 1 lt 1 lw 2 lc rgb "black"
set style line 2 lt 2 lw 2 lc rgb "black"
set style line 3 lt 1 lw 3 lc rgb "black"


i=1
set label 10 "N" at gr labx, (1.0-i*laby) left
set label 11 sprintf("= %d",N) at gr labx2, (1.0-i*laby) left
i=i+1
set label 20 "Mean" at gr labx, (1.0-i*laby) left
set label 21 sprintf("= %.4f", mean) at gr labx2, (1.0-i*laby) left
i=i+1
set label 30 "Median" at gr labx, (1.0-i*laby) left
set label 31 sprintf("= %.4f", median) at gr labx2, (1.0-i*laby) left
i=i+1
set label 40 "RMS" at gr labx, (1.0-i*laby) left
set label 41 sprintf("= %.4f",rms) at gr labx2, (1.0-i*laby) left
i=i+1
set label 70 "Skewness" at gr labx, (1.0-i*laby) left
set label 71 sprintf("= %.4f",skew) at gr labx2, (1.0-i*laby) left
i=i+1
set label 80 "Kurtosis" at gr labx, (1.0-i*laby) left
set label 81 sprintf("= %.2f", kurt) at gr labx2, (1.0-i*laby) left
i=i+1
set label 83 "Min" at gr labx, (1.0-i*laby) left
set label 84 sprintf("= %.2f (%.1f {/Symbol s})",min,(min-mean)/rms) at gr labx2, (1.0-i*laby) left
i=i+1
set label 86 "Max" at gr labx, (1.0-i*laby) left
set label 87 sprintf("=  %.2f (%.1f {/Symbol s})",max,(max-mean)/rms) at gr labx2, (1.0-i*laby) left
i=i+1
set label 90 "Reduced {/Symbol c}^{2}" at gr labx, (1.0-i*laby) left
set label 91 sprintf("= %.2f",chi2) at gr labx2, (1.0-i*laby) left


yxbar=0.64
dy=0.1
set arrow 1 from mean,gr yxbar-dy to mean,gr yxbar+dy nohead ls 3
set arrow 2 from (mean-rms),gr yxbar to (mean+rms),gr yxbar nohead ls 3
set arrow 3 from (mean-rms),gr yxbar+dy to (mean-rms),gr yxbar-dy nohead ls 3
set arrow 4 from (mean+rms),gr yxbar+dy to (mean+rms),gr yxbar-dy nohead ls 3

set lmargin 9
set rmargin 9

e=2.718281728

f(x)=hmax*e**(-(x-mean)**2/(2.0*rms**2))
plot 'HISTFILE0' using 1:2 t "" with boxes ls 1,\
     f(x) t "Best-fit Gaussian" with line ls 2

unset label
unset arrow
set label 1 "Residuals from Best-Fit Gaussian" at gr labx,1.0-laby left
set size 2,0.9
set origin 0, 0.05
set yrange [-3.5*sqrt(ymax):3.5*sqrt(ymax)]


plot 'HISTFILE0' using 1:($2 - f($1)) t "" w boxes ls 1,\
     0 w line ls 2 t "",\
     sqrt(f(x)) t "N^{1/2} Standard Deviation" w line ls 2,\
     -sqrt(f(x)) t "" w line ls 2






