#!/usr/bin/env perl 
#
#

use strict;
use warnings;
use File::Basename;

my $outfile = shift;
my $keep = shift;
my $height = shift;
my $angle = shift;
my $nWide = shift;
my @images = @ARGV;

die "Usage: " .basename(__FILE__)." outfile(no suffix) keep(0 or 1) height angle nWide images...\n" if (! $images[0]);

my $maxUnprocFloats = 10;


# print the header information

open(TEXFILE,">${outfile}.tex");

printf TEXFILE "\\documentclass[letterpaper, 10pt]{article}\n\n";

printf TEXFILE "\\usepackage[dvips]{graphicx}\n";
printf TEXFILE "\\usepackage{epsfig}\n";
printf TEXFILE "\\usepackage{float}\n\n";

printf TEXFILE "\\setlength{\\oddsidemargin}{+0.in}\n";
printf TEXFILE "\\setlength{\\textheight}{9.9in}\n";
printf TEXFILE "\\setlength{\\textwidth}{6.5in}\n";
printf TEXFILE "\\setlength{\\topmargin}{-0.25in}\n\n";


printf TEXFILE "\\pagestyle{empty}\n\n";

printf TEXFILE "\\begin{document}\n\n";




# print the float sections for each image  

my $count=0;
for (my $i=0; $i<(scalar @images); $i++) {


    printf TEXFILE "\\begin{figure}\n";
    
    my $file;
    my $caption = "";
    foreach my $j (1 .. $nWide) {
	$file = $images[$i];
	printf TEXFILE "\\centering\\epsfig{figure=$file, angle=$angle, height=$height}"; 
	$caption .= "$file,  ";

	$i++ if ($j<$nWide);
	last if ($i>$#images);
    }

    printf TEXFILE "\n";

    # escape any special characters.
    $caption =~ s/_/\\_/g;
    $caption =~ s/,  $//;
    
    printf TEXFILE "\\caption{$caption}\n";
    printf TEXFILE "\\end{figure}\n\n";

    printf TEXFILE "\\clearpage\n\n" 
	if ( $count%$maxUnprocFloats == ($maxUnprocFloats-1) );
    
    $count++;
}
printf TEXFILE "\\end{document}\n";

#clean up
close (TEXFILE);


# latex the file and convert to postscript.

system ("latex ${outfile}.tex");
system ("dvips -o ${outfile}.ps ${outfile}.dvi");

unlink "${outfile}.dvi";

if ($keep == 0) {
    unlink "${outfile}.tex";
    unlink "${outfile}.aux";
    unlink "${outfile}.log";
}

exit (0);
