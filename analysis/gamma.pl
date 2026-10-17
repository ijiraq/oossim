#!/usr/bin/env perl
#
# original filename: gamma.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Wed Aug  8, 2007  20:36:26 DST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/analysis
#


use strict;
use warnings;
use File::Basename;

use Local::Constants;
use Local::Statistics;

my $exe = basename($0);
my $usage = "Usage: $exe x\n";

my ($x) = @ARGV;
die $usage unless defined $x;

printf STDOUT "%.8g\n", gamma($x);

exit 0;
