package Process::Storable;

# Process that is compatible with Storable after new, and after run.

use 5.005;
use strict;
use base 'Process::Serializable';
use Storable     ();
use IO::Handle   ();
use IO::String   ();
use Scalar::Util ();
use Params::Util '_INSTANCE';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.10';

	# Hack IO::String to be a real IO::Handle
	unless ( @IO::String::ISA ) {
		@IO::String::ISA = qw{IO::Handle IO::Seekable};
	}
}

sub serialize {
	my $self = shift;

	# Serialize to a named file (locking it)
	if ( defined $_[0] and ! ref $_[0] and length $_[0] ) {
		return Storable::lock_nstore($self, shift);
	}

	# Serialize to a string (via a handle)
	if ( Params::Util::_SCALAR0($_[0]) ) {
		my $string = shift;
		$$string   = 'pst0' . Storable::nfreeze($self);
		return 1;
	}

	# Serialize to a generic handle
	if ( fileno($_[0]) ) {
		return Storable::nstore_fd($self, shift);
	}

	# Serialize to an IO::Handle object
	if ( Params::Util::_INSTANCE($_[0], 'IO::Handle') ) {
		my $string   = Storable::nfreeze($self);
		my $iohandle = shift;
		$iohandle->print( 'pst0' )  or return undef;
		$iohandle->print( $string ) or return undef;
		return 1;
	}

	# We don't support anything else
	undef;
}

sub deserialize {
	my $class = shift;
	my $self  = $class->_deserialize(@_);

	# Integrity check
	(_INSTANCE($self, $class) and ref($self) eq $class) or return undef;

	$self;
}

sub _deserialize {
	my $class = shift;

	# Serialize from a named file (locking it)
	if ( defined $_[0] and ! ref $_[0] and length $_[0] ) {
		return Storable::lock_retrieve(shift);
	}

	# Serialize from a string (via a handle)
	if ( Params::Util::_SCALAR0($_[0]) ) {
		my $string = shift;

		# Remove the magic header if it exists
		if ( substr($$string, 0, 4) eq 'pst0' ) {
			substr($$string, 0, 4, '');
		}

		return Storable::thaw($$string);
	}

	# Serialize from a generic handle
	if ( fileno($_[0]) ) {
		return Storable::retrieve_fd(shift);
	}

	# Serialize from an IO::Handle object
	if ( Params::Util::_INSTANCE($_[0], 'IO::Handle') ) {
		local $/   = undef;
		my $string = $_[0]->getline;

		# Remove the magic header if it exists
		if ( substr($string, 0, 4) eq 'pst0' ) {
			substr($string, 0, 4, '');
		}

		return Storable::thaw($string);
	}

	# We don't support anything else
	undef;
}

1;

__END__

=pod

=head1 NAME

Process::Storable - The Process::Serializable role implemented by Storable

=head1 SYNOPSIS

  package MyStorableProcess;
  
  use base 'Process::Storable',
           'Process';
  
  sub prepare {
      ...
  }
  
  sub run {
      ...
  }
  
  1;

=head1 DESCRIPTION

C<Process::Storable> provides an implementation of the
L<Process::Serializable> role using the standard L<Storable> module
from the Perl core. It is not itself a subclass of L<Process> so you
will need to inherit from both.

Objects that inherit from C<Process::Storable> must follow the C<new>,
C<prepare>, C<run> rules of L<Process::Serializable>.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Process>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2006 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
