package OpenGL::RWX;

# Generate OpenGL models from the RWX file format

use strict;
use warnings;
use OpenGL;
use OpenGL::List;

our $VERSION = '0.01';

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check param
	my $file  = $self->file;
	unless ( -f $file ) {
		die "RWX model file '$file' does not exists";
	}

	return $self;
}

sub file {
	$_[0]->{file}
}

sub init {
	my $self = shift;

	open( FILE, 
}

1;
