#!/usr/bin/env perl 
#
#

use strict;
use warnings;

my $BIN_DIR = "$ENV{HOME}/bin";
my $SRC_DIR = "$BIN_DIR/src";

foreach my $execfile (@ARGV) {

    my ($fileroot,$extension) = $execfile =~ m/(\w+)\.(pl|c|py)/;
    if ( -f "$SRC_DIR/$execfile" && -f "$BIN_DIR/$fileroot" ) {  
	print "About to delete\t\t$SRC_DIR/$execfile\n ... and symlink\t$BIN_DIR/$fileroot.\nContinue? ";
	my $reply = getc STDIN;
	if ($reply eq 'y' || $reply eq 'Y') {
	    system "rm $SRC_DIR/$execfile $BIN_DIR/$fileroot" ;
	    print "Deleted\t\t$SRC_DIR/$execfile\n and symlink\t$BIN_DIR/$fileroot\n";
	} else {
	    print "Delete cancelled.\n\n";
	}
    } else {
	print "Can't help you today ...\n";
	print "File $execfile does not exist in $SRC_DIR ...\n\n" if ( ! -f "$SRC_DIR/$execfile") ;
	print "File $fileroot does not exist in $BIN_DIR ...\n\n" if ( ! -f "$BIN_DIR/$fileroot") ;
    }

}
