#!/usr/bin/env perl
#
# original filename: xcorVariates.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Thu Sep 21, 2006  19:48:00 DST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/working/phd_figures/xcorVariates
#


use strict;
use warnings;
use File::Basename;

use Local::Constants;
use Local::Statistics;
use Local::Histogram;

my $exe = basename($0);
my $usage = "Usage: $exe datafile column [bin=binwidth] [flag=number]\n";

my ($datafile, $col) = @ARGV;
die $usage unless ( $datafile and $col=~/^\d+$/ );
die $usage if $datafile =~ /help/;
shift @ARGV;
shift @ARGV;

my $binwidth = 0;
my $flag = 0;
foreach my $arg (@ARGV) {
    if ($arg =~ /^bin/) {
	($binwidth) = $arg =~ /bin=(.*)/;
    }
    if ($arg =~ /^flag/) {
	($flag)     = $arg =~ /flag=(.*)/;
    }
}
my $coli = ($col) ? $col-1 : 0;



my @variates;
open (DATAFILE, "$datafile") or die "opening datafile: $!";
while(<DATAFILE>) {
    next if /^\#/;
    my ($x) = (split)[$coli];
    push @variates, $x;
}
close (DATAFILE);

my $histfile = $datafile.".hist";
my $kernfile = $datafile.".kern";
my $statfile = $datafile.".stat";



#######################################################################
# get the stats
my $N          = scalar @variates;
my $mean       = mean(\@variates);
my $rms        = rms(\@variates);
my $median     = median(\@variates);
my $skew       = skew(\@variates);
my $skew_rms   = $skew / (sqrt(15.0/$N));
my $kurt       = kurt(\@variates);
my $kurt_rms   = ($kurt-3.0) / (sqrt(96.0/$N));
my ($min, $max)= range(\@variates);
my ($min_rms, $max_rms) = (($min-$mean)/$rms, ($max-$mean)/$rms);

my ($nSigma, $tol, $iter) = (3.0, 0.001, 3);
my ($meanC, $rmsC) = meanRmsClip(\@variates, $nSigma, $tol, $iter);

my $sigmaTrunc = 5.0;
$binwidth = $rms*(20.0/$N)**(0.2) unless $binwidth > 0.0;
my $resolution = $binwidth/10.0;
my $low = $median - $sigmaTrunc*$rms;
my $high = $median + $sigmaTrunc*$rms;


#######################################################################
# bin the data into histograms and smoothed versions.
my ($kbins, $kvals) =  bin(\@variates, $binwidth, "gauss");
my ($bins, $vals)   =  bin(\@variates, $binwidth, "boxcar");



#######################################################################
# dump the histograms
open (HIST, ">$histfile");
open (KERN, ">$kernfile");
foreach my $j (0 .. scalar @$bins - 1) {
    printf HIST "%.5f %.5f\n", $$bins[$j], $$vals[$j];
}
foreach my $j (0 .. scalar @$kbins - 1) {
    printf KERN "%.5f %.5f\n", $$kbins[$j], $$kvals[$j];
}
close (HIST);
close (KERN);


#######################################################################
# fit the data
my $A = $binwidth*$N/$sqrtTWOPI;
my $fitcommand = "mlfit $histfile \"f(x)=($A/rms)*($EXP)**(-(x-mean)**2/(2*(rms)**2))\" $min $max 1:2 mean=$meanC rms=$rmsC";
my @fitresult= split /\n/,`$fitcommand`;
my $meanFit = (split /\s+/,$fitresult[1])[2];
my $rmsFit = (split /\s+/,$fitresult[2])[2];

sub gaussN ($$$$) {
    my ($x,$N,$mean,$rms) = @_;
    return ($binwidth*$N/($sqrtTWOPI*$rms))*$EXP**(-($x-$mean)**2/(2.0*$rms**2));
}

        
#######################################################################
# get the chi^2 value
my $chi2=0;
my $Nbins = 0;
foreach my $j (0 .. $#{@$bins}) {
    
    if ($$vals[$j]) {
	my $chi2tmp = 
	    ( $$vals[$j]-gaussN($$bins[$j], $N, $meanFit, $rmsFit) )**2;
	$chi2tmp /= gaussN($$bins[$j],$N,$meanFit,$rmsFit);
	$chi2 += $chi2tmp;
	$Nbins++;
    }
}
my $dof = $Nbins - 2;
my $red_chi2 = $chi2/$dof;  # 2 degrees of freedom

my $chi2sig = `chi2dist $red_chi2 $dof -r`;
chomp $chi2sig;
$chi2sig = 0.0 if $chi2sig =~ /nan/;
$chi2sig =~ s/^\# (\d+\.\d+)/$1/;


my $histmax = $binwidth*$N/($sqrtTWOPI*$rms);

#######################################################################
# output
my $stats = sprintf "".
    "exp             = $EXP\n".
    "N${flag}        = %d\n".
    "mean${flag}     = %.4g\n".
    "meanC${flag}    = %.4g\n".
    "rms${flag}      = %.4g\n".
    "rmsC${flag}     = %.4g\n".
    "median${flag}   = %.4g\n".
    "skew${flag}     = %.4g\n".
    "skew_rms${flag} = %.3f\n".
    "kurt${flag}     = %.4g\n".
    "kurt_rms${flag} = %.3f\n".
    "min${flag}      = %.4g\n".
    "min_rms${flag}  = %.3f\n".
    "max${flag}      = %.4g\n".
    "max_rms${flag}  = %.3f\n".
    "meanFit${flag}  = %.4g\n".
    "rmsFit${flag}   = %.4g\n".
    "binwidth${flag} = %.4g\n".
    "dof${flag}      = %d\n".
    "chi2${flag}     = %.4g\n".
    "redchi2${flag}  = %.4g\n".
    "chi2sig${flag}  = %s\n".
    "histmax${flag}  = %.4g\n".
    "G${flag}(x)= binwidth${flag}*N${flag}/(sqrt(2*pi)*rmsFit${flag})*exp**(-(x-meanFit${flag})**2/(2.0*rmsFit${flag}**2))\n",
    $N,
    $mean,
    $meanC,
    $rms,
    $rmsC,
    $median,
    $skew,
    $skew_rms,
    $kurt,
    $kurt_rms,
    $min,
    $min_rms,
    $max,
    $max_rms,
    $meanFit,
    $rmsFit,
    $binwidth,
    $dof,
    $chi2,
    $red_chi2,
    $chi2sig,
    $histmax;


open (STATFILE, ">$statfile");
printf STATFILE $stats;
close (STATFILE);

printf STDOUT $stats;

exit 0;
