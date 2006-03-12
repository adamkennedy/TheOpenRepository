#!/usr/bin/perl

# Compile-testing for LVAS

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import('blib', 'lib');
	}
}

use Test::More;

# Skip testing without a server to test
# For Example:
# export TEST_LVAS_SERVER="assimilated.linearg.com,6980,contact,password,domain.com,testacc1,test@test.com"
if ( $ENV{TEST_LVAS_SERVER} and scalar(split /,\s*/, $ENV{TEST_LVAS_SERVER}) == 7) ) {
	plan( 'no_plan' );
} else {
	plan( 'skip_all' );
}

use_ok( 'LVAS' );

my ($host, $port, $login, $password, $domain, $email, $to) = split /,\s*/, $ENV{TEST_LVAS_SERVER};

# Create the client
my $lvas = new LVAS;
isa_ok( $lvas, 'LVAS' );

# Connect to the server
ok( $lvas->connect($host, $port), '->connect returns ok' );

# Login
if ( $lvas->authenticate('contact', 'password') ) {
	diag( "Successful authentication" );
} else {
	skip( "Failed to login", )
}

my $vs_id  = $lvas->locate_vserver($domain);
my $dns_id = $lvas->locate_domain($domain);
ok( $vs_id, '->locate_vserver returns an id' );
ok( $dns_id, '->locate_domain returns an id' );
unless ( $vs_id and $dns_id ) {
	skip( "Failed to find server information", );
}

diag( "Found VServer with ID $vs_id" );
diag( "Found Domain with ID $dns_id" );

@list = $lvas->vserver_list_mail_aliases($vs_id);
diag( "Current mail aliases: );
foreach my $alias ( @list ) {
	diag ( join ',', @$alias );
}

my $rv = $lvas->vserver_create_remote_mail_alias( $vs_id, $dns_id, $email, $to);
ok( $rv, '->vserver_create_remote_mail_alias succeeded' );

@list = $lvas->vserver_list_mail_aliases($vs_id);
diag( "Current mail aliases: );
foreach my $alias ( @list ) {
	diag ( join ',', @$alias );
}

# Test for existance of appropriate redirect

ok( ! $lvas->vserver_remove_mail_alias($vs_id, $dns_id, $email),
	'Removed test account ok' );

ok( $lvas->disconnect, '->disconnect returns true' );
