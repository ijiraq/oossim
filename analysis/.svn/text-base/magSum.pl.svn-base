#!/usr/bin/env perl
#
# original filename: magSum.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Fri Jul 28, 2006  17:45:01 DST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/analysis
#

use strict;
use warnings;
use File::Basename;

use Local::Constants;
use Local::Astrotools;

my $exe = basename($0);
my $usage = "Usage: $exe mag1 mag2 ...\n";

die $usage unless @ARGV;

printf STDOUT "%.3f\n", magSum(@ARGV);

exit 0;
