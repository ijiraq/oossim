#!/usr/bin/env perl
#
# original filename: calc.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Thu Jan 31, 2008  13:28:35 EST
#  Host: bender.astro.princeton.edu
#  Working Directory: /Users/bick/sandbox/analysis
#


use strict;
use warnings;
use File::Basename;

use Local::Constants;
use Local::Astrotools;
use Local::Physics;

my $exe = basename($0);
my $usage = "Usage: $exe expression\n";

my ($expression, $form) = @ARGV;
die $usage unless $expression;

$form = "%g" unless $form;
$form .= "\n";
printf STDOUT $form, eval($expression);

exit 0;
