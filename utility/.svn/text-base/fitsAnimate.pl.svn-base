#!/usr/bin/env perl
#
#

use strict;
use warnings;
use File::Basename;

use 5.6.0;
use PDL;
use PDL::Image2D;
use PDL::Primitive;


my $anim_file = shift @ARGV;
my $scalefactor = shift @ARGV;
my $every = shift @ARGV;
my $percent = shift @ARGV;
my @images = @ARGV;

my $exe = basename ($0);
die "Usage: $exe anim_file scalefactor every percent images ...\n" 
    unless ( $images[0]   && 
	     $scalefactor && $scalefactor=~/\d*/ &&
	     $every       && $every=~/\d*/       &&
	     $percent     && $percent=~/\d\.\d*/   );

#  get the clip limits
my $ref_raw = rfits($images[0]);
my ($dx,$dy) = $ref_raw->dims;


my @gif_images;
my @tmp_images;
my $count = 0;
foreach my $image (@images) {

    $count++;
    next if ($count % $every);

    my $scaled = zeroes $scalefactor*$dx, $scalefactor*$dy;
    my $raw = rfits($image);
    my ($mean, $rms, $median, $min, $max) = $raw->stats;

    # clip off above median pixels (ie. stars)
    my $sky_low = $raw->clip($median-4.0*$rms,$median);

    # mean of clipped image is the rms of the sky
    my ($mean_sky, $rms_sky, $median_sky, $min_sky, $max_sky)= $sky_low->stats;
    
    #  clipping at 15% sky RMS (mean_sky variable) seems good
    my $clip = $raw->clip($median-$percent*$mean_sky, $median+$percent*$mean_sky);
    rescale2d($clip, $scaled);

    (my $image_tmp = $image) =~ s/\.fits$/.tmp.fits/;
    push @tmp_images, $image_tmp;
    (my $image_gif = $image) =~ s/\.fits$/.gif/;
    push @gif_images, $image_gif;
    $scaled->wfits($image_tmp,-32);

    my $s = "convert $image_tmp $image_gif";
    print "executing: $s\n";
    system ("$s");

}

my $tmp_image_string = join (" ",@tmp_images);
	
print "Deleting tmp files.\n";
system ("rm $tmp_image_string");

my $gif_image_string = join (" ",@gif_images);

print "Making animation.\n";
system ("convert $gif_image_string $anim_file");

system ("rm $gif_image_string");

exit 0;
