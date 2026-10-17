#!/usr/bin/env perl
#
# original filename: rstar40.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Sun Mar 19, 2006  18:44:31 EST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/analysis
#

use strict;
use warnings;
use File::Basename;

use Local::Constants;
use Local::Stardata;
use Local::Units;
use Local::Misc;

my $exe = basename($0);
my $usage = "Usage: $exe spectype distance(pc)\n";

my ($mk, $dist_star) = @ARGV;
die $usage unless $dist_star;


# get the projected size at 40 AU
my $dist_star_M = $dist_star * $MperPC;

my $dist_kb = 40.0;  # AU
my $dist_kb_M = $dist_kb * $MperAU;

my $R_star = $star{$mk}{"R"};
my $R_star_M = $R_star * $Ro_M;

my $angle = $R_star_M/$dist_star_M;

my $R_star_40 = $dist_kb_M * $angle;

my $R_star_40s = distanceUnits($R_star_40, "m");


# get the V magnitude

my $Mv = $star{$mk}{"Mv"};
my $mmM = 5.0*log10($dist_star) - 5.0;

my $V = $Mv + $mmM;

# get the flux
# http://www.astro.utoronto.ca/~patton/astro/mags.html#flux
# Band 	 lambda_c 	 dlambda/lambda 	 Flux at m=0 	 Reference
#	um 		Jy 	
#U 	0.36 	0.15 	1810 	Bessel (1979)
#B 	0.44 	0.22 	4260 	Bessel (1979)
#V 	0.55 	0.16 	3640 	Bessel (1979)
#R 	0.64 	0.23 	3080 	Bessel (1979)
#I 	0.79 	0.19 	2550 	Bessel (1979)
#J 	1.26 	0.16 	1600 	Campins, Reike, & Lebovsky (1985)
#H 	1.60 	0.23 	1080 	Campins, Reike, & Lebovsky (1985)
#K 	2.22 	0.23 	670 	Campins, Reike, & Lebovsky (1985)
#g 	0.52 	0.14 	3730 	Schneider, Gunn, & Hoessel (1983)
#r 	0.67 	0.14 	4490 	Schneider, Gunn, & Hoessel (1983)
#i 	0.79 	0.16 	4760 	Schneider, Gunn, & Hoessel (1983)
#z 	0.91 	0.13 	4810 	Schneider, Gunn, & Hoessel (1983)
#1 Jy = 10^-23 erg sec^-1 cm^-2 Hz^-1
#1 Jy = 1.51e7 photons sec^-1 m^-2 (dlambda/lambda)^-1


my $V0_flux_Jy = 3640;  # Jy sec^-1 m^-2 (dlambda/lambda)^-1

my $V_flux_Jy = $V0_flux_Jy * 10**(-0.4*$V);

my $dlambda = 100;  # nm
my $lambda = 550; # nm

my $photonFlux_per_Jy = 1.51e7 * ($dlambda/$lambda); 

my $V_flux_phot = $V_flux_Jy * $photonFlux_per_Jy;


# output
printf STDOUT "R* = %s    V = %.2f mag   (%.2f phot/sec/m^2) \n", $R_star_40s, $V, $V_flux_phot;

exit 0;
