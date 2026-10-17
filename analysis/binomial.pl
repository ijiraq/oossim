#!/usr/bin/env perl
#
# original filename: binomial.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Tue Dec 19, 2006  21:38:49 EST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/analysis
#


use strict;
use warnings;
use File::Basename;

use Local::Constants;
use Local::Astrotools;
use Local::Statistics;

my $exe = basename($0);
my $usage = "Usage: $exe p t n\n";

my ($p, $t, $n) = @ARGV;
die $usage unless defined $n;

printf "%.4g\n", binomDist($p, $t, $n);

exit 0;
