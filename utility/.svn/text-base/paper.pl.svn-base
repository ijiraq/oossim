#!/usr/bin/env perl
#
# original filename: paper.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Sat Jun 21, 2008  16:14:05 DST
#  Host: bender.astro.princeton.edu
#  Working Directory: /Users/bick/working/papers/paper_phd2-scint
#


use strict;
use warnings;
use File::Basename;
use Getopt::Std;

my $exe = basename($0);
my $usage = "Usage: $exe finaldir aastex|emulateapj(default)\n".
  "  options: -v (verbose), -c (compile), -t (tar), -p (postscript)\n";

my %options = ();
getopts("vptc", \%options);

my $verbose = defined($options{v}) ? 1 : 0;
my $tar = defined($options{t}) ? 1 : 0;
my $postscript = defined($options{p}) ? 1 : 0;
my $compile = defined($options{c}) ? 1 : 0;

my ($finaldir, $style) = @ARGV;
die $usage unless $finaldir;

$style = "emulateapj" unless $style;
die "Style must be emulateapj or aastex.\n" 
  unless $style =~ /^(emulateapj|aastex)$/;

my $astroph = ($style=~/^aastex$/) ? 0 : 1;
my $preprint = ($astroph) ? "" : "preprint";
my $documentclass = "\\documentclass\[$preprint\]\{$style\}";
my $astroph_bool = ($astroph) ? "true" : "false";
my $setboolean_astroph = "\\setboolean\{astroph\}\{$astroph_bool\}";
my $manuscript_raw = "ms_raw.tex";
my $manuscript = ($astroph) ? "ms-astroph" : "ms";
my $texfile = "${manuscript}.tex";

my $figdir = "figures";

#######################################################################
# scan the manuscript to get the figure order
if ( $compile ) { 

  my $fig_i = 1;
  my $fig_enviro = 0;
  my @figures;
  my @letter = ('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p');
  open(RAW, "$manuscript_raw");
  open(MS, ">$texfile");
  while(<RAW>) {
    
    my $line = $_;
    
    # set the document class
    if ( $line =~ /documentclass/ ) {
      $line = "$documentclass";
    }
    
    # set the boolean
    if ( $line =~ /setboolean\{astroph\}/ ) {
      $line = sprintf "$setboolean_astroph\n";
    }
    
    # replace figure names and store the number to copy it appropriately
    
    
    my $lines = $line;
    my @abc = ();
    
    # read in the whole figure
    if ($line =~ /begin\{figure\}/) {
      
      while(<RAW>) {
	
	my $figline = $_;
	if ($figline =~ /\{(.*).eps\}/) {
	  push @abc, [$1, "f${fig_i}"];
	}
	$lines .= $figline;
	
	last if $figline =~ /end\{figure\}/;
	
      }
      
      if ( @abc == 0 ) {
	die "Error: figure environment contains no eps file\n";
      } elsif ( @abc == 1 ) {
	my ($src, $dst) = ($abc[0]->[0].".eps", $abc[0]->[1].".eps");
	push @figures, [$src, $dst];
	$lines =~ s/$src/$dst/;
      } elsif ( @abc > 1 )  {
	foreach my $j ( 0 .. $#abc ) {
	  my ($src, $dst) = @{$abc[$j]};
	  $dst .= ${letter[$j]}. ".eps";
	  push @figures, [$src, $dst];
	  $lines =~ s/$src/$dst/;
	}   
      }
      $fig_i += 1;
    } # end of figure read in
    
    print MS $lines;
  }
  close(MS);
  close(RAW);
  
  
  ########################################################################
  # remove any existing figures
  foreach my $figure (glob("f\d+[a-z]?.eps")) {
    print STDOUT "Removing $figure\n" if $verbose;
    unlink $figure;
  }
  
  
  ########################################################################
  # get the figures
  my $missing_files = "";
  (-d $figdir) or mkdir $figdir;
  foreach my $ref (@figures) {
    my ($figure, $figN) = @$ref;
    
    my $file;
    my $basefile = basename($figure);
    ($file = $figure) =~ s/\~/$ENV{HOME}/; # for some reason glob fails
    if ( $file and -s $file ) {
	my $cp1 = "cp $file ${figdir}/$basefile";
	my $cp2 = "cp ${figdir}/$basefile $figN";
	printf STDOUT "$cp1\n" if ($verbose);
	system($cp1);
	printf STDOUT "$cp2\n" if ($verbose);
	system($cp2);

    # if it's come from a different machine, but we have it
    } elsif ( (${figdir}/$basefile) and (-s ${figdir}/$basefile) ) {
	my $cp1 = "cp ${figdir}/$basefile $figN";
	printf STDOUT "$cp1\n" if ($verbose);
	system($cp1);
    } else {
	$missing_files .= "  ".$figure."\n";
    }
    
  }
  die "Files missing:\n$missing_files\n" if length($missing_files) > 1;
  
  
  ########################################################################
  # compile
  
  
  my $cmd_latex = "latex ${texfile}";
  system($cmd_latex) && die;
  system("bibtex $manuscript");
  system($cmd_latex) && die;
  system($cmd_latex) && die;
  system($cmd_latex) && die;
  
}

########################################################################
# make the postscript
if ($postscript) {
  system("dvips -o ${finaldir}.ps ${manuscript}.dvi");
  system("ps2pdf ${finaldir}.ps");
}

########################################################################
# tar it up
if ($tar) {
  (-d $finaldir) || mkdir $finaldir;
  system("cp f*.eps $texfile ${manuscript}.bbl README coverletter $finaldir/");
  system("tar cvf ${finaldir}.tar $finaldir/");
}


exit 0;
