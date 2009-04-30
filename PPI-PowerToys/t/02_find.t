#!/usr/bin/perl

# Compile-testing for Perl::PowerToys

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 6;
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

# Single-Quote vars
version_is( <<'END_PERL', '0.01', q{$VERSION = '0.01'} );
use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}
END_PERL

# Double-Quote vars
version_is( <<'END_PERL', '0.01', q{$VERSION = "0.01"} );
use vars qw{$VERSION};
BEGIN {
	$VERSION = "0.01";
}
END_PERL

# Numeric vars
version_is( <<'END_PERL', '0.01', q{$VERSION = 0.01} );
use vars qw{$VERSION};
BEGIN {
	$VERSION = 0.01;
}
END_PERL

# Single-Quote our
version_is( <<'END_PERL', '0.01', q{our $VERSION = '0.01'} );
our $VERSION = '0.01';
END_PERL

# Double-Quote our
version_is( <<'END_PERL', '0.01', q{our $VERSION = "0.01"} );
our $VERSION = "0.01";
END_PERL

# Numeric our
version_is( <<'END_PERL', '0.01', q{our $VERSION = 0.01} );
our $VERSION = 0.01;
END_PERL
