#!/usr/bin/env perl
# Perl Module:  Histogram.pm
#
# Purpose: a Perl module  containing a subroutines dealing with making
#          histograms of data.
# Author: Steve Bickerton, McMaster University
#         bick@physics.mcmaster.ca
#         Sun. Sep. 25, 2005
#
package  Local::Histogram;

use strict;
use warnings;
use File::Temp qw(tempfile);

use Carp;
use Math::Trig;

#use lib "$ENV{HOME}/libperl";
use Local::Constants;

require  Exporter;

our @ISA       = qw( Exporter );
our @EXPORT    = qw( bin histogram kernelhist );
our @EXPORT_OK = qw();
our @EXPORT_TAGS = ( ALL => [ @EXPORT_OK ], );
our $VERSION   = 1.00;



sub bin ($$$) {
    
    my ($inArrRef, $binwidth, $kernel) = @_;
    
    my $tmpdir = "$ENV{HOME}/tmp";
    my $template = "binXXXX";
    my ($fh, $filename) = tempfile($template, DIR=>$tmpdir);
    printf $fh "%s\n", join("\n", @$inArrRef);
    close ($fh);

    my $kern = ($kernel =~ /gauss/) ? 1 : 0;
    my $col = 1;
    my $bin = `bin $filename $col $binwidth $kern` or die "Can't run bin";

    my @lines = split /\n/, $bin;    
    my (@bins, @values);
    foreach my $line (@lines) {
	my ($x, $y) = split /\s+/, $line;
	push @bins, $x;
	push @values, $y;
    }

    return \@bins,\@values;
}



sub kernelhist ($$$$$$$) {

    my ($inArrRef,$resolution,$binwidth,$kernel,$scaling,$low,$high) = @_;

    my @inarray = @$inArrRef;
   
    #
    # Calculate the dimensions of the required array and initiallize the array
    #

    my $n = int(($high-$low)/$resolution);
    my $counter = @inarray;
    my @histogram = (0) x ($n+1);

    # get the bin values
    my @bins;
    foreach my $i (0 .. $n) {
	$bins[$i] = $low + ($i)*$resolution;
    }

    # Read through the input data file and determine which bins the
    # data point will fall in.  In the case of the gaussian, the amount of
    # the contribution to each relevant bin is first determined.
    
    my $highestbin = int (($high-$low)/$resolution);

    #######################################################################
    #                   Calculations for the boxcar format

    if ( $kernel eq "boxcar" ) {
	my $hwid = $binwidth/2.0;
	
	foreach my $value (@inarray) {

	    # if within the range requested
	    if ($value >= ($low-$hwid) && $value <= ($high+$hwid)) {
		
		my $binlow = $value - $hwid;
		my $binhigh = $value + $hwid;
		my $nbinlow = int(($binlow - $low)/$resolution) + 
		    (  ($binlow>$low) ? (1) : (0)  );

		# if a point is right on the limit, it will appear
		# in the next bin ... correct for this.
		$nbinlow -= 1 if (($binlow - $low) == ($high-$low));

		my $nbinhigh = int(($binhigh - $low)/$resolution); 
		
		for (my $j=$nbinlow; $j <= $nbinhigh; $j++) {
		    $histogram[$j]++ if (($j >= 0) && ($j <= $highestbin));
		    
		}

	    }
	}
	
    }
    
    #######################################################################
    #                   Calculations for the gaussian format

    my $sigma = $binwidth/2.0;    
    if ( $kernel eq "gauss" ) {
	#my $sigma = $binwidth/2.0;

	foreach my $value (@inarray) {
	    
	    if ($value >= ($low-3*$sigma) && $value <= ($high+3*$sigma)) {
		my $binlow = $value - 3*$sigma;
		my $binhigh = $value + 3*$sigma;
		my $nbinlow = int(($binlow - $low)/$resolution) + 
		    (  ($binlow>$low) ? (1) : (0) );
		my $nbinhigh = int(($binhigh - $low)/$resolution);
		
		for (my $l=$nbinlow; $l <= $nbinhigh; $l++) {
		    if (($l >= 0) && ($l <= $highestbin)) {
			my $negdistsqr = -1 * ($value - ($low + ($l * $resolution)))**2;
			my $contrib = $EXP**($negdistsqr/(2 * $sigma**2));
			$histogram[$l] += $contrib;
		    }
		}
	    }
	    
	}
	
    }
   
    if ($scaling eq "density") {
	@histogram = map {$_/$binwidth} @histogram if ( $kernel eq "boxcar" ); 
	@histogram = map {$_/($sigma*$sqrtTWOPI)} @histogram if ( $kernel eq "gauss" ); 	
    } elsif ($scaling eq "probdensity") {
	$binwidth *= $counter;
	@histogram = map {$_/($binwidth*(scalar @inarray))} @histogram if ( $kernel eq "boxcar" ); 
	@histogram = map {$_/($sigma*$sqrtTWOPI*(scalar @inarray))} @histogram if ( $kernel eq "gauss" );
    } else {
	@histogram = @histogram;  # ie do nothing, return raw counts
    }


    return \@bins,\@histogram;

}


# -------------------------------------------------------
#
# function: histogram ($$)
#
# Purpose: Make a histogram with a bunch of data
#
# Req'd Parameters: $value: the value to be formated
#                   $chars: the number of characters it has to fit
#
#
# Limitation:  
#
#

#-----------------------------------------------


sub histogram ($$) {

    my ($valuesRef,$bins) = @_;

    my @values = @$valuesRef;

    my @valuesort = sort {$a <=> $b} @values;

    my $low = $valuesort[0];
    my $high = $valuesort[-1];
    my $range = $high - $low;
    my $binwidth = $range/$bins;
    
    my @histValues = (0)x$bins;
    my @binCentres = (0)x$bins;
    
    for (my $i=0; $i<$bins; $i++) {
	$binCentres[$i] = $low + ($i+0.5)*$binwidth;
    }
    
    # look at each value and see which bin i goes into
    foreach my $inValue (@values) {
	
	# check each bin
	for (my $q=0; $q<$bins; $q++) {
	    
	    # values on a bin boundary fall into the lower bin.
	    $histValues[$q]++ 
		if ( $inValue > ($low+$q*$binwidth) && 
		     $inValue <= ( $low+($q+1)*$binwidth) );
	}
	# add one to the first bin if its right on the border
	#  i've used  > for the low binlimit, but <= for the high
	#  ... so this is not a problem for the last bin.
	$histValues[0]++
	    if ( $inValue == $low ); 
	
    }

    return \@binCentres,\@histValues;
    
}



