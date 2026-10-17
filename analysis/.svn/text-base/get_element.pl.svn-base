#!/usr/bin/env perl
#
# original filename: get_element.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Sun Jan 13, 2008  18:20:28 EST
#  Host: bender.astro.princeton.edu
#  Working Directory: /Users/bick/sandbox/analysis
#
# script to pluck out the r'th row and c'th column of a table

use strict;
use warnings;
use File::Basename;

my $exe = basename($0);
my $usage = "Usage: $exe infile row col\n";

my ($infile, $r, $c) = @ARGV;
die $usage unless defined($c);

$c -= 1;
my $r_i = 1;
open (INFILE, "$infile");
while (<INFILE>) {
  printf "%s\n", (split)[$c] if ($r_i==$r);
  last if ($r_i++ > $r);
}
close(INFILE);

exit 0;
