#!/usr/bin/env perl
#
#

use strict;
use warnings;
use Local::Stardata;

my ($spectype, $param) = @ARGV;
die "usage: $0 spectype (Teff|L|R|M|Mbol|Mv|UmB|BmV|VmR|RmI)\n" unless $param;

#my $value = star($spectype,$param);
my $value2 = $star{$spectype}{$param};
#printf STDOUT "%s\n", ($value) ? ($value):"$spectype $param not in database";
printf STDOUT "%s\n", ($value2) ? ($value2):"$spectype $param not in database";
