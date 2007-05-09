package ADAMK::Starter;

use 5.005;
use strict;
use Params::Util qw{ _STRING };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

use Object::Tiny qw{
	name
	abstract
	module
	perl_version
	version
	author
	email
	trunk_dir
	dist_dir
	makefile_ok
	changes
	module_pm
	compile_t
	main_t
	};




#####################################################################
# Module::Starter Methods

sub new {
	my $self = shift->SUPER::new(@_);

	# Apply defaults and check params
	unless ( $self->module ) {
		croak("Did not provide a module name");
	}
	unless ( $self->trunk_dir ) {
		croak("Did not provide the trunk directory");
	}
	unless ( -d $self->trunk_dir ) {
		croak("The trunk directory does not exist");
	}
	$self->{perl_version} ||= '5.005';
	$self->{version}      ||= '0.01';
	$self->{abstract}     ||= 'The author of this module is an idiot';
	$self->{author}       ||= 'Adam Kennedy';
	$self->{email}        ||= 'adamk@cpan.org';
	unless ( $self->name ) {
		$self->{name} = $self->module;
		$self->{name} =~ s/::/-/g;
	}
	unless ( $self->{module_path} ) {
		$self->{module_path} = $self->module . '.pm';
		$self->{module_path} =~ s/::/\//g;
	}

	# Derive some additional paths
	$self->{dist_dir} = File::Spec->catdir( $self->trunk_dir, $self->name );
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
	
}

# Create and write the files to the target directory
sub save {
	my $self = shift;

	# Write the Makefile.PL
	my $makefile_pl;
}



#####################################################################
# File Generation

sub create_makefile_pl { my $self = shift; return <<"END_FILE"; }
use strict;
use inc::Module::Install;

name           '$self->{name}';
all_from       'lib/$self->{module_path}';
requires       'Carp'         => 0;
requires       'Params::Util' => '0.20';
build_requires 'Test::More'   => '0.42';

WriteAll;
END_FILE





sub create_module_pm { my $self = shift; return <<"END_FILE"; }
package $self->{module};

=pod

=head1 NAME

$self->{module} - $self->{abstract};

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

$self->{author} E<lt>$self->{email>E<gt>

=head1 COPYRIGHT

Copyright 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

END_FILE





sub create_01_compile_t { my $self = shift; return <<"END_FILE"; }
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





sub create_02_main { my $self = shift; return <<"END_FILE"; }
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
