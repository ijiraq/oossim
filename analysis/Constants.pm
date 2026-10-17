#!/usr/bin/env perl
# Perl Module:  Constants.pm
#
# Purpose: a Perl module  containing commonly used physical/astro constants
# Author: Steve Bickerton, McMaster University
#         bick@physics.mcmaster.ca
#         Thurs. Sep. 22, 2005

package  Local::Constants;

use warnings;

use Carp;


###########     Constants        ##############

my @mathConstants = qw($PI $TWOPI $PIHALF $EXP $sqrtTWOPI $sqrtPI 
		       $RAD $DEG $ASperRAD);

my @physConstants = qw($G_SI $G_CGS $C_SI $C_CGS $EP_SI $MU_SI $h_SI 
		       $h_CGS $hBAR_SI $hBAR_CGS $e_C $e_ESU
		       $k_SI $k_CGS $k_EV $h_EV $hBAR_EV 
		       $R_SI $R_CGS $ao_SI $ao_CGS $RH_SI $RH_CGS
		       $sigma_SI $a_SI $a_CGS $NA_SI);

my @massConstants = qw($mp_KG $mp_G $mn_KG $mn_G $me_KG $me_G
		       $mH_KG $mH_G $amu_KG $amu_G $amu_REL
		       $mp_AMU $mn_AMU $me_AMU);

my @astroConstants = qw($Mo_CGS $Mo_G $Lo_CGS $Ro_CGS $Ro_CM $Ro_M $Teff_K 
			$Me_CGS $Me_G $Re_CGS $Re_CM $Mo_KG $Mo_SI
			$Me_SI $Me_KG $Re_M $Re_SI);

my @astroConversions = qw($LY_CM $PC_CM $PC_LY $AU_CM $SID_DAY $SOL_DAY
			  $SID_YR $TROP_YR $Ho_SI $PC_M $CMperLY $PC_M 
			  $MperPC $CMperPC $KMperPC $LYperPC $CMperAU 
			  $KMperAU $MperAU $AUperPC $RAD_ARCSEC 
			  $AU_M $AU_KM $MperAU $AU_CGS $ARCSECperRAD
			  $SECperDAY $SECperWK $SECperMONTH $SECperYR 
			  $SECperMYR $SECperGYR $HT_SEC $SECperHT
			  $Mj_CGS $Mc_CGS $Mm_CGS $M1_CGS);

my @astroMisc       = qw( $JD2000 );

my @miscConstants   = qw( $is_number );

push my @allConstants,
    @mathConstants, @physConstants, @massConstants,
    @astroConstants, @astroConversions, @astroMisc, @miscConstants;

push (my @allExports, @allConstants);

require  Exporter;
our @ISA       = qw( Exporter );
our @EXPORT    = @allExports;
our @EXPORT_OK = qw();
our @EXPORT_TAGS = ( ALL => [ @EXPORT_OK ], );
our $VERSION   = 1.00;


*is_number   = \('[+-]?\d+\.?\d*');

*PI       = \3.141_592_653_589_793_238_462_643_383_279;
*TWOPI    = \(2.0*$PI);
*sqrtPI   = \sqrt($PI);
*sqrtTWOPI= \sqrt($TWOPI);
*PIHALF   = \($PI/2.0);
*EXP      = \2.718_281_828_459_045_235_360_287_471_352;
*RAD      = \($PI/180.0);
*DEG      = \(180.0/$PI);
*ASperRAD = \(3600.0*180.0/$PI);

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


#particle charges and masses
*amu_KG   = \1.6605402e-27;      # kg
*amu_G    = \1.6605402e-24;      # g
*amu_REL  = \931.49432;          # MeV c^-2

*e_C      = \1.60217733e-19;     # C
*e_ESU    = \4.803206e-10;       # esu
*mp_KG    = \1.6726231e-27;      # kg
*mp_G     = \1.6726231e-24;      # g
*mp_AMU   = \($mp_KG/$amu_KG);   # amu
*mn_KG    = \1.674929e-27;       # kg
*mn_G     = \1.674929e-24;       # g
*mn_AMU   = \($mn_KG/$amu_KG);   # amu
*me_KG    = \9.1093897e-31;      # kg
*me_G     = \9.1093897e-28;      # g
*me_AMU   = \($me_KG/$amu_KG);   # amu
*mH_KG    = \1.673534e-27;       # kg
*mH_G     = \1.673534e-24;       # g
*mH_AMU   = \($mH_KG/$amu_KG);   # amu

#plank's const
*h_SI     = \6.6260755e-34;      # J   s
*h_CGS    = \6.6260755e-27;      # erg s
*h_EV     = \($h_SI/$e_C);       # eV  s
*hBAR_SI  = \1.05457266e-34;     # J   s
*hBAR_CGS = \1.05457266e-27;     # erg s
*hBAR_EV  = \($hBAR_SI/$e_C);    # eV  s

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
*k_EV     = \($k_SI/$e_C);           # eV     K^-1

# Stefan-Boltzman const
*sigma_SI = \5.67051e-8;         # J    m^-2  s^-1  K^-4
*sigma_CGS= \5.67051e-5;         # erg  cm^-2 s^-1  K^-4

# Radiation const  (what is this?)
*a_SI     = \7.56591e-16;        # J    m^-3  K^-4
*a_CGS    = \7.56591e-15;        # erg  cm^-3 K^-4

# avagadro's number
*NA_SI    = \6.0221367e23;       # mole^-1

# Solar stuff

*Mo_CGS   = \1.989e33;           # g
*Mo_G     = \1.989e33;           # g
*Mo_KG    = \1.989e30;           # kg
*Mo_SI    = \1.989e30;           # kg (SI)
*Lo_CGS   = \3.826e33;           # erg  s^-1
*Ro_CGS   = \6.9599e10;          # cm
*Ro_CM    = \6.9599e10;          # cm
*Ro_M     = \6.9599e8;           # m
*Teff_K   = \5770;               # K

# Earth stuff
*Me_CGS   = \5.974e27;           # g
*Me_G     = \5.974e27;           # g
*Me_KG    = \5.974e24;           # kg
*Me_SI    = \5.974e24;           # kg
*Re_CGS   = \6.378e8;            # cm
*Re_CM    = \6.378e8;            # cm
*Re_M     = \6.378e6;            # m
*Re_SI    = \6.378e6;            # m


# Misc Masses
*Mj_CGS   = \1.899e30;           # g   Jupiter
*Mm_CGS   = \7.35e25;            # g   Moon
*Mc_CGS   = \9.5e20;             # g   Ceres
*M1_CGS   = \5.24e14;            # g   1 km diameter asteroid w rho=1.0

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
*AU_KM    = \1.4960e8;           # km
*AU_M     = \1.4960e11;          # m
*AU_CM    = \1.4960e13;          # cm
*CMperAU  = \1.4960e13;          # cm
*AU_CGS   = \1.4960e13;          # cm (CGS)
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

*SECperDAY    = \($SOL_DAY);                         # s
*SECperWK     = \(7.0*$SOL_DAY);                     # s
*SECperMONTH  = \(31.0*$SOL_DAY);                    # s
*SECperYR     = \(365.24*$SECperDAY);                # s
*SECperMYR    = \(1e6*$SECperYR);                    # s
*SECperGYR    = \(1e9*$SECperYR);                    # s
*HT_SEC       = \( 1.0 / ($Ho_SI/($KMperPC*1e6)) );  # s
*SECperHT     = \($HT_SEC);                          # s 



*JD2000       = \2451545.00;         # days

