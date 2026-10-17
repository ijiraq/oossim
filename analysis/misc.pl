#!/usr/bin/env perl
#
#

use strict;
use warnings;
use lib "$ENV{HOME}/libperl";
use Local::Misc;

my $usage = "Functions: \$logOfvalue = log10(\$value)\n".
    "           \$string = timerBar(\$width, \$position, \$size)\n".
    "           \$string = labelFormat(\$value, \$chars)\n".
    "           \$string_centred = centreText(\$string, \$termwidth)\n";

printf STDOUT "$usage";
