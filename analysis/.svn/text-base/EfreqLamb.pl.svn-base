#!/usr/bin/env perl
#
# original filename: EfreqLamb.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Sun Jan 27, 2008  14:37:34 EST
#  Host: bender.astro.princeton.edu
#  Working Directory: /Users/bick/sandbox/analysis
#


use strict;
use warnings;
use File::Basename;

use Local::Constants;
use Local::Astrotools;
use Local::Physics;

my $exe = basename($0);
my $usage = "Usage: $exe value (Ef|fE|LE|EL|fL|Lf)\n";

my ($value0, $conv_type) = @ARGV;
die $usage unless $conv_type;

printf STDOUT "%.4g\n", EfreqLamb($value0,$conv_type);

exit 0;
