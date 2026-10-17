#!/usr/bin/env perl
#
#
use strict;
use warnings;

use Local::Constants;
use Local::Rotate;
use Local::Astrotools;

my $usage = "$0 n {(c)ent|(f}oc} a e [pomega] [acsNode] [i] [true] [prefix]\n".
    "\n".
    "n        = number of points to use\n".
    "c|f      = origin at (c)entre or (f)ocus\n".
    "a        = semi-major axis\n".
    "e        = eccentricity\n".
    "pomega   = argument of perihelion  (zero if not given)\n".
    "ascNode  = argument of the ascending Node (zero if not given)\n".
    "i        = inclination  (zero if not given)\n".
    "true     = true anomaly (1) or mean anomaly(0) default=0\n".
    "           point spacing based on time for true anomaly, even for mean\n".
    "           just use 0 for this if you want evenly spaced points\n".
    "prefix   = base filename prefix (STDOUT if not given)\n";

my ($n, $cen_foc, $aa, $e, $pomega, $ascNode, $i, $true_spaced, $base) = @ARGV;
for (@ARGV) {die $usage if $_=~/help/;}
die $usage unless $e;
die $usage unless (  $cen_foc =~ /^[cCfF]/ && 
		     $aa =~ /^\d+/  &&
		     $e =~ /^\d+/  );

my $focus = ($cen_foc =~ /^[Ff]/) ? 1 : 0;
my $date = `date`;
chomp $date;

# set constants and initialize values to radians (or zero if not provided)
my $PI = 3.141592654;
my $dmean = 2.0*$PI/$n;  
$pomega  = ($pomega)  ? $pomega*$PI/180.0  : 0;
$ascNode = ($ascNode) ? $ascNode*$PI/180.0 : 0;
$i       = ($i)       ? $i*$PI/180.0       : 0;
$true_spaced = 0 unless ( defined($true_spaced) );

# make an output file name that won't conflict with previous ones
my $file = "foo";
if ( $base ) {
    $file = $base."1";
    foreach my $k (1 .. 100) {
	my $num = sprintf "%03d", $k;
	$file = $base.$num;
	last unless  ( -s "$file" );
    }
    $file = $base; # this trumps out the prev few lines
}

# get the semi-minor axis 'bb' and center-to-focus distance 'cc'
my $bb = sqrt (  $aa**2 * (1.0 - $e**2) );
my $cc = sqrt($aa**2 - $bb**2);



#############################################################################
# make the ellipse and rotate by the argument of perihelion

my ($ellipfile, $apfile, $nodefile, $normfile, 
    $arcperifile, $arcnodefile, $arcifile) = 
    ("${file}_ellip", "${file}_apline", "${file}_nodes", "${file}_norm", 
     "${file}_arcperi", "${file}_arcnode", "${file}_arci");
if ($base) {
    open (PERI2AP, ">${apfile}");
    open (NODES, ">${nodefile}");
    open (ELLIP, ">${ellipfile}");
    open (NORMAL, ">${normfile}");
    open (ARCPERI, ">${arcperifile}");
    open (ARCNODE, ">${arcnodefile}");
    open (ARCI, ">${arcifile}");
}    

my $header = sprintf "# Made with ellipse.pl on %s\n".
    "# N_points         %d\n".
    "# centre           %s\n".
    "# semi_major_axis  %.2f\n".
    "# eccentricity     %.2f\n".
    "# arg_of_peri      %.2f\n".
    "# arg_of_asc_Node  %.2f\n".
    "# inclination      %.2f\n".
    "# anomaly_spacing  %s\n".
    "", $date, $n, ($focus?"focus":"geometric_centre"),
    $aa, $e, 180.0*$pomega/$PI, 180.0*$ascNode/$PI, 180.0*$i/$PI, 
    ($true_spaced?"true":"mean");

if ($base) {
    printf ELLIP   "%s${header}", "# ellipse\n";
    printf PERI2AP "%s${header}", "# line_of_apsides\n";
    printf NODES "%s${header}", "# line_of_nodes\n";
    printf NORMAL "%s${header}", "# normal_to_ellipse\n";
    printf ARCPERI "%s${header}", "# peri arc for labelling\n";
    printf ARCNODE "%s${header}", "# node arc for labelling\n";
    printf ARCI "%s${header}", "# inclination arc for labelling\n";
} else {
    printf STDOUT "%s${header}", "# ellipse\n";
}

my ($x0, $y0, $z0, $eclLat0, $elong0);
my ($toler, $maxiter) = (0.1*$PI/180.0, 100);
my $ratio = 0.8;
my $iratio = 0.5;
foreach my $j (0 .. $n-1) {

    # get the unrotated ellipse
    my $mean = $j * $dmean;
    my $true = mean2true($mean, $e, $toler, $maxiter);

    my ($r, $theta);
    if ($focus && $true_spaced) {
	$theta = $true;
	$r = $aa*(1.0 - $e**2) / (1.0 + $e*cos($theta));
    } else {	
	$theta = $mean;
	$r = sqrt(($aa*$bb)**2/(($aa*sin($theta))**2 + ($bb*cos($theta))**2));
    }

    # E= ellipse,   C= circle,   L=line-of-peri,   N=normal,   P=peri-arc, 
    # I=incl-arc,   A=nodes-arc
    # get the x-axis and z-axis lines  # ie. peri and normal
    my ($Lx, $Ly, $Lz) = ( (-2.0*$aa + $j*(4.0*$aa)/$n), 0, 0 );
    my ($Nx, $Ny, $Nz) = ( 0, 0, (-2.0*$aa + $j*(4.0*$aa)/$n) );

    # convert to cartesian and translate to focus if required
    my ($Ex, $Ey, $Ez) = ($r*cos($theta), $r*sin($theta), 0);
    my ($Cx, $Cy, $Cz) = ($ratio*$aa*cos($mean), $ratio*$aa*sin($mean), 0);
    $Ex -= ($focus && ! $true_spaced) ? $cc : 0;


    # subscript pin for rotation by pomega, inclination, and arg of node

    # rotate by pomega (argument of perihelion)
    my ($Ex_p, $Ey_p, $Ez_p) = rotate3D('z', $pomega, $Ex, $Ey, $Ez);
    my ($Lx_p, $Ly_p, $Lz_p) = rotate3D('z', $pomega, $Lx, $Ly, $Lz);
    my ($Nx_p, $Ny_p, $Nz_p) = rotate3D('z', $pomega, $Nx, $Ny, $Nz);
    my ($Px_p, $Py_p, $Pz_p) = rotate3D('z', $pomega, $Cx, $Cy, $Cz);

    # rotate by $i (orbital inclination)
    my ($Ex_pi, $Ey_pi, $Ez_pi) = rotate3D('x', $i, $Ex_p, $Ey_p, $Ez_p);
    my ($Lx_pi, $Ly_pi, $Lz_pi) = rotate3D('x', $i, $Lx_p, $Ly_p, $Lz_p);
    my ($Nx_pi, $Ny_pi, $Nz_pi) = rotate3D('x', $i, $Nx_p, $Ny_p, $Nz_p);
    my ($Px_pi, $Py_pi, $Pz_pi) = rotate3D('x', $i, $Px_p, $Py_p, $Pz_p);

    # rotate the inclination arc up to vertical about y-axis
    my ($Ix_y, $Iy_y, $Iz_y) = 
	rotate3D('y', $PI/2.0, $iratio*$Cx, $iratio*$Cy, $iratio*$Cz);

    # rotate by $ascNode  (argument of the ascending Node)
    my ($Ex_pin, $Ey_pin, $Ez_pin) = 
	rotate3D('z', $ascNode, $Ex_pi, $Ey_pi, $Ez_pi);
    my ($Lx_pin, $Ly_pin, $Lz_pin) = 
	rotate3D('z', $ascNode, $Lx_pi, $Ly_pi, $Lz_pi);
    my ($Lx_n, $Ly_n, $Lz_n) = rotate3D('z', $ascNode, $Lx, $Ly, $Lz);
    my ($Nx_pin, $Ny_pin, $Nz_pin) = 
	rotate3D('z', $ascNode, $Nx_pi, $Ny_pi, $Nz_pi);
    my ($Px_pin, $Py_pin, $Pz_pin) = 
	rotate3D('z', $ascNode, $Px_pi, $Py_pi, $Pz_pi);
    my ($Ix_ny, $Iy_ny, $Iz_ny) = rotate3D('z', $ascNode, $Ix_y, $Iy_y, $Iz_y);

    my $eclLat = $DEG*atan2( $Ez_pin, sqrt($Ex_pin**2 + $Ey_pin**2) );
    my $elong  = $DEG*atan2( $Ey_pin, $Ex_pin );

    if ($base) {
	printf ELLIP "%.6f %.6f %.6f $j %.3f %.3f %.3f\n", $Ex_pin, $Ey_pin, $Ez_pin, $eclLat, $elong, $aa;
	printf PERI2AP "%.6f %.6f %.6f\n", $Lx_pin, $Ly_pin, $Lz_pin;
	printf NORMAL "%.6f %.6f %.6f\n", $Nx_pin, $Ny_pin, $Nz_pin;
	printf NODES "%.6f %.6f %.6f\n", $Lx_n, $Ly_n, $Lz_n;

	printf ARCPERI "%.6f %.6f %.6f\n", $Px_pin, $Py_pin, $Pz_pin
	    if ($theta>=(2.0*$PI - $pomega) );
	printf ARCNODE "%.6f %.6f %.6f\n", $Cx, $Cy, $Cz
	    if ($theta<=($ascNode) && $theta>=0 );
	printf ARCI "%.6f %.6f %.6f\n", $Ix_ny, $Iy_ny, $Iz_ny
	    if ( $theta>=(2.0*$PI - $i) );

    } else {
	printf STDOUT "%.6f %.6f %.6f $j %.3f %.3f %.3f\n", $Ex_pin, $Ey_pin, $Ez_pin, $eclLat, $elong, $aa;
    }

    ($x0, $y0, $z0, $eclLat0, $elong0) = 
	($Ex_pin, $Ey_pin, $Ez_pin, $eclLat, $elong) if $j==0; 

}
if ($base) {
    printf ELLIP "%.6f %.6f %.6f $n %.3f %.3f %.3f\n", $x0, $y0, $z0, $eclLat0, $elong0, $aa;
    close (ELLIP);
    close (NODES);
    close (PERI2AP);
    close (NORMAL);
} else {
    printf STDOUT "%.6f %.6f %.6f $n %.3f %.3f %.3f\n", $x0, $y0, $z0, $eclLat0, $elong0, $aa;
}


printf STDOUT "Ellipse coordinates written to $ellipfile\n".
    "Line of apsides coordinates written to $apfile\n".
    "Line of nodes coordinates written to $nodefile\n".
    "Normal to ellipse coordinates written to $normfile\n".
    "Arc line for argument of perihelion written to $arcperifile\n".
    "Arc line for longitude of the ascending node written to $arcnodefile\n".
    "Arc line for inclination written to $arcifile\n" if $base;

exit 0;
