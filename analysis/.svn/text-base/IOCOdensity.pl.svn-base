#!/usr/bin/env perl
#
#

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
use Local::IOCOdensity;

my $usage = "usage: $0 rad(m)\n";
my ($r_in) = @ARGV;
die $usage unless $r_in;

printf STDOUT "%.4g %.4g\n", IOCOdensity($r_in);

exit (0);

