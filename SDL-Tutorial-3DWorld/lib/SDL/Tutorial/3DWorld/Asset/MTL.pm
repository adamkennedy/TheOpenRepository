package SDL::Tutorial::3DWorld::Asset::MTL;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::Asset::MTL - Support for loading material libraries from MTL files

=head1 SYNOPSIS

  # Create the object but don't load anything
  my $mtl = SDL::Tutorial::3DWorld::Asset::MTL->new(
      file => 'mymaterials.mtl',
  );
  
  # Locate a material in the library
  $mtl->material('glass');

=head1 DESCRIPTION

B<SDL::Tutorial::3DWorld::Asset::MTL> provides a basic implementation of an
MTL file parser. MTL files are libraries of material (surface) definitions
to be consumed (by name) by OBJ models.

Given a file name, it will load the file and parse the contents into an
abstract set of material objects. However, no dependency files or textures
of the materials are loaded. Any materials that you use on real models
will need to be initialised before the objects they are applied to are
displayed.

The current implementation is extremely preliminary and functionality will
be gradually fleshed out over time.

=cut

use 5.008;
use strict;
use warnings;
use IO::File                        ();
use File::Spec                      ();
use OpenGL                          ':all';
use OpenGL::List                    ();
use SDL::Tutorial::3DWorld::Model   ();
use SDL::Tutorial::3DWorld::Texture ();
use SDL::Tutorial::3DWorld::Asset   ();


our $VERSION = '0.21';





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check param
	my $file  = $self->file;
	unless ( -f $file ) {
		die "The model file '$file' does not exists";
	}

	# Bootstrap a asset if we were not passed one.
	unless ( $self->{asset} ) {
		my $directory = $self->file;
		$directory =~ s/[\w\._-]+$//;
		$self->{asset} = SDL::Tutorial::3DWorld::Asset->new(
			directory => $directory,
		);
	}
	unless ( _INSTANCE($self->asset, 'SDL::Tutorial::3DWorld::Asset') ) {
		die "Missing or invalid asset";
	}

	# We start with an empty material library
	$self->{material} = { };

	return $self;
}

sub file {
	$_[0]->{file}
}

sub asset {
	$_[0]->{asset};
}

sub list {
	$_[0]->{list};
}





######################################################################
# Main Methods

sub material {
	# Fetch a material from the library
	die "CODE INCOMPLETE";
}

sub init {
	my $self   = shift;
	my $handle = IO::File->new( $self->file, 'r' );
	$self->parse( $handle );
	$handle->close;
	return 1;
}





######################################################################
# Parsing

sub parse {
	my $self   = shift;
	my $handle = shift;

	# Parser state
	my $material = undef;

	# Parse the file
	while ( 1 ) {
		my $line = $handle->getline;
		last unless defined $line;

		# Remove blank lines, trailing whitespace and comments
		$line =~ s/\s*(?:#.+)[\012\015]*\z//;
		$line =~ m/\S/ or next;

		# Parse the dispatch the line
		my @words   = split /\s+/, $line;
		my $command = lc shift @words;
		if ( $command eq 'newmtl' ) {
			$material = { };
			$self->{material}->{$words[0]} = $material;

		} else {
			# Ignore unsupported lines
		}
	}

	return 1;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=OpenGL-RWX>

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<OpenGL>

=head1 COPYRIGHT

Copyright 2010 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
