#!/usr/bin/perl

use strict;
use warnings;
use lib q(C:\Dokumente und Einstellungen\Renee\Eigene Dateien\Perl\cpan\Business-Telstra-PhoneBill-Download\lib);
use FindBin ();
use lib "$FindBin::Bin";
use Business::Telstra::PhoneBill::Download;

# Where to save the CSV file
my $save_path = File::Spec->catfile( 't', 'module_test.csv' );
unlink $save_path if -e $save_path;
END { unlink $save_path if -e $save_path }


my $downloader = Business::Telstra::PhoneBill::Download->new();
isa_ok( $downloader, 'Business::Telstra::PhoneBill::Download' );

SKIP: {
	unless ( $ENV{TEST_ACCOUNT} and $ENV{TEST_PASSWORD} ) {
		skip("Skipping, no test account", 4);
	}
	$downloader->user('geomick1');
	$downloader->password('micksols');
	
	$downloader->account(2);
	
	$downloader->download();

	$downloader->save_as('module_test.csv');
}
