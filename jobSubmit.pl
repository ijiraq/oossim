#!/usr/bin/perl
#
# This script is simply a shortcut for submitting jobs to
# the computing cluster at HIA, varying one variable by
# the column of values specified in the input file
#
# NOTE: this script only works for ONE column of data separated
# by the newline character...
#


use strict;
use warnings;
use File::Basename;

my $exe = basename($0);
my $usage = "Usage: $exe cluster variable1 inputFile1 (non-functional yet: variable2 inputFile2)\n"
    . "Clusters: M35, M25\n" 
    . "Variables: Lamlo, Lamhi, Aper, Thru, Rdnoise, Hz, PixSizeMic, Fnum, Dichroic(1 or 0), FOV, OrbHeight, IOCOPowerform, Nrun, Q1, Q2, Q3, Albedo, RKneeWidth, ObsDate\n"
    . "Please ensure arguments are typed EXACTLY as specified above (case-sensitive)\n";

my ($clusterName, $variableName1, $inputFile1, $variableName2, $inputFile2) = @ARGV;
die $usage unless ($clusterName && $variableName1 && $inputFile1);

my $rootDir = "/home/cadc/johnsont";
my $oossim = $rootDir."/oossim";
my $jobDir = $rootDir."/jobs";
foreach $dir in ($oossim, $jobDir) {
    mkdir $dir if ( ! -e $dir );
}


#set up all of the variables common to a cluster...

# Dist Av Ebmv Rawphot RacolDeccol:Vcol:Bmvcol RA Dec
my %clusterParameters = ("M35", "816 0.79 0.255 sung1999_MNRAS.306.361.dat 18:19:11:13 92.27 24.34 2008/12/23", 
			 "M25", "620 1.4756 0.476 M25-MosaicCatalogue.dat 1:2:3:4 277.92 -19.12 2008/06/29");

# initialize all modifiable variables in an associative array
# set default values
my %par = ();
$par{"Lamlo"} = 3.0e-7;
$par{"Lamhi"} = 9.0e-7;
$par{"Aper"} = 0.3;
$par{"Thru"} = 0.975;
$par{"Rdnoise"} = 4;
$par{"Hz"} = 40;
$par{"FOV"} = 0.4;
$par{"OrbHeight"} = 700;
$par{"IOCOPowerform"} = 0;
$par{"Nrun"} = 0;
$par{"Q1"} = -3.8;
$par{"Q2"} = -1.0;
$par{"Q3"} = -2.5;
$par{"Albedo"} = 0.07;
$par{"RKneeWidth"} = 1.176;
$par{"ObsDate"} = "2008/06/29";
$par{"PixSizeMic"} = 8.0;
$par{"Fnum"} = 5.78;
$par{"Dichroic"} = 0;

# Now parse all the strings into variables...

die $usage unless $clusterParameters{$clusterName};
my ($dist, $Av, $Ebmv, $dataBaseFile, $RaDecCol, $RA, $Dec, $date) = split(/\ /,  $clusterParameters{$clusterName});

die $usage unless $par{$variableName1};

$par{"ObsDate"} = $date;

# Open input file and begin cycling through column of data

open(INPUT_FILE1, "$inputFile1");


# Now it is time to loop through the input file, assign the variable, create 
# the appropriate script file and submit the job to the computing cluster...

while (<INPUT_FILE1>) {

    chop;
    $par{$variableName1} = $_;

    my $scriptContent = ""
	. '#!/bin/tcsh
echo `hostname`
echo $TMPDIR
cd $TMPDIR
cp -R -t $TMPDIR $oossim/evalTarget/ $oossim/fluxCalc/
echo `pwd`
echo `date`

#set env variables!
#fluxcalc directory
setenv FLUXCALC ${TMPDIR}/fluxCalc

cd evalTarget/' 
. "\n./evalTarget.pl $dist $Av $Ebmv " . $par{'Lamlo'} . " " . $par{'Lamhi'} . " " . $par{'Aper'} . " " 
. $par{'Thru'} . " " . $par{'Rdnoise'} . " " . $par{'Hz'} . " " . $par{"PixSizeMic"} . " " . $par{"Fnum"} 
. " " . $par{"Dichroic"} . " $dataBaseFile $RaDecCol " . $par{'FOV'} 
. " " . $par{'OrbHeight'} . " " . $par{'IOCOPowerform'} . " " . $par{'Nrun'} . " $RA $Dec " . $par{'Q1'} 
. " " . $par{'Q2'} . " " . $par{'Q3'} . " " . $par{'Albedo'} . " " . $par{'RKneeWidth'} . " " 
. $par{'ObsDate'} . "\ncp runKomplete.log $jobDir/$clusterName-$par{$variableName1}$variableName1-runKomplete.log\ncp makeStarDB.log $jobDir/$clusterName-$par{$variableName1}$variableName1-makeStarDB.log\n\necho `date`\n";

     my $scriptFile = "job-$clusterName-$par{$variableName1}$variableName1.csh";
     my $outputFile = "job-$clusterName-$par{$variableName1}$variableName1.out";

if ($variableName1 eq "ObsDate") {
     my ($year, $month, $day) = split(/\//, $par{"ObsDate"});
    
     $scriptFile = "job-$clusterName-$year-$month-$day-$variableName1.csh";
     $outputFile = "job-$clusterName-$year-$month-$day-$variableName1.out";
 }

     open(SCRIPT, ">$scriptFile");
     print SCRIPT ($scriptContent);
     close SCRIPT;

     my $qsubCommand = "qsub -q cadcproc -l arch=lx24-x86 -o $jobDir/$outputFile -j y $scriptFile";
     system($qsubCommand);
}

close INPUT_FILE1;
