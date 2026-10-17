#!/usr/bin/env perl
#
# original filename: power2split.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Wed Feb  6, 2008  21:40:36 EST
#  Host: apache2.astro.Princeton.EDU
#  Working Directory: /u/bick/usr/bin/cdiffracSim
#


use strict;
use warnings;
use File::Basename;

my $exe = basename($0);
my $usage = "Usage: $exe infile base2min base2max\n";

my ($infile, $base2min, $base2max) = @ARGV;
die $usage unless $base2max;
die "Cannot read from stdin\n" if $infile=~/^-$/;

sub log2($) {return log($_[0])/log(2.0);}

# read in the datafile
my @data;
open(INFILE, "$infile");
while(<INFILE>) {
    next if /\#/;
    push @data, [split];
}
close(INFILE);
my $N = scalar @data;

# output the data to files
my $Nprinted = 0;
my $Nremaining = $N;
my $base2 = (2**$base2max>$Nremaining) ? log2($Nremaining) : $base2max;
my $n = 2**$base2;

my $j;
my $nfile = 0;
while ($Nremaining) {

    if ($Nremaining < 2**$base2min) {
	$n = $Nremaining;
    }
    while ($n > $Nremaining) {
	$base2--;
	$n = 2**$base2;
    }

    my $outfile = sprintf("%s.%02d",$infile, $nfile);
    open(OUTFILE, ">$outfile");
    foreach $j ($Nprinted .. $Nprinted+$n-1) {
	printf OUTFILE "%s %s\n", @{$data[$j]}[0,1];
    }
    close(OUTFILE);
    printf STDOUT "$outfile written ($n lines)\n";
    $Nremaining -= $n;
    $Nprinted += $n;
    $nfile++;
}

exit 0;
