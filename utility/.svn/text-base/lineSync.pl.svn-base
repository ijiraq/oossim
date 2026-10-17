#!/usr/bin/env perl
#
#
use strict;
use warnings;

my @cmds = @ARGV;

die "Usage: $0 \"=text\" \"cmd1\" \"cmd2\" ...\n" if ( ! $cmds[0] );

my @outputs;
my @texts;
my @longest_outputs = (0)x@cmds;
my $i = 0;
my $most_lines = 0;
foreach my $cmd ( @cmds ) {

    my $text = "";
    my $output = "";
    if ($cmd =~ /^=/ ) {
	push @{$outputs[$i]}, $cmd;
	$i++;
    } elsif ($cmd =~ /^sleep/) {
	system("$cmd");
    } else {
	$output = `$cmd`  or die "${cmd}: command not found\n";
	push @{$outputs[$i]}, (split /\n/,$output);

	# keep track of the maximum no. of lines of output needed
	$most_lines = ( $#{$outputs[$i]} > $most_lines ) ? 
	    ($#{$outputs[$i]}) : $most_lines;
	
	# for each command, get the length of the longest output line
	foreach my $out ( @{$outputs[$i]} ) {
	    my $len = length($out);
	    $longest_outputs[$i] = ( $len > $longest_outputs[$i] ) ? 
		$len : $longest_outputs[$i];
	}
	$i++;
    }
}

foreach my $j (0 .. $most_lines) {
    foreach my $k (0 .. $#outputs) {

	# if it's just text, output the string stored in the 0'th array element
	my $tmp = ${ $outputs[$k] }[$j];
	if ( ${ $outputs[$k] }[0] =~ /^=/  ) {
	    ( $tmp ) = ${ $outputs[$k]}[0] =~ /^=(.*)/;
	}
	printf STDOUT "%-${longest_outputs[$k]}s\t", ( $tmp ) ? $tmp : "NULL";
    }
    printf STDOUT "\n";
}
exit 0;
