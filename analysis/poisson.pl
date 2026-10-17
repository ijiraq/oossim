#!/usr/bin/env perl
#
# original filename: poisson.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Tue Oct 17, 2006  14:20:01 DST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/pack_main/sandbox/analysis
#


use strict;
use warnings;
use File::Basename;

use Local::Constants;
use Local::Astrotools;
use Local::Statistics;

my $exe = basename($0);
my $usage = "Usage: $exe mu x1 x2\n";

my ($mu, $x1, $x2) = @ARGV;
die $usage unless defined $x2;
die $usage."  mu must be a number, and x1, and x2 must be integers\n" 
    unless ($mu=~/^$is_number$/ && $x1=~/^\d+$/ && $x2=~/^\d+$/ );

sub poisson ($) { my ($x)=@_; return ( $mu**$x/factorial($x) )* $EXP**(-$mu); }

for my $x ($x1 .. $x2) {  printf STDOUT "$x %.6f\n", poisson($x); }

exit 0;
