#!/usr/bin/env perl
#
#

package Local::IOCOdensity;

use strict;
use warnings;

#use Getopt::Long;
#   my ($q_small, $q_large, $r_break, $r_max, $mass, $width) =
#     (3.0, 4.5, 25, 2.5e3, 3.0, 45.0);
#   GetOptions(
# 	     "q_small:f" => \$q_small, # help=Slope of the small-size past break
# 	     "q_large:f" => \$q_large, # help=Slope of the large-size past break
# 	     "r_break:f" => \$r_break, # help=Break radius, in kilometers
# 	     "r_max:f" => \$r_max,     # help=Radius of largest object to consider
# 	     "mass:f" => \$mass,       # help="Mass of disk, in Earth masses"
# 	     "width:f" => \$width      # help="Width of the particle belt"
# 	    );
    

use Local::Constants;


require  Exporter;
our @ISA       = qw( Exporter );
our @EXPORT    = qw( IOCOdensity );
our @EXPORT_OK = qw();
our @EXPORT_TAGS = ( ALL => [ @EXPORT_OK ], );
our $VERSION   = 1.00;


# -- globals -- 
my $rho = 0.8;                  # g cm-3
$rho = $rho * (1.0E5)**3.0/1.0E3;  # Put rho into kg/km3
my $r_min = 1.0;                # smallest object to consider, in km

## Sky Area of oort cloud (in square arcseconds)

sub CNDF($$$) {
    my ($r,$r0,$q) = @_;
    # return the cumulative number of objects
    return -($r0/(1.0-$q))*($r/$r0)**(1.0-$q);
}

sub CMDF($$$) {
    my ($r,$r0,$q) = @_;
    #return the cummulative mass
    if ($q < 4.0) {
	return (4.0/3.0)*$PI*$rho*(($r0**4.0)/(4.0-$q))*($r/$r0)**(4.0-$q);
    } else {
	return -(4.0/3.0)*$PI*$rho*(($r0**4.0)/(4.0-$q))*($r/$r0)**(4.0-$q);
    }
}


sub IOCOdensity($) {
  
  
  my ($q_small, $q_large, $r_break, $r_max, $mass, $width) =
    (3.0, 4.5, 25, 2.5e3, 3.0, 45.0);
  
  my ($r_in) = @_;
  $r_in /= 1000.0;

  ### a cheap, approximate, area scaling
  my $A = sqrt(2.0)*2.0*$PI*$ARCSECperRAD**2   * ($width/45.0);
  
  my $usage = "usage: $0 rad(m)\n";
  die $usage unless $r_in;
  
  ### Some constants....
  my $mass_oort = $mass*$Me_SI; ## oort cloud is 3 times mass of earth
  
  ## compute the value of r0 based on the desired mass of the belt
  ## ie.  Normallize this sucker, ie determine the r0 that, for the
  ## anticpated total mass, results in 1 object per unit area
  my $r0 = 1.0;
  my $total_mass = $A * CMDF($r_min,$r0,$q_large);
  $r0 =($mass_oort/$total_mass)**(1.0/$q_large);
  
  ### compute the density of objects per arcsecond2
  my $n_uniform = CNDF($r_in,$r0,$q_large);
  
  
  ### do the same thing, but now with a 'broken powerlaw'
  ### first compute the normalization again.
  ### we can't invert the problem this time, so look for a
  ### convergent solution.
  
  my $mass_total = 0.0;
  my $r_large = $r0;
  my $r_small = 1.0;
  while ( abs(($mass_total - $mass_oort)/$mass_oort) > 0.01 ) {
    
    if ($mass_total > $mass_oort) {
      $r_large = $r_large * 0.99;
    } else {
      $r_large = $r_large * 1.01;
    }
    
    ### set r_small so the function is smooth at r_break
    my $N_large = CNDF($r_break,$r_large,$q_large);
    $r_small = 1.0;
    my $N_small = CNDF($r_break,$r_small,$q_small);
    $r_small = ($N_large/$N_small)**(1.0/$q_small);
    $mass_total = $A * ( CMDF($r_min,$r_small,$q_small) - 
			 CMDF($r_break,$r_small,$q_small) + 
			 CMDF($r_break,$r_large,$q_large) );
    
  }                
  my $n_bpl = CNDF($r_in,$r_small,$q_small);
  return ($n_bpl, $n_uniform);
}
  
