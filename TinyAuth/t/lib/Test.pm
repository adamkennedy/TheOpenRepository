package t::lib::Test;

# Testing stuff for TinyAuth

use strict;
use vars qw{@ISA @EXPORT};
BEGIN {
	require Exporter;
	@ISA    = qw{ Exporter };
	@EXPORT = qw{ default_config cgi_cmp };
}

use File::Spec::Functions ':ALL';
use YAML::Tiny       ();
use Test::LongString ();

sub default_config {
	my $config_file = rel2abs( catfile( 't', 'data', 'htpasswd'      ) );
	Test::More::ok( -f $config_file, 'Testing config file exists' );

	my $config = YAML::Tiny->new;
	$config->[0]->{htpasswd}     = $config_file;
	$config->[0]->{email_from}   = 'adamk@cpan.org';
	$config->[0]->{email_driver} = 'Test';
	Test::More::isa_ok( $config, 'YAML::Tiny' );

	return $config;
}






# Test that two HTML files match
sub cgi_cmp {
	my $left  = shift;
	my $right = shift;

	# Clean up the two sides
	$left  =~ s/^\s+//is;
	$left  =~ s/\s+$//is;
	$left  =~ s/(?:\015{1,2}\012|\015|\012)/\n/sg;
	$right =~ s/^\s+//is;
	$right =~ s/\s+$//is;
	$right =~ s/(?:\015{1,2}\012|\015|\012)/\n/sg;

	Test::LongString::is_string( $left, $right, $_[0] );
}

1;
