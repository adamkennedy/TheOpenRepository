#!/usr/bin/perl

# Compile-testing for Perl::PowerToys

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use PPI;
use PPI::App::ppi_version ();

sub version_is {
        my $string   = shift;
        my $version  = shift;
        my $message  = shift || "Found version $version";
	my $document = PPI::Document->new( \$string );
	my $elements = $document->find( \&PPI::App::ppi_version::_find_version );
	is_deeply(
		[
			map { PPI::App::ppi_version::_get_version($_) }
			@$elements,
		],
		[ $version ],
		$message,
	);
}

# Check ADAMK's normal style
version_is( <<'END_PERL', '0.01', "\$VERSION = '0.01'; ok" );
use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}
END_PERL

# Check Padre's style
version_is( <<'END_PERL', '0.21', "our \$VERSION = 0.21; ok" );
our $VERSION = 0.21;
END_PERL
