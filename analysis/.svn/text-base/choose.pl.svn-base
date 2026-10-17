#!/usr/bin/env perl
#
# original filename: choose.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Wed Feb 14, 2007  15:23:18 EST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/analysis
#


use strict;
use warnings;
use File::Basename;

use Local::Constants;
use Local::Statistics;

my $exe = basename($0);
my $usage = "Usage: $exe n t [suppress(0|1)]\n";

my ($n, $t, $suppress) = @ARGV;
die $usage unless defined $t;

printf STDOUT "%s%d\n", ($suppress)?"":"$n choose $t = ", binomCoef($n,$t);

exit 0;
