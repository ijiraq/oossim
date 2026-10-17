#!/usr/bin/env perl
#
#

use strict;
use warnings;

use lib "$ENV{HOME}/libperl";
use Local::Constants;

use File::Basename;
use Math::Trig;

my $base = basename($0);

my ($infile, $expr, $x1, $x2, $columns, @params) = @ARGV;
my $usage = "usage: $base infile expr x1 x2 columns [param1 param2 ...] \n".
    "expr = f(x)=function  _OR_  \n".
    "            line, polyN (N is an integer), gauss, exp, ten\n".
    "example: $base data \"f(x)=a*x**2+b*x+c\" 0 100 1:2 a b c=100\n".
    "         $base data \"f(x)=A*(2.71828)**(-(x-mean)**2/(2*rms**2))\" -5 5 1:2 A mean rms\n".
    "         $base data line 0 10 1:2 m b\n".
    "         $base data gauss -4 4 1:2 A mean rms\n".
    "         $base data poly2 0 10 1:2 a0 a1=2 a2=4\n".
    "         $base data line 0 10 1:2\n";


die $usage unless $expr;


# polynomials

if ($expr =~ /^line/) {
    $expr = "f(x)=m*x + b";
    @params = ("m", "b") unless (scalar @params);
}

if ($expr =~ /^poly/) {

    my ($order) = $expr =~ /^poly(\d+)/;

    my $have_params = scalar @params;
    $expr = "f(x)=a0";
    @params = "a0" unless $have_params;
    for (my $term=1; $term<=$order; $term++) {
	$expr .= " + a${term}*x**${term}";
	push @params, "a${term}" unless $have_params;
    }
}


# other functions

if ($expr =~ /gauss/) {
    $expr = "f(x)=A*(2.71828)**(-(x-mean)**2/(2*rms**2))";
    @params = ("A", "mean", "rms") unless (scalar @params);
}

if ($expr =~ /exp/) {
    $expr = "f(x)=A*($EXP)**(q*x)";
    @params = ("A", "q") unless (scalar @params);
}

if ($expr =~ /ten/) {
    $expr = "f(x)=A*(10)**(q*x)";
    @params = ("A", "q") unless (scalar @params);
}

if ($expr =~ /cosh/) {
    $expr = "f(x)=Amp*cosh(k*x)";
    @params = ("Amp", "k") unless (scalar @params);
}

if ($expr =~ /sinh/) {
    $expr = "f(x)=Amp*sinh(k*x)";
    @params = ("Amp", "k") unless (scalar @params);
}

die "$usage" if ! scalar @params;



###################################################
#  Build the gnuplot script

my ($f, $f_of_x) = split /=/, $expr;

my $gpt_script = "#!/usr/bin/env gnuplot\n";
my $paramlist = "";
foreach my $param (@params) {
    my ($var,$value) = split /=/, $param;
    $gpt_script .= "$param\n" if defined($value);
    $paramlist .= sprintf "%s,", $var;
}
$paramlist =~ s/(.*),$/$1/;

my $TMPDIR = "$ENV{HOME}/tmp";
( -d $TMPDIR ) or mkdir($TMPDIR);
my $logfile = "${TMPDIR}/mlfit.log";
( -f $logfile ) and unlink($logfile);

$gpt_script .= "$expr\n".
    "set fit errorvariables\n".
    "FIT_MAXITER = 100\n".
    #"set fit logfile \'$logfile\'\n".
    "set print \'-\'\n".
    "fit [${x1}:${x2}] $f \'$infile\' using $columns via $paramlist\n";


foreach my $param (@params) {
    my ($var,$value) = split /=/, $param;
    $gpt_script .= "${var}_str = sprintf(\"$var = %%.4f +/- %%.4f\", $var, ${var}_err)\n".
	"print ${var}_str\n";
}


###################################################
#  Run gnuplot

printf STDOUT "#$expr\n";

(-f $logfile) and unlink($logfile);
open (GNUPLOT, "| gnuplot 2> /dev/null") or die "Couldn't open Gnuplot\n";
printf GNUPLOT "$gpt_script";
#printf STDOUT "$gpt_script";
close (GNUPLOT);

exit 0;


#unlink "$logfile";
