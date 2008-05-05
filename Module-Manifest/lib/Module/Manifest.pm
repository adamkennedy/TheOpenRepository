package Module::Manifest;

=pod

=head1 NAME

Module::Manifest - Parse and examine a Perl distribution MANIFEST file

=head1 DESCRIPTION

B<Module::Manifest> is a simple utility module created originally for
use in L<Module::Inspector>.

It allows you to load the F<MANIFEST> file that comes in a Perl
distribution tarball, examine the contents, and perform some simple
tasks.

Granted, the functionality needed to do this is quite simple, but the
Perl distribution F<MANIFEST> specification contains a couple of little
idiosyncracies, such as line comments and space-seperated inline
comments.

The use of this module means that any little nigglies are dealt with
behind the scenes, and you can concentrate the main task at hand.

=head2 Comparison to ExtUtil::Manifest

This module is quite similar to L<ExtUtils::Manifest>, or is at least
similar in scope. However, there is a general difference in approach.

L<ExtUtils::Manifest> is imperative, requires the existance of the actual
F<MANIFEST> file on disk, and requires that your current directory remains
the same.

L<Module::Manifest> treats the F<MANIFEST> file as an object, can load
a the file from anywhere on disk, and can run some of the same
functionality without having to change your current directory context.

That said, note that L<Module::Manifest> is aimed at reading and checking
existing MANFIFEST files, rather than creating new ones.

=head2 METHODS

=cut

use 5.005;
use strict;
use File::Spec     ();
use File::Basename ();
use Params::Util   '_STRING';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.03';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new

  my $manifest = Module::Manifest->new( $filename );

The C<new> constructor takes the name of a MANIFEST file on disk and
and creates a new object.

At the present time, a new empty manifest object cannot be created,
although this may be added in a later version.

Return a B<Module::Manifest> object or dies on error.

=cut

sub new {
	my $class = shift;
	my $file  = _STRING(shift);
	unless ( $file and -f $file and -r _ ) {
		Carp::croak("Did not provide a readable file path");
	}

	# Derelativise the file name if needed
	my $absfile = File::Spec->rel2abs($file);
	my $absdir  = File::Basename::dirname($absfile);

	# Parse the file
	my %files = ();
	open( FILE, $absfile ) or Carp::croak("Failed to load MANIFEST: $!");
	while ( defined(my $line = <FILE>) ) {
		next unless $line =~ /^\s*([^\s#]\S*)/;
		if ( $files{$1}++ ) {
			Carp::croak("Duplicate file $1");
		}
	}
	close FILE;

	# Create and return the object
	return bless {
		file  => $absfile,
		dir   => $absdir,
		files => \%files,
		}, $class;
}

=pod

=head2 file

The C<file> accessor returns the absolute path of the MANIFEST file that
was loaded.

=cut

sub file {
	$_[0]->{file};
}

=pod

=head2 dir

The C<dir> accessor returns the path to the directory that contains the
MANIFEST file, and thus SHOULD be the root of the distribution.

=cut

sub dir {
	$_[0]->{dir};
}

=head2 files

The C<files> method returns the (relative, unix-style) list of files
within the manifest. In scalar context, returns the number of files
in the manifest.

=cut

sub files {
	if ( wantarray ) {
		return sort { lc $a cmp lc $b } keys %{$_[0]->{files}};
	} else {
		return scalar keys %{$_[0]->{files}};
	}
}

1;

=pod

=head1 SUPPORT

This module is stored in an Open Repository at the following address.

L<http://svn.ali.as/cpan/trunk/File-HomeDir>

Write access to the repository is made available automatically to any
published CPAN author, and to most other volunteers on request.

If you are able to submit your bug report in the form of new (failing)
unit tests, or can apply your fix directly instead of submitting a patch,
you are B<strongly> encouraged to do so. The author currently maintains
over 100 modules and it may take some time to deal with non-Critical bug
reports or patches.

This will guarentee that your issue will be addressed in the next
release of the module.

If you cannot provide a direct test or fix, or don't have time to do so,
then regular bug reports are still accepted and appreciated via the CPAN
bug tracker.

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Manifest>

For other issues, for commercial enhancement and support, or to have your
write access enabled for the repository, contact the author at the email
address above.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<ExtUtils::Manifest>

=head1 COPYRIGHT

Copyright 2006 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
