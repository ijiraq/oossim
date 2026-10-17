#!/usr/bin/env perl
#
#  kernelhist.pl - sliding kernel histogram program
#  Steve Bickerton - Sun. 25 Sept, 2005
# 
#

use strict;
use warnings;
use lib "$ENV{HOME}/libperl";
use Local::Histogram;


my $usage = "usage: $0 [infile] resolution binwidth kernel scale low high\n".
    "\n".
    "functions:\n".
    "(\$binsref,\$hist_ref) = histogram(\$valuesRef, \$bins)\n".
    "(\$binsref,\$hist_ref) = kernelhist(\$inArrRef,\$res,\$binw,\$kern,\$scaling,\$lo,\$hi)\n".
    "                         scaling = (density|probdensity|raw)";


die "$usage" unless @ARGV;
( -s $ARGV[0] ) or unshift(@ARGV, "-");
my ($infile, $resolution, $binwidth, $kernel, $scaling, $low, $high) = @ARGV;
die "$usage" if ! $high;
die "$usage" if ($scaling !~ /dens|prob|raw/ );

if ($scaling=~/prob/) { $scaling =  "probdensity"; } 
elsif ($scaling=~/raw/) {} 
else { $scaling= "density"; }

# read in the data
my @array;
open (INFILE, "$infile");
while (<INFILE>) { push @array, (split)[0]; }
close (INFILE);

# call kernelhist
my ($bins_ref, $hist_ref) = kernelhist(\@array, $resolution, $binwidth, $kernel, $scaling, $low, $high);
my @bins = @$bins_ref;
my @hist = @$hist_ref;

foreach my $i ( 0 .. $#bins ) {
    printf STDOUT "%f %f\n", $bins[$i], $hist[$i];
}
