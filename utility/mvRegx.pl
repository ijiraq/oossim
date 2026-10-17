#!/usr/bin/env perl
#
#

use strict;
use warnings;

my $usage = "Usage: $0 filename patt1 patt2\n";

my ($filename, $patt1, $patt2) = @ARGV;
die $usage unless $patt2;


my $filename2 = $filename;
my $string = "(\$filename2 = \$filename) =~ s/$patt1/$patt2/";
eval $string;

$filename2 = $filename unless $filename2;

#printf "$filename $filename2\n";
rename $filename, $filename2;

exit 0;
