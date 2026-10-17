#!/usr/bin/env perl
#
# original filename: Hmag2mv.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Tue Oct  3, 2006  16:40:47 DST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/analysis
#


use strict;
use warnings;
use File::Basename;

use Local::Constants;
use Local::Astrotools;

my $exe = basename($0);
my $usage = "Usage: $exe mv r0 re p\n".
  "    r0 = heliocentric dist to object\n".
  "    re = geocentric dist to object\n".
  "    p  = albedo\n";

my ($mv, $r0, $re, $p) = @ARGV;
die $usage unless $p;

printf STDOUT "%.3g\n", mv2rad($mv, $r0, $re, $p);

exit 0;
