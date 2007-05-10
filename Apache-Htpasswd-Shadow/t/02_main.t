#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More               tests => 49;
use Test::File::Cleaner      ();
use File::Spec::Functions    ':ALL';
use Apache::Htpasswd::Shadow ();

# Create the file cleaner
my $cleaner = Test::File::Cleaner->new('t');

# Check for the test data files
my $file1 = catfile( 't', 'data', 'passwd1.txt' );
ok( -f $file1, 'Test file 1 exists' );
my $file2 = catfile( 't', 'data', 'passwd2.txt' );
ok( -f $file2, 'Test file 2 exists' );
my $file3 = catfile( 't', 'data', 'passwd3.txt' );
ok( ! -f $file3, 'Test file 3 does not exist' );

sub methods_match {
	my $object1 = shift;
	my $object2 = shift;
	foreach my $method ( @_ ) {
		my $scalar1 = $object1->$method();
		my $scalar2 = $object2->$method();
		my $list1   = [ $object1->$method() ];
		my $list2   = [ $object2->$method() ];
		is_deeply( $scalar1, $scalar2, "Method $method scalar context results match" );
		is_deeply( $list1,   $list2,   "Method $method scalar context results match" );
	}
}

	



#####################################################################
# Check the ReadOnly case

SCOPE: {
	my $auth = Apache::Htpasswd::Shadow->new({
		passwdFile => $file1,
		ReadOnly   => 1,
		} );
	isa_ok( $auth, 'Apache::Htpasswd::Shadow' );
	isa_ok( $auth, 'Apache::Htpasswd'         );
	is(     $auth->passwdFile, $file1, '->passwdFile ok' );
	isa_ok( $auth->passwdObject, 'Apache::Htpasswd' );
	is(     $auth->shadowFile, undef, '->shadowFile ok' );
	is(     $auth->shadowObject, undef, '->shadowObject ok' );
	isa_ok( $auth->object, 'Apache::Htpasswd' );
	is(     $auth->error,         '', '->error ok' );
	is(     $auth->object->error, '', '->error ok' );

	ok( $auth->htCheckPassword('adam', 'adam'), '->htCheckPassword ok' );
	ok( ! $auth->htCheckPassword('adam', 'bad'), '->htCheckPassword negative ok' );
}





#####################################################################
# Read-Write with the shadow already existing

SCOPE: {
	my $auth = Apache::Htpasswd::Shadow->new({
		passwdFile => $file1,
		shadowFile => $file2,
		} );
	isa_ok( $auth, 'Apache::Htpasswd::Shadow' );
	isa_ok( $auth, 'Apache::Htpasswd'         );
	is(     $auth->passwdFile, $file1, '->passwdFile ok' );
	is(     $auth->passwdObject, undef, '->passwdObject ok' );
	is(     $auth->shadowFile, $file2, '->shadowFile ok' );
	isa_ok( $auth->shadowObject, 'Apache::Htpasswd' );
	isa_ok( $auth->object,       'Apache::Htpasswd' );

	ok( $auth->htCheckPassword('adam', 'adam'), '->htCheckPassword ok' );
	ok( ! $auth->htCheckPassword('adam', 'bad'), '->htCheckPassword negative ok' );
}





#####################################################################
# Read-Write where the shadow does not exist

SCOPE: {
	my $auth = Apache::Htpasswd::Shadow->new({
		passwdFile => $file1,
		shadowFile => $file3,
		} );
	ok( -f $file3, 'Shadow file was created' );
	isa_ok( $auth, 'Apache::Htpasswd::Shadow' );
	isa_ok( $auth, 'Apache::Htpasswd'         );
	is(     $auth->passwdFile, $file1, '->passwdFile ok' );
	is(     $auth->passwdObject, undef, '->passwdObject ok' );
	is(     $auth->shadowFile, $file3, '->shadowFile ok' );
	isa_ok( $auth->shadowObject, 'Apache::Htpasswd' );
	isa_ok( $auth->object,       'Apache::Htpasswd' );

	ok( $auth->htCheckPassword('adam', 'adam'), '->htCheckPassword ok' );
	ok( ! $auth->htCheckPassword('adam', 'bad'), '->htCheckPassword negative ok' );

	# Add a key
	is( scalar($auth->fetchUsers), 1, 'File has one account' );
	ok( ! $auth->htCheckPassword('foo', 'bar'), 'Test account foo does not exist');
	ok( $auth->htpasswd('foo', 'bar'), 'Added test account' );
	is( scalar($auth->fetchUsers), 2, 'File has two accounts' );
	ok( $auth->htCheckPassword('foo', 'bar'), '->htCheckPassword for new account ok' );
	ok( ! $auth->htCheckPassword('foo', 'baz'), 'Negative case works ok' );
}






#####################################################################
# Read-Write where the shadow does not exist (default name)

SCOPE: {
	my $auth = Apache::Htpasswd::Shadow->new({
		passwdFile => $file1,
		} );
	ok( -f "$file1.new", 'Shadow file was created' );
	isa_ok( $auth, 'Apache::Htpasswd::Shadow' );
	isa_ok( $auth, 'Apache::Htpasswd'         );
	is(     $auth->passwdFile, $file1, '->passwdFile ok' );
	is(     $auth->passwdObject, undef, '->passwdObject ok' );
	is(     $auth->shadowFile, "$file1.new", '->shadowFile ok' );
	isa_ok( $auth->shadowObject, 'Apache::Htpasswd' );
	isa_ok( $auth->object,       'Apache::Htpasswd' );

	ok( $auth->htCheckPassword('adam', 'adam'), '->htCheckPassword ok' );
	ok( ! $auth->htCheckPassword('adam', 'bad'), '->htCheckPassword negative ok' );
}

1;
