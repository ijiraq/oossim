#!/usr/bin/env bash
#
# Steven Bickerton
# Dept. of Physics/Astronomy, McMaster University
# bick@physics.mcmaster.ca
# Made with makeScript, Tue May 20, 2008  18:41:17 DST
# Host: bender.local
# Working Directory: /Users/bick/working/aperture_test

cd $TMPDIR


function usage()
{
    echo "Usage: $0"
}

if [ $# -ne 0 ]; then
    usage
    exit 1;
fi

set -x


#TARGET DATA
RAWPHOT=sung1999_MNRAS.306.361.dat
Vcol=11
BmVcol=13
RAcol=18   #degrees
Deccol=19  #degrees

#TARGET PARAMETERS
DIST=816
Ebmv=0.255
Av=0.79   # 3.1 * Ebmv
RA=92.27 #RA and Dec for the target center
DEC=24.34
OBSDATE="2008/12/23" #Julian Date of Target Observation (used to compute elong, among other things)

#SCOPE PARAMETERS
HZ="40"
# leave at this value unless modifying something other than mirror reflectivity, QE of detector, respose of dichroic, and flux percentage contained in pixel aperture (e.g. 3x3 box); these are accounted for.
THRU="0.975"
LAMLO="4.0e-7"
LAMHI="8.0e-7" # used only to make diffraction templates
ORBHEIGHT=700 #mean distance of orbit from earth surface in km
APERTUREs="0.30"
FOV="0.4"
RDNOISEs="4" #note this is the readnoise per pixel at 40hz
PIXSIZEMIC="8.0" #size of each pixel in microns
FNUM="5.78" #fnumber of optics of telescope
DICHROIC="0" #binary variable for presence of dichroic optical system

#SCIENCE PARAMETERS
IOCOpowerform=0 # 0 broken (pessimistic), 1 uniform (optimistic)

#Parameters for the cumulative density function
Q1="-3.8" #slope of the largest radius portion of the function (r>rknee1)
Q2="-1.0" #slope of the medium radius portion of the function (rknee1> r >rknee2)
Q3="-2.5" #slope of the smallest radius portion
ALBEDO=0.07 #albedo level of TNOs
RKNEEWIDTH=1.176 #width of break radii area in logarithmic units

Nrun=0

BASEDIR="/home/cadc/kavelaar/svnrepo/oossim/trunk"
FLUXCALC="${BASEDIR}/fluxCalc"
export FLUXCALC
EVALDIR="${BASEDIR}/evalTarget"
export EVALDIR

for RDNOISE in $RDNOISEs
do
    PREFIX="rdnoise${RDNOISE}"
    PREFIX="doh2.5"
    PREFIX=""
    for APER in $APERTUREs
    do
	$EVALDIR/evalTarget.pl $DIST $Av $Ebmv $LAMLO $LAMHI $APER $THRU $RDNOISE $HZ $PIXSIZEMIC $FNUM $DICHROIC $RAWPHOT $RAcol:$Deccol:$Vcol:$BmVcol $FOV $ORBHEIGHT $IOCOpowerform $Nrun $RA $DEC $Q1 $Q2 $Q3 $ALBEDO $RKNEEWIDTH $OBSDATE $PREFIX
    
done
done

exit 0
