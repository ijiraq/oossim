#!/usr/bin/env perl
#
#

use strict;
use warnings;
use lib "$ENV{HOME}/libperl";
use Local::Constants; # $PI
use Local::Misc;      # log10()
use Local::Elong2v;

my ($v, $AU, $tolerance) = @ARGV;
die "usage: $0 v[m/s] AU [tolerance(deg)]\n" if ! $AU;


$tolerance = 0.01 unless (defined $tolerance);
my $decimals = abs( int( log10(0.99*$tolerance) ) ) ;
my $outformat = sprintf("%%\.%df",  $decimals  );
$tolerance *= $PI/180.0;

printf STDOUT "$outformat\n", (180.0/$PI)*v2elong($v, $AU, $tolerance);

exit 0;

