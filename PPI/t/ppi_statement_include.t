#!/usr/bin/perl

# Unit testing for PPI, generated by Test::Inline

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$|  = 1;
	$^W = 1;
	$PPI::XS_DISABLE = 1;
	$PPI::XS_DISABLE = 1; # Prevent warning
}
use PPI;

# Execute the tests
use Test::More tests => 9;

# =begin testing module_version 9
{
my $document = PPI::Document->new(\<<'END_PERL');
use Integer::Version 1;
use Float::Version 1.5;
use Version::With::Argument 1 2;
use No::Version;
use No::Version::With::Argument 'x';
use No::Version::With::Arguments 1, 2;
use 5.005;
END_PERL

isa_ok( $document, 'PPI::Document' );
my $statements = $document->find('PPI::Statement::Include');
is( scalar @{$statements}, 7, 'Found expected include statements.' );
is( $statements->[0]->module_version(), 1, 'Integer version' );
is( $statements->[1]->module_version(), 1.5, 'Float version' );
is( $statements->[2]->module_version(), 1, 'Version and argument' );
is( $statements->[3]->module_version(), undef, 'No version, no arguments' );
is( $statements->[4]->module_version(), undef, 'No version, with argument' );
is( $statements->[5]->module_version(), undef, 'No version, with arguments' );
is( $statements->[6]->module_version(), undef, 'Version include, no module' );
}


1;
