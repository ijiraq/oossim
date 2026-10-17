#!/usr/bin/env perl
#
# original filename: powerSpecrum.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Tue Jan 17, 2006  15:28:24 EST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/working/oneOverF
#

use strict;
use warnings;

use Local::Fourier;

my $usage = "Usage: $0 infile [time_col] [rvalue_col] [ivalue_col]\n";

my ($infile, $tcol, $vcol, $icol) = @ARGV;
die $usage unless $infile;
$tcol = 1 unless $tcol;
$vcol = 2 unless $vcol;
my $is_complex = ($icol) ? 1 : 0;
$icol = 3 unless $icol;
$tcol-=1;
$vcol-=1;
$icol-=1;


# read in the data
my @ts;
open (INFILE, "$infile");
while (<INFILE>) {
    next if $_=~/^\#/;
    my ($t, $value, $ivalue) = (split)[$tcol,$vcol,$icol];
    push @ts, ($is_complex) ? [$t, [$value, $ivalue] ] : [$t, $value];
}
close(INFILE);

my $spectrum = powerSpectrum(\@ts);

# print out the spectrum
printf STDOUT "# %-12s %-14s %-14s %-14s %-14s".
    "\n", "freq", "pow", "phase", "real", "imag";

foreach my $entry (@$spectrum) {

    my ($freq, $power, $phase, $real, $imag, $t, $tsr, $tsi) = @$entry;
    printf STDOUT "%-14.8g %-14.8g %-14.8g %-14.8g %-14.8g".
	"\n", $freq, $power, $phase, $real, $imag;

}


exit 0;
