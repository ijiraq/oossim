#!/usr/bin/env perl
#
# original filename: TNO_Rmag.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Wed Apr 23, 2008  11:29:52 DST
#  Host: bender.astro.princeton.edu
#  Working Directory: /Users/bick/sandbox/analysis
#


use strict;
use warnings;
use File::Basename;

use Local::Constants;
use Local::Astrotools;

my $exe = basename($0);
my $usage = "Usage: $exe R rad albedo\n";

my ($R, $rad, $albedo) = @ARGV;
die $usage unless $albedo;

printf STDOUT "%.3f\n", get_TNOAU_from_Rrada($R, $rad, $albedo);

exit 0;
