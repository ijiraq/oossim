#!/usr/bin/env perl
#
#

use strict;
use warnings;
use File::Basename;

my $BIN_DIR = "$ENV{HOME}/bin";
my $SRC_DIR = "$BIN_DIR/src";

foreach my $execfile (@ARGV) {

    my @extensions = ("\.pl","\.py","\.bash","\.csh","\.ksh");
    my ($basename,$path,$suffix) = fileparse $execfile, @extensions;
    my $filename = "$basename$suffix";

    #print "$basename\t$path\t$suffix\t$filename\n";


    if ( $suffix ) {    

	if ( (! -e "$BIN_DIR/$basename") || (! -e "$SRC_DIR/$filename") ) { 

	    system "cp $execfile $SRC_DIR/$filename";
	    chmod 0744, "$SRC_DIR/$filename";
	    print "Copied $execfile to $SRC_DIR/$filename\n";

	    symlink "$SRC_DIR/$filename","$BIN_DIR/$basename";
	    print "Created symlink $BIN_DIR/$basename\n";

	} else {
	    print "File $BIN_DIR/$basename or $SRC_DIR/$filename already exists ... overwrite [y/N]: ";
	    my $reply = getc STDIN;

	    if ( $reply =~ m/(y|Y)/ ) {

		unlink ("$BIN_DIR/$basename", "$SRC_DIR/$filename");

		print "$BIN_DIR/$basename $SRC_DIR/$filename\n";
		if ( -e "$BIN_DIR/$basename" || -e "$SRC_DIR/$filename") {

		    print "Could not delete files\n";  

		    exit 0;
		}

		system "cp $execfile $SRC_DIR/$filename\n";
		chmod 0744, "$SRC_DIR/$filename";
		print "Copied $execfile to $SRC_DIR/$filename\n";
		
		symlink "$SRC_DIR/$filename","$BIN_DIR/$basename";
		print "Created symlink $BIN_DIR/$basename\n";
		
	    } else {
		print "Copy and Linking cancelled.\n";
	    }
	}
    } else {
	print "Don't know what kind of file it is ...\n";
    }
    
}
