#!/usr/bin/env perl
#
#

use strict;
use warnings;
use lib "$ENV{HOME}/libperl";
use Local::Histogram;


my $usage = "usage: $0 infile bins\n".
    "functions:\n".
    "  (\$binsref,\$histref) = histogram(\$valuesRef, \$bins)\n".
    "  (\$binsref,\$histref) = kernelhist(\$inArrRef,\$res,\$binw,\$kern,\$scaling,\$lo,\$hi)\n";


die "$usage" unless @ARGV;
( -e $ARGV[0] ) or unshift(@ARGV, "-");
my ($infile, $bins) = @ARGV;
die "$usage" if ! $bins;

# read in the data
my @array;
open (INFILE, "$infile");
while (<INFILE>) { push @array, (split)[0]; }
close (INFILE);

# call the histogram routine
my ($bin_centres_ref, $hist_values_ref) = histogram(\@array, $bins);
my @bin_centres = @$bin_centres_ref;
my @hist_values = @$hist_values_ref;

# print output
foreach my $i ( 0 .. $#bin_centres ) {
    printf STDOUT "%f %f\n", $bin_centres[$i], $hist_values[$i];
}
