#!/usr/bin/env perl
#
# original filename: lineInterval.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Mon Apr 16, 2007  15:20:52 DST
#  Host: kuiper
#  Working Directory: /home/bickersj/sandbox/utility
#


use strict;
use warnings;
use File::Basename;

my $exe = basename($0);
my $usage = "Usage: $exe infile nth-line\n";

my ($infile, $nth) = @ARGV;
die $usage unless $nth;

# print every n'th line of the file

my $i=0;
open (INFILE, "$infile") or die "opening $infile: $!\n";
while (<INFILE>) { print STDOUT $_ unless ($i++)%$nth; }
close (INFILE);

exit 0;
