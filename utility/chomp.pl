#!/usr/bin/env perl
#
# original filename: chomp.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Fri Jul 21, 2006  10:32:10 DST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/utility
#

use strict;
use warnings;
use File::Basename;

use lib "$ENV{HOME}/libperl";
use Local::Constants;

my $exe = basename($0);
my $usage = "Usage: command | $exe\n";

my $string = <STDIN>;
chomp $string;
printf STDOUT "$string";

exit 0;
