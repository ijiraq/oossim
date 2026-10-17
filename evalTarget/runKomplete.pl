#!/usr/bin/env perl
#
# original filename: apOccRate.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Wed May 21, 2008  1:45:25 DST
#  Host: bender.local
#  Working Directory: /Users/bick/working/aperture_test
#


use strict;
use warnings;
use File::Basename;

use Local::Constants;
use Local::Astrotools;
use Local::Stardata;
use Local::KBOdensity;
use Local::Elong2v;

use Math::Trig;
use Math::Round qw(nhimult);

my $exe = basename($0);
my $usage = "Usage: $exe dist AU hz QE rdnoise Av Ebmv elong ap1 ap2 ap3 ...\n";

my ($dist, $AU, $hz, $QE, $rdnoise, $Av, $Ebmv, $elong, $pixelSizeMic, $fNum, $dichroic, @apertures) = @ARGV;
die $usage unless $hz;

my $Evmr = 0.5*$Ebmv; # total kluge

my $incl = 0.0;
my $photon_min = 5.0;
my $AUstr = sprintf "%04d", $AU;

#lower QE and readnoise if using dichroic setup
if ($dichroic) {
    print STDOUT "Using Dichroic...adjusting QE and readnoise";
    $QE = $QE*(0.97**2);
    $rdnoise = $rdnoise/sqrt(2.1);
}

my ($cyc, $nCyc, $corTh, $chiTh, $Noff, $norm) = (1, 10, 8.0, 2.0, 25, 0);
if ($dichroic) {
    $corTh = 5.5;
}
my $lambda = 5.5e-7; # hate to hardcode this, but we're using B+V after all.
my $fsu = sqrt($lambda*$AU*$AU_M/2.0);
my $vRet = elongi2v($RAD*$elong, $RAD*$incl, $AU);
my $event_duration = 3.4*$fsu/$vRet;    # duration of each event (seconds)
my $ts_duration = 1.0*20.0*($nCyc*$cyc)*$event_duration;  # use a 5% fill factor to avoid crowding

#my @apertures = map {0.01*(10 + 1.0*$_)} (1 .. 20);
#@apertures = (0.10, 0.15, 0.20, 0.30);

sub log10($) { return log($_[0])/log(10.0); }

my @mktypes = ();
foreach my $mk ( glob("[OBAFGKM][0-9]V") ) {
  push @mktypes, [$mk, $star{$mk}{Teff}];
}
@mktypes = sort {$b->[1] <=> $a->[1]} @mktypes;

# - loop over each star 
foreach my $ref ( @mktypes ) {

  my ($mk, $Teff) = @$ref;
  
  my $Mv  = $star{$mk}{'Mv'};
  my $BmV = $star{$mk}{'BmV'};
  my $VmR = $star{$mk}{'VmR'};
  my $Mb  = $Mv + $BmV;
  my $Mr  = $Mv - $VmR;
  my $Ab = $Av + $Ebmv;
  my $Ar = $Av - $Evmr;

  my $distmod = 5.0*log10($dist) - 5.0;
  my $V = $Mv + $distmod + $Av;
  my $B = $Mb + $distmod + $Ab;
  my $R = $Mr + $distmod + $Ar;

#begin call of flux sub-routine
   my $fluxB = mag2flux('B', $B); # phot per sec per m^2
   my $fluxV = mag2flux('V', $V);
   my $fluxR = mag2flux('R', $R);
   my $flux = $QE * ($fluxB + $fluxV + $fluxR);

  my $base_dir = `pwd`;
  chop ($base_dir);
  my $star_dir = $mk;
  chdir $star_dir;
  
  foreach my $aperture (@apertures) {

    #adjust readnoise based on number of pixels PSF takes up and 'refresh rate

    my $apertureRadius = 0.9*2.0*rad2deg(1.44*450e-9/$aperture)*3600.0;
    my $pixelScale = $pixelSizeMic*(1./($aperture*$fNum))*206265/1.0e6;
    #pix. width of box containing PSF
    my $numPixels = ((2*nhimult(1, ($apertureRadius/$pixelScale))) + 1);
    my $newRdnoise = $rdnoise*$numPixels*sqrt($hz/40);
    print STDOUT "number of Pixels: $numPixels  readnoise: $newRdnoise\n";

    # -- skip it unless enough flux to bother
    my $area = $PI * ($aperture/2.0)**2;
    my $photons = $flux * $area / $hz;
#   next unless $photons > $photon_min;

    #---------BEGIN TOM CODE---------------------
    my $fluxCalc_dir = $ENV{FLUXCALC};
    die "FLUXCALC not defined\n" unless $fluxCalc_dir;
    die "Directory $fluxCalc_dir does not exist\n" unless (-d $fluxCalc_dir);

    chdir $fluxCalc_dir;
    
    open(MAKESPEC_PARS, ">$fluxCalc_dir/makespec.par");
    print MAKESPEC_PARS ("teffective ", $Teff, "\nvmag ", $V, "\n");
    close MAKESPEC_PARS;

    my $newflux = `./makespec`;
    chop $newflux;
    $newflux =~ s/\s*//;
    $newflux = $QE*$newflux;

    chdir $base_dir;

    # -- small section to peek at variable values - COMMENT OUT AFTER USE
    open(TOMTEST, ">>runKomplete.log");
    print TOMTEST ("\$Teff ", $Teff, "\n\$V: ", $V, "\n\$flux: ", $flux, 
		  "\n\$photons: ", $photons, "\n\$newflux: ", $newflux, "\n\$photon_min: ", $photon_min,
		  "\n\$aperture: ", $aperture);
    print TOMTEST ("\n---------------------\n");
    close TOMTEST;

    chdir $star_dir;
    next unless ($newflux > $photon_min);

    # -- get rms and make the timeseries
    my $rms = 1.0 / sqrt($newflux);
    my $dt = 1.0 / $hz;
    my $Np = $ts_duration*$hz + 4096;

    my $binw = 20.0;
    #my $kernel = 'gauss';
    my $basename = sprintf "ts%05.3f", $aperture;
    my $rawfile = $basename . ".data";
    my $smthfile = $basename . ".norm.fits";
    my $tsfile = $basename . ".${AUstr}.fits";

    my $COUNTS= sprintf "%d", 1.0/$rms**2;
    my $TMAX = $dt*$Np;
    my $ts_cmd = "ran_poisson $COUNTS $Np $TMAX > $rawfile";
    print STDERR $ts_cmd."\n";
    system($ts_cmd);

    my $smth_cmd = "fftSmooth -b $rawfile 1:2 $binw";
    print STDERR $smth_cmd."\n";
    system($smth_cmd);
    rename $smthfile, $tsfile;
    
    # -- run komplete
    my $komppars = "params.komp";
    open(KPAR, ">$komppars");
    printf KPAR "# cyc NperCyc corrThr chiThr fresDir Noffset norm\n";
    printf KPAR "$cyc $nCyc $corTh $chiTh fresnelFiles${AUstr} $Noff $norm\n";
    close(KPAR);

    my $komp_cmd = "komplete -r $newRdnoise $elong $incl $komppars $tsfile";
    system($komp_cmd);

  }
  chdir "../";

}


exit 0;
