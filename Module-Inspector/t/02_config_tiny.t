#!/usr/bin/perl -w

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 16;
use Module::Inspector;

my $tarball = catfile( 't', 'dists', 'Config-Tiny-2.09.tar.gz' );
ok( -f $tarball, "Tarball file $tarball exists"      );
ok( -r $tarball, "Tarball file $tarball is readable" );





#####################################################################
# Create the handle

SCOPE: {
	my $mod = Module::Inspector->new( dist_file => $tarball );
	isa_ok( $mod, 'Module::Inspector' );
	is( $mod->dist_file, $tarball, '->dist_file ok' );
	is( $mod->dist_file_type, 'tgz', '->dist_file_type ok' );
	ok( -d $mod->dist_dir, '->dist_dir exists' );
	is( $mod->version_control, '', '->version_control is null' );
	my @docs = grep { ! /^inc\b/ } $mod->documents;
	is_deeply( \@docs, [qw{
		META.yml
		Makefile.PL
		lib/Config/Tiny.pm
		t/00_compile.t
		t/01_main.t
		t/99_pod.t
		}], '->documents ok' );

	# Check YAML support
	is( $mod->document_type('META.yml'), 'YAML::Tiny', '->document_type(YAML) ok' );
	isa_ok( $mod->document('META.yml'), 'YAML::Tiny' );
	is( $mod->document_type('META.yml'), 'YAML::Tiny', '->document_type(YAML) ok' );
	isa_ok( $mod->document('META.yml'), 'YAML::Tiny' );

	# Check Perl support
	is( $mod->document_type('Makefile.PL'), 'PPI::Document::File', '->document_type(Perl) ok' );
	isa_ok( $mod->document('Makefile.PL'), 'PPI::Document::File' );
	is( $mod->document_type('Makefile.PL'), 'PPI::Document::File', '->document_type(Perl) ok' );
	isa_ok( $mod->document('Makefile.PL'), 'PPI::Document::File' );
}
