#!/usr/bin/perl -w
#
# Program density.pl
# 
# Used to create a surface density plot in .pgm image format using an input 
# data file.  Densities are calculated for each point by using either a 
# boxcar comvolution kernel, or a gaussian convolution kernel.
#
# boxcar: xbinsize,ybinsize are the major axes of an ellipse. Any point
#         within the ellipse contributes equally to the density of the 
#         central point.
# gauss:  xbinsize,ybinsize are the xsigma,ysigma standard deviations for 
#         a bivariate ellipsoidal gaussian.  Any point within the 3*sigma 
#         distance contributes a value weighted by the gaussian to the
#         density of the central point.
#
# Input data file must be of the form:
#
# x1 y1
# x2 y2
# .. ..
# xn yn
#

# There are a total or 12 input arguments

# i/o files
$infile = $ARGV[0];
$outfile = $ARGV[1];

# resolution (basically pixel size), and binsizes
$xresolution = $ARGV[2];
$xbinsize = $ARGV[3];
$yresolution = $ARGV[4];
$ybinsize = $ARGV[5];

# kernel type (boxcar or gaussian)
$kernel = $ARGV[6];

# Maximum and minimum data values (ie boundaries of the plot)
$xlow = $ARGV[7];
$xhigh = $ARGV[8];
$ylow = $ARGV[9];
$yhigh = $ARGV[10];

# Invert the contrast of the image 
# (0=high density is bright, 1=high density is dark)
$invert = $ARGV[11];

#
# Error messages
#
die "Usage: density infile outfile xres xbin yres ybin kernel xlow xhigh ylow yhigh invert(1=high density dark)\n" if ( ( ! $infile ) || ( ! $invert ) );
die "$infile does not exist\n" if ( ! -e $infile );
die "kernel must be boxcar or gauss\n" if ( $kernel ne "boxcar" && $kernel ne "gauss" );
die "resolution must be <= binsize\n" if ( $xresolution > $xbinsize || $yresolution > $ybinsize);

#
# Open data files
#

open (INFILE, "$infile" );
open (OUTFILE, "> $outfile" );

#
# Calculate the dimensions of the required array and initiallize the array
#

$nx = int(($xhigh-$xlow)/$xresolution);
$ny = int(($yhigh-$ylow)/$yresolution);
$counter = 0;

for ($i=0; $i <= $nx; $i++) {
    for ($j=0; $j <= $ny; $j++) {
	$histogram[$i][$j] = 0;
    }
} 

######################################################################
#                     Main part of program
#
# Read through the input data file and determine which bins the
# data point will fall in.  In the case of the gaussian, the amount of
# the contribution to each relevant bin is first determined.
#
######################################################################

$xhighestbin = ($xhigh-$xlow)/$xresolution;
$yhighestbin = ($yhigh-$ylow)/$yresolution;

while (<INFILE>) {

    next if /^\#/;
    
    # Read in the values
    ($x,$y) = split(/\s+/);
    
    # Count the number of data points as they are processed
    $counter++;
 
#######################################################################
#                   Calculations for the boxcar format
#######################################################################

    if ( $kernel eq "boxcar" ) {

	# If the data point is within the upper in lower bounds given,
	# determine which range of bins to put it in. 
	# ...both the value of the bin, and its array number.

	if ($x >= $xlow && $x <= $xhigh && $y >= $ylow && $y <= $yhigh) {
	    $xbinlow = $x - 0.5*$xbinsize;
	    $xbinhigh = $x + 0.5*$xbinsize;
	    $nxbinlow = int(($xbinlow - $xlow)/$xresolution) + 1;
	    $nxbinhigh = int(($xbinhigh - $xlow)/$xresolution);

	    $ybinlow = $y - 0.5*$ybinsize;
	    $ybinhigh = $y + 0.5*$ybinsize;
	    $nybinlow = int(($ybinlow - $ylow)/$yresolution) + 1;
	    $nybinhigh = int(($ybinhigh - $ylow)/$yresolution);


	    # Step through the bins, and add 1 to each bin.
	    for ($i=$nxbinlow; $i <= $nxbinhigh; $i++) {
		for ($j=$nybinlow; $j <= $nybinhigh; $j++) {
		    $dx = $x-($xlow + $i*$xresolution);
		    $dy = $y-($ylow + $j*$yresolution);

		    # Use only points within a 'radial' distance of the bin
		    # and do sanity check to ensure the bin is not outside
		    # the specified limits (could occur for points near the 
		    # edges of the region.

		    if ( ( (($dx/($xbinsize/2))**2 + ($dy/($ybinsize/2))**2) < 1) && ($i >= 0) && ($j >= 0) && ($i <= $xhighestbin) && ($j <= $yhighestbin)) {
			$histogram[$i][$j]++; 
		    }
		}
	    }

	}

    }

#######################################################################
#                   Calculations for the gaussian format
#######################################################################

    if ( $kernel eq "gauss" ) {

	$exp = 2.718281728;
	my $s_max = 5;

	# If the data point is within the upper in lower bounds given,
	# determine which range of bins to put it in. 
	# ...both the value of the bin, and its array number.

	if ($x >= $xlow && $x <= $xhigh && $y >= $ylow && $y <= $yhigh) {
	    $xbinlow = $x - $s_max*$xbinsize;
	    $xbinhigh = $x + $s_max*$xbinsize;
	    $nxbinlow = int(($xbinlow - $xlow)/$xresolution) + 1;
	    $nxbinhigh = int(($xbinhigh - $xlow)/$xresolution);

	    $ybinlow = $y - $s_max*$ybinsize;
	    $ybinhigh = $y + $s_max*$ybinsize;
	    $nybinlow = int(($ybinlow - $ylow)/$yresolution) + 1;
	    $nybinhigh = int(($ybinhigh - $ylow)/$yresolution);

	    # Step through the bins, and add a gaussian scaled 
	    # contribution to each bin.

	    for ($i=$nxbinlow; $i <= $nxbinhigh; $i++) {
		for ($j=$nybinlow; $j <= $nybinhigh; $j++) {
		    $dx = $x-($xlow + $i*$xresolution);
		    $dy = $y-($ylow + $j*$yresolution);
		    $distsqr = ($dx/($xbinsize))**2 + ($dy/($ybinsize))**2;

		    # Use only points within a 'radial' distance of the bin
		    # and do sanity check to ensure the bin is not outside
		    # the specified limits (could occur for points near the 
		    # edges of the region.

		    if (($distsqr < $s_max**2) && ($i >= 0) && ($j >= 0) && ($i <= $xhighestbin) && ($j <= $yhighestbin) ) {
			$contrib = $exp**(-1 * $distsqr/4);
			$histogram[$i][$j] += $contrib;
		    }
		}
	    }
	}

    }



}

#
# xdim and ydim are the number of columns and rows respectively
#

$xdim = $nx + 1;
$ydim = $ny + 1;

#
# maxcount is the highest value stored in the array
#

$maxcount = 0;
for ($l=0; $l <= $ny; $l++) {
    for ($k=0; $k <= $nx; $k++) {
	$maxcount = int($histogram[$k][$l]) if ($histogram[$k][$l] > $maxcount);
    }
}

#
# Begin the file output
# For a .pgm file, the header is:
#
# P2
# xdim ydim
# 255
#

print OUTFILE "P2\n$xdim\t$ydim\n255\n";

#
# Now output the pixel values
# Initially, the different formats were separated to allow for appropriate 
# normalization.  However, it seemed to make more sense to simply scale 
# the images to use the full dynamic range of the .pgm file format.
# The two output sections are therefore identical, but are left separate
# to make it easier to normalize the values should that be desired.
#

for ($l=$ny; $l >= 0; $l--) {
    for ($k=0; $k <= $nx; $k++) {

	# Can't remember what these were for ...
	#$xhistval = $xlow + $xresolution * $k;
	#$yhistval = $ylow + $yresolution * $l;

	# Boxcar values

	if ( $kernel eq "boxcar" ) {
	    #$percdensity = ($histogram[$k][$l]/$counter)/(3.141592654*$xbinsize*$ybinsize/4);
	    #$percent = $percdensity;
	    # pgm graphic format output
	    $percdensity = $histogram[$k][$l]*255/($maxcount+1);
	    $percent = int($percdensity);
	    $percent = 255 - $percent if ($invert == 1);
	}

	# Gaussian values

	if ( $kernel eq "gauss" ) {
	    #$percdensity = ($histogram[$k][$l]/$counter)/(2*3.141592654*($ybinsize*$xbinsize)**(1/2));
	    #$percent = $percdensity;

	    # pgm graphic format output
	    $percdensity = $histogram[$k][$l]*255/($maxcount+1);
	    $percent = int($percdensity);
	    $percent = 255 - $percent if ($invert == 1);
	}
  
	# pgm graphic output line
	print OUTFILE "$percent\t";

	# individual data point output
	#print OUTFILE "$xhistval\t$yhistval\t$percent\n"
    }

    # This carriage return is actually not necessary, but is kept for the
    # sake of formality.
    print OUTFILE "\n";
}

close ( INFILE );
close ( OUTFILE );












