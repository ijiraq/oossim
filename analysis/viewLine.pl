#!/usr/bin/env perl
#
#

use strict;
use warnings;

use Local::Statistics;
use Local::Fit;

my $usage = "Usage: $0 infile [x:y:dy] [epsfile]\n".
    "   dump            - [1|0] gnuplot script dumpted to stdout\n".
    "   xlabel=boo      - set xlabel\n".
    "   ylabel=ya       - set ylabel\n".
    "   residlab=cha    - set ylabel for residual plot\n".
    "   title=something - set title\n".
    "   noplot          - [1|0] don't make the plot\n";

die $usage unless @ARGV;
die "$usage" if ( defined($ARGV[0])  && $ARGV[0] eq 'help');


#########################
# initializations

my $infile = shift @ARGV; #( ($ARGV[0]) and (-s $ARGV[0]) )? shift @ARGV : "-";
my $cols = "1:2";
my $epsfile;
my $dumping = 0;
my $noplot = 0;
my ($xlabel, $ylabel, $yresidlabel) = ("x", "f(x)", "y - f(x)");
my $title;

foreach my $arg (@ARGV) {
    
    $cols    = $arg if ( $arg =~ /^\d+:\d+.*/ );
    $epsfile = $arg if ( $arg =~ /.*\.eps$/   );
    $dumping = 1    if ( $arg =~ /^dump.*/    );
    $noplot  = 1    if ( $arg =~ /^noplot.*/  );
    ($xlabel)  = $arg =~ /^xlabel=(.*)$/  if ($arg =~ /^xlabel=/);
    ($ylabel)  = $arg =~ /^ylabel=(.*)$/  if ($arg =~ /^ylabel=/);
    ($yresidlabel) = $arg =~ /^residlab=(.*)$/ if ($arg =~ /^residlab=/);
    ($title)   = $arg =~ /^title=(.*)$/   if ( $arg =~ /^title=/);
}

$cols = "1:2" unless $cols;
my ($xColo, $yColo, $dyColo) = split /:/, $cols;
my $xCol = $xColo - 1;
my $yCol = $yColo - 1;
my $dyCol = $dyColo - 1 if ($dyColo);


my ($yfill, $arrow0fill, $arrowt1fill, $arrowb1fill) = (0.80, 0.80, 0.90, 0.70);
my ($arrowt2fill, $arrowb2fill) = (0.85, 0.75);
my ($marrowtfill, $marrowbfill) = (1.10, 1.00);


############################
# read in the data
my $tmpfile = "$ENV{HOME}/tmp/viewLine.tmp";
my $number = '[+-]?\d+\.?\d*';
my @data = ();
my @x;
my @y;

open (INFILE, "$infile");
open (TMPFILE, ">$tmpfile");
while (<INFILE>) { 
    next if $_=~/^\#/;
    my ($x, $y, $dy);
    ($x, $y, $dy) = (split)[$xCol, $yCol, $dyCol] if $dyCol;
    ($x, $y) = (split)[$xCol, $yCol] if ! $dyCol;
    die "Values missing in dy column ... exiting\n" if ($dyCol and !defined($dy));
    push @x, $x;
    push @y, $y;

    if ( $x=~/^$number$/ && $y=~/^$number$/ && ! defined($dy) ) {
	push @data, [$x, $y, 1.0]; 
	printf TMPFILE "$x $y\n";
    }
    if ( $x=~/^$number$/ && $y=~/^$number$/ && defined($dy) && $dy=~/^$number$/ ) {
	push @data, [$x, $y, $dy] ;
	printf TMPFILE "$x $y $dy\n";
    }
}
close (TMPFILE);
close (INFILE);
my $N = scalar @data;

$tmpfile = $infile unless $infile eq '-';

############################
# fit the line
my ($aa, $rms_aa, $bb, $rms_bb, $r, $X2) = map {sprintf "%.4f",$_} lineFit(\@data);
my $r2 = sprintf "%.4f", $r**2;


############################
# get an array of residuals
my @residuals;
foreach my $pt (@data) {
    my ($x, $y, $dy) = @$pt;
    my $fx = $aa + $bb*$x;
    push @residuals, ($y - $fx);
}
my ($min_resid, $max_resid) = range(\@residuals);
my $rms_resid = rms(\@residuals);


##############################
# make the plot

my $filename = $infile;

my ($term, $setoutput, $setsize) = ("x11", "", "set size 1,1");
my ($lw1, $lw2, $ps, $size) = (2, 1, 1, 1);
if (defined($epsfile)) {
    $term = "postscript eps enhanced color \"Helvetica\" 20";
    $setoutput = "set output \'${epsfile}\'";
    $size = 1;
    ($lw1, $lw2, $ps) = (3, 1, 1);
    ($filename = $infile) =~ s/\_/\\\_/g;

}


###########################33
#   MAKE A NICE TITLE
#
# handle underscores in the filename to print it in the title
#(my $unenhanced_infile = $infile) =~ s/_/\\_/g;
my $unenhanced_infile = $infile;
($unenhanced_infile = $infile) =~ s/_/\\_/g if (defined($epsfile));;

# get the date/time and add it to the title
my @month = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my @wday = qw(Su Mo Tu We Th Fr Sa);
my $mtime = ($infile eq '-') ? time() : (stat($infile))[9];
my ($ss,$mm,$hh,$mdy,$M,$Y,$wdy,$ydy,$isdst) = localtime($mtime);
$Y += 1900;
#$Y = $Y % 100;
my $infile_mtime = sprintf "$wday[$wdy] $Y $month[$M] $mdy %02d:%02d:%02d", $hh,$mm,$ss;

my $title_main = ($infile eq '-') ? 
    "<STDIN>  ($infile_mtime)" : "$unenhanced_infile   ($infile_mtime)";
    
# get host and user to put in the title
my $title_info = "Host: $ENV{HOSTNAME} User: $ENV{USER}";

$title = ( defined($title) ) ? 
    "\'$title\'":
    "sprintf(\"%s\\n\\n%s\\n\",\'$title_main\', \"$title_info\")";

my ($xmin, $xmax) = range(\@x);
my ($ymin, $ymax) = range(\@y);

my ($ylow, $yhigh) = ($ymin - 0.1*abs($ymin), $ymax+0.1*abs($ymax));
my $yrange = $yhigh - $ylow;

my $labelxL = 0.06;
my $labelxR = 0.60;
my $labely = 0.06;

my $keyside = ($bb>0) ? "left" : "right";
my $labelx = ($bb>0) ? $labelxL : $labelxR;
my $columns = ($dyCol) ? "1:2:3" : "1:2";
my $point = ($dyCol) ? "err" : "p";

# make the plot string
my $gpt_string = "#!/usr/bin/env gnuplot\n".
    "set terminal $term\n".
    "$setoutput\n".
    "\n".
    "LX=$size\n".
    "LY=$size\n".
    "set size LX,LY\n".
    "set lmargin 8\n".
    "OX=0.02*LX\n".
    "PX=0.98*LX\n".
    "\n".
    "set style line 1 lt 1 lw $lw1 lc rgb \"blue\"\n".
    "set style line 2 lt 1 lw $lw2 lc rgb \"blue\"\n".
    "set style line 3 pt 1 ps $ps lt 1 lw $lw1 lc rgb \"red\"\n".
    "\n".
    "\n".
    "set title $title\n".
    "set xlabel \'$xlabel\'\n".
    "set ylabel \'$ylabel\'\n".
    "\n".
    "\n".
    "xmin=$xmin\n".
    "xmax=$xmax\n".
    "ymin=$ylow\n".
    "ymax=$ymax\n".
    "set xrange [xmin:xmax]\n".
    "set yrange [ymin:ymax]\n".
    "\n".
    "set grid\n".
    "set key $keyside width 8 box\n".
    "\n".
    "\n".
    "###  VARIABLES  ####\n".
    "\n".
    "f(x,a,b) = a + b*x\n".
    "N = $N\n".
    "a = $aa\n".
    "b = $bb\n".
    "a_rms = $rms_aa\n".
    "b_rms = $rms_bb\n".
    "r = $r\n".
    "r2 = $r2\n".
    "X2 = $X2\n".
    "\n".
    "\n".
    "###  LABELS   #####\n".
    "\n".
    "labx=$labelx\n".
    "laby=$labely\n".
    "i=3.3\n".
    "set label 1 sprintf(\"N:   %d\",N) at gr labx, 1.0-i*laby left\n".
    "i=i+1\n".
    "set label 2 sprintf(\"a:   %.3g +/- %.3g\",a,a_rms) at gr labx, 1.0-i*laby left\n".
    "i=i+1\n".
    "set label 3 sprintf(\"b:   %.3g +/- %.3g\",b,b_rms) at gr labx, 1.0-i*laby left\n".
    "i=i+1\n".
    "set label 4 sprintf(\"r:   %.3g\",r) at gr labx,1.0-i*laby  left\n".
    "i=i+1\n".
    "set label 5 sprintf(\"r^2: %.3g\",r2) at gr labx,1.0-i*laby  left\n".
    "i=i+1\n".
    "set label 6 sprintf(\"X2:  %.3g\",X2) at gr labx,1.0-i*laby  left\n".
    "\n".
    "\n".
    "\n".
    "###   PLOTTING ### \n".
    "\n".
    "set multiplot\n".
    "\n".
    "###   MAIN PLOT ### \n".
    "\n".
    "set origin OX,0.3*LY\n".
    "set size PX, 0.7*LY\n".
    "\n".
    "plot \'${tmpfile}\' using $columns t \'data\' with $point ls 3,\\\n".
    "f(x, a, b) t \"f(x) = a + b*x\"  w l ls 1,\\\n".
    "f(x, a-a_rms, b+b_rms) t \"\" w l ls 2,\\\n".
    "f(x, a+a_rms, b-b_rms) t \"\" w l ls 2\n".
    "\n".
    "\n".
    "###   RESIDUALS  ### \n".
    "\n".
    "set title \"\"\n".
    "unset key\n".
    "unset label\n".
    "\n".
    "set ylabel \'$yresidlabel\'\n".
    "max_resid = $max_resid\n".
    "rms_resid = $rms_resid\n".
    "ymin = -max_resid - 2.0*rms_resid\n".
    "ymax = max_resid + 2.0*rms_resid\n".
    "set yrange [ymin:ymax]\n".
    "\n".
    "set origin OX,0*LY\n".
    "set size PX, 0.3*LY\n".
    "plot 0 w l ls 1,\\\n".
    "\'${tmpfile}\' u ${xColo}:(\$$yColo - f(\$$xColo,a,b)) t \"\" w p ls 3\n".
    "\n";


# open the pipe and print to it

unless ($noplot) {
    open (GNUPLOT, "|gnuplot -persist");
    print GNUPLOT "$gpt_string\n";
    close (GNUPLOT);
}

if ($dumping) {
    print STDOUT "$gpt_string\n";
}

my $fh = ($dumping) ? *STDERR : *STDOUT;
printf $fh "xmin = %.3f\n".
    "xmax = %.3f\n".
    "ymin = %.3f\n".
    "ymax = %.3f\n".
    "N = $N\n".
    "a     = $aa\n".
    "a_rms = $rms_aa\n".
    "b     = $bb\n".
    "b_rms = $rms_bb\n".
    "r     = $r\n".
    "r2    = $r2\n".
    "X2    = $X2\n".
    "rX2    = %.3f\n".
    "min_resid = %.4f\n".
    "max_resid = %.4f\n".
    "rms_resid = %.4f\n", 
    $xmin, $xmax, $ymin, $ymax,
    $X2/($N-2), $min_resid, $max_resid, $rms_resid;

# clean up
unlink ("$tmpfile") if $infile eq '-';
