#!/usr/bin/perl -w

# Unit testing for PPI, generated by Test::Inline

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::XS_DISABLE = 1; # Prevent warning
}
use PPI;

# Execute the tests
use Test::More tests => 24;

# =begin testing __insert_after 6
{
my $Document = PPI::Document->new( \"print 'Hello World';" );
isa_ok( $Document, 'PPI::Document' );
my $string = $Document->find_first('Token::Quote');
isa_ok( $string, 'PPI::Token::Quote' );
is( $string->content, "'Hello World'", 'Got expected token' );
my $foo = PPI::Token::Word->new('foo');
isa_ok( $foo, 'PPI::Token::Word' );
is( $foo->content, 'foo', 'Created Word token' );
$string->__insert_after( $foo );
is( $Document->serialize, "print 'Hello World'foo;",
	'__insert_after actually inserts' );
}



# =begin testing __insert_before 6
{
my $Document = PPI::Document->new( \"print 'Hello World';" );
isa_ok( $Document, 'PPI::Document' );
my $semi = $Document->find_first('Token::Structure');
isa_ok( $semi, 'PPI::Token::Structure' );
is( $semi->content, ';', 'Got expected token' );
my $foo = PPI::Token::Word->new('foo');
isa_ok( $foo, 'PPI::Token::Word' );
is( $foo->content, 'foo', 'Created Word token' );
$semi->__insert_before( $foo );
is( $Document->serialize, "print 'Hello World'foo;",
	'__insert_before actually inserts' );
}



# =begin testing insert_after after __insert_after 6
{
my $Document = PPI::Document->new( \"print 'Hello World';" );
isa_ok( $Document, 'PPI::Document' );
my $string = $Document->find_first('Token::Quote');
isa_ok( $string, 'PPI::Token::Quote' );
is( $string->content, "'Hello World'", 'Got expected token' );
my $foo = PPI::Token::Word->new('foo');
isa_ok( $foo, 'PPI::Token::Word' );
is( $foo->content, 'foo', 'Created Word token' );
$string->insert_after( $foo );
is( $Document->serialize, "print 'Hello World'foo;",
	'insert_after actually inserts' );
}



# =begin testing insert_before after __insert_before 6
{
my $Document = PPI::Document->new( \"print 'Hello World';" );
isa_ok( $Document, 'PPI::Document' );
my $semi = $Document->find_first('Token::Structure');
isa_ok( $semi, 'PPI::Token::Structure' );
is( $semi->content, ';', 'Got expected token' );
my $foo = PPI::Token::Word->new('foo');
isa_ok( $foo, 'PPI::Token::Word' );
is( $foo->content, 'foo', 'Created Word token' );
$semi->insert_before( $foo );
is( $Document->serialize, "print 'Hello World'foo;",
	'insert_before actually inserts' );
}


1;
