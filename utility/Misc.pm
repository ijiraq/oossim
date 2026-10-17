#!/usr/bin/env perl
# Perl Module:  Misc.pm
#
# Purpose: a Perl module  containing some miscellaneous subroutines
# Author: Steve Bickerton, McMaster University
#         bick@physics.mcmaster.ca
#         Sun. Sep. 25, 2005
#
#

package  Local::Misc;

use strict;
use warnings;

use Carp;
use Math::Trig;

require  Exporter;

our @ISA       = qw( Exporter );
our @EXPORT    = qw( log10 log2 logN jd sumArray meanArray 
		     timerBar labelFormat centreText 
		     sec2sex elapseRemain texTable );
our @EXPORT_OK = qw();
our @EXPORT_TAGS = ( ALL => [ @EXPORT_OK ], );
our $VERSION   = 1.00;


#  this should already exist in perl, but doesn't
sub log10 ($) {
    my $n = shift;
    croak "Can't take log of negative number: $n\n" if $n<0;
    return log($n)/log(10);
}

sub log2 ($) {
    my $n = shift;
    croak "Can't take log of negative number: $n\n" if $n<0;
    return log($n)/log(2);
}

sub logN ($$){
    my ($N,$n) = @_;
    croak "Can't take log of negative number: $n\n" if $n<0;
    return log($n)/log($N);
}




#  from   http://aa.usno.navy.mil/faq/docs/JD_Formula.html
sub jd ($$$$$$) {
    my ($year, $month, $day, $hour, $min, $sec) = @_;
    $min += $sec/60.0;
    my $sign = (100*$year + $month - 190002.5 > 0) ? 1 : (-1);
    my $jd = 367*$year - 
	int(  7.0*( $year +  int( ($month+9.0)/12.0 ) )/4.0 )   +
	int ( (275.0*$month)/9.0) + 
	$day + 
	1721013.5 + 
	($hour+$min/60.0)/24.0 - 
	0.5*$sign + 0.5;
    return $jd;
}


# handy for user feedback
sub timerBar ($$$) {
    my ($width, $position, $size) = @_;
    $width -= 2;

    my ($leadspace,$tailspace) = (" "x($width*($position/$size)+0.5),
				  " "x($width-$width*($position/$size)+0.5) );
    return sprintf "|%-${width}s|",$leadspace."*".$tailspace;

}


# -------------------------------------------------------
#
# function: labelFormat ($$)
#
# Purpose: Take a value and truncate it to an appropriate number of decimals
#          based on the number of characters requested.  
#          Useful for putting labels on things
#
# Req'd Parameters: $value: the value to be formated
#                   $chars: the number of characters it has to fit
#
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
#
# function: centreText ($$)
#
# Purpose: Centre a string given the width of the line and an offset
#
# Req'd Parameters: $string: the string to centre
#                   $width: the width of the terminal
#-----------------------------------------------

sub centreText ($$) {

    my ($string_in, $termwidth) = @_;

    my $len = length $string_in;
    my $indent = ($termwidth - $len) / 2;
    my $string_out = sprintf "%${indent}s%s", " ", $string_in;

    return $string_out;

}



# -------------------------------------------------------
#
# function: sumArray()
#
# Purpose: Sum the elements of an array.
#
# Req'd Parameters: $arrayRef, the array whose elements are to be summed
#
# Limitation: none known.
#

#-----------------------------------------------
sub sumArray ($) {
    my ($arrayRef) = @_;

    my $sum = 0;
    foreach my $value (@$arrayRef) {
	$sum += $value if ($value);
    }
    return $sum;
}

sub meanArray ($) {
    my ($arrayRef) = @_;

    return sumArray($arrayRef)/@$arrayRef;
}




# -------------------------------------------------------
#
# function: elapseRemain()
#
# Purpose: Calculate the elapsed time and remaining time for a looping program.
#
# Req'd Parameters: $t0 = starttime in seconds
#                   $ti = current time during execution (in seconds)
#                   $i  = current index in loop
#                   $total = number of loops
#
# Limitation: none known.
#

#-----------------------------------------------

sub sec2sex ($) {

    my ($t_sec) = @_;

    my $hr =  int($t_sec/3600.0);
    my $min = int(($t_sec - 3600.0*$hr)/60);
    my $sec = $t_sec - 3600.0*$hr - 60*$min;

    return sprintf  "%02d:%02d:%06.3f", $hr, $min, $sec;

}


sub elapseRemain ($$$$) {

    my ($t0, $ti, $i, $total) = @_;

    my $secElapse = $ti - $t0;
    my $percent = $i/$total;
    my $secTotal = $secElapse / $percent;
    my $secRemain = $secTotal - $secElapse;
    #printf STDERR "%d %d   %.4f %.4f  %.4f %.4f".
#	"\n", $i, $total, $secTotal $secElapse, $secRemain, $percent;
    
    my $elapse = sec2sex($secElapse);
    my $remain = sec2sex($secRemain);

    return ($elapse, $remain);

}







sub texTable ($$$$) {

    my ($data,$head,$vert,$align) = @_;
    my %data = %$data;

    my $table = "\\begin{tabular}{$align}\\hline\n";

    # print the header
    foreach my $head (@$head) {
	$table .= "$head &";
    }
    $table =~ s/(.*)&$/$1\\\\/;
    $table .= "\\hline\n";

    # fill in the bod
    foreach my $vert (@$vert) {
	
	$table .= "$vert &";
	foreach my $head (@$head) {
	    $table .= "$data{$head}{$vert} &";
	}
	$table =~ s/(.*)&$/$1\\\\/;
	$table .= "\n";
    }

    $table .= "\\hline\n".
	"\\end{tabular}\n";

    return $table;

}
