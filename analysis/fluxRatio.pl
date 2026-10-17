#!/usr/bin/env perl
#
# original filename: fluxRatio.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Fri Jul 28, 2006  18:05:20 DST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/analysis
#

use strict;
use warnings;
use File::Basename;

use Local::Constants;
use Local::Astrotools;

my $exe = basename($0);
my $usage = "Usage: $exe mag1 mag2\n";

my ($mag1, $mag2) = @ARGV;
die $usage unless $mag1;

unless ($mag2) {
    $mag2 = $mag1;
    $mag1 = 0;
}

printf STDOUT "%.3f\n", fluxRatio($mag1, $mag2);

exit 0;
