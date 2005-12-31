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

use File::Remove;
use PITA::Scheme;
use Test::More tests => 23;

# Locate the injector directory
my $injector = catdir( 't', '02_empiric', 'injector' );
ok( -d $injector, 'Test injector exists' );

# Create the workarea directory
my $workarea = catdir( 't', '02_empiric', 'workarea' );
      File::Remove::remove( \1, $workarea ) if -d $workarea;
END { File::Remove::remove( \1, $workarea ) if -d $workarea; }
ok( mkdir( $workarea ), 'Created workarea' );
ok( -d $workarea, 'Test workarea exists' );





#####################################################################
# Main Testing

my $scheme = PITA::Scheme->new(
	injector => $injector,
	workarea => $workarea,
	);
isa_ok( $scheme, 'PITA::Scheme'              );
isa_ok( $scheme, 'PITA::Scheme::Perl5::Make' );

# Check the accessors
is( $scheme->injector, $injector, '->injector matches original'  );
is( $scheme->workarea, $workarea, '->workarea matches original'  );
is( ref($scheme->instance), 'HASH', '->instance returns a hash'  );
ok( $scheme->scheme_conf, '->scheme_conf returns true'           );
ok( -f $scheme->scheme_conf, '->scheme_conf file exists'         );
isa_ok( $scheme->config, 'Config::Tiny'                          );
isa_ok( $scheme->request, 'PITA::Report::Request'                );
ok( $scheme->archive, '->archive returns true'                   );
ok( -f $scheme->archive, '->archive file exists'                 );
is( $scheme->extract_path, undef, 'No ->extract_path value yet'  );
is( scalar($scheme->extract_files), undef, 'No ->extract_files ' );
is_deeply( [ $scheme->extract_files ], [], 'No ->extract_files ' );

# Prepare the package
my $rv = $scheme->prepare_package;
ok( $rv, '->prepare_package runs ok' );
ok( $scheme->extract_path, '->extract_path gets set'  );
ok( -d $scheme->extract_path, '->extract_path exists' );
ok( $scheme->workarea_file('Makefile.PL'), '->workarea_file returns a value' );
like( $scheme->workarea_file('Makefile.PL'), qr/\bMakefile\.PL$/,
	'->workarea_file return a right-looking string' );
ok( -f $scheme->workarea_file('Makefile.PL'),
	'Makefile.PL exists in the extract package' );

exit(0);
