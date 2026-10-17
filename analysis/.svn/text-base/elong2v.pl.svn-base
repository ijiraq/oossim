#!/usr/bin/env perl
#
#

use strict;
use warnings;
use lib "$ENV{HOME}/libperl2";
use Local::Constants;
use Local::Elong2v;

my ($elong, $i, $AU) = @ARGV;
die "usage: $0 elong i AU\n" if ! $AU;

printf STDOUT "%.2f\n", elongi2v($RAD*$elong, $RAD*$i, $AU);

exit 0;
