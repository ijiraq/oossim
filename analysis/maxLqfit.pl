#!/usr/bin/env perl
#
# original filename: maxLqfit.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Thu Feb  2, 2006  11:12:20 EST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/analysis
#

use strict;
use warnings;
use File::Basename;

use lib "$ENV{HOME}/libperl";
use Local::Constants;
use Local::Fit;

my $exe = basename($0);
my $usage = "Usage: $exe datafile beta_guess\n";

my ($datafile, $beta_guess) = @ARGV;
die $usage unless $datafile;

my $ds = 0.00001;
my $iter_lim = 200;
my $ds_ref = [$ds, $ds];
my $A_guess = 0.65;
my $tol = [0.001, 0.001];


###############################################################
# read in the data
my $data_tmp = [];
my $data = [];
open (DATA, "$datafile");
while (<DATA>) { 
    next if /^\#/; 
    my ($f, $p, $ph, $re, $im) = (split);
    next if $f == 0;
    push @$data_tmp, [$f, sqrt($re**2 + $im**2) ] if ($f > 0.01 && $f < 20); 
}
close (DATA);

my $N = scalar @$data_tmp;
my ($i1, $i2) = (0, int(1.0*$N)-1);
@$data = @$data_tmp[$i1 .. $i2];


#################################################################
# grid find
my $grid = 0;
if ($grid) {

    my $n = 50;
    my ($bmin, $bmax, $Amin, $Amax) = (-0.6, -0.4, 0.5, 0.8 );
    my ($d_b, $d_A) = (  ($bmax - $bmin)/$n, ($Amax - $Amin)/$n );
    open (GRID, ">maxLgridzoom.dat");
    for (my $beta=$bmin; $beta<$bmax; $beta+=$d_b) {
	for (my $A=$Amin; $A<$Amax; $A+= $d_A) {
	    my $param = [$beta, $A];
	    my ($lnL) = lnL($data, \&lnLi_powerSpec, $param, $ds_ref);
	    printf GRID "$beta $A %.4f\n", $lnL;
	    printf STDERR "$beta $A\r", $lnL;
	}
	printf GRID "\n";
	#printf STDERR "\n";
    }
    close(GRID);
}



####################
# iterate the max liklihood solution
my $param = [$beta_guess, $A_guess];

#my ($paramFit, $iter) = maxLik($data,\&lnLi_powerSpec, $param, $ds_ref, $tol);
my ($paramFit, $iter) = maxLik($data,\&lnLi_powerSpec, $param, $ds_ref, $tol);
my ($beta, $A) = @$paramFit;


printf STDOUT "#beta = %.6f  A = %.6f   iter = $iter\n", $beta, $A;

exit 0;
