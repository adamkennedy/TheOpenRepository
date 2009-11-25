#!/usr/bin/perl

use strict;
use warnings 'all';
BEGIN {
	$|  = 1;
}

use Test::More tests => 9;
use Test::NoWarnings;
use File::Spec::Functions ':ALL';
use CPAN::Mini::Visit ();

my $minicpan = {
	local        => catdir('t', 'minicpan'),
	remote       => 'http://cpan.strawberryperl.com/',
	offline      => 1,
	skip_cleanup => 1,
};
ok( -d $minicpan->{local}, "Found root minicpan '$minicpan->{local}'" );

my @data  = ();
my $visit = new_ok( 'CPAN::Mini::Visit' => [
	minicpan => $minicpan,
	ignore   => [ qr/\bFile\b/ ],
	callback => sub {
		push @data, { %{ $_[0] } };
	},
	callback_before_extract => sub {
	        return 0 if $_[0]->{'author'} eq 'ADAMK';
	        return 1;
	},
] );

# Kick off the visit
ok( $visit->run, '->run ok' );

# Do a detailed check of the results
is( scalar(@data), 1, 'Triggered one visit' );
ok( -f $data[0]->{archive} );
is( $data[0]->{author}, 'ANDYA' );
is( $data[0]->{dist}, 'ANDYA/HTML-Tiny-1.05.tar.gz' );
ok( ! -d $data[0]->{tempdir} );
