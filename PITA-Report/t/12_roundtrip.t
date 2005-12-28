#!/usr/bin/perl -w

# Round-trip from an object to XML and back again

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

use Test::More tests => 11;
use PITA::Report ();





#####################################################################
# Create the Report

my $platform = PITA::Report::Platform->current;
isa_ok( $platform, 'PITA::Report::Platform' );

my $request = PITA::Report::Request->new(
	scheme    => 'perl5',
	distname  => 'Foo-Bar',
	filename  => 'Foo-Bar-0.01.tar.gz',
	md5sum    => '5cf0529234bac9935fc74f9579cc5be8',
	authority => 'cpan',
	authpath  => '/id/authors/A/AD/ADAMK/Foo-Bar-0.01.tar.gz',
	);
isa_ok( $request, 'PITA::Report::Request' );

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
isa_ok( $command, 'PITA::Report::Command' );

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
isa_ok( $test, 'PITA::Report::Test' );

my $install = PITA::Report::Install->new(
	request  => $request,
	platform => $platform,
	);
isa_ok( $install, 'PITA::Report::Install' );
ok( $install->add_command( $command ), '->add_command returned true' );
ok( $install->add_test( $test ), '->add_test returned true' );

my $report = PITA::Report->new;
isa_ok( $report, 'PITA::Report' );

ok( $report->add_install( $install ), '->add_install returns ok' );





#####################################################################
# Write out the file and read it back in

# Save
my $output = '';
ok( $report->write( \$output ), '->write(SCALAR) returns true' );
like( $output, qr(^\<report\>.+\<\/report\>$)s, 'PITA-XML is written' );

SKIP: {

	# Load
	my $report2 = PITA::Report->new( \$output );
	isa_ok( $report2, 'PITA::Report' );

	skip("Parsing failed, skipping comparison check", 1) unless $report2;

	# Compare
	is_deeply( $report, $report2, 'PITA::Report object round-trips correctly' );
}

exit(0);
