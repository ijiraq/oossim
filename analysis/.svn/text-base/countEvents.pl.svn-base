#!/usr/bin/env perl
#
# original filename: countEvents.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Wed May 30, 2007  11:36:47 DST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/analysis
#


use strict;
use warnings;
use File::Basename;

use Local::Constants;
use Local::Astrotools;

my $exe = basename($0);
my $usage = "Usage: $exe eventfile\n";

my ($efile) = @ARGV;
die $usage unless $efile;

my $t_step = 0.025;
my %events;
### read in the events
###################################################################
if ( defined($efile)  and  -s $efile ) {
    open (EVENTS, "$efile");

    while (<EVENTS>) { 
	next if /^\#/; 
	
	my $t_limit = 1.0;

	my @record = split;
	my ($RStar, $aa, $AU, $offset, 
	    $icor, $mgcor, $cor0, $corN, 
	    $ichi, $mgchi, $chi0, $chiN) = @record;
	
	$mgcor = 1e-9 if $mgcor==0.0;
	$cor0 = 1e-9 if $cor0==0.0;
	$mgchi = 1e-9 if $mgchi==0.0;
	$chi0 = 1e-9 if $chi0==0.0;
	my $cor_ratio = ($mgcor>$cor0) ? $cor0/$mgcor : $mgcor/$cor0;
	my $chi_ratio = ($mgchi>$chi0) ? $chi0/$mgchi : $mgchi/$chi0;
	my $rank = $mgcor*$cor_ratio + abs($mgchi*$chi_ratio);
	my $time = sprintf "%.3f", $icor*$t_step;
	push @record, ($time, $rank);
	
	# if it's close to one that we already have, put it with that one
	my $t_key = $time;
	foreach my $existingT (keys %events) {
	    $t_key = $existingT if ( abs($time-$existingT) < $t_limit );
	}
	
	push @{$events{$t_key}}, [@record];	
	
    }
    close (EVENTS);

    die "No events in $efile ... exiting\n" unless (keys %events);
}


printf "${efile}: %d\n", scalar keys %events;

exit 0;
