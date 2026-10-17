#!/usr/bin/env perl
# Perl Module:  Fit.pm
#
# Purpose: a Perl module  containing a subroutine to do a maximum liklihood
#          fit to a given function and parameters.
# Author: Steve Bickerton, McMaster University
#         bick@physics.mcmaster.ca
#         Fri. Jan. 13, 2006
# Functions:   maxLik()
#
#

package  Local::Fit;

use strict;
use warnings;
use Carp;
use Local::Constants;
use Local::Misc;
use Math::Trig;

require  Exporter;

our @ISA       = qw( Exporter );
our @EXPORT    = qw( maxLik lineFit qFit lnL lnLi_powerSpec lnLi_gauss
		     lnLi_psSmth);
our @EXPORT_OK = qw();
our @EXPORT_TAGS = ( ALL => [ @EXPORT_OK ], );
our $VERSION   = 1.00;




# -------------------------------------------------------
#
# function: lineFit
#
# Purpose: Given a function and parameters, return the linear regression
#          values of the parameters
# Req'd Parameters: $data - data reference $data = \@data = \($xi, $yi, $dyi)
#
# Limitation:
#
# Source: Numerical Recipes pp. 662
#-----------------------------------------------

sub lineFit ($) {

    my ($data) = @_;

    my @data = @$data;
    my $N = scalar @data;
    
    my $no_err = 0;
    my ($S, $Sx, $Sy, $Sxx, $Sxy);
    foreach my $pt_ref (@data) {

	my ($x, $y, $dy) = @$pt_ref;
	if (! defined($dy) ) { $dy = 1.0; $no_err++; }# assume a constant;

	my $var = $dy**2;

	$S    +=  1.0   / $var;
	$Sx   +=  $x    / $var;
	$Sy   +=  $y    / $var;
	$Sxx  +=  $x**2 / $var;
	$Sxy  +=  $x*$y / $var;
	
    }

    my ($Stt, $Sty);
    if ($no_err) {
	foreach my $pt_ref (@data) {
	    my ($x, $y) = @$pt_ref;
	    $Stt += ($x - $Sx/$S)**2;
	    $Sty += ($x - $Sx/$S)*$y;
	}
    }
    
    my $Delta = $S*$Sxx - $Sx**2;
    my $bb = ($no_err) ? (1.0/$Stt)*$Sty  : ( $S*$Sxy - $Sx*$Sy ) / $Delta;
    my $aa = ($no_err) ? ($Sy-$Sx*$bb)/$S : ( $Sxx*$Sy - $Sx*$Sxy ) / $Delta;
    my $var_aa = ($no_err) ? (1.0/$S)*(1.0+$Sx**2/($S*$Stt)) : $Sxx / $Delta;
    my $var_bb = ($no_err) ? (1.0/$Stt)                      : $S / $Delta;
    my $rms_aa = sqrt($var_aa);
    my $rms_bb = sqrt($var_bb);

    # coefficient of correlation
    my $cov_ab = ($no_err) ? (-$Sx/($S*$Stt))            : (-$Sx/$Delta);
    my $r_ab =   ($no_err) ? ($cov_ab/($rms_aa*$rms_bb)) : -$Sx/sqrt($S*$Sxx);

    # get chi_squared
    my $X2;
    foreach my $pt_ref (@data) {
	my ($x, $y, $dy) = @$pt_ref;
	$dy = 1.0 unless $dy;
	$X2 += ( ($y - $aa - $bb*$x) / $dy )**2;
    }

    return ($aa, $rms_aa, $bb, $rms_bb, $r_ab, $X2);

}



# -------------------------------------------------------
#
# function: qFit
#
# Purpose: Given a function and parameters, return the linear regression
#          values of the parameters for the log10() of the data
# Req'd Parameters: $data - data reference $data = \@data = \($xi, $yi, $dyi)
#
# Limitation:
#
# Source: Numerical Recipes pp. 662
#-----------------------------------------------


sub qFit ($) {

    my ($data_ref) = @_;

    my @data;
    foreach my $pt_ref (@$data_ref) {
	my ($x, $y, $dy) = @$pt_ref;
	$dy = 1.0 unless defined($dy);
	croak "Can't take log10(\$y) if y<=0 ... exiting\n" unless ($y>0);
	push @data, [ log10($x), log10($y), $dy/$y ];
    }

    return lineFit(\@data);
}





########################################################################
#
#  Maximum liklihood  codes
#
#########################################################################


# individual log liklihood for a set of parameters and data coords
my $logRoot2PI = log($sqrtTWOPI);
sub lnLi_powerSpec ($$$$) {
    my ($beta, $A, $f, $mag) = @_;
    if ($A<=0) {
	return 0;
    }
    #printf STDERR "A $A  f $f  beta $beta\n";
    my $s = $A*$f**$beta;
    return -$logRoot2PI - log($s) - $mag**2/(2.0*$s**(2.0));
}

# individual log liklihood for a set of parameters and data coords
sub lnLi_psSmth ($$$$) {
    my ($beta, $A, $f, $mag) = @_;
    if ($A<=0) {
	return 0;
    }
    #printf STDERR "A $A  f $f  beta $beta\n";
    my $s = $A*$f**$beta;
    my $gauss = $EXP**(-$f**4/(2.0*1.0));
    $s *= (1.0-$gauss);
    return -$logRoot2PI - log($s) - $mag**2/(2.0*$s**(2.0));
}



# a handy test case 
sub lnLi_gauss ($$$) {
    my ($mean, $s, $x) = @_;
    return -$logRoot2PI - log($s) - ($x-$mean)**2/(2.0*$s**(2.0));
}




# -------------------------------------------------------
#
# function: lnL
#
# Purpose: Given a function and parameters, return the sum of log likelihood
#          for a set of the parameters
# Req'd Parameters: $data - data reference
#                   $lnLf - function reference
#                   \@param - the parameters
#                   \@ds - derivative step sizes
#
# Limitation:
#
# Source: 
#-----------------------------------------------

sub lnL ($$$$) {
    my ($data, $lnLfunc, $param_ref, $ds_ref) = @_;
    my @param = @$param_ref;
    my @ds = @$ds_ref;
    my ($lnL, @lnLp, @lnLm, @paramP, @paramM);

    # add ds to each parameter
    foreach my $i (0 .. $#param) { 
	$paramP[$i] = $param[$i] + $ds[$i]; 
	$paramM[$i] = $param[$i] - $ds[$i]; 
    }

    # get the contribution of each point
    foreach my $pt (@$data) {

	$lnL  += $lnLfunc->(@param, @$pt);

	# get the values at +/- ds of each point
	foreach my $i (0 .. $#param) {
	    my @param_tmp = @param;
	    $param_tmp[$i] = $paramP[$i];
	    $lnLp[$i] += $lnLfunc->(@param_tmp, @$pt);
	    @param_tmp = @param;
	    $param_tmp[$i] = $paramM[$i];
	    $lnLm[$i] += $lnLfunc->(@param_tmp, @$pt);
	}

    }

    # get the derivative of lnL using the point-derivatives
    my (@dParam, @ddParam);
    foreach my $i (0 .. $#param) { 
	$dParam[$i] = ($lnLp[$i] - $lnL)/$ds[$i]; 
	$ddParam[$i] = ($lnLp[$i] - 2.0*$lnL + $lnLm[$i])/$ds[$i]**2;
	#foreach my $j ($i .. $#param) {
	#    $ddParam[$i][$j] = ($lnLp[$i] - 2.0*$lnL + $lnLm[$i])/$ds[$i]**2;
	#}
	#printf STDERR "$param[$i]  $lnLp[$i]   $lnL    $lnLm[$i]   $ds[$i]\n";
    }

    return ($lnL, \@dParam, \@ddParam);
}



# -------------------------------------------------------
#
# function: maxLik
#
# Purpose: Given a function and parameters, return the maximum likelihood
#          values of the parameters
# Req'd Parameters: $data - data reference
#                   $lnLf - function reference
#                   \@param - the parameters
#                   \@ds - derivative step sizes
#                   \@tol - the tolerances
# Limitation:
#
# Source: 
#-----------------------------------------------

sub maxLik ($$$$$) {
    my ($data, $lnLf, $param, $ds, $tol) = @_;

    my $max_iter = 100;
    my @param = @$param;
    my @param_old = @param;

    # use Newtons method to find the roots of the derivative function
    # ... ie. us x_new = x - f''/f' instead of x_new = x - f'/f

    open (PATH, ">maxLpath.dat");
    my $stepCondition = 1;
    my $i = 0;
    my ($lnL, $ddx, $d2dx2);
    while ($stepCondition && $i<$max_iter) {
	
	# get the log liklihood with the new parameters
	($lnL, $ddx, $d2dx2) = lnL($data, $lnLf, \@param, $ds);
	my @dParam = @$ddx;
	my @ddParam = @$d2dx2;
	my @param_old = @param;	

	# get the new parameters
	printf PATH "%.4f %.4f %.4f", @param, $lnL;
	$stepCondition = 0;
	foreach my $j (0 .. $#param) {
	    if ($ddParam[$j] == 0) {
		printf STDERR "Warning \$ddParam[$j]==0\n";
		#return (\@param, $i);
	    }

	    my $ddParam;
	    foreach my $k (0 .. $#param) {
		$ddParam += $ds->[$j]*$ddParam[$j]/$ds->[$k];
	    }
	    
	    my $incr = $dParam[$j]/$ddParam;
	    
	    #$incr = ( $dParam[$j-1]*$ddParam[$j] - $dParam[$j]*$ddParam[$j-1] )
	    #	/   ( $ddParam[$j-1]**2 - $ddParam[$j]*$ddParam[$j-1] );
	    
	    #printf STDERR "%.3g  %.3g   %.3g  %.3g\n", $dParam[$j-1]*$ddParam[$j], $dParam[$j]*$ddParam[$j-1], $ddParam[$j-1]**2, $ddParam[$j]*$ddParam[$j-1];
	    my $scale = 1.0;
	    $param[$j] = $param_old[$j] - $scale*$incr;
	    my $error = abs( $scale*$incr/$param_old[$j] );
	    $stepCondition = 1 if ($error > $$tol[$j]);
	    #printf STDERR "$incr $error    $$tol[$j]\n";
	    printf PATH "   %.6f %.6f", $dParam[$j], $ddParam[$j];
	}
	printf PATH "\n";

	$i++;
    }
    close (PATH);

    return \@param, $i;
}


