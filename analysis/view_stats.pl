#!/usr/bin/env perl
#
#

use strict;
use warnings;

use File::Basename;

use Local::Constants;
use Local::Statistics;
use Local::Histogram;

my $usage = "Usage: $0 [infile] [col] [logy] [epsfile]\n".
    "   title=\"something\"\n".
    "   binw=\"number\"\n".
    "   sigma:\"6\"\n".
    "   mask=N\n".
    "   range=num:num\n".
    "   -h = histogram only\n";

die "$usage" if ( defined($ARGV[0])  && $ARGV[0] eq 'help');

# command line parsing
( $ARGV[0] ) and ( -s $ARGV[0] ) or unshift(@ARGV, "-");
my $infile = shift @ARGV;

my $number = '[+-]?\d+\.?\d*';
my $enumber = ${number}.'[eE][+-]?\d+';

my $date = `date`;
chomp $date;

my ($col, $dumpscript, $sigmaTrunc, $log, $epsfile) = (0,0,5,"");
my ($title) = "";
my ($binw) = 0.0;
my ($mask);
my ($lo, $hi);
my $histonly = 0;
foreach my $arg (@ARGV) {
    $col = $arg if $arg =~ /^\d+$/;         # it's a column if it's only digits

    if ($arg =~ /^log/) {
	($log) = $arg =~ /^log(\w+)$/;       # set logscale
	die "Must provide an axis for log ... eg logy (x not yet supported)\n" 
	    unless $log;
    }

    $epsfile = $arg if $arg =~ /^\w+.eps$/; # if there's an epsfile

    $dumpscript = 1 if $arg =~ /^dump$/;    # dump the data and script
    $histonly = 1 if $arg =~ /^hist$/;        # show only the histogram

    if ($arg =~ /^sigma:\d+\.?\d*/) {
	($sigmaTrunc) = $arg =~ /^sigma:(\d+\.?\d*)/;
    }

    if ($arg =~ /^title=.*/) {
	($title) = $arg =~ /^title=(.*)$/;
    }

    if ($arg =~ /^binw=.*/) {
	($binw) = $arg =~ /^binw=(.*)$/;
    }
    
    if ($arg =~ /^mask=.*/) {
      ($mask) = $arg =~ /^mask=(.*)$/;
    }

    if ($arg =~ /^range=.*/) {
      ($lo, $hi) = $arg =~ /^range=($number):($number)$/;
    }

}
$col = ($col) ? ($col-1) : 0;
$log .= "y2" if $log =~ /y/;
die "Can't support log(x)\n" if $log =~ /x/;

my $setlog = ($log) ? "set logscale $log" : "";
my $unsetlog = ($log) ? "unset logscale" : "";

# initializations
my ($nSigma, $tol, $iter) = (3.0, 0.001, 3);
my ($xlabel, $x2label, $y2label, $ylabel) = ("x", "Std.Dev.", "dN/dx", "N");
my ($htmpfile, $ktmpfile) = ("hist.tmp", "kern.tmp");
my $tmpfile = ($infile eq '-') ? "data.tmp" : $infile;
my ($yfill, $arrow0fill, $arrowt1fill, $arrowb1fill) = (0.80, 0.80, 0.90, 0.70);
my ($arrowt2fill, $arrowb2fill) = (0.85, 0.75);
my ($marrowtfill, $marrowbfill) = (1.10, 1.00);

my $filename = basename $infile;
my $colNum = $col+1;


sub log10 ($) {return log($_[0]) / log(10); }

sub gauss ($$$$) {
    my ($x, $N, $mean, $rms) = @_;

    return ( $N/($sqrtTWOPI*$rms) ) * $EXP ** (-($x-$mean)**2/(2.0*$rms**2));
}

sub residuals ($$$$$) {
    my ($kbins, $kvals, $N, $mean, $rms) = @_;
    
    my @residuals;
    foreach my $i (0 ..  @$kbins-1 ) {
	my $x = $$kbins[$i];
	my $y = $$kvals[$i];
	my $f_at_x = gauss($x, $N, $mean, $rms);
	push @residuals, ($y - $f_at_x);

    }
    return \@residuals;
}


# read in the data
my @data = ();
open (INFILE, "$infile");
while (<INFILE>) { 
    next if $_=~/^\#/;
    my ($value) = (split)[$col];
#    printf STDOUT "$value\n";
    if ( (($value =~ /^$number$/) or ($value =~ /^$enumber$/)) and 
	 ( ( $mask and ($value != $mask) ) or ( !$mask ) )  and
	 ( ( ($lo and $hi )  and ($value>=$lo and $value<=$hi) ) or (! $lo and ! $hi) ) ) {
      push @data, $value;
    }
}
close (INFILE);

# get the stats on the distributions
my $N = scalar @data;
my ($meanF, $medianF, $rmsF, $maxF, $minF, $skewF, $kurtF) = allstats(\@data);
my ($mean, $median, $rms, $max, $min, $skew, $kurt) = 
    map {sprintf "%.4f", $_} ($meanF, $medianF, $rmsF, $maxF, $minF, $skewF, $kurtF);

my ($meanClipF, $rmsClipF, $iter2) =  meanRmsClip(\@data, $nSigma, $tol, $iter);
my ($meanClip, $rmsClip) =  map {sprintf "%.4f", $_} ($meanClipF, $rmsClipF);


my ($min_rms, $max_rms) = 
    map {sprintf "%.4f", $_} (($minF-$meanClipF)/$rmsClipF, ($maxF-$meanClipF)/$rmsClipF);

my $skew_rms = sprintf "%.4f", $skewF/sqrt(15/$N);
my $kurt_rms = sprintf "%.4f", ($kurtF-3.0)/sqrt(96/$N);


my @outlierHi = grep {$_>($median+$sigmaTrunc*$rmsClip)} @data;
my @outlierLo = grep {$_<($median-$sigmaTrunc*$rmsClip)} @data;


my $NoutliersHi = scalar @outlierHi;
my $NoutliersLo = scalar @outlierLo;

my @notClipped = grep {$_>($meanClip-$nSigma*$rmsClip) && $_<($meanClip+$nSigma*$rmsClip)} @data;
my $NClip = scalar @notClipped;


# run histogram code to make the hist plots
my $binwidth = ($binw) ? $binw : $rmsClip*(20.0/$N)**(0.2);
my $resolution = $binwidth/10.0;
my $low = $median - $sigmaTrunc*$rmsClip;
my $high = $median + $sigmaTrunc*$rmsClip;

my $low2 = ($low-$mean)/$rmsF;
my $high2 = ($high-$mean)/$rmsF;
 
my ($kbins, $kvals) = 
    bin(\@data, $binwidth, "gauss");
my ($bins, $vals) = 
    bin(\@data, $binwidth, "boxcar");
#my ($kbins, $kvals) = 
#    kernelhist(\@data, $resolution, $binwidth, "gauss", "density",$low,$high);
#my ($bins, $vals) = 
#    kernelhist(\@data, $binwidth, $binwidth, "boxcar", "x",$low,$high);



# dump the histogram curves to tmp files
open (HTMP, ">$htmpfile");
foreach my $i (0.. @$bins-1) { printf HTMP "$$bins[$i] $$vals[$i]\n"; }
close (KTMP);

open (KTMP, ">$ktmpfile");
foreach my $i (0 .. @$kbins-1) { printf KTMP "$$kbins[$i] $$kvals[$i]\n"; }
close (HTMP);

# if we're reading from a pipe ... need to put the data in a file.
if ( $infile eq '-' ) {
    open (TMP, ">$tmpfile");
    foreach my $i (0 .. $#data) { printf TMP "$data[$i]\n"; }
    close (TMP);
    $colNum = 1;
}




# put together the residuals information
my ($kmin,$kmax) = range($kvals);
my ($hmin,$hmax) = range($vals);

# fit the histogram to a gaussian
# Don't do this anymore ... just use the mean,rms we have.
my $A=$hmax*$sqrtTWOPI*$rmsF;
#my $fitcommand = "mlfit $htmpfile \"f(x)=(A/($sqrtTWOPI*rms))*($EXP)**(-(x-mean)**2/(2*(rms)**2))\" $min $max 1:2 A=$A mean=$meanClipF rms=$rmsClipF";
#my @fitresult= split /\n/,`$fitcommand`;
my $gA = $binwidth*$NClip;# / ($sqrtTWOPI*$rmsF); #(split /\s+/,$fitresult[1])[2];
my $gmean = $meanClipF; #(split /\s+/,$fitresult[2])[2];
my $grms = $rmsClipF; #(split /\s+/,$fitresult[3])[2];



#  smoothed distribution
my $kresiduals = residuals($kbins,$kvals,$N,$meanClip,$rmsClip);
my ($kresidMin, $kresidMax) = range($kresiduals);

my $kresMin = abs($kresidMin);
my $kresMax = abs($kresidMax);

my $overScale = 2.0;
my $kresLimit = $overScale * (($kresMin>$kresMax) ? ($kresMin) : ($kresMax));

# normal histogram
my $hresiduals = residuals($bins,$vals,$N*$hmax/$kmax,$meanClip,$rmsClip);
my ($hresidMin, $hresidMax) = range($hresiduals);

my $hresMin = abs($hresidMin);
my $hresMax = abs($hresidMax);

my $hresLimit = $overScale * (($hresMin>$hresMax) ? ($hresMin) : ($hresMax));



# make the plot

my $scale = 1.0;
my ($term, $setoutput, $setsize) = ("x11", "", "set size $scale, $scale");

my $labelx = 1.20;
my $labely = 0.085;
my $yj = 1.5;
my $yj2 = 1.0;
$scale = 2.0 if ($epsfile);
if (defined($epsfile)) {
    $term = "postscript eps enhanced color solid \"Courier\" 24";
    $setoutput = "set output \'${epsfile}\'";
    $setsize = "set size $scale,$scale";
    $labelx = 1.2;
    $labely = 0.09;
    ($filename = $filename) =~ s/\_/\\\_/g;
}
$title = "File ($filename) using column $colNum  (${date})" unless $title;


my $y2max = ($hmax/$binwidth)/$yfill;  # how much of the screen to fill
my $ymax = $hmax/$yfill;   # same for y and y2 axes
my $ymin = $log ? 0.5 : 0;
my $y2min = $log ? 0.5*$kmax/$hmax : 0;

# get the limits for the arrows
my $arrow0 = $hmax*$arrow0fill;
my $arrowt1 = $hmax*$arrowt1fill;
my $arrowb1 = $hmax*$arrowb1fill;
my $arrowt2 = $hmax*$arrowt2fill;
my $arrowb2 = $hmax*$arrowb2fill;
my $marrowt = $hmax*$marrowtfill;
my $marrowb = $hmax*$marrowbfill;


my ($dxhis, $dyhis, $dxres, $dyres, $dxscat, $dyscat) = 
    map {$scale*$_} (0.75, 0.42, 0.75, 0.25, 0.96, 0.3);
my ($oxhis, $oyhis, $oxres, $oyres, $oxscat, $oyscat) = 
    map {$scale*$_} (0.0, 0.57, 0.0, 0.3, 0.0, 0.0);

if ($histonly) {
  $scale = 1.0;
  if (defined($epsfile)) {
    $term = "postscript eps enhanced color solid \"Courier\" 12";
  }
  ($dxhis, $dyhis, $dxres, $dyres, $dxscat, $dyscat) = 
    map {$scale*$_} (0.85, 0.96, 0.0, 0.0, 0.0, 0.0);
  ($oxhis, $oyhis, $oxres, $oyres, $oxscat, $oyscat) = 
    map {$scale*$_} (0.0, 0.02, 0.0, 0.0, 0.0, 0.0);
  $setsize = "set size 1.0,1.0";
  $labelx = 1.2;
  $labely = 0.05;
}

my $lw_lin1 = 2.0;
my $lw_lin2 = 1.0;
my $lw_arr = 1.0;

# make the plot string
my $gpt_string = "#!/usr/bin/env gnuplot\n".
  "set terminal $term\n".
  "$setoutput\n".
  "$setsize\n".
  "set title \'$title\' offset 0,-0.9\n".
  "set multiplot\n".
  "set size $dxhis,$dyhis\n".
  "set origin $oxhis,$oyhis\n".
  "set xrange [$low:$high]\n".
  "set x2range [$low2:$high2]\n".
  "set yrange [${ymin}:${ymax}]\n".
  "set y2range [${y2min}:${y2max}]\n".
  "set xlabel \'$xlabel\' offset 0,0.5\n".
  "set x2label \'$x2label\' \n".
  "set ylabel \'$ylabel\' offset 0.5,0\n".
  "set y2label \'$y2label\' offset -0.25,0\n".
  "set xtics nomirror\n".
  "set ytics nomirror\n".
  "set x2tics\n".
  "set y2tics\n".
  "set grid\n".
  "set key horizontal left Left\n".
  "\n".
  "mean=$mean\n".
  "N=$N\n".
  "NClip=$NClip\n".
  "median=$median\n".
  "rms=$rms\n".
  "rmsC=$rmsClip\n".
  "meanC=$meanClip\n".
  "skew=$skew\n".
  "skewr=$skew_rms\n".
  "kurt=$kurt\n".
  "kurtr=$kurt_rms\n".
  "min=$min\n".
  "minr=$min_rms\n".
  "max=$max\n".
  "maxr=$max_rms\n".
  "\n".
  "set style line 1 lt 1 lw $lw_lin1 lc rgb \"red\"\n".
  "set style line 2 lt 2 lw $lw_lin1 lc rgb \"green\"\n".
  "set style line 3 lt 3 lw $lw_lin1 lc rgb \"blue\"\n".
  "set style line 4 lt 3 lw $lw_lin2 lc rgb \"blue\"\n".
  "\n".
  "labx=$labelx\n".
  "laby=$labely\n".
  "labx2=labx+0.17\n".
  "\n".
  "i=1\n".
  "set label 10 \"N\" at gr labx,(1.0-i*laby) left\n".
  "set label 11 sprintf(\"= %d\",N) at gr labx2,(1.0-i*laby) left\n".
  "i=i+$yj2\n".
  "set label 12 \" 3s clip\" at gr labx,(1.0-i*laby) left\n".
  "set label 13 sprintf(\"= %d\",NClip) at gr labx2,(1.0-i*laby) left\n".
  "i=i+$yj2\n".
  "set label 14 sprintf(\"  (%.2f%%)\",100.0*NClip/N) at gr labx2,(1.0-i*laby) left\n".
  "i=i+$yj\n".
  "set label 20 \"mean\" at gr labx,(1.0-i*laby) left\n".
  "set label 21 sprintf(\"= %.4g\", mean) at gr labx2,(1.0-i*laby) left\n".
  "i=i+$yj2\n".
  "set label 50 \" 3s clip\" at gr labx,(1.0-i*laby) left\n".
  "set label 51 sprintf(\"= %.4g\", meanC) at gr labx2,(1.0-i*laby) left\n".
  "i=i+$yj\n".
  "set label 30 \"median\" at gr labx,(1.0-i*laby) left\n".
  "set label 31 sprintf(\"= %.4g\", median) at gr labx2,(1.0-i*laby) left\n".
  "i=i+$yj\n".
  "set label 40 \"rms\" at gr labx,(1.0-i*laby) left\n".
  "set label 41 sprintf(\"= %.4g\", rms) at gr labx2,(1.0-i*laby) left\n".
  "i=i+$yj2\n".
  "set label 60 \" 3s clip\" at gr labx,(1.0-i*laby) left\n".
  "set label 61 sprintf(\"= %.4g\", rmsC) at gr labx2,(1.0-i*laby) left\n".
  "i=i+$yj\n".
  "set label 70 \"skew\" at gr labx,(1.0-i*laby) left\n".
  "set label 71 sprintf(\"= %.4g\", skew) at gr labx2,(1.0-i*laby) left\n".
  "i=i+$yj2\n".
  "set label 75 \" (sig)\" at gr labx, (1.0-i*laby) left\n".
  "set label 76 sprintf(\"= %.4g\", skewr) at gr labx2, (1.0-i*laby) left\n".
  "i=i+$yj\n".
  "set label 80 \"kurt\" at gr labx,(1.0-i*laby) left\n".
  "set label 81 sprintf(\"= %.4g\", kurt) at gr labx2,(1.0-i*laby) left\n".
  "i=i+$yj2\n".
  "set label 85 \" (sig)\" at gr labx, (1.0-i*laby) left\n".
  "set label 86 sprintf(\"= %.4g\", kurtr) at gr labx2, (1.0-i*laby) left\n".
  "i=i+$yj\n".
  "set label 90 \"min\" at gr labx, (1.0-i*laby) left\n".
  "set label 91 sprintf(\"= %.4g\", min) at gr labx2, (1.0-i*laby) left\n".
  "i=i+$yj2\n".
  "set label 100 \" (sig)\" at gr labx, (1.0-i*laby) left\n".
  "set label 101 sprintf(\"= %.4g\", minr) at gr labx2, (1.0-i*laby) left\n".
  "i=i+$yj\n".
  "set label 110 \"max\" at gr labx, (1.0-i*laby) left\n".
  "set label 111 sprintf(\"= %.4g\", max) at gr labx2, (1.0-i*laby) left\n".
  "i=i+$yj2\n".
  "set label 120 \" (sig)\" at gr labx,(1.0-i*laby) left\n".
  "set label 121 sprintf(\"= %.4g\", maxr) at gr labx2,(1.0-i*laby) left\n".
  "\n".
  "\n".

  # mean vertical
  "set arrow 1 from mean,$arrowb1 to mean,$arrowt1 nohead lc \"black\" lw $lw_arr\n".
  # mean/rms horizontal
  "set arrow 2 from (mean-rms),$arrow0 to (mean+rms),$arrow0 nohead lc \"black\" lw $lw_arr\n".

  # rms verticals
  "set arrow 3 from (mean-rms),$arrowb2 to (mean-rms),$arrowt2 nohead lc \"black\" lw $lw_arr\n".
  "set arrow 4 from (mean+rms),$arrowb2 to (mean+rms),$arrowt2 nohead lc \"black\" lw $lw_arr\n".

  # rmsClip verticals
  "set arrow 5 from (mean-rmsC),$arrowb2 to (mean-rmsC),$arrowt2 nohead lc \"black\" lw $lw_arr\n".
  "set arrow 6 from (mean+rmsC),$arrowb2 to (mean+rmsC),$arrowt2 nohead lc \"black\" lw $lw_arr\n".

  # median arrow
  "set arrow 7 from median,$marrowt to median,$marrowb lc \"black\" lw $lw_arr\n".
    
  "set lmargin 9\n".
  "set rmargin 9\n".
  "$setlog\n".
  "f(x)=($gA/(sqrt(2.0*pi)*$grms))*$EXP**(-(x-$gmean)**2/(2.0*$grms**2))\n".
  "\n".
  "plot \'${htmpfile}\' using 1:2 axes x1y1 t \"\" with boxes ls 1,\\\n".
  "\'${ktmpfile}\' u 1:2 axes x1y2 t \"Smoothed\" with l ls 2,\\\n".
  "f(x) axes x1y1 t \"Gaussian\" with line ls 3\n".
  
  "$unsetlog\n";

  # residuals

if (! $histonly) {

  $gpt_string .= "unset label\n".
    "unset arrow\n".
    "set title \"Residuals from Best-Fit Gaussian\"\n".
    "set size $dxres,$dyres\n".
    "set origin $oxres, $oyres\n".
    "set yrange [-$hresLimit:$hresLimit]\n".
    "set y2range [-$kresLimit:$kresLimit]\n".
    "g(x)= f(x) / (1.0*$binwidth)\n".
    "plot \'${ktmpfile}\' u 1:(\$2 - g(\$1)) axes x1y2 t \"\" w l ls 2,\\\n".
    "\'${htmpfile}\' u 1:(\$2 - f(\$1)) axes x1y1 t \"\" w boxes ls 1,\\\n".
    "0 w line ls 3 t \"\",\\\n".
    "sqrt(f(x)) w line ls 4 t \"\", -sqrt(f(x)) w line ls 4 t \"\"\n".

    # scatter plot
    "reset\n".
    "set title \'\'\n".
    "set xlabel \'$ylabel\' offset 0,0.5\n".
    "set y2label \"$x2label\'\n".
    "set ylabel \'$xlabel\' offset 0.5,0\n".
    "set size $dxscat,$dyscat\n".
    "set origin $oxscat,$oyscat\n".
    "set grid\n".
    "set yrange [$low:$high]\n".
    "set y2range [$low2:$high2]\n".
    "set ytics nomirror\n".
    "set label 1 \"Outliers:  $NoutliersHi (High) $NoutliersLo (Low)\" at gr 0.95,1.05 right\n".
    "set y2tics\n".
    "plot \'${tmpfile}\' using $colNum axes x1y1 t \"\" w p ls 1\n".
    "";

}

# open the pipe and print to it
my $gp_line = "gnuplot -geometry 700x700 -persist";
$gp_line = "gnuplot -persist" if $histonly;
open (GNUPLOT, "|$gp_line");
print GNUPLOT "$gpt_string\n";
print STDOUT "$gpt_string\n" if ($dumpscript);;
close (GNUPLOT);


# clean up
unlink ("$htmpfile", "$ktmpfile", "fit.log") unless ($dumpscript);
