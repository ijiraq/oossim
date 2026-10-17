#!/usr/bin/env perl
#
#

use strict;
use warnings;
use lib "$ENV{HOME}/libperl";
use Local::Filters;

my $usage = "usage: $0 [infile] xcol ycol binwidth kernel \n";

die "$usage" unless @ARGV;
( -s $ARGV[0] ) or unshift(@ARGV, "-");
my ($infile, $xcol, $ycol, $binwidth, $kernel) = @ARGV;
die "$usage" if ! $kernel;


# read in the data
open (INFILE, "$infile");
my @array;
while (<INFILE>) {
    next if $_=~/^\#/;
    my @line = split;
    my ($x, $y) = ( $line[$xcol-1], $line[$ycol-1] );
    push @array, [$x, $y];
}
close (INFILE);

#my $array_ref = \@array;
#timethese (1, {smooth2 => sub{ smooth2($array_ref, $binwidth, $kernel)},
#		 smooth3 => sub{ smooth3($array_ref, $binwidth, $kernel)} });

# call the smooth2 routine
#my $smoothed2_ref = smooth2(\@array, $binwidth, $kernel);
my $smoothed2_ref = smoothC(\@array, $binwidth, $kernel);



# output the result
printf STDOUT "# X                1\n".
    "# Y_smooth         2\n".
    "# Y_orig           3\n".
    "# Y_orig/Y_smooth  4\n";
foreach my $i (0 .. $#{$smoothed2_ref}) {
    my ($x, $ys, $y) = (@{$$smoothed2_ref[$i]}[0,1], ${@{$array[$i]}}[1]);
    printf STDOUT "%f %f %f %f\n",$x, $ys, $y, $y/$ys if ($ys);
    printf STDOUT "%f %f %f %s\n",$x, $ys, $y, "NAN" if (!$ys);
}
