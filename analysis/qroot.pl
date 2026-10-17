#!/usr/bin/env perl
#
#

use strict;
use warnings;
use Math::Complex;

my $PI = 3.14159265358979;
my $usage = "usage: $0 a b c  (a*x^2 + b*x + c = 0)\n";

my ($a, $b, $c) = @ARGV;
die $usage unless $c;

$a = cplx($a,0);
$b = cplx($b,0);
$c = cplx($c,0);

my $x1 = (-$b + sqrt($b**2.0 - 4.0*$a*$c))/(2.0*$a);
my $x2 = (-$b - sqrt($b**2.0 - 4.0*$a*$c))/(2.0*$a);

sub cplxParse ($) { my ($x)=@_; return (Re($x), Im($x), atan2(Im($x),Re($x)));}
my ($x1r,$x1i,$x1p) = cplxParse($x1);
my ($x2r,$x2i,$x2p) = cplxParse($x2);


printf STDOUT "%6.4g %s j%.4g \tMag: %.4g   Phase:   %.4g rad = %.4g deg\n", 
    $x1r, $x1i>0? "+":"-", abs($x1i),     abs($x1), $x1p, 180.0*$x1p/$PI;
printf STDOUT "%6.4g %s j%.4g \tMag: %.4g   Phase:   %.4g rad = %.4g deg\n", 
    $x2r, $x2i>0? "+":"-", abs($x2i),     abs($x2), $x2p, 180.0*$x2p/$PI;

