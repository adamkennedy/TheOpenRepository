package Module::Collection;

=pod

=head1 NAME

Module::Collection - Examine a group of Perl distributions

=head1 DESCRIPTION

The canonical source of all CPAN and Perl installation functionality is a
simple group of release tarballs, contained within some directory.

After all, at the very core CPAN is just a simple FTP server containing
a number of files uploaded by authors.

B<Module::Collection> is a a simple object which takes an arbitrary
directory, scans it for tarballs (which are assumed to be distribution
tarballs) and allows you to load up the tarballs as L<Module::Inspector>
objects.

While this is a fairly simple and straight forward implementation, and
is certainly not scalable enough to handle all of CPAN, it should be
quite sufficient for loading and examining a typical group of
distribution tarballs generated as part of a private project.

=cut

use 5.005;
use strict;
use Carp                  ();
use Params::Util          '_STRING';
use File::Find::Rule      ();
use Module::Inspector     ();
use Module::Math::Depends ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

my $find_dist = File::Find::Rule->relative->file->name('*.tar.gz');





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_,
		dists => {},
		}, $class;

	# We need a collection root
	unless ( $self->root and -d $self->root ) {
		Carp::croak("Missing or invalid root directory");
	}

	# Scan the for files.
	# We want readable .tar.gz files (to start with)
	foreach my $file ( $find_dist->in($self->root) ) {
		$self->{dists}->{$file} = 'dist_file';
	}

	$self;
}

sub root {
	$_[0]->{root};
}





#####################################################################
# Distribution Handling

sub dists {
	if ( wantarray ) {
		return sort { lc $a cmp lc $b } keys %{$_[0]->{dists}};
	} else {
		return scalar keys %{$_[0]->{dists}};
	}
}

sub dist_path {
	my $self = shift;
	File::Spec->catfile( $self->root, shift );
}

sub dist {
	my $self = shift;
	my $file = _STRING(shift);
	unless ( $file and $self->{dists}->{$file} ) {
		Carp::croak("No dist name provided, or does not exist");
	}

	# Is it already an object
	if ( ref $self->{dists}->{$file} ) {
		# Loaded and cached, return it
		return $self->{dists}->{$file};
	}

	# Convert the dist to a Module::Inspector
	my $module = Module::Inspector->new(
		$self->{dists}->{$file} => $self->dist_path($file),
		)
		or Carp::croak("Failed to create Module::Inspector for $file");

	# Cache and return
	return $self->{dists}->{$file} = $module;
}

sub ignore_dist {
	my $self = shift;
	my $file = _STRING(shift);
	unless ( $file and $self->{dists}->{$file} ) {
		Carp::croak("No dist name provided, or does not exist");
	}

	# Remove the dist from our collection
	delete $self->{dists}->{$file};
	return 1;
}





#####################################################################
# Common Tasks

sub ignore_old_dists {
	my $self = shift;

	# Scan the dists.
	my %keep = ();
	foreach my $file ( $self->dists ) {
		my $dist    = $self->dist($file);
		my $name    = $dist->dist_name;
		my $version = $dist->dist_version;

		# Have we seen this dist before
		unless ( exists $keep{$name} ) {
			$keep{$name} = [ $file, $version ];
			next;
		}

		# Compare the versions
		if ( $version > $keep{$name}->[1] ) {
			# Replace with newer
			$self->ignore_dist($keep{$name}->[0]);
			$keep{$name} = [ $file, $version ];
		} else {
			# Existing is newer
			$self->ignore_dist($file);
		}
	}

	return 1;	
}





#####################################################################
# Higher-Level Analysis

sub depends {
	my $self    = shift;
	my $depends = Module::Math::Depends->new;
	foreach my $file ( $self->dists ) {
		$depends->merge( $self->dist($file)->dist_depends );
	}
	$depends;
}

1;

=pod

=head1 TO DO

- Implement most of the functionality

=head1 SUPPORT

This module is stored in an Open Repository at the following address.

L<http://svn.phase-n.com/svn/cpan/trunk/Module-Collection>

Write access to the repository is made available automatically to any
published CPAN author, and to most other volunteers on request.

If you are able to submit your bug report in the form of new (failing)
unit tests, or can apply your fix directly instead of submitting a patch,
you are B<strongly> encouraged to do so as the author currently maintains
over 100 modules and it can take some time to deal with non-Critcal bug
reports or patches.

This will guarentee that your issue will be addressed in the next
release of the module.

If you cannot provide a direct test or fix, or don't have time to do so,
then regular bug reports are still accepted and appreciated via the CPAN
bug tracker.

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Collection>

For other issues, for commercial enhancement or support, or to have your
write access enabled for the repository, contact the author at the email
address above.

=head1 ACKNOWLEDGEMENTS

The biggest acknowledgement must go to Chris Nandor, who wielded his
legendary Mac-fu and turned my initial fairly ordinary Darwin
implementation into something that actually worked properly everywhere,
and then donated a Mac OS X license to allow it to be maintained properly.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Module::Inspector>

=head1 COPYRIGHT

Copyright 2006 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
