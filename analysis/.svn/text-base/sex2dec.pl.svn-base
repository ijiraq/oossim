#!/usr/bin/env perl
#
#

use strict;
use warnings;
use lib "$ENV{HOME}/libperl";
use Local::Coords;

my ($RA_col, $Dec_col, $keep, $infile) = @ARGV;
die "Usage: $0 RA_col Dec_col  keep[0|1] [infile]\n" 
    unless ( defined $keep && $keep =~/[01]/);
$RA_col--;
$Dec_col--;

my $fh = *STDIN;
open ($fh, "$infile") if ($infile);

while (<$fh>) {
 
    my $line = $_;
    chomp $line;
    my ($ra, $dec) = (split)[$RA_col,$Dec_col];

    my $is_sex = 1;
    my $sexnum = sexnum();
    $is_sex = 0 unless ($ra =~ /$sexnum/ && $dec =~ /$sexnum/ ); 

    my ($ra_deg, $dec_deg) = ($is_sex) ? 
	( (map {15.0*$_} sex2dec($ra)), sex2dec($dec) ) : ("nan", "nan");
    my $outformat = ($is_sex) ? "%.8f %.8f" : "%8s %8s";

    my $outstring = sprintf "$outformat", $ra_deg, $dec_deg;
    printf STDOUT "%s%s\n", ($keep)? "$line " : "", $outstring;

}

exit 0;
