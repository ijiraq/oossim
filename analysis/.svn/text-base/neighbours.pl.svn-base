#!/usr/bin/env perl
#
# original filename: neighbours.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Wed July 23, 2007  13:49:57 DST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/analysis
#
#  Find the N nearest neighbours of id,x,y values in a file.

use strict;
use warnings;
use File::Basename;

my $exe = basename($0);
my $usage = "Usage: $exe file N idx:cx:cy [pix=%.f]\n".
    "\n".
    "   idx:cx:cy: column numbers for the ID and x,y coordinates in file\n".
    "   N:     The number of neighbours to return\n".
    "   pix:   the pixel size for the units used as a decimal number\n".
    "          default = 1  (ie. pixel units assumed)\n";

my ($file, $N, $col, @args) = @ARGV;
die $usage unless $col;

my ($icol, $xcol, $ycol) = $col =~ /^(\d+):(\d+):(\d+)$/;

die "icol not defined\n".$usage unless $icol;
die "xcol not defined\n".$usage unless $xcol;
die "ycol not defined\n".$usage unless $ycol;

my $number = '[+-]?\d+\.?\d*';
my $enumber = ${number}.'[eE][+-]\d+';
my %args;
foreach my $arg (@args) {   
    my ($key, $value) = $arg =~ /^(tol|pix)=(.*)$/;
    $args{$key} = $value;
}
my $pix       = $args{'pix'} || 1.0;

die "pix must be in decimal or exponential form\n" 
    unless $pix=~/^($number|$enumber)$/;

my $rmin = 1.0e-12;

###    read in file   #################################################
my (@data, %data2);
open (FILE, "$file") or die "file: $file could not be opened: $!\n";
while (<FILE>) {
    next if /^\#/;
    my ($ID, $x, $y) = (split)[$icol-1, $xcol-1, $ycol-1];

    # break the data into cells of size 'pix'
    ($x, $y) = map {$_/$pix} ($x,$y);
    
    # put a list in an array
    push @data, [$ID, $x, $y];

    # store the same info in a hash by coordinate
    my $xi = sprintf "%d",$x;
    my $yi = sprintf "%d",$y;
    push @{$data2{$xi}{$yi}}, [$ID, $x, $y];

}
close(FILE);

# find neighbours  ###################################################
my %neighbours;
foreach my $src (@data) {

    my ($ID, $X, $Y) = @$src;

    my $k = 0;  # ring number
    my $n = 0;  # number of neighbours within ring k
    my @neighbours;
    my $finished = 0;


    # we'll look in rings of "cells" progressively farther out.
    while (!$finished) {
	
	# put this at the beginning 
	$finished = 1 if ($n > $N);  
	
	# choose the cells to search in this (the k'th) ring
	my @pairs;
	foreach my $k2 (-$k .. $k) {
	    foreach my $k3 (-$k .. $k) {		
		my $r = sqrt($k2*$k2 + $k3*$k3);
		if ( ($k-$r)>=0.0 && ($k-$r)<1.0 ) {
		    push @pairs, [$k2,$k3];
		}
	    }
	}
	
	# go to each cell in this ring and append it's members to the list
	foreach my $coordref (@pairs) {

	    my ($i, $j) = @$coordref;
	    my $xi = sprintf "%d", ($X+$i);
	    my $yi = sprintf "%d", ($Y+$j);

	    if ( $data2{$xi}{$yi} ) {
		
		foreach my $member (@{$data2{$xi}{$yi}}) {
		    
		    my ($id, $x, $y) = @$member;
		    my $r = sqrt( ($x-$X)**2 + ($y-$Y)**2 );
		    
		    next if $r < $rmin;
		    push @neighbours, [$id, $r];
		    $n++;
		}
	    }
	}
	$k++;
    }

    # sort the list by radius and take the nearest N entries
    @neighbours = map {$_->[0]} sort {$a->[1] <=> $b->[1]} @neighbours;
    push @{$neighbours{$ID}}, @neighbours[0..$N-1];
}

# output
foreach my $ID (sort {$a<=>$b} keys %neighbours) {
    printf "%s", $ID;
    foreach my $match ( @{$neighbours{$ID}} ) {
	printf " %s", $match;
    }
    printf "\n";
}

exit 0;
