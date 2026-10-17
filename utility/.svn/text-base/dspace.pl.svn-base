#!/usr/bin/env perl
#
#

use warnings;
use strict;

my $interactive = 0;
foreach my $file (@ARGV) {

    my $newfile = $file;
    for ($newfile) {
	s/\ /_/g;  #space -> underscore
	s/\,/./g;  #comma -> period
	s/[\~\!\@\#\$\%\^\&\*\(\)\;\:\"\'\\\/\`\<\>]//g; # remove special char
    }

    # die the there's nothing left of the filename
    die "Removing special chars leaves zero length filename ... exiting\n"
	if ( length($newfile)==0 );
    
    # die if the file already exists
    if ($interactive && -f $newfile) {
	printf "File $newfile already exists. Delete (y/N)? ";
	my $reply = <STDIN>;
	die "Exiting\n" unless ($reply eq 'y' || $reply eq 'Y');
    }

    # rename it
    printf STDOUT 'Renaming %s %s %s', $file, $newfile, "\n";
    rename $file, $newfile;
}

exit 0;
