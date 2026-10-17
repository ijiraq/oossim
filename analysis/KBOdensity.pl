#!/usr/bin/env perl
#
#

use strict;
use warnings;
use lib "$ENV{HOME}/libperl";
use Local::KBOdensity;

my ($r_min, $r_knee, $q, $q_doh) = @ARGV;
die "usage: $0 r_min[metres] r_knee[metres] q q_doh\n" if ! $q;

printf STDOUT "%.3g\n", KBOdensity($r_min, $r_knee, $q, $q_doh);
