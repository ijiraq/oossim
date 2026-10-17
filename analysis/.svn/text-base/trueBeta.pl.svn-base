#!/usr/bin/env perl
#
# original filename: trueBeta.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Thu Oct 26, 2006  15:11:31 DST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/pack_main/sandbox/analysis
#


use strict;
use warnings;
use File::Basename;

use Local::Constants;
use Local::Astrotools;
use Local::Fit;

my $exe = basename($0);
my $usage = "Usage: $exe infile xcol ycol\n";

my ($lo, $hi) = (0.3, 20.0);

my ($infile, $xcol, $ycol) = @ARGV;
die $usage unless $infile;

$xcol = ($xcol) ? $xcol-1 : 0;
$ycol = ($ycol) ? $ycol-1 : 1;

sub log10($) { return log($_[0])/log(10.0); }

my @data;
open (INFILE, "$infile");
while (<INFILE>) {   
    next if /^\#/;
    my ($x, $y) = map {1.0*$_} (split)[$xcol, $ycol];
    next unless ($x > $lo && $x < $hi );
    my ($logx, $logy) = ( log10($x), log10($y) );
    push @data, [ $logx, $logy ];
}
close (INFILE);


my $a1 = 0.963;
my $a0 = 0.068;
my $a1rms = 0.008;
my $a0rms = 0.008;

my ($interc, $interc_rms, $beta, $beta_rms) = lineFit(\@data);
my $beta_true = ($beta - $a0)/$a1;
my $beta_true_rms = $beta_rms + $a0rms + (($beta-$a0)/$a1**2)*$a1rms;

printf STDOUT "interc = %.4f\n".
    "interc_rms = %.4f\n".
    "beta_true = %.4f\n".
    "beta_true_rms = %.4f\n".
    "beta = %.4f\n".
    "beta_rms = %.4f\n",
    $interc,
    $interc_rms,
    $beta_true,
    $beta_true_rms,
    $beta,
    $beta_rms;

exit 0;
