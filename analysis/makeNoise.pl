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

use Local::Fourier;


my $usage = "Usage: $0 beta dt Npoints rms\n";

my ($beta, $dt, $Nreq, $rms) = @ARGV;
die $usage unless $rms;

my $timeseries = makeNoise($beta, $dt, $Nreq, $rms);

foreach my $entry (@$timeseries) {

    my ($t, $I, $real, $imag, $f, $power, $Freal, $Fimag) = @$entry;
    printf STDOUT "%.6f %.6f   %.6f %.6f   %.6f %.6f  %.6f %.6f".
	"\n", $t, $I, $real, $imag, $f, $power, $Freal, $Fimag;

}

exit 0;
