#!/usr/bin/env perl
#
# original filename: makeFresFiles.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Thu May 22, 2008  12:40:30 DST
#  Host: captive-wireless-250-139.ncsa.uiuc.edu
#  Working Directory: /Users/bick/working/aperture_test
#


use strict;
use warnings;
use File::Basename;

use Local::Constants;
use Local::Astrotools;
use Local::Stardata;

my $exe = basename($0);
my $usage = "Usage: $exe dist lamlo lamhi AU Nrun(0 for all)\n";

my ($dist, $lamlo, $lamhi, $AU, $Nrun) = @ARGV;
die $usage unless $AU;

sub log10($) { return log($_[0])/log(10.0); }


my @rads;

if ( $AU < 50.0 ) {
  @rads = map {25*$_ + 50} (0..78);
  unshift @rads, (5, 10, 15, 20, 30, 40);
} elsif ( abs($AU-300.0) < 1) {
  @rads = map {100*$_ + 200} (0..78);
  unshift @rads, (20, 40, 60, 80, 120, 160);
}


$Nrun = map {$_=~/V/} (keys %star) if $Nrun ==0;
my $i = 0;
foreach my $mk (sort keys %star) {

  next unless $mk =~ /^[OBAFGKM][0-9]V$/;

  my $distmod = 5.0*log10($dist) - 5.0;
  my $V = $star{$mk}{'Mv'} + $distmod;

  my $Teff = $star{$mk}{'Teff'};

  (-d $mk) or mkdir $mk;
  chdir $mk;


  # make the fresnelFiles
  my $AUstr = sprintf "%04d", $AU;
  my $fresdir = "fresnelFiles${AUstr}";
  my $frespars = "params.fres";
  if (not -d $fresdir) {   #only make the files once
    mkdir $fresdir;
    chdir $fresdir;
    my $frespar_cmd = "writeFresParams $lamlo $lamhi $V $mk $AU > $frespars";
    system($frespar_cmd);
    foreach my $rad (@rads) {
      my $fres_cmd = "fresnelT $rad $Teff $frespars";
      print STDERR $fres_cmd."\n";
      system($fres_cmd);
    }
    
    chdir "../";
  }

  chdir "../"; 
  $i += 1;
  last if $i >= $Nrun;
}

exit 0;
