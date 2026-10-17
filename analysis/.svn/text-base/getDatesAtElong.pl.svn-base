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
my $usage = "usage: $exe alpha delta elong year\n".
    "   eg.  $exe 06:08:54.0 24:20:00.0 170.0 2004\n";

my ($alpha, $delta, $elong, $year)  = @ARGV;
die $usage unless defined($year);

# put the RA Dec into degrees format
($alpha, $delta) = hms2degRADec($alpha, $delta);

# get the elongation
my ($JD1, $JD2) = getDatesOfCoordsAtElong($alpha, $delta, $elong, $year);

my ($yr1, $mon1, $mday1, $hr1, $min1, $sec1) = JD2calendar($JD1);
my ($yr2, $mon2, $mday2, $hr2, $min2, $sec2) = JD2calendar($JD2);

# output the answer.
printf STDOUT "%04d-%02d-%02d %02d:%02d:%02d      ".
    "%04d-%02d-%02d %02d:%02d:%02d\n",
    $yr1, $mon1, $mday1, $hr1, $min1, $sec1, 
    $yr2, $mon2, $mday2, $hr2, $min2, $sec2;

exit 0;
