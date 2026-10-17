#!/usr/bin/env perl
#
# original filename: countEntries.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Thu Nov 16, 2006  18:01:41 EST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/pack_main/sandbox/analysis
#


use strict;
use warnings;
use File::Basename;

use Local::Constants;

my $exe = basename($0);
my $usage = "Usage: $exe infile [column]\n";

my ($infile, $col) = @ARGV;
die $usage unless $infile;
$col = ($col) ? $col-1 : 0;

# the values into and increment a hash entry for each instance.
my %data;
open (INFILE, "$infile");
while (<INFILE>) {
    next if /^\#/;
    my ($entry) = (split)[$col];
    $data{$entry} = ($data{$entry}) ? $data{$entry}+1 : 1;
}
close (INFILE);

# print out all the hash entries.
foreach my $entry (sort keys %data) {
    printf STDOUT "$entry $data{$entry}\n";
}

exit 0;
