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
my $usage = "Usage: $exe f v1 v2 (v1/v2 are degrees of freedom)\n";

my ($f, $v1, $v2) = @ARGV;
die $usage unless $v2;

my $N = 200;
my @Fdist;
foreach my $i (0 .. $N) {
    my $fi = $i*$f/$N;
    my $Fdist = Fdist($fi,$v1,$v2);
    push @Fdist, ($i) ? [$fi, $Fdist] : [0,0];
    #printf "%.3f %.5f\n", $fi,$Fdist;
}
my $Fstat = integrate(\@Fdist, 0, $f, 1);
printf STDERR "%.3g\n",$Fstat;

exit 0;
