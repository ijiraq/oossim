#! /usr/bin/perl

use strict;
use warnings;
use File::Basename;
use Local::Astrotools;


my $exe = basename($0);
my $usage = 
    "Usage: $exe RA Dec obsHeight[km] obsDate[JD]\n";

my ($RA, $Dec, $obsHeight, $obsDate) = @ARGV;
die $usage unless ($RA && $Dec && $obsHeight && $obsDate);

my ($year, $month, $day) = split(/\//, $obsDate);
my $JD = calendar2JD($year, $month, $day);

my $fraction = orbitalObsFraction($RA, $Dec, $obsHeight, $JD);

print STDOUT "$fraction\n";

exit 0;
