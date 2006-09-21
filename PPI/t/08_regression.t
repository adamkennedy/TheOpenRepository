#!/usr/bin/perl -w

# code/dump-style regression tests for known lexing problems.

# Some other regressions tests are included here for simplicity.

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::XS_DISABLE = 1; # Prevent warning
}
use PPI::Lexer;
use PPI::Dumper;
use Params::Util '_INSTANCE';

sub pause {
	local $@;
	eval { require Time::HiRes; };
	$@ ? sleep(1) : Time::HiRes::sleep(0.1);
}





#####################################################################
# Prepare

# For each new item in t/data/08_regression add another 11 tests

use Test::More tests => 268;
use Test::Object;
use t::lib::PPI;

use vars qw{$testdir};
BEGIN {
	$testdir = catdir( 't', 'data', '08_regression' );
}

# Does the test directory exist?
ok( (-e $testdir and -d $testdir and -r $testdir), "Test directory $testdir found" );

# Find the .code test files
opendir( TESTDIR, $testdir ) or die "opendir: $!";
my @code = map { catfile( $testdir, $_ ) } sort grep { /\.code$/ } readdir(TESTDIR);
closedir( TESTDIR ) or die "closedir: $!";
ok( scalar @code, 'Found at least one code file' );





#####################################################################
# Code/Dump Testing

my $Lexer = PPI::Lexer->new;
foreach my $codefile ( @code ) {
	# Does the .code file have a matching .dump file
	my $dumpfile = $codefile;
	$dumpfile =~ s/\.code$/\.dump/;
	my $codename = $codefile;
	$codename =~ s/\.code$//;
	ok( (-f $dumpfile and -r $dumpfile), "$codename: Found matching .dump file" );

	# Create the lexer and get the Document object
	my $Document = $Lexer->lex_file( $codefile );
	ok( $Document, "$codename: Lexer->Document returns true" );
	ok( _INSTANCE($Document, 'PPI::Document'), "$codename: Object isa PPI::Document" );

	my $rv;
	SKIP: {
		skip "No Document to test", 7 unless $Document;

		# Check standard things
		object_ok( $Document );

		# Get the dump array ref for the Document object
		my $Dumper = PPI::Dumper->new( $Document );
		ok( _INSTANCE($Dumper, 'PPI::Dumper'), "$codename: Object isa PPI::Dumper" );
		my @dump_list = $Dumper->list;
		ok( scalar @dump_list, "$codename: Got dump content from dumper" );
	
		# Try to get the .dump file array
		open( DUMP, $dumpfile ) or die "open: $!";
		my @content = <DUMP>;
		close( DUMP ) or die "close: $!";
		chomp @content;
	
		# Compare the two
		is_deeply( \@dump_list, \@content, "$codename: Generated dump matches stored dump" );
	
		# Also, do a round-trip check
		$rv = open( CODEFILE, '<', $codefile );
		ok( $rv, "$codename: Opened file" );
	}
	SKIP: {
		unless ( $Document and $rv ) {
			skip "Missing file", 1;
		}
		my $source = do { local $/ = undef; <CODEFILE> };
		$source =~ s/(?:\015{1,2}\012|\015|\012)/\n/g;

		is( $Document->serialize, $source, "$codename: Round-trip back to source was ok" );
	}
}





#####################################################################
# Regression Test for rt.cpan.org #11522

# Check that objects created in a foreach don't leak circulars.
is( scalar(keys(%PPI::Element::_PARENT)), 0, 'No parent links initially' );
foreach ( 1 .. 3 ) {
	pause();
	is( scalar(keys(%PPI::Element::_PARENT)), 0, 'No parent links at start of loop time' );
	my $Document = PPI::Document->new(\q[print "Foo!"]);
	is( scalar(keys(%PPI::Element::_PARENT)), 4, 'Correct number of keys created' );
}





#####################################################################
# A number of things picked up during exhaustive testing I want to 
# watch for regressions on

# Create a document with a complete braced regexp
SCOPE: {
my $Document = PPI::Document->new( \"s {foo} <bar>i" );
isa_ok( $Document, 'PPI::Document' );
my $stmt   = $Document->first_element;
isa_ok( $stmt, 'PPI::Statement' );
my $regexp = $stmt->first_element;
isa_ok( $regexp, 'PPI::Token::Regexp::Substitute' );

# Check the regexp matches what we would expect (specifically
# the fine details about the sections.
my $expected = bless {
	_sections => 2,
	braced    => 1,
	content   => 's {foo} <bar>i',
	modifiers => { i => 1 },
	operator  => 's',
	sections  => [ {
		position => 3,
		size     => 3,
		type     => '{}',
	}, {
		position => 9,
		size     => 3,
		type     => '<>',
	} ],
	seperator => undef,
	};
is_deeply( { %$regexp }, $expected, 'Complex regexp matches expected' );
}

# Also test the handling of a screwed up single part multi-regexp
SCOPE: {
my $Document = PPI::Document->new( \"s {foo}_" );
isa_ok( $Document, 'PPI::Document' );
my $stmt   = $Document->first_element;
isa_ok( $stmt, 'PPI::Statement' );
my $regexp = $stmt->first_element;
isa_ok( $regexp, 'PPI::Token::Regexp::Substitute' );

# Check the internal details as before
my $expected = bless {
	_sections => 2,
	_error    => "No second section of regexp, or does not start with a balanced character",
	braced    => 1,
	content   => 's {foo}',
	modifiers => {},
	operator  => 's',
	sections  => [ {
		position => 3,
		size     => 3,
		type     => '{}',
	}, {
		position => 7,
		size     => 0,
		type     => '',
	} ],
	seperator => undef,
	};
is_deeply( { %$regexp }, $expected, 'Badly short regexp matches expected' );
}

# Encode an assumption that the value of a zero-length substr one char
# after the end of the string returns ''. This assuption is used to make
# the decision on the sections->[1]->{position} value being one char after
# the end of the current string
is( substr('foo', 3, 0), '', 'substr one char after string end returns ""' );

# rt.cpan.org: Ticket #16671 $_ is not localized 
# Apparently I DID fix the localisation during parsing, but I forgot to 
# localise in PPI::Node::DESTROY (ack).
$_ = 1234;
is( $_, 1234, 'Set $_ to 1234' );
SCOPE: {
	my $Document = PPI::Document->new( \"print 'Hello World';");
	isa_ok( $Document, 'PPI::Document' );
}
is( $_, 1234, 'Remains after document creation and destruction' );





#####################################################################
# Bug 16815: location of Structure::List is not defined.

SCOPE: {
	my $code = '@foo = (1,2)';
	my $doc = PPI::Document->new(\$code);
	isa_ok( $doc, 'PPI::Document' );
	ok( $doc->find_first('Structure::List')->location, '->location for a ::List returns true' );
}





#####################################################################
# Bug 18413: PPI::Node prune() implementation broken

SCOPE: {
	my $doc = PPI::Document->new( \<<'END_PERL' );
#!/usr/bin/perl

use warnings;

sub one { 1 }
sub two { 2 }
sub three { 3 }

print one;
print "\n";
print three;
print "\n";

exit;
END_PERL
	isa_ok( $doc, 'PPI::Document' );
	ok( defined $doc->prune('PPI::Statement::Sub'), '->prune ok' );
}





#####################################################################
# Bug 19883: 'package' bareword used as hash key is detected as package statement

SCOPE: {
	my $doc = PPI::Document->new( \'(package => 123)' );
	isa_ok( $doc, 'PPI::Document' );
	isa_ok( $doc->child(0)->child(0)->child(0), 'PPI::Statement' );
	isa_ok( $doc->child(0)->child(0)->child(0), 'PPI::Statement::Expression' );
}





#####################################################################
# Bug 19629: End of list mistakenly seen as end of statement

SCOPE: {
	my $doc = PPI::Document->new( \'()' );
	isa_ok( $doc, 'PPI::Document' );
	isa_ok( $doc->child(0), 'PPI::Statement' );
}

SCOPE: {
	my $doc = PPI::Document->new( \'{}' );
	isa_ok( $doc, 'PPI::Document' );
	isa_ok( $doc->child(0), 'PPI::Statement' );
}

SCOPE: {
	my $doc = PPI::Document->new( \'[]' );
	isa_ok( $doc, 'PPI::Document' );
	isa_ok( $doc->child(0), 'PPI::Statement' );
}

#####################################################################
# Bug 21571: PPI::Token::Symbol::symbol does not properly handle
#            variables with adjacent braces

SCOPE: {
	my $doc = PPI::Document->new( \'$foo{bar}' );
	my $symbol = $doc->child(0)->child(0);
	isa_ok( $symbol, 'PPI::Token::Symbol' );
	is( $symbol->symbol, '%foo', 'symbol() for $foo{bar}' );
}

SCOPE: {
	my $doc = PPI::Document->new( \'$foo[0]' );
	my $symbol = $doc->child(0)->child(0);
	isa_ok( $symbol, 'PPI::Token::Symbol' );
	is( $symbol->symbol, '@foo', 'symbol() for $foo[0]' );
}


SCOPE: {
	my $doc = PPI::Document->new( \'@foo{bar}' );
	my $symbol = $doc->child(0)->child(0);
	isa_ok( $symbol, 'PPI::Token::Symbol' );
	is( $symbol->symbol, '%foo', 'symbol() for @foo{bar}' );
}

exit(0);
