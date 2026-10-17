#!/usr/bin/env perl
#
# original filename: from.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Mon Oct 30, 2006  15:39:38 EST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/pack_main/sandbox/utility
#


use strict;
use warnings;
use File::Basename;

my $exe = basename($0);
my $usage = "Usage: $exe\n";

my $outfile = "$ENV{HOME}/.from";

#my ($x) = @ARGV;
#die $usage unless $x;

my @headers;
my $in_header = 0;
my @lines = <STDIN>;
my $i = 0;
my ($from, $subject);
my $firstline = 1;
foreach my $line (@lines) {

    # only twig on header values (could be in body if replied-to)
    $in_header = 1 if $line=~/Return-Path: /;
    $in_header = 0 if ($line=~/X-Spam/);
    next unless $in_header;

    # get the from line and subject
    chomp $line;
    $from = sprintf ("%-75s", $line) if ($line=~/From: /);
    $subject = sprintf ("%-75s", $line) if ($line=~/Subject: /);

    # if we're starting a new message, store the values from the last one
    if ( $line=~/Return-Path: / and ! $firstline) {
	$headers[$i] = [$from, $subject];
	$i++;
    }
    $firstline = 0 if $line=~/Return-Path: /;
}
# stash the last message we read (we missed it because there wasn't a message
# following it with 'return-path' to cause a recording.
$headers[$i] = [$from, $subject];


# print out our messages.
open (my $fh, ">>$outfile");
foreach my $header (@headers) {

    my ($from, $subject) = @$header;
    printf $fh "  %75s\n".
	"  %75s\n",
	($from    ? $from    : "No From Address"),
	($subject ? $subject : "No Subject Line");
}
close ($fh);

exit 0;
