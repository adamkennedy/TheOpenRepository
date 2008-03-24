package CPAN::Mini::Extract;

=pod

=head1 NAME

CPAN::Mini::Extract - Create CPAN::Mini mirrors with the archives extracted

=head1 SYNOPSIS

  # Create a CPAN extractor
  my $cpan = CPAN::Mini::Extract->new(
      remote         => 'http://mirrors.kernel.org/cpan/',
      local          => '/home/adam/.minicpan',
      trace          => 1,
      extract        => '/home/adam/.cpanextracted',
      extract_filter => sub { /\.pm$/ and ! /\b(inc|t)\b/ },
      extract_check  => 1,
      );
  
  # Run the minicpan process
  my $changes = $cpan->run;

=head1 DESCRIPTION

C<CPAN::Mini::Extract> provides a base for implementing systems that
download "all" of CPAN, extract the dists and then process the files
within.

It provides the same syncronisation functionality as L<CPAN::Mini> except
that it also maintains a parallel directory tree that contains a directory
located at an identical path to each archive file, with a controllable
subset of the files in the archive extracted below.

=head2 How does it work

C<CPAN::Mini::Extract> starts with a L<CPAN::Mini> local mirror, which it
will optionally update before each run. Once the L<CPAN::Mini> directory
is current, it will scan both directory trees, extracting any new archives
and removing any extracted archives no longer in the minicpan mirror.

=head1 EXTENDING

This class is relatively straight forward, but may evolve over time.

If you wish to write an extension, please stay in contact with the
maintainer while doing so.

=head1 METHODS

=cut

use 5.006;
use strict;
use base 'CPAN::Mini';
use Carp             ();
use File::Spec       ();
use File::Basename   ();
use File::Path       ();
use File::Remove     ();
use List::Util       ();
use File::HomeDir    ();
use File::Temp       ();
use URI::file        ();
use IO::File         ();
use IO::Zlib         (); # Needed by Archive::Tar
use Archive::Tar     ();
use Params::Util     '_CODELIKE',
                     '_INSTANCE',
                     '_ARRAY0';
use LWP::Online      ();
use File::Find::Rule ();
use constant FFR  => 'File::Find::Rule';

our $VERSION;
BEGIN {
        $VERSION = '1.17';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new

The C<new> constructor is used to create and configure a new CPAN
Processor. It takes a set of named params something like the following.

  # Create a CPAN processor
  my $Object = CPAN::Mini::Extract->new(
      # The normal CPAN::Mini params
      remote         => 'ftp://cpan.pair.com/pub/CPAN/',
      local          => '/home/adam/.minicpan',
      trace          => 1,
      
      # Additional params
      extract        => '/home/adam/explosion',
      extract_filter => sub { /\.pm$/ and ! /\b(inc|t)\b/ },
      extract_check  => 1,
      );

=over

=item minicpan args

C<CPAN::Mini::Extract> inherits from L<CPAN::Mini>, so all of the arguments
that can be used with L<CPAN::Mini> will also work with
C<CPAN::Mini::Extract>.

Please note that C<CPAN::Mini::Extract> applies some additional defaults
beyond the normal ones, like turning C<skip_perl> on.

=item offline

Although useless with L<CPAN::Mini> itself, the C<offline> flag will
cause the CPAN synchronisation step to be skipped, and only any
extraction tasks to be done. (False by default)

=item extract

Provides the directory (which must exist and be writable, or be creatable)
that the tarball dists should be extracted to.

=item extract_filter

C<CPAN::Mini::Extract> allows you to specify a filter controlling which
types of files are extracted from the Archive. Please note that ONLY
normal files are ever considered for extraction from an archive, with
any directories needed created automatically.

Although by default C<CPAN::Mini::Extract> only extract files of type .pm,
.t and .pl from the archives, you can add a list of additional things you
do not want to be extracted.

The filter should be provided as a subroutine reference. This sub will
be called with $_ set to the path of the file. The subroutine should
return true if the file is to be extracted, or false if not.

  # Extract all .pm files, except those in an include directory
  extract_filter => sub { /\.pm$/ and ! /\binc\b/ },

=item extract_check

The main extraction process is done as each new archive is downloaded,
but occasionally in a process this long-running something may go wrong
and you can end up with archives not extracted.

In addition, sometimes the processing of the extracted archives is
destructive and will result in them being deleted each run.

Once the mirror update has been completed, the C<extract_check> keyword
forces the processor to go back over every tarball in the mirror and
double check that it has a corrosponding extracted directory.

=back

Returns a new C<CPAN::Mini::Extract> object, or dies on error.

=cut

sub new {
	my $class = shift;
	my %params = @_;

        # Look for a user-config
        my %config = CPAN::Mini->read_config;

        # Unless provided auto-detect offline mode
	unless ( defined $params{offline} ) {
		$params{offline} = LWP::Online::offline();
	}

        # Fake a remote URI if CPAN::Mini can't handle offline mode
        my %fake = ();
        if ( $params{offline} and $CPAN::Mini::VERSION <= 0.552 ) {
                my $tempdir   = File::Temp::tempdir();
                my $tempuri   = URI::file->new( $tempdir )->as_string;
                $fake{remote} = $tempuri;
        }

        # Use a default local path if none provided
        unless ( defined $params{local} ) {
                my $local = File::Spec->catdir(
			File::HomeDir->my_data, 'minicpan',
		);
        }

        # Call our superclass to create the object
        my $self = $class->SUPER::new( %params, %fake );

	# Check the extract param
	$self->{extract} or Carp::croak(
		"Did not provide an 'extract' path"
		);
	if ( -e $self->{extract} ) {
		unless ( -d _ and -w _ ) {
			Carp::croak(
				"The 'extract' path is not a writable directory"
				);
		}
	} else {
		File::Path::mkpath( $self->{extract}, $self->{trace}, $self->{dirmode} )
			or Carp::croak("The 'extract' path could not be created");
	}

	# Set defaults and apply rules
	$self->{extract_check} = 1 if $self->{extract_force};

	# Compile file_filters if needed
	$self->_compile_filter('extract_filter');

	$self;
}





#####################################################################
# Main Methods

=pod

=head2 run

The C<run> methods starts the main process, updating the minicpan mirror
and extracted version, and then launching the PPI Processor to process the
files in the source directory.

Returns the number of changes made to the local minicpan and extracted
directories, or dies on error.

=cut

sub run {
	my $self = shift;

	# Prepare to start
	local $| = 1;
	my $changes;
	$self->{added}   = {};
	$self->{cleaned} = {};

	# If we want to force re-expansion,
	# remove all current expansion dirs.
	if ( $self->{extract_force} ) {
		$self->trace("Flushing all expansion directories (extract_force enabled)\n");
		my $authors_dir = File::Spec->catfile( $self->{extract}, 'authors' );
		if ( -e $authors_dir ) {
			$self->trace("Removing $authors_dir...");
			File::Remove::remove( \1, $authors_dir ) or Carp::croak(
				"Failed to remove previous expansion directory '$authors_dir'"
				);
			$self->trace(" removed\n");
		}
	}

	# Update the CPAN::Mini local mirror
	if ( $self->{offline} ) {
		$self->trace("Skipping MiniCPAN update (offline mode enabled)\n");
	} else {
		$self->trace("Updating MiniCPAN local mirror...\n");
		$self->update_mirror;
	}

	$changes ||= 0;
        if ( $self->{extract_check} or $self->{extract_force} ) {
		# Expansion checking is enabled, and we didn't do a normal
		# forced check, so find the full list of files to check.
		$self->trace("Tarball expansion checking enabled\n");
		my @files = FFR->new
		               ->file
		               ->name('*.tar.gz')
		               ->relative
		               ->in( $self->{local} );

		# Filter to just those we need to extract
		$self->trace("Checking " . scalar(@files) . " tarballs\n");
		@files = grep { ! -d File::Spec->catfile( $self->{extract}, $_ ) } @files;
		if ( @files ) {
			$self->trace("Scheduling " . scalar(@files) . " tarballs for expansion\n");
		} else {
			$self->trace("No tarballs need to be extracted");
		}

		# Expand each of the tarballs
		foreach my $file ( sort @files ) {
			$self->mirror_extract( $file );
			$changes++;
		}
	}

	$self->trace("Completed minicpan extraction\n");
	$changes;
}





#####################################################################
# CPAN::Mini Methods

# Track what we have added
sub mirror_file {
	my $self = shift;
	my $file = shift;

	# Do the normal stuff
	my $rv = $self->SUPER::mirror_file($file, @_);

	# Expand the tarball if needed
	unless ( -d File::Spec->catfile( $self->{extract}, $file ) ) {
		$self->{current_file} = $file;
		$self->mirror_extract( $file ) or return undef;
		delete $self->{current_file};
	}

	$self->{added}->{$file} = 1;
	delete $self->{current_file};
	$rv;
}

sub mirror_extract {
	my ($self, $file) = @_;

	# Don't try to extract anything other than normal tarballs for now.
	return 1 unless $file =~ /\.tar\.gz$/;

	# Extract the new file to the matching directory in
	# the processor source directory.
	my $local_file  = File::Spec->catfile( $self->{local}, $file   );
	my $extract_dir = File::Spec->catfile( $self->{extract}, $file );

	# Do the actual extraction
	$self->_extract_archive( $local_file, $extract_dir );
}

# Also remove any processing directory.
# And track what we have removed.
sub clean_file {
	my $self = shift;
	my $file = shift; # Absolute path

	# Convert to relative path, and clear the expansion directory
	my $relative = File::Spec->abs2rel( $file, $self->{local} );
	$self->clean_extract( $relative );

	# We are doing this in the reverse order to when we created it.
	my $rv = $self->SUPER::clean_file($file, @_);

	$self->{cleaned}->{$file} = 1;
	$rv;
}

# Remove a processing directory
sub clean_extract {
	my ($self, $file) = @_;

	# Remove the source directory, if it exists
	my $source_path = File::Spec->catfile( $self->{extract}, $file );
	if ( -e $source_path ) {
		File::Remove::remove( \1, $source_path ) or Carp::carp(
			"Cannot remove $source_path $!"
			);
	}

	1;
}





#####################################################################
# Support Methods and Error Handling

# Compile a set of filters
sub _compile_filter {
	my $self = shift;
	my $name = shift;

	# Shortcut for "no filters"
	return 1 unless $self->{$name};

	# If the filter is already a code ref, shortcut
	return 1 if _CODELIKE($self->{$name});

	# Allow a single Regexp object for the filter
	if ( _INSTANCE($self->{$name}, 'Regexp') ) {
		$self->{$name} = [ $self->{$name} ];
	}

	# Check for bad cases
	_ARRAY0($self->{$name}) or Carp::croak(
		"$name is not an ARRAY reference"
		);
	unless ( @{$self->{$name}} ) {
		delete $self->{$name};
		return 1;
	}

	# Check we only got Regexp objects
	my @filters = @{$self->{$name}};
	if ( scalar grep { ! _INSTANCE($_, 'Regexp') } @filters ) {
		return $self->_error("$name can only contains Regexp filters");
	}

	# Build the anonymous sub
	$self->{$name} = sub {
		foreach my $regexp ( @filters ) {
			return 1 if $_ =~ $regexp;
		}
		return '';
	};

	1;
}

# Encapsulate the actual extraction mechanism
sub _extract_archive {
	my ($self, $archive, $to) = @_;

	my @contents;
	SCOPE: {
		local $Archive::Tar::WARN = 0;
		@contents = eval {
			Archive::Tar->list_archive( $archive, undef, [ 'name', 'size' ] );
			};
	}
	if ( $@ or ! @contents ) {
		return $self->_tar_error("Expansion of $archive failed");
	}

	# Filter to get just the ones we want
	@contents = map { $_->{name} } grep { $_->{size} } @contents;
	if ( $self->{extract_filter} ) {
		@contents = grep &{$self->{extract_filter}}, @contents;
	}

	unless ( @contents ) {
		# Create an empty directory so it isn't checked over and over
		File::Path::mkpath( $to, $self->{trace}, $self->{dirmode} );
		return 1;
	}

	# Extract the needed files
	my $tar;
	SCOPE: {
		local $Archive::Tar::WARN = 0;
		$tar = eval {
			Archive::Tar->new( $archive );
			};
	}
	if ( $@ or ! $tar ) {
		return $self->_tar_error;
	}

	# Iterate and extract each file
	foreach my $wanted ( @contents ) {
		# Where to extract to
		my $to_file = File::Spec->catfile( $to, $wanted );
		my $to_dir  = File::Basename::dirname( $to_file );
		File::Path::mkpath( $to_dir, $self->{trace}, $self->{dirmode} );
		$self->trace("    $wanted");

		my $rv;
		SCOPE: {
			local $Archive::Tar::WARN  = 0;
			local $Archive::Tar::CHOWN = 0;
			local $Archive::Tar::CHMOD = 0;
			$rv = eval {
				$tar->extract_file( $wanted, $to_file );
			};
		}
		if ( $@ or ! $rv ) {
			# There was an error during the extraction
			$self->_tar_error( " ... failed" );
			if ( -e $to_file ) {
				# Remove any partial file left behind
				File::Remove::remove( $to_file );
			}
			return 1;
		}

		# Extraction successful
		$self->trace(" ... extracted\n");
	}

	$tar->clear;

	1;	
}

sub _tar_error {
	my $self = shift;

	# Get and clean up the message
	my $message = shift;
	if ( ! $message and $self->{current_file} ) {
		$message = "Expansion of $self->{current_file} failed";
	}
	if ( ! $message ) {
		$message = "Expansion of file failed";
	}
	$message .= " (Archive::Tar warning)" if $@ =~ /Archive::Tar warning/;
	$message .= "\n";

	$self->trace( $message );
}

1;

=pod

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPAN-Mini-Extract>

For other issues, contact the maintainer

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>, L<http://ali.as/>, 

Funding provided by The Perl Foundation.

=head1 SEE ALSO

L<CPAN::Mini>

=head1 COPYRIGHT

Copyright 2005, 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
