#!/usr/bin/env perl
#
#

use strict;
use warnings;

use Local::Coords;

my $usage = "usage: $0 [infile] function col1 col2 keep outform\n\n".
    "  infile is optional.  List of coords can be piped in through STDIN\n".
    "  functions: ecl2cel, cel2ecl, gal2cel, cel2gal\n".
    "  keep: [1|0] append the original line to the output\n".
    "  outform:  hms (hours,minutes,seconds) or dec (decimal)\n";


die "$usage" unless @ARGV;
(-s $ARGV[0]) or unshift (@ARGV, "-");
my ($infile, $function, $col1, $col2, $keep, $outform) = @ARGV;
die "$usage" unless $outform;

$col1--;
$col2--;

my %op = (
	  ecl2cel => \&ecl2cel,
	  cel2ecl => \&cel2ecl,
	  gal2cel => \&gal2cel,
	  cel2gal => \&cel2gal,
	  );
my %opnames = reverse %op;

die "Don't recognize function $function ? ... exiting.\n" if ! $op{$function};


# read in the data;
open (INFILE, "$infile");
while (<INFILE>) {

    next if /\#/;
    my $line = $_;
    chomp $line;
    my ($alpha, $delta) = (split)[$col1, $col2];

    # if we only got one coord, print out not a number
    if (! $delta) {
	printf STDOUT "%s%9s %9s\n", ($keep) ? "$line " : "", "nan", "nan";
	next;
    }

    my $stringformat = ($outform=~/hms/) ? "%s %s\n" : "%.9f %.9f\n";
    printf STDOUT "%s$stringformat", ($keep) ? "$line " : "", $op{$function}->($alpha, $delta, $outform);

}

exit 0;
