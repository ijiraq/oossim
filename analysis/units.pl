#!/usr/bin/env perl
#
#

use strict;
use warnings;
use lib "$ENV{HOME}/libperl";
use Local::Units;

my $usage = "usage: $0 value unit\n".
    "time units:     fs ns us ms s min h d w l y My Gy HT \n".
    "angle units:    rad deg am as mas uas \n".
    "distance units: fm pm nm um mm cm m km AU pc ly kpc Mpc Gpc \n".
    "mass units:     fg pg ng ug mg g  kg T kT M1 Mc Mm Me Mj Mo \n".
    "\n".
    "funtions: timeUnits(\$value, \$unit)\n".
    "          angleUnits(\$value, \$unit)\n".
    "          distanceUnits(\$value, \$unit)\n";


my ($value, $unit) = @ARGV;
die $usage if ! $unit;


if ( $unit =~ /^(fs|ns|us|ms|s|min|h|d|w|l|y|My|Gy|HT)$/ ) {
    $unit = ( $unit eq "min" ) ? "m" : $unit;
    printf STDOUT "%s\n", timeUnits($value, $unit);
    exit 0;
}

printf STDOUT "%s\n", angleUnits($value, $unit)    
    if ( $unit=~/^(rad|deg|am|as|mas|uas)$/ );

printf STDOUT "%s\n", distanceUnits($value, $unit) 
    if ( $unit =~ /^(fm|pm|nm|um|mm|cm|m|km|AU|pc|ly|kpc|Mpc|Gpc)$/ );

printf STDOUT "%s\n", massUnits($value, $unit)
    if ( $unit =~ /^(fg|pg|ng|ug|mg|g|kg|T|kT|M1|Mc|Mm|Me|Mj|Mo)$/ );

exit 0;
