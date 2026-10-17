#!/usr/bin/env perl
#
# original filename: oneOverF.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Mon Jan 16, 2006  17:01:37 EST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/working/oneOverF
#

use strict;
use warnings;

use Local::Filters;
use Local::Statistics;
use Local::Fourier;


my $usage = "Usage: $0 beta dt points rms binwidth kernel\n";

my ($beta, $dt, $Nreq, $rms, $binwidth, $kernel) = @ARGV;
die $usage unless $kernel;

# make the timeseries and smooth it
my $timeseries = makeNoise($beta, $dt, $Nreq, $rms);
my $smooth_ts = smooth2($timeseries,$binwidth,$kernel);


# now divide by the smoothed version to cancel to low frequency signals
my @smoothed;
foreach my $j (0 .. $#{@$smooth_ts} ) {
    my $ts_entry = $timeseries->[$j];
    my $sm_entry = $smooth_ts->[$j];
    push @smoothed, $ts_entry->[1]/$sm_entry->[1];
}

# we'll need the new rms to make sure that we still generate the req. rms
my $rms_new = rms(\@smoothed);

# output
foreach my $i ( 0 .. $#smoothed ) {
    my ($t, $Itmp, $real, $imag, $f, $power, $Freal, $Fimag) = 
	@{$timeseries->[$i]};
    my $I = ($smoothed[$i] - 1.0)*($rms/$rms_new) + 1.0;
    printf STDOUT "%.6f %.8f   %.8f %.8f   %.6f %.8f  %.8f %.8f".
	"\n", $t, $I, $real, $imag, $f, $power, $Freal, $Fimag;
}

exit 0;
