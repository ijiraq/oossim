#!/usr/bin/env perl
#
# original filename: mjd_months.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Tue Sep 18, 2007  19:23:27 DST
#  Host: bender.astro.princeton.edu
#  Working Directory: /Users/bick/sandbox/utility
#


use strict;
use warnings;
use File::Basename;

use Local::Constants;
use Local::Astrotools;

my $exe = basename($0);
my $usage = "Usage: $exe [year1 (default_current)] [year2 (default-year1)]\n";

my ($year1, $year2) = @ARGV;

$year1 = (localtime)[5] + 1900 unless $year1;
$year2 = $year1 unless $year2;

my @monthS = qw(jan feb mar apr may jun jul aug sep oct nov dec);

foreach my $year ($year1 .. $year2) {
  foreach my $month (0 .. 11) {

    my $epoch = $year + $month/12.0;
    my $jd = epoch2JD($epoch);
    my $mjd = $jd - 2400000.5;
    printf STDOUT "%d %3s  %.2f  %.2f\n", $year, $monthS[$month], $jd, $mjd;
  }
}

exit 0;
