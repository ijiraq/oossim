#!/usr/bin/env perl
#
# original filename: numConvert.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Mon Oct 16, 2006  11:27:03 DST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/utility
#


use strict;
use warnings;
use File::Basename;


my $exe = basename($0);
my $usage = "Usage: $exe number\n";

my ($number) = @ARGV;
die $usage unless defined $number;

my $b10 = ($number=~/^0/) ? oct($number) : $number;
$b10 = ord($number) unless $b10;

my $bin = sprintf "0b%b", $b10;
my $oct = sprintf "0%o", $b10;
my $hex = sprintf "0x%x", $b10;
my $cha = sprintf "\'%c\'", $b10;
$cha = "%%" if $cha=~/\%/;

printf STDOUT "$b10  ==   $bin   $oct   $hex    ascii $cha\n";


exit 0;
