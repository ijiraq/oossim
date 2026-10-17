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
my $usage = "usage: $exe elong date [time 1AM assumed]\n".
    "  eg. $exe 06:08:54.0 24:20:00.0 2004-01-02 19:00:00\n";
my ($elong, $date, $time)  = @ARGV;
die $usage unless defined($date);

$time = "00:00:00" unless $time;

# get the julian day
my ($yr, $mon, $mday) = split /-/, $date;
my ($hr, $min, $sec) = split /:/, $time;
my $JD = calendar2JD($yr, $mon, $mday, $hr, $min, $sec);

# get the elongation
my ($alpha1, $delta1, $alpha2, $delta2) = getRADecOfElongAtDate($elong, $JD);

my $alphaS1 = deg2hmsS($alpha1/15.0);
my $deltaS1 = deg2hmsS($delta1);
my $alphaS2 = deg2hmsS($alpha2/15.0);
my $deltaS2 = deg2hmsS($delta2);


# output the answer.
printf STDOUT "$alphaS1 $deltaS1   $alphaS2 $deltaS2\n";

exit 0;
