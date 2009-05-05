use Test::More tests => 2;
use Test::Compile;
use File::Spec::Functions qw(catdir catfile);

BEGIN {
	use_ok( 'Module::Build::Functions' );
}

diag( "Testing Module::Build::Functions $Module::Build::Functions::VERSION" );
pl_file_ok(catfile(catdir(qw(blib lib auto Module Build Functions)), 'bundler.al'), 'bundler() compiles correctly.')