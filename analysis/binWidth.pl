#!/usr/bin/env perl
#
# original filename: binWidth.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Mon Oct 16, 2006  22:11:12 DST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/pack_main/sandbox/analysis
#


use strict;
use warnings;
use File::Basename;

#use lib "$ENV{HOME}/libperl2";
use Local::Constants;
use Local::Statistics;

my $exe = basename($0);
my $usage = "Usage: $exe (infile column) OR (N rms)\n";

die $usage unless $ARGV[0];

my ($infile, $column, $N, $rms);
if (  (-s $ARGV[0]) || $ARGV[0] eq '-' ) {
    ($infile, $column) = @ARGV;
} else {
    ($N, $rms) = @ARGV;
    die $usage unless $rms;
    printf STDOUT "%.3f\n", binWidth($N, $rms);
    exit 0;
}

$column = ($column) ? $column-1 : 0;
my @array;
open (INFILE, "$infile");
while (<INFILE>) {
    my @line = split;
    push @array, $line[$column];
}
close (INFILE);

my ($nSigma, $tol, $maxiter) = (3.0, 0.001, 3);
my $rmsC = rmsClip(\@array, $nSigma, $tol, $maxiter);

printf STDOUT "%.3f\n", binWidth(scalar @array, $rmsC);

exit 0;
