#!/usr/bin/env perl
#
# original filename: cal2JD.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Fri Jul 21, 2006  9:34:31 DST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/analysis
#

use strict;
use warnings;
use File::Basename;

use lib "$ENV{HOME}/libperl";
use Local::Constants;
use Local::Astrotools;

my $exe = basename($0);
my $usage = "Usage: $exe date [time - noon assumed]\n".
    "date format: yyyy-mm-dd.dd\n".
    "time format: hh:mm:ss.ss\n";

my ($date, $time) = @ARGV;
die $usage unless $date;

$time = "12:00:00" unless $time;

my ($Y, $M, $D) = split /-/, $date;
my ($H, $m, $S) = split /:/, $time;

my $JD = calendar2JD($Y, $M, $D, $H, $m, $S);

printf STDOUT "$JD\n";

exit 0;
