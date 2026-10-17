#!/usr/bin/env perl
#
#

use strict;
use Local::Utility;

my $telescope = "HST";
my $band = "V";            # passband observed (B,V,R,u,b,v,y,beta)
my $moon = "0";            # days past new moon (0,3,7,10,14)
$moon = "Z" if ($telescope eq "HST");
my @requestedMagnitudes = ();
my @requestedApertures = ();
my @requestedSignal2Noise = ();

#                  nMir AirGl secR R  see  pxSc atm   opt   mirr   QE   aper
my %scopes= (CFHT =>[2,   8, 0.40, 6, 0.9, 0.2, 0.95, 0.80, 0.85, 0.85, 3.5],
	     HST  =>[2,   4, 0.25, 17,0.043,0.46,1.00, 0.96, 0.89, 0.85, 2.5],
	     GEM  =>[2,   8, 0.16, 5, 0.9, 0.2, 0.95, 0.95, 0.85, 0.85, 8.0],
	     CTIO =>[2,   8, 0.20, 5, 0.9, 0.2, 0.95, 0.95, 0.85, 0.85, 4.0],
	     DAO  =>[2,   8, 0.20, 10,2.5, 0.3, 0.95, 0.93, 0.80, 0.80, 2.0],
	     Def  =>[2,   8, 0.20, 5, 0.9, 0.2, 0.95, 0.95, 0.85, 0.85, 0.0]
	     );

my $pattern = join("|",keys %scopes);
$telescope = "Def" if ( $telescope !~ /$pattern/ );

my ($nMirr,$nAirGlassSurf,$secondaryRatio,$R,$seeing,$pixelScale,$atmConst,
    $opticsConst, $mirrorConst, $ccdQEPeak, $ap) 
    = @{$scopes{$telescope}};


#$nMirr = 2;             # number of reflecting surf (primary, secondary)
#$nAirGlassSurf = 8;     # ie 4 lenses (corrector, focal reducer, achro, +1)
#$secondaryRatio = 0.35; # secondary mirror is 0.20 diameter of primary.
#$R = 6;                 # readnoise
#$seeing = 1.0;          # arcsec
#$pixelScale = 0.2;      # arcsec/pixel
#$atmConst = 0.95;       # peak atmospheric transmission
#$opticsConst = 0.95;    # peak optics throughput for air-glass surface
#$mirrorConst = 0.85;    # peak reflectivity of mirror
#$ccdQEPeak = 0.85;      # peak CCD Quantum efficiency

printf STDOUT "Telescope:                $telescope\n";
printf STDOUT "Passband:                 $band\n";
printf STDOUT "Days past new moon:       $moon\n";
printf STDOUT "No. refl. surfaces:       $nMirr\n";
printf STDOUT "No. air-glass surfs:      $nAirGlassSurf (%d elements)\n",$nAirGlassSurf/2;
printf STDOUT "diam Secondary/Primary:   $secondaryRatio\n";
printf STDOUT "Readnoise:                $R electrons\n";
printf STDOUT "Seeing:                   %.1f arcsec\n",$seeing;
printf STDOUT "Pixel scale:              %.3f arcsec/pixel\n\n",$pixelScale;

my @apertures = (0.5, 1.0, 2.0, 5.0, 8.0, 20.0);
push @apertures, @requestedApertures;
@apertures = sort {$a <=> $b} @apertures;

my @magnitudes = (1.0 .. 30.0);
push @magnitudes, @requestedMagnitudes;
@magnitudes = sort {$a <=> $b} @magnitudes;

my @signal2noise = (5.0, 20.0, 100.0);
push @signal2noise, @requestedSignal2Noise;
@signal2noise = sort {$a <=> $b} @signal2noise;

# get the highest signal to noise
my $lastSNR = $signal2noise[-1];

# determine which aperture number has size $ap to get spacing right to flag it
# in the output.
my $whichAper=0;
my @tmpAper = @apertures;
while ( shift @tmpAper < $ap ) {$whichAper++;}
my $tab = 10;
my $tmpSpace = " "x(22+$tab*$whichAper);


#  hash tables  ########################################################

# from Walker - Astronomical Observations
my %filters = (
	       # Johnson - center,width
	       #U => [365,70],
	       B => [440,100,0.85],
	       V => [550,90,0.9],
	       
	       # Johnson IR
	       R => [700,220,0.9],
	       #I => [880,240],
	       #J => [1250,380],
	       #H => [],
	       #K => [2200,480],
	       #L => [3400,700],
	       #M => [5000,1200],
	       #N => [10400,5700],
	       
	       # Stromgren
	       u => [350,34,0.9],
	       v => [410,20,0.9],
	       b => [470,16,0.9],
	       y => [550,24,0.9],
	       beta => [485,15,0.9]  # actually 486, 3-15 
	       );

# from my notes (values in magnitudes/arcsec^2 )
my %skyMags = (
	       U => {'0'=>22.0, '3'=>21.5, '7'=>19.9,'10'=>18.5, '14'=>17.0,
		     'Z'=>23.4},
	       B => {'0'=>22.7, '3'=>22.4, '7'=>21.6,'10'=>20.7, '14'=>19.5,
		     'Z'=>23.4},
	       V => {'0'=>21.8, '3'=>21.7, '7'=>21.4,'10'=>20.7, '14'=>20.0,
		     'Z'=>23.4},
	       R => {'0'=>20.9, '3'=>20.8, '7'=>20.6,'10'=>20.3, '14'=>19.9,
		     'Z'=>23.4},
	       I => {'0'=>19.9, '3'=>19.9, '7'=>19.7,'10'=>19.5, '14'=>19.2,
		     'Z'=>23.4},
	       );


#  Subroutines   ######################################################

sub integratePassband ($$) {
    my ($arrayRef,$nMirr) = @_;
    my ($center,$bandwidth,$maxThruPut) = 
	($$arrayRef[0],$$arrayRef[1],$$arrayRef[2]);
    my ($low,$high) = ($center-$bandwidth/2,$center+$bandwidth/2);
    # For Vega (ie an A0V spectral type star)
    my %vegaFlux = (
		       250 => 2150,  # i'm guessing
		       300 => 1970,  # i'm guessing
		       350 => 1800,  # i'm guessing
		       400 => 1620,
		       450 => 1453,
		       500 => 1167,
		       550 =>  990,
		       600 =>  833,
		       650 =>  700,
		       700 =>  620,
		       750 =>  536,
		       800 =>  483,
		       850 =>  430,   #i'm guessing
		       900 =>  380,   #i'm guessing
		       950 =>  330,   #i'm guessing
		       );

    # from CFH12K CCD responses (backlit typical devices)
    my %ccdQE = (
		 250 => $ccdQEPeak*0.00/0.85,
		 300 => $ccdQEPeak*0.00/0.85,
		 350 => $ccdQEPeak*0.15/0.85,
		 400 => $ccdQEPeak*0.22/0.85,
		 450 => $ccdQEPeak*0.50/0.85,
		 500 => $ccdQEPeak*0.65/0.85,
		 550 => $ccdQEPeak*0.75/0.85,
		 600 => $ccdQEPeak*0.80/0.85,
		 650 => $ccdQEPeak*0.85/0.85,
		 700 => $ccdQEPeak*0.85/0.85,
		 750 => $ccdQEPeak*0.80/0.85,
		 800 => $ccdQEPeak*0.75/0.85,
		 850 => $ccdQEPeak*0.62/0.85,
		 900 => $ccdQEPeak*0.50/0.85,
		 950 => $ccdQEPeak*0.35/0.85,
		 1000=> $ccdQEPeak*0.12/0.85,
		 1050=> $ccdQEPeak*0.00/0.85
		 );
    
    my %atm = (
	       250 => $atmConst*1.0,
	       300 => $atmConst*1.0,
	       350 => $atmConst*1.0,
	       400 => $atmConst*1.0,
	       450 => $atmConst*1.0,
	       500 => $atmConst*1.0,
	       550 => $atmConst*1.0,
	       600 => $atmConst*1.0,
	       650 => $atmConst*1.0,
	       700 => $atmConst*1.0,
	       750 => $atmConst*1.0,
	       800 => $atmConst*1.0,
	       850 => $atmConst*1.0,
	       900 => $atmConst*1.0,
	       950 => $atmConst*1.0,
	       1000=> $atmConst*1.0,
	       1050=> $atmConst*1.0
	       );
    
    my %mirror = (
	       250 => $mirrorConst*1.0,
	       300 => $mirrorConst*1.0,
	       350 => $mirrorConst*1.0,
	       400 => $mirrorConst*1.0,
	       450 => $mirrorConst*1.0,
	       500 => $mirrorConst*1.0,
	       550 => $mirrorConst*1.0,
	       600 => $mirrorConst*1.0,
	       650 => $mirrorConst*1.0,
	       700 => $mirrorConst*1.0,
	       750 => $mirrorConst*1.0,
	       800 => $mirrorConst*1.0,
	       850 => $mirrorConst*1.0,
	       900 => $mirrorConst*1.0,
	       950 => $mirrorConst*1.0,
	       1000=> $mirrorConst*1.0,
	       1050=> $mirrorConst*1.0
	       );

    my %optics = (
	       250 => $opticsConst*1.0,
	       300 => $opticsConst*1.0,
	       350 => $opticsConst*1.0,
	       400 => $opticsConst*1.0,
	       450 => $opticsConst*1.0,
	       500 => $opticsConst*1.0,
	       550 => $opticsConst*1.0,
	       600 => $opticsConst*1.0,
	       650 => $opticsConst*1.0,
	       700 => $opticsConst*1.0,
	       750 => $opticsConst*1.0,
	       800 => $opticsConst*1.0,
	       850 => $opticsConst*1.0,
	       900 => $opticsConst*1.0,
	       950 => $opticsConst*1.0,
	       1000=> $opticsConst*1.0,
	       1050=> $opticsConst*1.0
	       );

    
    # interpolate the limits of the passband flux
    my %finalFlux;
    my ($i,$lastLam) = 0;

    # go through all the flux values and make a new flux density distrib.
    #
    foreach my $lam (sort {$a <=> $b} keys %vegaFlux) {
	if ($i) {
	    for (my $j=$lastLam; $j<=$lam; $j+=5) {
		my $thisEfficiency = $maxThruPut*
		    $ccdQE{$lam}*
		    $atm{$lam}*
		    $optics{$lam}**$nAirGlassSurf*
		    $mirror{$lam}**$nMirr;
		my $lastEfficiency = $maxThruPut*
		    $ccdQE{$lastLam}*
		    $atm{$lastLam}*
		    $optics{$lastLam}**$nAirGlassSurf*
		    $mirror{$lastLam}**$nMirr;
		my $thisFlux = $thisEfficiency*$vegaFlux{$lam};
		my $lastFlux = $lastEfficiency*$vegaFlux{$lastLam};
		my $fluxDiff = $thisFlux - $lastFlux;
		my $ratio = ($j-$lastLam)/($lam-$lastLam);
		$finalFlux{$j} = $lastFlux+$ratio*$fluxDiff; 
	    }
	}
	$lastLam = $lam;
	$i++;
    }

    # integrate the flux in the passband
    my ($lastk,$electrons) = 0;
    $i = 0;
    for (my $k=$low; $k<=$high; $k+=5) {
	if ($i) {   # this just skips the first pass as there's no lastk
	    # use the midpoint times the binwidth (50 angstrom)
	    $electrons += 50*($finalFlux{$k}+$finalFlux{$lastk})/2;
	}
	$lastk = $k;
	$i++;
    }

    return $electrons;  # phot/sec/cm^2  (ie photFlux integrated over passband)
}


#  main body of code  ####################################################


my $pixelsSeeing = int $PI*( ($seeing/$pixelScale)/2.0 )**2;    # PI r^2
($seeing,$pixelsSeeing) = (2,2) if ($pixelsSeeing < 2);


my $stdFlux = integratePassband($filters{$band},$nMirr);

printf STDOUT "%-5s%-3s %-3s  %-3s  ","mag","S/N","lim","t/t";
my $spacer = sprintf "%-5s%-3s %-3s  %-3s  ","","","","";
foreach my $ap (@apertures) {
    printf STDOUT "%-10s", "--".$ap."--";
    $spacer .= sprintf "%-10s", "--".$ap."--";
}
printf STDOUT "\n\n";


my @lastTimes = (1.0) x @signal2noise;

foreach my $mag (@magnitudes) {

    printf STDOUT "%-5s", $mag;

    foreach my $snr (@signal2noise) {

	printf STDOUT "%-5s"," " if ($snr!=5.0);
	foreach my $aper (@apertures) {

	    my $areaSqrCM = $PI*( (100*$aper/2.0)**2 );             
	    my $secondary = ($secondaryRatio**2)*$areaSqrCM; 
	    $areaSqrCM -= $secondary; # subtract region obscured by secondary

	    # stdFlux is Vega (ie zero mag)
	    my $starFlux = $stdFlux*$areaSqrCM*10**( (-$mag)/2.5 );
	    my $skyFlux = $stdFlux*$areaSqrCM*10**( (-$skyMags{$band}{$moon})/2.5 );

	    my $readNoiseSqr = $pixelsSeeing*$R**2;
	    my $skyNoiseRateSqr = $skyFlux*$PI*(0.5*$seeing)**2;

	    # solve the quadratic equation for time.
	    my $a = $starFlux**2;
	    my $b = -$snr**2*($starFlux+$skyNoiseRateSqr);
	    my $c = -$snr**2*$readNoiseSqr;
	    my $seconds = (-$b + sqrt($b**2-4*$a*$c) ) / (2*$a);

	    if ($aper == $apertures[0]) {
		my $skyNoise = $seconds*$skyNoiseRateSqr;
		my $targetNoise = $seconds*$starFlux;
		my $limit = " ";
		my $lastTime = shift @lastTimes;
		$limit = "Rd " if ($readNoiseSqr > ($skyNoise + $targetNoise));
		$limit = "Sky" if ($skyNoise > ($readNoiseSqr + $targetNoise));
		$limit = "Src" if ($targetNoise > ($skyNoise + $readNoiseSqr));
		my $timeRatio = ($mag>1) ? ($seconds/$lastTime) : "---";
		my $timeRatFormat = ($mag>1) ? "%3.1f" : "%3s";
		printf STDOUT "%-4s%3s  $timeRatFormat  ",$snr,$limit,$timeRatio;

		push @lastTimes, $seconds;
	    }

	    my $timeString = timeUnits($seconds);
	    printf STDOUT "%-10s",$timeString;

	}
	#printf STDOUT ($snr==$lastSNR) ? "\n$tmpSpace*" : "\n";
	printf STDOUT ($snr==$lastSNR) ? "\n$spacer" : "\n";
    }
    printf STDOUT "\n";
}


