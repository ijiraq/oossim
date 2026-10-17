#!/usr/bin/env perl
# Perl Module:  KBOdensity.pm
#
# Purpose: a Perl module  containing a subroutine to get the density of KBOs
#               per sqr arcsec, given a minimum size and slope of the size dist
# Author: Steve Bickerton, McMaster University
#         bick@physics.mcmaster.ca
#         Thurs.  Sep 22 2005
package  Local::KBOdensity;

use strict;
use warnings;
use Carp;

use Math::Trig; 
use Local::Constants;
use Local::Astrotools;
use Local::Coords;
use Local::Utility;

require  Exporter;
our @ISA       = qw( Exporter );
our @EXPORT    = qw( KBOdensity KBOprobability expectationTime m2arcsec
		     maxDensity pMax DEffective KBOpoisProb expectTimePois
                     KBOdensity_doubleKnee);
our @EXPORT_OK = qw();
our @EXPORT_TAGS = ( ALL => [ @EXPORT_OK ], );
our $VERSION   = 1.00;

######################################################################
sub KBOdensity ($$$$) {

    my ($r_min, $r_knee, $q, $q_doh) = @_;

    my $DMax       = 2.0*1160.0;   # diameter of Pluto
    my $Do         = 2.0*$r_min/1000.0;
    my $Dk         = 2.0*$r_knee/1000.0;

    my $c     = 2;       # const for r^(-c)  ie. slope of radial density
                         # not the speed of light
    my $Ro    = 23.4;    # zero-point mag of cum. lum. Func.
    my $r     = 40.0;    # distance to the kuiper belt in AU
    my $C     = 18.8;    # from Eq. 1 above
    my $S     = 1.0;     # area of sky under study (in sqr.degrees)
    
    my $rMax  = 50.0;    # most distant KBOs (AU)
    my $rMin  = 30.0;    # nearest KBOs (AU)
    
    my $alpha = ($q - 1.0)/5.0;  # a redefinition based on $q
    
    # equation numbers from Gladman et al. 2001, AJ 122 1051
    # need to integrate  n(r,D) dr dD = A r**(-c) D**(-q) dr dD   (eqn 4)

    # solve for the coefficient A  (eqn 9)
    my $x = 3.0 - 2.0*$q - $c;
    my $A = 5*$S*$alpha*10**($alpha*($C-$Ro))*$x / ($rMax**$x - $rMin**$x);
    
    # integral over the range in AU of the KB ==> int r^-c = r^(-c+1) / (-c+1)
    my $coefr = -$c+1.0;
    my $r_int = ( $rMax**$coefr - $rMin**$coefr ) / $coefr;
    
    # integral over the range in KBO size     ==> int D^-q = D^(-q+1) / (-q+1)
    my $coefD = 1.0 - $q;

    # $Do should actually be $Dk according to Gladman2001, but in this
    #   case, it represents any limiting point greater than the Diameter
    #   that defines the knee.
    my $D_int = $Do**($coefD) / (-$coefD);

    # this is more in keeping with Gladman 2001.
    my $D2_int = ( $Dk**($q_doh-$q) * $Do**(1.0-$q_doh) )/ (-$coefD);

    # put these together (choose which D_int to use depending on 
    #   whether we're asked for a point above or below the knee.
    my $n = $A * $r_int * ( ($r_knee<=$r_min) ? ($D_int) : ($D2_int) );   

    # $n is still in number/sqrDeg
    my $nSam = $n/3600.0;            # this is in number/sqrArcMin
    my $nSas = $nSam/3600.0;         # this in in number/sqrArcSec

    return $nSas;
}



sub DEffective ($$$$$$$) {
    my ($D,$AU,$lambda,$RStar,$Dk,$q1,$q2) = @_;   # D in metres
    my $fresnel_scale = sqrt($lambda*$AU*$AU_M/2.0);

    # from Nihei 2007
    #  - but with D transitioning between D and Dmean at 2Fsu
    my $Dmean = Dmean($D, $Dk, $q1, $q2);
    my $Dinterp = transition($D,$D,$Dmean,
			     2.0*$fresnel_scale,$fresnel_scale/1.0);
    my $r_fs = 0.5*$Dinterp/$fresnel_scale;
    my $RStar_fs = $RStar/$fresnel_scale;
    my $omega = 2.0 * ( (sqrt(3.0))**1.5 + $r_fs**1.5 )**(2.0/3.0) + 
      2.0*$RStar_fs;
    my $DEff = $omega*$fresnel_scale;

    return $DEff;
}


sub DEmpirical ($) {
    my ($D) = @_;  # D in metres

    my $r = $D/2.0;
    my $r_emp = 300.0 + 3.0*$r;

    my $D_emp = 2.0 * $r_emp;
    return $D_emp;
}

sub m2arcsec ($$) {

    my ($size, $distance_AU) = @_;  # size in metres, $dist in AU
    return  ($size / ($distance_AU*$AU_M) ) * $ARCSECperRAD;

}



# see my notes (pg 133) for details on probability calcs.
# see also pg 170 of notes for some changes.

sub KBOprobability ($$$$$$$) {
    
    # nSAS = number per square arcsec
    # Dmin = min diameter in metres
    # vRet = retrograd velocity (m/s)
    # AU   = semi-maj axis of KBO orbit in AU
    # t    = duration of observation (seconds)

    my ($nSas, $Dmin, $vRet, $AU, $lambda, $t, $RStar) = @_;  

    my $DEff = DEmpirical($Dmin);
    #my $DEff = DEffective($Dmin,$AU,$lambda,$RStar);     # in metres
    my $DMinAS = m2arcsec($DEff, $AU);    # in arcsec
    
    
    my $ASperM = (1.0 * $ARCSECperRAD / ($AU * $AU_M));
    my $vRet_ASperS = $vRet* $ASperM;   # to as/s  x (as/km)
 
    ##  probabilities for a single object per sqr arcsec ##

    # Astrip in m^2
    my $Astrip = $DMinAS * $vRet_ASperS * 1.0;  # * 1.0 for 1.0 second
    my $Abox = 1.0;                             # arcsec^2
    my $p_1obj_1sec = $Astrip / $Abox;          # prob of occult in 1 second
    
    # prob of seeing nothing in 1 sec with 1 obj per sqr arcsec
    my $p_null_1obj_1sec = 1 - $p_1obj_1sec;   
    # prob of seeing nothing in 1 sec with n objects per square arcsec
    my $p_null_Nobj_1sec = $p_null_1obj_1sec**$nSas;
    # prob of seeing nothing in t sec
    my $p_null_Nobj_tsec = $p_null_Nobj_1sec**$t; 

    # prob of _not_ observing _nothing_ with N obj/sqr arcsec after t sec 
    #  ie.  the probability of 1 or more events
    my $p_oneOrMore_Nobj_tsec = 1 - $p_null_Nobj_tsec;     

    return $p_oneOrMore_Nobj_tsec;

}


sub expectationTime ($$) {

    # p       = probability per unit time
    # percent = confidence probability of something
    my ($p, $percent) = @_;

    # throw an error if necessary
    if ($percent < 0 or $percent > 1.0) {
	carp("percent: $percent not in range 0 < p < 1.0 ... using 0.95\n");
	$percent = 0.95;
    }

    # convert to the percent of seeing nothing.
    my $percent_nothing = 1.0 - $percent;
    

    # units here are time corresponding to units given for $p
    #  ie, if $p is prob/hour, then this is expected hours
    #  percent_nothing = (1-p)^n  (n is number of time units)
    my $expectationTime = log($percent_nothing) / log (1.0 - $p);

    return $expectationTime;
}



sub pMax ($$) {

    # t       = duration of observation (seconds)
    # percent = confidence probability of something

    my ($t, $percent) = @_;

    # throw an error if necessary
    if ($percent < 0 or $percent > 1.0) {
	carp("percent: $percent not in range 0 < p < 1.0 ... using 0.95\n");
	$percent = 0.95;
    }

    # convert to the percent of seeing nothing.
    my $percent_nothing = 1.0 - $percent;
    
    # units here are time corresponding to units given for $p
    #  ie, if $p is prob/hour, then this is expected hours
    #  percent_nothing = (1-p)^n  (n is number of time units)
    my $p = 1.0 - $percent_nothing**(1.0/$t);

    return $p;
}


# see my notes (pg 133) for details on probability calcs.
# see also pg 170 of notes for some changes.

sub maxDensity ($$$$$$) {
    
    # nSAS = number per square arcsec
    # Dmin = min diameter in metres
    # vRet = retrograd velocity (m/s)
    # AU   = semi-maj axis of KBO orbit in AU
    # t    = duration of observation (seconds)

    my ($p_oneOrMore_Nobj_1sec, $Dmin, $vRet, $AU, $lambda, $RStar) = @_;  

    my $DEff = DEmpirical($Dmin);
    #my $DEff = DEffective($Dmin,$AU,$lambda,$RStar);     # in metres
    my $DMinAS = m2arcsec($DEff, $AU);    # in arcsec
    
    
    my $ASperM = (1.0 * $ARCSECperRAD / ($AU * $AU_M));
    my $vRet_ASperS = $vRet* $ASperM;   # to as/s  x (as/km)
 
    ##  probabilities for a single object per sqr arcsec ##

    # Astrip in m^2
    my $Astrip = $DMinAS * $vRet_ASperS * 1.0;  # * 1.0 for 1.0 second
    my $Abox = 1.0;                             # arcsec^2
    my $p_1obj_1sec = $Astrip / $Abox;          # prob of occult in 1 second
    
    # prob of seeing nothing in 1 sec with 1 obj per sqr arcsec
    my $p_null_1obj_1sec = 1.0 - $p_1obj_1sec;   
    my $p_null_Nobj_1sec = 1.0 - $p_oneOrMore_Nobj_1sec;

    # prob of seeing nothing in 1 sec with n objects per square arcsec
    #my $p_null_Nobj_1sec = $p_null_1obj_1sec**$nSas;
    my $nSas = log($p_null_Nobj_1sec) / log($p_null_1obj_1sec);

    return $nSas;

}



############  new calcs using Poisson stats ##################
sub KBOpoisProb ($$$$$$$) {
    
    # nSAS = number per square arcsec
    # Dmin = min diameter in metres
    # vRet = retrograd velocity (m/s)
    # AU   = semi-maj axis of KBO orbit in AU
    # t    = duration of observation (seconds)
    my ($nSas, $bmax, $vRet, $AU, $lambda, $t, $RStar) = @_; 

    my $bmaxAS = m2arcsec($bmax, $AU);
    my $vRetAS = m2arcsec($vRet, $AU);
    my $p = 1.0 - $EXP**(-2.0*$bmaxAS*$vRetAS*$t*$nSas);    
    return $p;
}


sub expectTimePois ($$$$$) {

    # bmax    = max detectable impact param (arcsec)
    # vRet    = retrograde velocity         (arcsec/sec)
    # nSas    = density  (arcsec^-2)
    # Pconf   = confidence probability of something
    my ($bmax, $vRet, $nSas, $AU, $Pconf) = @_;

    my $bmaxAS = m2arcsec($bmax, $AU);
    my $vRetAS = m2arcsec($vRet, $AU);

    # throw an error if necessary
    if ($Pconf < 0 or $Pconf > 1.0) {
	carp("percent: $Pconf not in range 0 < p < 1.0 ... using 0.95\n");
	$Pconf = 0.95;
    }

    my $expectationTime = log(1.0 - $Pconf) / (-2.0*$bmaxAS*$vRetAS*$nSas);
    return $expectationTime;
}

sub Dmean($$$$) {
  my ($Do, $Dk, $q1, $q2) = @_;
  return ( ( (1.0-$q1)/(2.0-$q1) - (1.0-$q2)/(2.0-$q2) )*($Do/$Dk)**($q2-2.0) +
	   (1.0-$q2)/(2.0-$q2) ) * $Do;
}

######### Function added my Tom #############
sub KBOdensity_doubleKnee ($$$$$$$$) {

    # $r_min is the radius (and anything larger) of objects we are intersted in
    # $q1 is the slope of the cum. size dist. func. for sizes greater than the first knee
    # $q2 is the slope of the cum. size dist. func. for sizes greater than the second knee
    # $r_knee1 is the location of the 'largest' knee of the function (i.e. at the largest radius)
    # $r_knee2 is the location of the 'smallest' knee of the function
    # RA and Dec are of the center of the field (i.e. center of M35)

    my ($r_min, $q1, $q2, $q3, $albedo, $rkneeWidth, $RA, $Dec) = @_;
    #print STDOUT "rmin: $r_min, Q1: $q1, Q2: $q2, Q3: $q3 albedo: $albedo rkneeWidth: $rkneeWidth RA: $RA, Dec: $Dec\n";

    #check to see if $RA and $Dec are in decimal format
    my $decnum = '[+-]?\d+\.?\d*';
    my $sexnum = '[+-]?\d{1,3}:\d\d:\d\d\.?\d*';

    if ($RA =~/^$sexnum$/) {
	($RA) = map {15.0*$_} sex2dec($RA);
    }
    ($Dec) = sex2dec($Dec) if ($Dec=~/^$sexnum$/);

    #compute ecliptic latitude of center of field from RA and Dec
    my $E_tilt = deg2rad(23.439281); #tilt of earth to ecliptic in radians
    my $RA_rad = deg2rad($RA);
    my $Dec_rad = deg2rad($Dec);

    my $sin_lat = (cos($E_tilt)*sin($Dec_rad))-(sin($RA_rad)*cos($Dec_rad)*sin($E_tilt));
    my $lat = rad2deg(asin($sin_lat));

    #compute value of N0 at r=100km from albedo level
    my $rOneObjSqDeg = get_TNOrad_from_RAUa(23.3, 42, $albedo);
    my $test = TNO_Rmag($rOneObjSqDeg, 42, $albedo);
    my $N0 = (100000/$rOneObjSqDeg)**$q1;
    $rOneObjSqDeg = $rOneObjSqDeg/1000;

    #print STDOUT "rofOneObjSqDeg = $rOneObjSqDeg magnitude(test): $test N0: $N0\n";

    #compute location of rknee1 from albedo
    #this is known value from Fraser (2009): r = 30 +- 15km at albedo = 0.06 for KB
    my $r_knee1Mag = TNO_Rmag(30000, 40, 0.06); #this is known value from Fraser (2009)
    my $r_knee1 = get_TNOrad_from_RAUa($r_knee1Mag, 42, $albedo)/1000;

    #next, compute the y-axis offset of the size dist. func.
    my $E = 2.7182818284;

    my $k = log10($N0)-(log10($E)*($lat*$lat/200))-($q1*2);

    my $logrknee = log10($r_knee1) - $rkneeWidth;
    my $r_knee2 = 10**$logrknee;

    #print STDOUT "r_kneeMag: $r_knee1Mag rknee1: $r_knee1 rknee2: $r_knee2\n";

    # now calculate density assuming a size dist. func. with slope of Q1 before rknee1,
    # a slope of Q2 inbetween rknee1 and rknee2 and a slope of Q3 after rknee2
    if ($r_min >= $r_knee1) {
	my $log_N = $q1*log10($r_min) + $k;
	my $N_arcmin = (10**$log_N)/3600;
	my $N_arcsec = $N_arcmin/3600;
	return $N_arcsec;
    } elsif ($r_min < $r_knee1 && $r_min > $r_knee2) {
	my $log_N_1 = ($q1*log10($r_knee1)) + $k;
	my $dlogr = log10($r_min) - log10($r_knee1);
	my $log_N_2 = ($q2*$dlogr) + $log_N_1;
       	my $N_arcmin = (10**$log_N_2)/3600;
	my $N_arcsec = $N_arcmin/3600;
    } else {
	my $log_N_1 = ($q1*log10($r_knee1)) + $k;
	my $dlogr = log10($r_knee2) - log10($r_knee1);
	my $log_N_2 = ($q2*$dlogr) + $log_N_1;
	$dlogr = log10($r_min) - log10($r_knee2);
	my $log_N_3 = ($q3*$dlogr) + $log_N_2;
       	my $N_arcmin = (10**$log_N_3)/3600;
	my $N_arcsec = $N_arcmin/3600;
	return $N_arcsec;
    }
}
    
