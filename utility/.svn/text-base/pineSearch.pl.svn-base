#!/usr/bin/env perl
#
# original filename: pineSearch.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Tue Apr 15, 2008  14:25:10 DST
#  Host: bender.astro.princeton.edu
#  Working Directory: /Users/bick/sandbox/utility
#


use strict;
use warnings;
use File::Basename;

my $exe = basename($0);
my $usage = "Usage: $exe -l(long) -nN regex folder1 folder2\n";

my @args = ();
my $N = 1;
my $long = 0;
foreach my $arg (@ARGV) {
  if ($arg=~/^-n\d+$/) {
    ($N) = $arg=~/^-n(\d+)/;
  } elsif ($arg=~/^-l$/) {
    $long = 1;
  } else {
    push @args, $arg;
  }
}

my ($regex_str, @folders) = @args;
die $usage unless $regex_str;

# compile the regex
my ($regex) = map { qr/$_/ } ($regex_str);

# allow maildir to be defined by an envir var.
my $maildir;
if ( defined($ENV{MAILDIR}) ) {
	$maildir = $ENV{MAILDIR};
} else {
	$maildir = "$ENV{HOME}/mail";
}


# use only folders provided, if none then use all in the dir
if (@folders) {
  @folders = map { "${maildir}/".$_ } @folders;
} else {
  @folders = glob("${maildir}/*");
  @folders = grep {$_ !~ /${maildir}\/bak/} @folders;
}


# make the pattern to split in messages
my $wday = '(Sun|Mon|Tue|Wed|Thu|Fri|Sat)';
my $mon = '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)';
my $time = '\d?\d:\d\d:\d\d';
my $year = '[12]\d\d\d';
my $pattern_str = "From\\s+(\\w+\\@(\\w+\\.)+\\w{2,3}|MAILER-DAEMON)\\s+$wday\\s+$mon\\s+\\d{1,2} $time $year\\s*";
my ($pattern) = map { qr/$_/ } ($pattern_str);
my $tmppatt = 'XXSPLITXX';

foreach my $folder (@folders) {
  
  #read in the messages in the folder
  my $all_messages = "";
  open(FOLDER, "$folder");
  while (<FOLDER>) {$all_messages .= $_;}
  close(FOLDER);

  # split the messages
  $all_messages =~ s/$pattern/\n${tmppatt}\n/g;
  my @messages = split /${tmppatt}/, $all_messages;

  # loop over each message
  foreach my $message (@messages) {

    # --search for the pattern line by line
    my @matches = ();
    my %head;
    foreach my $line ( reverse split /\n/, $message ) {
      if ( my ($key,$value) = $line =~ /^(\w+): (.*)$/) {
	$head{$key} = $value;
      }
      push @matches, $line if ($line=~/$regex/);
    }
    next unless (scalar @matches > 0);

    # -- output a summary of the match
    next unless ( defined($head{Date}) && 
		  defined($head{From}) && 
		  defined($head{Subject}) );
    chomp($head{Date});
    chomp($head{From});
    chomp($head{Subject});

    my $N_total = scalar @matches;

    # have both a verbose (long) format and a short one
    if ($long) {

      printf STDOUT "\e[33;1m--------- %s ----------\e[0m\n", basename($folder);
      printf STDOUT "Date: \e[32;1m$head{Date}\e[0m\n";
      printf STDOUT "From: \e[31;1m$head{From}\e[0m\n";
      printf STDOUT "Subject: \e[36;1m$head{Subject}\e[0m\n";
      my $Nmin = ($N_total < $N) ? ($N_total) : $N;
      printf STDOUT "$N_total matches - showing %s\n", $Nmin;
      foreach my $i (0 .. $Nmin-1) {
	chomp($matches[$i]);
	$matches[$i] =~ s/$regex/\e[35;1m$&\e[0m/g;
	printf STDOUT "  %d %74s\n", $i+1, substr($matches[$i],0,73);
      }

    } else {

      my ($wday, $cday, $mon, $yr, $time, $tzone) = split /\s+/, $head{Date};
      my ($from) = $head{From} =~ /(\w+\@(\w+\.)+\w{2,3})/;
      $from = substr($from,0,20);
      my $outline = sprintf "%-8s %3s %2d %4d %2d %-20s".
	"", basename($folder).":", $mon, $cday, $yr, $N_total, $from;
      my $space_left = 74 - length($outline);
      my $subj = substr($head{Subject}, 0, $space_left);
      printf STDOUT "$outline $subj\n";

    }

  }

}

exit 0;
