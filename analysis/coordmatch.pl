#!/usr/bin/env perl
#
# original filename: coordmatch.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Wed May 16, 2007  13:49:57 DST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/analysis
#


use strict;
use warnings;
use File::Basename;

my $exe = basename($0);
my $usage = "Usage: $exe file1 file2 xcol1:ycol1 xcol2:ycol2 [tol=%.f]\n".
    "\n".
    "   cx1:cy1: column numbers for the x,y coordinates in file 1\n".
    "   tol:   the tolerance as a decimal number\n".
    "          default = 1  (ie. match within 1 unit as defined by \'pix\')\n";


my ($file1, $file2, $col1, $col2, @args) = @ARGV;
die $usage unless $col2;

my ($xcol1, $ycol1) = $col1 =~ /^(\d+):(\d+)$/;
my ($xcol2, $ycol2) = $col2 =~ /^(\d+):(\d+)$/;

die "xcol1 not defined\n".$usage unless $xcol1;
die "xcol2 not defined\n".$usage unless $xcol2;
die "ycol1 not defined\n".$usage unless $ycol1;
die "ycol2 not defined\n".$usage unless $ycol2;

my $number = '[+-]?\d+\.?\d*';
my $enumber = ${number}.'[eE][+-]\d+';
my %args;
foreach my $arg (@args) {   
    my ($key, $value) = $arg =~ /^(tol|pix)=(.*)$/;
    $args{$key} = $value;
}
my $tolerance = $args{'tol'} || 1.0;


die "tolerance must be in decimal or exponential form\n" 
    unless $tolerance=~/^($number|$enumber)$/;

#die "$tolerance $pix\n";


###    read in file1
my @data1;
open (FILE1, "$file1");
while (<FILE1>) {
    next if /^\#/;
    my ($x1, $y1) = (split)[$xcol1-1, $ycol1-1];
    my $line1 = $_;
    chomp $line1;
    push @data1, [$x1, $y1, $line1, 0];
}
close(FILE1);


###    read in file2
my @data2;
open (FILE2, "$file2");
while (<FILE2>) {
    next if /^\#/;
    my ($x2, $y2) = (split)[$xcol2-1, $ycol2-1];
    my $line2 = $_;
    chomp $line2;
    push @data2, [$x2, $y2, $line2, 0];
}
close(FILE2);


# double loop to find matches
my @matched;
my @unmatch1;
my @unmatch2;
my @doubmatch1;
my @doubmatch2;
foreach my $src1 (@data1) {

    my ($x1, $y1, $line1, $nmatch1) = @$src1;
    foreach my $src2 (@data2) {
	my ($x2, $y2, $line2, $nmatch2) = @$src2;
	
	my $r = sqrt( ($x2-$x1)**2 + ($y2-$y1)**2 );

	if ($r<$tolerance) {
	    push @matched, [$line1, $line2];
	    $$src1[3]++;
	    $$src2[3]++;
	}

    }
}


# output
foreach my $match (@matched) {
    my ($line1, $line2) = @$match;
    printf "%s %s\n", $line1, $line2;
}

exit 0;
