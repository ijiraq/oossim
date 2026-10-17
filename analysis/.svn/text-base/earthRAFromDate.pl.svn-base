#! /usr/bin/perl

use strict;
use warnings;
use File::Basename;
use Local::Astrotools;


my $exe = basename($0);
my $usage = 
    "Usage: $exe obsDate flag[JD for Julian Date, nothing for standard date YYYY/MM/DD]";

my ($obsDate, $flag) = @ARGV;
die $usage unless $obsDate;
$flag = "" unless $flag;

if ($flag eq "JD") {

    my $earthRA = earthRAFromDate($obsDate);

    print STDOUT "obsdate: $obsDate , earthRA: $earthRA\n";
} else {
    my ($year, $month, $day) = split(/\//, $obsDate);
    my $JD = calendar2JD($year, $month, $day);
    my $earthRA = earthRAFromDate($JD);
    my $sunRA = sunTrueLongJ2000($JD);

    print STDOUT "obsdate: $JD , earthRA: $earthRA , sunRA: $sunRA\n";
}
