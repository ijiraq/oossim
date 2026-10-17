#!/usr/bin/env perl
#
#

use strict;
use warnings;
use lib "$ENV{HOME}/libperl";
use Local::KBOdensity;
use Local::Utility;

my ($mode, $r_min, $q1, $q2, $q3, $albedo, $rkneeWidth, $RA, $Dec) = @ARGV;
my $usage = "usage: $0 mode ['point' or 'function'] r_min[km] q1(slope for larger r values) q2(slope for intermediate r values) q3(slope for smaller r values) albedo(fraction) rkneeWidth(log-km units) RA[deg] Dec[deg]\n";
die $usage unless ($q1 && $q2 && $q3);

if ($mode eq "point") {

    printf STDOUT "%.3g\n", KBOdensity_doubleKnee($r_min, $q1, $q2, $q3, $albedo, $rkneeWidth, $RA, $Dec);
}
elsif ($mode eq "function") {
    open(TABLE, '>KBOdensityTable.dat');
    printf TABLE "%-8s %-12s\n", "log(R)", "log(DENSITY)";
    for (my $i = log10($r_min); $i <= 3; $i += 0.1) {
	my $density = KBOdensity_doubleKnee((10**$i), $q1, $q2, $q3, $albedo, $rkneeWidth, $RA, $Dec);
	$density = log10($density);
	printf TABLE "%-8.6f %-12.8f\n", $i, $density;
    }
    close TABLE;
}
else {
    die $usage;
}
