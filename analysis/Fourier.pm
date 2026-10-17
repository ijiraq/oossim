#!/usr/bin/env perl
# Perl Module:  Fourier.pm
#
# Purpose: a Perl module  containing subroutines to generate fake timeseries
#          data and get a powerspectrum
# Author: Steve Bickerton, McMaster University
#         bick@physics.mcmaster.ca
#         Thurs. Jan. 26, 2006
# Functions:   makeNoise() powerSpectrum()
#
#

package  Local::Fourier;

use strict;
use warnings;
use Carp;

use Math::Random qw( random_normal random_uniform random_set_seed );
use Math::FFT;
use Math::Trig;

use Local::Constants;
use Local::Statistics qw( rms );


require  Exporter;

our @ISA       = qw( Exporter );
our @EXPORT    = qw( makeNoise powerSpectrum );
our @EXPORT_OK = qw();
our @EXPORT_TAGS = ( ALL => [ @EXPORT_OK ], );
our $VERSION   = 1.00;


sub log2 ($) {
    my $n = shift;
    croak "Can't take log of negative number: $n\n" if $n<0;
    return log($n)/log(2);
}

my $number = '[+-]?\d+\.?\d*';

sub makeNoise ($$$$) {

    my $usage = "Use: \$ts_ref = makeNoise(\$beta, \$dt, \$points, \$rms);\n".
	"       \$ts_ref = \\\@ts with [t, real, f, power] as entries\n";

    my ($beta, $dt, $Nreq, $rms) = @_;
    croak $usage unless (  $beta =~ /^$number$/ && 
			   $dt   =~ /^$number$/ &&
			   $Nreq =~ /^\d+$/     &&
			   $rms  =~ /^$number$/    );

    my @seed = (time, time);
    random_set_seed(@seed);

    # make sure N is a power of 2
    my $log2Nreq = log2($Nreq);
    my $lowGuess = int($log2Nreq);
    $Nreq = 2**($lowGuess+1) if ( $lowGuess != $log2Nreq );
    my $N = $Nreq;

    # generate the fake power spectrum
    my @FT = (0)x(2*$N);
    
    my ($mean, $std) = (0.0, 1.0);
    my @gaussian  = random_normal($N, $mean, $std);
    my @phase     = random_uniform($N, 0, $TWOPI);
    
    my $T = $N*$dt;
    my $df = 1.0 / $T;
    my $dw = $TWOPI*$df;
    my $mag_sum = 0.0;
    for (my $k=1; $k<$N/2; $k++) {
	
	my $f = $k*$df;
	my $mag = ($f)**(-$beta/2.0) * $gaussian[$k];
	
	$FT[2*$k]              = $mag * cos($phase[$k]);  # real
	$FT[2*$k + 1]          = $mag * sin($phase[$k]);  # imag

	$FT[2*$N - 2*$k]       =   $FT[2*$k];       # real -ve freq
	$FT[2*$N - 2*$k + 1]   =  -$FT[2*$k + 1];   # imag -ve freq

	$mag_sum += 2.0 * $mag * $mag;  # x2 for +ve and -ve freqs
    }

    my $A = $rms * $N / sqrt($mag_sum);
    @FT = map {$_ * $A} @FT;

    @FT[0,1, $N, $N+1] = ($N,0,0,0);  # the DC components


    # invert to get the time-series
    my $cspec = new Math::FFT(\@FT);
    my $cts   = $cspec->invcdft(\@FT);

    # return the time-series and the spectrum
    my @timeseries;
    for (my $k=0; $k<$N; $k++) {
	
	my $t = $k*$dt;
	my $I = $cts->[2*$k];
	my $f = $k*$df;
	my $power = ($FT[2*$k]**2 + $FT[2*$k+1]**2);
	push @timeseries, [ $t,   $I,     $cts->[2*$k],   $cts->[2*$k+1], 
			    $f,   $power, $FT[2*$k],      $FT[2*$k+1]   ];
    }
        
    return \@timeseries;
}






sub powerSpectrum ($) {

    my $usage = "Usage: \$spectrum = powerSpectrum(\@timeseries)\n".
	"     \\\@timeseries has [\$t, \$value] entries\n";

    my ($timeseries) = @_;
    croak $usage unless $timeseries;

    my $is_complex = (ref $$timeseries[0]->[1]) ? 1 : 0;
    my @t          = map { $_->[0] } @$timeseries;
    my $Ntmp = scalar @t;
    my @all_values;
    if ($is_complex) {
	foreach my $tsref (@$timeseries) {
	    push @all_values,  ($tsref->[1]->[0], $tsref->[1]->[1]);
	}
    } else {
	for (my $j=0; $j<$Ntmp; $j++) {
	    my ($t,$re) = @{$timeseries->[$j]};
	    $all_values[2*$j] = $re;
	    $all_values[2*$j+1] = 0;
	}
    }
    
    my $Nall = scalar @all_values;
    $Nall /= 2 if $is_complex;

    # truncate the list at a power of 2
    my $power2lo = int(log2($Nall));
    my $N = 2**($power2lo);
    my $lastindex = ($is_complex) ? 2*$N-1 : $N-1;
    #my $lastindex = 2*$N-1;
    my @value = @all_values[0..$lastindex];

    # pad with zeros up to a power of 2
    #my $power2lo = int(log2($Nall));
    #my $N = 2**($power2lo + 1);
    #my @value = (@all_values, (0)x($N-$Nall));


    # get the freq step
    my $dT = ( $t[1] - $t[0] );
    my $df = 1.0 / (($N/2)*$dT);

    # get the FFT
    my $ts = new Math::FFT(\@value);
    my $ft = $ts->cdft(); 

    # return the spectrum
    my $nhalf = $N/2;
    my $q = (scalar @$ft)/2;
    my @spectrum;

    foreach my $i (0 .. $q-1) {
	
	my $real = $ft->[2*$i];
	my $imag = $ft->[2*$i+1];
	my $phase = atan2($imag,$real);
	my $power = ($real**2 + $imag**2);

	$real = 0 if $i==0;  # don't care about the DC offset
	push @spectrum, [$i*$df, $power, $phase, $real, $imag];

    }
    
    return \@spectrum;
}
