#!/usr/bin/perl -w

# Unit tests for the PITA::Report::Platform class

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'lib'),
			catdir('blib', 'arch'),
			);
	}
}

use Test::More tests => 20;
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




SCOPE: {
	my $driver = driver_new();
	$driver->start_document( {} );

	# Create a test request
	my $stdout = <<'END_STDOUT';
include /home/adam/cpan2/trunk/PITA-Report/inc/Module/Install.pm
include inc/Module/Install/Metadata.pm
include inc/Module/Install/Base.pm
include inc/Module/Install/Share.pm
include inc/Module/Install/Makefile.pm
include inc/Module/Install/AutoInstall.pm
include inc/Module/Install/Include.pm
include inc/Module/AutoInstall.pm
*** Module::AutoInstall version 1.00
*** Checking for dependencies...
[Core Features]
- File::Spec              ...loaded. (3.11 >= 0.80)
- Test::More              ...loaded. (0.62 >= 0.47)
- Module::Install::Share  ...loaded. (0.01)
- Carp                    ...loaded. (1.02)
- IO::Handle              ...loaded. (1.25)
- IO::File                ...loaded. (1.13)
- IO::Seekable            ...loaded. (1.1)
- File::Flock             ...loaded. (104.111901 >= 101.060501)
- Params::Util            ...loaded. (0.07 >= 0.07)
- File::ShareDir          ...loaded. (0.02 >= 0.02)
- XML::SAX::ParserFactory ...loaded. (1.01 >= 0.13)
- XML::Validator::Schema  ...loaded. (1.08 >= 1.08)
*** Module::AutoInstall configuration finished.
include inc/Module/Install/WriteAll.pm
Writing META.yml
include inc/Module/Install/Win32.pm
include inc/Module/Install/Can.pm
include inc/Module/Install/Fetch.pm
Writing Makefile for PITA::Report
END_STDOUT

	# Create the command object
	my $command = PITA::Report::Command->new(
		cmd    => 'perl Makefile.PL',
		stdout => \$stdout,
		stderr => \"",
		);
	isa_ok( $command, 'PITA::Report::Command' );
	$driver->_parse_command( $command );

	$driver->end_document( {} );
	my $command_string = <<"END_XML";
<command><cmd>perl Makefile.PL</cmd><stdout>include /home/adam/cpan2/trunk/PITA-Report/inc/Module/Install.pm
include inc/Module/Install/Metadata.pm
include inc/Module/Install/Base.pm
include inc/Module/Install/Share.pm
include inc/Module/Install/Makefile.pm
include inc/Module/Install/AutoInstall.pm
include inc/Module/Install/Include.pm
include inc/Module/AutoInstall.pm
*** Module::AutoInstall version 1.00
*** Checking for dependencies...
[Core Features]
- File::Spec              ...loaded. (3.11 &gt;= 0.80)
- Test::More              ...loaded. (0.62 &gt;= 0.47)
- Module::Install::Share  ...loaded. (0.01)
- Carp                    ...loaded. (1.02)
- IO::Handle              ...loaded. (1.25)
- IO::File                ...loaded. (1.13)
- IO::Seekable            ...loaded. (1.1)
- File::Flock             ...loaded. (104.111901 &gt;= 101.060501)
- Params::Util            ...loaded. (0.07 &gt;= 0.07)
- File::ShareDir          ...loaded. (0.02 &gt;= 0.02)
- XML::SAX::ParserFactory ...loaded. (1.01 &gt;= 0.13)
- XML::Validator::Schema  ...loaded. (1.08 &gt;= 1.08)
*** Module::AutoInstall configuration finished.
include inc/Module/Install/WriteAll.pm
Writing META.yml
include inc/Module/Install/Win32.pm
include inc/Module/Install/Can.pm
include inc/Module/Install/Fetch.pm
Writing Makefile for PITA::Report
</stdout><stderr /></command>
END_XML
	chomp $command_string;
	driver_is( $driver, $command_string, '->_parse_command works as expected' );	
}




SCOPE: {
	my $driver = driver_new();
	$driver->start_document( {} );

	# Create a test request
	my $stdout = <<'END_STDOUT';
1..4
ok 1 - Input file opened
# diagnostic
not ok 2 - First line of the input valid
ok 3 - Read the rest of the file
not ok 4 - Summarized correctly # TODO Not written yet
END_STDOUT

	# Create the command object
	my $test = PITA::Report::Test->new(
		name     => 't/01_main.t',
		stdout   => \$stdout,
		stderr   => \"",
		exitcode => 0,
		);
	isa_ok( $test, 'PITA::Report::Test' );
	$driver->_parse_test( $test );

	$driver->end_document( {} );
	my $test_string = <<"END_XML";
<test language='text/x-tap' name='t/01_main.t'><stdout>1..4
ok 1 - Input file opened
# diagnostic
not ok 2 - First line of the input valid
ok 3 - Read the rest of the file
not ok 4 - Summarized correctly # TODO Not written yet
</stdout><stderr /><exitcode>0</exitcode></test>
END_XML
	chomp $test_string;
	driver_is( $driver, $test_string, '->_parse_test works as expected' );	
}
