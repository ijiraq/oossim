#!/usr/bin/env perl
#
#

use strict;
use warnings;
#use lib "$ENV{HOME}/libperl2";
use Local::Integrate;

my $usage = "usage: $0 [infile] col1 col2 x1 x2 numberonly\n";

die "$usage" unless @ARGV;
( -e $ARGV[0] ) or unshift(@ARGV, "-");
my ($infile, $col1, $col2, $x1, $x2, $numberonly) = @ARGV;
die "$usage" if ! defined $numberonly;


# read in the values
my @values;
open (INFILE, "$infile");
while (<INFILE>) { 
    next if /^#/;
    my @v = split; 
    push @values, [ $v[$col1-1], $v[$col2-1] ]; 
}
close (INFILE);

# call the integral routine
my $integral = integrate(\@values, $x1, $x2, $numberonly);

# if only the final integral value is requested .. print it
if ($numberonly) {
    printf STDOUT "$integral\n";  # $integral is just a number

# this prints the integral function
} else {
    foreach my $pair (@{$integral}) {
	printf STDOUT "$$pair[0] $$pair[1]\n";  # integral is an array ref
    }
}


