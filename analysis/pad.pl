#!/usr/bin/env perl
#
# original filename: binaryPad.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Thu Nov 16, 2006  12:15:45 EST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/pack_main/sandbox/analysis
#


use strict;
use warnings;
use File::Basename;

use Local::Constants;

my $exe = basename($0);
my $usage = "Usage: $exe infile N [xcol:ycol] [pad=padvalue (default=0)]\n";

my ($infile, $n) = @ARGV;
die $usage unless $n;

# get some command line args
my ($xcol, $ycol);
my $padvalue = 0;
foreach my $arg (@ARGV) {
    
    if ( $arg =~ /\d+:\d+/ ) {
	($xcol, $ycol) = $arg =~ /^(\d+):(\d+)$/;
    } elsif ( $arg =~ /^pad=/ ) {
	($padvalue) = $arg =~ /^pad=(\S+)$/;
    }

}
$xcol = ($xcol) ? $xcol-1 : 0;
$ycol = ($ycol) ? $ycol-1 : 1;


# read in the data
my @data;
open (INFILE, "$infile");
while(<INFILE>) {
    next if /^\#/;
    my ($x, $y) = (split)[$xcol,$ycol];
    push @data, [$x,$y];
}
close (INFILE);
my $N = scalar @data;

# get the coordinate separation
my $dx;
my $xmin = my $xmax = $data[0]->[0];
foreach my $i (1 .. $N-1) {
  my $x = $data[$i]->[0];
  $dx += $x - $data[$i-1]->[0];
  $xmin = $x if $x < $xmin;
  $xmax = $x if $x > $xmax;
}
$dx /= $N-1;

# print out the low pad numbers, the originals, and the hi pad numbers
for my $i (reverse (1 .. $n)) {printf "%.6f %.6f\n", $xmin - $i*$dx, $padvalue;}
for my $i ( 0 .. $N-1 ) {printf "%.6f %.6f\n", @{$data[$i]}; }
for my $i ( 1 .. $n ) {printf "%.6f %.6f\n", $xmax + $i*$dx, $padvalue;}

exit 0;
