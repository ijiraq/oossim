package Local::Statistics;


use 5.008003;
use strict;
use warnings;
use Carp;

use Local::Constants;

require Exporter;


our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Local::Statistics ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
		 sum mean rms srms median mode kurt skew max min range
		 moment moment_mean medianInsitu allstats meanRmsClip
		 meanClip rmsClip fwhm binWidth
		 factorial binomCoef binomDist poissonDist 
		 gamma Fdist chi2dist
		 wmean
		 );

our $VERSION = '0.01';

# Preloaded methods go here.


sub sum($) {
    my ($data_ref) = @_;

    my $sum = 0;
    foreach my $value (@$data_ref) {
	$sum += $value;
    }
    return $sum;
}

sub mean($) {
    my ($data_ref) = @_;
    
    my $sum = sum($data_ref);
    my $n = scalar @$data_ref;
    my $mean = ($n) ?  ($sum / (scalar @$data_ref) ) : 0;

    return $mean;
}

sub wmean($) {
    my ($data_ref) = @_;
    
    my @refs = @$data_ref;
    my $n = scalar @refs;

    my ($sum, $wsum);
    foreach my $ref (@refs) {
      my ($value, $err) = @$ref;
      my $w = 1.0/$err**2;
      $sum += $w*$value;
      $wsum += $w;
    }
    my $wmean = ($n) ?  ($sum / $wsum) : 0;

    return $wmean;
}

sub rms($) {
    my ($data_ref) = @_;
    
    my @sqrs = map {$_**2} @$data_ref;
    my $mean = mean ($data_ref);
    my $mean_sqrs = mean (\@sqrs);
    my $rms = sqrt( abs($mean_sqrs - $mean**2) );
    
    return $rms;
}


# the sample rms
sub srms($) {
    my ($data_ref) = @_;
    
    my @sqrs = map {$_**2} @$data_ref;
    my $sum = sum ($data_ref);
    my $sum_sqrs = sum (\@sqrs);
    my $N = scalar @sqrs;
    my $rms = sqrt( abs($N*$sum_sqrs - $sum**2)/($N*($N-1))  );
    
    return $rms;
}



sub median($) {
    my ($data_ref) = @_;

    my @data_sort = sort {$a<=>$b} @$data_ref;

    my $n = scalar @data_sort;
    my $nBy2 = int ($n / 2);

    return 0 if ($n==0);

    # if odd take the middle value, if even avg the two middle values
    my $median;
    if ( $n % 2 == 0 ) {
	$median = ($data_sort[$nBy2] + $data_sort[$nBy2-1] ) / 2.0;
    } else {
	$median = $data_sort[$nBy2];
    }

    return $median;
}


sub medianInsitu($) {
    my ($data_ref) = @_;

    @$data_ref = sort {$a<=>$b} @$data_ref;

    my $n = scalar @$data_ref;
    my $nBy2 = int ($n / 2);

    return 0 if ($n==0);

    # if odd take the middle value, if even avg the two middle values
    my $median;
    if ( $n % 2 == 0 ) {
	$median = ($$data_ref[$nBy2] + $$data_ref[$nBy2-1] ) / 2.0;
    } else {
	$median = $$data_ref[$nBy2];
    }

    return $median;
}


sub mode($$) {
    my ($data_ref, $bins) = @_;

    my ($max) = max($data_ref);
    my ($min) = min($data_ref);
    my $n = scalar @$data_ref;
    return 0 if ($n == 0);

    $bins = ($bins) ? ($bins) : sqrt($n);
    my $incr = ( $max - $min ) / $bins ;

    return $max if ($incr==0);

    my @hist = (0)x$bins;
    foreach my $value ( @$data_ref ) {
	my $index = int ( ($value - $min) / $incr );
	$hist[$index]++;
    }
    my ($max_hist, $max_hist_i) = max (\@hist);
    
    my $mode = $min + $incr*($max_hist_i+0.5);

    return $mode;
}


sub moment ($$) {
    my ($data_ref, $r) = @_;

    my @x2theR = map {$_**$r} @$data_ref;
    my $n = scalar @$data_ref;
    my $moment = ($n) ? ( sum(\@x2theR) / $n ) : 0;

    return $moment;
}


sub moment_mean ($$) {
    my ($data_ref, $r) = @_;

    my $mean = mean($data_ref);
    my @data = map {$_ - $mean} @$data_ref;
    my $moment_mean = moment(\@data, $r);

    return $moment_mean;
}


sub kurt($) {
    my ($data_ref) = @_;

    my $rms = rms($data_ref);
    my $fourth_moment = moment_mean($data_ref, 4);
    my $kurt = ($rms) ? ( $fourth_moment / $rms**4 ) : 0;

    return $kurt;
}


sub skew($) {
    my ($data_ref) = @_;

    my $rms = rms($data_ref);
    my $third_moment = moment_mean($data_ref, 3);
    my $skew = ($rms) ? ( $third_moment / $rms**3 ) : 0;

    return $skew;
}

sub max($) {
    my ($data_ref) = @_;

    return 0 if (scalar @$data_ref == 0 );
    
    my $max = $$data_ref[0];
    my $max_index = 0;
    my $i = 0;
    foreach my $value (@$data_ref) {
	($max, $max_index) = ($value, $i) if ($value>$max);
	$i++;
    }
    return ($max, $max_index);
}

sub min($) {
    my ($data_ref) = @_;

    return 0 if (scalar @$data_ref == 0 );

    my $min = $$data_ref[0];
    my $min_index = 0;
    my $i = 0;
    foreach my $value (@$data_ref) {
	($min, $min_index) = ($value, $i) if ($value<$min);
	$i++;
    }
    return ($min, $min_index);
}


sub range($) {

    my ($data_ref) = @_;

    return 0 if (scalar @$data_ref == 0);

    my ($min, $max) = ( $$data_ref[0], $$data_ref[0] );
    my ($min_index, $max_index) = ( 0, 0 );
    my $i = 0;
    foreach my $value (@$data_ref) {
	($min, $min_index) = ($value, $i) if ($value<$min);
	($max, $max_index) = ($value, $i) if ($value>$max);
	$i++;
    }

    return ($min, $max, $min_index, $max_index);
}

sub allstats($) {
    my ($d) = @_;
    return ( mean($d),median($d),rms($d), (max($d))[0], (min($d))[0], 
	     skew($d),kurt($d) );
}





sub meanRmsClip ($$$$) {
    
    my ($value_ref, $nSigma, $tol, $iter) = @_;
    
    my @values = @$value_ref;
    my $n = scalar @values;

    return (0,0,0) if $n == 0;
    return ($values[0],0,0) if $n == 1;

    my ($i, $k, $nGood);
    my ($mean, $mean_last, $rms, @goodvalues);

    #my $subsamp = ($subsamp<$n) ? ($subsamp) : ($n);  
    #my $step = int ($n/$subsamp);
    #my $hstep = $step / 4;

    $mean = mean($value_ref);
    $rms = rms ($value_ref);

    my $k_final = 0;

    foreach my $k (0 .. $iter-1) {

	$nGood = 0;
	
	foreach my $i (0.. $n-1) {
	    push @goodvalues, $values[$i] 
		if ( abs($values[$i] - $mean) < $nSigma*$rms );
	    last if ($nGood >= $n);
	}
	
	last if ($nGood >= $n);
	
	$mean_last = $mean;

	$mean = mean(\@goodvalues);
	$rms = rms(\@goodvalues);


	$k_final = $k;
	last if ( $mean_last && abs(($mean_last - $mean)/$mean_last) < $tol   );
	last if ( $mean_last == $mean );

    }

    return ($mean, $rms, $k_final);
}


sub meanClip ($$$$) {
    my ($value_ref, $nSigma, $tol, $maxiter) = @_;
    my ($mean, $rms, $iter) = meanRmsClip($value_ref, $nSigma, $tol, $maxiter);
    return $mean;
}

sub rmsClip ($$$$) {
    my ($value_ref, $nSigma, $tol, $maxiter) = @_;
    my ($mean, $rms, $iter) = meanRmsClip($value_ref, $nSigma, $tol, $maxiter);
    return $rms;
}


sub fwhm ($) {
    my ($data_ref) = @_;

    my @values = map {$_->[1]} @$data_ref;
    my ($max, $index) = max(\@values);

    my ($set_lo, $set_hi) = (0,0);
    my ($lo, $hi) = (0,0);
    my $max_bin;
    foreach my $ref (@$data_ref) {
	my ($bin, $value) = @$ref;

	if ($value > $max/2.0 && $set_lo==0) {
	    $lo = $bin;
	    $set_lo = 1;
	}
	if ($value > $max/2.0) {
	    $hi = $bin;
	}
	$max_bin = $bin if ( $value == $max );
    }

    return ($lo, $hi, $max_bin);

}


sub binWidth ($$) {
    my ($N,$rms) = @_;
    return $rms*(20.0/$N)**(0.2);
}


sub factorial ($) {
    my ($N) = @_;

    my $Nint = ($N == int($N)) ? $N : int($N);
    carp "factorial(): value should be an integer. Truncating $N to $Nint\n" 
	unless ($N == $Nint);
    croak "factorial(): value must be >= zero.\n" unless ($Nint >= 0);

    my $factorial = 1;
    if ($N > 50 ) {
	$factorial = sqrt($TWOPI) * sqrt($N) * $N**($N) * $EXP**(-$N) *
	    (1.0 + 1.0/(12.0*$N) + 1.0/(288.0*$N*$N) + 139.0/(51840*$N*$N*$N));
    } else {
	$factorial = 1;
	foreach my $i ( reverse 1 .. $Nint) { $factorial *= $i; }
    }

    return $factorial;
}


sub binomCoef ($$) {

    my ($n, $k) = @_;

    croak "binomCoefs(): n must be greater than k\n" unless $n>$k;

    my $nfact = factorial($n);
    my $kfact = factorial($k);
    my $nmkfact = factorial($n-$k);

    return $nfact/($kfact*$nmkfact);
}


sub binomDist ($$$) {

    my ($p, $t, $n) = @_;

    croak "binomDist(): n must be greater than t\n" unless $n>$t;
    croak "binomDist(): p must be between 0 and 1\n" unless ($p>=0 && $p<=1.0);

    my $n_choose_t = binomCoef($n,$t);
    my $q = 1.0 - $p;

    return $n_choose_t * $p**$t * $q**($n-$t);
}


sub poissonDist ($$) {

    my ($rate, $n) = @_;
    croak "n must be an integer.\n" unless ($n == int($n));
    return $rate**$n * $EXP**(-$rate) / factorial($n);
}



sub gamma ($) {
    my ($n) = @_;
    croak "usage: \$gamma = gamma(\$n);\n" unless $n =~ /$is_number/;

    my $gamma;
    
    # if $n is a positive integer
    if ( $n>0 && abs($n-int($n)) < 1.0e-12 ) {
	$gamma = factorial(int($n)-1);

    # if $n is a negative integer  cluck and error
    } elsif ( $n<0 && abs($n-int($n)) < 1.0e-12) {
	carp "Warning: Gamma(x) not defined for neg. integers. Return 0\n";
	return 0;

    # if $n is a positive half-integer
    } elsif ( $n>0 &&  abs($n-0.5 - int($n-0.5) < 1.0e-12)  ) {
	my $m = $n-0.5;	
	$gamma = $sqrtPI/2.0**$m;
	foreach my $i (1 .. $m) { $gamma *= 2.0*$i-1.0; }

    # if $n is a negative half-integer
    } elsif ($n < 0  &&  abs($n -0.5 - int($n-0.5) < 1.0e-12) ) {
	my $m = -($n-0.5);
	$gamma = $sqrtPI * (-1.0)**$m * 2**$m;
	foreach my $i (1 .. $m) { $gamma /= 2.0*$i-1.0; }
    } else {
	# if $n is an arbitrary number (warning ... only good to a few digits)
	$n -= 1;
	my $gamma = $sqrtTWOPI * sqrt($n) * $n**$n * $EXP**(-$n) *
	    (1.0 + 1.0/(12.0*$n) + 1.0/(288.0*$n*$n) + 139.0/(51840*$n*$n*$n));
    }
    
    return $gamma;
}


sub Fdist ($$$) {
    my ($f, $v1, $v2) = @_;
    my $g1 = gamma( ($v1+$v2)/2.0 );
    my $g2 = gamma( $v1/2.0 );
    my $g3 = gamma( $v2/2.0 );
    my $termMath = ($v1**($v1/2.0)) * ($v2**($v2/2.0));
    my $func1Math = $f**($v1/2.0-1.0);
    my $func2Math = ($v2 + $v1*$f)**(-($v1+$v2)/2.0);
    #my $termBev = ($v1/$v2)**($v1/2.0);
    #my $func1Bev = $f**(($v1-2.0)/2.0);
    #my $func2Bev = (1.0+$f*$v1/$v2)**(1.0/(2.0*($v1+$v2) ));

    my $term = $termMath * $func1Math * $func2Math;
    #my $term = $termBev * $func1Bev * $func2Bev;

    my $P = $g1/($g2*$g3) * $term;
    return  $P;
}


sub chi2dist ($$) {

    my ($x2, $v) = @_;
    my $usage = "\$chi2dist = chi2dist(\$x2, \$v);\n";
    croak $usage."x2 must be a number\n" unless ($x2 =~ /$is_number/);
    croak $usage."v must be a number\n" unless ($v =~ /$is_number/);

    my $term1 = 1.0/( (2.0**($v/2.0)) * gamma($v/2.0) );
    my $term2 = $x2**(($v-2.0)/2.0);
    my $term3 = $EXP**(-$x2/2.0);

    return $term1 * $term2 * $term3;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Local::Statistics - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Local::Statistics;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Local::Statistics, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Steve Bickerton, E<lt>bickersj@hia.nrc.caE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Steve Bickerton

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
