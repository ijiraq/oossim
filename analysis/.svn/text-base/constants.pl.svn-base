#!/usr/bin/env perl
#
#


#use strict;
use warnings;
use lib "$ENV{HOME}/libperl";
use Local::Constants;
use Local::Misc;

foreach my $symname (keys %Local::Constants::) {

    my $ignore = ($symname=~/(EXPORT|VERSION|ISA|is_number)/) ? (1) : (0);
    if (! $ignore ) {
	local *value = $Local::Constants::{$symname};
	
	my $value2 = (log10($value)>5) ? (sprintf "%e",$value) : ($value) if defined $value;
	printf STDOUT "%1s%-10s\t%s\n","\$",$symname,$value2 if defined $value;
	printf STDOUT "%1s%-10s\n", "\@", $symname, $value2 if defined @value;
	printf STDOUT "%1s%-10s\n", "\%", $symname, $value2 if defined %value;
    }

}
