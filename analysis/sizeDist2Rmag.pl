#!/usr/bin/env perl
#
# original filename: sizeDist2Rmag.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Sun Dec 10, 2006  20:37:16 EST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/analysis
#


use strict;
use warnings;
use File::Basename;

use Local::Constants;
use Local::Astrotools;

my $exe = basename($0);
my $usage = "Usage: $exe r(m) d(AU) albedo\n";

my ($r, $d, $albedo) = @ARGV;
die $usage unless $albedo;

printf STDOUT "m_R = %.3f\n", TNO_Rmag($r,$d, $albedo);

exit 0;
