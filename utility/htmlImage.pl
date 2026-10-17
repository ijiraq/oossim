#!/usr/bin/env perl 
#
#

use strict;
use warnings;
use File::Basename;

my ($outfile, $nWide, @images) = @ARGV;

my $exe = basename($0);
die "Usage: $exe outfile nWide images...\n" if (! $images[0]);

# header
open (HTMLFILE, ">${outfile}");
printf HTMLFILE "<html>\n".
    "<head>\n".
    "<Title>\n".
    "</title>\n".
    "</head>\n".
    "<body bgcolor=\"white\" text=\"black\">\n".
    "<TABLE ALIGN=\"center\" border=0 width\"90%%\">";

# make a table of images
my $count=0;
for (my $i=0; $i<(scalar @images); $i++) {

    printf HTMLFILE "<TR ALIGN=\"center\">\n";  # start a row
    foreach my $j (1 .. $nWide) {

	# add an entry to this row
	printf HTMLFILE "<TH> <img src=\"$images[$i]\" width=\"100%%\">\n";
	printf HTMLFILE "<div> %s </div>\n", basename $images[$i];

	$i++ if ($j<$nWide);
	last if ($i>$#images);
    }
    printf HTMLFILE "\n";
    $count++;
}

printf HTMLFILE "</BODY>\n</HTML>\n";
close (HTMLFILE);

exit (0);
