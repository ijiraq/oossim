#!/usr/bin/env perl
#
# original filename: Fsu.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Tue Nov  7, 2006  17:14:41 EST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/pack_main/sandbox/analysis
#


use strict;
use warnings;
use File::Basename;

use Local::Constants;
use Local::Astrotools;

my $exe = basename($0);
my $usage = "Usage: $exe distance(AU) lambda(m)\n";

my ($lamb, @dist) = @ARGV;
die $usage unless @dist;

$lamb = 5.5e-7 if $lamb =~ /v/;

printf "# AU Fsu\n";
foreach my $dist (@dist) {
    printf STDOUT "$dist %.1f\n", fresnelScale($dist,$lamb);
}

exit 0;
