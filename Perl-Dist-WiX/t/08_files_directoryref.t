#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	if ( $^O eq 'MSWin32' ) {
		plan tests => 22;
	} else {
		plan skip_all => 'Not on Win32';
	}
}

use     File::Spec::Functions 
            qw(curdir updir splitdir rel2abs catfile catdir);
require Perl::Dist::WiX::Files::DirectoryRef;
require Perl::Dist::WiX::Directory;


#####################################################################
#

my $path = rel2abs( catdir( curdir(), 't' ) );
my $path_up = rel2abs( curdir() );

my $dir = Perl::Dist::WiX::Directory->new( 
    trace => 100,
    path => $path,
    name => (splitdir($path))[-1],
    sitename => 'www.test.site.invalid',
);

my $dir_up = Perl::Dist::WiX::Directory->new( 
    trace => 100,
    path => $path_up,
    name => (splitdir($path_up))[-1],
    sitename => 'www.test.site.invalid',
);

my $ref_2 = Perl::Dist::WiX::Files::DirectoryRef->new(
    trace => 100,
    directory_object => $dir_up,
    sitename => 'www.test.site.invalid',
);

my $ref_1 = Perl::Dist::WiX::Files::DirectoryRef->new(
    trace => 100,
    directory_object => $dir,
    sitename => 'www.test.site.invalid',
);
ok( $ref_1, '->new returns true' );

    local $SIG{__DIE__};

eval {

    my $ref_2 = Perl::Dist::WiX::Files::DirectoryRef->new(
        directory_object => undef,
        sitename => 'www.test.site.invalid',
    );
};

like( $@, qr(Missing or undefined directory object), '->new catches bad directory object' );

is( $ref_1->get_path, $path, '->get_path' );

# search_dir is tested in 12_directorytree

is ( $ref_1->is_child_of($dir_up), 1, '->is_child_of' );

is ( $ref_1->is_child_of($dir), 0, '->is_child_of identity' );

is ( $ref_2->is_child_of($dir), 0, '->is_child_of unsuccessful' );

eval {
    my $answer = $ref_2->is_child_of(undef);
};

like( $@, qr(Invalid directory object), '->is_child_of catches bad object' );

my $dir_1 = $ref_2->add_directory_path($path);

is ( $dir_1->get_path, $ref_1->get_path, '->add_directory_path' );

eval {
    my $dir_2 = $ref_2->add_directory_path(undef);
};

like( $@, qr(Missing or invalid path), '->add_directory_path catches bad path' );

my $file_1 = $ref_1->add_file(filename => catfile($ref_1->get_path, 'test.txt'), sitename => 'www.test.site.invalid');

ok( $ref_1, '->add_file returns true' );

isnt($ref_1->search_file(catfile($ref_1->get_path, 'test.txt')), undef, '->search_file');

is($ref_2->search_file(catfile($ref_1->get_path, 'test.txt')), undef, '->search_file for file that is not there');

eval {
    my $file_2 = $ref_2->add_file();
};

like( $@, qr(Missing file parameter), '->add_file catches no parameters' );

eval {
    my $file_3 = $ref_2->add_file(filename => undef);
};

like( $@, qr(Missing or invalid file\[1\] parameter), '->add_file catches bad parameters' );

is( scalar $ref_1->get_component_array, 1, '->get_component_array' );

is( scalar $ref_2->get_component_array, 0, '->get_component_array when empty' );

like( $ref_1->as_string, qr(\A<DirectoryRef(?:.*?)<File)ms, '->as_string');

is( $ref_2->as_string, q{}, '->as_string when empty');

is( $ref_1->delete_filenum(0)->as_string, q{}, '->delete_filenum');

eval {
    $ref_2->delete_filenum(-1);
};

like( $@, qr(Missing or invalid index parameter), '->delete_filenum catches invalid parameter' );

eval {
    $ref_2->delete_filenum(1);
};

like( $@, qr(Not enough files), '->delete_filenum catches deleting too much' );

eval {
    $ref_1->delete_filenum(0);
};

like( $@, qr(Already deleted), '->delete_filenum catches deleting file twice' );
