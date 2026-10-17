#!/usr/bin/env perl
#
# original filename: pathStrip.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Fri Sep 28, 2007  19:20:03 DST
#  Host: bender.astro.princeton.edu
#  Working Directory: /Users/bick/sandbox/utility
#
use strict; 
use warnings;
while(<>) { 
    (my $s = $_) =~ s/(\w+\/)+/...\//g; 
    print $s; 
}
exit 0;
