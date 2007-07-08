package Apache::Htpasswd::Shadow;

=pod

=head1 NAME

Apache::Htpasswd::Shadow - Apache::Htpasswd variant that saves to a different file

=head1 DESCRIPTION

The L<Apache::Htpasswd> provides an interface to Apache I<.htpasswd>-style
files.

However, it saves changes to the .htpasswd file directly, which assumes that
you actually have write permission to the file.

In many cases, particularly when modifying accounts from a web interface on
that same Apache instance, you would B<never> want the web user to have
the sort of permissions needed to change the file.

In these cases, it is instead preferred to have the web user write to a
"shadow" version of the .htpasswd file. This shadow version is then
examined and copied into place by a process with suitable permissions
that is trigged by the web user, or runs at regular intervals.

The B<Apache::Htpasswd::Shadow> module implements this concept.

=head1 METHODS

With the exception of the additional B<new> parameter, the interface for
B<Apache::Htpasswd::Shadow> is identical to L<Apache::Htpasswd>. See that
module for interface documentation.

=cut

use 5.005;
use strict;
use Carp             ();
use File::Copy       ();
use Apache::Htpasswd ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.03';
}





#####################################################################
# Constructor

=pod

=head2 new

  # Single-param version
  $htpasswd = Apache::Htpasswd::Shadow->new("name-of-file");
  
  # Multiple-param version
  $htpasswd = Apache::Htpasswd::Shadow->new({
          passwdFile => 'name-of-file',
          shadowFile => 'name-of-shadow-file',
          ReadOnly   => 1,
          UseMD5     => 1,
   } );

The B<new> constructor takes the same parameters in the same way
as the regular L<Apache::Htpasswd> B<new> constructor.

The one exception is that it allows you to pass the additional named
parameter B<shadowFile> to explicitly specify the name of the shadow
file. If not provided, the default shadow file name is the same as
the B<passwdFile> value, but with '.new' appended.

=cut

sub new {
	my $class = shift;
	my %param = ref($_[0]) eq 'HASH'
		? %{$_[0]}
		: ( passwdFile => $_[0] );

	# Create the empty object
	my $self = bless {
		passwdFile   => $param{passwdFile},
		passwdObject => undef,
		shadowFile   => $param{shadowFile},
		shadowObject => undef,
		UseMD5       => $param{UseMD5},
		}, $class;

	# Get the password file name
	unless ( defined $self->passwdFile ) {
		# No password file name, return an empty
		# Htpasswd object to get a compatible error message.
		$self->{passwdObject} = Apache::Htpasswd->new(\%param);
		return $self;
	}

	# Determine the shadow file name
	unless ( defined $self->shadowFile ) {
		# Default file name based on the main one
		$self->{shadowFile} = $self->passwdFile . '.new';
	}

	# Does the shadow file exist?
	unless ( -f $self->shadowFile ) {
		if ( $param{ReadOnly} ) {
			# Use the main, don't create a shadow
			delete $self->{shadowFile};
			$self->{passwdObject} = Apache::Htpasswd->new(\%param);
			return $self;
		}

		# Create the shadow file
		File::Copy::copy( $self->passwdFile => $self->shadowFile )
			or Carp::croak("Failed to create shadow file $self->{shadowFile}");		
	}

	# The shadow file exists.
	# We should use that for our operations.
	$self->{shadowObject} = Apache::Htpasswd->new({
			%param,
			passwdFile => $self->shadowFile,
			});

	return $self;
}

sub passwd_object {
	$_[0]->{passwdObject};
}

sub shadow_object {
	$_[0]->{shadowObject};
}

sub object {
	$_[0]->shadowObject || $_[0]->passwdObject;
}

sub isa {
	if ( $_[1] and $_[1] eq 'Apache::Htpasswd' ) {
		return 1;
	}
	return shift->SUPER::isa(@_);
}

sub passwdFile {
	$_[0]->{passwdFile};
}

sub passwdObject {
	$_[0]->{passwdObject};
}

sub shadowFile {
	$_[0]->{shadowFile};
}

sub shadowObject {
	$_[0]->{shadowObject};
}





#####################################################################
# Pass-Through Methods

sub error {
	shift->object->error(@_);
}

sub htCheckPassword {
	shift->object->htCheckPassword(@_);
}

sub htpasswd {
	shift->object->htpasswd(@_);
}

sub htDelete {
	shift->object->htDelete(@_);
}

sub fetchPass {
	shift->object->fetchPass(@_);
}

sub fetchInfo {
	shift->object->fetchInfo(@_);
}

sub fetchUsers {
	shift->object->fetchUsers(@_);
}

sub writeInfo {
	shift->object->writeInfo(@_);
}

sub CryptPasswd {
	shift->object->CryptPasswd(@_);
}

1;

=pod

=head1 SUPPORT

This module is stored in an Open Repository at the following address.

L<http://svn.ali.as/cpan/trunk/Apache-Htpasswd-Shadow>

Write access to the repository is made available automatically to any
other CPAN author, and to most other volunteers on request.

If you are able to submit your bug report in the form of new (failing)
unit tests, or can apply your fix directly instead of submitting a patch,
you are B<strongly> encouraged to do so as the author currently maintains
over 100 modules and it can take some time to deal with non-critical bug
reports or patches.

This will also guarentee that your issue will be addressed in the next
release of the module (since my release automation won't let me release
a module with broken tests) :)

If you cannot provide a direct test or fix, or don't have time to do so,
then regular bug reports are still accepted and appreciated via the CPAN
bug tracker.

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Inspector>

For other issues, for commercial enhancement or support, or to have your
write access enabled for the repository, contact the author at the email
address below.

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

=head1 SEE ALSO

L<Apache::Htpasswd>

=head1 COPYRIGHT

Copyright 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
