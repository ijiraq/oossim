#!/usr/bin/env perl
#
#

use strict;
use File::Basename;

# read in the rc file   (all this to grab the $webdir variable)
#  ... i need to move this into webpost.pl at somepoint and be rid of htmllist
my $rcfile = "$ENV{HOME}/.webpost/webpostrc";
(-s $rcfile) or die "rc file \'$rcfile\' not found.  Exiting.\n";

my %rc_settings;
my @forbiddenDirs;
my %forbiddenDirs;
open (RC, "$rcfile");
while (<RC>) {
    next if ( $_ =~ /^\#/  or  $_ =~ /^\s*$/ );
    my ($command, $value) = split;
    if ($command =~ /^[dD]eny$/ ) {

	# don't mess around with these directories. They're not repositories.
	push @forbiddenDirs, $value;
	$forbiddenDirs{$value} = 1;
    }	else {

	$rc_settings{$command} = $value;
    }
}
close (RC);

# do some error checking.
my $webdir = $rc_settings{"WEBDIR"} or die "WEBDIR not defined in $rcfile\n";
(-d $webdir) or die "Directory WEBDIR = \'$webdir\' not found.  Exiting.\n";

my ($dir) = @ARGV;
$dir = "$webdir/$dir";
my ($thisdir, $parentdir, $ext) = fileparse($dir);



# switch these comments to use the dirname instead of index.html
#my $defaultfile = "./${thisdir}.html";
my $defaultfile = "$webdir/misc/index.html";

my $targetfile;
my ($targetpath, $targetdir, $targetext);
if ($dir) {
    $dir =~ s/(.*)\/$/$1/;
    ($targetdir, $targetpath, $targetext) = fileparse($dir);

    # switch these comments to use the dirname instead of list.html
    #$targetfile = "${targetpath}/${targetdir}/${targetdir}.html";
    $targetfile = "${targetpath}${targetdir}/index.html";
}
chomp $thisdir if $thisdir;

my $indexfile = ($dir) ?  "$targetfile" : "$defaultfile";

(-s $indexfile) && unlink "$indexfile";

# HTML header
my $indexstr = "<html>\n".
    "<head>\n".
    "<Title> Miscellaneous Files\n".
    "</title>\n".
    "</head>\n".
    "<body text=\"black\" background=\"white\">\n".
    "<basefont size=2 face=\"times\">\n".
    "\n".
    "<div align=\"center\">\n".
    "<font size=\"+3\"><b>$targetdir</b></font>\n".
    "</div>\n".
    "\n".
    "<table align=\"center\" border=0 width=\"90%\">\n".
    "\n";


# get a long directory listing and put each entry in an array
my $ls = `ls -lh $dir`;
my @ls = split /\n/, $ls;

# make an HTML table entry for each
foreach my $line (@ls) {
    
    my ($size, $mon, $day, $time, $file) = (split /\s+/,$line)[4,5,6,7,8];

    #print STDOUT "f$file s$size m$mon d$day t$time\n";
    $indexstr .= "<tr align=\"left\">\n".
	"<th> <font size=\"-1\"> <A href=\"$file\"> $file </A></font>\n".
	"<th> <font size=\"-1\"> $size</font>\n".
	"<th> <font size=\"-1\"> $mon $day $time</font>\n".
	"\n";

    
}


# print the output file
open (INDEX, ">$indexfile");
printf INDEX "$indexstr\n";
close(INDEX);
