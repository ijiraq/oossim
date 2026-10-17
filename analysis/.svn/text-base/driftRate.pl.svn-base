#!/usr/bin/env perl
#
# original filename: driftRate.pl
#
# Steven Bickerton
#  Dept. of Astrophysical Sciences, Princeton University
#  bick@astro.princeton.edu
#  Created: Thu Jun 26, 2008  16:56:27 DST
#  Host: bender.astro.princeton.edu
#  Working Directory: /Users/bick/usr/src/analysis
#


use strict;
use warnings;
use File::Basename;

use Local::Constants;
use Local::Astrotools;
use Local::Elong2v;

my $exe = basename($0);
my $usage = "Usage: $exe elong i AU\n";

my ($elong, $i, $AU) = @ARGV;
die $usage unless $AU;

my $vRet = elongi2v($elong*$RAD,$i*$RAD,$AU);
my $drift_rads_per_sec = $vRet / ($AU * $AU_M);
my $drift_as_per_hour  = $drift_rads_per_sec * $RAD_ARCSEC * 3600.0;


printf STDOUT "%.3f\n", $drift_as_per_hour;

exit 0;
