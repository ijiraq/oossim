#!/usr/bin/env perl
#
# original filename: webpost.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Wed Aug  9, 2006  12:20:34 DST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/utility
#


use strict;
use warnings;
use File::Basename;
use File::Copy;
use File::stat;

my $exe = basename($0);
my $usage = "Usage: $exe command dir files\n".
    "commands: post|add rm|remove|del flush\n".
    "\n".
    "eg.  $exe add misc file.dat\n".
    "     $exe rm misc file.dat\n".
    "     $exe flush misc\n".
    "     $exe flush auto\n";

my ($command, $basedir, @files) = @ARGV;
die $usage unless $basedir;
die $usage unless ($command =~ /(post|add|rm|remove|del|flush)/);


# if command is 'flush' ... set auto (from $basedir)
my $auto = ($command eq 'flush' and $basedir eq 'auto') ? 1 : 0;

##########################################################################
# directory setup
#
##########################################################################

# read in the rc file
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
my $dir = "$webdir/$basedir/";
my $junkdir = "$webdir/junk";

my $dir_removed = 0;

die "Name \'auto\' is reserved for use with \'flush\' command. Exiting.\n" 
    if ($basedir eq 'auto' and $command ne 'flush');
foreach my $forbidden (@forbiddenDirs) {
    die "Will not operate on core directory: $basedir. Exiting\n"
	if ($basedir eq $forbidden);
}

my $flush_num  = $rc_settings{'flush_num'};
my $flush_unit = $rc_settings{'flush_unit'};

# allow a flush time override
my $number = '[+-]?\d+\.?\d*';
foreach my $file (@files) {
    # grab settings if they're provide among the @files
    if ( $file =~ /(week|day|month)$/ ) {
	($flush_num,$flush_unit) = $file =~ /($number)(week|day|month)$/;
    }
}
# keep only real files ... not flush times
@files = grep { $_ !~ /(week|day|month)$/ } @files;


###########################################################################3
# 
# function definitions
# 
##########################################################################

sub fileExist ($) {
    my ($directory) = @_;
    
    if ( -f $directory ) {
	printf "junk directory: $directory exists as a regular file.".
	    "Delete and make a directory? [Y/n]: ";
	my $reply = <STDIN>;

	if ($reply =~ /[yY]/) {
	    unlink $directory;
	    mkdir $directory;
	} else {
	    die "Not replacing file $dir with directory. Exiting.";
	}
	
    }
    return 0;
}

sub dirExist ($) {
    my ($directory) = @_;
    
    unless (-d $directory) {
	printf "Making directory $directory\n";
	mkdir $directory;
    }
    return 0;
}

sub postFile ($) {

    my ($file) = @_;
    die $usage unless $file;

    my $fullname = "$dir/$file";
    my $reply = "y";
    if (-s $fullname) {
	printf STDOUT "$fullname already exists. Replace? ";
	$reply = <STDIN>;
    }

    die "Aborted\n" unless $reply =~ /^[yY]/;    
    copy $file, $dir;

    return 0;
}

sub rmFile ($) {

    my ($file) = @_;
    die $usage unless $file;

    my $fullname = "$dir/$file";
    ((-s $fullname) && unlink ("$fullname")) || 
	die "$fullname does not exist\n";

    return 0;
}

sub flushDir ($) {

    my ($dir_local) = @_;

    # set the time limit to flush old files
    my $seconds_per_day = 86400;
    my $seconds_per_week = 7.0*$seconds_per_day;
    my $seconds_per_month = 30.0*$seconds_per_week;
    my $time = time;

    my $seconds_lim = $seconds_per_week;
    $seconds_lim = $seconds_per_day if $flush_unit =~ /^day/;
    $seconds_lim = $seconds_per_week if $flush_unit =~ /^week/;
    $seconds_lim = $seconds_per_month if $flush_unit =~ /^month/;
    $seconds_lim *= ($flush_num) ? $flush_num : 1.0;


    # go thru and remove files older than $seconds_lim
    foreach my $file (<$dir_local/*>) {
	next if $file =~ /html$/;
	my $ctime = stat($file)->ctime;
	
	if (  ($time - $ctime) > $seconds_lim ) {
	    print "Flushing $file to $junkdir\n";
	    system("mv $file $junkdir") ;
	}
    }

    # if there are no more files in the directory (other than the html file)
    #   delete the html file, and remove the directory
    my @htmlfiles = grep { $_=~/html$/ } (<$dir_local/*>);
    my $htmlfile = shift @htmlfiles;
    my @filelist = grep { $_!~/html$/ } (<$dir_local/*>);
    unless (@filelist) {
	unlink "$htmlfile";
	rmdir $dir_local;
	$dir_removed = 1;
	printf "Deleted last file in the directory, removing directory:\n".
	    " ----> $dir_local.\n";
    }
    
    return 0;
}





##################################################################
# $junkdir existance
# see if junkdir exists as a file ... remove it and make a directory
# see if the directory exists ... or make it.
fileExist ($junkdir);
dirExist ($junkdir);
chmod (0700, $junkdir);



###########################################################################
# process the appropriate command

#######################################################################
#       Add        Add          Add         Add

if ($command =~ /(post|add)/) {

    # make sure dir exists;
    fileExist ($dir);
    dirExist ($dir);
    chmod (0755, $dir);

    foreach my $file (@files) {	print "Adding $file\n"; postFile($file); }
    flushDir($dir);


#######################################################################
#       Remove        Remove          Remove         Remove

} elsif ($command =~ /(rm|remove|del)/ ) {

    # make sure dir exists;
    ( -d $dir ) or die "Directory $dir does not exist. Exiting.\n";

    @files = grep { $_ !~ /html$/ } map { basename $_ } (<$dir/*>) 
	if $files[0] eq 'allPostedFiles';
    
    foreach my $file (@files) { print "Removing $file\n"; rmFile($file);  }
    flushDir($dir);


#######################################################################
#       Flush        Flush          Flush         Flush

} elsif ($command =~ /flush/) {

    
    ( -d $dir  ||  $basedir =~ /auto/) or 
	die "Directory $dir does not exist. Exiting.\n";

    # get the file list
    if ($auto) {
      DIR: foreach my $flushdir (<$webdir/*>) {
	  my $flushbase = basename($flushdir);
	  next DIR unless (-d $flushdir);            # is a directory
	  next DIR if $forbiddenDirs{$flushbase}; # isn't forbidden
	  flushDir($flushdir);
	  system("htmllist $flushbase") unless $dir_removed;
	  $dir_removed = 0;
      }

    } else {
	flushDir($dir);
	system("htmllist $basedir") unless $dir_removed;
    }
    


#######################################################################
#       Default        Default          Default         Default

} else {

    die "Command: $command not found.\n$usage\n";

}

system("htmllist $basedir") unless ($dir_removed or $command eq 'flush');

exit 0;
