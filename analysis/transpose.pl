#!/usr/bin/env perl
#
#

use strict;
use warnings;

my @data;
while (<>) {
    my @line = split;
    foreach my $column (0 .. $#line) { 
	push @{$data[$column]}, $line[$column]; 
    }
}

foreach my $dataref (@data) {
    printf STDOUT "%s\n", join(" ", @$dataref);
}

exit 0;
