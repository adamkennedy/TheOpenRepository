package SDL::Tutorial::3DWorld::Model;

=pod

=head1 NAME

SDL::Tutorial::3DWorld::Model - Generic support for on disk model files

=head1 SYNOPSIS

  # Create the object but don't load anything
  my $model = SDL::Tutorial::3DWorld::Model->new(
      file => 'mymodel.rwx',
  );
  
  # Load the model into OpenGL
  $model->init;
  
  # Render the model into the current scene
  $model->display;

=head1 DESCRIPTION

B<SDL::Tutorial::3DWorld::Model> provides shared functionality across all
of the different model file implementations.

=cut

use 5.008;
use strict;
use warnings;
use IO::File                       ();
use Params::Util                   '_INSTANCE';
use SDL::Tutorial::3DWorld::Asset  ();
use SDL::Tutorial::3DWorld::OpenGL ();

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

sub init {
	my $self   = shift;
	my $handle = IO::File->new( $self->file, 'r' );
	$self->{list} = $self->parse( $handle );
	$handle->close;
	return 1;
}

sub parse {
	die "CODE INCOMPLETE";
}

sub display {
	$_[0]->{mesh}->display;
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
