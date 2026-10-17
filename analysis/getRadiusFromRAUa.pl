#! /usr/bin/perl

use strict;
use warnings;
use File::Basename;
use Local::Astrotools;

my $exe = basename($0);
my $usage = "Usage: $exe magnitude dist(AU) albedo\n";

my ($R, $AU, $albedo) = @ARGV;
die $usage unless ($R && $AU && $albedo);

my $out = (get_TNOrad_from_RAUa($R, $AU, $albedo)/1000);

print $out . " km\n";
