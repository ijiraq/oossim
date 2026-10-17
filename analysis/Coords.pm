#!/usr/bin/env perl
# Perl Module:  Coords.pm
#
# Purpose: a Perl module  containing subroutines to perform coordinate
#          transforms.  
# Author: Steve Bickerton, McMaster University
#         bick@physics.mcmaster.ca
#         Tues. Oct. 18, 2005
# Functions:   
#
#

package  Local::Coords;

use strict;
use warnings;

use Carp;
use Math::Trig;

require  Exporter;

our @ISA       = qw( Exporter );
our @EXPORT    = qw( 
		     sex2dec dec2sex dec2sexS 
		     gal2cel cel2gal ecl2cel cel2ecl 
		     decnum sexnum
		     );
our @EXPORT_OK = qw();
our @EXPORT_TAGS = ( ALL => [ @EXPORT_OK ], );
our $VERSION   = 1.00;


#######################################################################
# initializations
#
#######################################################################
my $PI = 3.1415926536;

my $decnum = '[+-]?\d+\.?\d*';
my $sexnum = '[+-]?\d{1,3}:\d\d:\d\d\.?\d*';

my ($alpha_GP, $delta_GP) = (192.85948, 27.12825);
my ($l_CP, $b_CP)    = (123.932, 27.12825);


sub eclipticPoleIncl ($) {
    my ($epoch) = @_;
    my $T = ($epoch - 2000.0)/100.0;
    return 23 + 26/60 + (21.448 - 46.82*$T - 0.0006*$T**2 + 0.0018*$T**3)/3600;
}

my $ecl_pole_incl = eclipticPoleIncl(2000);
my ($alpha_EP, $delta_EP) = (270.0,  90.0 - $ecl_pole_incl);
my ($lambda_CP, $beta_CP) = (90.0, 90.0 - $ecl_pole_incl);

######### end of initializations ######################################

sub decnum () { return $decnum; }
sub sexnum () { return $sexnum; }


######################################################################
# sex2dec, dec2sec
# convert decimal to sexigesimal
######################################################################
sub dec2sex ($) {

    my ($radec) = @_;
    my $sign = ($radec>=0) ? 1 : (-1);
    $radec = abs($radec);

    my $hour = int $radec;
    my $min = int (($radec - $hour)*60);
    my $sec = ( ($radec - $hour)*60 - $min )*60;
	
    return ( $sign*$hour,$min,$sec);
}   

sub dec2sexS (@) {

    my @sex_strings;
    foreach my $radec (@_) {
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
	
	push @sex_strings, sprintf "%s%02d:%02d:%s", $signS, $hour,$min, $secS;
    }

    return @sex_strings;
}   

# convert sexigesimal to decimal
sub sex2dec (@) {

    my @dec;
    foreach my $radec ( @_ ) {
	my ($hour,$min,$sec) = split /:/,$radec;
	
	my $sign = ($hour>=0) ? 1 : (-1);
	$hour = abs($hour);
	
	push @dec, $sign*($hour+$min/60.0+$sec/3600.0);
    }
    return @dec;
}
########## done sex2dec, dec2sex  #####################################







#################################################################
# transform between different coordinate systems
# From Galactic Astronomy - Binney and Merrifield p31
#
# written using nomenclature for Galactic<->Celestial transformations
#  but can easily (and is easily) used to convert Ecliptic<->Celestial
#  by executing with ecliptic poles instead of Galactic
#  The inverse transform is obtained by switching the pole coordinates
#  for Galactic and Celestial.  There is a subroutine below that
#  computes the true inverse, but it gives the same answer as switching the
#  Gal and Cel poles ... so it's unused.
#  
#################################################################
sub transform($$$$$$$) {

    my ($alpha, $delta, $outform, @poles) = @_;

    # convert poles to radians
    my ($alpha_GP, $delta_GP, $l_CP, $b_CP) = map {$_*$PI/180.0} @poles;

    # convert hh:mm:ss to decimal degrees if necessary ... then to radians
    ($alpha) = map {15.0*$_} sex2dec($alpha) if ($alpha=~/^$sexnum$/);
    ($delta) = sex2dec($delta) if ($delta=~/^$sexnum$/);
    return (0,0) unless ($alpha =~ /^$decnum$/ && $delta =~ /^$decnum$/ ); 

    $alpha *= $PI/180.0;
    $delta *= $PI/180.0;
    
    # transform
    my $l = $l_CP - atan2( (cos($delta)*sin($alpha-$alpha_GP)), (cos($delta_GP)*sin($delta) - sin($delta_GP)*cos($delta)*cos($alpha-$alpha_GP)) );
	
    my $b = atan2( (sin($delta_GP)*sin($delta) + cos($delta_GP)*cos($delta)*cos($alpha-$alpha_GP)), (cos($delta)*sin($alpha-$alpha_GP)/sin($l_CP-$l)));
	
    # convert back to decimal
    $l *= 180.0/$PI;
    $b *= 180.0/$PI;
	
    # fix cyclic coordinate issues
    $l = 360 + $l if ($l < 0);
    $l = $l - 360.0 if ($l >= 360.0);

    # convert to hh:mm:ss if desired
    if ($outform=~/hms/) {
	my ($lS) = dec2sexS($l/15.0);
	my ($bS) = dec2sexS($b);
	return ($lS, $bS);
    }

    return ($l, $b);
}



#  not being used ... but i'm not deleting it
#  ... can accomplish this by switching the pole coordinates in Transform()
sub inverseTransform($$$$$$) {

    my ($l, $b, $alpha_GP, $delta_GP, $l_CP, $b_CP) = 
	map {$PI*$_/180.0} @_;

    my $alpha = $alpha_GP + atan2( (cos($b)*sin($l_CP-$l)), (cos($delta_GP)*sin($b) - sin($delta_GP)*cos($b)*cos($l_CP-$l)) );
	
    my $delta = atan2( (sin($delta_GP)*sin($b) + cos($delta_GP)*cos($b)*cos($l_CP-$l)), (cos($b)*sin($l_CP - $l)/sin($alpha - $alpha_GP)));
	
    $alpha *= 180.0/$PI;
    $delta *= 180.0/$PI;
	
    $alpha = 360 + $alpha if ($alpha < 0);
    $alpha = $alpha - 360.0 if ($alpha >= 360.0);

    return ($alpha, $delta);
}
########   end of transforms  #######################################






######################################################################
# gal2cel, cel2gal, ecl2cel, cel2ecl
#
# The are just front-end subroutines for transform().  They run transform()
#   with the appropriate poles for the desired transformation.
# 
#######################################################################
sub gal2cel ($$$) {
    my ($l, $b, $outform) = @_;
    return transform($l, $b, $outform, $l_CP, $b_CP, $alpha_GP, $delta_GP);
}

sub cel2gal ($$$) {
    my ($alpha, $delta, $outform) = @_;
    return transform($alpha, $delta, $outform, $alpha_GP, $delta_GP, 
		     $l_CP, $b_CP);
}

sub ecl2cel ($$$) {
    my ($lambda, $beta, $outform) = @_;
    return transform($lambda, $beta, $outform, $lambda_CP, $beta_CP, 
		     $alpha_EP, $delta_EP);    
}

sub cel2ecl ($$$) {
    my ($alpha, $delta, $outform) = @_;
    return transform($alpha, $delta, $outform, $alpha_EP, $delta_EP, 
		     $lambda_CP, $beta_CP);    
}

##########################################################################
