#!/usr/bin/env perl
#
# original filename: evalTarget.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Mon Jun 16, 2008  19:52:05 DST
#  Host: bender.astro.princeton.edu
#  Working Directory: /Users/bick/working/aperture_test
#


use strict;
use warnings;
use File::Basename;
use Local::Astrotools;


my $exe = basename($0);
my $DIRNAME = dirname($0);
my $usage = 
  "Usage: $exe dist Av Ebmv lamlo lamhi aper QE rdnoise Hz pixelSizeMic fNum dichroic(1 or 0) photfile RA:dec:V:BmVcol FOV OrbHeight IOCOpowerform Nrun RA Dec q1 q2 rknee1 rkneeWidth N0 ObsDate(JD) prefix\n";

#Creating variables to store command-line arguments
#   1      2   3     4      5      6   7   8    9        0     1
my ($dist,$Av,$Ebmv,$lamlo,$lamhi,$ap,$QE,$rdnoise,$hz,$pixelSizeMic,$fNum,$dichroic,$photfile,$columns,$FOV,$obsHeight,$IOCOpowerform,$Nrun,$RA,$Dec,$q1,$q2,$q3,$albedo,$rkneeWidth,$obsDate,$prefix) = @ARGV;

#Determining if command-line arguments were sufficient and 
#killing program or re-assigning if not.
die $usage unless $FOV;
die $usage unless ($RA && $Dec && $obsHeight && $obsDate && $rkneeWidth);
$Nrun = 0 unless $Nrun;
$IOCOpowerform = 0 unless $IOCOpowerform;
$prefix = "" unless $prefix;
($q1, $q2, $q3, $albedo, $rkneeWidth) = (-3.3, -1.0, -2.5, 0.07, 1.5) unless ($q1 && $q2 && $q3 && $albedo && $rkneeWidth);

#convert date from YYYY/MM/DD to JD
my ($year, $month, $day) = split(/\//, $obsDate);
$obsDate = calendar2JD($year, $month, $day);

my $elong = getElongOfCoordsAtDate($RA, $Dec, $obsDate);
$elong = 180.0 unless $elong;

my @AUs = (40,300);
# @AUs = (40);
# @AUs = (300);

#Sends relevant parameters to makespec.par.hard
my $fluxCalc_dir = $ENV{FLUXCALC};
die "FLUXCALC not defined\n" unless $fluxCalc_dir;
die "Directory $fluxCalc_dir does not exist\n" unless (-d $fluxCalc_dir);

open(MAKESPEC_PAR_HARD, ">$fluxCalc_dir/makespec.par.hard");
print MAKESPEC_PAR_HARD ("diameter ", $ap, "\nmetallicity 0\nspecname none\nexposure ", (1/$hz), 
			 "\npitch 1\ncoating Aluminum\ndetector BkTh\ndesign perf\nfilter y\nwave1 ", ($lamlo*(10**6)), "\nwave2 ", ($lamhi*(10**6)), "\n");
print STDERR ("Adding parameters to makespec.par.hard...\n");
close MAKESPEC_PAR_HARD;

#Takes parameters defined in run.sh and produces data file starDB.dat
my $cmd_makeStarDB = "$DIRNAME/makeStarDB.pl $photfile $dist $Av $Ebmv $columns $FOV $ap $hz";
system($cmd_makeStarDB);

foreach my $AU (@AUs) {

  my $cmd_fresfile    = "$DIRNAME/makeFresFiles.pl $dist $lamlo $lamhi $AU $Nrun";
  my $cmd_runkomplete = "$DIRNAME/runKomplete.pl $dist $AU $hz $QE $rdnoise $Av $Ebmv $elong $pixelSizeMic $fNum $dichroic $ap";
#  my $cmd_getRate     = "./getRate.pl starDB.dat $dist $AU $ap $IOCOpowerform $prefix $q1 $q2 $q3 $rknee1 $RA $Dec";
  my $cmd_fitRmin     = "$DIRNAME/fitRminBmax.pl starDB.dat $dist $AU $ap $IOCOpowerform $elong $prefix";
  my $cmd_getRates    = "$DIRNAME/getRates.pl starDB.dat $dist $Av $AU $ap $IOCOpowerform $q1 $q2 $q3 $albedo $rkneeWidth $RA $Dec $obsDate $obsHeight $elong $prefix";

  system($cmd_fresfile);
  system($cmd_runkomplete);
  #system($cmd_getRate); #depricated
  system($cmd_fitRmin);
  system($cmd_getRates);

}

exit 0;
