#!/usr/bin/perl -w

# Unit tests for the PITA::Report::Platform class

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import('blib/lib', 'blib/arch');
	}
}

use Test::More tests => 14;
use Config                  ();
use PITA::Report            ();
use PITA::Report::SAXDriver ();
use XML::SAX::Writer        ();

# Extra testing functions
sub dies {
	my $code = shift;
	eval { &$code() };
	ok( $@, $_[0] || 'Code dies as expected' );
}

sub driver_new {
	my $driver = PITA::Report::SAXDriver->new;
	isa_ok( $driver, 'PITA::Report::SAXDriver' );
	return $driver;
}

sub driver_is {
	my ($driver, $string, $message) = @_;
	my $output = $driver->Output;
	is( $$output, $string, $message );
}





#####################################################################
# Prepare

# Check the normal way we make output writers
my $output = '';
my $writer = XML::SAX::Writer->new( Output => \$output );
isa_ok( $writer,            'XML::Filter::BufferText' );
isa_ok( $writer->{Handler}, 'XML::SAX::Writer::XML'   );

# Get a platform object
isa_ok( PITA::Report::Platform->current,
	'PITA::Report::Platform' );

# Check we can make a basic driver
driver_new();





#####################################################################
# Test the XML Support Methods

SCOPE: {
	# Test the _element hash
	my $driver  = driver_new();
	my $element = $driver->_element( 'foo' );
	is_deeply( $element, {
		Name         => 'foo',
		#Prefix       => '',
		#LocalName    => 'foo',
		#NamespaceURI => 'http://ali.as/xml/schema/pita-xml/'
		#	. $PITA::Report::VERSION,
		Attributes   => {},
		}, 'Basic _element call matches expected' );
}



SCOPE: {
	my $driver = driver_new();
	$driver->start_document( {} );

	# Create an undef tag
	$driver->_undef;

	$driver->end_document( {} );
	driver_is( $driver, '<null />', '->_undef works as expected' );
}



SCOPE: {
	my $driver = driver_new();
	$driver->start_document( {} );

	# Test a cut-down version of a platform object
	my $platform = PITA::Report::Platform->current;
	isa_ok( $platform, 'PITA::Report::Platform' );
	$platform->{bin}    = 'BIN';
	$platform->{env}    = { foo => 'FOO', bar => '', baz => undef };
	$platform->{config} = { foo => 'FOO', bar => undef, baz => '' };
	$driver->_parse_platform( $platform );

	$driver->end_document( {} );
	my $platform_string = <<"END_XML";
<platform>
<bin>BIN</bin>
<env name='bar' />
<env name='baz'><null /></env>
<env name='foo'>FOO</env>
<config name='bar'><null /></config>
<config name='baz' />
<config name='foo'>FOO</config>
</platform>
END_XML
	$platform_string =~ s/\n//g;
	driver_is( $driver, $platform_string, '->_parse_platform works as expected' );	
}




SCOPE: {
	my $driver = driver_new();
	$driver->start_document( {} );

	# Create a test request
	my $request = PITA::Report::Request->new(
		scheme    => 'perl5',
		distname  => 'Foo-Bar',
		filename  => 'Foo-Bar-0.01.tar.gz',
		md5sum    => '5cf0529234bac9935fc74f9579cc5be8',
		authority => 'cpan',
		authpath  => '/id/authors/A/AD/ADAMK/Foo-Bar-0.01.tar.gz',
		);
	isa_ok( $request, 'PITA::Report::Request' );
	$driver->_parse_request( $request );

	$driver->end_document( {} );	
	my $request_string = <<"END_XML";
<request>
<scheme>perl5</scheme>
<distname>Foo-Bar</distname>
<filename>Foo-Bar-0.01.tar.gz</filename>
<md5sum>5cf0529234bac9935fc74f9579cc5be8</md5sum>
<authority>cpan</authority>
<authpath>/id/authors/A/AD/ADAMK/Foo-Bar-0.01.tar.gz</authpath>
</request>
END_XML
	$request_string =~ s/\n//g;
	driver_is( $driver, $request_string, '->_parse_request works as expected' );	
}
	