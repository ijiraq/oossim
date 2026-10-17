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

use lib "$ENV{HOME}/libperl2";
use Local::Constants;
use Local::Astrotools;

my $exe = basename($0);
my $usage = "Usage: $exe H r0 re\n".
    "    r0 = heliocentric dist to object\n".
    "    re = geocentric dist to object\n";

my ($H, $r0, $re) = @ARGV;
die $usage unless $re;

printf STDOUT "%.3f\n", Hmag2mv($H, $r0, $re);

exit 0;
