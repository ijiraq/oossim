#!/usr/bin/env perl
#
# original filename: lineFit.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Tue Jan 24, 2006  13:52:54 EST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/analysis
#

use strict;
use warnings;

use lib "$ENV{HOME}/libperl";
use Local::Constants;
use Local::Fit;
#use Local::Fit;
use Local::Misc;

my $usage = "Usage: datafile xCol yCol [dyCol]\n";

my ($datafile, $xCol, $yCol, $dyCol) = @ARGV;
die $usage unless ( defined($xCol) && $xCol=~/\d+/ && 
		    defined($yCol) && $yCol=~/\d+/ );
$xCol -= 1;
$yCol -= 1;
$dyCol -= 1 if defined $dyCol;


# read in the data;
my @data;
open (DATAFILE, "$datafile") or die "Could not open $datafile\n";
while (<DATAFILE>) {
    next if /^\#/;
    push @data, [ (split)[$xCol,$yCol,$dyCol] ] if defined $dyCol;
    push @data, [ (split)[$xCol,$yCol] ]        if ! defined $dyCol;
}
close (DATAFILE);


# call the fitting routine
my ($a, $rms_a, $b, $rms_b, $r, $X2) = lineFit(\@data);

printf STDOUT "f(x) = a + b*x\n".
    "a  = %.4g #+/- %.4g\n".
    "b  = %.4g #+/- %.4g\n".
    "r  = %.4f\n".
    "X2 = %.4g\n", $a, $rms_a, $b, $rms_b, $r, $X2;

exit 0;
