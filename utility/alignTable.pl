#!/usr/bin/env perl
#
# original filename: alignTable.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Sat Dec 23, 2006  14:42:33 EST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/utility
#


use strict;
use warnings;
use File::Basename;

use Local::Constants;
use Local::Astrotools;

my $exe = basename($0);
my $usage = "Usage: $exe infile decimals\n";

my ($infile, $decimals) = @ARGV;
die $usage unless defined $decimals;

my $form = "%.${decimals}g";

my @lines;
my @lengths = (0)x100;
my $imax = 0; 
open (INFILE, "$infile");
while (<INFILE>) {

    # keep the comments
    printf $_ if /^\#/;
    next if /^\#/;

    # read in the fields from this line
    my @line = split;
    push @lines, [@line];

    # get the length of the output
    #   assuming the num of decimals given.
    my $i = 0;
    foreach my $field (@line) {

	# sprintf using the num of decimals and lose the whitespace
	my $string = sprintf "$form ", $field;
	$string =~ s/\s+(\S+)\s+/$1/;

	# get the line length and store the size of the longest one.
	my $len = length ($string);
	$lengths[$i] = $len if $len > $lengths[$i];
	$i++;
    }
    # stash the max number of columns too.
    $imax = $i if $i>$imax;
}
close (INFILE);


# print the column numbers
foreach my $i (0 .. $imax) {
    my $colform = "%${lengths[$i]}d";
    printf "$colform  ", $i+1 if $lengths[$i] > 0;
}
printf "\n";

# print the fields
foreach my $line (@lines) {

    foreach my $j (0 .. $#{@$line} ) {
	my $fullform = "%${lengths[$j]}.${decimals}g";
	printf "$fullform  ", $$line[$j];
    }
    printf "\n";
}

exit 0;
