#!/usr/bin/env perl
# Perl Module:  Rotate.pm
#
# Purpose: a Perl module  containing a subroutine to rotate a vector in 3d
#
# Author: Steve Bickerton, McMaster University
#         bick@physics.mcmaster.ca
#         Thurs. June 22, 2006
# Functions:   rotate3D
#
#

package  Local::Rotate;

use strict;
use warnings;

require  Exporter;

our @ISA       = qw( Exporter );
our @EXPORT    = qw( rotate3D );
our @EXPORT_OK = qw();
our @EXPORT_TAGS = ( ALL => [ @EXPORT_OK ], );
our $VERSION   = 1.00;


# -------------------------------------------------------
#
# function: rotate3D
#
# Purpose: Rotate a vector about axis 'x/y/z' by arg
#
# Req'd Parameters: axis  - x,y,z
#                   arg   - angle in radians
#                   x,y,z - coords of vector to rotate
#
# Limitation:
#
# Source:   schaums math pp 34
#-----------------------------------------------



########################################################################
# rotation subroutine
sub rotate3D($$$$$) {    
    my ($axis, $arg, $x, $y, $z) = @_;

    die "Axis must be x, y, or z\n", unless $axis=~/[xXyYzZ]/;
    # direction cosines
    my ($C, $S) = (cos($arg), sin($arg));

    my ($l1, $l2, $l3, $m1, $m2, $m3, $n1, $n2, $n3);
    if ($axis =~ /[xX]/) {
	($l1, $l2, $l3) = (1.0, 0, 0);
	($m1, $m2, $m3) = (0, $C, $S);
	($n1, $n2, $n3) = (0, -$S, $C);
    }
    if ($axis =~ /[yY]/) {
	($l1, $l2, $l3) = ($C, 0, $S);
	($m1, $m2, $m3) = (0, 1.0, 0);
	($n1, $n2, $n3) = (-$S, 0, $C);
    }
    if ($axis =~ /[zZ]/) {
	($l1, $l2, $l3) = ($C, $S, 0);
	($m1, $m2, $m3) = (-$S, $C, 0);
	($n1, $n2, $n3) = (0, 0, 1.0);
    }
     
    return ($l1*$x+$m1*$y+$n1*$z, $l2*$x+$m2*$y+$n2*$z, $l3*$x+$m3*$y+$n3*$z);
}

