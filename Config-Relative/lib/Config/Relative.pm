package Config::Relative;

=pod

=head1 NAME

Config::Relative - Add file path awareness to configuration files

=head1 SYNOPSIS

  ###################################################################
  # Configuration File
  
  ---
  template_dir: templates
  foo_templates: foo
  
  other_stuff:
    - one
    - two
  
  
  
  ###################################################################
  # Configuration Class
  
  package Foo::Bar;
  
  use strict;
  use base 'Config::Relative';
  
  sub driver { 'YAML::Tiny' }
  
  # Defaults to 'Foo-Bar.conf'
  sub config_file_default { 'foo.conf' }
  
  sub config_root_default { '/etc/foo' }
  
  sub template_dir {
      $_[0]->relative_dir( $_[0]->root => $_[0]->{template_dir} );
  }
  
  sub foo_templates {
      $_[0]->relative_dir( $_[0]->template_dir, $_[0]->{foo_templates} );
  }
  
  sub cache_dir {
      $_[0]->relative_dir( $_[0]->root => $_[0]->{cache_dir} );
  }
  
  1;
  
  
  
  ###################################################################
  # Using the class
  
  # All of these do the same thing
  $config = Foo::Bar->new( config_file => '/etc/foo/foo.conf' );
  $config = Foo::Bar->new( config_root => '/etc/foo'          );
  $config = Foo::Bar->new;

=head1 DESCRIPTION

When working with configuration files for applications that need to
interact with the local disk, there is a common problem when dealing
with relative file-system paths.

B<Config::Relative> provides a base class that implements a collection
of standard functionality to allow you to use relative paths in
configuration files.

The main focus of the implementation is to ensure that absolute paths
are used as much as possible.

To this end, anything relative to the current system directory will
be resolved at the time you create the configuration object. Once the
object exists, all functionality will be stable and continue to work
if the current system directory chances.

=head2 Supported Drivers

The C<driver> method is used to indicate the class to be used to load
the actual configuration content.

Currently, L<Config::Tiny> and L<YAML::Tiny> are known to work.

Any other module that can be called as C<Class-E<gt>read( $filename )>
and returns a HASHLIKE structure should also work. Further small hooks
will be added as needed to support other backend config drivers.

=head2 Ordering of Defaults

Each B<Config::Relative> object needs to know two things. Firstly, the
file from which to load the configuration, and secondly the "root path"
to be used as the default for relative paths within the configuration
file.

Both are converted to absolute paths in all cases, using the current
system directory as a base.

If both are provided, nothing needs to be done.

If only a config file name is provided, the root is taken to be the
directory that contains the configuration file.

If only a root path is provided, the C<config_file_default> method is
called and apended to determine the expected config file name.

If neither is provided, the C<config_root_default> method is called
and used as the root path, and then C<config_file_default> method called
for the expected config file location.

=head1 METHODS

=cut

use 5.005;
use strict;
use Carp           ();
use File::Spec     ();
use File::Basename ();
use File::HomeDir  ();
use Params::Util   qw{
	_STRING
	_IDENTIFIER
	_CLASS
	_HASHLIKE
	_INSTANCE
	};

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}





#####################################################################
# Configuration Class Methods

=pod

=head2 config_root_default

The C<config_root_default> method is used to set the root path to use
if the location of the config file needs to be intuited.

By default, the home directory of the current user will be used, as
determined by L<File::HomeDir>.

=cut

sub config_root_default {
	File::HomeDir->home;
}

=pod

=head2 config_file_default

  sub config_file_default { 'myconfig.conf' }

The C<config_file_default> method is used to specific the default file
name for the config file.

This should not contain any path elements, and be just the name of the
file itself.

=cut

sub config_file_default {
	my $class = ref $_[0] || $_[0];
	my $file  = $class . '.conf';
	$file =~ s/::/-/g;
	return $file;
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;

	# Create the object
	my $self = bless { @_ }, $class;

	# Check the content driver class
	unless ( _DRIVER($self->config_driver) ) {
		Carp::croak(
			"Missing, invalid, or broken class '"
			. $self->config_driver
			. "'"
		);
	}

	# Apply the root/file detault logic
	unless ( $self->config_root or $self->config_file ) {
		# If we have neither root or file,
		# use the default root directory.
		my $config_root = $class->config_root_default;
		unless ( File::Spec->file_name_is_absolute($config_root) ) {
			my $home = _STRING(File::HomeDir->home)
				or die "Failed to locate home directory";
			$config_root = File::Spec->catdir( $home, $config_root );
		}		
	}
	if ( $self->config_root ) {
		# Make any passed-in root param absolute
		$self->{config_root} = File::Spec->rel2abs( $self->config_root );
	}
	if ( $self->config_file ) {
		# Make any passed-in file param absolute
		$self->{config_file} = File::Spec->rel2abs( $self->config_file );
	}
	if ( $self->config_root and ! $self->config_file ) {
		# If only the root is provided, intuit the config file name
		$self->{config_file} = $class->config_file_default;
		unless ( File::Spec->file_name_is_absolute($self->config_file) ) {
			$self->{config_file} = File::Spec->catfile(
				$self->config_root, $self->config_file,
				);
		}
	}
	if ( $self->config_file and ! $self->config_root ) {
		# If only the config file is provided,
		# use the directory it is in as the root.
		$self->{config_root} = File::Basename::dirname( $self->config_file );
	}

	# Check the config file/root
	unless ( -d $self->config_root ) {
		Carp::croak("The root directory '" . $self->config_root . "' does not exist");
	}
	unless ( -f $self->config_file ) {
		Carp::croak("The config file '" . $self->config_file . "' does not exist");
	}

	# Load the config file data structure
	my $data = $self->config_driver->read( $self->config_file );
	Carp::croak(
		$self->config_driver
		. " failed to load '"
		. $self->config_file
		. "'"
	) unless $data;
	if ( _INSTANCE($data, 'YAML::Tiny') ) {
		# Handle a known special case
		$data = $data->[0];
	}
	unless ( _HASHLIKE($data) ) {
		my $config_driver = $self->config_driver;
		Carp::croak("Data structure returned by $config_driver->read must be HASH-like");
	}

	# Suck the contents of the data structure into our object
	# If we have a key already, don't overwrite it.
	%$self = ( %$data, %$self );

	return $self;
}

sub config_driver {
	$_[0]->{config_driver};
}

sub config_root {
	$_[0]->{config_root};
}

sub config_file {
	$_[0]->{config_file};
}





#####################################################################
# Main Methods

sub relative_dir {
	my $self = shift;
	my $path = _STRING(shift) or Carp::croak("Invalid dir path to relative_dir");
	if ( File::Spec->file_name_is_absolute($path) ) {
		return $path;
	}

	# Apply a relative path to the base
	my $base = @_ ? shift : $self->config_root;
	unless ( _STRING($base) ) {
		Carp::croak("Invalid base path to relative_dir");
	}
	return File::Spec->catdir( $base, $path );
}

sub relative_file {
	my $self = shift;
	my $path = _STRING(shift) or Carp::croak("Invalid dir path to relative_dir");
	if ( File::Spec->file_name_is_absolute($path) ) {
		return $path;
	}

	# Apply a relative path to the base
	my $base = @_ ? shift : $self->config_root;
	unless ( _STRING($base) ) {
		Carp::croak("Invalid base path to relative_dir");
	}
	return File::Spec->catdir( $base, $path );
}





#####################################################################
# Support Methods

sub _DRIVER {
	# Now check the class itself
	return (
		_CLASS($_[0])
		and
		eval "require $_[0]"
		and
		$@ eq ''
		and
		$_[0]->VERSION
		and
		$_[0]->can('read')
	) ? $_[0] : undef;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracking system

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-Relative>

For other inquiries, contact the author

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Config::Tiny>, L<YAML::Tiny>

=head1 COPYRIGHT

Copyright 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

