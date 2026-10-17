#!/usr/bin/env perl
#
#

use strict;
use warnings;
use File::Basename;
#use diagnostics;
#use HTML::LinkExtor;

#use Getopt::Std;

my $exe = basename($0);
my $usage = "\n usage:\n\n$exe [opt] add name category url\n".
    "$exe [opt] (move|mv) name old_category new_category\n".
    "$exe [opt] (rename|ren) name category new_name\n".
    "$exe [opt] (copy|cp) name old_category new_category\n".
    "$exe [opt] (remove|del|rm) name category [category2] ...\n".
    "$exe [opt] (update|up)\n\n";


my ($command, $name, @category) = @ARGV;

die $usage unless ( $command=~/^(update|up)$/ or @category );

my $category = $category[0];
my $new_url = pop @category if $command =~ /add/;

my $delimchar = ";";

my ($old_category, $new_category) = @category 
    if $command =~ /(cp|copy|mv|move)/;

my $new_name = $category[1] if $command =~ /(ren|rename)/;

if ($command =~ /add/) {
    die "Error in add command:\n".$usage unless $new_url;
} elsif ($command =~ /(copy|cp|move|mv)/) {
    die "Error in cp/mv command:\n".$usage unless $new_category;
} elsif ($command =~ /(rename|ren)/) {
    die "Error in rename command:\n".$usage unless $new_name;
} elsif ($command =~ /(remove|del|rm)/) {
    die "Error in rm command:\n".$usage unless $category;
} elsif ($command =~ /(update|up)/) {
    printf STDERR "No arguments required to update ... ignoring $name, ..." if $name;
} else {
    die "Command: $command not found\n".$usage;
}

my ($feedback, $nofeedback) = (1,0);

################################################################
# read in the rc file.

my $rcdir = "$ENV{HOME}/.bookmarks";
my $rcfile = "${rcdir}/bookmarksrc";

my %rcdata;
open (RC, "$rcfile") or die "Could not open rcfile: $rcfile\n";
while (<RC>) {
    next unless $_ =~ /^(PUBLIC_HTML|BACKUP|COLUMNS|SEARCH|FONTSIZE|SORT)/;

    my ($key, $value) = split;
    $value = glob($value)  if $value =~ /\~/;
    $rcdata{$key} = $value;
}
close (RC);


my $dir    = $rcdata{"PUBLIC_HTML"}; #."/bookmarks";
my $bakdir = $rcdata{"BACKUP"};

my $dbfile = "${rcdir}/bookmarks.list";
my $dbbak  = "${bakdir}/bookmarks.list";

my $indexfile = "${dir}/bookmarks.php";
my $indexbak  = "${bakdir}/bookmarks.php";

my $columns = $rcdata{"COLUMNS"};
my $search_columns = $rcdata{"SEARCH_COLUMNS"};

my $fontsize = $rcdata{"FONTSIZE"};

my $alpha_sort = ($rcdata{"SORT"} =~ /^alpha$/) ? 1 : 0;

my %bookmark;



################################################################
# subroutines

sub setPermission {
    chmod 0644, "$indexfile";
    chmod 0644, "$dbfile";
}

sub dbAdd ($$$$) {

    my ($category, $name, $url, $local_feedback) = @_;

    # first, check and make sure the entry doesn't already exist.
    my $replace = 1;
    if ( $bookmark{$category}{$name} ) {
	printf STDERR "name $name already exists. Replace [y/N]? ";
	my $reply = <STDIN>;
	$replace = 0 unless $reply =~ /^[yY]/;
    }
    
    # add the entry 
    if ($replace) {
	$bookmark{"$category"}{"$name"} = $url;
	printf STDOUT "Added entry $name to category: $category\n"
	    if ($local_feedback);
    }
}    

sub dbRm ($$) {
    my ($category, $name) = @_;

    # check to make sure the entry exists
    #  ... and if there's nothing else in the category, remove that too.

    my $found = 0;
    my $url;
    if ( ! $bookmark{"$category"}{"$name"} ) {
	printf STDERR "name $name does not exist in $category\n";
    } else {

	# now delete the entry
	# we'll return the URL we're deleting so that this subroutine can
	#   be used by dbMove().
	$url = $bookmark{"$category"}{"$name"};
	delete( $bookmark{"$category"}{"$name"} );
	printf STDOUT "Entry: $name deleted from category: $category\n";
	unless (keys %{$bookmark{"$category"}} ) {
	    delete( $bookmark{"$category"} );
	    printf "Entry: $name was last entry in category: $category.\n".
		"\tDeleting category: $category\n";
	}
	$found = 1;
    }
    
    return $found ? $url : 0;
}


sub dbMove ($$$) {
    
    my ($name, $old_category, $new_category) = @_;

    # remove the old one and grab the URL from dbRm()
    #   then add it to the new category

    my $url = dbRm($old_category, $name);
    dbAdd($new_category, $name, $url, $feedback) if $url;

    return 0;
}

sub dbCopy ($$$) {
    
    my ($name, $old_category, $new_category) = @_;

    # grab the URL and add it the new category
    my $url = $bookmark{"$old_category"}{"$name"};
    dbAdd ($new_category, $name, $url, $feedback);

    return 0;
}

sub dbRename ($$$) {

    my ($name, $category, $new_name) = @_;

    my $url = dbRm($category,$name);
    dbAdd ($category, $new_name, $url, $feedback) if $url;
    
    return 0;
}

sub max (@) {
    my $max = $_[0];
    foreach my $value (@_) { $max = $value if $value > $max; }
    return $max;
}

######################################################################3
#
#  Main body of code
#
######################################################################

######################################################################
# read in the database file
open (DB, "$dbfile");
while (<DB>) {
    
    next if /^\#/;
    
    my ($category, $name, $url) = split /${delimchar}/, $_;
    die "Error reading database: field missing\n" if ! $url;
    
    dbAdd ($category, $name, $url, $nofeedback);
    
}
close (DB);



############################################################################
# execute the command

if ( $command =~ /^add$/ ) {
    dbAdd($category, $name, $new_url, $feedback);
} elsif ( $command =~ /^(mv|move)$/ ) {
    dbMove($name, $old_category, $new_category);
} elsif ( $command =~ /^(ren|rename)$/ ) {
    dbRename($name, $category, $new_name);
} elsif ( $command =~ /^(cp|copy)$/ ) {
    dbCopy($name, $old_category, $new_category);
} elsif ( $command =~ /^(up|update)$/ ) {
    printf STDOUT "Updating.\n";
} elsif ( $command =~ /^(rm|del|remove)$/ ){
    foreach my $category (@category) {
	dbRm($category, $name);
    }
}

	
#############################################################################  
# write the new database file

# make a backup of the database file
my $date = `date +%m%d%y_%H%M%S`;
my $prettydate = `date`;
system("cp $dbfile ${dbfile}_${date}");

open (DB, ">$dbfile");
foreach my $category ( sort keys %bookmark ) {
    foreach my $name ( sort keys %{$bookmark{"$category"}} ) {
	my $url = $bookmark{"$category"}{"$name"};
	chomp $url;
	printf DB "${category}${delimchar}${name}${delimchar}${url}\n";
    }
}
close (DB);

system("cp $dbfile $dbbak");



############################################################################
# write the HTML page

# use a subroutine to make the HTML search FORMs
sub webSearch ($$$$) {

    my ($name, $url, $search_dir, $var_name) = @_;

    # this creates a label that has width 8 chars
    my $len = 8;
    my $diff = $len - length($name);
    my $namePad;
    $namePad = $name." "x(1.5*$diff) if $diff >= 0;
    ( ($namePad) = $name =~ /^(\w{8})/ ) if $diff < 0;
    
    return 
	"<!-- Search $name -->\n".
	"        <center>\n".
	"        <FORM method=GET action=\"http://${url}/${search_dir}\">\n".
	"        <TABLE bgcolor=\"#FFFFFF\"><tr><td>\n".
	"        <A HREF=\"http://${url}/\">\n".
	"        <IMG SRC=\"http://${url}/favicon.ico\" border=\"0\" ALT=\"${name}\" align=\"absmiddle\"></A>\n".
	"        <INPUT TYPE=text name=${var_name} size=25 maxlength=255 value=\"\">\n".
	"        <INPUT type=submit name=btnG VALUE=\"${namePad}\">\n".
	"        </td></tr></TABLE>\n".
	"        </FORM>\n".
	"        </center>\n".
	"<!-- Search $name -->\n";    
}


# put the various FORMs into a hash (call the above routine)
my %search;

#    "        <IMG SRC=\"http://www.google.com/logos/Logo_40wht.gif\" border=\"0\" ALT=\"Google\" align=\"absmiddle\"></A>\n".
$search{"google"}   = webSearch("google", "www.google.com", "search", "q");
$search{"cpan"}     = webSearch("cpan", "search.cpan.org", "search", "q");
$search{"chapters"} = webSearch("chapters", "www.chapters.indigo.ca", 
				"books/search", "keywords");
$search{"imdb"}     = webSearch("imdb", "www.imdb.com", "find", "q");



my $html_string = "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n".
  "<HTML>\n".
  "<HEAD>\n".
  "<TITLE> Bookmarks </title>\n".
  "<link rel=\"stylesheet\" type=\"text/css\" title=\"Green\" href=\"style.css\" />\n".
  "</HEAD>\n".
  "<BODY>\n".
  "\n".

  # Title
  "<div id=\"header\">\n".
  "<div id=\"header_inner\" class=\"fluid\">\n".
  "  <?php include(\"h1h2.php\"); ?>\n".
  "</div>\n".
  "</div>\n".


  "<div id=\"main\">\n".
  "<div id=\"main_inner\" class=\"fluid\">\n".
  "<div id=\"primaryContent_columnless\">\n".
  "<div id=\"columnA_columnless\">\n".
 
  # link back to homepage
  "<DIV ALIGN=\"center\">\n".
  "<A HREF=\"index.php\">Back to homepage</A>\n".
  "</DIV>\n".
  "\n";


# include the search FORMs in a table
my @search_cats = sort keys %search;
$html_string .= sprintf "<TABLE ALIGN=\"center\" border=0 width=\"100%%\">\n";
my $i = 0;
foreach my $search_cat (@search_cats) {
    next unless $rcdata{"SEARCH_".$search_cat};
    $html_string .= sprintf "<TR ALIGN=\"center\"\n" unless $i % $search_columns;
    $html_string .= sprintf "<TH $search{$search_cat}";
    $i++;
}
$html_string .= sprintf "</TABLE>\n";


$html_string .= "</div>\n".
  "<br class=\"clear\"/>\n".
  "<div id=\"columnA_columnless\">\n";


# put together the tables of links
$html_string .= sprintf "<TABLE ALIGN=\"center\" border=0 width=\"100%%\">\n";

# handle the sorting of the categories
my @sortlist;
foreach my $key (keys %bookmark) {
    push @sortlist, [$key, scalar (keys %{$bookmark{$key}}) ];
}
my @categories = ($alpha_sort) ? 
		 map {$_->[0]} sort {$a->[0] cmp $b->[0]} @sortlist :
		 map {$_->[0]} sort {$b->[1] <=> $a->[1]} @sortlist ;


for ( 0 .. @categories/$columns ) {


    # print the category titles
    $html_string .= sprintf "<TR ALIGN=\"center\"\n";
    my @cat;
    foreach my $col (0 .. $columns-1) {
	$cat[$col] = (@categories) ? shift @categories : "";
	$html_string .= sprintf "<TH><FONT SIZE=\"+1\"> $cat[$col] </FONT>\n";
    }
    $html_string .= sprintf "<FONT SIZE=\"-3\">\n\n";

    # get the names in each category
    my @names;
    my @Nnames;
    foreach my $col (0 .. $columns-1) {
	@{$names[$col]} = 
	    $cat[$col] ? ( sort {lc($a) cmp lc($b)} 
			   keys %{$bookmark{"$cat[$col]"}} ) : ();
	push @Nnames, scalar @{$names[$col]};
    }
    
    my $max_i = max( @Nnames );


    # print the links from each category
    foreach my $i (0 .. $max_i) {

	$html_string .= sprintf "<TR ALIGN=\"center\">\n";
	    
	foreach my $col (0 .. $columns-1) {
	    my $cat = $cat[$col];
	    my $name = ${$names[$col]}[$i] ? ${$names[$col]}[$i] : "";
	    my $url = $name ? $bookmark{"$cat"}{"$name"} : "";
	    chomp $url;
	    my $url_tmp = ($url =~ /^(ftp|http):/) ? $url : "http://".$url;
	    $html_string .= sprintf "<TH><FONT SIZE=\"$fontsize\"> <A HREF=\"${url_tmp}\"> $name </A> </FONT>\n";
	}

	$html_string .= sprintf "\n";
	
    }
 
    $html_string .= sprintf "<BR><BR>\n";

}

$html_string .= sprintf "</FONT>\n".
  "</TABLE>\n".
  "</div>\n".
  "<br class=\"clear\"/>\n".
  "</div>\n".
  "</div>\n".
  "</div>\n".
  "\n";


$html_string .= "<div align=\"center\">\n".
  "<a href=\"index.php\">Back to homepage</a>\n".
  "</div>\n".
  "<address id=\"footer\" class=\"fluid\">\n".
  "Copyright &copy; 2008. All rights reserved. <br/>\n".
  "Modified: $prettydate by S. Bickerton <br/>\n".
  "Design by <a href=\"http://www.nodethirtythree.com/\">NodeThirtyThree Design</a>.\n".
  "</address>\n".
  "</BODY>\n".
  "<?php include(\"sitelog.php\") ?>\n".
  "</HTML>\n";


open (INDEX, ">$indexfile");
#my $fh = *STDOUT;
my $fh = *INDEX;
printf $fh "%s", $html_string;
close ($fh);

system ("cp $indexfile $indexbak");

setPermission();

exit 0;
