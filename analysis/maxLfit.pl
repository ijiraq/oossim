#!/usr/bin/env perl
#
# original filename: maxLfit.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Wed Feb  8, 2006  16:52:32 EST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/analysis
#

use strict;
use warnings;
use File::Basename;

use lib "$ENV{HOME}/libperl";
use Local::Constants;
use Local::Fit;

my $exe = basename($0);
my $usage = "Usage: $exe infile column function tolerance par1 par2 ...\n".
    "     function = gauss\n".
    "     eg. maxLfit file.dat 1 gauss 0.01 100.0 10.0\n";

my ($infile, $col, $f, $tol, @guess) = @ARGV;
die $usage unless @guess;
die "Don't know function $f\n" unless ($f =~ /(gauss)/);
$col-= 1;

# read in the data
my @data;
open (IN, "$infile");
while (<IN>) {
    next if /^\#/;
    push @data, [ (split)[$col] ];
}
close (IN);


# get the function params
my %name = ( "gauss" => ["# mean","rms"], );
my %ds = ( "gauss" => [0.001, 0.001], );
my %tol = ( "gauss" => [$tol, $tol], );
my %func = ( "gauss" => \&lnLi_gauss, );


##################################################################
# grid
my $grid = 0;
if ($grid) {
    my ($mmin, $mmax, $smin, $smax) = (90, 110, 5, 15);
    my $n = 30;
    my ($dm, $ds) = ( ($mmax-$mmin)/$n, ($smax-$smin)/$n );
    open (GRID, ">grid.dat");
    for (my $m=$mmin; $m<$mmax; $m+=$dm) {
	for (my $s=$smin; $s<$smax; $s+=$ds) {
	    printf GRID "$m $s %.3f\n", lnL(\@data,$func{$f},[$m,$s],$ds{$f});
	    printf STDERR "%.3f %.3f\r", $m, $s;
	}
	printf GRID "\n";
    }
    close (GRID);
    printf STDERR "\n";
}

#################################################################
# path
my ($fit, $iter) = maxLik(\@data, $func{$f}, \@guess, $ds{$f}, $tol{$f});
my @fit = @$fit;

foreach my $i (0 .. $#fit ) { printf "%-12s", $name{$f}->[$i]; }
printf "%-12s\n", "iter";
foreach my $i (0 .. $#fit ) { printf "%-12.3f", $fit[$i]; }
printf "%-12d\n", $iter;

exit 0;
