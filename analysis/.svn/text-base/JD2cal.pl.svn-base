#!/usr/bin/env perl
#
# original filename: JD2cal.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Fri Jul 21, 2006  9:34:37 DST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/analysis
#

use strict;
use warnings;
use File::Basename;

use lib "$ENV{HOME}/libperl";
use Local::Constants;
use Local::Astrotools;

my $exe = basename($0);
my $usage = "Usage: $exe JD\n";

my ($JD) = @ARGV;
die $usage unless $JD;

my ($Y, $M, $D, $H, $m, $S) = JD2calendar($JD);

printf STDOUT "%04d-%02d-%02d  %02d:%02d:%05.2f\n", $Y, $M, $D, $H, $m, $S;

exit 0;


