#!/usr/bin/env perl
# Perl Module:  Elong2v.pm
#
# Purpose: a Perl module  containing a subroutine to determine the velocity 
#          of a KBO at a given distance and elongation
# Author: Steve Bickerton, McMaster University
#         bick@physics.mcmaster.ca
#         Thurs. Sep. 22, 2005
# Functions:   elong2v and its inverse v2elong
#
#

package  Local::Elong2v;

use strict;
use warnings;
use Carp;
use Local::Constants;

use Math::Trig;

require  Exporter;

our @ISA       = qw( Exporter );
our @EXPORT    = qw( dvde elongi2v elong2v v2elong r2D );
our @EXPORT_OK = qw();
our @EXPORT_TAGS = ( ALL => [ @EXPORT_OK ], );
our $VERSION   = 1.00;


# constants
#my $PI       = 3.14159265358979;
#my $G_CGS    = 6.67259e-8;         # dyne cm^2 g^-2
#my $Mo_CGS   = 1.989e33;           # g
#my $AU_CGS   = 1.4960e13;          # cm
my $Ve = sqrt( $G_CGS*$Mo_CGS / $AU_CGS );


# see my notes p180
sub dvde ($$) {
    my ($elong, $r) = @_;

    my $alpha = $PI - $elong;
    my $sa = sin($alpha);
    my $ca = cos($alpha);

    # various steps in the chain rule 
    my $delta = $sa/$r;
    my $ddelta_de = -$ca/$r;

    my $beta = $delta;  # actually asin($delta) but delta = sin($beta);
    my $dbeta_de = (1.0 / (1.0 - $delta**2)) * $ddelta_de;

    my $dvde = 0.01*$Ve * ( (1/sqrt($r)) * sin($beta) * $dbeta_de + $sa);

    return $dvde;
}

# -------------------------------------------------------
#
# function: elongi2v
#
# Purpose: Given the distance, inclination, and elongation, 
#           returns the velocity of an object
#
# Req'd Parameters: AU     - the distance in AU
#                   i      - oribital inclination
#                   elong - the velocity of the object
#
# Limitation:
#
# Source:   My thesi, p 53.
#-----------------------------------------------

sub elongi2v ($$$) {

    my ($elong, $i, $rk) = @_;  # elong in radians
    croak "usage \$v = elongi2v(\$elong, \$i, \$rk);\n" unless $rk;


    # get the direction cosines of the line connecting the earth to kbo
    my $rkp = $rk * cos($i);
    my $elong_lim = ($rkp<1.0) ? asin($rkp) : 360.0;

    if ($elong > $elong_lim) {
	my $elongD = $DEG*$elong_lim;
	printf STDERR 
	    "Elongation cannot exceed %.2f deg at this inclination.  Returning 0\n", $elongD;
	return 0;
    }

    my $zk = $rk * sin($i);
    my $dp = r2D($rkp, $elong);
    my $d = sqrt($dp**2 + $zk**2);


    # this whole process comes from Schaum's mathematical methods pp. 31.
    #  But it's exactly the same as taking the dot-produce between the 
    #   relative velocity vector and the relative position vector.


    # get the direction cosines of the relative velocity
    my $vk = $Ve / sqrt($rk);
    my ($vex, $vey, $vez) = (0.0, $Ve, 0.0);

    my $beta = asin ( sin($elong) / $rkp );
    my $alpha = $PI - $elong;

    # get the coords of the objects
    my ($xe, $ye, $ze) = (1.0, 0.0, 0.0);
    my ($xk, $yk) = ($rkp*cos($alpha-$beta), $rkp*sin($alpha-$beta));

    my ($l, $m, $n) = ( ($xk-$xe)/$d, ($yk-$ye)/$d, ($zk-$ze)/$d );



    my ($vkx, $vky, $vkz) = 
	(-$vk*sin($alpha-$beta), $vk*cos($alpha-$beta), 0.0);

    my ($dvx, $dvy, $dvz) = ($vkx - $vex, $vky - $vey, $vkz - $vez);
    my $dv = sqrt($dvx**2 + $dvy**2 + $dvz**2);

    my ($l2, $m2, $n2) = ( $dvx/$dv, $dvy/$dv, $dvz/$dv );



    my $theta = acos($l*$l2 + $m*$m2 + $n*$n2);

    #my $vdotr = ($dvx*($xk-$xe) + $dvy*($yk-$ye) + $dvz*($zk-$ze));
    #my $absV = $dv;
    #my $absR = $d;
    #my $theta2 = acos( $vdotr / ($absV*$absR) );

    my $vPerp = $dv * sin($theta);
    $vPerp /= 100.0;

    #warn db($elong, $alpha, $beta,
#	    $rk, $rkp, $d, $dp, $xe, $ye, $ze, $xk, $yk, $zk, $l, $m, $n, 
	#    $vex, $vey, $vez, $vkx, $vky, $vkz, $dvx, $dvy, $dvz, 
	#    $dv, $l2, $m2, $n2, $DEG*$theta, $vPerp );



    return $vPerp;  # in metres
}

sub elong2v ($$) {

    my ($elong, $rk) = @_;  # elong in radians
    croak "usage: \$v = elong2v(\$elong, \$rk);\n" unless $rk;

    my $v = $Ve * ( 
		    sqrt(  (1.0/$rk) * (1.0-(1.0/$rk**2)*sin($elong)**2)  ) + 
		    cos($elong) 
		    );

    $v /= 100; # to convert to metres

    return $v;
}



# the inverse of elong2v ... has to be done iteratively
sub v2elong ($$$) {

    my ($v0, $AU, $tolerance) = @_;   # v0 in metres

    # just using Newton's method.
    my $max_count = 100;
    my $elong_new = 0;
    my $elong = 3.0*$PI/4.0;  # avoid pi as dvde = 0 when e=pi
    my $count = 0;
    my $d_elong = 2*$tolerance; 
    while ( $d_elong > $tolerance && $count < $max_count ) {

	my $v    = $v0 - elong2v($elong, $AU);
	my $dvde = dvde($elong, $AU);

	$elong_new = $elong - $v/$dvde;

	$d_elong = abs($elong_new - $elong);
	$elong = $elong_new;
	$count++;
    }

    return $elong;  # in radians
}

# calculate the distance to an object given it's orbital radius and elong
#  see page 182 of my notes.  ... it's just cosine law.
sub r2D ($$) {

    my ($AU, $elong) = @_;

    # note to self ... stop using $a and $b in perl (due to sort function)
    my $a = $AU_M;
    my $b = $AU*$AU_M;
    my $alpha = $PI - $elong;

    my $beta = asin( sin($elong)/$AU );
    my $theta = $alpha - $beta;

    #warn db($alpha, $beta, $theta);

    return sqrt($a**2 + $b**2 - 2.0 * $a * $b * cos($theta) )/$AU_M;

}
