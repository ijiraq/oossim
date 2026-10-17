#!/usr/bin/env perl
#
# Steven Bickerton
# Dept. of Astrophysical Sciences, Princeton University
# bick@astro.princeton.edu
# Created: Fri Jul  4, 2008  13:46:02 DST
# Host: bender.astro.princeton.edu
# Working Directory: /Users/bick/working/radec

use strict;
use warnings;

use Getopt::Std;
use Local::Constants;
use Local::Astrotools;
use Local::Coords;

my $usage = "usage: $0 [options] infile gnuplot-pars\n".
    "  Options:\n".
    "    -a           all, same as -egm\n".
    "    -c width     shade a continuous viewing zone\n".
    "    -d           dump gnuplot script\n".
    "    -e           show ecliptic plane\n".
    "    -g           show galactic plane\n".
    "    -m           show months\n".
    "    -p file.eps  output to eps file\n".
    "    -u           units are degrees\n".
    "    -z latitude  show midnight zenith at latitude\n".
    "\n";


my %options = ();
getopts("aec:dghmp:uz:", \%options);

if (defined($options{a})) {
    $options{e} = $options{g} = $options{m} = 1;
}

my (@infiles, @gp_pars);
while( @ARGV ) {
    push @infiles, shift @ARGV;
    push @gp_pars, shift @ARGV;
}
die $usage unless ($infiles[0] or $infiles[0]=~/help/ or defined($options{h}) );


my ($term, $setout) =  ("x11 enhanced", "");
if (defined($options{p})) {
    $term = "postscript eps enhanced color dl 2.0";
    $setout = "set out \'$options{p}\'";
}
my $plot = "plot \\\n";


my $resolution = 0.99; #degrees
my $n_eq = 360.0/$resolution;
my @eqs = map {$resolution*$_} (0 .. $n_eq);

# generate the ecliptic plane
my $ecl_file = "$ENV{HOME}/tmp/ecliptic.dat";
if ( defined($options{e}) or defined($options{c}) ) {
    my @coords = ();
    for my $eq (@eqs) {
	push @coords, [ecl2cel(1.0*$eq, 0.0, "deg")];
    }
    @coords = sort {$a->[0]<=>$b->[0]} @coords;
    open(ECL, ">$ecl_file");
    for my $ref (@coords) {
	my ($RA, $dec) = @$ref;
	printf ECL "%.3f %.3f\n", $RA/15.0, $dec;
    }
    close(ECL);
    if (defined($options{c}) ) {
	$plot .= "\'$ecl_file\' u 1:(\$2+$options{c}):(\$2-$options{c}) t \"\" w filledcurves above y1=0.0 lc rgb \"#bbbbbb\",\\\n";
    }
    $plot .= "\'$ecl_file\' u 1:2 t \"EP\" w l ls 2,\\\n";

}



# generate the galactic eq.
my $gal_file = "$ENV{HOME}/tmp/galactic.dat";
if ( defined($options{g}) ) {
    my @coords = ();
    for my $eq (@eqs) {
	push @coords,  [gal2cel(1.0*$eq, 0.0, "deg")];
    }
    @coords = sort {$a->[0]<=>$b->[0]} @coords;
    open(GAL, ">$gal_file");
    for my $ref (@coords) {
	my ($RA, $dec) = @$ref;
	printf GAL "%.3f %.3f\n", $RA/15.0, $dec;
    }
    close(GAL);
    $plot .= "\'$gal_file\' u 1:2 t \"GP\" w l ls 3,\\\n";
}


# generate zenith line
my $zen_file = "$ENV{HOME}/tmp/zenith.dat";
if ( defined($options{z}) ) {
    my @coords = ();
    for my $eq (@eqs) {
	push @coords, [ecl2cel(1.0*$eq, $options{z}, "deg")];
    }
    @coords = sort {$a->[0]<=>$b->[0]} @coords;
    open(ZEN, ">$zen_file");
    for my $ref (@coords) {
	my ($RA, $dec) = @$ref;
	printf ZEN "%.3f %.3f\n", $RA/15.0, $dec;
    }
    close(ZEN);
    $plot .= "\'$zen_file\' u 1:2 t \"ZP\" w l ls 3,\\\n";

}


# handle data from stdin
my $tmp = "$ENV{HOME}/tmp/plotRadec.tmp";
if ($infiles[0] =~ /^-$/) {
    open(IN, "$infiles[0]");
    open(TMP, ">$tmp");
    while(<IN>) { print TMP $_;  }
    close(TMP);
    close(IN);
    $infiles[0] = $tmp;
}
my $axes = ($options{u}) ? "axes x2y1" : "";

for my $i (0 .. $#infiles) {
    $gp_pars[$i] = "u 1:2 w p lt $i pt 7 ps 1" unless $gp_pars[$i];
    $plot .= "\'$infiles[$i]\' $gp_pars[$i]";
    $plot .= ",\\\n" if $i < $#infiles;
}

# make month labels
my $setmonths = "";
if ( $options{m} ) {
    my @mon = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    for my $i (1 .. 12) {
	my $j = $i - 1;
	my $JD = calendar2JD(2008, $i, 15, 0, 01, 0.0);
	my ($ra1, $dec1, $ra2,$dec2) = getRADecOfElongAtDate(179.0, $JD);
	$ra2 /= 15.0;
	$setmonths .= "set label $i \"$mon[$j]\" at $ra2,gr 0.04 center\n";
    }
}


# make the plot
my $gp = "#!/usr/bin/env gnuplot\n".
    "set term $term\n".
    "$setout\n".
    "set xrange [0:24]\n".
    "set x2range [0:360]\n".
    "set yrange [-90:90]\n".
    "set xlabel \"Right Ascension (Hrs)\"\n".
    "set x2label \"RA (Deg)\"\n".
    "set ylabel \"Declination (Deg)\"\n".
    "set xtic 3 nomirror\n".
    "set x2tic 45 nomirror\n".
    "set grid\n".
    "set key top horizontal\n".
    "$setmonths\n".
    "set style line 1 lt 1 lw 1 lc rgb \"black\"\n".
    "set style line 2 lt 2 lw 1 lc rgb \"black\"\n".
    "set style line 3 lt 3 lw 1 lc rgb \"black\"\n". 
    "set style fill solid 0.4 nobord\n".
    "$plot\n";

open(GP, "|gnuplot -persist");
print GP $gp;
print STDOUT $gp if ($options{d});
close(GP);

exit 0;
