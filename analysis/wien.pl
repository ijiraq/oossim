#!/usr/bin/env perl
#
# original filename: wien.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Fri Nov 16, 2007  11:28:33 EST
#  Host: bender.astro.princeton.edu
#  Working Directory: /Users/bick/sandbox/analysis
#


use strict;
use warnings;
use File::Basename;
use Local::Units;
use Local::Constants;
#use Local::Physics;
use Local::Physics;

my $exe = basename($0);
my $usage = "Usage: $exe T (T in Kelvin, result in metres)\n";

my ($T) = @ARGV;
die $usage unless ($T and $T > 0);

printf STDOUT "%s\n", distanceUnits(wien($T), 'm');

exit 0;
