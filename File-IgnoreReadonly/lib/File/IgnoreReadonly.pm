package File::IgnoreReadonly;

=pod

=head1 NAME

File::IgnoreReadonly - Make all files (even readonly ones) lexically writable

=head1 SYNOPSIS

  SCOPE: {
      # Make writable, if possible (dies on error)
      my $guard = File::IgnoreReadonly->new( 'readonly.txt' );
      
      # Change the file
      open( FILE, '>readonly.txt' ) or die "open: $!";
      print FILE "New Content"      or die "print: $!";
      close( FILE )                 or die "close: $!";
  }
  
  # File is now readonly again

=head1 DESCRIPTION

This is a convenience package for use in situations that require you to
make modifications to files, even if those files are readonly.

Typical scenarios include tweaking files in software build systems, where
some files will have been generated that are readonly, but you need to be
able to make small tweaks to them anyways.

While it is certainly possible to simply set a file non-readonly (if it is
readonly) and then set it back to readonly again afterwards, doing this in
many places can get laborious and looks visually messy.

B<File::LexWrite> allows for the creation of a simple guard object that
will ensure a file is NOT set readonly (across multiple different operating
systems).

When the object is DESTROY'ed at the end of the current scope, the file
will be returned to the original file permissions it had when the guard
object was created.

=head1 METHODS

=cut

use 5.006;
use strict;
use File::chmod ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}

# Deal with platform issues
use constant WIN32 => $^O eq 'MSWin32';





#####################################################################
# Constructor

=pod

=head2 new

The C<new> method is a simple constructor that takes a single parameter.

It will set the file to writable if needed, and return a guard object.

When the guard object is DESTROYed, the file will be set back to the
original file mode.

Returns a new B<File::IgnoreReadonly> object, or throws an exception (dies)
on error.

=cut

sub new {
	my ( $class, $file ) = @_;
	unless ( defined $file and ! ref $file and length $file and -f $file ) {
		Carp::croak("Missing or invalid file name");
	}

	# Create the object
	my $self = bless {
		file => $file,
	}, $class;

	# If the file is already writable, we don't need to do anything
	if ( -w $file ) {
		return $self;
	}

	# Save the original file mode and set writable
	if ( WIN32 ) {
		$self->{win32} = (File::chmod::getmod( $file ))[0];
		File::chmod::chmod('u+w', $file);
	} else {
		# Otherwise, save the original file mode
		$self->{unix} = (File::chmod::getmod( $file ))[0];
		File::chmod::chmod('ug+w', $file);
	}
	return $self;
}

sub DESTROY {
	if ( defined $_[0]->{win32} ) {
		File::chmod::chmod( $_[0]->{win32}, $_[0]->{file} );
		delete $_[0]->{win32};

	} elsif ( defined $_[0]->{unix} ) {
		File::chmod::chmod( $_[0]->{unix},  $_[0]->{file} );
		delete $_[0]->{unix};
	}
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-IgnoreReadonly>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
