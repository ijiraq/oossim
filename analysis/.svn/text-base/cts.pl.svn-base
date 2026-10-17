#!/usr/bin/env perl
#
#

use strict;
use warnings;


my $usage = "Usage: $0 infile show halfwidth centre-point [halfwidth2]\n";

my ($infile, $show, $halfwid, $cen, $halfwid2) = @ARGV;
die $usage unless $halfwid;
$halfwid2 = 4.0*$halfwid unless $halfwid2;

my $plotfile = "${infile}_${cen}_${halfwid}.eps";

my ($min, $max) = ($cen-$halfwid, $cen+$halfwid);
my ($min2, $max2) = ($cen-$halfwid2, $cen+$halfwid2);


# read in the data and dump to tmpfile
my $out_tmp1 = "$infile.tmp1";
my $out_tmp2 = "$infile.tmp2";
open(OUT1, ">$out_tmp1");
open(OUT2, ">$out_tmp2");
open(IN, "$infile");
while (<IN>) {
    my $sec = (split)[2];
    printf OUT1 "$_" if ($sec>$min && $sec<$max);
    printf OUT2 "$_" if ($sec>$min2 && $sec<$max2);
}
close(IN);
close(OUT2);
close(OUT1);

my $script = "#!/usr/bin/env gnuplot\n".
    "set terminal postscript eps enhanced color solid\n".
    "set output \'${plotfile}\'\n".
    "set title \'$out_tmp1\'\n".
    "set xlabel \'time (sec)\'\n".
    "set grid\n".
    "set size 1,2.5\n".
    "set multiplot\n".
    "\n".
    "\n".
    "\n".


    # plot 0 (top) ... coords
    "set origin 0, 2.0\n".
    "set size 0.5,0.5\n".
    "plot [0:30] [0:24] \'$out_tmp1\' using 10:11 t \"\" w p, \'$out_tmp1\' using 12:13 t \"\" w p\n".
    "\n".
    "\n".


    # plot 00 (top) ... coords
    "set origin 0.5, 2.0\n".
    "set size 0.5,0.5\n".
    "plot [0:30] [0:24] \'$out_tmp2\' using 10:11 t \"\" w p, \'$out_tmp1\' using 12:13 t \"\" w p\n".
    "\n".
    "\n".

    # plot 1 ()  ... raw 1
    "set origin 0,1.5\n".
    "set size 1,0.5\n".
    "set xrange [$min:$max]\n".
    "set yrange [:]\n".
    "plot \'$out_tmp1\' using 3:( (\$4>10)?(\$4):(1/0)) t \"Raw 1\" w lp\n".
    "\n".
    "\n".
    "\n".

    # plot 2 ()  ... raw 2
    "set origin 0,1.0\n".
    "set size 1,0.5\n".
    "set xrange [$min:$max]\n".
    "set yrange [:]\n".
    "plot \'$out_tmp1\' using 3:( (\$5>10)?(\$5):(1/0)) t \"Raw 2\" w lp\n".
    "\n".
    "\n".
    "\n".

    # plot 3 ()  ... ratio 
    "set origin 0,0.5\n".
    "set size 1,0.5\n".
    "set xrange [$min:$max]\n".
    "set yrange [0.8:1.2]\n".
    "plot \'$out_tmp1\' using 3:6 t \"Ratio\" w lp\n".
    "\n".
    "\n".
    "\n".

    # plot 4 ()  ... ratio wide 
    "set origin 0,0.0\n".
    "set size 1,0.5\n".
    "set xrange [$min2:$max2]\n".
    "set yrange [0.8:1.2]\n".
    "plot \'$out_tmp2\' using 3:6 t \"Ratio Wide\" w lp\n".
    "\n".
    "\n";


open (GNUPLOT, "|gnuplot");
#printf STDOUT "$script";
printf GNUPLOT "$script";
close (GNUPLOT);

unlink ($out_tmp1, $out_tmp2);

system ("display $plotfile &") if $show;

exit 0;
