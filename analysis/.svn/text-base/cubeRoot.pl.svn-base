#!/usr/bin/env perl
#
#

use strict;
use warnings;
use Math::Complex;

my $usage = "usage: $0 a1 a2 a3   (x^3 + a1*x^2 + a2*x + a3 = 0)\n";
my $PI = 3.141592654;

my ($a1, $a2, $a3) = @ARGV;
die $usage unless $a3;

$a1 = cplx($a1,0);
$a2 = cplx($a2,0);
$a3 = cplx($a3,0);


# see Schaum's Mathematical Handbook, pp 10

my $Q = (3.0*$a2 - $a1**2.0) / 9.0;
my $R = (9.0*$a1*$a2 - 27.0*$a3 - 2.0*$a1**3.0) / 54.0;
my $D = $Q**3.0 + $R**2.0;
my $S = ($R + sqrt($D) )**(1.0/3.0);
my $T = ($R - sqrt($D) )**(1.0/3.0);

my $x1 = $S + $T - $a1/3.0;
my $x2 = -0.5*($S+$T)-$a1/3.0 + 0.5*sqrt(3.0)*($S-$T)*i;
my $x3 = -0.5*($S+$T)-$a1/3.0 - 0.5*sqrt(3.0)*($S-$T)*i;

sub cplxParse ($) { my ($x)=@_; return (Re($x), Im($x), atan2(Im($x),Re($x)));}
my ($x1r,$x1i,$x1p) = cplxParse($x1);
my ($x2r,$x2i,$x2p) = cplxParse($x2);
my ($x3r,$x3i,$x3p) = cplxParse($x3);


printf STDOUT "%6.4g %s j%.4g \tMag: %.4g   Phase:   %.4g rad = %.4g deg\n", 
    $x1r, $x1i>0? "+":"-", abs($x1i),     abs($x1), $x1p, 180.0*$x1p/$PI;
printf STDOUT "%6.4g %s j%.4g \tMag: %.4g   Phase:   %.4g rad = %.4g deg\n", 
    $x2r, $x2i>0? "+":"-", abs($x2i),     abs($x2), $x2p, 180.0*$x2p/$PI;
printf STDOUT "%6.4g %s j%.4g \tMag: %.4g   Phase:   %.4g rad = %.4g deg\n", 
    $x3r, $x3i>0? "+":"-", abs($x3i),     abs($x3), $x3p, 180.0*$x3p/$PI;
