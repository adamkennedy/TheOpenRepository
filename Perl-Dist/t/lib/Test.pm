package t::lib::Test;

# Generic base class for test classes

use strict;
use File::Spec::Functions ':ALL';
use Test::More    ();
use File::Path    ();
use File::Remove  ();
use t::lib::Test1 ();
use t::lib::Test2 ();
use t::lib::Test3 ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.01';
}





#####################################################################
# Default Paths

sub make_path {
	my $dir = rel2abs( catdir( curdir(), @_ ) );
	File::Path::mkpath( $dir ) unless -d $dir;
	Test::More::ok( -d $dir, 'Created ' . $dir );
	return $dir;
}

sub remake_path {
	my $dir = rel2abs( catdir( curdir(), @_ ) );
	File::Remove::remove( \1, $dir ) if -d $dir;
	File::Path::mkpath( $dir );
	Test::More::ok( -d $dir, 'Created ' . $dir );
	return $dir;
}

sub paths {
	# Prepare the test directories
	my $output_dir   = remake_path( "C:\\tmp\\sp\\output"   );
	my $image_dir    = remake_path( "C:\\tmp\\sp\\image"    );
	my $download_dir =   make_path( "C:\\tmp\\sp\\download" );
	my $build_dir    = remake_path( "C:\\tmp\\sp\\build"    );
	return (
		output_dir   => $output_dir,
		image_dir    => $image_dir,
		download_dir => $download_dir,
		build_dir    => $build_dir,
	);
}

sub cpan {
	if ( $ENV{TEST_PERLDIST_CPAN} ) {
		return URI->new($ENV{TEST_PERLDIST_CPAN});
	}
	my $path = rel2abs( catdir( 't', 'data', 'cpan' ) );
	Test::More::ok( -d $path, 'Found CPAN directory' );
	Test::More::ok( -d catdir( $path, 'authors', 'id' ), 'Found id subdirectory' );
	return URI::file->new($path . '\\');
}

sub new1 {
	my $class = shift;
	my @paths = $class->paths;
	my $cpan  = $class->cpan;
	return t::lib::Test1->new( cpan => $cpan, @paths, @_ );
}

sub new2 {
	my $class = shift;
	my @paths = $class->paths;
	my $cpan  = $class->cpan;
	return t::lib::Test2->new( cpan => $cpan, @paths, @_ );
}

sub new3 {
	my $class = shift;
	my @paths = $class->paths;
	my $cpan  = $class->cpan;
	return t::lib::Test3->new( cpan => $cpan, @paths, @_ );
}

1;
