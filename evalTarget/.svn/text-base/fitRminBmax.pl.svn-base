#!/usr/bin/env perl
#
# original filename: getRate.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Thu May 22, 2008  10:51:24 DST
#  Host: captive-wireless-250-139.ncsa.uiuc.edu
#  Working Directory: /Users/bick/working/aperture_test
#


use strict;
use warnings;
use File::Basename;

use Local::Constants;
use Local::Astrotools;
use Local::KBOdensity;
use Local::Elong2v;
use Local::Stardata;

my $exe = basename($0);
my $usage = "Usage: $exe stardb dist AU aperture OCOpowerform prefix\n";

my ($stardb, $dist, $AU0, $ap, $OCOpowerform, $elong, $prefix) = @ARGV;
die $usage unless $ap;
my $AUstr = sprintf "%04d", $AU0;
$OCOpowerform = 0 unless $OCOpowerform;

my $number = '[+-]?\d+\.?\d*[eE]?[+-]?\d+?';
my ($prefix_title, $prefix_entry);
if ($prefix) {
  ($prefix_title, $prefix_entry) = $prefix =~ /^(.*)($number)$/;
} else {
  ($prefix_title, $prefix_entry) = ('--', -1);
  $prefix = "";
}

die "OCOpowerform must be 0 (broken) or 1 (uniform)\n" 
  unless $OCOpowerform=~/^[01]$/;

sub log10($) {return log($_[0])/log(10.0); }


my $incl = 0.0;
my ($q, $q_doh, $rknee) = (4.6, 3.0, 25000.0);
my $min_nonzero = 20; #min # of nadd!=0 in .stat file
my ($lam) = 5.5e-7;
my $fsu = sqrt($lam * $AU0 * $AU_M/2.0);

# count the number of each star
my %mk;
open(STARDB, "$stardb");
while(<STARDB>) {
  next if /^\#/;
  my ($mk, $V, $BmV, $Teff, $Mv, $Rstar_rad, $flux) = split;
  if (-d "$mk") {
    if ($mk{$mk}) {
      $mk{$mk} += 1;
    } else {
      $mk{$mk} = 1;
    }
  }
}
close(STARDB);


# get the rates
my %outstrings;
my %rates;
my %n;
my %mklimit;

my @mktypes = ();
foreach my $mk ( glob("[OBAFGKM][0-9]V") ) {
  push @mktypes, [$mk, $star{$mk}{Teff}];
}
@mktypes = sort {$b->[1] <=> $a->[1]} @mktypes;

my $out_prefix = "rmin_bmax_DB";
foreach my $ref ( @mktypes ) {

  my ($mk, $Teff) = @$ref;
  chdir $mk;

  foreach my $tsfile ( glob("ts*.fits") ) {

    my ($aperture, $AUts) = $tsfile =~ /ts(\d\.\d\d\d).(\d\d\d\d).fits/;
    next unless $aperture =~ /$ap/ and $AUts =~ /$AU0/;
    

    my ($dummy, $dummy2, $rms) = split /\s+/, `cstats -rs $tsfile`;
    my $Rstarproj = $AU0 * $AU_M * ($star{$mk}{'R'} * $Ro_M) / ($dist * $PC_M);
    my $RstarFsu = $Rstarproj / $fsu;

    # -- get b_max and r_min from .stat file
    my $statfile = ${tsfile}.".stats";
    my $nonzero = 0;
    open(STAT, "$statfile");
    while(<STAT>) {
      next if /^\#/;
      my @line = split;
      $nonzero += 1 if $line[4] > 0;
    }
    close(STAT);
    
    my ($rmin, $bmax, $vret, $rwid, $bwid, $r0, $b0, $recov_frac, $s, $rbreak)= 
      (-1, 0.0, 0.0, 0.0, 0.0, -1, 0.0, 0.0, 1.0, -1);
    if ($nonzero > $min_nonzero) {
      my $rb_cmd = "rmin_bmax_from_stats $statfile";
      ($rmin, $bmax, $vret, $rwid, $bwid, $r0, $b0, $recov_frac, $s, $rbreak) = split /\s+/, `$rb_cmd`;
    }
    
    open(OUTFILE, ">${out_prefix}_${aperture}_${AUts}.dat");
    printf OUTFILE "# rmin bmax vret rwid bwid r0 b0 recov_frac s rbreak rms rstarFsu\n";
    printf OUTFILE "$rmin $bmax $vret $rwid $bwid $r0 $b0 $recov_frac $s $rbreak $rms $RstarFsu\n";
    close(OUTFILE);

    printf STDOUT "Done $mk $tsfile\n";
  }
  chdir "../";
}

exit 0;
