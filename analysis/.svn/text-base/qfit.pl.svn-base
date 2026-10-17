#!/usr/bin/env perl
#
# original filename: qfit.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Tue Jan 24, 2006  15:14:16 EST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/analysis
#
#  Code to measure the slope of a line when log-log is needed.
#
use strict;
use warnings;

use Local::Fit;

my $usage = "Usage: $0 specfile freqCol powerCol\n";

my ($specfile, $fCol, $pCol) = @ARGV;
die $usage unless $pCol;
$fCol -= 1;
$pCol -= 1;

# read in the data
my @data;
my ($maxf, $minf);
open (SPECFILE, "$specfile");
while (<SPECFILE>) { 

    next if /^\#/;
    my ($f, $power) = (split)[$fCol,$pCol];
    next if ($f == 0.0);

    push @data, [$f, $power];

}
close (SPECFILE);

# fit the line
my ($aa, $rms_aa, $bb, $rms_bb, $r, $X2) = qFit(\@data);
my ($q, $dq) = ($bb, $rms_bb);

printf STDERR "q = %.4f # +/- %.4f (r^2 = %.3f)\n", $q, $dq, $r**2;

exit 0;
