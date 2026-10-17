#!/usr/bin/env perl
# Perl Module:  Integrate.pm
#
# Purpose: a Perl module  containing a subroutine to integrate date in a file
# Author: Steve Bickerton, McMaster University
#         bick@physics.mcmaster.ca
#         Sun. Sep. 25, 2005
# Functions:   only the one
#
#

package  Local::Integrate;

use strict;
use warnings;

use Carp;
use Math::Trig;

require  Exporter;

our @ISA       = qw( Exporter );
our @EXPORT    = qw( integrate );
our @EXPORT_OK = qw();
our @EXPORT_TAGS = ( ALL => [ @EXPORT_OK ], );
our $VERSION   = 1.00;

# -------------------------------------------------------
#
# function: integrate ($$)
#
# Purpose: Integrate a function
#
# Req'd Parameters: \@values:  ref to array containing refs to [x,y] values
#                   $x1:      start point
#                   $x2:      end point
#                   $numonly   boolean ... return only final value if set.
#
# Limitation:  
#
#
#-----------------------------------------------


sub integrate ($$$$) {

    my ( $values, $x1, $x2, $numonly ) = @_;

    # this does nothing as sub is declared with ($$$$) ... must fix that.
    croak "usage: my \$int = integrate(\$val_ref, \$x1, \$x2, \$numonly)\n"
	unless defined($numonly);

    my $n = 0;
    my $ylast = 0.0;
    my ($traptotal,$trapout,$deltax);
    my $xlast = $x1;

    my ($x, $y);
    my @integral = ();
    my $size = $#{@$values};
    POINT: foreach my $i ( 0 ..  $size ) {
	
	($x, $y) = @{$$values[$i]};

	# first point between x1 and x2
	if ( $x > $x1 && $xlast <= $x1 ) {
	    carp "First point (x=$x) is greater than x1=$x1\n" if $i==0;
	    
	    my $dx = ($x - $xlast);
	    my $dy = ($y - $ylast);
	    $deltax = ($x - $x1);
	    my $y1 = $ylast + $deltax*($dy/$dx);
	    $trapout = 0.5*($y1+$y)*$deltax;
	    push @integral, [$x, $trapout];

	# points between x1 and x2
	} elsif ( $x > $x1 && $xlast > $x1 && $x < $x2 ) {
	    
	    $deltax = ($x-$xlast);
	    $trapout += 0.5*$deltax*($ylast + $y);
	    push @integral, [$x, $trapout];
	    
	# if we've past x2, interpolate to add the 
	#    bit from xlast to x2
	} elsif ( $x >= $x2 ) {
	    
	    $deltax = ($x2 - $xlast);
	    my $dy = ($y - $ylast);
	    my $dx = ($x - $xlast);
	    my $y2 = $ylast + $deltax*($dy/$dx);
	    $trapout += 0.5*($y + $y2)*$deltax;
	    push @integral, [$x2, $trapout];
	    
	    last POINT;
	}
	
	($xlast, $ylast) = ($x, $y);
    }
    
    carp "Last point (x=$x) reached before x2=$x2\n" if $x<$x2;
    
    if ( $numonly ) {
	return $trapout;
    } else {
	return \@integral;
    }

}
