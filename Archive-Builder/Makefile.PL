use inc::Module::Install;

name            'Archive-Builder';
all_from        'lib/Archive/Builder.pm';
requires        'List::Util'       => '1.15';
requires        'File::Spec'       => '0.80';
requires        'File::Flat'       => '0.92';
requires        'Class::Autouse'   => '1.04';
requires        'Class::Inspector' => '1.11';
requires        'IO::Scalar'       => '2.104';
requires        'IO::Zlib'         => 0;
requires        'Params::Util'     => '0.10';
build_requires  'Test::More'       => '0.47';
build_requires  'Class::Inspector' => '1.11'; # Needed by Test::ClassAPI
build_requires  'Test::ClassAPI'   => '1.02';
include         'Test::ClassAPI';

# When testing, have all the archive drivers available
if ( $ENV{AUTOMATED_TESTING} ) {
	requires 'Archive::Zip'   => 0;
	requires 'Archive::Tar'   => 0;
	requires 'Compress::Zlib' => 0;
}

auto_install;
WriteAll;
