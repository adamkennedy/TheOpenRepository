#!/usr/bin/perl -w

# Compile-testing for PITA-Scheme

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
use PITA::Scheme::Perl5::Make;
use Test::More tests => 26;

# Locate the injector directory
my $injector = catdir( 't', 'prepare', 'injector' );
ok( -d $injector, 'Test injector exists' );

# Create the workarea directory
my $cwd      = cwd();
my $workarea = catdir( 't', 'prepare', 'workarea' );
File::Remove::remove( \1, $workarea ) if -d $workarea;
END {
	chdir $cwd;
	File::Remove::remove( \1, $workarea ) if -d $workarea;
}
ok( mkdir( $workarea ), 'Created workarea' );
ok( -d $workarea, 'Test workarea exists' );

# Work out where to write the report to
my $write_report = 'write_report.pita';
      File::Remove::remove( \1, $write_report ) if -f $write_report;
END { File::Remove::remove( \1, $write_report ) if -f $write_report; }
ok( ! -f $write_report, "Report doesn't exist" );





#####################################################################
# Prepare

my $scheme = PITA::Scheme::Perl5::Make->new(
	injector    => $injector,
	workarea    => $workarea,
	scheme      => 'perl5.make',
	path        => '',
	request_xml => 'request.pita',
	request_id  => 1234,
	);
isa_ok( $scheme, 'PITA::Scheme' );

# Rerun the prepare stuff in one step
ok( $scheme->prepare_all, '->prepare_all runs ok' );
ok( $scheme->extract_path, '->extract_path gets set'  );
ok( -d $scheme->extract_path, '->extract_path exists' );
ok( $scheme->workarea_file('Makefile.PL'), '->workarea_file returns a value' );
like( $scheme->workarea_file('Makefile.PL'), qr/\bMakefile\.PL$/,
	'->workarea_file return a right-looking string' );
ok( -f $scheme->workarea_file('Makefile.PL'),
	'Makefile.PL exists in the extract package' );
ok( -f 'Makefile.PL', 'Changed to package directory, found Makefile.PL' );
isa_ok( $scheme->platform, 'PITA::XML::Platform' );
isa_ok( $scheme->install, 'PITA::XML::Install'   );
isa_ok( $scheme->report, 'PITA::XML::Report'             );





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
is( $commands[1]->cmd, 'make',
	'Command 2 contains the expected command' );
is( $commands[2]->cmd, 'make test',
	'Command 3 contains the expected command' );
like( ${$commands[2]->stdout}, qr/All tests successful./,
	'Command 3 contains "all tests pass"' );
ok( -f $scheme->workarea_file('Makefile'),
	'Makefile actually got created' );
ok( -d $scheme->workarea_file('blib'),
	'blib directory actually got created' );

exit(0);
