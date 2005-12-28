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

use Test::More tests => 37;
use Config                  ();
use PITA::Report            ();
use PITA::Report::SAXDriver ();
use XML::SAX::Writer        ();

my $XMLNS = PITA::Report->XMLNS;

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
	driver_is( $driver,
		"<?xml version='1.0' encoding='UTF-8'?><null xmlns='$XMLNS' />",
		'->_undef works as expected' );
}





my $platform = PITA::Report::Platform->current;
SCOPE: {
	my $driver = driver_new();
	$driver->start_document( {} );

	# Test a cut-down version of a platform object
	isa_ok( $platform, 'PITA::Report::Platform' );
	$platform->{bin}    = 'BIN';
	$platform->{env}    = { foo => 'FOO', bar => '', baz => undef };
	$platform->{config} = { foo => 'FOO', bar => undef, baz => '' };
	$driver->_parse_platform( $platform );

	$driver->end_document( {} );
	my $platform_string = <<"END_XML";
<?xml version='1.0' encoding='UTF-8'?>
<platform xmlns='$XMLNS'>
<bin>BIN</bin>
<env name='bar' />
<env name='baz'><null /></env>
<env name='foo'>FOO</env>
<config name='bar'><null /></config>
<config name='baz' />
<config name='foo'>FOO</config>
</platform>
END_XML
	chomp $platform_string;
	$platform_string =~ s/>\n</></g;
	driver_is( $driver, $platform_string, '->_parse_platform works as expected' );	
}





my $request = PITA::Report::Request->new(
	scheme    => 'perl5',
	distname  => 'Foo-Bar',
	filename  => 'Foo-Bar-0.01.tar.gz',
	md5sum    => '5cf0529234bac9935fc74f9579cc5be8',
	authority => 'cpan',
	authpath  => '/id/authors/A/AD/ADAMK/Foo-Bar-0.01.tar.gz',
	);
SCOPE: {
	my $driver = driver_new();
	$driver->start_document( {} );

	# Create a test request
	isa_ok( $request, 'PITA::Report::Request' );
	$driver->_parse_request( $request );

	$driver->end_document( {} );	
	my $request_string = <<"END_XML";
<?xml version='1.0' encoding='UTF-8'?>
<request xmlns='$XMLNS'>
<scheme>perl5</scheme>
<distname>Foo-Bar</distname>
<filename>Foo-Bar-0.01.tar.gz</filename>
<md5sum>5cf0529234bac9935fc74f9579cc5be8</md5sum>
<authority>cpan</authority>
<authpath>/id/authors/A/AD/ADAMK/Foo-Bar-0.01.tar.gz</authpath>
</request>
END_XML
	chomp $request_string;
	$request_string =~ s/>\n</></g;
	driver_is( $driver, $request_string, '->_parse_request works as expected' );	
}





my $command = PITA::Report::Command->new(
	cmd    => 'perl Makefile.PL',
	stderr => \"",
	stdout => \<<'END_STDOUT' );
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
SCOPE: {
	my $driver = driver_new();
	$driver->start_document( {} );

	# Create the command object
	isa_ok( $command, 'PITA::Report::Command' );
	$driver->_parse_command( $command );

	$driver->end_document( {} );
	my $command_string = <<"END_XML";
<?xml version='1.0' encoding='UTF-8'?>
<command xmlns='$XMLNS'>
<cmd>perl Makefile.PL</cmd>
<stdout>include /home/adam/cpan2/trunk/PITA-Report/inc/Module/Install.pm
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
</stdout>
<stderr />
</command>
END_XML
	chomp $command_string;
	$command_string =~ s/>\n</></g;
	driver_is( $driver, $command_string, '->_parse_command works as expected' );	
}





# Create the command object
my $test = PITA::Report::Test->new(
	name     => 't/01_main.t',
	stderr   => \"",
	exitcode => 0,
	stdout   => \<<'END_STDOUT' );
1..4
ok 1 - Input file opened
# diagnostic
not ok 2 - First line of the input valid
ok 3 - Read the rest of the file
not ok 4 - Summarized correctly # TODO Not written yet
END_STDOUT
SCOPE: {
	my $driver = driver_new();
	$driver->start_document( {} );

	# Create a test request
	isa_ok( $test, 'PITA::Report::Test' );
	$driver->_parse_test( $test );

	$driver->end_document( {} );
	my $test_string = <<"END_XML";
<?xml version='1.0' encoding='UTF-8'?>
<test xmlns='$XMLNS' language='text/x-tap' name='t/01_main.t'>
<stdout>1..4
ok 1 - Input file opened
# diagnostic
not ok 2 - First line of the input valid
ok 3 - Read the rest of the file
not ok 4 - Summarized correctly # TODO Not written yet
</stdout>
<stderr />
<exitcode>0</exitcode>
</test>
END_XML
	chomp $test_string;
	$test_string =~ s/>\n</></g;
	driver_is( $driver, $test_string, '->_parse_test works as expected' );	
}




# Create a single install
my $install = PITA::Report::Install->new(
	request  => $request,
	platform => $platform,
	);
SCOPE: {
	my $driver = driver_new();
	$driver->start_document( {} );

	# Create a test request
	isa_ok( $install,           'PITA::Report::Install'  );
	isa_ok( $install->request,  'PITA::Report::Request'  );
	isa_ok( $install->platform, 'PITA::Report::Platform' );
	$driver->_parse_install( $install );

	$driver->end_document( {} );
	my $install_string = <<"END_XML";
<?xml version='1.0' encoding='UTF-8'?>
<install xmlns='$XMLNS'>
<request>
<scheme>perl5</scheme>
<distname>Foo-Bar</distname>
<filename>Foo-Bar-0.01.tar.gz</filename>
<md5sum>5cf0529234bac9935fc74f9579cc5be8</md5sum>
<authority>cpan</authority>
<authpath>/id/authors/A/AD/ADAMK/Foo-Bar-0.01.tar.gz</authpath>
</request>
<platform>
<bin>BIN</bin>
<env name='bar' />
<env name='baz'><null /></env>
<env name='foo'>FOO</env>
<config name='bar'><null /></config>
<config name='baz' />
<config name='foo'>FOO</config>
</platform>
</install>
END_XML
	chomp $install_string;
	$install_string =~ s/>\n</></g;
	driver_is( $driver, $install_string, '->_parse_install works as expected' );	
}




# Add the command and test to the install and try again
ok( $install->add_test( $test ),       '->add_test returned true'    );
ok( $install->add_command( $command ), '->add_command returned true' );
SCOPE: {
	my $driver = driver_new();
	$driver->start_document( {} );

	# Create a installer
	$driver->_parse_install( $install );

	$driver->end_document( {} );
	my $install_string = <<"END_XML";
<?xml version='1.0' encoding='UTF-8'?>
<install xmlns='$XMLNS'>
<request>
<scheme>perl5</scheme>
<distname>Foo-Bar</distname>
<filename>Foo-Bar-0.01.tar.gz</filename>
<md5sum>5cf0529234bac9935fc74f9579cc5be8</md5sum>
<authority>cpan</authority>
<authpath>/id/authors/A/AD/ADAMK/Foo-Bar-0.01.tar.gz</authpath>
</request>
<platform>
<bin>BIN</bin>
<env name='bar' />
<env name='baz'><null /></env>
<env name='foo'>FOO</env>
<config name='bar'><null /></config>
<config name='baz' />
<config name='foo'>FOO</config>
</platform>
<command>
<cmd>perl Makefile.PL</cmd>
<stdout>include /home/adam/cpan2/trunk/PITA-Report/inc/Module/Install.pm
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
</stdout>
<stderr />
</command>
<test language='text/x-tap' name='t/01_main.t'>
<stdout>1..4
ok 1 - Input file opened
# diagnostic
not ok 2 - First line of the input valid
ok 3 - Read the rest of the file
not ok 4 - Summarized correctly # TODO Not written yet
</stdout>
<stderr />
<exitcode>0</exitcode>
</test>
</install>
END_XML
	chomp $install_string;
	$install_string =~ s/>\n</></g;
	driver_is( $driver, $install_string, '->_parse_install works as expected' );	
}




# Create a new report
my $report = PITA::Report->new;
isa_ok( $report, 'PITA::Report' );
SCOPE: {
	my $driver = driver_new();
	$driver->start_document( {} );

	# Create a installer
	$driver->_parse_report( $report );

	$driver->end_document( {} );
	my $report_string = <<"END_XML";
<?xml version='1.0' encoding='UTF-8'?>
<report xmlns='$XMLNS' />
END_XML
	chomp $report_string;
	$report_string =~ s/>\n</></g;
	driver_is( $driver, $report_string,
		'->_parse_report works as expected' );
}




# Add an install report to the file
ok( $report->add_install( $install ), '->add_install returns ok' );
my $report_string = <<"END_XML";
<?xml version='1.0' encoding='UTF-8'?>
<report xmlns='$XMLNS'>
<install>
<request>
<scheme>perl5</scheme>
<distname>Foo-Bar</distname>
<filename>Foo-Bar-0.01.tar.gz</filename>
<md5sum>5cf0529234bac9935fc74f9579cc5be8</md5sum>
<authority>cpan</authority>
<authpath>/id/authors/A/AD/ADAMK/Foo-Bar-0.01.tar.gz</authpath>
</request>
<platform>
<bin>BIN</bin>
<env name='bar' />
<env name='baz'><null /></env>
<env name='foo'>FOO</env>
<config name='bar'><null /></config>
<config name='baz' />
<config name='foo'>FOO</config>
</platform>
<command>
<cmd>perl Makefile.PL</cmd>
<stdout>include /home/adam/cpan2/trunk/PITA-Report/inc/Module/Install.pm
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
</stdout>
<stderr />
</command>
<test language='text/x-tap' name='t/01_main.t'>
<stdout>1..4
ok 1 - Input file opened
# diagnostic
not ok 2 - First line of the input valid
ok 3 - Read the rest of the file
not ok 4 - Summarized correctly # TODO Not written yet
</stdout>
<stderr />
<exitcode>0</exitcode>
</test>
</install>
</report>
END_XML
chomp $report_string;
$report_string =~ s/>\n</></g;
SCOPE: {
	my $driver = driver_new();
	$driver->start_document( {} );

	# Create a installer
	$driver->_parse_report( $report );
	$driver->end_document( {} );
	driver_is( $driver, $report_string,
		'->_parse_report works as expected' );
}




# Try the normal way
my $string = '';
ok( $report->write( \$string ), '->write returns true for report' );
is( $string, $report_string, '->write outputs the expected XML' );
