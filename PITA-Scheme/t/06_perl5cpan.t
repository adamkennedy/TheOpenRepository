#!/usr/bin/perl -w

# Testing the perl5.cpan scheme

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
			'lib',
			);
	}
}

use Cwd;
use File::Remove;
use PITA::Scheme::Perl5::CPAN;
use Test::More tests => 27;

# Locate the injector directory
my $injector = catdir( 't', 'perl5cpan', 'injector' );
ok( -d $injector, 'Test injector exists' );

# Create the workarea directory
my $cwd      = cwd();
my $workarea = catdir( 't', 'perl5cpan', 'workarea' );
File::Remove::remove( \1, $workarea ) if -d $workarea;
END {
	chdir $cwd;
	File::Remove::remove( \1, $workarea ) if -d $workarea;
}
ok( mkdir( $workarea ), 'Created workarea' );
ok( -d $workarea, 'Test workarea exists' );





#####################################################################
# Prepare

# Temporarily register the scheme
$PITA::XML::SCHEMES{'perl5.cpan'} = 1;
my $scheme = PITA::Scheme::Perl5::CPAN->new(
	injector    => $injector,
	workarea    => $workarea,
	scheme      => 'perl5.cpan',
	path        => '',
	request_xml => 'request.pita',
	request_id  => 1234,
	);
isa_ok( $scheme, 'PITA::Scheme' );
isa_ok( $scheme, 'PITA::Scheme::Perl5::CPAN' );

# Rerun the prepare stuff in one step
ok( $scheme->prepare_all, '->prepare_all runs ok' );

# Stop here...

isa_ok( $scheme->request, 'PITA::XML::Request'   );
is( $scheme->request_id, 1234, 'Got expected ->request_id value' );
isa_ok( $scheme->platform, 'PITA::XML::Platform' );
isa_ok( $scheme->install, 'PITA::XML::Install'   );
isa_ok( $scheme->report, 'PITA::XML::Report'     );





#####################################################################
# Execute

# Run the execution
ok( $scheme->execute_all, '->execute_all runs ok' );

# Does the install object contain things
is( scalar($scheme->install->commands), 3,
	'->execute_all added three commands to the report' );
my @commands = $scheme->install->commands;
isa_ok( $commands[0], 'PITA::XML::Command' );
isa_ok( $commands[1], 'PITA::XML::Command' );
isa_ok( $commands[2], 'PITA::XML::Command' );
is( $commands[0]->cmd, 'perl Makefile.PL',
	'Command 1 contains the expected command' );
like( $commands[1]->cmd, qr/Makefile$/,
	'Command 2 contains the expected command' );
like( $commands[2]->cmd, qr/Makefile test$/,
	'Command 3 contains the expected command' );
like( ${$commands[2]->stdout}, qr/All tests successful./,
	'Command 3 contains "all tests pass"' );
ok( -f $scheme->workarea_file('Makefile'),
	'Makefile actually got created' );
ok( -d $scheme->workarea_file('blib'),
	'blib directory actually got created' );

exit(0);
