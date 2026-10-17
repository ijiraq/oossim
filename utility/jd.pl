#!/usr/bin/env perl
#
#

use strict;
use warnings;

#use lib "$ENV{HOME}/libperl";
use Local::Misc;

my ($year, $month, $day, $hour, $min, $sec) = @ARGV;
die "Usage: year month day hour min sec\n" unless $day;

$hour = 0 if ! defined $hour;
$min = 0 if ! defined $min;
$sec = 0 if ! defined $sec;

printf STDOUT "${month}/${day}/${year}_%02d:%02d:%02d  JD%.9f\n", $hour, $min, $sec, jd($year, $month, $day, $hour, $min, $sec);

exit 0;
