#!/usr/bin/perl

# Formal testing for CSS::Tiny

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 22;
use CSS::Tiny;





# Test trivial creation
my $Trivial = CSS::Tiny->new();
isa_ok( $Trivial, 'CSS::Tiny' );
is( scalar(keys %$Trivial), 0, '->new returns an empty object' );

# Try to read in a config
my $Config = CSS::Tiny->read( 'test.css' );
isa_ok( $Config, 'CSS::Tiny' );

# Check the structure of the config
my $expected = {
	H1 => { color => 'blue' },
	H2 => { color => 'red', 'font-height' => '16px' },
	'P EM' => { this => 'that' },
	'A B' => { foo => 'bar' },
	'C D' => { foo => 'bar' },
	};
bless $expected, 'CSS::Tiny';
is_deeply( $Config, $expected, '->read returns expected structure' );

# Test clone
my $copy = $Config->clone;
isa_ok( $copy, 'CSS::Tiny' );
is_deeply( $copy, $Config, '->clone works as expected' );

# Add some stuff to the trivial stylesheet and check write_string() for it
$Trivial->{H1} = { color => 'blue' };
$Trivial->{'.this'} = {
	color => '#FFFFFF',
	'font-family' => 'Arial, "Courier New"',
	'font-variant' => 'small-caps',
	};
$Trivial->{'P EM'} = { color => 'red' };

my $string = <<END;
P EM {
	color: red;
}
H1 {
	color: blue;
}
.this {
	color: #FFFFFF;
	font-family: Arial, "Courier New";
	font-variant: small-caps;
}
END

my $Read = CSS::Tiny->read_string( $string );
ok( $Read, '>read_string() returns true' );
is_deeply( $Read, $Trivial, '->read_string() returns expected' );

my $generated = $Trivial->write_string();
ok( length $generated, '->write_string returns something' );
ok( $generated eq $string, '->write_string returns the correct file contents' );

# Try to write a file
my $rv = $Trivial->write( 'test2.css' );
ok( $rv, '->write returned true' );
ok( -e 'test2.css', '->write actually created a file' );

# Clean up on unload
END {
	unlink 'test2.css';
}

# Try to read the config back in
$Read = CSS::Tiny->read( 'test2.css' );
isa_ok( $Read, 'CSS::Tiny' );

# Check the structure of what we read back in
is_deeply( $Trivial, $Read, 'We get back what we wrote out' );		





#####################################################################
# Check that two identical named styles overwrite-by-property, rather than
# replace-by-style, so that styles are relatively correctly merged.

my $mergable = <<'END_CSS';
FOO {  test1: 1; }
FOO {  test2: 2; }
END_CSS

my $merged = CSS::Tiny->read_string( $mergable );
ok( $merged, "CSS::Tiny reads mergable CSS ok" );
is_deeply( $merged, { FOO => { test1 => 1, test2 => 2 } }, "Mergable CSS merges ok" );





#####################################################################
# Check the HTML generation

my $HTML = CSS::Tiny->new();
isa_ok( $HTML, 'CSS::Tiny' );
is( $HTML->html, '', '->html returns empty string for empty stylesheet' );

$HTML->{'.foo'}->{bar} = 1;
is( $HTML->html . "\n", <<'END_HTML', '->html returns correct looking HTML' );
<style type="text/css">
<!--
.foo {
	bar: 1;
}
-->
</style>
END_HTML





#####################################################################
# Check the XHTML generation

my $XHTML = CSS::Tiny->new;
isa_ok( $XHTML, 'CSS::Tiny' );
is( $XHTML->xhtml, '', '->xhtml returns empty string for empty stylesheet' );

$XHTML->{'.foo'}->{bar} = 1;
is( $HTML->xhtml . "\n", <<'END_XHTML', '->xhtml returns correct looking HTML' );
<style type="text/css">
/* <![CDATA[ */
.foo {
	bar: 1;
}
/* ]]> */
</style>
END_XHTML

1;
