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
my $usage = "Usage: $exe file1 file2 cx1:cy1[:ct1] cx2:cy2[:ct2] [tol=x:y[:t]] [pix=x:y[:t]]\n".
    "\n".
    "   cx1:cy1[:cy1]: column numbers for the x,y[,t] coordinates in file 1\n".
    "   tol:   the tolerances as decimal numbers\n".
    "          default = 1:1:1 (ie. within 1 unit as defined by \'pix\')\n".
    "   pix:   the pixel size for the units used as decimal numbers\n".
    "          default = 1:1:1  (ie. pixel units assumed)\n".
    "   o1=co1:co2:... : the output columns from file 1\n".
    "\n".
    "   -->RA/Dec in hh/deg use pix=1.8e-5:2.7e-4 (that's 1 arcsec cells)\n".
    "   -->Pixels use defaults\n".
    "   -->RA/Dec in deg/deg use pix=2.7e-4:2.7e-4 (1 arcsec)\n";

my ($file1, $file2, $col1, $col2, @args) = @ARGV;
die $usage unless $col2;

my ($xcol1, $ycol1, $tcol1) = $col1 =~ /^(\d+):(\d+):?(\d+)?$/;
my ($xcol2, $ycol2, $tcol2) = $col2 =~ /^(\d+):(\d+):?(\d+)?$/;

die "xcol1 not defined\n".$usage unless $xcol1;
die "xcol2 not defined\n".$usage unless $xcol2;
die "ycol1 not defined\n".$usage unless $ycol1;
die "ycol2 not defined\n".$usage unless $ycol2;

my $dim1 = ($xcol1 ? 1 : 0) + ($ycol1 ? 1 : 0) + ($tcol1 ? 1 : 0);
my $dim2 = ($xcol2 ? 1 : 0) + ($ycol2 ? 1 : 0) + ($tcol2 ? 1 : 0);

die "Need same number of dimensions for each file.\n" unless $dim1 == $dim2;

my $dimension = $dim1;

my $number = '[+-]?\d+\.?\d*';
my $enumber = ${number}.'[eE][+-]\d+';
my %args = ( 'tol' => "1.0:1.0:1.0",  'pix' => "1.0:1.0:1.0" );
foreach my $arg (@args) {   
    my ($key, $value) = $arg =~ /^(tol|pix|o1|o2)=(.*)$/;
    $args{$key} = $value;
}
my @tolerance = split /:/, $args{'tol'};
my @pix       = split /:/, $args{'pix'};
my @out1      = map {$_-1} split /:/, $args{'o1'} if $args{'o1'};
my @out2      = map {$_-1} split /:/, $args{'o2'} if $args{'o2'};


($tolerance[2],$pix[2]) = (1.0, 1.0) unless $dimension == 3;

foreach my $i (0 .. $dimension-1) {
    die "tolerances must be in decimal or exponential form\n" 
	unless $tolerance[$i]=~/^($number|$enumber)$/;
    die "pix values must be in decimal or exponential form\n" 
	unless $pix[$i]=~/^($number|$enumber)$/;
}



###    read in file1
my @data1;
open (FILE1, "$file1") or die "file: $file1 could not be opened: $!\n";
while (<FILE1>) {
    next if /^\#/;
    my ($x1, $y1, $t1);
    if ($dimension==2) {
	($x1, $y1) = (split)[$xcol1-1, $ycol1-1];
	$t1 = 1.0;
    } elsif ($dimension==3) {
	($x1, $y1, $t1) = (split)[$xcol1-1, $ycol1-1, $tcol1-1];
    }
    next unless defined $x1 and defined $y1 and defined $t1;

    my $line1 = (@out1) ? join(" ",(split)[@out1]) : $_;
    ($x1, $y1, $t1) = ($x1/$pix[0], $y1/$pix[1], $t1/$pix[2]);
    chomp $line1;
    push @data1, [$x1, $y1, $t1, $line1, 0];
}
close(FILE1);


###    read in file2
my %data2;
open (FILE2, "$file2") or die "file: $file2 could not be opened: $!\n";
while (<FILE2>) {
    next if /^\#/;
    my ($x2, $y2, $t2);
    if ($dimension==2) {
	($x2, $y2) = (split)[$xcol2-1, $ycol2-1];
	$t2 = 1.0;
    } elsif ($dimension==3) {
	($x2, $y2, $t2) = (split)[$xcol2-1, $ycol2-1, $tcol2-1];
    }
    next unless defined $x2 and defined $y2 and defined $t2;

    my $line2 = (@out2) ? join(" ",(split)[@out2]) : $_;
    chomp $line2;
    ($x2, $y2, $t2) = ($x2/$pix[0], $y2/$pix[1], $t2/$pix[2]);
    my ($x2i,$y2i,$t2i) = map {sprintf "%d",$_} ($x2,$y2,$t2);
    $data2{$x2i}{$y2i}{$t2i} = [$x2, $y2, $t2, $line2, 0];
}
close(FILE2);


# double loop to find matches
my @matched;
my @unmatch1;
my @unmatch2;
my @doubmatch1;
my @doubmatch2;
my @klist = ($dimension==2) ? (0) : (-1, 0, 1);
foreach my $src1 (@data1) {

    my ($x1, $y1, $t1, $line1, $nmatch1) = @$src1;
    
    foreach my $i (-1, 0, 1) {
	foreach my $j (-1, 0, 1) {
	    foreach my $k (@klist) {
		my ($x1i,$y1i,$t1i) = map {sprintf "%d",$_} ($x1+$i,$y1+$j,$t1+$k);
		if ( $data2{$x1i}{$y1i}{$t1i} ) {
		    
		    my ($x2, $y2, $t2, $line2, $nmatch2) = 
			@{$data2{$x1i}{$y1i}{$t1i}};
		    #my $r = sqrt( ($x2-$x1)**2 + ($y2-$y1)**2 );
		    
		    if ( abs($x2-$x1) < $tolerance[0] && 
			 abs($y2-$y1) < $tolerance[1] &&
			 abs($t2-$t1) < $tolerance[2] ) {
			push @matched, [$line1, $line2];
			$$src1[3]++;
			${$data2{$x1i}{$y1i}{$t1i}}[4]++;
		    }
		}
	    }
	}
    }

}


# output
foreach my $match (@matched) {
    my ($line1, $line2) = @$match;
    printf "%s %s\n", $line1, $line2;
}

exit 0;
