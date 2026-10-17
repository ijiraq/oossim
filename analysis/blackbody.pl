#!/usr/bin/env perl
#
#

use strict;
use warnings;

use lib "$ENV{HOME}/libperl2";
use Local::Constants;
use Local::Physics;

my $usage = "$0 Teff [lamblo] [lambhi]\n";
my ($T, $lambLo, $lambHi) = @ARGV;
die $usage unless $T and $T=~/^\d/;

$lambLo = 1e-9 unless $lambLo;
$lambHi = 1e-0 unless $lambHi;


my $lamb = $lambLo;

while ($lamb<$lambHi) {
    $lamb *= 1.01;
    printf STDOUT "%.10e %.10f\n", $lamb, planckL($lamb,$T);
}

exit 0;
