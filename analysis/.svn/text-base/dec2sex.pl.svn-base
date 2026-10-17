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

    my $is_dec = 1;
    my $decnum = decnum();
    $is_dec = 0 unless ($ra =~ /$decnum/ && $dec =~ /$decnum/ ); 

    my ($ra_sex, $dec_sex) = ($is_dec) ? 
	( dec2sexS($ra/15.0), dec2sexS($dec) ) : ("nan", "nan");
    my $outformat = ($is_dec) ? "%s %s" : "%12s %12s";

    my $outstring = sprintf "$outformat", $ra_sex, $dec_sex;
    printf STDOUT "%s%s\n", ($keep)? "$line " : "", $outstring;

}

exit 0;
