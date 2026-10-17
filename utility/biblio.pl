#!/usr/bin/env perl
#
# original filename: biblio.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Thu Sep  7, 2006  19:23:32 DST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/utility
#


use strict;
use warnings;
use File::Basename;
use Text::Wrap qw($columns &wrap);
$columns = 75;

use Data::Dumper::Simple as => 'db';
use Local::Debug;

#use lib "$ENV{HOME}/libperl2";
use Local::Constants;
use Local::Astrotools;

my $exe = basename($0);
my $usage = "Usage: $exe author\n".
    "  Use a carat '^' to search only first author\n".
    "  eg.  $exe smith        ... smith is in the author list\n".
    "       $exe ^smith       ... smith is first author\n";

my ($author) = @ARGV;
die $usage unless $author;


my %journals = (
		"aj" => "AJ",
		"araa" => "ARA\&A",
		"aplett" => "Astrophys.Lett.",
		"apspr" => "Astrophys.SpacePhys.Res.",
		"apj" => "ApJ",
		"apjs" => "ApJ Supp",
		"apjl" => "ApJ Lett",
		"ao" => "Appl.Opt.",
		"apss" => "Ap\&SS",
		"aap" => "Astr. Ap.,",
		"aaps" => "Astr. Ap. Supp.,",
		"aapr" => "Ann. Rev. Astr. Astrophys.",
		#areps" => "Ann. Rev. Ear. and Plan. Sci.",
		"areps" => "ARE\&PS",
		"azh" => "AZh",
		#Astronomische Nachrichten
		"an" => "AN",
		
		# b b b
		"bain" => "Bull.Astron.Inst.Netherlands",
		#"baas" => "Bull. Am. Astr. Soc.,",
		"baas" => "BAAS",
		
		# f f f 
		"fcp" => "Fund.CosmicPhys.",
		
		# g g g
		"gca" => "Geochim.Cosmochim.Acta",
		"grl" => "Geophys.Res.Lett.",
		
		# j j j
		"jrasc" => "JRASC",
		"jcp" => "J.Chem.Phys.",
		"jgr" => "J.Geophys.Res.",
		"jqsrt" => "J.Quant.Spec.Radiat.Transf.",
		"jbaa" => "J.Brit.Astr.Assoc.",
		
		# i i i
		"iaucirc" => "IAUCirc.",
		"icarus" => "Icarus",
		
		# m m m
		"memras" => "MmRAS",
		"mnras" => "Mon. Not. R. Astr. Soc.,",
		"memsai" => "Mem.Soc.Astron.Italiana",
		
		
		# n n n
		"nat" => "Nature",
		"nphysa" => "Nucl.Phys.A",
		
		# p p p 
		"pra" => "Phys.Rev.A",
		"prb" => "Phys.Rev.B",
		"prc" => "Phys.Rev.C",
		"prd" => "Phys.Rev.D",
		"pre" => "Phys.Rev.E",
		"prl" => "Phys.Rev.Lett.",
		"pasp" => "Publ. Astron. Soc. Pac.",
		"pasj" => "PASJ",
		"physrep" => "Phys.Rep.",
		"physscr" => "Phys.Scr",
		"planss" => "Planet.SpaceSci.",
		"procspie" => "Proc.SPIE",
		
		# q q q
		"qjras" => "QJRAS",
		
		# s s s
		"skytel" => "S\&T",
		"solphys" => "Sol.Phys.",
		"sovast" => "SovietAst.",
		"ssr" => "SpaceSci.Rev.",
		"sci" => "Science,",
		
		# z z z
		"yzap" => "ZAp",
		
		);

my $bibfile = "$ENV{HOME}/bibtex/bickerton.bib";

# load in the bibiography info
my %entry;
my $in_entry = 0;
my $key;
open (BIB, "$bibfile");
while (<BIB>) {
    
    # if we're at the beginning of an article entry
    if ( $_ =~ /^\@ARTICLE\{.*/i ) {
	($key) = $_ =~ /^\@ARTICLE\{(.*),$/i;
	$entry{$key}{"type"} = "article";
	$in_entry = 1;
    } elsif ( $_ =~ /^\@BOOK\{.*/i ) {
	($key) = $_ =~ /^\@BOOK\{(.*),$/i;
	$entry{$key}{"type"} = "book";
	$in_entry = 1;	
    } elsif ( $_ =~ /^\@INPROCEEDINGS\{.*/i ) {
	($key) = $_ =~ /^\@INPROCEEDINGS\{(.*),$/i;
	$entry{$key}{"type"} = "inproceedings";
	$in_entry = 1;
    } elsif ($_ =~ /^\@InCollection\{.*/i ) {
	($key) = $_ =~ /^\@InCollection\{(.*),$/i;
	$entry{$key}{"type"} = "incollection";
	$in_entry = 1;	
    } elsif ( $_ =~ /^\@MISC\{.*/i ) {         
	($key) = $_ =~ /^\@MISC\{(.*),$/i;
	$entry{$key}{"type"} = "misc";
	$in_entry = 1;
    }	

    
    if ($in_entry) {
	
	# remove braces and other stuff
	for ($_) {
	    s/\{//g;
	    s/\}//g;
	    s/\~//g;
	    s/=//g;
	    s/and others/et al./;
	}
	    

	if ($_ =~ /^\s*author.*$/) {
	    # get rid of multiple 'and'
	    my $num_and = $_ =~ s/and/and/g;
	    $_ =~ s/and// if $num_and > 1;

	    ( $entry{$key}{"author"} ) = $_ =~ /^\s*author\s+(.*)\s+$/;

	} elsif ( $_ =~ /^\s*editor.*$/ ) {
	    s/\,//;
	    ($entry{$key}{"editor"}) = $_ =~ /^\s*editor\s+(.*)\s+$/;

	} elsif ( $_ =~ /^\s*publisher.*$/ ) {
	    s/\,//;
	    ($entry{$key}{"publisher"}) = $_ =~ /^\s*publisher\s+(.*)\s+$/;


	} elsif ( $_ =~ /^\s*journal.*$/ ) {

	    s/,//g;
	    s/\\//g;
	    my ($tmp) = $_ =~ /^\s*journal\s+(.*)\s+$/;	    
	    ($entry{$key}{"journal"}) = $journals{$tmp} || $tmp;

	} elsif ( $_ =~ /^\s*year.*$/ ) {
	    s/\,//;
	    ($entry{$key}{"year"}) = $_ =~ /^\s*year\s+(.*)\s+$/;

	} elsif ( $_ =~ /^\s*title.*$/ ) {
	    s/\,//;
	    ($entry{$key}{"title"}) = $_ =~ /^\s*title\s+(.*)\s+$/;

	} elsif ( $_ =~ /^\s*volume.*$/ ) {
	    s/\,//;
	    ($entry{$key}{"volume"}) = $_ =~ /^\s*volume\s+(.*)\s+$/;

	} elsif ( $_ =~ /^\s*pages.*$/ ) {
	    s/\,//;
	    ($entry{$key}{"pages"}) = $_ =~ /^\s*pages\s+(.*)\s+$/;

	} elsif ( $_ =~ /^\s*booktitle.*$/ ) {
	    s/\,//;
	    ($entry{$key}{"booktitle"}) = $_ =~ /^\s*booktitle\s+(.*)\s+$/;

	} elsif ( $_ =~ /^\s*howpublished.*$/ ) {
	    s/\,//;
	    ($entry{$key}{"howpublished"}) = $_ =~ /^\s*howpublished\s+(.*)\s+$/;
	} elsif ( $_ =~ /^\s*url.*$/ ) {
	    s/\,//;
	    ($entry{$key}{"url"}) = $_ =~ /^\s*url\s+(.*)\s+$/;

	}
	
	$in_entry = 0  if ( $_ =~ /^\s*\}\s*$/ );
	
    }


}
close (BIB);


# go through the keys and report any matches.

$|=1;
printf "\n";
foreach my $key (sort keys %entry) {


    if ( $entry{$key}{"type"} =~ /article/ ) {

	my $author_string = $entry{$key}{"author"};
	if ($author_string =~ /$author/gi) {
	    
	    my ($year, $journal, $volume, $pages) =
		( $entry{$key}{"year"},
		  $entry{$key}{"journal"},
		  $entry{$key}{"volume"},
		  $entry{$key}{"pages"}       );
	    $volume = "vol?" unless $volume;
	    $journal = "journ?" unless $journal;
	    my $title = wrap("   ", "   ", ($entry{$key}{"title"}) );
	    printf STDOUT "($key)\n%s%s. %s %s, %s\n%s".
		"\n\n", 
		$author_string,
		$year,
		$journal,
		$volume,
		$pages,
		$title;
	}

    } elsif ( $entry{$key}{"type"} =~ /book/ ) {

	my $editor_string = $entry{$key}{"editor"};
	my $author_string = ($editor_string) ? $editor_string : $entry{$key}{"author"};
	if ($author_string =~ /$author/gi) {
	    
	    my $line = sprintf "($key)\n%s  In \"%s\" %s, %s.\n".
		"\n\n", 
		$author_string,
		$entry{$key}{"title"},
		$entry{$key}{"publisher"},
		$entry{$key}{"year"};

	    printf "%s\n", wrap("   ","   ", ($line) );
	}
	

    } elsif ( $entry{$key}{"type"} =~ /(misc|inproceedings|incollection)/i ) {

	my $author_string = $entry{$key}{"author"};
	if ($author_string =~ /$author/gi) {
	    
	    my $line = sprintf "($key)\n%s %s %s.".
		"\n", 
		$entry{$key}{"author"},
		$entry{$key}{"title"},
		$entry{$key}{"year"};

	    printf "%s", wrap("","   ", ($line) );

	    my $line2 = "";
	    foreach my $extra ( keys %{$entry{$key}} ) {
		unless ( $extra =~ /type|author|title|year/ ) {
		    $line2 .= sprintf "   -->${extra}: %s\n", $entry{$key}{$extra};
		}
	    }
	    printf "%s\n", $line2;
	}

    }


}

exit 0;
