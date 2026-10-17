#!/home/bickersj/perl/bin/perl -w
# Perl Module:  Utility.pm
#
# Purpose: a Perl module containing constants and functions useful in 
#          astronomy
# 
# Author: Steve Bickerton, McMaster University
#         bick@physics.mcmaster.ca
#
# Updated: February, 2004
#
# Version: 1.00
# Revisions/Corrections:
#
#
# Functions:
#
# randPowerLaw ($Xo,$alpha): Generates a single random deviate drawn from 
#                a power law distribution
# choosePop (@population_probs): (not exported) generates a number from
#                1 to n.  The prob. of each outcome defined in the array 
#                @population_probs.
# meanAnom2Theta ($M,$e,$iter_tolerance,$max_iter): converts mean anomaly 
#                of an eliptical orbit to angular displacement theta
# log10 (): Return the log of a number.
# sumArray (): Sum the elements of an array.
# normalizeArray (): Normalize (to a sum of one) the elements of an array.
# makeMultimodeDistrib (): make a multimodal (using gaussian modes)
#                     distribution.
# getLikelihood() : Get the likelihood of a value, given the parameters of
#                   a multimodal distribution.
#
#

package  Local::Utility;


use Carp;
use Math::Trig;
use Math::Random qw(random_normal random_multinomial);

#use Math::Complex;

require  Exporter;


###########     Constants        ##############

my @mathConstants = qw($PI $TWOPI $PIHALF $EXP $sqrtTWOPI $sqrtPI);

my @physConstants = qw($G_SI $G_CGS $C_SI $C_CGS $EP_SI $MU_SI $h_SI 
		       $h_CGS $hBAR_SI $hBAR_CGS $e_C $e_ESU);

my @massConstants = qw($mp_KG $mp_G $mn_KG $mn_G $me_KG $me_G
		       $mH_KG $mH_G $amu_KG $amu_G $amu_REL
		       $R_SI $R_CGS $ao_SI $ao_CGS $RH_SI $RH_CGS
		       $k_SI $k_CGS $sigma_SI $a_SI $a_CGS $NA_SI);

my @astroConstants = qw($Mo_CGS $Mo_G $Lo_CGS $Ro_CGS $Ro_CM $Teff_K 
			$Me_CGS $Me_G $Re_CGS $Re_CM);

my @astroConversions = qw($LY_CM $PC_CM $PC_LY $AU_CM $SID_DAY $SOL_DAY
			  $SID_YR $TROP_YR $Ho_SI $PC_M $CMperLY $PC_M 
			  $MperPC $CMperPC $KMperPC $LYperPC $CMperAU 
			  $KMperAU $MperAU $AUperPC $RAD_ARCSEC 
			  $AU_M $MperAU $ARCSECperRAD);

push my @allConstants,
    @mathConstants,@physConstants,@massConstants,
    @astroConstants,@astroConversions;


###########     Functions        ##############

my @utilFunctions = qw (timerBar labelFormat);
my @mathFunctions = qw (log10 randPowerLaw chooseFamily sumArray 
			normalizeArray makeMultimodeDistrib getLikelihood
			distanceUnits angleUnits timeUnits kernelhist
			smooth meanFilter medianFilter convFilter
			chiSquared histogram centreText integrate);
my @astroFunctions = qw (meanAnom2Theta);

push my @allFunctions,
    @mathFunctions,@astroFunctions,@utilFunctions;

push my @allExports,
    @allConstants,  @allFunctions;



############    Exporting        ################################
#
#
#################################################################

our @ISA       = qw(Exporter);

our @EXPORT    = @allExports;   # default exports

our @EXPORT_OK = qw();            # export by request

our @EXPORT_TAGS = (              # labels for subsets of export requests
		    ALL => [ @EXPORT_OK ],
		    );

our $VERSION   = 1.00;


#-----------------------------------------------
# math constants

*PI       = \3.14159265358979;
*TWOPI    = \(2.0*$PI);
*sqrtPI   = \sqrt($PI);
*sqrtTWOPI= \sqrt($TWOPI);
*PIHALF   = \($PI/2.0);
*EXP      = \2.718281828;

#gravity
*G_SI     = \6.67259e-11;       # N    m^2  kg^-2
*G_CGS    = \6.67259e-8;        # dyne cm^2 g^-2

#speed of light
*C_SI     = \2.99792458e8;      # m  s^-1   
*C_CGS    = \2.99792458e10;     # cm s^-1

#hubble const
*Ho_SI    = \72.0;              # km/s/Mpc

#free space permittivity and permeability
*EP_SI    = \8.854187818e-12;
*MU_SI    = \1.256637061e-6;

#plank's const
*h_SI     = \6.6260755e-34;      # J   s
*h_CGS    = \6.6260755e-27;      # erg s
*hBAR_SI  = \1.05457266e-34;     # J   s
*hBAR_CGS = \1.05457266e-27;     # erg s

#particle charges and masses
*e_C      = \1.60217733e-19;     # C
*e_ESU    = \4.803206e-10;       # esu
*mp_KG    = \1.6726231e-27;      # kg
*mp_G     = \1.6726231e-24;      # g
*mn_KG    = \1.674929e-27;       # kg
*mn_G     = \1.674929e-24;       # g  
*me_KG    = \9.1093897e-31;      # kg
*me_G     = \9.1093897e-28;      # g
*mH_KG    = \1.673534e-27;       # kg
*mH_G     = \1.673534e-24;       # g
*amu_KG   = \1.6605402e-27;      # kg
*amu_G    = \1.6605402e-24;      # g
*amu_REL  = \931.49432;          # MeV c^-2

# ideal gas const
*R_SI     = \8.31451;            # J    mole^-1  K^-1
*R_CGS    = \8.314510e7;         # erg  mole^-1  K^-1

# bohr radius
*ao_M     = \5.29177249e-11;     # m
*ao_CM    = \5.29177249e-9;      # cm

# Rydberg const
*RH_SI    = \1.09677585e3;       # m^-1
*RH_CGS   = \1.09677585e5;       # cm^-1

# Boltzman const
*k_SI     = \1.380658e-23;       # J      K^-1
*k_CGS    = \1.380658e-16;       # erg    K^-1

# Stefan-Boltzman const
*sigma_SI = \5.67051e-8;         # J    m^-2  s^-1  K^-4
*sigma_CGS= \5.67051e-5;         # erg  cm^-2 s^-1  K^-4

# Radiation const  (what is this?)
*a_SI     = \7.56591e-16;        # J    m^-3  K^-4
*a_CGS    = \7.56591e-15;        # erg  cm^-3 K^-4

#avagadro's number
*NA_SI    = \6.0221367e23;       # mole^-1

# Solar stuff

*Mo_CGS   = \1.989e33;           # g
*Mo_G     = \1.989e33;           # g
*Lo_CGS   = \3.826e33;           # erg  s^-1
*Ro_CGS   = \6.9599e10;          # cm
*Ro_CM    = \6.9599e10;          # cm
*Teff_K   = \5770;               # K

# Earth stuff
*Me_CGS   = \5.974e27;           # g
*Me_G     = \5.974e27;           # g
*Re_CGS   = \6.378e8;            # cm
*Re_CM    = \6.378e8;            # cm

# Astro consts
*LY_CM    = \9.4604e17;          # cm
*CMperLY  = \9.4604e17;          # cm
*PC_M     = \3.0857e16;          # m
*MperPC   = \3.0857e16;          # m
*PC_CM    = \3.0857e18;          # cm
*CMperPC  = \3.0857e18;          # cm
*KMperPC  = \3.0857e13;          # km
*PC_LY    = \3.2616;             # 
*LYperPC  = \3.2616;             # 
*AU_M     = \1.4960e11;          # m
*AU_CM    = \1.4960e13;          # cm
*CMperAU  = \1.4960e13;          # cm
*KMperAU  = \1.4960e8;           # km
*MperAU   = \1.4960e11;          # m
*PC_AU    = \206264.8062;        # AU
*AUperPC  = \206264.8062;        # AU
*RAD_ARCSEC= \206264.8062;       # arcsec
*ARCSECperRAD= \206264.8062;     # arcsec

*SID_DAY  = \86164.0905;         # s
*SOL_DAY  = \86400;              # s
*SID_YR   = \3.155815e7;         # s
*TROP_YR  = \3.155693e7;         # s



# -------------------------------------------------------
#
#  Stupid functions
#
# -------------------------------------------------------

sub log10 {
    my $n = shift;
    return log($n)/log(10);
}


sub timerBar ($$$) {
    my ($width, $position, $size) = @_;
    $width -= 2;

    my ($leadspace,$tailspace) = (" "x($width*($position/$size)+0.5),
				  " "x($width-$width*($position/$size)+0.5) );
    return sprintf "|%-${width}s|",$leadspace."*".$tailspace;

}

# -------------------------------------------------------
#
# function: randPowerLaw
#
# Purpose: To generate a random number drawn from a power law
#          distribution with slope $alpha and minimum value $Xo.
#
# Req'd Parameters: $Xo
#                   $alpha ( $alpha < -1, ie MORE negative )
#
# Limitations: For steep slopes, the majority of the points generated
#              will appear in the smallest bins.  Care should be
#              taken in choosing and appropriate $Xo.
#

#-----------------------------------------------

sub randPowerLaw ($$) {

    my ($Xo,$alpha) = @_;
    return $Xo*(   (1-rand())**( 1/(1-$alpha) )   );

}


# -------------------------------------------------------
#
# function: chooseFamily
#
# Purpose: To generate a random number from 0 to n with the probability
#          of each outcome defined as an element in the array
#          @population_probs.
#
# Req'd Parameters: @population_probs
#
#
# Limitations: None known
#
#

#-----------------------------------------------

sub chooseFamily (@) {

    my @population_probs = @_;

    my $pop_id = -1;
    my @population = random_multinomial(1,@population_probs);

    # loop thru and exit when you find a non-zero element
  POP: foreach (@population) {
      $pop_id++; 
      last POP if ($_);
  }  
    return $pop_id;

}


# -------------------------------------------------------
#
# function: meanAnom2Theta
#
# Purpose: To convert the mean anomaly $M of an orbit
#          to the angular position $w (true anomaly)
#
# Req'd Parameters: $M, mean anomaly (from 0 - 2pi)
#                   $e, eccentricity 
#                   $iter_tolerance, iteration tolerance for $E in rads
#                   $max_iter, max number of iterations before exit failure
#
# Limitation: The problem cannot be solved analytically and is therefore
#             limited to the accuracy defined by $iter_tolerance
#

#-----------------------------------------------

sub meanAnom2Theta ($$$$) {

    my ($M, $e, $iter_tolerance, $max_iter) = @_;

    # get the position for a random point in the orbit's phase (ie time)
    my $E = $PIHALF;                 # initial E value
    my $iter = 0;
    my $error = 2*$iter_tolerance;   # initial error value

    # the following iteration uses newton's method.
    # The function is defined as $f, with its derivative $fp (f-prime)
    while ( ($error**2 > $iter_tolerance**2) && ($iter < $max_iter) ) {
	
	my $f = $E-$e*sin($E)-$M;
	my $fp = 1-$e*cos($E);
	
	my $Enew = $E - $f/$fp;
	$error = $Enew - $E;
	$E = $Enew;
	$iter++;
    }
    
    my $w = 2*atan2( sqrt( (1+$e)/(1-$e) )*sin($E/2)/cos($E/2), 1);
    
    # atan2 returns from -pi -> pi, this changes that to be 0 -> pi
    $w = $w+$TWOPI if ($w < 0);
    
    if ($iter==$max_iter) {
	print "Error: meanAnom2Theta, solution did not converge in %i iterations ... Exiting.\n", $max_iter;
	exit -1;
    }
    return $w;

}


##############################################################

# -------------------------------------------------------
#
# function: sumArray()
#
# Purpose: Sum the elements of an array.
#
# Req'd Parameters: $arrayRef, the array whose elements are to be summed
#
# Limitation: none known.
#

#-----------------------------------------------
sub sumArray ($) {
    my ($arrayRef) = @_;

    my $sum = 0;
    foreach my $value (@$arrayRef) {
	$sum += $value if ($value);
    }
    return $sum;
}

sub meanArray ($) {
    my ($arrayRef) = @_;

    return sumArray($arrayRef)/@$arrayRef;
}

# -------------------------------------------------------
#
# function: normalizeArray ()
#
# Purpose: To normalize a list of numbers (mixing ratios) such that they
#          sum to one.
#
# Req'd Parameters: $arrayRef, a reference to the list of numbers.
#
#
# Limitation: Hardcoded to normalize to 'one' only.
#

#-----------------------------------------------
sub normalizeArray ($) {
    my ($arrayRef) = @_;

    my $sum = sumArray ($arrayRef);
    @$arrayRef = map {$_/$sum} @$arrayRef;
    return @$arrayRef;
}

# -------------------------------------------------------
#
# function: makeMultimodeDistrib()
#
# Purpose: To make a list of values distributed according to a specified
#          multimodal gaussian distribution.
#
# Req'd Parameters: $distribParasRef, a reference to an array containing
#                       references to arrays containing means,stddevs,mix
#                   $N, the number of values to return
#
# Limitation: multimodal gaussian only.
#

#-----------------------------------------------
sub makeMultimodeDistrib ($$) {
    my ($distribParamsRef, $N) = @_;
    my ($centreRef, $sigmaRef, $mixRatioRef) = @$distribParamsRef;

    my @listOfNs;
    if ( scalar(@$mixRatioRef) > 1 ) {
	@listOfNs = random_multinomial($N,@$mixRatioRef);
    } else {
	@listOfNs = ($N);
    }

    my @distribution;
    my $j=0;
    foreach my $n (@listOfNs) {
	push @distribution, 
	     random_normal($n, $$centreRef[$j], $$sigmaRef[$j++]);
    }
    return @distribution;
}


# -------------------------------------------------------
#
# function: getLikelihood ()
#
# Purpose: To calculate the log-likelihood of a list of values given
#          the parameters for multimodal distribution.
#
# Req'd Parameters: $distribParamsRef, a reference to an array containing
#                       references to arrays containing means,stddevs,mixratios
#                   $valueArrayRef, a reference to an array containing
#                       the values to get likelihoods for.
#
# Limitation:  Only works for multimodal gaussians.
#
#

#-----------------------------------------------
sub getLikelihood ($$) {
    my ($distribParamsRef, $valueArrayRef) = @_;
    my ($centreRef, $sigmaRef, $mixRatioRef) = @$distribParamsRef;

    my @likelihoods;
 
    # for each data point we're given ...
    my $nVal = 0;
    foreach my $value (@$valueArrayRef) {

	my $dx = 0.03; # width of prob bin.

	# for each mode of the distribution ...
	my $m=0;
	foreach my $cen (@$centreRef) {
	    my $x = abs($value-$cen);
	    my $sigma = $$sigmaRef[$m];
	    if ($x/$sigma < 4.0) {
		my $Amp = $$mixRatioRef[$m]*(1/($$sigmaRef[$m++]*$sqrtTWOPI));
		$likelihoods[$nVal] += $Amp*$EXP**( -$x**2/(2*$sigma**2) )*$dx;
	    } else {$likelihoods[$nVal] += 1e-5*$dx;}
	}
	$nVal++;
    }
    @likelihoods = map {log($_)} @likelihoods;
    return @likelihoods;
}

# -------------------------------------------------------
#
# function: chiSquared ()
#
# Purpose: To calculate the chiSquared stat of a list of histogram values given
#          the parameters for multimodal distribution and binning info.
#
# Req'd Parameters: $distribParamsRef, a reference to an array containing
#                       references to arrays containing means,stddevs,mixratios
#                   $valueArrayRef, a reference to an array containing
#                       the values to get likelihoods for.
#
# Limitation:  Only works for multimodal gaussians.
#
#

#-----------------------------------------------
sub chiSquared ($$$$) {
    my ($distribParamsRef, $binsRef, $valuesRef, $sced) = @_;
    my ($centreRef, $sigmaRef, $mixRatioRef) = @$distribParamsRef;

    my @bins = @$binsRef;
    my @values = @$valuesRef;

    my $binwidth = $bins[1] - $bins[0];

    # the number of data values used to make the histogram
    my $N = sumArray $valuesRef;  

    # the number of bins in the histogram
    my $n = @$valuesRef;   

    # the number of fitted parameters (-1 because Nth mix ratio = 1 - others)
    #  n-means + n-stddevs (or 1 if homosced) + (n-1)mix
    my $nc = @$centreRef + (($sced==2) ? @$sigmaRef : 1) + (@$mixRatioRef-1) ;

    # v (greek nu) = degrees of freedom
    my $v = $n - $nc;

    my @probDensity;
    my @NP;
    my $XSqrd;
    my $redXSqrd;
 
    # for each bin ...
    my $nVal = 0;
    open (TMP, ">tmp");
    foreach my $bin (@$binsRef) {

	my $value = $values[$nVal];

	# add probability contribs for each mode of the distribution ...
	my $m=0;
	foreach my $cen (@$centreRef) {
	    my $x = abs($bin-$cen);
	    my $mixRatio = $$mixRatioRef[$m];
	    my $sigma = $$sigmaRef[$m];
	    if ($x/$sigma < 4.0) {
		# add the probability density at this bin-centre for this mode
		my $Amp = $mixRatio*(1/($sigma*$sqrtTWOPI));
		my $probDensityC = $Amp*$EXP**( -$x**2/(2*$sigma**2) );
		my $probDensityP = $Amp*$EXP**( -($x+$binwidth/2.0)**2/(2*$sigma**2) );
		my $probDensityM = $Amp*$EXP**( -($x-$binwidth/2.0)**2/(2*$sigma**2) );
		$probDensity[$nVal] += 
		    (2*$probDensityC + $probDensityP + $probDensityM)/4.0;

	    } else {$probDensity[$nVal] += 1e-5;}
	    $m++;
	}

	# calculate chi Squared
	$NP = $N*$probDensity[$nVal]*$binwidth;
	my $hoo = @$centreRef;
	$XSqrd += ($value - $NP)**2/$NP;
	
	printf TMP "%.2f\t$probDensity[$nVal]\t$N\t$hoo\t$NP\t$value\t$XSqrd\n",$bin;

	$nVal++;	
    }

    close (TMP);
    return ($XSqrd,$v);
}



# -------------------------------------------------------
#
# function: distanceUnits ()
#
# Purpose: To convert a value to a string with an appropriate distance unit
#          appended (based on order of magnitude).
#
# Req'd Parameters: 

#
# Limitation:  
#
#

#-----------------------------------------------


sub distanceUnits ($$) {

    my ($dist,$unit) = @_;

    my $conversionFactor;
    if ($unit eq "AU") {
	$conversionFactor = $AU_CM;
    } elsif ($unit eq "UM") {
	$conversionFactor = 1.0e-4;
    } elsif ($unit eq "MM") {
	$conversionFactor = 1.0e-1;
    } elsif ($unit eq "CM") {
	$conversionFactor = 1.0;
    } elsif ($unit eq "M") {
	$conversionFactor = 1.0e2;
    } elsif ($unit eq "KM") {
	$conversionFactor = 1.0e5;
    } elsif ($unit eq "PC") {
	$conversionFactor = $PC_CM;
    } elsif ($unit eq "KPC") {
	$conversionFactor = 1000*$PC_CM;
    } elsif ($unit eq "MPC") {
	$conversionFactor = 1000000*$PC_CM;
    } elsif ($unit eq "LY") {
	$conversionFactor = $LY_CM;
    } else {
	$conversionFactor = 0;
    }
	
    # first, convert to m
    $dist = $conversionFactor*$dist/100.0;

    local *makeFormat = sub {
	
	my ($dist) = @_;

	my ($low, $mid, $high) = (10.0,100.0,10000.0);

	my $format = "%d";
	if ($dist < $low ) {
	    $format = "%.2f";
	} elsif ($dist >= $low && $dist < $mid) {
	    $format = "%.1f";
	} elsif ($dist >= $mid && $dist < $high) {
	    $format = "%.0f";
	} elsif ($dist >= $high) {
	    $format = "%.1e";
	}
	return $format;
    };
    
    my $format;
    if ($dist > 1.0e-18 && $dist <= 1.0e-15) {
	$format = makeFormat($dist/1.0e-18);
	$distString = sprintf "$format am",$dist/1.0e-18;
    } elsif ($dist > 1.0e-15 && $dist <= 1.0e-12) {
	$format = makeFormat($dist/1.0e-15);
	$distString = sprintf "$format fm",$dist/1.0e-15;
    } elsif ($dist > 1.0e-12 && $dist <= 1.0e-9) {
	$format = makeFormat($dist/1.0e-12);
	$distString = sprintf "$format pm",$dist/1.0e-12;
    } elsif ($dist > 1.0e-9 && $dist <= 1.0e-6) {
	$format = makeFormat($dist/1.0e-9);
	$distString = sprintf "$format nm",$dist/1.0e-9;
    } elsif ($dist > 1.0e-6 && $dist <= 1.0e-3) {
	$format = makeFormat($dist/1.0e-6);
	$distString = sprintf "$format um",$dist/1.0e-6;
    } elsif ($dist > 1.0e-3 && $dist <= 1.0e-2) {
	$format = makeFormat($dist/1.0e-3);
	$distString = sprintf "$format mm",$dist/1.0e-3;
    } elsif ($dist > 1.0e-2 && $dist <= 1.0) {
	$format = makeFormat($dist/1.0e-2);
	$distString = sprintf "$format cm",$dist/1.0e-2;
    } elsif ($dist > 1.0 && $dist <= 1.0e3) {
	$format = makeFormat($dist/1.0);
	$distString = sprintf "$format m",$dist/1.0;
    } elsif ($dist > 1.0e3 && $dist <= 1.0e11) {
	$format = makeFormat($dist/1.0e3);
	$distString = sprintf "$format km",$dist/1.0e3;
    } elsif ($dist > 1.0e11 && $dist <= 1000*$KMperPC/10.0) {
	$format = makeFormat($dist/(1.0e3*$KMperAU));
	$distString = sprintf "$format AU",$dist/(1000.0*$KMperAU);
    } elsif ($dist > 1000*$KMperPC/10.0 && $dist <= 1.0e6*$KMperPC) {
	$format = makeFormat($dist/(1.0e3*$KMperPC));
	$distString = sprintf "$format pc",$dist/(1000.0*$KMperPC);
    } elsif ($dist > 1.0e6*$KMperPC && $dist <= 1.0e9*$KMperPC) {
	$format = makeFormat($dist/(1.0e6*$KMperPC));
	$distString = sprintf "$format kpc",$dist/(1.0e6*$KMperPC);
    } elsif ($dist > 1.0e9*$KMperPC && $dist <= 4.2e12*$KMperPC) {
	$format = makeFormat($dist/(1.0e9*$KMperPC));
	$distString = sprintf "$format Mpc",$dist/(1.0e9*$KMperPC);
    } elsif ($dist > 4.2e12*$KMperPC) {
	$format = makeFormat($dist/(4.2e9*$KMperPC));
	$distString = sprintf "$format Horizon",$dist/(4.2e9*$KMperPC);
    }


    return $distString;
    
}
# -------------------------------------------------------
#
# function: angleUnits ()
#
# Purpose: To convert a value to a string with an appropriate angular unit
#          appended (based on order of magnitude).
#
# Req'd Parameters: 

#
# Limitation:  
#
#

#-----------------------------------------------


sub angleUnits ($) {

    my ($angle) = @_;

    my $angleArcsec = $angle*$ARCSECperRAD;

    my $angleString;
    if ($angleArcsec > 1e-8 && $angleArcsec <= 1e-5) {
	$angleString = sprintf "%.2f uas",$angleArcsec*1e6;
    } elsif ($angleArcsec > 1e-5 && $angleArcsec <= 1e-3) {
	$angleString = sprintf "%3d uas",$angleArcsec*1e6;
    } elsif ($angleArcsec > 1e-3 && $angleArcsec <= 1) {
	$angleString = sprintf "%3d mas",$angleArcsec*1e3;
    } elsif ($angleArcsec > 1.0 && $angleArcsec <= 60) {
	$angleString = sprintf "%.2f\"",$angleArcsec;
    } elsif ($angleArcsec >60 && $angleArcsec <= 3600) {
	$angleString = sprintf "%.2f\'",$angleArcsec/60.0;
    } elsif ($angleArcsec >3600 && $angleArcsec <= 36000) {
	$angleString = sprintf "%.2f d", $angleArcsec/3600;
    } elsif ($angleArcsec > 36000) {
	$angleString = sprintf "--";
    } elsif ($angleArcsec < 0.01) {
	$angleString = sprintf "--";
    }
    
    return $angleString;
    
}


# -------------------------------------------------------
#
# function: timeUnits ()
#
# Purpose: To convert a value to a string with an appropriate time unit
#          appended (based on order of magnitude).
#
# Req'd Parameters: 

#
# Limitation:  
#
#

#-----------------------------------------------


sub timeUnits ($) {

    my ($time) = @_;   # assumed in seconds

    my $timeString;

    my $secPerDay = $SOL_DAY;
    my $secPerWk = 7.0*$SOL_DAY;
    my $secPerMonth = 31.0*$SOL_DAY;
    my $secPerYr = 365.24*$secPerDay;
    my $secPerMyr = 1e6*$secPerYr;
    my $secPerGyr = 1e9*$secPerYr;

    local *formatString = sub {

	my ($time) = @_;
	my ($low,$mid,$high) = (1,10,100);

	if ($time >= $low && $time < $mid) {
	    $format = "%.2f";
	} elsif ($time >= $mid && $time < $high) {
	    $format = "%.1f";
	} elsif ($time >= $high) {
	    $format = "%.0f";
	}

	return $format;
    };


    if ($time >= 1e-15 && $time < 1e-12) {
	$format = formatString($time/1e-15);
	$timeString = sprintf "$format fs", $time/1e-15;
    } elsif ($time >= 1e-12 && $time < 1e-9) {
	$format = formatString($time/1e-12);
	$timeString = sprintf "$format ps", $time/1e-12;
    } elsif ($time >= 1e-9 && $time < 1e-6) {
	$format = formatString($time/1e-9);
	$timeString = sprintf "$format ns", $time/1e-9;
    } elsif ($time >= 1e-6 && $time < 1e-5) {
	$format = formatString($time/1e-6);
	$timeString = sprintf "$format us",$time*1e6;
    } elsif ($time >= 1e-5 && $time < 1e-3) {
	$format = formatString($time/1e-6);
	$timeString = sprintf "$format us",$time*1e6;
    } elsif ($time >= 1e-3 && $time < 1) {
	$format = formatString($time/1e-3);
	$timeString = sprintf "$format ms",$time*1e3;
    } elsif ($time >= 1.0 && $time < 60) {
	$format = formatString($time/1.0);
	$timeString = sprintf "$format s",$time;
    } elsif ($time >=60 && $time < 3600) {
	$format = formatString($time/60.0);
	$timeString = sprintf "$format m",$time/60.0;
    } elsif ($time >=3600 && $time < 24*3600) {
	$format = formatString($time/3600.0);
	$timeString = sprintf "$format h", $time/3600;
    } elsif ($time >= $secPerDay && $time < $secPerWk) {
	$format = formatString($time/$secPerDay);
	$timeString = sprintf "$format d", $time/$secPerDay;
    } elsif ($time >= $secPerWk && $time < $secPerMonth) {
	$format = formatString($time/$secPerWk);
	$timeString = sprintf "$format w", $time/$secPerWk;
    } elsif ($time >= $secPerMonth && $time < $secPerYr) {
	$format = formatString($time/$secPerMonth);
	$timeString = sprintf "$format l", $time/$secPerMonth;
    } elsif ($time >= $secPerYr && $time < 100*$secPerYr) {
	$format = formatString($time/$secPerYr);
	$timeString = sprintf "$format y", $time/$secPerYr;
    } elsif ($time >= 100*$secPerYr && $time < $secPerMyr) {
	$format = formatString($time/$secPerYr);
	$timeString = sprintf "$format y", $time/$secPerYr;
    } elsif ($time >= $secPerMyr && $time < $secPerGyr) {
	$format = formatString($time/$secPerMyr);
	$timeString = sprintf "$format My", $time/$secPerMyr;
    } elsif ($time >= $secPerGyr && $time < (1/$Ho_SI)) {
	$format = formatString($time/$secPerGyr);
	$timeString = sprintf "$format Gy", $time/$secPerGyr;
    } elsif ($time >= (1/$Ho_SI) ) {
	$format = formatString($time/$Ho_SI);
	$timeString = sprintf "$format HT", $time*$Ho_SI
    } elsif ($time < 0.01) {
	$timeString = sprintf "--";
    }
    
    return $timeString;
    
}


# -------------------------------------------------------
#
# function: smooth ()
#
# Purpose: smooth a list of data points
#
# Req'd Parameters: 

#
# Limitation:  
#
#

#-----------------------------------------------


sub kernelhist ($$$$$$$) {

    my ($inArrRef,$resolution,$binwidth,$kernel,$scaling,$low,$high) = @_;

    my @inarray = @$inArrRef;
   
    #
    # Calculate the dimensions of the required array and initiallize the array
    #

    my $n = int(($high-$low)/$resolution);
    my $counter = @inarray;
    my @histogram = (0) x ($n+1);

    # get the bin values
    my @bins;
    foreach my $i (0 .. $n) {
	$bins[$i] = $low + ($i)*$resolution;
    }

    # Read through the input data file and determine which bins the
    # data point will fall in.  In the case of the gaussian, the amount of
    # the contribution to each relevant bin is first determined.
    
    my $highestbin = int (($high-$low)/$resolution);

    #######################################################################
    #                   Calculations for the boxcar format

    if ( $kernel eq "boxcar" ) {
	my $hwid = $binwidth/2.0;
	
	foreach my $value (@inarray) {

	    # if within the range requested
	    if ($value >= ($low-$hwid) && $value <= ($high+$hwid)) {
		
		my $binlow = $value - $hwid;
		my $binhigh = $value + $hwid;
		my $nbinlow = int(($binlow - $low)/$resolution) + 
		    (  ($binlow>$low) ? (1) : (0)  );

		# if a point is right on the limit, it will appear
		# in the next bin ... correct for this.
		$nbinlow -= 1 if (($binlow - $low) == ($high-$low));

		my $nbinhigh = int(($binhigh - $low)/$resolution); 
		
		for (my $j=$nbinlow; $j <= $nbinhigh; $j++) {
		    $histogram[$j]++ if (($j >= 0) && ($j <= $highestbin));
		    
		}
	    }
	}
	
    }
    
    #######################################################################
    #                   Calculations for the gaussian format
    
    if ( $kernel eq "gauss" ) {
	my $sigma = $binwidth/2.0;

	foreach my $value (@inarray) {
	    
	    if ($value >= ($low-3*$sigma) && $value <= ($high+3*$sigma)) {
		my $binlow = $value - 3*$sigma;
		my $binhigh = $value + 3*$sigma;
		my $nbinlow = int(($binlow - $low)/$resolution) + 
		    (  ($binlow>$low) ? (1) : (0) );
		my $nbinhigh = int(($binhigh - $low)/$resolution);
		
		for (my $l=$nbinlow; $l <= $nbinhigh; $l++) {
		    if (($l >= 0) && ($l <= $highestbin)) {
			my $negdistsqr = -1 * ($value - ($low + ($l * $resolution)))**2;
			my $contrib = $EXP**($negdistsqr/(2 * $sigma**2));
			$histogram[$l] += $contrib;
		    }
		}
	    }
	    
	}
	
    }
   
    if ($scaling eq "density") {
	@histogram = map {$_/$binwidth} @histogram if ( $kernel eq "boxcar" ); 
	@histogram = map {$_/($sigma*$sqrtTWOPI)} @histogram if ( $kernel eq "gauss" ); 	
    } elsif ($scaling eq "probdensity") {
	$binwidth *= $counter;
	@histogram = map {$_/$binwidth} @histogram if ( $kernel eq "boxcar" ); 
	@histogram = map {$_/($sigma*$sqrtTWOPI)} @histogram if ( $kernel eq "gauss" );
    } else {
	@histogram = @histogram;  # ie do nothing, return raw counts
    }


    return \@bins,\@histogram;

}


# -------------------------------------------------------
#
# function: smooth ()
#
# Purpose: smooth a list of data points
#
# Req'd Parameters: 

#
# Limitation:  
#
#

#-----------------------------------------------


sub smooth ($$$) {

    my ($inArrRef, $binwidth, $kernel) = @_;
    my @inarray = @$inArrRef;   

    my @smooth = (0) x (@inarray );


    #######################################################################
    #                   Calculations for the boxcar format

    if ( $kernel eq "boxcar" ) {
	my $hwid = (int $binwidth/2.0+0.5)-($binwidth%2);

	for (my $q=0; $q<=$#inarray; $q++) {
	    my $lo = (($q-$hwid)>=0) ? (int ($q-$hwid)) : (int 0);
	    my $hi = (($q+$hwid)<@inarray) ? (int ($q+$hwid)) : ($#inarray);
	    my @tmp = @inarray[$lo .. $hi];
	    $smooth[$q] = (sumArray \@tmp) / (@tmp);

	}
    }
    
    #######################################################################
    #                   Calculations for the gaussian format
    
    if ( $kernel eq "gauss" ) {
	my $sigma = (int $binwidth/2.0+0.5)-($binwidth%2);

	for (my $q=0; $q<@inarray; $q++) {
	    
	    my $lo = (($q-3*$sigma)>=0) ? (int ($q-3*$sigma)) : (int 0);
	    my $hi = (($q+3*$sigma)<@inarray) ? (int ($q+3*$sigma)) : ($#inarray);
	    my @window = @inarray[$lo .. $hi];

	    my ($tmp,$integral) = (0,0);
	    for (my $i=0; $i<=$#window; $i++) {
		my $gaussian = (1/$sqrtTWOPI)*
		    $EXP**(   -( (3*($i-@window/2)/(@window/2) )**2 / 2 ) );
		if ( $window[$i] ) {
		    $tmp += $window[$i]*$gaussian;
		    $integral += $gaussian;
		}
	    }
	    $smooth[$q] = ($tmp) / $integral;
	}
    }

    return @smooth;
}


# -------------------------------------------------------
#
# function: meanFilter ()
#
# Purpose: meanFilter a list of data points
#
# Req'd Parameters: 

#
# Limitation:  
#
#

#-----------------------------------------------


sub meanFilter ($$) {

    my ($inArrRef, $binwidth) = @_;
    my @inarray = @$inArrRef;   

    my @mean = (0) x (@inarray );

    my $hwid = (int $binwidth/2.0+0.5)-($binwidth%2);

    for (my $q=0; $q<=$#inarray; $q++) {
	my $lo = (($q-$hwid)>=0) ? (int ($q-$hwid)) : (int 0);
	my $hi = (($q+$hwid)<@inarray) ? (int ($q+$hwid)) : ($#inarray);
	my @tmp = @inarray[$lo .. $hi];
	$mean[$q] = (sumArray \@tmp) / (@tmp);
    }    
    return @mean;
}

# -------------------------------------------------------
#
# function: medianFilter ()
#
# Purpose: medianFilter a list of data points
#
# Req'd Parameters: 

#
# Limitation:  
#
#

#-----------------------------------------------


sub medianFilter ($$) {

    my ($inArrRef, $binwidth) = @_;
    my @inarray = @$inArrRef;   

    my @median = (0) x (@inarray );

    my $hwid = (int $binwidth/2.0+0.5)-($binwidth%2);

    for (my $q=0; $q<=$#inarray; $q++) {
	my $lo = (($q-$hwid)>=0) ? (int ($q-$hwid)) : (int 0);
	my $hi = (($q+$hwid)<@inarray) ? (int ($q+$hwid)) : ($#inarray);
	my @tmp = @inarray[$lo .. $hi];

	my @sortTmp = sort {$a<=>$b} @tmp;

	my $middleIndex = int (scalar @sortTmp / 2.0 - 0.5);
	$median[$q] = $sortTmp[$middleIndex];
    }    
    return @median;
}

# -------------------------------------------------------
#
# function: convFilter ()
#
# Purpose: convFilter a list of data points
#
# Req'd Parameters: 

#
# Limitation:  
#
#

#-----------------------------------------------


sub convFilter ($$) {

    my ($inArrRef, $filterRef) = @_;
    my @inarray = @$inArrRef;
    my @filter = @$filterRef;

    # use a filter with an odd number of entries
    push @filter, 0 if (@filter%2 == 0);

    my @conv = (0) x (@inarray );

    my $hwid = @filter/2;

    for (my $q=0; $q<=$#inarray; $q++) {
	my $lo = (($q-$hwid)>=0) ? (int ($q-$hwid)) : (int 0);
	my $hi = (($q+$hwid)<@inarray) ? (int ($q+$hwid)) : ($#inarray);
	my @tmp = @inarray[$lo .. $hi];

	foreach my $i (0 .. $#tmp) {
	    $conv[$q] += ( $tmp[$i] * $filter[@filter - @tmp + $i] );
	}
    }    
    return @conv;
}



# -------------------------------------------------------
#
# function: labelFormat ($$)
#
# Purpose: Take a value and truncate it to an appropriate number of decimals
#          based on the number of characters requested.  
#          Useful for putting labels on things
#
# Req'd Parameters: $value: the value to be formated
#                   $chars: the number of characters it has to fit
#
#
# Limitation:  
#
#

#-----------------------------------------------


sub labelFormat ($$) {
    my ($value,$chars) = @_;
    
    # need the number of characters left of the decimal
    my $whole = int $value;
    my $wholeChars = 1;
    $wholeChars = int (log10($whole) + 1) if ($whole>0);

    # if the number is just the right size, leave room for a decimal
    # ... otherwise $decimalChars (see below) will be negative
    $wholeChars-- if ($wholeChars == $chars);

    # if the number is too big, it'll be in sci-notn
    $wholeChars = 1 if ($wholeChars > $chars);


    # one of them is a decimal point
    my $digits = $chars - 1;
    my $decimalChars = $digits-$wholeChars;

    my $printForm;
    if ($value > 10**(-$decimalChars) && ($value < 10**($chars) ) ) {
	$printForm = "\%".sprintf "%d\.%df",$wholeChars,$decimalChars;
    } else {
	$printForm = "\%".sprintf ("\.%de",$digits-4);
    }

    return $printForm;
}



# -------------------------------------------------------
#
# function: histogram ($$)
#
# Purpose: Make a histogram with a bunch of data
#
# Req'd Parameters: $value: the value to be formated
#                   $chars: the number of characters it has to fit
#
#
# Limitation:  
#
#

#-----------------------------------------------


sub histogram ($$) {

    my ($valuesRef,$bins) = @_;

    my @values = @$valuesRef;

    my @valuesort = sort {$a <=> $b} @values;

    my $low = $valuesort[0];
    my $high = $valuesort[-1];
    my $range = $high - $low;
    my $binwidth = $range/$bins;
    
    my @histValues = (0)x$bins;
    my @binCentres = (0)x$bins;
    
    for (my $i=0; $i<$bins; $i++) {
	$binCentres[$i] = $low + ($i+0.5)*$binwidth;
    }
    
    # look at each value and see which bin i goes into
    foreach my $inValue (@values) {
	
	# check each bin
	for (my $q=0; $q<$bins; $q++) {
	    
	    # values on a bin boundary fall into the lower bin.
	    $histValues[$q]++ 
		if ( $inValue > ($low+$q*$binwidth) && 
		     $inValue <= ( $low+($q+1)*$binwidth) );
	}
	# add one to the first bin if its right on the border
	#  i've used  > for the low binlimit, but <= for the high
	#  ... so this is not a problem for the last bin.
	$histValues[0]++
	    if ( $inValue == $low ); 
	
    }

    return \@binCentres,\@histValues;
    
}









# -------------------------------------------------------
#
# function: centreText ($$)
#
# Purpose: Centre a string given the width of the line and an offset
#
# Req'd Parameters: $string: the string to centre
#                   $width: the width of the terminal
#
#
# Limitation:  
#
#

#-----------------------------------------------

sub centreText ($$) {

    my ($string_in, $width) = @_;

    my $len = length $string_in;
    my $indent = ($width - $len) / 2;
    my $string_out = sprintf "%${indent}s%s", " ", $string_in;

    return $string_out;

}






# -------------------------------------------------------
#
# function: integrate ($$)
#
# Purpose: Integrate a function
#
# Req'd Parameters: \@values:  ref to array containing refs to [x,y] values
#                   $x1:      start point
#                   $x2:      end point
#                   $numonly   boolean ... return only final value if set.
#
# Limitation:  
#
#
#-----------------------------------------------


sub integrate ($$$$) {

    my ( $values, $x1, $x2, $numonly ) = @_;

    my $n = 0;
    my $ylast = 0.0;
    my ($traptotal,$trapout,$deltax);
    my $xlast = $x1;

    my @integral = ();
    foreach my $valueref ( @$values ) {
	
	my ($x, $y) = @$valueref;
	
	if ( ($x >= $x1 ) && ($x <= $x2) ) {
	    
	    my $distToX2 = $x2-$x;
	    
	    if ( $x > $x1 ) {
		
		$deltax = ($x-$xlast);
		
		#my $midtotal += ( ($y + $ylast)/2 );
		$traptotal = ($ylast + $y);
		
		#my $midout = ($deltax)*$midtotal;
		$trapout += ($deltax/2)*$traptotal;
		
		#my $simpout = (1/3)*$trapout + (2/3)*$midout;
		
		push @integral, [$x, $trapout];
		
	    }
	    
	    # if we're on the last point, add the bit that extends to x2
	    if ( $x>$x1 && $x+$deltax > $x2 ) {
		$deltax = ($x2 - $x);
		my $deltay = ($y - $ylast);
		
		# y is now ylast, and the real y is a projected value
		$trapout += ($deltax/2.0)*( 2*$y + $deltay );
		push @integral, [$x2, $trapout];
	    }
	    
	    $xlast = $x;
	    $ylast = $y;
	    
	}
	
    }
    
    if ( $numonly ) {
	return $trapout;
    } else {
	return \@integral;
    }

}
