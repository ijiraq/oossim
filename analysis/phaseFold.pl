#!/usr/bin/env perl
#
# original filename: tsFold.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Thu Nov 16, 2006  18:13:58 EST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/pack_main/sandbox/analysis
#


use strict;
use warnings;
use File::Basename;

use Local::Constants;

my $exe = basename($0);
my $usage = "Usage: $exe infile period [ xcol:ycol[:errcol] ]\n";

my ($infile, $period, @args) = @ARGV;
die $usage unless $period;

my ($xcol, $ycol, $errcol) = (1,2,0);
foreach my $arg (@args) {

    if ($arg =~ /^\d+:\d+$/) {
	($xcol, $ycol) = $arg =~ /^(\d+):(\d+)$/;
    }
    if ($arg =~ /^\d+:\d+:\d+$/ ) {
	($xcol, $ycol, $errcol) = $arg =~ /^(\d+):(\d+):(\d+)$/;
    }
}
$xcol--;
$ycol--;
$errcol--;

my @data;
open (INFILE, "$infile");
while (<INFILE>) {
    next if /^\#/;
    my ($x, $y, $dy);
    if ($errcol > 0) {
	($x, $y, $dy) = (split)[$xcol,$ycol,$errcol];
    } else {
	($x, $y) = (split)[$xcol, $ycol];
	$dy = 1.0;
    }
    # index 4 will hold the int part of the phase
    push @data, [$x, 0.0, $y, $dy, 0];
    push @data, [$x, 1.0, $y, $dy, 0];
}
close (INFILE);


# sort the data in x
@data = sort {$a->[0] <=> $b->[0]} @data;

my $x0 = $data[0]->[0];

# phase the data
foreach my $ref (@data) {
    my ($x, $phase, $y) = @$ref;
    
    my $Tfrac = ($x-$x0)/$period;
    my $Tfrac_int = int($Tfrac);
    
    my $remainder = $Tfrac-$Tfrac_int;
    my $x_new = $remainder*$period;
    
    $ref->[0] = $x_new;
    $ref->[1] = $x_new/$period;
    $ref->[4] = $Tfrac_int;
    if ($phase) {
	$ref->[0] += $period;
	$ref->[1] += 1.0;
    }
    
}

@data = sort {$a->[0] <=> $b->[0]} @data;

# print the phased data
printf STDOUT "# 01 x\n".
    "# 02 y\n".
    "# 03 dy\n".
    "# 04 Tfrac_int\n".
    "# 05 phase\n";
foreach my $ref (@data) {
    my ($x,$phase,$y,$dy,$Tfrac_int) = @$ref;
    printf STDOUT "%.6f %.6f %.6f %d %.6f".
	"\n", $x, $y, $dy, $Tfrac_int, $phase;
}

exit 0;
