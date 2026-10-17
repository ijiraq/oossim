#!/usr/bin/env perl
#
#

use strict;
use warnings;

use File::Basename;

use lib "$ENV{HOME}/libperl";
use Local::Statistics;
use Local::Histogram;

my $usage = "Usage: $0 [infile] [col]\n".
    "   other options:  nostat xlabel logy, [xmin:xmax], file.eps, dump\n";

die "$usage" if ( defined($ARGV[0])  && $ARGV[0] eq 'help');

my $date = `date`;
chomp $date;

# initializations
( $ARGV[0] ) and ( -s $ARGV[0] ) or unshift(@ARGV, "-");
my $infile = shift @ARGV;
my $number = '[+-]?\d+\.*\d*';
my ($logy, $col, $dumpscript, $epsfile) = (0,0,0);
my ($xrange, $title);
my $includelabels = "";
my $binwidth;
my $xlabel;
foreach my $arg (@ARGV) {

    $col = $arg     if ($arg =~ /^\d+$/);
    $dumpscript = 1 if ($arg =~ /^dump$/);
    $epsfile = $arg if ($arg =~ /\w+\.eps$/);
    $logy = 1       if ($arg =~ /^logy?$/);
    $xrange = $arg  if ($arg =~ /^\[${number}\:${number}\]$/);
    ($xlabel) = $arg =~ /^xlabel=(.*)$/ if ($arg =~ /^xlabel=.*$/);
    ($title) = $arg =~ /^title=(.*)$/ if ($arg =~ /^title=.*$/ );
    $includelabels = "unset label"    if ($arg =~ /^nostat$/);
    ($binwidth) = $arg =~ /^binwidth=(.*)$/ if ($arg =~/^binwidth=.*$/);

}


$col = ($col) ? ($col-1) : 0;
my $logscale = ($logy) ? "set logscale yy2" : "";
my ($nSigma, $tol, $iter) = (3.0, 0.001, 20);
my ($y2label, $ylabel) = ("dN/dx", "N");
my ($htmpfile, $ktmpfile) = ("hist.tmp", "kern.tmp");

my $filename = basename $infile;
$filename =~ s/_/\\_/g;
my $colNum = $col+1;
$xlabel = "Column: $colNum" unless defined($xlabel);


# read in the data
my @data = ();
open (INFILE, "$infile");
while (<INFILE>) { 
    next if $_=~/^\#/;
    my ($value) = (split)[$col];
    push @data, $value if $value=~/^$number$/; 
}
close (INFILE);

# get the stats on the distributions
my $N = scalar @data;
my ($meanF, $medianF, $rmsF, $maxF, $minF, $skewF, $kurtF) = allstats(\@data);
my ($mean, $median, $rms, $max, $min, $skew, $kurt) = 
    map {sprintf "%.4f", $_} ($meanF, $medianF, $rmsF, $maxF, $minF, $skewF, $kurtF);

my ($meanClipF, $rmsClipF) =  meanRmsClip(\@data, $nSigma, $tol, $iter);
my ($meanClip, $rmsClip) =  map {sprintf "%.4f", $_} ($meanClipF, $rmsClipF);

my ($min_rms, $max_rms) = 
    map {sprintf "%.4f", $_} (($minF-$meanF)/$rmsClipF, ($maxF-$meanF)/$rmsClipF);

# run histogram code to make the hist plots
$binwidth = $rmsClip*(20.0/$N)**(0.2) unless $binwidth;
my $resolution = $binwidth/10.0;
my $low = $median - 5.0*$rmsClip;
my $high = $median + 5.0*$rmsClip;

my ($kbins, $kvals) = 
    bin(\@data, $binwidth, "gauss");
my ($bins, $vals) = 
    bin(\@data, $binwidth, "boxcar");


# dump the histogram curves to tmp files
open (HTMP, ">$htmpfile");
foreach my $i (0.. @$bins-1) { printf HTMP "$$bins[$i] $$vals[$i]\n"; }
close (KTMP);

open (KTMP, ">$ktmpfile");
foreach my $i (0 .. @$kbins-1) { printf KTMP "$$kbins[$i] $$kvals[$i]\n"; }
close (HTMP);



########################################################################
# make the plot

# make a header for the script file ... in case you want to keep it.

my $host;
if ( $ENV{HOST} ) {
    $host = "$ENV{HOST}";
} elsif ( $ENV{HOSTNAME} ) {
    $host = "$ENV{HOSTNAME}";
}
$host = "unknown" if (! $host);
my $cwd = ( $ENV{PWD} ) ? "$ENV{PWD}" : `pwd`;
$cwd = "unknown" if ( ! $cwd );

my $header = "#!/usr/bin/env gnuplot\n".
    "#\n".
    "# Steven Bickerton\n".
    "# Dept. of Physics/Astronomy, McMaster University\n".
    "# bick\@physics.mcmaster.ca\n".
    "# Made with plot.pl $date\n".
    "# Host: $host\n".
    "# Working Directory: $cwd\n".
    "#\n";


my $term = "set terminal x11 enhanced";
my $output = "";
if ($epsfile) {
    $term = "set terminal postscript eps enhanced dl 4 color \"Helvetica\" 20";
    $output = "set output \'$epsfile\'";
}


# get the dimensions for the labels and arrows

my ($kmax) = max($kvals);
my ($hmax) = max($vals);

my ($yfill, $ycrossbar, $meanLine_dy) = (0.80, 0.80, 0.10);
my ($rmsLine_dy)= (0.05);
my ($medLine_dy) = (0.10);

my $y2max = $kmax/$yfill;  # how much of the screen to fill
my $ymax = $hmax/$yfill;   # same for y and y2 axes
my $ymin = ($logy) ? (0.5) : 0;
my $y2min= ($logy) ? (0.5*$kmax/$hmax) : 0;

my $mytics = ($logy) ? "set mytics 10" : "";
my $my2tics = ($logy) ? "set my2tics 10" : "";

my $labelx = 0.03;
my $labely = 0.05;

my $setxrange = (defined $xrange) ? "set xrange $xrange" : "set xrange [xmin:xmax]";

$title = "file: $filename  ($date)" unless $title;

# make the plot string
my $gpt_string = "$header".
    "\n".
    "$term\n".
    "$output\n".
    "\n".
    "set title \'$title\'\n".
    "set xlabel \'$xlabel\'\n".
    "set ylabel \'$ylabel\'\n".
    "set y2label \'$y2label\'\n".
    "set ytics scale 2,1 nomirror\n".
    "set y2tics scale 2,1\n".
    "$mytics\n".
    "$my2tics\n".
    "\n".
    "set border lw 1.3\n".
    "set grid lw 2\n".
    "\n".
    "\n".
    "###########  ranges  ##############\n".
    "\n".
    "xmin=$low\n".
    "xmax=$high\n".
    "ymin=$ymin\n".
    "ymax=$ymax\n".
    "y2max=$y2max\n".
    "y2min=$y2min\n".
    "$setxrange\n".
    "set yrange [ymin:ymax]\n".
    "set y2range [y2min:y2max]\n".
    "\n".
    "\n".
    "#########  Variables   #############\n".
    "N=$N\n".
    "mean=$mean\n".
    "median=$median\n".
    "rms=$rms\n".
    "meanC=$meanClip\n".
    "rmsC=$rmsClip\n".
    "skew=$skew\n".
    "kurt=$kurt\n".
    "min=$min\n".
    "max=$max\n".
    "max_rms=$max_rms\n".
    "min_rms=$min_rms\n".
    "\n".
    "labx=$labelx\n".
    "laby=$labely\n".
    "\n".
    "\n".
    "#########  Stats labels  ###########\n".
    "\n".
    "i=1\n".
    "set label 10 sprintf(\"N:      %d\",N) at gr labx, (1.0-i*laby) left\n".
    "i=i+1\n".
    "set label 20 sprintf(\"mean:   %.4f\",mean) at gr labx, (1.0-i*laby) left\n".
    "i=i+1\n".
    "set label 50 sprintf(\"meanC:  %.4f\",meanC) at gr labx, (1.0-i*laby) left\n".
    "i=i+1\n".
    "set label 40 sprintf(\"RMS:    %.4f\",rms) at gr labx, (1.0-i*laby) left\n".
    "i=i+1\n".
    "set label 60 sprintf(\"RMSC:   %.4f\",rmsC) at gr labx, (1.0-i*laby) left\n".
    "i=i+1\n".
    "set label 30 sprintf(\"median: %.4f\",median) at gr labx, (1.0-i*laby) left\n".
    "i=i+1\n".
    "set label 70 sprintf(\"skew:   %.4f\",skew) at gr labx, (1.0-i*laby) left\n".
    "i=i+1\n".
    "set label 80 sprintf(\"kurt:   %.4f\",kurt) at gr labx, (1.0-i*laby) left\n".
    "i=i+1\n".
    "set label 90 sprintf(\"min:    %.4f\",min) at gr labx, (1.0-i*laby) left\n".
    "i=i+1\n".
    "set label 100 sprintf(\" (sig): %.4f\",min_rms) at gr labx, (1.0-i*laby) left\n".
    "i=i+1\n".
    "set label 110 sprintf(\"max:    %.4f\",max) at gr labx, (1.0-i*laby) left\n".
    "i=i+1\n".
    "set label 120 sprintf(\" (sig): %.4f\",max_rms) at gr labx, (1.0-i*laby) left\n".
    "\n".
    "\n".
    "$includelabels\n".
    "\n".
    "j=1\n".
    "set label 10 sprintf(\"N:      %d\",N) at gr labx, (1.0-j*laby) left\n".
    "\n".
    "#########  Stat dimensions  ############\n".
    "\n".
    "hmax   = $yfill\n".
    "y_mn   = hmax*$ycrossbar\n".
    "mn_dy  = hmax*$meanLine_dy\n".
    "sd_dy  = hmax*$rmsLine_dy\n".
    "y_md   = hmax*1.0\n".
    "md_dy  = hmax*$medLine_dy\n".
    "\n".
    "set arrow 1 from mean,gr y_mn-mn_dy to mean,gr y_mn+mn_dy nohead\n".
    "set arrow 2 from (mean-rmsC),gr y_mn to (mean+rmsC),gr y_mn nohead\n".
    "set arrow 3 from (mean-rmsC),gr y_mn-sd_dy to (mean-rmsC),gr y_mn+sd_dy nohead\n".
    "set arrow 4 from (mean+rmsC),gr y_mn-sd_dy to (mean+rmsC),gr y_mn+sd_dy nohead\n".
    "set arrow 5 from median,gr y_md+md_dy to median,gr y_md\n".
    "\n".
    "\n".
    "set style line 1 lt 1 lw 2 lc rgb \"black\"\n".
    "set style line 2 lt 2 lw 2 lc rgb \"black\"\n".
    "\n".
    "${logscale}\n".
    "\n".
    "plot \'${htmpfile}\' using 1:2 axes x1y1 t \"\" with histeps ls 1,\\\n".
    "\'${ktmpfile}\' using 1:2 axes x1y2 t \"\" with line ls 2\n".
    "\n";


# open the pipe and print to it
open (GNUPLOT, "|gnuplot -persist");
print GNUPLOT "$gpt_string\n";
print STDOUT "$gpt_string\n" if ($dumpscript);
close (GNUPLOT);


# clean up
unlink ("$htmpfile", "$ktmpfile") unless ($dumpscript);

