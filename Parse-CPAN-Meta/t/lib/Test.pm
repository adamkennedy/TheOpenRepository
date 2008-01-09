package t::lib::Test;

use strict;
use Test::More ();
use Parse::CPAN::Meta;

use vars qw{@ISA @EXPORT};
BEGIN {
	require Exporter;
	@ISA    = qw{ Exporter };
	@EXPORT = qw{ tests  yaml_ok  slurp  load_ok };
}

# 22 tests per call to yaml_ok
# 4  tests per call to load_ok
sub tests {
	return ( tests => count(@_) );
}

sub count {
	my $yaml_ok = shift || 0;
	my $load_ok = shift || 0;
	my $single  = shift || 0;
	my $count   = $yaml_ok * 3 + $load_ok * 4 + $single;
	return $count;
}

sub yaml_ok {
	my $string  = shift;
	my $array   = shift;
	my $name    = shift || 'unnamed';

	# Does the string parse to the structure
	my $yaml_copy = $string;
	my @yaml      = eval { Parse::CPAN::Meta::Load( $yaml_copy ); };
	Test::More::is( $@, '', "$name: YAML::Tiny parses without error" );
	Test::More::is( $yaml_copy, $string, "$name: YAML::Tiny does not modify the input string" );
	SKIP: {
		Test::More::skip( "Shortcutting after failure", 1 ) if $@;
		Test::More::is_deeply( \@yaml, $array, "$name: YAML::Tiny parses correctly" );
	}

	# Return true as a convenience
	return 1;
}

sub slurp {
	my $file = shift;
	local $/ = undef;
	open( FILE, " $file" ) or die "open($file) failed: $!";
	my $source = <FILE>;
	close( FILE ) or die "close($file) failed: $!";
	$source;
}

sub load_ok {
	my $name = shift;
	my $file = shift;
	my $size = shift;
	Test::More::ok( -f $file, "Found $name" );
	Test::More::ok( -r $file, "Can read $name" );
	my $content = slurp( $file );
	Test::More::ok( (defined $content and ! ref $content), "Loaded $name" );
	Test::More::ok( ($size < length $content), "Content of $name larger than $size bytes" );
	return $content;
}

1;
