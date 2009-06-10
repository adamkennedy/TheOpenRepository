# Alien::Libjio
#  A Perl package to install libjio, a library for Journalled I/O.
#
# $Id: ISAAC.pm 7057 2009-05-12 22:51:01Z FREQUENCY@cpan.org $
#
# By Jonathan Yu <frequency@cpan.org>, 2009. All rights reversed.
#
# This package and its contents are released by the author into the Public
# Domain, to the full extent permissible by law. For additional information,
# please see the included `LICENSE' file.

package Alien::Libjio;

use strict;
use warnings;
use Carp ();

=head1 NAME

Alien::Libjio - Perl package to install libjio (Journalled I/O library)

=head1 VERSION

Version 1.0 ($Id: ISAAC.pm 7057 2009-05-12 22:51:01Z FREQUENCY@cpan.org $)

=cut

use version; our $VERSION = qv('1.0');

=head1 DESCRIPTION

To ensure reliability, some file systems and databases provide support for
something known as journalling. The idea is to ensure data consistency by
creating a log of actions to be taken (called a Write Ahead Log) before
committing them to disk. That way, if a transaction were to fail due to a
system crash or other unexpected event, the write ahead log could be used to
finish writing the data.

While this functionality is often available with networked databases, it can
be a rather memory- and processor-intensive solution, even where reliable
writes are important. In other cases, the filesystem does not provide native
journalling support, so other tricks may be used to ensure data integrity,
such as writing to a separate temporary file and then overwriting the file
instead of modifying it in-place. Unfortunately, this method cannot handle
threaded operations appropriately.

Thankfully, Alberto Bertogli published a userspace C library called libjio
that can provide these features in a small (less than 1500 lines of code)
library with no external dependencies.

This package is designed to install it, and provide a way to get the flags
necessary to compile programs using it. It is particularly useful for Perl XS
programs that use it, such as B<IO::Journal>.

=head1 SYNOPSIS

  use Alien::Libjio;

  my $jio = Alien::Libjio->new;
  my $ldflags = $jio->ldflags;
  my $cflags = $jio->cflags;

=head1 COMPATIBILITY

This module was tested under Perl 5.10.0, using Debian Linux. However, because
it's Pure Perl and doesn't do anything too obscure, it should be compatible
with any version of Perl that supports its prerequisite modules.

By default, this library is installed wherever the main system libraries are
usually installed. As a result, C<Alien::Libjio> will only work if installed
with root permissions.

If you encounter any problems on a different version or architecture, please
contact the maintainer.

=head1 METHODS

=head2 Alien::Libjio->new

Creates a new C<Alien::Libjio> object, which essentially just has a few
convenience methods providing useful information like compiler and linker
flags.

Example code:

  my $jio = Alien::Libjio->new();

This method will return an appropriate B<Alien::Libjio> object or throw an
exception on error.

=cut

sub new {
  my ($class, @seed) = @_;

  Carp::croak('You must call this as a class method') if ref($class);

  my $self = {
    installed => 0,
  };

  bless($self, $class);

  $self->_try_pkg_config()
    or $self->_try_liblist()
    ;
  return $self;
}

=head2 $jio->installed

Determine if a valid installation of libjio has been detected in the system.
This method will return a true value if it is, or undef otherwise.

Example code:

  print "okay\n" if $jio->installed;

=cut

sub installed {
  my ($self) = @_;

  Carp::croak('You must call this method as an object') unless ref($self);

  return $self->{installed};
}

=head2 $jio->version

Determine the installed version of libjio, as a string.

Currently versions are simply floating-point numbers, so you can treat the
version number as such, but this behaviour is subject to change.

Example code:

  my $version = $jio->version;

=cut

sub version {
  my ($self) = @_;

  Carp::croak('You must call this method as an object') unless ref($self);

  return $self->{version};
}

=head2 $jio->ldflags
=head2 $jio->linker_flags

This returns the flags required to link C code with the local installation of
libjio (typically in the LDFLAGS variable). It is particularly useful for
building and installing Perl XS modules such as L<IO::Journal>.

In scalar context, it returns an array reference suitable for passing to
other build systems, particularly L<Module::Build>. In list context, it gives
a normal array so that C<join> and friends will work as expected.

Example code:

  my $ldflags = $jio->ldflags;
  my @ldflags = @{ $jio->ldflags };
  my $ldstring = join(' ', $jio->ldflags);
  # or:
  # my $ldflags = $jio->linker_flags;

=cut

sub ldflags {
  my ($self) = @_;

  Carp::croak('You must call this method as an object') unless ref($self);

  # Return early if called in void context
  return unless defined wantarray;

  # If calling in array context, dereference and return
  return @{ $self->{ldflags} } if wantarray;

  return $self->{ldflags};
}

# Glob to create an alias to ldflags
*linker_flags = *ldflags;

=head2 $jio->cflags
=head2 $jio->compiler_flags

This method returns the compiler option flags to compile C code which uses
the libjio library (typically in the CFLAGS variable). It is particularly
useful for building and installing Perl XS modules such as L<IO::Journal>.

Example code:

  my $cflags = $jio->cflags;
  my @cflags = @{ $jio->cflags };
  my $ccstring = join(' ', $jio->cflags);
  # or:
  # my $cflags = $jio->compiler_flags;

=cut

sub cflags {
  my ($self) = @_;

  Carp::croak('You must call this method as an object') unless ref($self);

  # Return early if called in void context
  return unless defined wantarray;

  # If calling in array context, dereference and return
  return @{ $self->{cflags} } if wantarray;

  return $self->{cflags};
}
*compiler_flags = *cflags;

# Private methods to find & fill out information

use IPC::Open3 ('open3');

sub _get_pc {
  my ($key) = @_;

  my $read;
  # This string doesn't look all *too* noisy for me
  ## no critic(ProhibitNoisyQuotes)
  my $pid = open3(undef, $read, undef, 'pkg-config', 'libjio', '--' . $key);
  # We're using blocking wait, so the return value doesn't matter
  ## no critic(RequireCheckedSyscalls)
  waitpid($pid, 0);

  # Check the exit status; 0 = success - nonzero = failure
  if (($? >> 8) == 0) {
    # The value we got back
    return <$read>;
  }
  return (undef, <$read>) if wantarray;
  return;
}

sub _try_pkg_config {
  my ($self) = @_;

  my ($value, $err) = _get_pc('cflags');
  if (defined $err && length $err) {
    #warn "Problem with pkg-config; using ExtUtils::Liblist instead\n";
    return;
  }

  $self->{installed} = 1;

  # pkg-config returns things with a newline, so remember to remove it
  # I don't see anything wrong with the ' ' (pure whitespace quotes)
  ## no critic(ProhibitEmptyQuotes)
  $self->{cflags} = [ split(' ', $value) ];
  $self->{ldflags} = [ split(' ', _get_pc('libs')) ];
  $self->{version} = _get_pc('modversion');

  return 1;
}

sub _try_liblist {
  my ($self) = @_;

  use ExtUtils::Liblist ();
  local $SIG{__WARN__} = sub { }; # mask warnings

  my (undef, undef, $ldflags, $ldpath) = ExtUtils::Liblist->ext('-ljio');
  return unless (defined($ldflags) && length($ldflags));

  $self->{installed} = 1;

  # Empty out cflags; initialize it
  $self->{cflags} = [];

  my $read;
  my $pid = open3(undef, $read, undef, 'getconf', 'LFS_CFLAGS');

  # We're using blocking wait, so the return value doesn't matter
  ## no critic(RequireCheckedSyscalls)
  waitpid($pid, 0);

  # Check the status code
  if (($? >> 8) == 0) {
    # This only takes the first line
    ## no critic(ProhibitEmptyQuotes)
    push(@{ $self->{cflags} }, split(' ', <$read>));
  }
  else {
    warn 'Problem using getconf: ', <$read>, "\n";
    push(@{ $self->{cflags} },
      '-D_LARGEFILE_SOURCE',
      '-D_FILE_OFFSET_BITS=64',
    );
  }

  # Used for resolving the include path, relative to lib
  use Cwd ();
  use File::Spec ();
  push(@{ $self->{cflags} },
    # The include path is taken as: $libpath/../include
    '-I' . Cwd::realpath(File::Spec->catfile(
      $ldpath,
      File::Spec->updir(),
      'include'
    ))
  );

  push(@{ $self->{ldflags} },
    '-L' . $ldpath,
    $ldflags,
  );

  return 1;
}

=head1 AUTHOR

Jonathan Yu E<lt>frequency@cpan.orgE<gt>

=head2 CONTRIBUTORS

Your name here ;-)

=head1 ACKNOWLEDGEMENTS

=over

=item *

Special thanks to Alberto Bertogli E<lt>albertito@blitiri.com.arE<gt> for
developing this useful library and for releasing it into the public domain.

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Alien::Libjio

You can also look for information at:

=over

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Alien-Libjio>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Alien-Libjio>

=item * Search CPAN

L<http://search.cpan.org/dist/Alien-Libjio>

=item * CPAN Request Tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Alien-Libjio>

=item * CPAN Testing Service (Kwalitee Tests)

L<http://cpants.perl.org/dist/overview/Alien-Libjio>

=item * CPAN Testers Platform Compatibility Matrix

L<http://cpantesters.org/show/Alien-Libjio.html>

=back

=head1 REPOSITORY

You can access the most recent development version of this module at:

L<http://svn.ali.as/cpan/trunk/Alien-Libjio>

If you are a CPAN developer and would like to make modifications to the code
base, please contact Adam Kennedy E<lt>adamk@cpan.orgE<gt>, the repository
administrator. I only ask that you contact me first to discuss the changes you
wish to make to the distribution.

=head1 FEEDBACK

Please send relevant comments, rotten tomatoes and suggestions directly to the
maintainer noted above.

If you have a bug report or feature request, please file them on the CPAN
Request Tracker at L<http://rt.cpan.org>. If you are able to submit your bug
report in the form of failing unit tests, you are B<strongly> encouraged to do
so.

=head1 SEE ALSO

L<IO::Journal>, a Perl module that provides an interface to libjio.

L<App::Info::Lib::Jio>, a package that gets information about libjio.

L<http://blitiri.com.ar/p/libjio/>, Alberto Bertogli's page about libjio,
which explains the purpose and featuers of libjio.

=head1 CAVEATS

=head2 KNOWN BUGS

There are no known bugs as of this release.

=head2 LIMITATIONS

=over

=item *

This module can only search known/common paths for libjio installations.
It does try to use B<pkg-config> and B<ExtUtils::Liblist> to find a libjio
installation on your system, but it cannot predict where files might have
been installed. As a result, this package might install a duplicate copy
of libjio.

=back

=head1 LICENSE

Copyleft 2009 by Jonathan Yu <frequency@cpan.org>. All rights reversed.

I, the copyright holder of this package, hereby release the entire contents
therein into the public domain. This applies worldwide, to the extent that
it is permissible by law.

In case this is not legally possible, I grant any entity the right to use
this work for any purpose, without any conditions, unless such conditions
are required by law.

The full details of this can be found in the B<LICENSE> file included in
this package.

=head1 DISCLAIMER OF WARRANTY

The software is provided "AS IS", without warranty of any kind, express or
implied, including but not limited to the warranties of merchantability,
fitness for a particular purpose and noninfringement. In no event shall the
authors or copyright holders be liable for any claim, damages or other
liability, whether in an action of contract, tort or otherwise, arising from,
out of or in connection with the software or the use or other dealings in
the software.

=cut

1;
