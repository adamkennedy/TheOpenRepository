#!/usr/bin/perl

# Basic first pass API testing for Archive::Builder::Fill

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

# Load the API to test
use Archive::Builder ();

# Execute the tests
use Test::More tests => 72;
use Test::ClassAPI;

# Ignore imported functions
$Test::ClassAPI::IGNORE{refaddr} = 1;

# Execute the tests
Test::ClassAPI->execute('complete', 'collisions');

__DATA__

Archive::Builder=class
Archive::Builder::Section=class
Archive::Builder::File=class
Archive::Builder::Generators=class
Archive::Builder::Archive=class

[Archive::Builder]
new=method
test=method
save=method
delete=method
reset=method
archive=method
add_section=method
new_section=method
new_sections=method
sections=method
section_list=method
section=method
remove_section=method
file_count=method
files=method
errstr=method

[Archive::Builder::Section]
new=method
name=method
path=method
test=method
save=method
Builder=method
delete=method
reset=method
archive=method
add_file=method
new_file=method
files=method
file_list=method
file=method
remove_file=method
file_count=method
errstr=method

[Archive::Builder::File]
new=method
path=method
generator=method
arguments=method
save=method
binary=method
executable=method
Section=method
delete=method
reset=method
contents=method
errstr=method

[Archive::Builder::Generators]
string=method
file=method
handle=method
template=method

[Archive::Builder::Archive]
types=method
new=method
type=method
files=method
sorted_files=method
generate=method
save=method
errstr=method
