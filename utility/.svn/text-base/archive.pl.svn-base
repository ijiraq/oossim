#!/usr/bin/env perl
#
# program archive.pl  -  written to archive scripts so i can find old code 
#     when i need to ... if i remmember to run this
#
# Steve Bickerton  Fri, Sept 30, 2005
#

use strict;
use warnings;


my @files = @ARGV;
die "Usage: $0 file1 file2 ...\n" if ! $files[0];

my $archive_dir = "$ENV{HOME}/archive";

FILE: foreach my $file (@files) {
    
    # find out what kind of file it is
    my $filetype;
    $filetype = "perl" if ($file=~/.*\.pl$/);
    $filetype = "bash" if ($file=~/.*\.bash$/  || $file=~/.*\.sh$/ );
    $filetype = "python" if ($file=~/.*\.py$/);
    $filetype = "gnuplot" if ($file=~/.*\.gpt$/);
    
    if (! $filetype ) {
	printf STDERR "Can't identify filetype ... exiting (nothing copied)\n";
	next FILE;
    }
    
    
    # make a header for the file with info about it.
    my $cwd = `pwd`;
    chomp $cwd;
    my $date = `date`;
    chomp $date;

    my $shebang = "#!/usr/bin/env $filetype";
    
    my $message = "$shebang\n".
	"#\n".
	"# ARCHIVE INFORMATION\n".
	"# original file: ${cwd}/${file}\n".
	"# date:          $date\n".
	"# \n";
    
    
    #  tag the archive file with the date and time
    my $newfile = "${archive_dir}/${filetype}/${file}_".`date +%F_%R`;
    
    # dump the header to file
    open (NEWFILE, ">$newfile");
    printf NEWFILE "$message";
    close (NEWFILE);
    
    # copy over the rest of the file (cat it onto the header)
    my $command = "cat $file >> $newfile";
    system ($command);
    printf STDOUT "$command\n";
    
}
