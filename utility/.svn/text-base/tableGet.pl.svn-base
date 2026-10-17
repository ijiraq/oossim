#!/usr/bin/env perl
#
# original filename: tableGet.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Thu Apr 12, 2007  14:54:47 DST
#  Host: kuiper
#  Working Directory: /home/bickersj/sandbox/utility
#


use strict;
use warnings;
use File::Basename;

use Local::Constants;
use Local::Astrotools;

my $exe = basename($0);
my $usage = "Usage: $exe infile row1:col1 row2:col2 ...\n";

my ($infile, @coords) = @ARGV;
die $usage unless $coords[0];

my @data;
open (INFILE, "$infile");
while (<INFILE>) { push @data, [split]; }
close (INFILE);


my $rows = scalar @data;
foreach my $row (0 .. $rows-1) {
    my $columns = scalar @{$data[$row]};
    foreach my $column (0 .. $columns-1) {
	
	foreach my $coord (@coords) {
	    my ($r, $c) = $coord =~ /^(\d+):(\d+)$/ or die $usage;
	    $r--; $c--;
	    print "$data[$row][$column]  " if ($r == $row && $c == $column);
	}

    }
}
print "\n";
exit 0;
