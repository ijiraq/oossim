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
my $usage = "Usage: $exe infile [xcol:ycol] [pad=padvalue] [zero] \n";

my ($infile) = shift @ARGV;
die $usage unless $infile;

# get some command line args
my ($xcol, $ycol);
my $padvalue = 0;
my $zero = 0;
foreach my $arg (@ARGV) {
    
    if ( $arg =~ /\d+:\d+/ ) {
	($xcol, $ycol) = $arg =~ /^(\d+):(\d+)$/;
    } elsif ( $arg =~ /^pad=/ ) {
	$padvalue = $arg =~ /^pad=(\S+)$/;
    } elsif ( $arg =~ /^zero/ ) {
	$zero++ if $arg =~ /^zero/;
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
foreach my $i (1 .. $N-1) {
    $dx += $data[$i]->[0] - $data[$i-1]->[0];
}
$dx /= $N-1;

# get the number of points needed to reach the next binary power
my $pow2 = log($N)/log(2.0);
my $pow2above = int($pow2+1.0);
my $N2 = 2**($pow2above);

my $extra = $N2 - $N;
my $extrahalf = int($extra/2);  # this should be an integer

my ($lead,$tail) = ($extrahalf, $extrahalf);
$tail++ if ($extra%2);


for my $i (0 .. $N2-1) {

    my ($x,$y);
    if ($i<$lead) {
	$x= $data[0]->[0] - $dx*($lead-$i);
	$y=$padvalue;
    } elsif ($i>=$lead && $i<$lead+$N) {
	$x = $data[$i-$lead]->[0];
	$y = $data[$i-$lead]->[1];
    } elsif ($i>=$lead-$N) {
	$x = $data[-1]->[0] + $dx*($i-$lead-$N+1);
	$y = $padvalue;
    }
    printf "%.6f %.6f\n", ( ($zero) ? ($x+$dx*$lead) : $x ) , $y;
}

exit 0;
