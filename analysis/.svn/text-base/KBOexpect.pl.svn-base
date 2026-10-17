#!/usr/bin/env perl
#
# program KBOexpect.pl 
#
#  a perl script used to calculate the density of kuiper belt objects
#  given a slope for the size distribution and a minimum size.
#

use strict;
use warnings;
use File::Basename;

use Local::KBOdensity;
use Local::Constants;
use Local::Elong2v;
use Local::Units;
use Local::Misc;

my $exe = basename($0);


die "Usage: $exe [options]\n".
    "Options: elong=(d)   -- d in degrees\n".
    "         rknee=(m)   -- m in metres\n".
    "         lambda=(m)  -- m in metres\n".
    "         RStar=(m)   -- m in metres\n".
    "         mode=N      -- N = 1,2,3,4,5 (see below)\n".
    "         ttot=(s)    -- s in seconds\n".
    "         percent=(p) -- (0 < p < 1.0)\n".
    "\n".
    "mode1: N per sqr arcsec\n".
    "mode2: prob of occultation per star per hour\n".
    "mode3: Num. of starhrs for 95% cert. of 1 or more occultations\n".
    "mode4: Num. of starhrs for 50% cert. of 1 or more occultations\n".
    "mode5: Num. of starhrs for (percent)% cert. of 1 or more occultations\n"
    if ( @ARGV and $ARGV[0] =~ /help/ );  

# set defaults
my $elong  = 180.0;
my $r_knee = 25000;
my $lambda = 5.5e-7;
my $RStar  = 1;
my $mode   = 3;
my $percent= 0.95;
my $ttot   = 3600; # seconds

foreach my $arg (@ARGV) {
    ($elong) = $arg =~ /^elong=(.*)/ if $arg =~ /^elong=(.*)/;
    ($r_knee) = $arg =~ /^rknee=(.*)/ if $arg =~ /^rknee=(.*)/;
    ($lambda)=  $arg =~ /^lambda=(.*)/ if $arg =~ /^lambda=(.*)/;
    ($RStar) = $arg =~ /^RStar=(.*)/ if $arg =~ /^RStar=(.*)/;
    ($mode)  = $arg =~ /^mode=(.*)/ if $arg =~ /^mode=(.*)/;
    ($ttot)  = $arg =~ /^ttot=(.*)/ if $arg =~ /^ttot=(.*)/;
    ($percent)=$arg =~ /^percent=(.*)/ if $arg =~ /^percent=(.*)/;
}

# set some constants
my $AU   = 40;
my $t = ($mode==2) ? $ttot : 3600;
my $vRet = sprintf "%.3f", abs( elong2v($PI*$elong/180.0, $AU) );

# mode 1:  N per sqr arcsec
# mode 2:  p of occ. per star per hour
# mode 3:  starhours for 95% certainty of 1 or more detections
# mode 4:  starhours for 50% certainty of 1 or more detections
# mode 5:  starhours for $percent certainty of 1 or more detections

# minimum diameter (km) to integrate to.
my @DMin       = (0.02, 0.03, 0.04, 0.05, 0.06, 0.08, 0.12, 
		  0.16, 0.2, 0.3, 0.32, 0.4,
		  0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 
		  1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2.0, 2.2, 2.5,
		  3.0, 3.5, 4.0, 4.5, 5.0, 6.0, 7.0, 10.0, 
		  15.0, 20.0
		  ); 

# const for D^(-q)  ie. the slope of the size distrib.
my ($qmin, $qinc, $nq) = (2.6, 0.2, 7);
my @q     = map { $qmin + $qinc * $_ } ( 0 .. $nq-1 );
my $q1 = 4.6;




##############################################################################
# print a header

my $r_knee_km = sprintf "%.1f", $r_knee/1000.0;
my $vRet_kps  = sprintf "%.3f", $vRet/1000.0;
my $RStar_km = sprintf "%.3f", $RStar/1000.0;

# a different title line for each mode 
my $termwidth = 80;
my $lambdaS = sprintf "%3d", $lambda*1e9;
my $confidence = ($mode=~/3/) ? "95" : "50";
$confidence = $percent*100 if $mode==5;

my $t_vars = centreText("v=$vRet_kps km/s, d=$AU AU, r_knee=${r_knee_km}km, lamb=$lambdaS nm, R*(40)=$RStar_km km",$termwidth);

my $t1 = centreText("Density of KBOs larger than R_min for $q[0]<q<$q[-1] (per Sqr Arcsec)",$termwidth);

my $t2 = centreText("Occultation probability for KBOs larger than R_min for $q[0]<q<$q[-1]",$termwidth);

my $t3a = centreText("Star-hours observation to see 1 (or more) occultations of KBOs larger",$termwidth);
my $t3b = centreText("than R_min for $q[0]<q<$q[-1]  (${confidence}%% confidence)",$termwidth);


printf STDOUT "\n$t1\n" if ($mode =~ /1/ );
printf STDOUT "\n$t2\n\$t_vars\n" if ($mode =~ /2/);
printf STDOUT "\n$t3a\n$t3b\n${t_vars}\n" if ($mode=~/[345]/);


# print the q values across the top
printf STDOUT "%s (q) \n"," "x40;
printf STDOUT "R_min";
foreach my $q (@q) {printf STDOUT "%10.1f",$q; }
printf STDOUT "\n%-80s\n", "-"x80;

###########################################################################

# use the functions that use Poisson stats
my $expectTime   = \&expectTimePois;
my $KBOprob      = \&KBOpoisProb;



######   Main loop   #####################################
# loop over all the DMin
foreach my $DMin (map {1000.0*$_} @DMin) {

    # loop over all the q's
    my $r_min = $DMin / 2.0;

    my $DEff = DEffective($DMin, $AU, $lambda, $RStar);  # in meters
    my $bmax = $DEff/2.0;

    # print a row label
    printf STDOUT "%5d",$r_min;

    foreach my $q_doh (@q) {

	# get the density per sqr arcsec and probability of occultation
	my $nSas = KBOdensity( $r_min, $r_knee, $q1, $q_doh );
	my $p    = $KBOprob->( $nSas, $bmax, $vRet, $AU, $lambda, $t, $RStar );

	# if p > 0.999...( double precision) it'll use 1.0 and die
	#   set a threshhold here
	#  NOTE - this should never happen with the Poisson functions
	my $lt = "";
	my $limit = 0.999_999_999_999_999;
	if ($p> $limit) {
	    $lt = "<";
	    $p = $limit;
	}

	# get the expectation times and convert them to reasonable units
	my $t50 = $expectTime->( $bmax, $vRet, $nSas, $AU, 0.50 );
	my $t95 = $expectTime->( $bmax, $vRet, $nSas, $AU, 0.95 );
	my $tXX = ($percent) ? 
	    $expectTime->( $bmax, $vRet, $nSas, $AU, $percent ) : $t95;

	my $t50S = timeUnits( $t50, "s");
	my $t95S = timeUnits( $t95, "s");
	my $tXXS = timeUnits( $tXX, "s");

	# output the values based on the mode used
	my $chars = 6;
	my $format = "%.2f";
	$format = labelFormat ($nSas,$chars)      if ($mode =~ /1/);
	$format = labelFormat ($p,$chars)         if ($mode =~ /2/);

	printf STDOUT "%4s$format", " ", $nSas    if ($mode =~ /1/);
	printf STDOUT "%4s$format", " ", $p       if ($mode =~ /2/);
	printf STDOUT "%10s", $lt.$t95S           if ($mode =~ /3/);
	printf STDOUT "%10s", $lt.$t50S           if ($mode =~ /4/);
	printf STDOUT "%10s", $lt.$tXXS           if ($mode =~ /5/);

    }
    printf STDOUT "\n";

}
printf STDOUT "\n";
