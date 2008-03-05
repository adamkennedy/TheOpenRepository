package Win32::File::Object;

use strict;
use Carp        ();
use Win32::File ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor

sub new {
	my $class     = shift;
	my $path      = shift;
	my $autowrite = !! shift;
	unless ( $path ) {
		Carp::croak("Did not provide a file name");
	}
	unless ( -f $path ) {
		Carp::croak("File '$path' does not exist");
	}

	# Create the object
	my $self = bless {
		path      => $path,
		autowrite => $autowrite,
	}, $class;

	# Get the attributes
	$self->read;

	return 1;
}

sub path {
	$_[0]->{path};
}

sub autowrite {
	$_[0]->{autowrite};
}

sub archive {
	my $self = shift;
	if ( @_ ) {
		$self->{archive} = $_[0] ? 1 : 0;
		$self->write if $self->autowrite;
	}
	$self->{archive};
}

sub compressed {
	my $self = shift;
	if ( @_ ) {
		$self->{compressed} = $_[0] ? 1 : 0;
		$self->write if $self->autowrite;
	}
	$self->{compressed};
}

sub directory {
	my $self = shift;
	if ( @_ ) {
		$self->{directory} = $_[0] ? 1 : 0;
		$self->write if $self->autowrite;
	}
	$self->{directory};
}

sub hidden {
	my $self = shift;
	if ( @_ ) {
		$self->{hidden} = $_[0] ? 1 : 0;
		$self->write if $self->autowrite;
	}
	$self->{hidden};
}

sub normal {
	my $self = shift;
	if ( @_ ) {
		$self->{normal} = $_[0] ? 1 : 0;
		$self->write if $self->autowrite;
	}
	$self->{normal};
}

sub offline {
	my $self = shift;
	if ( @_ ) {
		$self->{offline} = $_[0] ? 1 : 0;
		$self->write if $self->autowrite;
	}
	$self->{offline};
}

sub readonly {
	my $self = shift;
	if ( @_ ) {
		$self->{readonly} = $_[0] ? 1 : 0;
		$self->write if $self->autowrite;
	}
	$self->{readonly};
}

sub system {
	my $self = shift;
	if ( @_ ) {
		$self->{system} = $_[0] ? 1 : 0;
		$self->write if $self->autowrite;
	}
	$self->{system};
}

sub temporary {
	my $self = shift;
	if ( @_ ) {
		$self->{temporary} = $_[0] ? 1 : 0;
		$self->write if $self->autowrite;
	}
	$self->{temporary};
}





#####################################################################
# Main Methods

sub read {
	my $self = shift;

	# Read the bitfield
	my $bits;
	Win32::File::GetAttributes( $path => $bits );

	# Scan for the bits
	$self->{archive}    = ($bits & Win32::File::ARCHIVE())    ? 1 : 0;
	$self->{compressed} = ($bits & Win32::File::COMPRESSED()) ? 1 : 0;
	$self->{directory}  = ($bits & Win32::File::DIRECTORY())  ? 1 : 0;
	$self->{hidden}     = ($bits & Win32::File::HIDDEN())     ? 1 : 0;
	$self->{normal}     = ($bits & Win32::File::NORMAL())     ? 1 : 0;
	$self->{offline}    = ($bits & Win32::File::OFFLINE())    ? 1 : 0;
	$self->{readonly}   = ($bits & Win32::File::READONLY())   ? 1 : 0;
	$self->{system}     = ($bits & Win32::File::SYSTEM())     ? 1 : 0;
	$self->{temporary}  = ($bits & Win32::File::TEMPORARY())  ? 1 : 0;

	return 1;
}

sub write {
	my $self = shift;

	# Generate the bitfield from the attributes
	my $bits = 0;
	if ( $self->archive ) {
		$bits += Win32::File::ARCHIVE();
	}
	if ( $self->compressed ) {
		$bits += Win32::File::COMPRESSED();
	}
	if ( $self->directory ) {
		$bits += Win32::File::DIRECTORY();
	}
	if ( $self->hidden ) {
		$bits += Win32::File::HIDDEN();
	}
	if ( $self->normal ) {
		$bits += Win32::File::NORMAL();
	}
	if ( $self->offline ) {
		$bits += Win32::File::OFFLINE();
	}
	if ( $self->readonly ) {
		$bits += Win32::File::READONLY();
	}
	if ( $self->system ) {
		$bits += Win32::File::SYSTEM();
	}
	if ( $self->temporary ) {
		$bits += Win32::File::TEMPORARY();
	}

	# Apply the attributes to the file
	my $path = $self->path;
	unless ( SetAttributes( $path, $bits ) ) {
		Carp::croak("Failed to apply attributes to '$path'");
	}

	return 1;
}

1;
