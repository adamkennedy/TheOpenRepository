package ADAMK::Starter;

use 5.005;
use strict;
use Getopt::Long ();
use Params::Util qw{ _STRING _INSTANCE };
use Date::Tiny   ();
use File::Flat   ();

use vars qw{$VERSION @ISA @EXPORT};
BEGIN {
	require Exporter;
	$VERSION = '0.01';
	@ISA     = qw{ Exporter Object::Tiny };
	@EXPORT  = qw{ main };
}

use Object::Tiny qw{
	name
	abstract
	module
	perl_version
	version
	author
	email
	date
	trunk
	dist_dir
	module_path
	makefile_pl
	changes
	module_pm
	compile_t
	main_t
	};





#####################################################################
# Main Functions

sub import {
	main();
}

sub main {
	# Parse the command line options
	my %params = ();
	Getopt::Long::GetOptions(
		'name=s'         => \$params{name},
		'module=s'       => \$params{module},
		'abstract=s'     => \$params{abstract},
		'version=s'      => \$params{version},
		'perl_version=s' => \$params{perl_version},
		'author=s'       => \$params{author},
		'email=s'        => \$params{email},
		'verbose'        => \$params{verbose},
	);

	# Create the starter object
	my $starter = ADAMK::Starter->new( %params );
	unless ( _INSTANCE($starter, 'ADAMK::Starter') ) {
		error("Failed to create ADAMK::Starter object");
	}

	# Run the main method
	eval { $starter->run };
	error( $@ ) if $@;

	exit(0);
}

sub error {
	my $message = shift;
	$message =~ s/\s+at\s+line\s.+$//;
	print "\nError: $message\n\n";
	exit(255);
}





#####################################################################
# Module::Starter Methods

sub new {
	my $self = shift->SUPER::new(@_);

	# Apply defaults and check params
	unless ( $self->module ) {
		croak("Did not provide a module name");
	}
	unless ( $self->trunk ) {
		croak("Did not provide the trunk directory");
	}
	unless ( -d $self->trunk ) {
		croak("The trunk directory does not exist");
	}
	$self->{trunk} = File::Spec->rel2abs( $self->trunk );
	$self->{perl_version} ||= '5.005';
	$self->{version}      ||= '0.01';
	$self->{abstract}     ||= 'The author of the module is an idiot';
	$self->{author}       ||= 'Adam Kennedy';
	$self->{email}        ||= 'adamk@cpan.org';
	$self->{date}         ||= Date::Tiny->now;
	unless ( _INSTANCE($self->date, 'Date::Tiny') ) {
		croak("Did not provide a Date::Tiny value for ->date");
	}
	$self->{date} = $self->date->as_string;
	unless ( $self->name ) {
		$self->{name} = $self->module;
		$self->{name} =~ s/::/-/g;
	}
	unless ( $self->{module_path} ) {
		$self->{module_path} = $self->module . '.pm';
		$self->{module_path} =~ s/::/\//g;
	}

	# Derive some additional paths
	$self->{dist_dir} = File::Spec->catdir( $self->trunk, $self->name );
	if ( -d $self->dist_dir ) {
		croak("The dist directory " . $self->dist_dir . " already exists");
	}
	$self->{makefile_pl} = File::Spec->catfile( $self->dist_dir, 'Makefile.PL'             );
	$self->{changes}     = File::Spec->catfile( $self->dist_dir, 'Changes'                 );
	$self->{module_pm}   = File::Spec->catfile( $self->dist_dir, 'lib', $self->module_path );
	$self->{compile_t}   = File::Spec->catfile( $self->dist_dir, 't', '01_compile.t'       );
	$self->{main_t}      = File::Spec->catfile( $self->dist_dir, 't', '02_main.t'          );

	return $self;
}





#####################################################################
# Main Methods

sub run {
	my $self = shift;

	File::Flat->write(
		$self->makefile_pl,
		$self->makefile_pl_content,
	);
	File::Flat->write(
		$self->changes,
		$self->changes_content,
	);
	File::Flat->write(
		$self->module_pm,
		$self->module_pm_content,
	);
	File::Flat->write(
		$self->compile_t,
		$self->compile_t_content,
	);
	File::Flat->write(
		$self->main_t,
		$self->main_t_content,
	);

	return 1;
}





#####################################################################
# File Generation

sub makefile_pl_content { my $self = shift; return <<"END_FILE"; }
use strict;
use inc::Module::Install;

name           '$self->{name}';
all_from       'lib/$self->{module_path}';
requires       'Carp'         => 0;
requires       'Params::Util' => '0.20';
build_requires 'Test::More'   => '0.42';

WriteAll;
END_FILE





sub changes_content { my $self = shift; return <<"END_FILE"; }
Changes for Perl extension $self->{name}

0.01 $self->{date}
	- Creating initial version
END_FILE





sub module_pm_content { my $self = shift; return <<"END_FILE"; }
package $self->{module};

=pod

=head1 NAME

$self->{module} - $self->{abstract}

=head1 SYNOPSIS

  The author is an idiot who forgot to write the synopsis

=head1 DESCRIPTION

The author is an idiot who forgot to write the description

=head1 METHODS

=cut

use $self->{perl_version};
use strict;

use vars qw{\$VERSION};
BEGIN {
	\$VERSION = '$self->{version}';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new

The author is an idiot that forgot to write the docs for the new method

=cut

sub new {
	my \$class = shift;

	# Create the object
	my \$self = bless { \@_ }, \$class;

	# Check params
	die "CODE INCOMPLETE";

	return \$self;
}





#####################################################################
# Main Methods

1;

=pod

=head1 SUPPORT

No support is available for this module

=head1 AUTHOR

$self->{author} E<lt>$self->{email}E<gt>

=head1 COPYRIGHT

Copyright 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

END_FILE





sub compile_t_content { my $self = shift; return <<"END_FILE"; }
#!/usr/bin/perl

use strict;
BEGIN {
	\$|  = 1;
	\$^W = 1;
}

use Test::More tests => 2;

ok( \$] <= $self->{perl_version}, 'Perl version is new enough' );

use_ok( '$self->{module}' );

END_FILE





sub main_t_content { my $self = shift; return <<"END_FILE"; }
#!/usr/bin/perl

use strict;
BEGIN {
	\$|  = 1;
	\$^W = 1;
}

use Test::More tests => 1;
use $self->{module};





#####################################################################
# Main Tests

ok( 0, 'The author forgot to write any tests' );

END_FILE

1;
