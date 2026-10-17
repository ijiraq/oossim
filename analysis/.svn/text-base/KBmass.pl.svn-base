#!/usr/bin/env perl
#
# program KBmass.pl 
#
#  a perl script used to calculate the mass of the kuiper belt
#  given a slope for the size distribution and a minimum size.
#

use strict;
use warnings;
use File::Basename;

use Local::KBOdensity;
use Local::Constants;
use Local::Units;
use Local::Misc;

my $exe = basename($0);


die "Usage: $exe"  if ( @ARGV and $ARGV[0] =~ /help/ );  

my $r_min = 1.0; # 1 metre

# minimum diameter (km) to integrate to.
my @DMin       = (0.04, 0.08, 0.12, 0.16, 0.2, 0.3, 0.32, 0.4,
		  0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 
		  1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2.0, 2.2, 2.5,
		  3.0, 3.5, 4.0, 4.5, 5.0, 6.0, 7.0, 10.0, 
		  15.0, 20.0
		  ); 

# const for D^(-q)  ie. the slope of the size distrib.
my @q     = ( 4.2, 4.4, 4.6, 4.8, 5.0 );


##############################################################################
# print a header

# a different title line for each mode 
my $termwidth = 80;
my $t1 = centreText("Mass of KB larger than R_min=$r_min km for $q[0]<q<$q[-1] [Mearth]",$termwidth);

printf STDOUT "\n#$t1\n";

# print the q values across the top
printf STDOUT "#%s (q) \n"," "x40;
printf STDOUT "#R_knee";
foreach my $q (@q) {printf STDOUT "%10.1f",$q; }
printf STDOUT "\n#%-80s\n", "-"x($termwidth-1);

######   Main loop   #####################################
# loop over all the DMin
foreach my $DMin (map {1000.0*$_} @DMin) {

    # loop over all the q's
    my $r_knee = $DMin / 2.0;

    # print a row label
    printf STDOUT "%5d",$r_knee;

    foreach my $q (@q) {

	# get the mass of the KB and convert KG to earth masses
	my $KBmass = KBmass( $r_min, $r_knee, $q ) / $Me_KG;

	# output the values based on the mode used
	my $chars = 6;
	my $format = "%.2f";
	$format = labelFormat ($KBmass,$chars);

	printf STDOUT "%4s$format", " ", $KBmass;

    }
    printf STDOUT "\n";
}
printf STDOUT "\n";
