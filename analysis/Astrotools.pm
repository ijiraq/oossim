#!/usr/bin/env perl
# Perl Module:  Astrotools.pm
#
# Purpose: a Perl module  containing subroutines useful for astronomy
#          calculations
# Author: Steve Bickerton, McMaster University
#         bick@physics.mcmaster.ca
#         Thurs. May 11, 2006
#         
# Update: Sat. June 24, 2006  (split mean2true into mean2ecc and ecc2true)
#
# Functions:   
#
# mean2true ($M,$e,$iter_tolerance,$max_iter): converts mean anomaly
#                of an eliptical orbit to angular displacement theta
# mean2ecc ($M, $e, $iter_tolerance, $max_iter): converts mean anomaly
#                of an elliptical orbit to eccentric anomaly
# ecc2true ($E, $e): converts eccentric anomaly to true anomaly.
#

package  Local::Astrotools;

use strict;
use warnings;
use Carp;

use Local::Constants;

use Math::Trig;

require  Exporter;

our @ISA       = qw( Exporter );
our @EXPORT    = qw( 
		     $JD2000
		     $degnum
		     $hmsnum
		     JCentury 
		     radiusEllipse
		     reduceAngle
		     mean2ecc
		     ecc2true
		     mean2true
		     JDsolsticeEquinox
		     ymd
		     hms
		     date
		     calendar2JD
		     JD2calendar
		     JD2epoch
		     epoch2JD
		     calendar2epoch
		     epoch2calendar
		     precess
		     separation
		     eclipticObliquity
		     sunGeoMeanLong
		     sunMeanAnom
		     sunEquationOfCenter
		     sunTrueLongitude
		     sunTrueLongJ2000
		     sunAppLongitude
		     sunTrueAnomaly
		     earthEccentricity
		     earthOrbitRadius
		     sunRAdec
		     sunAppRAdec
		     hms2deg
		     deg2hms
		     hms2degRADec
		     deg2hmsRADec
		     hms2degS
		     deg2hmsS
		     eq2gal
		     gal2eq
		     eq2ecl
		     ecl2eq
		     getDatesOfCoordsAtElong	
		     getLatsOfElongAtDate
		     getRADecOfElongAtDate
		     getElongOfCoordsAtDate
		     greenwichSidereal0hUT
		     greenwichSidereal
		     yearDay
		     eq2hA
		     hA2eq
		     mag2flux
		     magSum
		     fluxRatio
		     magDiff
		     Hmag2mv
		     mv2Hmag
		     mv2rad
		     Hmag2diam
		     fresnelScale
		     TNO_Rmag
		     get_TNOrad_from_RAUa
		     get_TNOAU_from_Rrada
			transition
		     earthRAFromDate
		     orbitalObsFraction
		     );
our @EXPORT_OK = qw();
our @EXPORT_TAGS = ( ALL => [ @EXPORT_OK ], );
our $VERSION   = 1.00;


##########################################################
# 
#   Prototypes
#
##########################################################
sub eclipticObliquity($);


sub log10 ($) {
    return log($_[0])/log(10.0);
}

sub JCentury ($) {
    my ($JD) = @_ or croak "usage: \$T = JCentury(\$JD)\n";
    return ($JD - $JD2000)/36525.0;
}

sub radiusEllipse($$) {
    my ($e, $w) = @_ or croak "usage: \$r = radiusEllipse(\$e,\$trueAnom);\n";
    my $r = (1.0 - $e**2.0) / ( 1.0 + $e*cos($w) );
    return $r;
}

sub reduceAngle($) {
    my ($angle) = @_ or croak "usage: \$angle = reduceAngle(\$angle);\n";
    $angle = $angle - int($angle/360.0)*360;
    $angle += 360.0 if $angle < 0;
    return $angle;
}






####################################################################
# 
#  7      7       7       7 
# 
###################################################################

sub ymd(@) {
    croak "usage: my \$string = ymd(\$Y, \$M, \$D);\n" unless $_[2];
    return sprintf "%04d-%02d-%02d", @_;
}

sub hms(@) {
    croak "usage: my \$string = hms(\$H, \$m, \$S);\n" unless defined($_[2]);
    return sprintf "%02d:%02d:%06.3f", @_;
}
sub date(@) {
    croak "usage: my \$string = ymd(\$Y, \$M, \$D, [\$H, \$m, \$S]);\n" 
	unless $_[2];
    my @ymd = @_[0,1,2];
    my @hms = ( defined($_[5]) ) ? @_[3,4,5] : (0,0,0);
    return sprintf "%s  %s", ymd(@ymd), hms(@hms);
}

# ------------------------------------------------------------------
# ------------------------------------------------------------------
sub calendar2JD (@) {

    my ($Y, $M, $D, $H, $min, $S) = @_;
    croak "usage calendar2JD(Y,M,D,[H],[min],[S])\n" unless ($D);

    $H = 0 unless $H;
    $min = 0 unless $min;
    $S = 0 unless $S;

    my $HpD = 24.0;
    my $minpD = $HpD*60.0;
    my $SpD = $minpD*60.0;

    if ( $M <= 2 ) {
	$Y -= 1;
	$M += 12;
    }

    my $A = int($Y/100);
    my $B =  2 - $A + int($A/4); 

    my ($y,$m,$d) = (1582, 10, 4);
    $B = 0 if ($Y<$y || 
	       ($Y==$y && $M<$m) || 
	       ($Y==$y && $M==$m && $D<=4));

    my $JD = int(365.25*($Y+4716)) + int(30.6001*($M+1)) + $D + $B - 1524.5;
    $JD += $H / $HpD + $min / $minpD + $S / $SpD;

    return $JD;

}




# ------------------------------------------------------------------
# ------------------------------------------------------------------
sub JD2calendar ($) {

    my ($JD) = @_ or croak "usage: JD2calendar(JD)\n";

    $JD += 0.5;
    my $Z = int ($JD);     # integer part
    my $F = $JD - $Z;      # decimal part

    my $alpha = int( ($Z - 1867216.25)/36524.25 );
    my $A = ( $Z < 2299161 ) ? $Z : $Z + 1 + $alpha - int($alpha/4);

    my $B = $A + 1524;
    my $C = int( ($B - 122.1)/365.25 );
    my $D = int( 365.25*$C );
    my $E = int( ($B-$D)/30.6001 );

    my $mday  = $B - $D - int(30.6001*$E) + $F;
    my $mon   = ($E < 14) ? ($E-1) : ($E-13);
    my $year  = ($mon > 2)  ? ($C-4716) : ($C-4715);

    my $hour = 24.0*$F;
    my $H = int($hour);
    my $min = ($hour - $H)*60.0;
    my $Min = int($min);
    my $s = ($min - $Min)*60.0;


    return ($year, $mon, $mday, $H, $Min, $s);

}


# ------------------------------------------------------------------
# ------------------------------------------------------------------
sub JD2epoch ($) {
    my ($JD) = @_ or croak "usage: \$epoch = JD2epoch(\$JD);\n";
    my $epoch = 2000 + ($JD - $JD2000)/365.25;
    return $epoch;
}



# ------------------------------------------------------------------
# ------------------------------------------------------------------
sub epoch2JD ($) {
    my ($epoch) = @_ or croak "usage: \$JD = epoch2JD(\$epoch);\n";
    my $JD = $JD2000 + ($epoch - 2000.0)*365.25;
    return $JD;
}




# ------------------------------------------------------------------
# ------------------------------------------------------------------
sub calendar2epoch(@) {

    my ($Y, $M, $D, $H, $min, $S) = @_;
    croak "usage: calendar2epoch(Y,M,D,[h],[m],[s]);\n" unless $D;
    
    $H = 0 unless $H;
    $min = 0 unless $min;
    $S = 0 unless $S;

    my $JD = calendar2JD($Y,$M,$D, $H,$min,$S);

    my $epoch = 2000.0 + 100.0*JCentury($JD);

}


# ------------------------------------------------------------------
# ------------------------------------------------------------------
sub epoch2calendar ($) {
    my ($epoch) = @_;
    my $jd = ($epoch - 2000.0) * 365.25;
    my $JD = $JD2000 + $jd;
    my ($Y, $M, $D, $H, $min, $S) = JD2calendar($JD);
    return ($Y, $M, $D, $H, $min, $S);
}


# ----------------------------------------------------------------
# ----------------------------------------------------------------
sub yearDay($$$) {
    my ($Y, $M, $D) = @_;
    croak "usage: \$yday = yearDay(\$year,\$month,\$day);\n" 
	unless defined($D);

    my $is_leap = (! ($Y % 4) && ($Y % 400) ) ? 1 : 0;
    my $K = ($is_leap) ? 1 : 2;
    my $yday = int(275.0*$M/9.0) - $K*int( ($M+9.0)/12.0 ) + $D - 30;
    return $yday;
}



####################################################################
# 
#  12      12       12       12 
# 
###################################################################
sub greenwichSidereal0hUT ($) {
    my ($JD) = @_;

    my ($Y, $M, $D, $H, $m, $S) = JD2calendar($JD);
    my $JDmidnight = calendar2JD($Y, $M, $D, 0, 0, 0);
    my $T = JCentury($JDmidnight);
    my $theta0 = 100.460_618_37 + 36_000.770_053_608*$T +
	0.000_387_933*$T**2 - $T**3/38_710_000;
    return reduceAngle($theta0);
}


sub greenwichSidereal ($) {
    my ($JD) = @_;
    my $T = JCentury($JD);
    my $theta0 = 280.460_618_37 + 360.985_647_366_29*($JD-$JD2000) +
	0.000_387_933*$T**2 - $T**3/38_710_000;
    return reduceAngle($theta0);
}



####################################################################
# 
#  13      13       13       13 
# 
###################################################################
# actually from Binney and Merrifield p 81

my $degnum = '[+-]?\d+\.?\d*';
my $hmsnum = '[+-]?\d{1,3}:\d\d:\d\d\.?\d*';

my ($alpha_GP, $delta_GP) = (192.85948, 27.12825);
my ($l_CP, $b_CP)         = (123.932, 27.12825);

my $eclipticObliquity2000 = eclipticObliquity($JD2000);
my ($alpha_EP, $delta_EP) = (270.0,  90.0 - $eclipticObliquity2000);
my ($lambda_CP, $beta_CP) = (90.0, 90.0 - $eclipticObliquity2000);

sub degnum () { return $degnum; }
sub hmsnum () { return $hmsnum; }

# ---------------------------------------------------------------------
# ---------------------------------------------------------------------
sub deg2hms ($) {

    my ($radec) = @_;
    croak "usage: (\$H,\$M,\$S) = deg2hms(\$radec);\n" unless $radec;
    my $sign = ($radec>=0) ? 1 : (-1);
    $radec = abs($radec);

    my $hour = int $radec;
    my $min = int (($radec - $hour)*60);
    my $sec = ( ($radec - $hour)*60 - $min )*60;
	
    return ( $sign*$hour,$min,$sec);
}   

# ---------------------------------------------------------------------
# ---------------------------------------------------------------------
sub deg2hmsS ($) {

    my ($radec) = @_;
    croak "usage: \$hmsS = deg2hmsS(\$radec);\n" unless $radec;

    my $sign = ($radec>=0) ? 1 : (-1);
    $radec = abs($radec);
	
    my $hour = int $radec;
    my $min = int (($radec - $hour)*60);
    my $sec = ( ($radec - $hour)*60 - $min )*60;

    # now make sure rounding won't give 60.000 for sec or min
    my $signS = ($sign >= 0) ? "" : "-";
    my $secS = sprintf "%06.3f", $sec;
    if ($secS >= 60.000) {
	$secS = "00.000";
	$min += 1;
	if ($min == 60) {
	    $min = 0;
	    $hour += 1;
	    if ($hour == 360) {
		$hour = 0;
	    }
	}
    }
    
    my $hmsS = sprintf "%s%02d:%02d:%s", $signS, $hour,$min, $secS;
    return $hmsS;
}   


# ---------------------------------------------------------------------
# ---------------------------------------------------------------------
sub hms2degS ($) {

    my ($radec) = @_;
    my ($hour,$min,$sec) = split /:/,$radec;
    croak "usage: \$deg = hms2degS(\$hms);\n" unless defined $sec;

    my $sign = ($hour>=0) ? 1 : (-1);
    $hour = abs($hour);
	
    my $deg = $sign*($hour + $min/60.0 + $sec/3600.0);
    return $deg;
}


# ---------------------------------------------------------------------
# ---------------------------------------------------------------------
sub hms2deg ($$$) {

    my ($hour,$min,$sec) = @_;
    croak "usage: \$deg = hms2deg(\$hr,\$min,\$sec);\n" unless defined $sec;
	
    my $sign = ($hour>=0) ? 1 : (-1);
    $hour = abs($hour);
	
    my $deg = $sign*($hour + $min/60.0 + $sec/3600.0);
    return $deg;
}

# ---------------------------------------------------------------------
# ---------------------------------------------------------------------
sub hms2degRADec ($$) {
    my ($alphaH, $deltaH) = @_;
    my $alphaD = 15.0*hms2degS($alphaH);
    my $deltaD = hms2degS($deltaH);
    return ($alphaD, $deltaD);
}

# ---------------------------------------------------------------------
# ---------------------------------------------------------------------
sub deg2hmsRADec ($$) {
    my ($alphaD, $deltaD) = @_;
    my $alphaH = deg2hmsS($alphaD/15.0);
    my $deltaH = deg2hmsS($deltaD);
    return ($alphaH, $deltaH);
}



######################################################################
# gal2cel, cel2gal, ecl2cel, cel2ecl
#
# The are just front-end subroutines for transform().  They run transform()
#   with the appropriate poles for the desired transformation.
# 
#######################################################################
sub gal2eq ($$) {
    my ($l, $b) = @_;
    croak "function gal2eq() not yet implemented\n";


}

sub eq2gal ($$) {
    my ($alpha, $delta) = @_;
    
    croak "function eq2gal() not yet implemented\n";
}

sub ecl2eq ($$$) {
    my ($lambda, $beta, $JD) = @_;
 
    croak "usage: \$epsilon = ecl2eq(\$lambda, \$beta, \$JD);\n" unless $JD;
    
    my $epsilon = $RAD * eclipticObliquity($JD);
    $lambda *= $RAD;
    $beta *= $RAD;

    my $numerator = sin($lambda)*cos($epsilon) - tan($beta)*sin($epsilon);
    my $denominator = cos($lambda);

    my $alpha = atan2 ($numerator, $denominator);
    my $delta = asin( sin($beta)*cos($epsilon)+cos($beta)*sin($epsilon)*sin($lambda) );

    return ($DEG*$alpha, $DEG*$delta);
}

sub eq2ecl ($$$) {
    my ($alpha, $delta, $JD) = @_;

    croak "usage: \$epsilon = eq2ecl(\$alpha, \$delta, \$JD);\n" unless $JD;

    my $epsilon = $RAD * eclipticObliquity($JD);
    $alpha *= $RAD;
    $delta *= $RAD;

    my $numerator = sin($alpha)*cos($epsilon) + tan($delta)*sin($epsilon);
    my $denominator = cos($alpha);

    my $lambda = atan2 ($numerator, $denominator);
    my $beta = asin( sin($delta)*cos($epsilon) - cos($delta)*sin($epsilon)*sin($alpha) );

    return ($DEG*$lambda, $DEG*$beta);

}


# -------------------------------------------------------------
sub eq2hA ($$$$$) {
    my ($alpha, $delta, $L, $psi, $JD) = @_;
    croak "usage: (\$h, \$A) = eq2AA(\$alpha \$delta, \$long, \$lat, \$JD);\n" 
	unless $JD;

    my $theta0 = greenwichSidereal($JD);
    my $H = $theta0 - $L - $alpha;
    
    # convert angles to radians
    ($alpha, $delta, $L, $psi, $theta0, $H) = 
	map {$RAD*$_} ($alpha, $delta, $L, $psi, $theta0, $H);

    # note that azimuth A is measured from the _South_
    my $A = atan2( sin($H), (cos($H)*sin($psi) - tan($delta)*cos($psi)) );
    my $h = asin( sin($psi)*sin($delta) + cos($psi)*cos($delta)*cos($H) );

    ($h, $A) = map {$DEG*$_} ($h, $A);
    $A = reduceAngle($A);
    return ($h, $A);
}

# -------------------------------------------------------------
sub hA2eq ($$$$$) {
    my ($h, $A, $L, $psi, $JD) = @_;
    croak "usage: (\$h, \$A) = eq2AA(\$alpha \$delta, \$long, \$lat, \$JD);\n" 
	unless $JD;

    # convert angles to radians
    ($h, $A, $psi) = map {$RAD*$_}  ($h, $A, $psi);

    # note that azimuth A is measured from the _South_
    my $H = $DEG * atan2( sin($A), (cos($A)*sin($psi) + tan($h)*cos($psi)) );
    my $delta = $DEG * asin( sin($psi)*sin($h) - cos($psi)*cos($h)*cos($A) );

    my $theta0 = greenwichSidereal($JD);
    (my $alpha, $delta) = ( ($theta0 - $L - reduceAngle($H) ) , $delta);

    return (reduceAngle($alpha), $delta);
}








####################################################################
# 
#  17      17       17       17 
# 
###################################################################

# -------------------------------------------------------
# function: separation
# Purpose: calculate the angular separation between two points in RA and Dec
# Req'd Parameters: 
# Source: Astronomical Algorithms (Jean Meeus) pp 
# Limitation: 
#-----------------------------------------------
sub separation ($$$$) {
    my ($RA1, $Dec1, $RA2, $Dec2) = @_  or 
	croak "usage: \$d = separation(\$RA1,\$Dec1,\$RA2,\$Dec2)\n";
    croak "Function separation() not yet implemented\n";
}




####################################################################
# 
#  21      21       21       21 
# 
###################################################################

# -------------------------------------------------------
# function: precessJ2000
# Purpose: precess coordinates from J2000 to given epoch.
# Req'd Parameters: $alpha (RA), $delta (Dec), $epoch (year)
# Source: Astronomical Algorithms (Jean Meeus) pp 134 (rigorous method)
# Limitation: 
#-----------------------------------------------
sub precess ($$$$) {
    my ($alpha0, $delta0, $JD0, $JD) = @_  or 
	croak "usage: (\$alpha, \$delta) = precess(\$alpha0,\$delta0,\$JD0,\$JD)\n";

    my $T = ($JD0 - $JD2000) / 36525.0;
    my $t =     ($JD - $JD0) / 36525.0;

    my $xi = (2306.2181 + 1.39656*$T - 0.000139*$T**2)*$t + 
	(0.30188 - 0.000344*$T)*$t**2 + 0.017998*$t**3;
    my $z = (2306.2181 + 1.39656*$T - 0.000139*$T**2)*$t + 
	(1.09468 + 0.000066*$T)*$t**2 + 0.018203*$t**3;
    my $theta = (2004.3109 - 0.85330*$T - 0.000217*$T**2)*$t -
	(0.42665 + 0.000217*$T)*$t**2 - 0.041833*$t**3;

    ($alpha0, $delta0) = map {$RAD * $_} ($alpha0, $delta0);
    ($xi, $z, $theta)  = map {$_ / $ASperRAD} ($xi, $z, $theta);


    my $A = cos($delta0) * sin($alpha0 + $xi);
    my $B = cos($theta)*cos($delta0)*cos($alpha0 + $xi) - 
	sin($theta)*sin($delta0);
    my $C = sin($theta)*cos($delta0)*cos($alpha0 + $xi) + 
	cos($theta)*sin($delta0);

    my $alpha = reduceAngle($DEG * ( atan2($A,$B) + $z));
    my $delta = $DEG * asin($C);

    return ($alpha, $delta);
}







####################################################################
# 
#  22      22       22       22 
# 
###################################################################

# -------------------------------------------------------
# function: eclipticObliquity
# Purpose: calculate the obliquity of the ecliptic 
# Req'd Parameters: JD
# Source: Astronomical Algorithms (Jean Meeus) pp 
# Limitation: 
#-----------------------------------------------
sub eclipticObliquity ($) {

    my ($JD) = @_  or croak "usage: \$epsilon0 = eclipticObliquity(\$JD);\n";

    my $T = JCentury($JD);
    my $U = $T / 100.0;

    my $correction = - 4680.93 * $U
	-    1.55 * $U**2
	+ 1999.25 * $U**3
	-   51.38 * $U**4
	-  249.67 * $U**5
	-   39.05 * $U**6
	+    7.12 * $U**7
	+   27.87 * $U**8
	+    5.79 * $U**9
	+    2.45 * $U**10;
    
    my $epsilon0 = 23.0 + 26.0/60.0 + (21.488 + $correction)/3600.0;
    
    return $epsilon0;
}








####################################################################
# 
#  25      25       25       25 
# 
###################################################################

# -------------------------------------------------------
# functions:  solar coordinates
# Purpose: several routines to calculate coords of the sun
# Req'd Parameters: 
# Source: Astronomical Algorithms (Jean Meeus) pp 163
# Limitation: 
#-----------------------------------------------

# --------------------------------------------------------------------
# --------------------------------------------------------------------
sub sunGeoMeanLong ($) {
    my ($JD) = @_ or croak "usage: \$L0 = sunGeoMeanLong(\$JD)\n";
    my $T = JCentury($JD);
    my $L0 = 280.46646 + 36000.76983*$T + 0.0003032*$T**2.0;
    return reduceAngle($L0);
}



# --------------------------------------------------------------------
# --------------------------------------------------------------------
sub sunMeanAnom ($) {
    my ($JD) = @_ or croak "usage: \$M = sunMeanAnom(\$JD)\n";
    my $T = JCentury($JD);
    my $M = 357.52911 + 35999.05029*$T + 0.0001537*$T**2.0;
    return reduceAngle($M);
}


# --------------------------------------------------------------------
# --------------------------------------------------------------------
sub sunEquationOfCenter ($) {
    my ($JD) = @_ or croak "usage: \$C = sunEquationOfCenter(\$JD)\n";
    my $M = sunMeanAnom ($JD);
    my $T = JCentury($JD);
    my $C = (1.914602 - 0.004817*$T - 0.000014*$T**2.0 )*sin($RAD*$M)
	+ ( 0.019993 - 0.000101*$T )*sin($RAD*2.0*$M) 
	+  0.000289*sin($RAD*3.0*$M);
    return reduceAngle($C);
}


# --------------------------------------------------------------------
# --------------------------------------------------------------------
sub sunTrueLongitude($) {
    my ($JD) = @_ or croak "usage: \$trueLong = sunTrueLongitude(\$JD);\n";
    my $L0 = sunGeoMeanLong($JD);
    my $C  = sunEquationOfCenter($JD);
    return reduceAngle($L0 + $C);
}


# --------------------------------------------------------------------
# --------------------------------------------------------------------
sub sunTrueLongJ2000($) {
    my ($JD) = @_ or croak "usage: \$trueLongJ2000 = sunTrueLongJ2000(\$JD);\n";
    my $epoch = JD2epoch($JD);
    my $trueLong = sunTrueLongitude($JD);
    my $trueLongJ2000 = $trueLong - 0.01397*($epoch - 2000.0);
    return reduceAngle($trueLongJ2000);
}


# --------------------------------------------------------------------
# --------------------------------------------------------------------
sub sunAppLongitude ($) {
    my ($JD) = @_ or croak "usage: \$lambda = sunApptLongitude(\$JD);\n";
    my $T = JCentury($JD);
    my $trueLong = sunTrueLongitude($JD);
    my $Omega = 125.04 - 1934.136*$T;
    my $lambda = $trueLong - 0.00569 - 0.00478*sin($RAD*$Omega);
    return reduceAngle($lambda);
}


# --------------------------------------------------------------------
# --------------------------------------------------------------------
sub sunTrueAnomaly($) {
    my ($JD) = @_ or croak "usage: \$v = sunTrueAnomaly(\$JD);\n";
    my $M = sunMeanAnom($JD);
    my $C = sunEquationOfCenter($JD);
    return reduceAngle($M + $C);
}

# --------------------------------------------------------------------
# --------------------------------------------------------------------
sub earthEccentricity ($) {
    my ($JD) = @_ or croak "usage: \$e = earthEccentricity(\$JD)\n";
    my $T = JCentury($JD);
    my $e = 0.016708634 - 0.000042037*$T - 0.0000001267*$T**2.0;
    return $e;
}
    

# --------------------------------------------------------------------
# --------------------------------------------------------------------
sub earthOrbitRadius ($) {
    my ($JD) = @_ or croak "usage: \$R = earthOrbitRadius(\$JD)\n";
    my $e = earthEccentricity($JD);
    my $C = sunEquationOfCenter($JD);
    my $M = sunMeanAnom($JD);
    my $w = $M + $C;   # true anomaly
    return 1.000001018*radiusEllipse($e, $RAD*$w);
}

# --------------------------------------------------------------------
# --------------------------------------------------------------------
sub sunRAdec($) {
    my ($JD) = @_  or croak "use: (\$alpha,\$delta) = sunRAdec(\$JD)\n";
    my $trueLongJ2000 = $RAD * sunTrueLongJ2000($JD);
    my $epsilon0      = $RAD * eclipticObliquity($JD);
    my $alpha = atan2(cos($epsilon0)*sin($trueLongJ2000), cos($trueLongJ2000));
    my $delta = asin( sin($epsilon0)*sin($trueLongJ2000) );
    return ( reduceAngle($DEG*$alpha), $DEG*$delta );
}


# --------------------------------------------------------------------
# --------------------------------------------------------------------
sub sunAppRAdec ($) {
    my ($JD) = @_  or croak "use: (\$alpha,\$delta) = sunRAdec(\$JD)\n";
    my $lambda = $RAD * sunAppLongitude($JD);
    my $T = JCentury($JD);
    my $Omega = $RAD* (125.04 - 1934.136*$T);
    my $epsilon0 = eclipticObliquity($JD);
    my $epsilon = $RAD * ( $epsilon0 + 0.00256*cos($Omega) );
    my $alpha = atan2(cos($epsilon)*sin($lambda), cos($lambda));
    my $delta = asin( sin($epsilon)*sin($lambda) );
    return ( reduceAngle($DEG*$alpha), $DEG*$delta );
}







####################################################################
# 
#  27      27       27       27 
# 
###################################################################
# -------------------------------------------------------
# function: JDsolsticeEquinox
# Purpose: Get the Julian Day of the solstices and equinoxes
# Req'd Parameters: $year
# Source: Astronomical Algorithms (Jean Meeus) pp 177 (Approx method)
# Limitation: 
#-----------------------------------------------
my @ABC = ( 
	    [ 485, 324.96, 1934.136   ],
	    [ 203, 337.23, 32964.467  ],
	    [ 199, 342.08, 20.186     ],  
	    [ 182, 27.85,  445267.112 ],	
	    [ 156, 73.14,  45036.886  ],	
	    [ 136, 171.52, 22518.443  ],	
	    [ 77,  222.54, 65928.934  ],	
	    [ 74,  296.72, 3034.906   ],	
	    [ 70,  243.58, 9037.513   ],	
	    [ 58,  119.81, 33718.147  ],	
	    [ 52,  297.17, 150.678    ], 	
	    [ 50,  21.02,  2281.226   ],	
	    [ 45,  247.54, 29929.562  ],	
	    [ 44,  325.15, 31555.956  ],	
	    [ 29,  60.93,  4443.417   ],
	    [ 18,  155.12, 67555.328  ],	
	    [ 17,  288.79, 4562.452   ],	
	    [ 16,  198.04, 62894.029  ],	
	    [ 14,  199.76, 31436.921  ],	
	    [ 12,  95.39,  14577.848  ],	
	    [ 12,  287.11, 31931.756  ], 	
	    [ 12,  320.81, 34777.259  ],	
	    [ 9,   227.73, 1222.114   ],	
	    [ 8,   15.45,  16859.073  ] 	    
	    );


sub JDsolsticeEquinox ($$) {
    
    my ($year, $season) = @_  or croak "usage: \$JD = JDsolsticeEquinox(\$year,\$season [0123])\n";

    my $Y;
    my ($y0, $y1, $y2, $y3, $y4);
    if ( $year<1000 ) {

	$Y = $year / 1000.0;

	if ( $season == 1 ) {
	    ($y0, $y1, $y2, $y3, $y4) = 
		(1721139.29189, 365242.13740, 0.06134, 0.00111, -0.00071);
	} elsif ($season == 2) {
	    ($y0, $y1, $y2, $y3, $y4) = 
		(1721233.25401, 365241.72562, -0.05323, 0.00907, 0.00025);
	} elsif ($season == 3) {
	    ($y0, $y1, $y2, $y3, $y4) = 
		(1721325.70455, 365242.49558, -0.11677, -0.00297, 0.00074);
	} elsif ($season == 4) {
	    ($y0, $y1, $y2, $y3, $y4) = 
		(1721414.39987, 365242.88257, -0.00769, -0.00933, 0.00006);
	} else {
	    warn "Season: 1 (spring), 2 (summer), etc JDaries() returning 0\n";
	    return 0;
	}

    } else {

	$Y = ( $year - 2000.0 ) / 1000.0;

	if ( $season == 1 ) {
	    ($y0, $y1, $y2, $y3, $y4) = 
		(2451623.80984, 365242.37404, 0.05169, -0.00411, -0.00057);
	} elsif ($season == 2) {
	    ($y0, $y1, $y2, $y3, $y4) = 
		(2451716.56767, 365241.62603, 0.00325, 0.00888, -0.00030);
	} elsif ($season == 3) {
	    ($y0, $y1, $y2, $y3, $y4) = 
		(2451810.21715, 365242.01767, -0.11575, 0.00337, 0.00078);
	} elsif ($season == 4) {
	    ($y0, $y1, $y2, $y3, $y4) = 
		(2451900.05952, 365242.74049, -0.06223, -0.00823, 0.00032);
	} else {
	    warn "Season: 1 (spring), 2 (summer), etc JDaries() returning 0\n";
	    return 0;
	}

    }

    my $JDE0 = $y0 + $y1*$Y + $y2*$Y**2 + $y3*$Y**3 + $y4*$Y**4;

    my $T = JCentury($JDE0);

    my $W = 35999.373*$T - 2.47;   # degrees
    my $Dl = 1.0 + 0.0334*cos($PI*$W/180.0) + 0.0007*cos(2.0*$PI*$W/180.0);

    my $S = 0;
    foreach my $ABC (@ABC) {
	my ($A, $B, $C) = @$ABC;
	my $arg = ($PI/180.0) * ($B + $C*$T);
	$S += $A*cos($arg);
    }

    my $JDE = $JDE0 + 0.00001*$S/$Dl;

    return $JDE;

}







####################################################################
# 
#  30      30       30       30 
# 
###################################################################

# -------------------------------------------------------
# function: mean2ecc
# Purpose: To convert the mean anomaly $M of an orbit
#          to the eccentric anomaly E
# Req'd Parameters: $M, mean anomaly (from 0 - 2pi)
#                   $e, eccentricity
# Limitation: The problem cannot be solved analytically and is therefore
#             limited to the accuracy defined by $iter_tolerance
#-----------------------------------------------
sub mean2ecc ($$) {

    my ($M, $e) = @_;

    my $iter_tolerance = 1.0e-12;   # error in E in rads
    my $error = 2*$iter_tolerance;   # initial error value
    my $max_iter = 20;

    # the following iteration uses newton's method.
    # The function is defined as $f, with its derivative $fp (f-prime)
    my $i = 0;
    my $E = $M + $e*sin( $M + $e*sin($M) );  #  initial guess (see Meeus)
    while ( ($error**2 > $iter_tolerance**2) && ($i < $max_iter) ) {

        my $f = $E - $e*sin($E) - $M;
        my $fp = 1.0 - $e*cos($E);
        my $Enew = $E - $f/$fp;
        $error = $Enew - $E;
        $E = $Enew;
        $i++;
    }

    croak  "Error: mean2ecc() did not converge in $max_iter iterations\n" 
	if ($i==$max_iter);

    return $E;
}



# -------------------------------------------------------
# function: ecc2true
# Purpose: To convert the eccentric anomaly $E of an orbit
#          to the angular position $w (true anomaly)
# Req'd Parameters: $E, Eccentric anomaly (from 0 - 2pi)
#                   $e, eccentricity
# Limitation: none known
#-----------------------------------------------
sub ecc2true ($$) {
    my ($E, $e) = @_;
    my $w = 2*atan2( sqrt( (1+$e)/(1-$e) )*sin($E/2)/cos($E/2), 1);
    # atan2 returns from -pi -> pi, this changes that to be 0 -> pi
    $w += $TWOPI if ($w < 0);
    return $w;
}



# -------------------------------------------------------
# function: mean2true
# Purpose: To convert the mean anomaly $M of an orbit
#          to the angular position $w (true anomaly)
# Req'd Parameters: $M, mean anomaly (from 0 - 2pi)
#                   $e, eccentricity
#-----------------------------------------------
sub mean2true ($$$$) {
    my ($M, $e) = @_;
    my $E = mean2ecc($M, $e);
    my $w = ecc2true($E, $e);
    return $w;
}






####################################################################
# 
#  56      56       56       56 
# 
###################################################################

# -------------------------------------------------------
# function: magSum
# Purpose: Get the combined magnitude of several magnitudes
# Req'd Parameters: @mags
# Limitation: 
#-----------------------------------------------
sub magSum (@) {
    
    my $sum = 0;
    foreach my $mag (@_) { $sum += 10.0**(-0.4*$mag); }
    return -2.5*log10($sum);

}


# -------------------------------------------------------
# function: fluxRatio
# Purpose: Get the flux ratio for two magnitudes
# Req'd Parameters: $mag1 $mag2
# Limitation: 
#-----------------------------------------------
sub fluxRatio ($$) {
    
    my ($mag1, $mag2) = @_;
    return 10.0**(0.4*($mag2 - $mag1));

}

# -------------------------------------------------------
# function: magdiff
# Purpose: Get the mag difference for a flux ratio
# Req'd Parameters: $flux1 $flux2
# Limitation: 
#-----------------------------------------------
sub magDiff ($$) {
    
    my ($flux1, $flux2) = @_;
    return log10($flux1/$flux2)/0.4;

}




#------------------------------------------------------------------
#------------------------------------------------------------------
#------------------------------------------------------------------
#----   My own code                                         -------
#------------------------------------------------------------------
#------------------------------------------------------------------
#------------------------------------------------------------------



#------------------------------------------------------------------
# function: getElongOfCoordsAtDate()
# Purpose: Get the solar elongation of a coordinate at a given date
# Req'd parameters: alpha, delta -  Right ascension, declination
#                   JD - the Julian day
#------------------------------------------------------------------
sub getElongOfCoordsAtDate ($$$) {

    my ($alpha0, $delta0, $JD) = @_;

    # get the equitorial coords of the sun (J2000)
    my $lambdaSun = sunTrueLongitude($JD);

    # precess the coordinates to the requested epoch
    my ($alpha, $delta) = precess($alpha0, $delta0, $JD2000, $JD);
    
    # get the ecliptic J2000 coords of the target.
    my ($lambda, $beta) = eq2ecl($alpha, $delta, $JD);

    # take the difference of the ecliptic latitudes
    my $elong = $lambdaSun - $lambda;
    
    $elong = reduceAngle ($elong);
    return $elong;
}




#------------------------------------------------------------------
# function: getDatesOfCoordsAtElong()
# Purpose: Get the dates that a coordinate is at a given solar elongation
# Req'd parameters: alpha, delta -  Right ascension, declination
#                   elong - solar elongation [degrees]
#------------------------------------------------------------------
sub getDatesOfCoordsAtElong ($$$$) {

    my ($alpha0, $delta0, $elong1, $year) = @_;
    my $elong2 = 360.0 - $elong1;
    my @elong = ($elong1, $elong2);

    # get approximate (unprecessed) ecliptic coords
    my ($lambda, $beta) = eq2ecl($alpha0, $delta0, $JD2000);
    
    # get approx JDs by assuming mean-motion for Earth with J2000 coords
    my $angle1fromJan1 = reduceAngle($lambda + $elong1 + 90.0);
    my $JD1 = $JD2000 + 
	( $year - 2000.0 + ($angle1fromJan1)/360.0)*365.25;
    my $angle2fromJan1 = reduceAngle($lambda + $elong2 + 90.0);
    my $JD2 = $JD2000 + 
	( $year - 2000.0 + ($angle2fromJan1)/360.0)*365.25;
    my @JD = ($JD1, $JD2);

    # get the dates that these elongations occur on using Newton's method
    my $JDtolerance = 0.001;
    my ($i, $i_max) = (0, 100);
    my $dJD = 0.00001;

    foreach my $j (0 .. 1) {

	# assign the starting points
	my $elong = $elong[$j];
	my $JD = $JD[$j];
	my $JDlast = $JD + 2.0*$JDtolerance;
	my $e = $elong + 2.0*$JDtolerance;

	while ( abs($JD - $JDlast) > $JDtolerance ) {
		
	    my $JDp = $JD + $dJD;
	    my $e = getElongOfCoordsAtDate($alpha0, $delta0, $JD);
	    my $ep = getElongOfCoordsAtDate($alpha0, $delta0, $JDp);
	    my $de_dJD = ($ep - $e) / $dJD;	    
	    my $delta_e = ($e - $elong);
	    
	    $JDlast = $JD;
	    $JD -= $delta_e/$de_dJD;

	    $i++;
	    
	    croak "Did not converge after $i iterations.  Exiting." 
		if $i > $i_max;
	    
	}
	$JD[$j] = $JD;
    }

    return (@JD) ? @JD : 0;
}




#------------------------------------------------------------------
# function: getLatsOfElongAtDate()
# Purpose: Get the RA and Dec of an ecliptic solar elongation for a given date
# Req'd parameters: elong - the solar elongation [degrees]
#                   JD - the Julian day
#------------------------------------------------------------------
sub getLatsOfElongAtDate ($$) {

    my ($elong, $JD) = @_;

    # get the ecliptic coords of the sun (J2000)
    my $lambdaSun = sunTrueLongJ2000($JD);

    # get the possible ecliptic latitudes
    my $lambda1 = abs($lambdaSun - $elong);
    my $lambda2 = $lambdaSun + $elong;
    $lambda2 -= 360.0 if $lambda2 > 360.0;

    return ($lambda1, $lambda2);
}


#------------------------------------------------------------------
# function: getRADecOfElongAtDate()
# Purpose: Get the RA and Dec of an ecliptic solar elongation for a given date
# Req'd parameters: elong - the solar elongation [degrees]
#                   JD - the Julian day
#------------------------------------------------------------------
sub getRADecOfElongAtDate ($$) {

    my ($elong, $JD) = @_;

    # get the ecliptic latitude
    my ($lambda1, $lambda2) = getLatsOfElongAtDate($elong, $JD);

    my ($alpha1, $delta1) = ecl2eq($lambda1, 0.0, $JD);
    my ($alpha2, $delta2) = ecl2eq($lambda2, 0.0, $JD);

    $alpha1 = reduceAngle($alpha1);
    $alpha2 = reduceAngle($alpha2);

    return ($alpha1, $delta1, $alpha2, $delta2);
}





#------------------------------------------------------------------
# function: mag2flux()
# Purpose: Get the flux from a star given its magnitude
# Req'd parameters: filter = photometric filter
#                   magnitude = self-expl.
#------------------------------------------------------------------
sub mag2flux ($$) {

    my ($filter, $mag) = @_;
    croak "usage \$flux = mag2flux(\$filter, \$mag);\n" unless defined $mag;

    # get the flux
    # http://www.astro.utoronto.ca/~patton/astro/mags.html#flux
    # Band lambda_c  dlambda/lambda   Flux at m=0   Reference
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
    
    my %filter_specs = (
			U => [0.36, 0.15, 1810], 
			B => [0.44, 0.22, 4260], 
			V => [0.55, 0.16, 3640], 
			R => [0.64, 0.23, 3080], 
			I => [0.79, 0.19, 2550], 
			J => [1.26, 0.16, 1600], 
			H => [1.60, 0.23, 1080], 
			K => [2.22, 0.23,  670], 
			g => [0.52, 0.14, 3730], 
			r => [0.67, 0.14, 4490], 
			i => [0.79, 0.16, 4760], 
			z => [0.91, 0.13, 4810]  
			);

    croak "Filter $filter not in database.\n" unless $filter_specs{$filter};

    # variable names  $mag_flux_Jy  '_Jy'   --> mag_flux is *in* Janskys
    #                 $photon_Flux_per_Jy   --> rate *per* Jansky
    my ($lambda, $dlambdaOverLambda, $mag0_flux_Jy) = 
	@{$filter_specs{$filter}};

    my $mag_flux_Jy = $mag0_flux_Jy * 10**(-0.4*$mag);

    my $photonFlux_per_Jy = 1.51e7 * ($dlambdaOverLambda);

    my $mag_flux_phot = $mag_flux_Jy * $photonFlux_per_Jy;

    return $mag_flux_phot; # photons per s per m^2
}



# see dePater and Lissauer pg373
sub Hmag2mv ($$$) {

    my ($H, $r0, $re) = @_;  # both r values in AU
    my $xi = 4.0;

    return $H + 2.5*$xi*log10($r0) + 5.0*log10($re);	
}


# inverted Hmag2mv from dePater pg373
sub mv2Hmag ($$$) {

    my ($mv, $r0, $re) = @_;  # r values in AU (r0=heliocentric,re=geocentric)
    my $xi = 4.0;

    return $mv - 2.5*$xi*log10($r0) - 5.0*log10($re);	
}


# see Bottke et al. 2005, Icarus 175, 111-140
sub Hmag2diam ($$) {
  my ($H, $p) = @_;  # p = geometric albedo
  return 1000.0*(1329.0/sqrt($p)) * 10.0**(-$H/5.0);
}


sub mv2rad ($$$$) {
  my ($mv, $r0, $re, $p) = @_; 
  my $H = mv2Hmag($mv, $r0, $re);
  return Hmag2diam($H,$p)/2.0;
}



# the fresnel scale
sub fresnelScale($$) {
    my ($dist, $lamb) = @_;
    $dist *= $AU_M;
    my $fsu = sqrt($dist*$lamb/2.0);
    return $fsu;
}


# calculate the R magnitude of an object given radius, distance, albedo
# from Gladman et al 2001
sub TNO_Rmag($$$) {

  my ($rad, $AU, $albedo) = @_;   # m, AU, percent

  my $D = 2.0 * $rad / 1000.0;
  my $C = 18.8;
  
  # remove the assumed albedo=0.04 quantity
  my $C2 = $C + 2.5*log10(0.04);
  return $C2 + 2.5*log10($AU**4/($albedo*$D**2));

}


sub get_TNOrad_from_RAUa($$$) {

  my ($R, $AU, $albedo) = @_;

  # this is just the inverse of TNO_Rmag()
  my $C = 18.8 + 2.5*log10(0.04);
  return 1000.0*0.5*( ($albedo/$AU**4) * 10**( ($R-$C) / 2.5 ) )**(-0.5);

}

sub get_TNOAU_from_Rrada($$$) {
  
  my ($R, $rad, $albedo) = @_;
  # inverse of TNO_Rmag()
  my $C = 18.8 + 2.5*log10(0.04);
  return ($albedo*(2.0*$rad/1000.0)**2 * 10**(($R-$C)/2.5))**(0.25);

}

# get an interpolated point along x where x changes values 
# from ~const a  to ~const b at some point $x0 in a width $w
sub transition($$$$$) {
  my ($x, $a, $b, $x0, $w) = @_;
  return $a + (($b-$a)/($PI))*(atan2(($x-$x0)/$w,1.0) + $PIHALF);
}

sub earthRAFromDate($) {
    my ($JD) = @_;
    
    # get the equitorial coords of the sun (J2000)
    my $lambdaSun = sunTrueLongJ2000($JD);
    $lambdaSun = $lambdaSun;

    my $earthRA = $lambdaSun + 180.0;

    if ($earthRA > 360.0) {
	$earthRA -= 360.0;
    }
    return $earthRA;
        
}

sub orbitalObsFraction($$$$) {

    my ($RA, $Dec, $obsHeight, $obsDate) = @_;
    my $earthRA = earthRAFromDate($obsDate); #RA that crosses meridian at midnight
    my $theta = $RA-$earthRA; #angle between target and RA of opposition (described above)
    my $sinbeta = (cos(15*$PI/180.0)*sin($Dec*$PI/180.0))-
	(sin($RA*$PI/180.0)*cos($Dec*$PI/180.0)*sin(15*$PI/180.0));
    my $beta = asin($sinbeta); #declination in "satellite" coordinate system

    print STDERR "theta = $theta , beta = $beta\n";

    my $rmin1 = cos($theta*$PI/180.0)*(($Re_SI/1000)+($obsHeight));
    $rmin1 = abs($rmin1);
    my $rmin2 = cos($beta*$PI/180.0)*(($Re_SI/1000)+($obsHeight));
    $rmin2 = abs($rmin2);

    my $orbFraction1 = 0.5 + 0.5*($rmin1/($Re_SI/1000));
    $orbFraction1 = 1 unless ($orbFraction1 < 1);
    my $orbFraction2 = 0.5 + 0.5*($rmin2/($Re_SI/1000));
    $orbFraction2 = 1 unless ($orbFraction2 < 1);

    return ($orbFraction1*$orbFraction2);

}
