#!/usr/bin/env perl
#
# original filename: ifold.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Tue May  6, 2008  13:27:41 DST
#  Host: bender.astro.princeton.edu
#  Working Directory: /Users/bick/sandbox/utility
#


use strict;
use warnings;
use File::Basename;
use Getopt::Std;

my $exe = basename($0);
my $usage = "Usage: $exe [-i n-indent] [-w n-fold] file\n";

my %options = ();
getopts("i:w:", \%options);

my ($infile) = @ARGV;
die $usage unless $infile;

my $n = (defined $options{w}) ? $options{w} : 80;
my $indent = (defined $options{i}) ? $options{i} : 4;

open(INFILE, "$infile");
while(<INFILE>) {
  chomp $_;
  my $length = length($_);

  printf STDOUT "%s\n", substr($_, 0, $n);

  my $overflow = ($length > $n) ? substr($_, $n) : "";
  my $Nover = length($overflow);

  if ( $Nover ) {
    chomp $overflow;
    my $iter = $Nover / ($n - $indent);
    for my $i (0 .. $iter) {
      printf STDOUT "%s%s\n", " " x $indent, 
	substr($overflow, $i*($n-$indent), $n-$indent );
    }
  }
  
}
close(INFILE);

exit 0;
