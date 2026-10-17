#!/usr/bin/env perl
# Perl Module:  Debug.pm
#
# Purpose: a Perl module  containing a subroutine to summarize the values 
#          of the given variable in a printf statement.
# Author: Steve Bickerton, McMaster University
#         bick@physics.mcmaster.ca
#         Thurs. Sep. 22, 2005
# Functions:   elong2v and its inverse v2elong
#
#

package  Local::Debug;

use strict;
use warnings;
use Term::ReadKey;
use Carp;

use Local::Astrotools;

require  Exporter;

our @ISA       = qw( Exporter );
our @EXPORT    = qw( ldb cdb $ldbw $ldbd $limit );
our @EXPORT_OK = qw();
our @EXPORT_TAGS = ( ALL => [ @EXPORT_OK ], );
our $VERSION   = 1.00;


my $i = 0;
my ($wchar, $hchar, $wpixels, $hpixels) = GetTerminalSize();
my $hbuf = 5;  # number to subtract from $hchar for modulus test statement
               # the header line will be printed every $hchar-$hbuf lines;

our $ldbw = 16;
our $ldbd = 8;
our $limit = 1e5;

my $number = '[+-]?\d+\.?\d*';
my $hms = '[+-]?\d\d:\d\d:\d\d\.?\d*';

sub ldb ($) {
    
    my ($s) = @_;

    my $ldbformF = "%${ldbw}.${ldbd}f  ";
    my $ldbformE = "%${ldbw}.${ldbd}e  ";
    my $ldbws = $ldbw - 2;
    my $ldbsform1 = "#\n# %${ldbws}s  ";
    my $ldbsform2 = "%${ldbw}s  ";
   
    # separate the names and values
    my @lines = split /\n/, $s;
    my %values;
    foreach my $line (@lines) {
	my ($var, $val) = split /=/, $line;
	$var =~  s/\s+//g;
	for ($val) {
	    s/\s+//g;
	    s/;$//;
	    s/\'//g;
	}
	$values{"$var"} = $val;
    }

    # we want a least one header per screen;
    if ($i % ($hchar-$hbuf)) {
	foreach my $variable (sort keys %values) {
	    my $value = $values{$variable};

	    my $ldbform;
	    if ( $value =~ /^$number$/  && $value>$limit ) {
		$ldbform = $ldbformE;
	    } elsif ( $value =~ /^$number$/ && $value<$limit ) {
		$ldbform = $ldbformF;
	    } else {
		$ldbform = $ldbsform2;
	    }
	    printf STDERR "$ldbform", $value;
	}

    } else {
	my @variables = sort keys %values;
	printf STDERR "$ldbsform1", shift @variables;
	foreach my $variable (@variables) {
	    printf STDERR "$ldbsform2", $variable;
	}
	printf STDERR "\n#\n";
	foreach my $variable (sort keys %values) {
	    my $value = $values{$variable};
	    my $ldbform;
	    if ( $value =~ /^$number$/  && $value>$limit ) {
		$ldbform = $ldbformE;
	    } elsif ( $value =~ /^$number$/ && $value<$limit ) {
		$ldbform = $ldbformF;
	    } else {
		$ldbform = $ldbsform2;
	    }
	    printf STDERR "$ldbform", $value;
	}
    }

    printf "\n";
    $i++;
	    
    return 1;
}


sub cdb ($) {
    
    my ($s) = @_;

    my $ldbformF = "%${ldbw}.${ldbd}f  ";
    my $ldbformE = "%${ldbw}.${ldbd}e  ";
    my $ldbsform = "%${ldbw}s  ";

    # separate the names and values
    my @lines = split /\n/, $s;
    my %values;
    foreach my $line (@lines) {
	my ($var, $val) = split /=/, $line;
	$var =~  s/\s+//g;
	for ($val) {
	    s/\s+//g;
	    s/;$//;
	    s/\'//g;
	}
	$values{"$var"} = $val;
    }

    my @variables = sort keys %values;

    my $len1 = length $variables[0];
    my $len2 = length $variables[1];
    my $ldbw2 = 2*$ldbw;
    my $ldbsform1 = "%${len1}s";
    my $ldbsform2 = "%${len2}s";
    my $label = sprintf "$ldbsform1 / $ldbsform2", @variables[0,1];
    printf STDERR "%-${ldbw2}s  ", $label;

    my ($Nhms, $Nnum) = (0,0);
    foreach my $variable (sort keys %values) {

	my $value = $values{"$variable"};
	#printf "value: $value\n";
	my $ldbform;

	if ( $value =~ /^$number$/  && $value>$limit ) {
	    $ldbform = $ldbformE;
	    $Nnum++;
	} elsif ( $value =~ /^$number$/ && $value<$limit ) {
	    $ldbform = $ldbformF;
	    $Nnum++;
	} elsif ( $value !~ /^$number$/  &&  $value =~ /^$hms$/ ) {
	    $ldbform = $ldbsform;
	    $values{"$variable"."D"} = hms2degS($value);
	    $Nhms++;
	} else {
	    $ldbform = $ldbsform;
	}
	printf STDERR "$ldbform", $value;

    }


    my $ldbform = "%${ldbw}s";
    my $diff;
    if ( $Nnum == 2  && $Nhms == 0 ) {
	$diff = $values{"$variables[0]"} - $values{"$variables[1]"}; 
	$ldbform = $ldbformF
    } elsif ( $Nnum == 0  && $Nhms == 2 ) {
	$diff = $values{"$variables[0]"."D"} - $values{"$variables[1]"."D"}; 
	$diff = deg2hmsS($diff);
	$ldbform = $ldbsform;
    } else {
	$diff = "N/A";
	$ldbform = $ldbsform;
    }
    
    printf STDERR "$ldbform", $diff;

    printf "\n";
    $i++;
	    
    return 1;
}


