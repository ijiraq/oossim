#!/usr/bin/env perl
#
# original filename: strSplit.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca

#  Host: bender.astro.princeton.edu
#  Working Directory: /Users/bick/sandbox/utility
#


use strict;
use warnings;
use File::Basename;

my $exe = basename($0);
my $usage = "Usage: $exe filename old-delimiter new-delimiter\n";

my ($infile, $delim_old, $delim_new) = @ARGV;
die $usage unless $delim_old;

my $string = "";
open (INFILE, "$infile");
while (<INFILE>) {$string .= $_;}
close(INFILE);

my $newline = sprintf "\n";
my $tab = sprintf "\t";
my $backspace = sprintf "\b";
my $cr = sprintf "\r";
for ($delim_new) {
  s/\\n/$newline/g;
  s/\\t/$tab/g;
  s/\\b/$backspace/g;
  s/\\r/$cr/g;
}
$string =~ s/${delim_old}/${delim_new}/g;
printf STDOUT "${string}";

exit 0;
