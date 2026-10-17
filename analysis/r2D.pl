#!/usr/bin/env perl
#
#

use strict;
use warnings;

use lib "$ENV{HOME}/libperl";
use Local::Elong2v;
use Local::Constants;

my ($r, $elong) = @ARGV;
die "usage: $0 r[AU] elong\n" if ! $elong;

printf STDOUT "%.2f\n", r2D($r, $PI*$elong/180.0);
