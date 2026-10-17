#!/usr/bin/env perl
#
#
# Written by Steve Bickerton
# Original version 31 May, 2004
#
# program txthistogram.pl
# 
# This program takes a list of values and bins them.  This is then
# output as an ascii histogram with bars made out of '*'s
# 

use strict;
use warnings;

my $usage = "Usage: $0 infile column bins\n";

die "$usage" unless @ARGV;
( -s $ARGV[0] ) or unshift(@ARGV, "-");
my ($infile, $column, $bins) = @ARGV;
die "$usage" if (!$bins);

my $width = 60;
my $totalHeight = 16;



sub log10 {
    my $n = shift;
    return log($n)/log(10);
}


# -------------------------------------------------------
# function: labelFormat ($$)
# Purpose: Take a value and truncate it to an appropriate number of decimals
#          based on the number of characters requested.  
#          Useful for putting labels on things
# Req'd Parameters: $value: the value to be formated
#                   $chars: the number of characters it has to fit
#-----------------------------------------------

sub labelFormat ($$) {
    my ($value,$chars) = @_;
    
    # need the number of characters left of the decimal
    my $whole = int $value;
    my $wholeChars = 1;
    $wholeChars = int (log10($whole) + 1) if ($whole>0);

    # if the number is just the right size, leave room for a decimal
    # ... otherwise $decimalChars (see below) will be negative
    $wholeChars-- if ($wholeChars == $chars);

    # if the number is too big, it'll be in sci-notn
    $wholeChars = 1 if ($wholeChars > $chars);


    # one of them is a decimal point
    my $digits = $chars - 1;
    my $decimalChars = $digits-$wholeChars;

    my $printForm;
    if ($value > 10**(-$decimalChars) && ($value < 10**($chars) ) ) {
	$printForm = "\%".sprintf "%d\.%df",$wholeChars,$decimalChars;
    } else {
	$printForm = "\%".sprintf ("\.%de",$digits-4);
    }

    return $printForm;
}


# -------------------------------------------------------
# function: histogram ($$)
# Purpose: Make a histogram with a bunch of data
# Req'd Parameters: $value: the value to be formated
#                   $chars: the number of characters it has to fit
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



###################################################################
#
#                  MAIN PROGRAM   
# 
####################################################################



#                read the values into an array
####################################################################

my @values;
my $i = 0;
open (INFILE, "$infile");
READIN: while (<INFILE>) { 
    next READIN if /^\#/; 
    push @values, (split)[$column-1];     
}
close (INFILE);


#                       Bin the data
###################################################################

my ($binCentreRef,$histValueRef) = histogram (\@values,$bins);

my @histValues = @$histValueRef;
my @binCentres = @$binCentreRef;


#    get the range of counts in the bins
my @sortHistValues = sort {$a <=> $b} @histValues;
my ($histMax,$histMin) = ($sortHistValues[-1],$sortHistValues[0]);



#           Initializations and definitions for formatted output
#####################################################################

#  define modulo:
#     if there are more bins than there's room to print labels for,
#     we'll need to print every 'n'th label ... modulo defines 'n'th
#     - it is: the width (in characters) for one label, divided by the
#              width of a bar of the histogram.
#####################################################################
my $charsPerLabel = 6.0;
my $modulo = int  ( $charsPerLabel/ ($width/$bins) + 1.0);
$modulo = 1 if ($modulo < 1);

my $charsPerBin = int ($width/$bins + 0.5);

# output format for labels and things being printed every n'th time.
my $outFormat = "%-".($modulo*$charsPerBin)."s";

# initialization of various 'special' strings
my $ticString = " "x($charsPerBin+1);    # built in histogram section
my $headString = " "x$charsPerBin;       # built in header section
my $labelString = " "x($charsPerBin-1);  # built in histogram section


####################################################################
#
#                  Print out Header stuff
####################################################################

# print the total number of values used to make the histogram
printf STDOUT "\n%s(%s values)\n\n",
    " "x(($width-$charsPerLabel)/2-2),scalar @values;


# print out the values (population) of some of the bins (those with labels)
my $k = 0;
foreach my $histValue (@histValues) {
    my $histValueTmp = sprintf "(%d)",$histValue;
    $headString .= sprintf ($outFormat, $histValueTmp) if ($k%$modulo==0);
    $k++;
}
printf STDOUT "$headString\n";



#####################################################################
#
#        Print out all the data as a nice histogram
#####################################################################

my $outString;
# Start at the top and work down
for (my $height=$totalHeight; $height>=0; $height--) {
    $outString = "|"." "x($charsPerBin);
    

    # go across bin by bin and if the value is high enough, include a "*"
    #  if not, include a space.

    my $k = 0;   # we need $k to do the 'modulo' thing
    foreach my $histValue ( @histValues ) {

	# if we not on the last line ...
	if ($height > 0) {

	    # concatenate a '*' or " " as necessary
	    $outString .= ($totalHeight*$histValue/$histMax >= ($height)) ? 
		"*"." "x($charsPerBin-1)   :   " "x($charsPerBin );

	} else {   # if we ARE on the last line:

	    # mark each bin with an 'x'
	    $outString .= "x"." "x($charsPerBin-1);

	    # build a ticstring with '^' chars to mark labeled bins
	    $ticString .= "^"." "x($modulo*$charsPerBin-1) 
		if ($k++%$modulo ==0);
	}
    }

    # now we've gone all the way across and built the string, print it out.
    printf STDOUT "%s\n", $outString;
}


#        Now make a footer with axis, labels, etc
########################################################################

# print an x-axis
printf STDOUT "_"x(length($outString)) . "\n";

# put a carot at each bin which is labelled (otherwise can't tell
#  which bin the label refers to
printf STDOUT "%s\n", $ticString;        # built in histogram section

# print labels
my $j = 0;
foreach my $label (@binCentres) {
    $label = sprintf labelFormat($label,5), $label;
    $labelString .= sprintf ($outFormat, $label) if ($j%$modulo==0);
    $j++;
}
printf STDOUT "$labelString\n\n";
