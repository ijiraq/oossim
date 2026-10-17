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
my $usage = "Usage: $exe gpscript datafile1 col1 datafile2 col2 ...\n";

my ($gpscript, @args) = @ARGV;
die $usage unless @args;

my (@datafiles, @cols);
while (@args) {
    push @datafiles, shift @args;
    push @cols, shift @args;
}

my ($epsfile, @N, @mean, @rms, @median, @skew, @kurt, @min, @max, @A, 
    @kmax, @red_chi2, @histfile, @kernfile );

foreach my $i (0 .. $#datafiles) {

    my $datafile = $datafiles[$i];
    my $col = $cols[$i] - 1;

    my @variates;
    open (DATAFILE, "$datafile") or die "opening datafile: $!";
    while(<DATAFILE>) {
	next if /\#/;
	my ($x) = (split)[$col];
	push @variates, $x;
    }
    close (DATAFILE);
    
    ($epsfile = $gpscript) =~ s/gp$/eps/;
    
    my $N    = $N[$i]    = scalar @variates;
    my $mean = $mean[$i] = mean(\@variates);
    my $rms  = $rms[$i]  = rms(\@variates);
    my $median = $median[$i] = median(\@variates);
    my $skew   = $skew[$i]   = skew(\@variates);
    my $kurt   = $kurt[$i]   = kurt(\@variates);
    my ($min, $max) =  ($min[$i], $max[$i]) = range(\@variates);
    
    my $sigmaTrunc = 5.0;
    my $binwidth = $rms*(20.0/$N)**(0.2);
    my $resolution = $binwidth/10.0;
    my $low = $median - $sigmaTrunc*$rms;
    my $high = $median + $sigmaTrunc*$rms;
    
    
    my ($kbins, $kvals) = 
	kernelhist(\@variates, $resolution, $binwidth, "gauss","density", $low, $high);
    my ($bins, $vals) = 
	kernelhist(\@variates, $binwidth, $binwidth, "boxcar","x", $low, $high);
    my $histfile = $histfile[$i] = "hist${i}.dat";
    my $kernfile = $kernfile[$i] = "kern${i}.dat";

    # dump the histograms
    open (HIST, ">$histfile");
    open (KERN, ">$kernfile");
    foreach my $j (0 .. scalar @$bins - 1) {
	
	printf HIST "%.5f %.5f\n", $$bins[$j], $$vals[$j];
	printf KERN "%.5f %.5f\n", $$kbins[$j], $$kvals[$j];
	
    }
    close (HIST);
    close (KERN);
    
    
    my ($hmax) = max($vals);
    ($kmax[$i]) = max($kvals);

    my $fitcommand = "mlfit $histfile \"f(x)=A*(2.7182818)**(-(x-$mean)**2/(2*($rms)**2))\" $min $max 1:2 A=5000";
    my @fitresult= split /\n/,`$fitcommand`;
    my $A = $A[$i] = (split /\s+/,$fitresult[1])[2];
    
    sub gauss ($$$$) {
	my ($x,$A,$mean,$rms) = @_;
	return $A*$EXP**(-($x-$mean)**2/(2.0*$rms**2));
    }
    
    
    # get the chi^2 value
    my $chi2=0;
    my $Nbins = 0;
    foreach my $j (0 .. $#{@$bins}) {
	
	if ($$vals[$j]) {
	    my $chi2tmp = ( $$vals[$j]-gauss($$bins[$j], $A, $mean, $rms) )**2;
	    $chi2tmp /= gauss($$bins[$j],$A,$mean,$rms);
	    $chi2 += $chi2tmp;
	    $Nbins++;
	}
    }
    my $red_chi2 = $red_chi2[$i] = $chi2/($Nbins - 3);  # 3 degrees of freedom
    
    printf STDOUT "$datafile: skew: %.4f  kurt: %.4f   chi2: %.3f   Nbins: %d   v: %.3f\n", $skew, $kurt, $chi2, $Nbins, $red_chi2;
    
}

# open the gnuplot script and sub the values
my $script = "";
open (SCRIPT, "$gpscript");
while(<SCRIPT>) {
    $script .= $_;
}
close (SCRIPT);

my $script2 = "";
for ( $script2 = $script) {

    foreach my $i (0 .. $#datafiles) {
	s/EPSFILE/$epsfile/g;
	s/NPOINTS${i}/$N[$i]/g;
	s/MEAN${i}/$mean[$i]/g;
	s/MEDIAN${i}/$median[$i]/g;
	s/STDDEV${i}/$rms[$i]/g;
	s/SKEWNESS${i}/$skew[$i]/g;
	s/KURTOSIS${i}/$kurt[$i]/g;
	s/MAXVALUE${i}/$max[$i]/g;
	s/MINVALUE${i}/$min[$i]/g;
	s/HMAX${i}/$A[$i]/g;
	s/KMAX${i}/$kmax[$i]/g;
	s/CHISQUARED${i}/$red_chi2[$i]/g;
	s/HISTFILE${i}/$histfile[$i]/g;
    }
    
}


open (GNUPLOT, "| gnuplot") or die "opening gnuplot: $!";
print GNUPLOT $script2;
close (GNUPLOT);

open (DUMP, ">dump.gp");
print DUMP $script2;
close (DUMP);


exit 0;
