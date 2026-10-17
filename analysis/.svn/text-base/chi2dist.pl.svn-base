#!/usr/bin/env perl
#
# original filename: Fdist.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Thu Sep 28, 2006  12:15:48 DST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/analysis
#


use strict;
use warnings;
use File::Basename;

#use lib "$ENV{HOME}/libperl2";
use Local::Constants;
use Local::Statistics;
use Local::Integrate;

my $exe = basename($0);
my $usage = "Usage: $exe chi2 v [-r] [-d] (v = degrees of freedom)\n".
    "    Use -r option is chi2 is a reduced chi2 statistic\n".
    "    Use -d option to dump the distribution up to chi2\n";


my ($x2, $v) = @ARGV;
die $usage unless $v;
shift @ARGV;
shift @ARGV;

my $is_reduced = 0;
my $print_distrib = 0;

foreach my $arg (@ARGV) {
    $is_reduced = 1 if ($arg eq '-r');
    $print_distrib = 1 if ($arg eq '-d');
}

$x2 *= $v if $is_reduced;

my $N = 1000;
my @chi2dist;
foreach my $i (0 .. $N) {
    my $x2i = $i*$x2/$N;
    my $chi2dist = chi2dist($x2i,$v);
    push @chi2dist, ($i) ? [$x2i, $chi2dist] : [0,0];
    printf "%.6f %.9f\n", $x2i/$v, $v*$chi2dist 
	if $print_distrib and $is_reduced;
    printf "%.6f %.9f\n", $x2i, $chi2dist 
	if $print_distrib and ! $is_reduced;
}
my $chi2stat = integrate(\@chi2dist, 0, $x2, 1);
printf STDOUT "# %.6f\n",$chi2stat;

exit 0;
