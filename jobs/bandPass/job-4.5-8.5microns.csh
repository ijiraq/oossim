#this script will serve as a standard. please do not edit.
#!/bin/tcsh

echo `hostname`
echo $TMPDIR
cd $TMPDIR
cp -R -t $TMPDIR /home/cadc/johnsont/oossim/evalTarget/ /home/cadc/johnsont/oossim/fluxCalc/
echo `pwd`
echo `date`

#set env variables!
#fluxcalc directory
setenv FLUXCALC ${TMPDIR}/fluxCalc

cd evalTarget/

#  DIST Av Ebmv LAMLO LAMHI APER THRU RDNOISE HZ RAWPHOT RA:Dec:V:BmV FOV IOCOpowerform Nrun RA DEC Q1 Q2 RKNEE1 RKNEE2 N0 PREFIX
./evalTarget.pl 620 1.4756 0.476 4.5e-7 8.5e-7 0.30 0.70 10.0000 40 M25-MosaicCatalogue.dat 1:2:3:4 0.4 0 0 277.92 -19.12 -3.3 -2.5 30 5 10

echo `date`
