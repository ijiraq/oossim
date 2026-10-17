#!/usr/bin/env perl
# Perl Module:  Filters.pm
#
# Purpose: a Perl module  containing a subroutines to filter data
#          (eg mean filters, median filters)
# Author: Steve Bickerton, McMaster University
#         bick@physics.mcmaster.ca
#         Mon. Sep. 26, 2005


#package  Local::Filters;
package  Local::Filters;

use strict;
use warnings;
use File::Temp qw(tempfile);

use lib "$ENV{HOME}/libperl";
use Local::Constants;
use Local::Misc;

use Carp;


require  Exporter;

our @ISA       = qw( Exporter );
our @EXPORT    = qw( meanFilter medianFilter smooth smooth2 smooth3 
		     smoothC convFilter );
our @EXPORT_OK = qw();
our @EXPORT_TAGS = ( ALL => [ @EXPORT_OK ], );
our $VERSION   = 1.00;


# -------------------------------------------------------
#
# function: smooth ()
#
# Purpose: smooth a list of data points
#
# Req'd Parameters: 

#
# Limitation:  
#
#

#-----------------------------------------------


sub smooth ($$$) {

    my ($inArrRef, $binwidth, $kernel) = @_;
    my @inarray = @$inArrRef;   

    my @smooth = (0) x (@inarray );


    #######################################################################
    #                   Calculations for the boxcar format

    if ( $kernel eq "boxcar" ) {
	my $hwid = (int $binwidth/2.0+0.5)-($binwidth%2);

	for (my $q=0; $q<=$#inarray; $q++) {
	    my $lo = (($q-$hwid)>=0) ? (int ($q-$hwid)) : (int 0);
	    my $hi = (($q+$hwid)<@inarray) ? (int ($q+$hwid)) : ($#inarray);
	    my @tmp = @inarray[$lo .. $hi];
	    $smooth[$q] = (sumArray \@tmp) / (@tmp);

	}
    }
    
    #######################################################################
    #                   Calculations for the gaussian format
    
    if ( $kernel eq "gauss" ) {
	my $sigma = (int $binwidth/2.0+0.5)-($binwidth%2);

	for (my $q=0; $q<@inarray; $q++) {
	    
	    my $lo = (($q-3*$sigma)>=0) ? (int ($q-3*$sigma)) : (int 0);
	    my $hi = (($q+3*$sigma)<@inarray) ? (int ($q+3*$sigma)) : ($#inarray);
	    my @window = @inarray[$lo .. $hi];

	    my ($tmp,$integral) = (0,0);
	    for (my $i=0; $i<=$#window; $i++) {
		my $gaussian = (1/$sqrtTWOPI)*
		    $EXP**(   -( (3*($i-@window/2)/(@window/2) )**2 / 2 ) );
		if ( $window[$i] ) {
		    $tmp += $window[$i]*$gaussian;
		    $integral += $gaussian;
		}
	    }
	    $smooth[$q] = ($tmp) / $integral;
	}
    }

    return @smooth;
}




sub smoothC ($$$) {
    
    my ($inArrRef, $binwidth, $kernel) = @_;
    
    my $tmpdir = "$ENV{HOME}/tmp";
    my $template = "smoothCXXXX";
    my ($fh, $filename) = tempfile($template, DIR=>$tmpdir);

    foreach my $coordpair (@$inArrRef) {
	printf $fh "%f %f\n",$coordpair->[0], $coordpair->[1];
    }
    
    my $kern = ($kernel =~ /gauss/) ? 1 : 0;
    my $smooth = `smoothC $filename 1:2 $kern $binwidth` 
	or die "Can't run smoothC";
    close ($fh);

    my @lines = split /\n/, $smooth;    
    my @smooth;
    foreach my $line (@lines) {
      next if $line=~/^\#/;
      my ($x, $y) = split /\s+/, $line;
      push @smooth, [$x,$y];
    }



    return \@smooth;

}


# smoothC is so much faster that there's no point in calling smooth2 anymore
sub smooth2 ($$$) { 
    my ($ref,$binw,$kern) = @_; 
    return smoothC($ref,$binw,$kern); 
}




# sub smooth2 ($$$) {

#     my ($inArrRef, $binwidth, $kernel) = @_;
#     my @inarray = @$inArrRef;   

#     my $halfwidth = $binwidth/2.0;
#     my $limit = $halfwidth;
#     $limit = 3.0*$halfwidth if ($kernel eq "gauss");

#     my %gaussian;
#     my @smooth;    
#     foreach my $i (0 .. $#inarray) {

# 	my ($x1, $y1) = @{ $inarray[$i] };

# 	# start at the point x1,y1 and work out from there
# 	my ($tmp, $integral, $count) = (0.0, 0.0, 0);
# 	LOOP: foreach my $j (0.. $#inarray) {	    


# 	    my ($x2,$y2,$dx,$kplus,$kminus);

# 	    LOOP2: foreach my $k (0..1) {
# 		my $sign = $k ? 1 : (-1);

# 		next LOOP2 if ! defined $inarray[$i+$sign*$j];
# 		($x2, $y2) = @{ $inarray[$i+$sign*$j] };
	    
# 		next LOOP2 if ($j==0 && $k==0);

# 		$dx = abs($x2-$x1);

# 		$kplus  += ($k==1 && $dx>$limit)?(1):(0);
# 		$kminus += ($k==0 && $dx>$limit)?(1):(0);

# 		if ($kernel eq "boxcar" ) {
# 		    if ( $dx <= $halfwidth )  {
# 			$tmp+=$y2; 
# 			$count++;
# 		    } 

# 		} elsif ($kernel eq "gauss" ) {
# 		    if ( $dx < 3.0*$halfwidth ) {
# 			if ( ! $gaussian{$dx} ) {
# 			    $gaussian{$dx} = (1/$sqrtTWOPI)*
# 				$EXP**(-($x2-$x1)**2/(2.0*$halfwidth**2));
# 			}
# 			my $gaussian = $gaussian{$dx};
			
# 			$tmp += $y2*$gaussian;
# 			$integral += $gaussian;
# 		    }		
# 		}

		
# 	    }  # end $k loop
# 	    last LOOP if ( $kplus && $kminus );
	    
# 	} # end j loop
# 	my $mean;
# 	$mean = $tmp/$count     if ($kernel eq "boxcar");
# 	$mean = $tmp/$integral  if ($kernel eq "gauss");
# 	push @smooth, [$x1, $mean];
	
	
#     } # end i loop
    
#     return \@smooth;
# }

sub smooth3 ($$$) {

    my ($inArrRef, $binwidth, $kernel) = @_;
    my @inarray = @$inArrRef;   

    my $limit = $binwidth;
    $limit = 3.0*$binwidth if ($kernel eq "gauss");
    my $halfwidth = $binwidth/2.0;

    my %gaussian;
    my @smooth;    
    foreach my $i (0 .. $#inarray) {

	my ($x1, $y1) = @{ $inarray[$i] };

	# start at the point x1,y1 and work out from there
	my ($tmp, $integral, $count) = (0.0, 0.0, 0);
	LOOP: foreach my $j (0.. $#inarray) {	    


	    my ($x2,$y2);
	    LOOP2: foreach my $k (0..1) {
		my $sign = $k ? 1 : (-1);

		next LOOP2 if ! defined $inarray[$i+$sign*$j];
		($x2, $y2) = @{ $inarray[$i+$sign*$j] };
	    
		next LOOP2 if ($j==0 && $k==0);

		if ($kernel eq "boxcar" ) {
		    if ( abs($x2-$x1) <= $halfwidth )  {
			$tmp+=$y2; 
			$count++;
		    } 

		} elsif ($kernel eq "gauss" ) {
		    my $dx = abs($x2-$x1);
		    my $gaussian = (1/$sqrtTWOPI)*
			$EXP**(-($dx)**2/(2.0*$binwidth));
		    
		    if ( $dx < 3.0*$halfwidth ) {
			$tmp += $y2*$gaussian;
			$integral += $gaussian;
		    }		
		}

		
	    }
	    last LOOP if ( abs($x2-$x1) > $limit);
	    
	}
	my $mean;
	$mean = $tmp/$count     if ($kernel eq "boxcar");
	$mean = $tmp/$integral  if ($kernel eq "gauss");
	push @smooth, [$x1, $mean];
	

    }
    
    return \@smooth;
}


# -------------------------------------------------------
#
# function: meanFilter ()
#
# Purpose: meanFilter a list of data points
#
# Req'd Parameters: 

#
# Limitation:  
#
#

#-----------------------------------------------


sub meanFilter ($$) {

    my ($inArrRef, $binwidth) = @_;
    my @inarray = @$inArrRef;   

    my @mean = (0) x (@inarray );

    my $hwid = (int $binwidth/2.0+0.5)-($binwidth%2);

    for (my $q=0; $q<=$#inarray; $q++) {
	my $lo = (($q-$hwid)>=0) ? (int ($q-$hwid)) : (int 0);
	my $hi = (($q+$hwid)<@inarray) ? (int ($q+$hwid)) : ($#inarray);
	my @tmp = @inarray[$lo .. $hi];
	$mean[$q] = (sumArray \@tmp) / (@tmp);
    }    
    return @mean;
}

# -------------------------------------------------------
#
# function: medianFilter ()
#
# Purpose: medianFilter a list of data points
#
# Req'd Parameters: 

#
# Limitation:  
#
#

#-----------------------------------------------


sub medianFilter ($$) {

    my ($inArrRef, $binwidth) = @_;
    my @inarray = @$inArrRef;   

    my @median = (0) x (@inarray );

    my $hwid = (int $binwidth/2.0+0.5)-($binwidth%2);

    for (my $q=0; $q<=$#inarray; $q++) {
	my $lo = (($q-$hwid)>=0) ? (int ($q-$hwid)) : (int 0);
	my $hi = (($q+$hwid)<@inarray) ? (int ($q+$hwid)) : ($#inarray);
	my @tmp = @inarray[$lo .. $hi];

	my @sortTmp = sort {$a<=>$b} @tmp;

	my $middleIndex = int (scalar @sortTmp / 2.0 - 0.5);
	$median[$q] = $sortTmp[$middleIndex];
    }    
    return @median;
}

# -------------------------------------------------------
#
# function: convFilter ()
#
# Purpose: convFilter a list of data points
#
# Req'd Parameters: 

#
# Limitation:  
#
#

#-----------------------------------------------


sub convFilter ($$) {

    my ($inArrRef, $filterRef) = @_;
    my @inarray = @$inArrRef;
    my @filter = @$filterRef;

    # use a filter with an odd number of entries
    push @filter, 0 if (@filter%2 == 0);

    my @conv = (0) x (@inarray );

    my $hwid = @filter/2;

    for (my $q=0; $q<=$#inarray; $q++) {
	my $lo = (($q-$hwid)>=0) ? (int ($q-$hwid)) : (int 0);
	my $hi = (($q+$hwid)<@inarray) ? (int ($q+$hwid)) : ($#inarray);
	my @tmp = @inarray[$lo .. $hi];

	foreach my $i (0 .. $#tmp) {
	    $conv[$q] += ( $tmp[$i] * $filter[@filter - @tmp + $i] );
	}
    }    
    return @conv;
}


