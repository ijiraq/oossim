#!/usr/bin/env perl
#
# original filename: starInfo.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Sun Mar 19, 2006  18:44:31 EST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/analysis
#

use strict;
use warnings;
use File::Basename;

use lib "$ENV{HOME}/libperl";
use Local::Constants;
use Local::Stardata;
use Local::Units;
use Local::Misc;

my $exe = basename($0);
my $usage = "Usage: $exe spectype\n";

my ($mk) = @ARGV;
die $usage unless $mk;

# get the general info about the spec type
my $Teff    = $star{$mk}{"Teff"};
my $L       = $star{$mk}{"L"};
my $R       = $star{$mk}{"R"};
my $M       = $star{$mk}{"M"};
my $Mbol    = $star{$mk}{"Mbol"};
my $BC      = $star{$mk}{"BC"};
my $Mv      = $star{$mk}{"Mv"};
my $UmB     = $star{$mk}{"UmB"};
my $BmV     = $star{$mk}{"BmV"};


# output

printf STDOUT "\n*** %s star ***\n", $mk;
printf STDOUT "Teff = %7s K\n", $Teff;
printf STDOUT "L    = %7s Lo\n", $L;
printf STDOUT "R    = %7s Ro\n", $R;
printf STDOUT "M    = %7s Mo\n", $M;
printf STDOUT "Mbol = %7s\n", $Mbol;
printf STDOUT "BC   = %7s\n", $BC;
printf STDOUT "Mv   = %7s\n", $Mv;
printf STDOUT "UmV  = %7s\n", $UmB;
printf STDOUT "BmV  = %7s\n\n", $BmV;

exit 0;
