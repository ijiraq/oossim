#!/usr/bin/env perl 
#
#

use strict;
use warnings;

my @infiles = @ARGV;


die "Usage: stdstats [columns] datafile\n" if (!$infiles[0]);

my @columns;
if ( $infiles[0] =~ /:/ || $infiles[0] =~ /^\d+$/ ) {
    
    my $firstArg = shift @infiles;
    @columns = split /:/, $firstArg;

}
@columns = map {$_ - 1} @columns;

die "Usage: stdstats [columns] datafile\n" if (!$infiles[0]);



# enter the percentiles you want (i chose the quartiles)
my @quartiles = (0.25,0.75);
my $modeSteps = 100;
my $binWidthRangeRatio = 0.1;
my @output = qw(N Sum Mean SD Median Mode Max Min Skew Kurt);

my %output;
foreach my $quantity (@output) {
    $output{$quantity} = 1;
}

sub outFormat ($) {  
    my ($value) = @_;

    $value = abs($value);

    my $oFormat;
    if ($value >= 1e6 ) {
	$oFormat = "%-9.3g";
    } elsif ($value < 1e6 && $value >= 1e5) {
	$oFormat = "%-9.0f";
    } elsif ($value < 1e5 && $value >= 1e4) {
	$oFormat = "%-9.0f";
    } elsif ($value < 1e4 && $value >= 1e3) {
	$oFormat = "%-9.1f";
    } elsif ($value < 1e3 && $value >= 1e2) {
	$oFormat = "%-9.2f";
    } elsif ($value < 1e2 && $value >= 0) {
	$oFormat = "%-9.3f";
    }

    return $oFormat;

}

#############################################
########      Read in the Data    ###########
#############################################


foreach my $infile (@infiles) {
    
    open (INFILE, "$infile");
    
    # declare an array (ultimately of references to arrays (one per col) )
    my @valueArray; 
    
    while (<INFILE>) {
 	my $column = 0;
 	
 	# split the string to get values from each column
 	foreach my $columnValue ( (split /\s+/,$_) ) {
	    if ( $columnValue =~ /^[+-]?\d+\.?\d*$/ ) {
		push @{$valueArray[$column++]}, $columnValue;
	    }else{
		push @{$valueArray[$column++]}, "#";
	    }		
 	}	
    }
    close (INFILE);
    
    ###############################################
    
    
    
    
    ###############################################
    ########## Print out the headings  ############
    ###############################################
    
    printf STDOUT "#            Data file: $infile\n";
    printf STDOUT "#            (Second row in units of standard deviation.)\n";
    
    # main headings
    printf STDOUT "%-5s","#Col";
    printf STDOUT "%-8s","N"        if ($output{N});
    printf STDOUT "%-9s","Sum"      if ($output{Sum});
    printf STDOUT "%-9s","Mean"     if ($output{Mean});
    printf STDOUT "%-9s","SD"       if ($output{SD});
    printf STDOUT "%-9s","Median"   if ($output{Median});
    printf STDOUT "%-9s","Mode"     if ($output{Mode});
    printf STDOUT "%-9s","Max"      if ($output{Max});
    printf STDOUT "%-9s","Min"      if ($output{Min});
    printf STDOUT "%-9s","Skew"     if ($output{Skew});
    printf STDOUT "%-9s","Kurt"     if ($output{Kurt});
    
    # any headings for percentiles
    foreach my $perc (@quartiles) {
 	printf STDOUT "%-9s","Q ".$perc;
    }
    printf STDOUT "\n";
    
    ##############################################
    
    
    
    
    ################################################################
    #
    ##############   Main body of Code   ###########################
    #
    ################################################################
    
    # declare global arrays to hold values for each column
    my $i = 0;
    my @N;
    my @sum;
    my @max;
    my @min;
    my @mean;
    my @median;
    my @stddev;
    my @skew;
    my @kurt;
    my @mode;
    
    # declare a global array to hold references to arrays (one per column)
    #    these arrays will contain any quartiles calculated.
    my @quart;


    my @columnRefsToAnalyse;
    foreach my $column (@columns) {
	push @columnRefsToAnalyse, $valueArray[$column];
    }

    @columnRefsToAnalyse = @valueArray if ( @columnRefsToAnalyse == 0 );
    
    # Calculate stats one column at a time.
    LISTLOOP: foreach my $list ( @columnRefsToAnalyse ) {

	my $nOrig = @$list;
 	@$list = grep {$_ !~ /\#/} @$list;
	@$list = (0)x$nOrig if (@$list == 0);

	if (@$list == 1) {
	    printf STDERR "Only 1 value in column %d ... skipping.\n",$i++ +1;
	    next LISTLOOP;
	}

 	# get the fundamental sums needed (values and values^2)
 	$sum[$i] = 0;
 	my $sumOfSqrs = 0;
 	my $sumOfCubes = 0;
 	my $sumOfQrs = 0;
 	foreach my $value ( @$list ) {
	    if ( $value =~ /^[+-]?\d+\.?\d*$/ ) {
		$sum[$i] += $value;
		$sumOfSqrs += $value**2;
		$sumOfCubes += $value**3;
		$sumOfQrs += $value**4;
	    }
 	}
 	
 	
 	# population and mean squared value.
 	$N[$i] = @$list;
 	my $meanOfSqrs = $sumOfSqrs/$N[$i];    
 	my $meanOfCubes = $sumOfCubes/$N[$i];
 	my $meanOfQrs = $sumOfQrs/$N[$i];
 	
 	# sort the data to get the max,min,median and any percentiles/quartiles
	my @sortlist = sort { $a <=> $b } @$list;
 	
 	$max[$i] = $sortlist[-1];
 	$min[$i] = $sortlist[0];
 	
	# if the whole column was not numeric, just fill it with zeros
 	
 	# Mode calculations #################
 	
 	if ( $output{Mode} ) {
 	    
 	    # bin the data to get the mode.
 	    
 	    $modeSteps = ($modeSteps>$N[$i]) ? ($N[$i]) : ($modeSteps);
 	    my @binnedData = (0)x$modeSteps;
 	    my $binWidth = $binWidthRangeRatio* ( $max[$i] - $min[$i] );
 	    my $binStep = ( $max[$i] - $min[$i] ) / $modeSteps;
 	    my $halfWidth = $binWidth/2.0;
 	    my $zerothBinCen = $min[$i] + 0.5*$binWidth;
 	    
 	    foreach my $value2 ( @$list ) {
 		my $binCentre = $zerothBinCen;
 		foreach my $count (@binnedData) {
 		    if (  ( $value2>=($binCentre-$halfWidth) ) && 
 			  ( $value2<=($binCentre+$halfWidth) ) ) {
 			$count++;
 		    }
 		    $binCentre += $binStep;
 		}
 	    }
 	    
 	    # Find the maximum count, ... that bin is the mode
 	    my $countMax = 0;
 	    $mode[$i] = $zerothBinCen;
 	    my $k = 0;
 	    foreach my $count2 (@binnedData) {
 		if ($count2 > $countMax) {
 		    $countMax = $count2;
 		    $mode[$i] = $zerothBinCen + $k*$binStep;
 		}
 		$k++;
 	    }
 	}
 	
 	
 	# Median and Quartiles ###############

 	if ($N[$i] > 3) {
	    # split quartiles into integers and decimal parts and interpolate
	    my $j = 0;
	    foreach my $quar (@quartiles) {
		my $Nint = int $quar*$N[$i];
		my $Ndec = $quar*$N[$i] - $Nint;
		my $diff = $sortlist[$Nint+1] - $sortlist[$Nint];
		$quart[$i]->[$j++] = $sortlist[$Nint]+$Ndec*$diff;
	    }
	    
	    # treat the median specially (rather than as a quartile) ... just because.
	    my $Nhalf_int = int 0.5*$N[$i];
	    my $Nhalf_dec = 0.5*$N[$i] - $Nhalf_int;
	    my $half_diff = $sortlist[$Nhalf_int+1] - $sortlist[$Nhalf_int];
	    $median[$i] = $sortlist[$Nhalf_int] + $Nhalf_dec*$half_diff;
	} elsif ($N[$i] == 2) {
	    my $j = 0;
	    foreach my $quar (@quartiles) {
		$quart[$i]->[$j++] = $quar*($sortlist[1]-$sortlist[0]);
	    }
	    $median[$i] = 0.5*($sortlist[1]-$sortlist[0]);
	} elsif ($N[$i] == 3) {
	    my $j = 0;
	    foreach my $quar (@quartiles) {
		$quart[$i]->[$j++] = $quar*($sortlist[-1]-$sortlist[0]);
	    }
	    $median[$i] = $sortlist[1];
	}
 	
 	# Mean ################################
 	
 	$mean[$i] = $sum[$i]/$N[$i];
 	my $meanSqrd = $mean[$i]**2;
 	my $meanCubed = $mean[$i]**3;
 	
 	
 	#  Standard Deviation #################
 	
 	$stddev[$i] = sqrt( $meanOfSqrs - $meanSqrd );
 	
 	
 	#  Skew and Kurtosis ##################
 	
 	if ($output{Skew} || $output{Kurt} ) {
 	    
 	    my $thirdMoment = ($meanOfCubes - 3*$mean[$i]*$meanOfSqrs + 2*$meanCubed);
 	    my $fourthMoment = ( $meanOfQrs - 4*$mean[$i]*$meanOfCubes + 6*$meanSqrd*$meanOfSqrs - 3*$mean[$i]**4);
 	    $skew[$i] = ($stddev[$i]>0) ? ($thirdMoment / $stddev[$i]**3) : 0;
 	    $kurt[$i] = ($stddev[$i]>0) ? ($fourthMoment / $stddev[$i]**4): 0;
 	    
 	}
 	
 	##################################
 	###    OUTPUT VALUES        ######
 	##################################
 	
 	# main values
 	printf STDOUT "%-5d",$columns[$i]+1              if (@columns>0);
	printf STDOUT "%-5d",$i+1                        if (@columns==0);
 	printf STDOUT "%-8d",$N[$i]                      if ($output{N});
 	printf STDOUT outFormat($sum[$i]),$sum[$i]       if ($output{Sum});
 	printf STDOUT outFormat($mean[$i]),$mean[$i]     if ($output{Mean});
 	printf STDOUT outFormat($stddev[$i]),$stddev[$i] if ($output{SD});
 	printf STDOUT outFormat($median[$i]),$median[$i] if ($output{Median});
 	printf STDOUT outFormat($mode[$i]),$mode[$i]     if ($output{Mode});
 	printf STDOUT outFormat($max[$i]),$max[$i]       if ($output{Max});
 	printf STDOUT outFormat($min[$i]),$min[$i]       if ($output{Min});
 	printf STDOUT outFormat($skew[$i]),$skew[$i]     if ($output{Skew});
 	printf STDOUT outFormat($kurt[$i]),$kurt[$i]     if ($output{Kurt});
 	
 	# any values for percentiles
 	foreach my $q ( @{$quart[$i]} ) {
 	    printf STDOUT "%-9.3g",$q;
 	}
 	printf STDOUT "\n";
 	
 	$stddev[$i] = ($stddev[$i]>0) ? $stddev[$i] : 1 ;
 	
 	printf STDOUT "%-5s","--";
 	printf STDOUT "%-8s","--"             if ($output{N} );
 	printf STDOUT "%-9s","--"           if ($output{Sum});
 	printf STDOUT "%-9s","--"           if ($output{Mean});
 	printf STDOUT "%-9s","--"           if ($output{SD});
 	printf STDOUT "%-9.3g",($median[$i]-$mean[$i])/$stddev[$i] 
 	    if ($output{Median});
 	printf STDOUT "%-9.3g",($mode[$i]-$mean[$i])/$stddev[$i]
 	    if ($output{Mode});
 	printf STDOUT "%-9.3g",($max[$i]-$mean[$i])/$stddev[$i]
 	    if ($output{Max});
 	printf STDOUT "%-9.3g",($min[$i]-$mean[$i])/$stddev[$i]
 	    if ($output{Min});
 	printf STDOUT "%-9s","--"           if ($output{Skew});
 	printf STDOUT "%-9s","--"           if ($output{Kurt});
 	
 	foreach my $q2 ( @{$quart[$i]} ) {
 	    printf STDOUT "%-9.3g",($q2-$mean[$i])/$stddev[$i];
 	}
 	printf STDOUT "\n\n";
 	
 	###################################
 	
 	
 	
 	$i++;
    }
    
    
}
