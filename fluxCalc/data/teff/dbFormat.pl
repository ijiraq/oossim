#!/usr/bin/perl

my $usage = "Usage: dbFormat filename1 filename2 ...";

my @input = @ARGV;
die $usage unless $input[0];

# want to be able to pass multiple files as CL arguments
foreach $in (@input) {

my $newDB = $in . ".form";

open(INPUT, "$in");
open(NEWDB, ">>$newDB");

my @wave = ();
my @flux = ();

while (<INPUT>) {
    my @line = split;
    my ($wave, $flux) = @line[0,1];

    next if (($wave < 0.301) || ($wave > 0.897));

    push(@wave, $wave);
    push(@flux, $flux);

}

for ($i=0; $i < @wave; $i=$i+3) {
    my $w = $wave[$i];
    my $f = $flux[$i];
    print NEWDB ($w, " $f\n");
}

close INPUT;
close NEWDB;

}#closes foreach loop
