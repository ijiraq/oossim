#!/usr/bin/env perl
# Perl Module:  Physics.pm
#
# Purpose: a Perl module  containing subroutines to calculate equations 
#          in Physics
# Author: Steve Bickerton, McMaster University
#         bick@physics.mcmaster.ca
#         Mon. Jun. 26, 2006
# Functions:   blackbody()
#
#

package  Local::Physics;

use strict;
use warnings;
use Carp;
use Local::Constants;


require  Exporter;

our @ISA       = qw( Exporter );
our @EXPORT    = qw( planckV planckL planckN wien EfreqLamb);
our @EXPORT_OK = qw();
our @EXPORT_TAGS = ( ALL => [ @EXPORT_OK ], );
our $VERSION   = 1.00;

sub EfreqLamb($$) {
  my ($value0, $conv_type) = @_;
  
  my $out_value = 0.0;
  $out_value = $value0/$h_SI       if ($conv_type=~/Ef/);
  $out_value = $value0*$h_SI       if ($conv_type=~/fE/);
  $out_value = $h_SI*$C_SI/$value0 if ($conv_type=~/(EL|LE)/);
  $out_value = $C_SI/$value0       if ($conv_type=~/(fL|Lf)/);

  return $out_value;
}


# -------------------------------------------------------
# function: planckL()
# Purpose: Given the wavelength and Teff, calc the Energy/d(lambda)
# Req'd Parameters: lambda = wavelength
#                   Teff  = effective temperature
# Limitation:
# Source:   Carroll and Ostlie
#-----------------------------------------------
sub planckL ($$) {

    my ($lamb, $T) = @_;
    croak "usage: \$E_over_dlamb = planckL(\$lamb, \$T);\n" unless $T;

    my $numerator =  8.0 * $PI * $h_SI * $C_SI / $lamb**5;
    my $denominator = $EXP**($h_SI*$C_SI/($lamb*$k_SI*$T) ) - 1.0;

    return $numerator/$denominator;
}


# -------------------------------------------------------
# function: planckV()
# Purpose: Given the frequency and Teff, calc the Energy/d(nu)
# Req'd Parameters: nu = frequency
#                   Teff  = effective temperature
# Limitation:
# Source:   Carroll and Ostlie
#-----------------------------------------------
sub planckV ($$) {

    my ($nu, $T) = @_;
    croak "usage: \$E_over_dnu = planckV(\$nu, \$T);\n" unless $T;

    my $numerator =  8.0 * $PI * $h_SI * $nu**3 / $C_SI**2;
    my $denominator = $EXP**($h_SI*$nu/($k_SI*$T) ) - 1.0;

    return $numerator/$denominator;
}



sub wien ($) {
  my ($T) = @_;
  croak "usage: \$lambda = wien(\$T);  \# T in Kelvin, lambda in m \n" 
    unless ($T and $T > 0.0);
  return 2.8977685e-3/$T;
}
