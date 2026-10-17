#!/bin/bash

for f in $@
do
	sed s/'\/LTb { BL \[\] 0 0 0 DL } def'/'\/LTb { BL \[\] 0 0 0 DL } def'/ $f | \
	sed s/'\/LTa { AL \[1 udl mul 2 udl mul\] 0 setdash 0 0 0 setrgbcolor } def'/'\/LTa { AL \[1 udl mul 2 udl mul\] 0 setdash 0 0 0 setrgbcolor } def'/ | \
	sed s/'\/LT0 { PL \[\] 1 0 0 DL } def'/'\/LT0 { PL \[\] 1 0 0 DL } def'/ | \
	sed s/'\/LT1 { PL \[4 dl 2 dl\] 0 1 0 DL } def'/'\/LT1 { PL \[8 dl 8 dl\] 0 0 0 DL } def'/ | \
	sed s/'\/LT2 { PL \[2 dl 3 dl\] 0 0 1 DL } def'/'\/LT2 { PL \[\] 0 0 1 DL } def'/ | \
	sed s/'\/LT3 { PL \[1 dl 1.5 dl\] 1 0 1 DL } def'/'\/LT3 { PL \[1 dl 1.5 dl\] 1 0 1 DL } def'/ | \
	sed s/'\/LT4 { PL \[5 dl 2 dl 1 dl 2 dl\] 0 1 1 DL } def'/'\/LT4 { PL \[2 dl 3 dl\] 1 0 0 DL } def'/ | \
	sed s/'\/LT5 { PL \[4 dl 3 dl 1 dl 3 dl\] 1 1 0 DL } def'/'\/LT5 { PL \[2 dl 3 dl\] 0 0 1 DL } def'/ | \
	sed s/'\/LT6 { PL \[2 dl 2 dl 2 dl 4 dl\] 0 0 0 DL } def'/'\/LT6 { PL \[\] 0 0 0 DL } def'/ | \
	sed s/'\/LT7 { PL \[2 dl 2 dl 2 dl 2 dl 2 dl 4 dl\] 1 0.3 0 DL } def'/'\/LT7 { PL \[2 dl 3 dl\] 0 0 0 DL } def'/ | \
	sed s/'\/LT8 { PL \[2 dl 2 dl 2 dl 2 dl 2 dl 2 dl 2 dl 4 dl\] 0.5 0.5 0.5 DL } def'/'\/LT8 { PL \[1 dl 2 dl\] 0 0 0 DL } def'/ > ${f}.tmp

	symbolify ${f}.tmp ${f}

	rm ${f}.tmp

done
