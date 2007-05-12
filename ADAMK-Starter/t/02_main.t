#!/usr/bin/perl

# Main testing

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 22;
use File::Spec::Functions ':ALL';
use ADAMK::Starter        ();

# Check and clean the test directory
my $trunk   = File::Spec->catdir( 't', 'data' );
ok( -d $trunk, 'Output directory exists' );





#####################################################################
# Main Tests

SCOPE: {
	my $starter = ADAMK::Starter->new(
		module => 'Foo::Bar',
		trunk  => $trunk,
	);
	isa_ok( $starter, 'ADAMK::Starter' );
	is( $starter->module,       'Foo::Bar',       '->module ok'       );
	is( $starter->trunk,        rel2abs($trunk),  '->trunk ok'        );
	is( $starter->perl_version, '5.005',          '->perl_version ok' );
	is( $starter->version,      '0.01',           '->version ok'      );
	is(
		$starter->abstract,
		'The author of the module is an idiot',
		'->abstract ok',
	);
	is( $starter->author,       'Adam Kennedy',   '->author ok'       );
	is( $starter->email,        'adamk@cpan.org', '->email ok'        );
	is( $starter->name,         'Foo-Bar',        '->name ok'         );
	is(
		$starter->module_path,
		'Foo/Bar.pm',
		'->module_path ok',
	);
	is(
		$starter->dist_dir,
		rel2abs(catfile(qw(t data Foo-Bar))),
		'->dist_dir ok',
	);
	is(
		$starter->makefile_pl,
		rel2abs(catfile(qw(t data Foo-Bar Makefile.PL))),
		'->makefile_pl ok',
	);
	is(
		$starter->changes,
		rel2abs(catfile(qw(t data Foo-Bar Changes))),
		'->changes ok',
	);
	is(
		$starter->module_pm,
		rel2abs(catfile(qw(t data Foo-Bar lib Foo Bar.pm))),
		'->module_pm ok',
	);
	is(
		$starter->compile_t,
		rel2abs(catfile(qw(t data Foo-Bar t 01_compile.t))),
		'->compile_t ok',
	);
	is(
		$starter->main_t,
		rel2abs(catfile(qw(t data Foo-Bar t 02_main.t))),
		'->mail_t ok',
	);

	# Check the generation of Makefile.PL
	is( $starter->makefile_pl_content, <<'END_FILE', '->create_makefile_pl ok' );
use strict;
use inc::Module::Install;

name           'Foo-Bar';
all_from       'lib/Foo/Bar.pm';
requires       'Carp'         => 0;
requires       'Params::Util' => '0.20';
build_requires 'Test::More'   => '0.42';

WriteAll;
END_FILE

	# Check the generation of the changes file
	my $string = Date::Tiny->now->as_string;
	is( $starter->changes_content, <<"END_FILE", '->create_changes ok' );
Changes for Perl extension Foo-Bar

0.01 $string
	- Creating initial version
END_FILE

	# Check the generation of the main module file
	my $got_module = [ split /\n/, $starter->module_pm_content ];
	my $exp_module = [ split /\n/, <<'END_FILE' ];
package Foo::Bar;

=pod

=head1 NAME

Foo::Bar - The author of the module is an idiot

=head1 SYNOPSIS

  The author is an idiot who forgot to write the synopsis

=head1 DESCRIPTION

The author is an idiot who forgot to write the description

=head1 METHODS

=cut

use 5.005;
use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new

The author is an idiot that forgot to write the docs for the new method

=cut

sub new {
	my $class = shift;

	# Create the object
	my $self = bless { @_ }, $class;

	# Check params
	die "CODE INCOMPLETE";

	return $self;
}





#####################################################################
# Main Methods

1;

=pod

=head1 SUPPORT

No support is available for this module

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
END_FILE
	is_deeply( $got_module, $exp_module, '->create_module_pm ok' );

	# Check the creation of the 01_compile.t file
	is( $starter->compile_t_content, <<'END_FILE', '->create_compile_t' );
#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

ok( $] <= 5.005, 'Perl version is new enough' );

use_ok( 'Foo::Bar' );

END_FILE

	# Check the creation of the 02_main.t file
	is( $starter->main_t_content, <<'END_FILE', '->create_main_t' );
#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 1;
use Foo::Bar;





#####################################################################
# Main Tests

ok( 0, 'The author forgot to write any tests' );

END_FILE

}
