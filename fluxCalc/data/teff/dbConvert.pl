#!/usr/bin/perl
# This script is specifically designed to convert data files from LeJeune's stellar 
# spectra library (1997 & 1998) into a format usable by the makespec program.

my $usage = "Usage: dbConvert filename1 filename2 ...";

my @input = @ARGV;
die $usage unless $input[0];

# want to be able to pass multiple files as CL arguments
foreach $in (@input) {

my $newDB = $in . ".norm";

open(INPUT, "$in");
open(TEMP, ">tmpFile");
open(NEWDB, ">>$newDB");

#note that the CGS system of units is used here(sort of)...
my $planck = 6.626e-27; # erg.s
my $c = 2.9979e17;# nm/s
my $normalization;

while(<INPUT>) {
    my @line = split;
    my ($wave, $flux) = @line[0, 2];

    $flux = ($flux*(0.4)*$c)/($wave**2);
    my $photon_per_erg = $wave/($planck*$c);
    $flux = $flux*$photon_per_erg;

    if ($wave == 549) {
	$normalization = $flux;
    }
    
    $wave = $wave/1000;# nm to microns

    print TEMP ($wave, " $flux\n");
}
close INPUT;

die "No normalization found!" unless $normalization;

close TEMP;
open(TEMP, "tmpFile");
while (<TEMP>) {
    my @line2 = split;
    my ($wave_tmp, $flux_tmp) = @line2[0,1];

    $flux_tmp = $flux_tmp/$normalization;

    print NEWDB ($wave_tmp, " $flux_tmp\n");
}

close TEMP;
close NEWDB;
system("rm tmpFile");

}# closes foreach loop
