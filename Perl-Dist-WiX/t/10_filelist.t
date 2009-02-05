#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use File::Spec::Functions qw(catfile curdir catdir rel2abs);

my @file = (
    catfile( rel2abs(curdir()), qw(t test10 file1.txt)),
    catfile( rel2abs(curdir()), qw(t test10 file2.txt)),
    catfile( rel2abs(curdir()), qw(t test10 file3.txt)),
    catfile( rel2abs(curdir()), qw(t test10 excluded file1.txt)),
    catfile( rel2abs(curdir()), qw(t test10 excluded file2.txt)),    
);

BEGIN {
	if ( $^O eq 'MSWin32' ) {
		plan tests => 6;
	} else {
		plan skip_all => 'Not on Win32';
	}
}

use_ok( 'Perl::Dist::WiX::Filelist' );

is( Perl::Dist::WiX::Filelist->new->add_file($file[0])->as_string, 
    $file[0],
    'adding single file' );

my @files = @file[1, 2];

is( Perl::Dist::WiX::Filelist->new->load_array(@files)->as_string, 
    "$file[1]\n$file[2]",
    'adding array' );
    
my $add1 = Perl::Dist::WiX::Filelist->new->add_file($file[0]);
my $add2 = Perl::Dist::WiX::Filelist->new->add_file($file[1]);

is( $add1->add($add2)->as_string,
    "$file[0]\n$file[1]",
    'addition' );
    
my $sub1 = Perl::Dist::WiX::Filelist->new->add_file($file[0])->add_file($file[1])
    ->add_file($file[2]);
my $sub2 = Perl::Dist::WiX::Filelist->new->add_file($file[1]);

is( $sub1->subtract($sub2)->as_string,
    "$file[0]\n$file[2]",
    'subtraction' );

my $filter = Perl::Dist::WiX::Filelist->new->load_array(@file);
my $re = catdir( rel2abs(curdir()), qw(t test10 excluded));

is( $filter->filter([$re])->as_string,
    "$file[0]\n$file[1]\n$file[2]",
    'filtering'); 
    
