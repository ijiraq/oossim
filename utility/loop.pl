#!/usr/bin/env perl
#
# original filename: loop.pl
#
# purpose: to execute a command with one of the arguments varied over a 
#          given range
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Thu Jul 20, 2006  9:30:58 DST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/utility
#

use strict;
use warnings;
use File::Basename;

use lib "$ENV{HOME}/libperl";
use Local::Constants;

my $exe = basename($0);
my $usage = "\n".
    "Usage: $exe \"command args ... \" x1lo:x1hi:x1inc x2lo:x2hi:x2inc [supressx]\n".
    "eg. 1> $exe \"elong2v x1 AU\" 80:180:1\n".
    "    2> $exe \"elong2v x1 x2\" 80:180:1 30:50:2\n".
    "    3> $exe \"generate 'x1*sin(\\\$x)' '-\\\$PI' '\\\$PI' uniform %.3f 100 0.0\" 1:5:1 0\n".
    "\n".
    "--> x1, and x2 will be replace with the next value in the loop for \n".
    "    each execution of the command\n".
    "--> boolean suppressx will cause x1 and x2 not to be printed if set\n".
    "--> Note escaping of \$ in ex.3 (they're not ENV variables) \n".
    "\n";

my $number = '[+-]?\d+\.?\d*';
my ($command, $x1string, $x2string, $suppressx) = @ARGV;
die $usage unless $x1string;
die "Problem with x1string: $x1string\n$usage" 
    unless $x1string =~ /^${number}:${number}:${number}$/;

if (defined $x2string  && $x2string =~ /^[01]$/) {
    $suppressx = $x2string;
    undef $x2string;
} elsif (defined $x2string && $x2string !~ /^${number}:${number}:${number}$/ ) {
    die "Problem with x2string: $x2string\n$usage";
}

$suppressx = 0 unless defined $suppressx;

# parse the ranges
my ($x1lo, $x1hi, $x1inc) = split /:/,$x1string;
my ($x2lo, $x2hi, $x2inc) = split /:/,$x2string if $x2string;

my $Nx1 = int( ($x1hi - $x1lo)/$x1inc );
my $Nx2 = ($x2string) ? int( ($x2hi - $x2lo)/$x2inc ) : (0);

printf STDERR "\n";
foreach my $x2i (0 .. $Nx2) {

    my $x2 = ($x2string) ? ($x2lo + $x2inc*$x2i) : "";
    foreach my $x1i (0 .. $Nx1) {

	my $x1 = $x1lo + $x1inc*$x1i;

	my $cmd = $command;

	for ($cmd) {
	    s/x1/$x1/g;
	    s/x2/$x2/g;
	}
	
	my $output = `$cmd`;
	$output =~ s/\%/\%\%/g;  # there might be percents in a header.
	chomp $output;
	printf STDOUT ($suppressx) ? "$output\n" : "$x1 $x2 $output\n";

	printf STDERR "\t\t %d / %d       %d / %d\r".
	    "", $x1i+1, $Nx1+1, $x2i+1, $Nx2+1;
    }
    printf STDOUT "\n";
}
printf STDERR "\n";

exit 0;
