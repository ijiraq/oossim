#!/usr/bin/env perl
#
#
#  makes a template script/program
#       perl
#       latex
#       python
#       bash/sh
#       csh
#       c
#       f77
#       html
#       gnuplot
#

use strict;
use warnings;

use Sys::Hostname;

my ($name, @args) = @ARGV;

(my $this_script = $0) =~ s{.*\/}{};
die "Usage: $this_script name [args] [header]\n"
    ." args:  .gp (gnuplot):  nx ny separate(0|1) files ...\n"
    ." header: use this to print only the commented file header (to STDOUT)\n" 
    ."\n" if (! $name);


my $header_only = (@args && $args[-1]=~/^[Hh]eader$/) ? 1 : 0;
pop @args if $header_only;

######################################################################
###         get some info for the comments in the file header  #####
#######################################################################

# date/time
my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
my @mon = qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
my @wday = qw/Sun Mon Tue Wed Thu Fri Sat/;
my $time_string = sprintf "%3s %3s %2d, %4d  %d:%02d:%02d %1sST",
    $wday[$wday], $mon[$mon], $mday, $year+1900, 
    $hour, $min, $sec, ($isdst)?("D"):("E") ;

# host
my $host = hostname;

# working directory
my $cwd = ( $ENV{PWD} ) ? "$ENV{PWD}" : `pwd`;
$cwd = "unknown" if ( ! $cwd );

my $stamp_date = "Created: $time_string";
my $stamp_host = "Host: $host";
my $stamp_cwd  = "Working Directory: $cwd";
my $stamp_auth = "Steven Bickerton";
my $stamp_inst = "Dept. of Astrophysical Sciences, Princeton University";
my $stamp_email= 'bick@astro.princeton.edu';

##################   Done header info  #############################







####################################################################
#
#                Init  etc
#
####################################################################

# get file type assuming suffix
(my $insuffix = $name) =~ s/.*\.(\w+)$/$1/ ;
my $executible = ( $name =~ /.*\.(pl|py|bash|sh|csh|tcsh|gp)/ ) ? (1) : (0);
my $filetype;

# make sure we can make one of these files
my %suffixes = ( pl => 1, py => 1, bash => 1, sh => 1, 
		csh => 1, tcsh => 1, c => 1, f => 1,  htm => 1, 
		html => 1, gp => 1, tex => 1  );
die "Don't know how to make a .$insuffix file ?\n" 
    if ( ! $suffixes{$insuffix} );
    
########################  Done init stuff  ########################








####################################################################
#
#                  PERL
#
#####################################################################




my $perl = <<'PERL';
#!/usr/bin/env perl
#
=head1 NAME 

FILENAME - perl script template

=head1 SYNOPSIS

FILENAME [options] in out

    Options: (v)erbose, (d)ebug, (h)elp, (r)equired=, (o)ptional:
    Arguments: in  =  input file name
               out =  output file name

=head1 AUTHOR

STAMP_AUTH
 STAMP_INST
 STAMP_EMAIL
 STAMP_DATE
 STAMP_HOST
 STAMP_CWD
 HEADER_END

=cut

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
# use Math::Random qw(random_normal);
# use File::Basename;

# use PDL;
# use PDL::Image2D;
# use PDL::Reduce;
# use PDL::Primative;

# use lib "$ENV{HOME}/libperl";
# use Local::Constants;


# s,i,f (string,int,float)  =required  :optional
# shown: verb,debug are boolean, $required is required, $optional is optional
my ($verb, $debug, $help, $man) = ('', '', '', '');
my ($reqd, $optl) = ('', '');
GetOptions("verbose" => \$verb, "debug" => \$debug, 
	   "help" => \$help, "man" => \$man,
	   "required|needed=s" => \$reqd, "optional:i" => \$optl );

my ($in,$out) = @ARGV;

$help and pod2usage(1);
$man  and pod2usage(-verbose => 2);
$out  or  pod2usage(1);



# open (IN, "$in");
# while (<IN>) {
# my ($a,$b) = split;
printf STDOUT "Options: verbose=$verb\n"
    ."         debug=$debug\n"
    ."         required=$reqd\n"
    ."         optional=$optl\n"
    ."arguments: in=$in out=$out\n";
# }
# close (IN);

exit 0;

__END__

=head1 DESCRIPTION

=head1 BUGS

None known

=head1 SEE ALSO

=head1 COPYRIGHT

GNU Public Licence.  This code comes with no warranty whatsoever.
If it breaks, you get to keep both pieces!
=cut 

PERL



my $perl_simple = << 'PERL_SIMPLE';
#!/usr/bin/env perl
#
# original filename: FILENAME
#
# STAMP_AUTH
#  STAMP_INST
#  STAMP_EMAIL
#  STAMP_DATE
#  STAMP_HOST
#  STAMP_CWD
#
#  HEADER_END

use strict;
use warnings;
use File::Basename;

use Local::Constants;
use Local::Astrotools;

my $exe = basename($0);
my $usage = "Usage: $exe x\n";

my ($x) = @ARGV;
die $usage unless $x;

printf STDOUT "$x $PI\n";

exit 0;

PERL_SIMPLE
    
$perl = $perl_simple if ($insuffix eq 'pl' && $args[0] eq 'simple');




######################     END PERL      ##########################





####################################################################
#
#                  LATEX
#
#####################################################################

my $latex = <<'LATEX';
%% STAMP_AUTH
%% STAMP_INST
%% STAMP_EMAIL
%% STAMP_DATE
%% STAMP_HOST
%% STAMP_CWD
%% HEADER_END
\documentclass[letterpaper, 12pt]{article}
% \documentclass[twocolumn, 10pt]{article}
   
\usepackage[dvips]{graphicx}
\usepackage{epsfig}
\usepackage{float}
% \usepackage{rotating}
% \usepackage{array}
% \usepackage{amsmath}
% \usepackage{amssymb}
% \usepackage{verbatim}
% \usepackage{natbib}

\setlength{\oddsidemargin}{+0.in}
\setlength{\textheight}{9.9in}
\setlength{\textwidth}{6.5in}
\setlength{\topmargin}{-0.25in}


\pagestyle{empty}

\begin{document}

{\bfseries\large Hello}  {\itshape World} \\
    
    
% \begin{figure}
% \centering\epsfig{figure=file.eps, angle=0, height=10cm}
% \caption{}
% \end{figure}

% \begin{table}
% \begin{tabular}{llccrr}
% &&&&&\\
% \end{tabular}
% \caption[]{}
% \end{table}


\end{document}

LATEX
######################     END LATEX      ##########################







####################################################################
#
#                  PYTHON
#
#####################################################################

my $python = <<'PYTHON';
#!/usr/bin/env python
#
# STAMP_AUTH
# STAMP_INST
# STAMP_EMAIL
# STAMP_DATE
# STAMP_HOST
# STAMP_CWD
# HEADER_END

import sys, os, math
import numpy as num
import scipy as sci
    
def usage():
    print """Usage: %s parameters""" % sys.argv[0]
    sys.exit(1)
    
def main():
    if len(sys.argv) != 1:
        usage()
    
    print "hello world"
    
if __name__ == '__main__':
    main()
    
PYTHON
######################     END PYTHON      ##########################








####################################################################
#
#                  BASH/SH
#
#####################################################################

my $bash = <<'BASH';
#!/usr/bin/env bash
#
# STAMP_AUTH
# STAMP_INST
# STAMP_EMAIL
# STAMP_DATE
# STAMP_HOST
# STAMP_CWD
# HEADER_END

function usage()
{
    echo "Usage: $0 [options] arg"
    echo "  Options: -v    verbose"
    echo "  Options: -h    help"
}

if [ $# -eq 0 ]; then
    usage
fi

#  Warning: getopts doens't shift off the options from $@ ...
while getopts "vh" OPTIONS
  do
    case $OPTIONS in

      v)
         echo "verbose"
         ;;
      h)
         echo "help"
         ;;
      *)
         usage
         ;;

    esac
done


for f in $@; do
    echo $f
done

exit 0
 
BASH


my $bash_simple = <<'BASH_SIMPLE';
#!/usr/bin/env bash
#
# STAMP_AUTH
# STAMP_INST
# STAMP_EMAIL
# STAMP_DATE
# STAMP_HOST
# STAMP_CWD
# HEADER_END

function usage()
{
    echo "Usage: $0"
}

if [ $# -ne 0 ]; then
    usage
    exit 1;
fi


exit 0
 
BASH_SIMPLE


$bash = $bash_simple 
    if ( ($insuffix eq 'sh' or $insuffix eq 'bash')  && @args && $args[0] eq 'simple');




######################     END BASH      ##########################






####################################################################
#
#                  CSH/TCSH
#
#####################################################################

my $csh =<<'CSH';
#!/usr/bin/env tcsh
#
# STAMP_AUTH
# STAMP_INST
# STAMP_EMAIL
# STAMP_DATE
# STAMP_HOST
# STAMP_CWD
# HEADER_END

if ( $#argv == 0 ) then
    echo "Usage: $0 arg"
endif
    
foreach f ($argv)
    echo $f
end

exit 0
 
CSH
######################     END CSH      ##########################






####################################################################
#
#                 C
#
#####################################################################

my $gcc =<<'GCC';
/*            */
/* STAMP_AUTH */
/* STAMP_INST */
/* STAMP_EMAIL*/
/* STAMP_DATE */
/* STAMP_HOST */
/* STAMP_CWD  */
/* HEADER_END */

#include <stdlib.h>
#include <stdio.h>
#include <getopt.h>
#include <errno.h>
#include <assert.h>
#include <time.h>
#include <string.h>
/* #include <math.h>  */
/* #include <fitsio.h> */
/* #include <fftw3.h> */
/* #include <gsl/gsl_errno.h> */
/* #include <gsl/gsl_rng.h> */
/* #include <gsl/gsl_randist.h> */

/* #define PI 3.141592654  */



void usage(char execName[]) {
    printf ("Usage: %s arg1 arg2\n", execName);
    exit(1);
}

int main(int argc, char *argv[])
{
    int i;
    char *arg1, *arg2;
    char c;
    int verbose = 0;

    while( (c=getopt(argc,argv,"v")) != -1 ) {
      switch(c) {
      case 'v':
        verbose = 1;
        break;
      default:
        break;
      }
    }

    if ( argc-optind != 2 ) {
	usage(argv[0]);
    } else {
	arg1 = argv[optind];
	arg2 = argv[optind+1];
    }

    if (verbose) printf ("verbose\n");
    for (i=0; i<10; i++) {
        printf ("hello world %s %s %d\n", arg1, arg2, i);
    }

    return 0;

}

GCC
######################     END C      ##########################






####################################################################
#
#                 FORTRAN 77
#
#####################################################################

my $f77 = <<'FORTRAN';
c     PROGRAM $name
c     STAMP_AUTH
c     STAMP_INST
c     STAMP_EMAIL
c     STAMP_DATE
c     STAMP_HOST
c     STAMP_CWD
c     HEADER_END
c
c
      INTEGER NUM, NUMSQR
c
      WRITE (6,*) 'NUMBER = Number-Squared'
      DO 231 NUM=1,10
        NUMSQR = NUM*NUM
        WRITE (6,*) NUM, NUMSQR
231   CONTINUE
      STOP
      END

FORTRAN
######################     END FORTRAN 77      ##########################






####################################################################
#
#                  HTML
#
#####################################################################

my $html = <<'HTML';
<!-- STAMP_DATE -->
<!-- STAMP_HOST -->
<!-- STAMP_CWD -->
<!-- HEADER_END -->
<html>
<head>
<Title> Stuff
</title>
</head>

<body text="black" background="white">
<basefont size=2 face="times">
    
<div align="center">
<font size="+3"><b>Stuff</b></font>
</div>


<table align="center" border=0 width="90%">

<tr align="left">
<th> <font size="-1"> Line of text </font>
<th> <font size="-1"> <A href="./file"> ./file </A></font>

<tr align="left">
<th> <font size="-1"> Line of text </font>
<th> <font size="-1"> <A href="./file"> ./file </A></font>

</table>

</body>
</html>

HTML
######################     END HTML      ##########################





####################################################################
#
#                  GNUPLOT
#
#####################################################################

my ($nx,$ny,$separate, @files) = (2,2,1,());     #default values
($nx,$ny,$separate,@files) = @args if ($insuffix eq 'gp' && @args);
@files = ("data") if ! @files;


###############      GNUPLOT SIMPLE      ###########################
(my $eps_name = $name) =~ s/gp/eps/;

my $gnuplot = << "GNUPLOT";
#!/usr/bin/env gnuplot
#
# STAMP_AUTH
# STAMP_INST
# STAMP_EMAIL
# STAMP_DATE
# STAMP_HOST
# STAMP_CWD
# HEADER_END

set terminal postscript eps enhanced color \"Helvetica\" 24
set output \'$eps_name\'

set title \'title\'
set xlabel \'x\'
set ylabel \'y\'

set border lw 2
set grid lw 2
set xrange [:]
set yrange [:]

set style line 1 lt 1 lw 3 lc rgb \"black\"
set style line 2 lt 2 lw 3 lc rgb \"black\"

plot \'data\' using 1:2 t \"\" with l ls 1

GNUPLOT

##################    DONE GNUPLOT SIMPLE  ###########################



##################    GNUPLOT MULTI   ####################################
    
my $mmx = ($separate) ? ("0.15*PX") : (0);
my $mmy = ($separate) ? ("0.15*PY") : (0);
my $ppx = ($separate) ? ("0.70*PX") : ("PX");
my $ppy = ($separate) ? ("0.70*PY") : ("PY");


my $gnuplot_multi =<< "GNUPLOT_MULTI";
#!/usr/bin/env gnuplot
#
# STAMP_AUTH
# STAMP_INST
# STAMP_EMAIL
# STAMP_DATE
# STAMP_HOST
# STAMP_CWD
# HEADER_END

set terminal postscript eps enhanced color \"Helvetica\" 24
set output \'$eps_name\'

XMAX = 2
YMAX = 2

MX = 0.10*XMAX   # margin X,Y
MY = 0.10*YMAX
PX = 0.80*XMAX/$nx   # plot width
PY = 0.80*YMAX/$ny 

MMX = $mmx
MMY = $mmy
PPX = $ppx
PPY = $ppy

set size XMAX,YMAX

set tmargin MY
set bmargin MY
set rmargin MX
set lmargin MX

#set arrow 100 from 1,1 to 2,2 nohead lt 1
#set arrow 100 from 1,1 to 2,2 lt 1

set format x \"% g\"
set format y \"% g\"

set grid
set xrange [:]
set yrange [:]

set multiplot

set tmargin MMY
set bmargin MMY
set rmargin MMX
set lmargin MMX

GNUPLOT_MULTI


my ($dx, $dy) = ( 2.0/$nx, 2.0/$ny );

my ($count,$n) = (1, $nx*$ny);
foreach my $i (0 .. $nx-1) {
    foreach my $j (0 .. $ny-1) {

	my $k = $i*$ny + $j;
	my $file = $files[$k] if ($k <= $#files);
	$file = $files[0] if ($k > $#files);
	my $filename  =  `basename $file`;
	chomp $filename;

	my $settitle = ( $separate  ||  $j==$ny-1) ? 
	    "set title 'title'\n" : 
	    "unset title";

	my ($setxlabel,$setxtic);
	if ( $separate ||  !$j ) {
	    $setxlabel = "set xlabel 'x'";
	    $setxtic = "set format x \"% g\"";
	} else {
	    $setxlabel = "unset xlabel";
	    $setxtic = "set format x \"\"";
	}

	my ($setylabel,$setytic);
	if ( $separate ||  !$i ) {
	    $setylabel = "set ylabel 'y'";
	    $setytic = "set format y \"% g\"";
	} else {
	    $setylabel = "unset ylabel";
	    $setytic = "set format y \"\"";
	}

	$gnuplot_multi .= "\n"
	    ."#############################################################\n"
	    ."#  segment $count of $n   ($i,$j)\n"
	    ."#\n"
	    ."#          ";
	
	foreach my $jj (reverse (0 .. $ny-1)) {
	    foreach my $ii (0 .. $nx-1) {
		$gnuplot_multi .= ($ii==$i && $jj==$j) ? "X " : "O ";
	    }
	    $gnuplot_multi .= "\n#          ";
	}


	$gnuplot_multi .= "\n\n"
	    ."$settitle\n"
	    ."$setxlabel\n"
	    ."$setylabel\n"
	    ."$setxtic\n"
	    ."$setytic\n"
	    ."\n"
	    ."set origin MX+MMX+$i*PX, MY+MMY+$j*PY\n"
	    ."set size PPX,PPY\n"
	    ."\n"
	    #."plot \'$file\' using 1:2 t \"$filename\"\n"
	    ."plot \'$file\' using 1:2 t \"\"\n"
	    ."\n";

	$count++;
    }
}
###############    DONE   GNUPLOT MULTI  ##############################

######################     END GNUPLOT      ##########################




my $s;
if ($name =~ /.*\.pl$/)      { $filetype = "Perl script"; $s = $perl; }
if ($name =~ /.*\.tex$/)     { $filetype = "latex"; $s = $latex; }
if ($name =~ /.*\.py$/)      { $filetype = "Python script"; $s = $python; }
if ($name =~ /.*\.(ba)?sh$/) { $filetype = "Bash shell script"; $s = $bash;  }
if ($name =~ /.*\.t?csh$/)   { $filetype = "(T)CSH shell script"; $s = $csh; }
if ($name =~ /.*\.c$/)       { $filetype = "C program"; $s = $gcc; }
if ($name =~ /.*\.f$/)       { $filetype = "Fortran 77 program"; $s = $f77;}
if ($name =~ /.*\.html?$/)   { $filetype = "HTML code"; $s = $html; }

if ($name =~ /.*\.gp$/)  { 
    $filetype = "Gnuplot script"; 
    $s = $gnuplot;
    $s = $gnuplot_multi if @args; 
}





#####################################################################
#
#                    OUTPUT TO FILE
#
#####################################################################

### Now, write the script, but check and make sure not to overwrite anything #

my $ok = 1;   # assume it's $ok to overwrite
if ( ! $header_only && -e $name ) {
    print "File $name already exists ... overwrite? [y/N]: ";
    my $reply = getc STDIN;

    if ( $reply !~ /[yY]/ ) {
	$ok = 0;
	print "File not written.  Exiting\n";
    }

}


if ( $ok || $header_only ) {

    my $header = "";
    my $header_end = 0;
    # evaluate each line
    my @s = split /\n/, $s; 
    foreach (@s) {  

	s/%/%%/g;      # change % to %% so printf will get it right
	s/STAMP_DATE/$stamp_date/;
	s/STAMP_HOST/$stamp_host/;
	s/STAMP_CWD/$stamp_cwd/;
	s/STAMP_AUTH/$stamp_auth/;
	s/STAMP_INST/$stamp_inst/;
	s/STAMP_EMAIL/$stamp_email/;
	s/FILENAME/$name/;


	# lose the header only flag once we've reached the end of the header
	if ($_ =~ /HEADER_END/) {
	    s/.*//;
	    $header_end = 1;
	}

	$header .= "$_\n" if ($header_only == 1 && ! $header_end);

    }
    # put lines back together into one string
    $s = join("\n", @s);  

    # output to file
    if ($header_only) {
	printf STDOUT "$header\n";
    } else {
	open (FILE, ">$name");
	printf FILE "$s\n";
	close (FILE);
	chmod (0744, "$name") if ($executible);
	
	printf STDOUT "$filetype file $name written\n";
    }

}	

#########################   DONE  OUTPUT   ######################



exit 0;
