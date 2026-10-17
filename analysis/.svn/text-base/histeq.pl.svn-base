#!/usr/bin/env perl
#
# original filename: histeq.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Mon Mar 31, 2008  15:34:13 DST
#  Host: bender.astro.princeton.edu
#  Working Directory: /Users/bick/usr/bin/analysis
#


use strict;
use warnings;
use File::Basename;

use Local::Constants;
use Local::Astrotools;

my $exe = basename($0);
my $usage = "Usage: $exe file x:y:z\n";

my ($infile, $columns) = @ARGV;
die $usage unless $columns;

my ($xcol, $ycol, $zcol) = split /:/, $columns;
die "$columns - x, y, z must be integers in command line\n" 
  unless ($xcol =~ /\d+/ and $ycol =~ /\d+/ and $zcol =~ /\d+/);


# read in the data
my @data = ();
open(INFILE, "$infile");
while(<INFILE>) {
  next if /\#/;
  next unless /\d+/;
  my ($x, $y, $z) = (split)[$xcol-1,$ycol-1,$zcol-1];
  push @data, [$x, $y, $z];
}
close(INFILE);

# sort on z
my @datasort = sort {$a->[2] <=> $b->[2]} @data;

# make the cdf lookup table
my %cdf;
my $i = 0;
foreach my $ref (@datasort) {
  $cdf{$ref->[2]} = $i++;
}

# output the histeq
my $cdf0 = $cdf{$datasort[0]->[2]};
my $N = (scalar @datasort) - $cdf0;
my $xprev = $data[0]->[0];
foreach my $ref (@data) {
  my ($x, $y, $z) = @$ref;
  printf "\n" unless $x == $xprev;
  printf "$x $y %.6g $z\n", ($cdf{$z}-$cdf0)/$N;
  $xprev = $x;
}

exit 0;
