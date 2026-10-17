#!/usr/bin/env perl
#
# original filename: getElong.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Mon Jul 17, 2006  16:05:57 DST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/analysis
#

use strict;
use warnings;
use File::Basename;

use Local::Constants;
use Local::Astrotools;

my $exe = basename $0;
my $usage = "usage: $exe alpha delta date [time 1AM assumed]\n";
my ($alpha, $delta, $JD)  = @ARGV;
die $usage unless defined($JD);

# put the RA Dec into degrees format
my ($alphaD,$deltaD) = hms2degRADec($alpha,$delta);

# get the elongation
my $elong = getElongOfCoordsAtDate($alphaD, $deltaD, $JD);
my $elongReduced = ($elong>180.0) ? (360.0-$elong) : $elong;

my ($lambda, $beta) = eq2ecl($alphaD, $deltaD, $JD);

# output the answer.
printf STDOUT "%.3f  (%.3f)  ecl-latitude: %.3f\n", $elong, $elongReduced, $beta;

exit 0;
