#!/usr/bin/env perl
#
# original filename: magDiff.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Fri Jul 28, 2006  18:10:50 DST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/analysis
#

use strict;
use warnings;
use File::Basename;

use Local::Constants;
use Local::Astrotools;

my $exe = basename($0);
my $usage = "Usage: $exe flux1 [flux2]\n";

my ($flux1, $flux2) = @ARGV;
die $usage unless $flux1;
$flux2 = 1.0 unless $flux2;

printf STDOUT "%.3f\n", magDiff($flux1, $flux2);

exit 0;
