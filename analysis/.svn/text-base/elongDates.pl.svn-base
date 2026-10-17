#!/usr/bin/env perl
#
#

use strict;
use warnings;
use File::Basename;

use lib "$ENV{HOME}/libperl2";
use Local::Coords;
#use Local::Constants;

use Time::Local;
# use Time::localtime;

my $exe = basename($0);
my $usage = "usage: $exe alpha delta elong\n";
my ($alpha, $delta, $elong)  = @ARGV;
die $usage unless defined($delta);

$elong = 180.0 unless defined($elong);


# convert coords to ecliptic
my ($lambda, $beta) = cel2ecl($alpha, $delta, "deg");


# get the epoch in seconds when vernal equinox is at opposition;
my ($year) = (localtime)[5] + 1900;
my ($yr_ve, $mon_ve, $mday_ve, $hr_ve, $min_ve, $sec_ve) =  
    ($year-1900, 9 - 1, 21, 12, 0, 0);  # sep 21 of the current year
my $epochSve = timelocal($sec_ve, $min_ve, $hr_ve, $mday_ve, $mon_ve, $yr_ve);


# convert coords to elongation of the target when observed from VE position.
my $elongFromVE = 180.0 - $lambda;


# get angle past VE for 1st requested elong
my $psi1 = $elong - $elongFromVE;
my $psi2 = 360.0 - $elong - $elongFromVE;



# convert angle past VE to time past VE (in seconds);
my $secondsPerYr = 86400*365.25;
my $secondsPastVE1 = $secondsPerYr*$psi1/360.0; # sec past the vernal equinox
my $secondsPastVE2 = $secondsPerYr*$psi2/360.0; # sec past the vernal equinox

# add seconds to value for vern eq
my $epochS1 = int($epochSve + $secondsPastVE1);
my $epochS2 = int($epochSve + $secondsPastVE2);


# convert new seconds to date
my ($sec1, $min1, $hr1, $mday1, $mon1, $yr1, $wday1, $yday1) = 
    localtime($epochS1);
$mon1 += 1;
$yr1 += 1900;

my ($sec2, $min2, $hr2, $mday2, $mon2, $yr2, $wday2, $yday2) = 
    localtime($epochS2);
$mon2 += 1;
$yr2 += 1900;

my $date1 = sprintf "%04d-%02d-%02d  %02d:%02d:%05.2f", 
    $yr1, $mon1, $mday1, $hr1, $min1, $sec1;
my $date2 = sprintf "%04d-%02d-%02d  %02d:%02d:%05.2f", 
    $yr2, $mon2, $mday2, $hr2, $min2, $sec2;

printf STDOUT "$date1   $date2\n";
