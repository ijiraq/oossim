#!/usr/bin/perl -w
# Perl Module:  KBO.pm
#
# Purpose: a Perl module containing functions useful in KBO astronomy
# 
# Author: Steve Bickerton, McMaster University
#         bick@physics.mcmaster.ca
#
#
#
# Functions:
#
# getKBO ($n_kbos): generates a KBO by drawing observable properties from 
#                appropriate distribution functions.
# occultPercent ($xstar,$ystar,$Rstar,$xkbo,$ykbo,$Rkbo): returns the percent
#                of a star's area occulted by a passing kbo
#

package  Local::KBO;


use Carp;
use Math::Trig;

require  Exporter;


our @ISA       = qw(Exporter);

our @EXPORT    = qw(getKBO occultPercent);

our @EXPORT_OK = qw();

our @EXPORT_TAGS = (
		    ALL => [ @EXPORT_OK ],
		    );

our $VERSION   = 1.00;

use lib "$ENV{HOME}/libperl";    #add ~/libperl
no lib ".";                      #remove cwd
use Math::Random qw(random_normal random_multinomial);



# -------------------------------------------------------
#
# function: getKBO
#
# Purpose: Uses functions from Math::Random to generate a KBO
#          with physical and orbital parameters (roughly) consistent with
#          those of the KB as of writing (see date in module header)
#          
#          
#
# Req'd Parameters: N/A
#
# Opt'l Parameters: $iter_tolerance, required convergence (in degrees)
#                   for accepted solution (default 0.001).
#                   $max_iter, max number of iterations to use before
#                   exiting the function with return -1.
#
# Limitation: 
#

#-----------------------------------------------

sub getKBO {

    $_[0] = $_[0] || 0.001*$PI/180.0; 
    my $iter_tolerance       = $_[0]*$PI/180.0;
    $_[1] = $_[1] || 100;      
    my $max_iter             = $_[1];

    # Definitions of typical KBO distributions for the KB

    # Define population ID numbers
    my $CLAS = 0;
    my $PLUT = 1;
    my $SCAT = 2;

    # - Eccentricities  ( gaussian distrib with mean $av_e, std dev $sd_e )
    # - Inclinations (gaussian distrib with mean $av_i, std dev $sd_i) 
    #   to get a half-distribution (from 0 up) set av_i's to zero, 
    #   and use sd as mean
    # - semimajor axes (gaussian distrib with mean $av_a, std dev $sd_a )
    # - KBO size (diameter) mins (km) and distribution slopes (-ve assumed)
    #   ... will use a power law distribution with slope -4.4 (gladman,2001)

    my (@av_e, @sd_e, @av_i, @sd_i, @av_a, @sd_a, @min_D, @alf_D);
    $av_e[$CLAS] = 0.0;        $sd_e[$CLAS] = 0.08;  
    $av_i[$CLAS] = 0.0;        $sd_i[$CLAS] = 4.0/57.3;   
    $av_a[$CLAS] = 47.0;       $sd_a[$CLAS] =  10.0;   
    $min_D[$CLAS] = 0.5;       $alf_D[$CLAS] = 4.4;

    $av_e[$PLUT] = 0.22;       $sd_e[$PLUT] = 0.05;   
    $av_i[$PLUT] = 12.0/57.3;  $sd_i[$PLUT] = 6.0/57.3;   
    $av_a[$PLUT] = 39.5;       $sd_a[$PLUT] =  0.1;   
    $min_D[$PLUT] = 0.5;       $alf_D[$PLUT] = 4.4;

    $av_e[$SCAT] = 0.2;        $sd_e[$SCAT] = 0.6;    
    $av_i[$SCAT] = 0.00;       $sd_i[$SCAT] = 20/57.3;     
    $av_a[$SCAT] = 300.0;      $sd_a[$SCAT] = 250.0;
    $min_D[$SCAT] = 0.5;       $alf_D[$SCAT] = 4.4;


    # ------------------------------------------

    # pick a kbo family
    my @familyPercent;
    #my $pop_id = chooseFamily(0.45,0.36,0.18); # CLAS,PLUT,SCAT
    my $pop_id = chooseFamily(0.30,0.10,0.60); # CLAS,PLUT,SCAT
    
    # pick suitable parameters the type of kbo just chosen

    # orbital parameters

    # gaussian distributions  (eccentricity, inclination, semi-maj axis)
    my ($e, $a, $incl) ;
    do {
	$e= abs(random_normal(1,$av_e[$pop_id],$sd_e[$pop_id]));
	$incl = abs(random_normal(1,$av_i[$pop_id],$sd_i[$pop_id]));
	$a = random_normal(1,$av_a[$pop_id],$sd_a[$pop_id]);
    } until ( $a*(1-$e) > 35  && 
	      ($a*(1-$e) < 45 || $e < 0.2) &&
	      $e < 0.80 &&
	      $incl < 45/57.3 &&
	      $incl > 0.00001 &&
	      $e > 0.0001 ) ;

    # uniform distributions
    my $omega = $TWOPI*rand(); # argument of perihelion
    my $M     = $TWOPI*rand(); # mean anomaly
    my $Omega = $TWOPI*rand(); # longitude of ascending node

    # power law distributions  ( diameter )
    my $D = randPowerLaw($min_D[$pop_id], $alf_D[$pop_id]);

    # convert $M (mean anomaly) to $w (true anomaly)
    my $w = meanAnom2Theta($M, $e, $iter_tolerance, $max_iter);

    # Get radius of orbit and elevation
    my $r = $a*(1-$e**2)/(1+$e*cos($w));
    my $z = $r*sin($incl)*sin($omega+$w);

    return ($pop_id, $D, $a, $w, $r, $z, $e, $omega, $incl, $Omega , $M);
}


# -------------------------------------------------------
#
# function: occultPercent
#
# Purpose: To determine the percentage of a star's projected area occulted
#          by a passing KBO given coords and radius of each.
#
# Req'd Parameters: $xstar,ystar,$Rstar: coords and radius of the star
#                   $xkbo,ykbo,$Rkbo: coords and radius of the kbo
#
# Limitation:
#
#-----------------------------------------------

sub occultPercent ($$$$$$) {

    ($x_star,$y_star,$R_star,$x_kbo,$y_kbo,$R_kbo) = @_;

    # distance between the star and occulting object
    $d = sqrt( ($x_star-$x_kbo)**2+($y_star-$y_kbo)**2 );

    # if only a portion of each overlaps the other
    if ( ($d < ($R_star+$R_kbo)) && ($d > abs($R_star-$R_kbo)) ) {

	$A_star = $PI*$R_star**2;  
	$A_kbo  = $PI*$R_kbo**2;

	# use cos-law to get the angle between the line connecting
	# the two centres and one intersection of the two circles
	# (there are two intersecting points symmetric about the connect-line
	$theta_star = 2*acos(($R_star**2+$d**2-$R_kbo**2) / (2*$R_star*$d));
	$theta_kbo  = 2*acos(($R_kbo**2 +$d**2-$R_star**2)/ (2*$R_kbo*$d));

	# Get the area of the little rounded part at the tip of the 
	# pie slice subtended by theta
	$A_star_seg = 0.5*$R_star**2*($theta_star - sin($theta_star));
	$A_kbo_seg  =  0.5*$R_kbo**2*($theta_kbo  - sin($theta_kbo ));

	# Add up the two roundish bits and the lens shape is the intersection
	$A_block = $A_star_seg + $A_kbo_seg;

    # elsif ( one is entirely overlapping the other )
    } elsif ( $d < abs($R_star-$R_kbo) ) {
	$A_star = $PI*$R_star**2;
	$A_block = ($R_kbo>$R_star) ? $A_star : $PI*$R_kbo**2;       

    # else ... there's no overlap at all.
    } else {
	$A_star = 1.0;
	$A_block = 0.0;
    }

    return $A_block/$A_star;
}



1;
