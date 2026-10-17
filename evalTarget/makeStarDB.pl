#!/usr/bin/env perl
#
# original filename: makeStarDB.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Wed May 21, 2008  0:47:39 DST
#  Host: bender.local
#  Working Directory: /Users/bick/working/aperture_test
#


use strict;
use warnings;
use File::Basename;

use Local::Constants;
use Local::Astrotools;
use Local::Stardata;

my $exe = basename($0);
my $usage = "Usage: $exe infile dist(pc) Av Ebmv RA:Dec:V:BmV-columns FOV\n";


sub log10($) {return log($_[0])/log(10.0);}

my ($infile, $dist, $Av, $Ebmv, $columns, $FOV, $aperture, $hz) = @ARGV;
die $usage unless $FOV;

my @columns = split /:/, $columns;
foreach my $col (@columns) {
  die $usage unless $col=~/\d+/;
}
my ($RAcol, $Deccol, $Vcol, $BmVcol) = @columns;

my @spectypes = sort keys %star;
my $distmod = 5.0*log10($dist) - 5.0;

print STDERR "Building stellar catalogue from $infile\n";
open(MK, ">mk.dat");
printf MK "MK Mv  B-V\n";
foreach my $mk (@spectypes) {
  next unless $mk=~/..V/;
  printf MK "$mk %.2f %.2f\n", $star{$mk}{'Mv'}, $star{$mk}{'BmV'};
}
close(MK);

# read in the photometry
# need the center of the field for FOV calcs ... use awk to strip the whitespace
my ($RAmean, $Decmean) = (split /\s+/, `cstats -ms -c$RAcol:$Deccol $infile | awk '{print \$1,\$2}'`);

print STDERR "Done Building stellar catalogue inputs \n";
my $starDBfile = "starDB.dat";
open(INFILE, "$infile");
open(STARDB, ">$starDBfile");

printf STARDB "#%3s %6s %5s   %5s %5s %9s  %12s %5s ".
    "\n", "MK", "V", "B-V", "Teff", "Mv", "Rstar_rad", "flux", "MKcode";

while(<INFILE>) {
  next if /^\#/;
  my @line = split;
  my ($RA, $dec, $V, $BmV) = @line[$RAcol-1,$Deccol-1,$Vcol-1,$BmVcol-1];
  next unless ($RA and $dec and $V and $BmV);

  next if ( (abs($RA-$RAmean) > $FOV/2.0 ) or (abs($dec-$Decmean) > $FOV/2.0));
  

  my $Mv = $V -$Av - $distmod;
  $BmV -= $Ebmv;

  # -- loop over all star types and get the closest one
  my $min_mag_rad=20.0;
  my $mk_best;
  foreach my $mk (@spectypes) {
    next unless $mk=~/..V/;
    my $dV = $Mv - $star{$mk}{'Mv'};
    my $dBmV = $BmV - $star{$mk}{'BmV'};
    my $mag_rad = sqrt( $dV**2 + $dBmV**2 );
    if ($mag_rad < $min_mag_rad) {
      $min_mag_rad = $mag_rad;
      $mk_best = $mk;
    }
  }
  next unless $min_mag_rad < 1.0; # don't want to confuse different spec class

  my $Teff = $star{$mk_best}{'Teff'};
  my $Rstar_rad = ($star{$mk_best}{'R'} * $Ro_M) / ($dist * $PC_M);

  # don't need to redden these ... they're measured apparent mags
  my $fluxB = mag2flux('B', $V + $BmV); # phot per sec per m^2
  my $fluxV = mag2flux('V', $V);
  my $flux = $fluxB + $fluxV;

  #---------BEGIN TOM CODE---------------------
  my $base_dir = `pwd`;
  chop($base_dir);

  my $fluxCalc_dir = $ENV{FLUXCALC};
  die "FLUXCALC not defined\n" unless $fluxCalc_dir;
  die "Directory $fluxCalc_dir does not exist\n" unless (-d $fluxCalc_dir);

  chdir $fluxCalc_dir;

  open(MAKESPEC_PARS, ">$fluxCalc_dir/makespec.par");
  print MAKESPEC_PARS ("teffective ", $Teff, "\nvmag ", $V, "\n");
  close(MAKESPEC_PARS);

  my $newflux = `./makespec`;
  chop $newflux;
  $newflux =~ s/\s*//;

  chdir $base_dir;

  my $area = $PI * ($aperture/2.0)**2;
  my $totflux = $newflux / $area * $hz;

  # -- small section to peek at variable values - COMMENT OUT AFTER USE
  open(TOMTEST, ">>makeStarDB.log");
  print TOMTEST ("\$Teff: ", $Teff, "\n\$V: ", $V, "\n\$flux: ", $flux, 
		  "\n\$totflux: ", $totflux, "\n\$aperture: ", $aperture);
  print TOMTEST ("\n---------------------\n");
  close TOMTEST;
  #----------end small section---------------

  #-------END TOM CODE---------------

  printf STARDB "$mk_best $V $BmV   %5.0f %5.2f %9.3g  %9.3g %5.2f $RA $dec".
    "\n", $Teff, $Mv, $Rstar_rad, $totflux, $star{$mk_best}{'code'};

}
close(STARDB);
close(INFILE);
print STDERR "Done building stellar catalogue\n";

exit 0;
