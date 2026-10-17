#!/usr/bin/env perl
#
# original filename: phasePlot.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Thu Aug 16, 2007  13:28:50 DST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/working/TASS
#


use strict;
use warnings;
use File::Basename;

my $exe = basename($0);
my $usage = "Usage: $exe tsfile [cx:cy] [t=thresh] [o=oversample] [noforce] [dump] [{eps|png}file]\n";

my ($tsfile, @args) = @ARGV;
die $usage unless $tsfile;

my $number = '[+-]?\d+\.?\d*';
my ($tcol, $ycol) = (1,2);
my ($mono) = 0;
my ($pdmthresh,$oversample) = (100.0,16);
my ($force,$dumping, $pngfile, $epsfile) = (1, 0, "", "");
foreach my $arg (@args) {
    ($tcol,$ycol) = $arg =~ /(\d+):(\d+)/ if $arg=~/\d+:\d+/;
    $force = 0 if $arg=~/^noforce.*/;
    $dumping += 1 if $arg=~/^d.*/;
    $pngfile = $arg if $arg=~/.*\.png$/;
    $epsfile = $arg if $arg=~/.*\.eps$/;
    ($pdmthresh) = $arg =~ /t=($number)/ if $arg=~/t=($number)/;
    ($oversample) = $arg =~ /o=(\d+)/ if $arg=~/o=(\d+)/;
    $mono = 1 if $arg =~ /mono/;
}

my $pdmfile = "${tsfile}.pdm";
my $phasefile = "${tsfile}.ph1";
my $smthfile = "${tsfile}.smth1";

# pdmfile columns
my ($pcol, $pdmcol) = (2, 7);

# phase columns
my ($ph_tcol, $ph_ycol, $ph_ocol) = (1,2,4);

# run pdm
system("pdm -c ${tcol}:${ycol} -o $oversample $tsfile > $pdmfile");

# get the peaks and best period from the pdm file
my @lines = split /\n/, `getPeaks -c ${pcol}:${pdmcol} $pdmfile $pdmthresh`;
die "No peaks above $pdmthresh\n" unless @lines;
my @peaks = ();
foreach my $line ( @lines ) {
    push @peaks, [ split /\s+/,$line ];
}

@peaks = sort {$a->[1] <=> $b->[1]} @peaks;
my $period = $peaks[-1]->[0];

# need to read the pdmfile to get the range
my ($Pmin, $Pmax) = (0, 0);
open (PDMFILE, "$pdmfile");
while (<PDMFILE>) {
    next if /^\#/;
    my ($P,$prob) = (split)[$pcol-1,$pdmcol-1];
    $Pmin = $P if ($P < $Pmin or $Pmin == 0);
    $Pmax = $P if ($P > $Pmax or $Pmax == 0);
}
close(PDMFILE);

# phase the data.
(-s $phasefile && ! $force ) || system("phaseFold $tsfile $period ${tcol}:${ycol} > $phasefile");

# smooth the data.
my ($gauss, $width) = (1, 0.1*$period);
(-s $smthfile && ! $force ) || system("smoothC $phasefile ${ph_tcol}:${ph_ycol} $gauss $width > $smthfile");


# make plot script
my $setterm = "set term ";
if ($pngfile) {
    $setterm .= "png enhanced large";
} elsif ($epsfile) {
    $setterm .= "postscript eps enhanced color";
} else {
    $setterm .= "x11 enhanced font \"Helvetica\" 16\n";
}

my $setoutput = "";
$setoutput = "set out \'$pngfile\'" if $pngfile;
$setoutput = "set out \'$epsfile\'" if $epsfile;
(my $tsfilename = $tsfile) =~ s/_/\\_/g;

my $splot = "splot \'$smthfile\' using 1:2:(0) t \"\" w l ls 3,\\\n".
    "\'$phasefile\' using ${ph_tcol}:${ph_ycol}:${ph_ocol} t \"\" w p pt 7 ps 1.1 palette\n";
my $x2label = "";
if ($mono) {
    $splot = "plot \'$smthfile\' using 1:2 t \"\" w l ls 3,\\\n".
	"\'$phasefile\' using ${ph_tcol}:${ph_ycol} t \"\" w p ls 1\n";
    $x2label = "set x2label \'Phase\'";
}

my $gp_script = "#!/usr/bin/env gnuplot\n".
    "#\n".
    "$setterm\n".
    "$setoutput\n".
    "XSIZE=1.0\n".
    "YSIZE=1.0\n".
    "set size XSIZE,YSIZE\n".
    "MX=0.0*XSIZE\n".
    "MY=0.05*YSIZE\n".
    "PX=0.95*XSIZE\n".
    "PY=0.45*YSIZE\n".
    "set title \'${tsfilename}:   PDM (top), and phased with P=$period (bottom)\'\n".
    "set style line 1 pt 7 ps 1.2 lc rgb \"blue\"\n".
    "set style line 2 lt 1 lw 2 lc rgb \"red\"\n".
    "set style line 3 lt 1 lw 2 lc rgb \"red\"\n".
    "set multiplot\n".
    "set grid\n".
    "set log x\n".
    "set xrange [$Pmin:$Pmax]\n".
    "set size PX, PY\n".
    "set origin MX,PY+MY\n".
    "set xlabel \"Period\"\n".
    "set ylabel \"Probability Density\" offset -1,0\n".
    "plot \'$pdmfile\' using ${pcol}:${pdmcol} t \"\" w l ls 2\\\n".
    "\n".
    "unset title\n".
    "unset log\n".
    "set view map\n".
    "set xrange [0:2.0*$period]\n".
    "set x2range [0:2]\n".
    "set xtic nomirror\n".
    "set x2tic 0.2 nomirror\n".
    "set yrange [:]\n".
    "set arrow 1 from $period, gr 0 to $period, gr 1 nohead\n".
    "set origin MX,MY\n".
    "set format x \"%%.f\"\n".
    "set xlabel \"Time (column $tcol)\" offset -1,0\n".
    "$x2label\n".
    "set ylabel \"Column $ycol\"\n".
    "$splot\n";

# plot

open(GNUPLOT, "|gnuplot -persist");
printf GNUPLOT $gp_script;
printf STDOUT "$gp_script" if $dumping;
close(GNUPLOT);

exit 0;
