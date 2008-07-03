#!/usr/bin/perl -w

# Compile testing for JSAN::Librarian

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( catdir( updir(), updir(), 'modules') );
	}
}

use Test::More tests => 14;
use URI             ();
use Config::Tiny    ();
use JSAN::Librarian ();
use JavaScript::Librarian ();

# Set paths
my $lib_path      = 't.data';
my $default_index = catfile( 't.data', '.openjsan.deps' );

# Build the example copnfig to compare things to
my $Expected = Config::Tiny->new;
$Expected->{'Foo.js'} = {};
$Expected->{'Bar.js'} = { 'Foo.js' => 1 };
$Expected->{catfile('Foo', 'Bar.js')} = { 'Foo.js' => 1, 'Bar.js' => 1 };





#####################################################################
# JSAN::Librarian Tests

# Check paths and remove as needed
ok( -d $lib_path, 'Lib directory exists' );
unlink $default_index if -e $default_index;
END {
	unlink $default_index if -e $default_index;
}
	
# Build first to check the scanning logic
my $Config = JSAN::Librarian->build_index( $lib_path );
isa_ok( $Config, 'Config::Tiny' );
is_deeply( $Config, $Expected,
	'->build_index returns Config::Tiny that matches expected' );

# Check that make_index writes as expected
ok( JSAN::Librarian->make_index( $lib_path ), '->make_index returns true' );
ok( -e $default_index, '->make_index created index file' );
$Config = Config::Tiny->read( $default_index );
isa_ok( $Config, 'Config::Tiny' );
is_deeply( $Config, $Expected,
	'->make_index returns Config::Tiny that matches expected' );





#####################################################################
# JSAN::Librarian::Library Tests

# Create the Library
my $Library = JSAN::Librarian::Library->new( $Config );
isa_ok( $Library, 'JSAN::Librarian::Library' );
ok( $Library->load, 'Library loads ok' );

# Fetch a Book
my $Book = $Library->item('Foo.js');
isa_ok( $Book, 'JSAN::Librarian::Book' );





#####################################################################
# Full test of JavaScript::Librarian

my $uri = URI->new( '/jsan' );
my $Librarian = JavaScript::Librarian->new(
	base    => $uri,
	library => $Library,
	);
isa_ok( $Librarian, 'JavaScript::Librarian' );

# Generate script tags for something
ok( $Librarian->add( 'Foo/Bar.js' ), '->add(Foo/Bar.js) returned true' );
my $script = $Librarian->html;
ok( defined $script, '->html returns defined' );
is( $script . "\n", <<'END_HTML', '->html returns expected' );
<script language="JavaScript" src="/jsan/Foo.js" type="text/javascript"></script>
<script language="JavaScript" src="/jsan/Bar.js" type="text/javascript"></script>
<script language="JavaScript" src="/jsan/Foo/Bar.js" type="text/javascript"></script>
END_HTML

exit(0);
