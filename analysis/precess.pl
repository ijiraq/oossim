#!/usr/bin/env perl
#
# original filename: precess.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Thu Jul 20, 2006  10:48:02 DST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/analysis
#

use strict;
use warnings;
use File::Basename;

#use lib "$ENV{HOME}/libperl2";
use Local::Constants;
use Local::Astrotools;

my $exe = basename($0);
my $usage = "Usage: $exe RA Dec [date] [time]\n".
    "date format: yyyy-mm-dd.d\n".
    "time format: hh:mm:ss.s\n";

my ($alpha, $delta, $date, $time) = @ARGV;
die $usage unless $delta;

# use the date if given ... otherwise use today's date
my ($yr, $mon, $mday) = ($date) ? split /-/, $date : (localtime)[5,4,3];
$yr += 1900 unless $date;
$mon++ unless $date;

# use the time if given ... otherwise midnight of the date ... or current time
my ($hh, $mm, $ss) = (localtime)[2,1,0];
($hh, $mm, $ss) = (0,0,0) if $date;
($hh, $mm, $ss) = split /:/, $time  if $time;


my $outdate = sprintf "%04d-%02d-%02d  %02d:%02d:%05.2f", $yr, $mon, $mday, $hh, $mm, $ss;

my $JD = calendar2JD($yr, $mon, $mday, $hh, $mm, $ss);

my $is_hms = ( $alpha =~ /\d:\d\d:\d/ ) ? 1 : 0;
my ($alphaD, $deltaD) = ($is_hms) ? 
    hms2degRADec($alpha, $delta) : ($alpha, $delta);

my ($alphaP, $deltaP) = precess($alphaD, $deltaD, $JD2000, $JD);

($alphaP, $deltaP) = deg2hmsRADec($alphaP, $deltaP) if $is_hms;

printf STDOUT "$alphaP  $deltaP   $outdate  orig: $alpha $delta\n";

exit 0;
