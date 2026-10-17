#!/usr/bin/env perl
#
# original filename: webLog.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Sun Jun 15, 2008  14:46:39 DST
#  Host: bender.astro.princeton.edu
#  Working Directory: /Users/bick/usr/src/utility
#


use strict;
use warnings;
use File::Basename;

use Local::Misc;

my $exe = basename($0);
my $usage = "Usage: $exe x\n";

my ($ig) = @ARGV;

my %ignore = ();
if ($ig and $ig=~/ig/) {
  %ignore = ("128.112.25.181"=>1);
}

my $prefix = "/\~bick";
my $downpref = ""; #"/~bick/download.php?f=";
my %pages = (
	     #"$prefix/" => "index",
	     "$prefix/index.php" => "index",
	     "$prefix/aboutme.php" => "about",
	     "$prefix/research.php" => "research",
	     "$prefix/publications.php" => "pubs",
	     "$prefix/contact.php" => "contact",
	     "$prefix/TASS.php" => "tass",
	     "$prefix/linux.php" => "linux",
	     "$prefix/bookmarks.php" => "links",

	     "${downpref}linux_sum.ps" => "d-sumPs",
	     "${downpref}linux_sum.pdf" => "d-sumPdf",
	     "${downpref}2col_linux_sum.ps" => "d-sum2ps",
	     "${downpref}2col_linux_sum2.ps" => "d-sum22ps",
	     "${downpref}2col_linux_sum_2.ps" => "d-sum22ps",
	     "${downpref}2col_linux_sum.pdf" => "d-sum2pdf",
	     "${downpref}cascaPoster2006_final.pdf" => "d-c06",
	     "${downpref}cascaPoster2007_final.pdf" => "d-c07",
	     "${downpref}dpsPoster2005_final.pdf" => "d-d05",
	     "${downpref}kbo_occult.mpg" => "d-kbompg",
	     "${downpref}lightcurve.mpg" => "d-lcmpg",
	     "${downpref}thesis_50min.pdf" => "d-phd-50min",
	     "${downpref}bickerton_phd.pdf" => "d-phd-thes"
	    );

my $webdir = "$ENV{HOME}/WWW/public";
(-d $webdir) or $webdir = "/Library/WebServer/Documents";
my $sitefile = "${webdir}/logs/sitelog.log";
my $downfile = "${webdir}/logs/downloads.log";

# store the log info by date and ip
my %hits;
my %domain;
open(SITE, "$sitefile");
while(<SITE>) {
  next if /^\$/;
  my ($date, $time, $ip, $page) = split;
  push @{$hits{$date}{$ip}}, [$date, $time, $ip, $page];
  $domain{$ip} = 1;
}
close(SITE);

open(DOWN, "$downfile");
while(<DOWN>) {
  next if /^\$/;
  my ($date, $time, $ip, $page) = split;
  push @{$hits{$date}{$ip}}, [$date, $time, $ip, $page];
  $domain{$ip} = 1;
}
close(DOWN);



# get the domains
foreach my $ip ( keys %domain ) {
  my @ns = (split /\n/, `nslookup $ip`);
  my ($line) = grep {$_ =~ /name =/} @ns;
  my ($dns,$name) = $line =~ /(.*)\s+name\s+=\s+(.*)/;
  $domain{$ip} = $name;
}

# go through daily hits
foreach my $date (sort keys %hits) {
  printf STDOUT "%s\n", centreText("\e[36;1m-- ".$date." --\e[0m", 80);
  foreach my $ip (sort keys %{$hits{$date}} ) {

    next if $ignore{$ip};

    # count the hits and
    my %pagetime;
    my %pagehits;
    foreach my $hit (@{$hits{$date}{$ip}}) {
      my ($date, $time, $ip, $page) = @$hit;

      # if it doesn't exist, define it
      unless ($pagehits{$page}) {
	$pagehits{$page} = 1;
	$pagetime{$page} = $time;
      } else {

	# if this hit is earlier ... use it (have to pick one)
	$pagetime{$page} = $time if ($pagetime{$page} lt $time);
	$pagehits{$page} += 1;
      }

    }
    
    # print a header
    printf STDOUT "\e[31;1m%-15s %-s \e[0m\n", $ip, $domain{$ip};

    foreach my $page (sort keys %pagehits) {
      my $thispage = $pages{$page} ? $pages{$page} : $page;
      printf STDOUT "%-10s", substr($thispage,0,10);
    }
    printf STDOUT "\n";

    foreach my $page (sort keys %pagehits) {
      printf STDOUT "%-5s(%1d) ", $pagetime{$page}, $pagehits{$page};
    }
    printf STDOUT "\n\n";
  }
}


exit 0;
