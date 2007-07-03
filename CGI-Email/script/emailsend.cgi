#!/usr/bin/perl

use 5.005;
use strict;
use FindBin    ();
use File::Spec ();
use YAML::Tiny ();
use CGI::Email ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

my $config_file = File::Spec->catfile( $FindBin::Bin, 'emailsend.conf' );
unless ( -f $config_file ) {
	die "Failed to find config file";
}
my $config = YAML::Tiny->read( $config_file );
unless ( $config ) {
	die "Failed to load config file";
}
$config = $config->[0];

my $mailer = CGI::Email->new( 
