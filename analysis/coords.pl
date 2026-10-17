#!/usr/bin/env perl
#
#

use strict;
use warnings;
use lib "$ENV{HOME}/libperl";
use Local::Coords;

printf STDOUT "functions: \@dec_list = sex2dec(\@sex_list) \n".
    "           (\$deg, \$min, \$sec) = dec2sex(\$decimal) \n".
    "           \@sex_list = dec2sexS(\@decimal)\n\n".
    "           (\$l, \$b) = cel2gal(\$alpha, \$delta)\n".
    "           (\$alpha, \$delta) = gal2cel(\$l, \$b)\n".
    "           (\$lambda, \$beta) = cel2ecl(\$alpha, \$delta)\n".
    "           (\$alpha, \$delta) = ecl2cel(\$lambda, \$beta)\n";

exit 0;
