#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use File::Spec::Functions qw(catfile);

BEGIN {
	if ( $^O eq 'MSWin32' ) {
		plan tests => 6;
	} else {
		plan skip_all => 'Not on Win32';
	}
}

use_ok( 'Perl::Dist::WiX::Filelist' );

is( Perl::Dist::WiX::Filelist->new->add_file('C:\\test.txt')->as_string, 
    'C:\\test.txt',
    'adding single file' );

my @files = ('C:\\test3.txt', 'C:\\test4.txt');

is( Perl::Dist::WiX::Filelist->new->load_array(@files)->as_string, 
    "C:\\test3.txt\nC:\\test4.txt",
    'adding array' );
    
my $add1 = Perl::Dist::WiX::Filelist->new->add_file('C:\\test5.txt');
my $add2 = Perl::Dist::WiX::Filelist->new->add_file('C:\\test6.txt');

is( $add1->add($add2)->as_string,
    "C:\\test5.txt\nC:\\test6.txt",
    'addition' );
    
my $sub1 = Perl::Dist::WiX::Filelist->new->add_file('C:\\test7.txt')->add_file('C:\\test8.txt')
    ->add_file('C:\\test9.txt');
my $sub2 = Perl::Dist::WiX::Filelist->new->add_file('C:\\test8.txt');

is( $sub1->subtract($sub2)->as_string,
    "C:\\test7.txt\nC:\\test9.txt",
    'subtraction' );

my $filter = Perl::Dist::WiX::Filelist->new->add_file('C:\\test10.txt')->add_file('D:\\test11.txt')
    ->add_file('C:\\test12.txt')->add_file('C:\excluded\test13.txt')->add_file('D:\\test14.txt');
my @filters = ('D:\\', 'C:\\excluded');

is( $filter->filter(@filters)->as_string,
    "C:\\test10.txt\nC:\\test12.txt",
    'filtering'); 
    
