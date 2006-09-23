package Module::Inspector;

=pod

=head1 NAME

Module::Inspector - An integrated API for inspecting Perl distributions

=head1 DESCRIPTION

An entire ecosystem of CPAN modules exist around the files and formats
relating to the CPAN itself. Parsers and object models for various
different types of files have been created over the years by various people
for various projects.

These modules have a variety of different styles, and work in various
different ways.

So when it comes to analysing the structure of a Perl module (either
inside a repository, in a tarball, or in unpacked form) it is certainly
quite possible to do.

It's just that often it takes a high level of experience with the
various modules in question, and the knowledge of how to combine the
dozen of so modules in one cohesive program.

Personally, I have always found this laborious.

What I would prefer is a single API that is easy to use, implements the
magic invisibly behind the scenes, and co-ordinates the use of the
various modules for me as needed.

B<Module::Inspector> provides such an API, and provides a companion to
the L<Class::Inspector> API for accessing information on class after
installation.

It provides a wrapper around the various modules used to read and examine
the different parts of a Perl module distribution tarball, and can inspect
a module unrolled on disk, in a repository checkout, or just look directly
inside a tarball.

=head1 METHODS

=cut

use 5.005;
use strict;
use Carp                   ();
use File::Spec             ();
use File::Path             ();
use File::Temp             ();
use File::Find::Rule       ();
use File::Find::Rule::VCS  ();
use File::Find::Rule::Perl ();
use Params::Util           ('_STRING');

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

# If prefork is available, flag the optional modules
eval " use prefork 'YAML::Tiny';          ";
eval " use prefork 'Archive::Extract';    ";
eval " use prefork 'PPI::Document::File'; ";





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	if ( $self->dist_file ) {
		# Create the inspector for a tarball
		unless ( $self->dist_file =~ /\.(?:zip|tgz|tar\.gz)$/ ) {
			Carp::croak("The dist_file '" . $self->dist_file . "' is not a zip|tgz|tar.gz");
		}
		unless ( -f $self->dist_file ) {
			Carp::croak("The dist_file '" . $self->dist_file . "' does not exist");
		}

		# Do we have a directory to unroll to
		if ( $self->dist_dir ) {
			# The directory should not exist
			if ( -d $self->dist_dir ) {
				Carp::croak("Cannot reuse an pre-existing dist_dir '"
					. $self->dist_dir
					. "'" );
			}

			# Create it
			File::Path::mkpath( $self->dist_dir );
		} else {
			# Find a temp directory
			$self->{dist_dir} = File::Temp::tempdir( CLEANUP => 1 );
		}

		# Double check it now exists and is writable
		unless ( -d $self->dist_dir and -w $self->dist_dir ) {
			Carp::croak("The dist_dir '" . $self->dist_dir . "' is not writeable");
		}

		# Unpack dist_file into dist_dir
		require Archive::Extract;
		my $archive = Archive::Extract->new( archive => $self->dist_file )
			or Carp::croak("Failed to extract dist_file '"
				. $self->dist_file . "'"
				);
		$self->{dist_file_type} = $archive->type;
		unless ( $archive->extract( to => $self->dist_dir ) ) {
			Carp::croak("Failed to extract dist_file '"
				. $self->dist_file . "'"
				);
		}

		# Double check the expansion directory
		if ( $archive->extract_path ne $self->dist_dir ) {
			# Archive::Extract can extract to a single
			# directory beneath the target, in which case
			# we actually want to be using that as our dist_dir.
			$self->{dist_dir} = $archive->extract_path;
		}

	} elsif ( $self->dist_dir ) {
		# Create the inspector for a directory
		unless ( -d $self->dist_dir ) {
			Carp::croak("Missing or invalid module root $self->{dist_dir}");
		}

	} else {
		# Missing a module location
		Carp::croak("Did not provide a dist_file or dist_dir param");
	}

	# Auto-detect version control
	unless ( defined $self->version_control ) {
		$self->{version_control} = $self->_version_control;
	}

	# Create the document store
	$self->{document} = {};

	# Add the META.yml file to the document store
	if ( -e $self->file_path('META.yml') ) {
		$self->{document}->{'META.yml'} = 'YAML::Tiny';
	}

	# Populate the document store with all Perl files
	my $find_perl = File::Find::Rule->ignore_vcs($self->version_control)->perl_file;
	foreach my $file ( $find_perl->relative->in($self->dist_dir) ) {
		$self->{document}->{$file} = 'PPI::Document::File';
	}

	$self;
}

sub dist_file {
	$_[0]->{dist_file};
}

sub dist_file_type {
	$_[0]->{dist_file_type};
}

sub dist_dir {
	$_[0]->{dist_dir};
}

sub file_path {
	File::Spec->catfile( $_[0]->dist_dir, $_[1] );
}

sub dir_path {
	File::Spec->catdir( $_[0]->dist_dir, $_[1] );
}

# Detect version control
sub version_control {
	my $self = shift;

	# Determine it if we haven't yet
	unless ( exists $self->{version_control} ) {
		if ( -d $self->file_path('.svn') ) {
			# We in a subversion checkout
			$self->{version_control} = 'svn';

		} elsif ( -f $self->file_path('CVS/Repository') ) {
			# We in a CVS checkout
			$self->{version_control} = 'cvs';

		} else {
			# We have none, or can't tell
			$self->{version_control} = '';
		}
	}

	$self->{version_control};
}

# The list of documents
sub documents {
	sort keys %{ $_[0]->{document} };
}

# The type of document
sub document_type {
	my $self = shift;
	my $file = _STRING(shift)
		or Carp::croak("Missing or invalid param to document_type");
	unless ( defined $self->{document}->{$file} ) {
		Carp::croak("Document $file does not exist in module");
	}
	ref($self->{document}->{$file}) or $self->{document}->{$file};
}

# Return the document, loading it if needed
sub document {
	my $self = shift;
	my $file = _STRING(shift)
		or Carp::croak("Missing or invalid param to document_type");
	unless ( defined $self->{document}->{$file} ) {
		Carp::croak("Document $file does not exist in module");
	}

	# Return the document if loaded
	if ( ref $self->{document}->{$file} ) {
		return $self->{document}->{$file};
	}

	# Load the document
	my $path   = $self->file_path($file);
	my $loader = $self->{document}->{$file};
	if ( $loader eq 'PPI::Document::File' ) {
		require PPI::Document::File;
		my $document = PPI::Document::File->new( $path )
			or Carp::croak("Failed to load $file with PPI::Document::File");
		$self->{document}->{$file} = $document;

	} elsif ( $loader eq 'YAML::Tiny' ) {
		require	YAML::Tiny;
		my $document = YAML::Tiny->read( $path )
			or Carp::croak("Failed to load $file with $loader");
		$self->{document}->{$file} = $document;

	} else {
		die "Internal Error: Unknown document loader '$loader'";
	}

	$self->{document}->{$file};
}





#####################################################################
# Installer Detection

sub makefile_pl {
	shift->document('Makefile.PL');
}

sub build_pl {
	shift->document('Build.PL');
}

1;


=head1 TO DO

- Implement most of the functionality

=head1 SUPPORT

This module is stored in an Open Repository at the following address.

L<http://svn.phase-n.com/svn/cpan/trunk/Module-Inspector>

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

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Inspector>

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

L<Class::Inspector>

=head1 COPYRIGHT

Copyright 2006 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
