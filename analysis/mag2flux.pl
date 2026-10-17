#!/usr/bin/env perl
#
# original filename: mag2flux.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Mon Oct  2, 2006  22:05:10 DST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/analysis
#


use strict;
use warnings;
use File::Basename;

#use lib "$ENV{HOME}/libperl2";
use Local::Constants;
use Local::Astrotools;

my $exe = basename($0);
my $usage = "Usage: $exe filter mag [zeropoint]\n";

my ($filter, $mag, $zeropoint) = @ARGV;
die $usage unless defined $mag;

$zeropoint = 25.0 unless defined $zeropoint;

my $flux_zp = fluxRatio($mag, $zeropoint);  #flux == 1 at m=zeropoint
my $flux_calc = mag2flux($filter, $mag);

printf STDOUT "#calc   zp  (photons per sec per m^2)\n";
printf STDOUT "%.2f  %.2f\n", $flux_calc, $flux_zp;

exit 0;
