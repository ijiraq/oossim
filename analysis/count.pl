#!/usr/bin/env perl
#
#

use strict;
use warnings;

my $usage = "Usage: $0 infile(or \"dump\") low high stepsize output-format\n";

die $usage  unless @ARGV;
my ($infile, $lo, $hi, $step, $form) = @ARGV;
die $usage if ! $form;

my @lines;
my $header = "";
if ( $infile !~ /dump/ ) {

    open (INFILE, "$infile");
    while (<INFILE>) { 
	if ( $_ =~ /^\#/ ) {
	    $header .= $_;
	    next;
	}
	chomp $_;
	push @lines, $_; 
    }
    close(INFILE);

}

# deal with % symbols in the header
$header =~ s/\%/\%\%/g;

my $file_pres = ($#lines>1) ? (1) : (0);

my $n = ($file_pres) ? ($#lines) : (($hi - $lo) / $step);

printf STDOUT "$header";
foreach my $i (0 .. $n) {
    printf STDOUT "$form %s\n", ($lo + $i*$step), ($file_pres) ? ($lines[$i]) : "";
}
