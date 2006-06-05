package PITA::Guest::Storage::Simple;

=pod

=head1 NAME

PITA::Guest::Storage::Simple - A (relatively) simple Guest Storage object

=head1 DESCRIPTION

The L<PITA::Guest::Storage> class provides an API for cataloguing and
retrieving Guest images, with all the data stored on the filesystem using
the native XML file formats.

Guest image location and searching is done the long way, with no indexing.

=head1 METHODS

=cut

use strict;
use Carp       ();
use File::Spec ();
use File::Path ();
use base 'PITA::Guest::Storage';

use vars qw{$VERSION $LOCKFILE};
BEGIN {
	$VERSION  = '0.22';
	$LOCKFILE = 'PITA-Guest-Storage-Simple.lock';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new

  my $store = PITA::Guest::Storage::Simple->new(
  	storage_dir => '/var/pita/storage',
  	);

The C<new> method creates a new simple storage object. It takes a single
named param

Returns a C<PITA::Guest::Storage::Simple> object, or throws an exception
on error.

=cut

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	# Check params
	unless ( $self->storage_dir and -d $self->storage_dir and -w _ ) {
		Carp::croak('The storage_dir is not a writable directory');
	}

	$self;
}

=pod

=head2 storage_dir

The C<storage_dir> accessor returns the location of the directory that
serves as the root of the data store.

=cut

sub storage_dir {
	$_[0]->{storage_dir};
}





#####################################################################
# PITA::Guest::Storage::Simple Methods

=pod

=head2 create

  my $store = PITA::Guest::Storage::Simple->new(
  	storage_dir => 
  	);

The C<create> constructor creates a new C<PITA::Guest::Storage::Simple>
repository.

=cut

sub create {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# The storage_dir should not exist, we will create it
	my $storage_dir = $self->storage_dir;
	unless ( $storage_dir ) { 
		Carp::croak("The storage_dir param was not provided");
	}
	if ( -d $storage_dir ) {
		Carp::croak("The storage_dir '$storage_dir' already exists");
	}
	eval { File::Path::mkpath( $storage_dir, 1, 0711 ) };
	if ( $@ ) {
		Carp::croak("Failed to create the storage_dir '$storage_dir': $@");
	}

	# Create the lock file and take it
	unless ( $self->storage_lock_take ) {
		# In create, a false return is a bigger problem
		Carp::croak('Failed to create and take the lock file');
	}

	$self;
}

=pod

=head2 storage_lock

The C<storage_lock> method returns the location of the storage lock file.

The lock file is taken by a C<PITA::Guest::Storage::Simple> object at
constructor-time, and hold for the duration of the object's existance.

Returns a file path string.

=cut

sub storage_lock {
	File::Spec->catfile( $_[0]->storage_dir, $LOCKFILE );
}

=pod

=head2 storage_lock_take

The C<storage_lock_take> method takes a lock on the C<storage_lock> file,
creating it if needed (in the C<create> method case).

It does not wait to take the lock, failing immediately if the lock
cannot be taken.

Returns true if the lock is taken, false if the lock cannot be taken,
or throws an exception on error.

=cut

sub storage_lock_take {
	my $self = shift;
	my $lock = $self->storage_lock;

	# Take the lock

	# Create the file if needed
	unless ( -f $lock ) {
		local *LOCKFILE;
		open( LOCKFILE, ">$lock" )   or Carp::croak("open: $!" );
		print LOCKFILE  "A lockfile" or Carp::croak("print: $!");
		close LOCKFILE               or Carp::croak("close: $!");
	}

	# Store the lock in the object
	$self->{storage_lock_object} = 1; ### Temporary object

	1;
}

=pod

=head2 storage_lock_object

If we have a lock on the storage, returns the lock object for the lock.

Returns a C<XXXXXX> object or false if we do not have a lock

=cut

sub storage_lock_object {
	$_[0]->{storage_lock_object};	
}

=pod

=head2 storage_lock_release

If we have a lock on the storage, release the lock.

Returns true once the lock is released, or throws an exception on error
or if the object does not hold the lock.

=cut

sub storage_lock_delete {
	my $self = shift;
	unless ( $self->storage_lock_object ) {
		Carp::croak('Cannot release a lock that we do not hold');
	}
	delete $self->{storage_lock_object};
	1;
}





#####################################################################
# PITA::Guest::Storage Methods

sub add_guest {
	my $self = shift;
	die 'CODE INCOMPLETE';
}

sub guest {
	my $self = shift;
	die 'CODE INCOMPLETE';
}

sub guests {
	my $self = shift;
	die 'CODE INCOMPLETE';
}

sub platform {
	my $self = shift;
	die 'CODE INCOMPLETE';
}

sub platforms {
	my $self = shift;
	die 'CODE INCOMPLETE';
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PITA>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>

=head1 SEE ALSO

L<PITA::Guest::Storage>, L<PITA>, L<http://ali.as/pita/>

=head1 COPYRIGHT

Copyright 2005, 2006 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
