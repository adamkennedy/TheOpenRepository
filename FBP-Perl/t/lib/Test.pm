package t::lib::Test;

use strict;
use warnings;
use Test::More;
use Test::LongString;
use Exporter ();

our $VERSION = '0.43';
our @ISA     = 'Exporter';
our @EXPORT  = qw{ code compiles slurp };

sub code {
	my $left    = shift;
	my $right   = shift;
	if ( ref $left ) {
		$left = join '', map { "$_\n" } @$left;
	}
	if ( ref $right ) {
		$right = join '', map { "$_\n" } @$right;
	}
	is_string( $left, $right, $_[0] );
}

sub compiles {
	my $code = shift;
	if ( ref $code ) {
		$code = join '', map { "$_\n" } @$code;
	}
	SKIP: {
		skip("Skipping compile test for release", 1) if $ENV{ADAMK_RELEASE};
		my $rv = eval $code;
		# diag( $@ ) if $@;
		ok( $rv, $_[0] );
	}
}

# Provide a simple slurp implementation
sub slurp {
	my $file = shift;
	local $/ = undef;
	local *FILE;
	open( FILE, '<', $file ) or die "open($file) failed: $!";
	my $text = <FILE>;
	close( FILE ) or die "close($file) failed: $!";
	return $text;
}

1;
