#!/usr/bin/env perl
#
# original filename: viewPoly.pl
# changed to: viewFit.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Tue Feb 28, 2006  15:55:10 EST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/analysis
#

use strict;
use warnings;
use File::Basename;
use Math::Trig;

use lib "$ENV{HOME}/libperl";
use Local::Constants;
use Local::Statistics;

my $exe = basename($0);
my $usage = "Usage: $exe [infile] expr [x1] [x2] [columns] [param1 ... paramN] [plot.eps]\n".
    "   expr = (line|polyN|gauss|exp|ten|cosh|sinh)\n".
    "   eg. cat file.dat | viewFit poly3\n".
    "   eg. viewFit file.dat poly6 2 5 1:2:3 test.eps\n".
    "\n";



# initializations
( $ARGV[0] ) and ( -s $ARGV[0] ) or unshift(@ARGV, "-");
my ($infile, $expr) = @ARGV;
die $usage unless $expr;


# extract the different command line args ... a pain in the ass with so
#  many of them optional.
my ($x1, $x2, $cols, $epsfile);
my @ARGV_TMP = @ARGV[5 .. -1];
my @params;
my $number = '[+-]?\d+\.?\d*';

foreach my $arg (@ARGV[2 .. $#ARGV]) { 

    if ($arg =~ /\w+\.eps$/) {
	$epsfile = $arg;
       
	# set the x1/x2 values
    } elsif ($arg =~ /$number/ and $arg !~ /:/ and ! defined($x1) ) {
	$x1 = $arg;
    } elsif ($arg =~ /$number/ and $arg !~ /:/ and defined($x1) ) {
	$x2 = $arg;

	# skip the columns
    } elsif ($arg =~ /:/) {
	$cols = $arg;

	# only thing left must be a param
    } else {
	push @params, $arg;
    }
}

$cols = "1:2" unless $cols;
$x1 = "" unless $x1;
$x2 = "" unless $x2;
my ($xColo, $yColo, $dyColo) = split /:/, $cols;
my $xCol = $xColo - 1;
my $yCol = $yColo - 1;
my $dyCol = $dyColo - 1 if ($dyColo);



my $expr_label = "";

# polynomials

if ($expr =~ /^line/) {
    $expr = "f(x)=m*x + b";
    $expr_label = "f(x) = m*x + b";
    @params = ("m", "b") unless (scalar @params);
}

if ($expr =~ /^poly/) {

    my ($order) = $expr =~ /^poly(\d+)/;

    my $have_params = scalar @params;
    $expr = "f(x)=a0";
    @params = "a0" unless $have_params;
    for (my $term=1; $term<=$order; $term++) {
	$expr .= " + a${term}*x**${term}";
	push @params, "a${term}" unless $have_params;
    }
    $expr_label = "f(x)=sum(xN*x^(N))";
}


# other functions

if ($expr =~ /gauss/) {
    $expr = "f(x)=A*(2.71828)**(-(x-mean)**2/(2*rms**2))";
    @params = ("A", "mean", "rms") unless (scalar @params);
    $expr_label = "f(x) = A*e^(-(x-mean)^2/(2*rms^2))";
}

if ($expr =~ /exp/) {
    $expr = "f(x)=A*($EXP)**(q*x)";
    $expr_label = "f(x)=A*e**(q*x)";
    @params = ("A", "q") unless (scalar @params);
}

if ($expr =~ /ten/) {
    $expr = "f(x)=A*(10)**(q*x)";
    $expr_label = "f(x)=A*(10)^(q*x)";
    @params = ("A", "q") unless (scalar @params);
}

if ($expr =~ /cosh/) {
    $expr = "f(x)=Amp*cosh(k*x)";
    $expr_label = $expr;
    @params = ("Amp", "k") unless (scalar @params);
}

if ($expr =~ /sinh/) {
    $expr = "f(x)=Amp*sinh(k*x)";
    $expr_label = $expr;
    @params = ("Amp", "k") unless (scalar @params);
}

die "$usage" if ! scalar @params;




# read in the data
my $tmpfile = "$ENV{HOME}/tmp/viewPoly.tmp";
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





# make the gnuplot script

my $filename = $infile;
my $fitlog = "$ENV{HOME}/tmp/viewPoly.fit";
my ($xlabel, $ylabel, $yresidlabel) = ("x", "f(x)", "y - f(x)");

my ($terminal, $setoutput, $setsize) = ("x11 font \"Courier,14\"", "", "set size 1,1");
my ($lw1, $lw2, $ps, $size) = (2, 1, 1, 1);
if (defined($epsfile)) {
    $terminal = "postscript eps enhanced color solid \"Courier\" 32";
    $setoutput = "set output \'${epsfile}\'";
    $size = 2;
    ($lw1, $lw2, $ps) = (5, 2, 3);
    ($filename = $infile) =~ s/\_/\\\_/g;

}

my ($xmax) = max(\@x);
my ($xmin) = min(\@x);
my ($ymax) = max(\@y);
my ($ymin) = min(\@y);

$x1 = defined($x1)?($x1):$xmin;
$x2 = defined($x2)?($x2):$xmax;

my $yResid = ($ymax-$ymin) / 4.0;

my ($low, $high) = ($xmin, $xmax);
my ($ylow, $yhigh) = ($ymin - 0.1*abs($ymin), $ymax+0.1*abs($ymax));
my $yrange = $yhigh - $ylow;

my $labelx = $low + ($high-$low)*1.08;
my $labely = 0.07;
my $xWidth = 0.7;

my $columns = ($dyCol) ? "1:2:3" : "1:2";
my $point = ($dyCol) ? "errorbar" : "point";



# make the plot string
my $gp_script = "#!/usr/bin/env gnuplot\n";
my $paramlist = "";
foreach my $param (@params) {
    my ($var,$value) = split /=/, $param;
    $gp_script .= "$param\n" if defined($value);
    $paramlist .= sprintf "%s,", $var;
}
$paramlist =~ s/(.*),$/$1/;

$gp_script = "set terminal $terminal\n".
    "$setoutput\n".
    "set size $size\n".
    "set lmargin 8\n".

    # do the fit
    "$expr\n".
    "set fit errorvariables\n".
    "set fit logfile \'$fitlog\'\n".
    "fit [$x1:$x2] f(x) \'$tmpfile\' using $columns via $paramlist\n".

    # make the plot
    "set multiplot\n".

    "set xrange [$low:$high]\n".
    "set yrange [${ylow}:${yhigh}]\n".
    "set title \'$filename\'\n".
    "set xlabel \'$xlabel\'\n".
    "set ylabel \'$ylabel\'\n".
    "set grid\n".
    "set arrow 1 from $x1,$ylow to $x1,$yhigh nohead lw 2 lc 2\n".
    "set arrow 2 from $x2,$ylow to $x2,$yhigh nohead lw 2 lc 2\n".

    "unset key\n".
    "i=3.3\n".
    "set label 1 \"$expr_label\" at $labelx, $yhigh-i*$yrange*$labely left\n".
    "i=i+2\n".
    "set label 2 \"N:   $N\" at $labelx, $yhigh-i*$yrange*$labely left\n";

    
my $l = 4;
foreach my $param (@params) {
    $gp_script .= "i=i+1\n".
	"${param}_str = sprintf(\"$param = %%.3f +/- %%.3f\", $param, ${param}_err)\n".
	"set label $l ${param}_str at $labelx, $yhigh-i*$yrange*$labely left\n".
	"\n";
    $l++;
}

$gp_script .=  "\n".
    #"a=$aa\n".
    #"b=$bb\n".
    "set origin 0,0.3*$size\n".
    "set size $xWidth*$size,0.7*$size\n".
    "plot \'${tmpfile}\' using $columns t \'data\' with $point ps $ps,\\\n".
    "f(x) t \"$expr\"  w l lt 3 lw $lw1\n".


    # plot the residuals
    "set title \"\"\n".
    "unset key\n".
    "unset label\n".
    "set arrow 1 from $x1,-$yResid to $x1,$yResid nohead lw 2 lc 2\n".
    "set arrow 2 from $x2,-$yResid to $x2,$yResid nohead lw 2 lc 2\n".
    "set ylabel \'$yresidlabel\'\n".
    "set yrange [-$yResid:$yResid]\n".
    #"set yrange [${min_resid}-${rms_resid}:${max_resid}+${rms_resid}]\n".
    "set origin 0,0\n".
    "set size $xWidth*$size,0.3*$size\n".
    "plot 0 with line lt 3 lw $lw1, \'${tmpfile}\' using 1:(\$2 - f(\$1)) t \"\" with point pt 1 ps $ps lt 1\n".
    "";

#open (TMP, ">gp.tmp");
#printf TMP "$gp_script\n";
#close(TMP);

# open the pipe and print to it
open (GNUPLOT, "|gnuplot -persist 2> /dev/null");
#open (GNUPLOT, "|gnuplot -persist");
printf GNUPLOT "$gp_script\n";
close (GNUPLOT);

unlink ("$fitlog");

exit 0;
