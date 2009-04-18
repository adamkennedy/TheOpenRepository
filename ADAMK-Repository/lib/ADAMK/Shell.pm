package ADAMK::Shell;

use 5.008;
use strict;
use warnings;
use Class::Inspector  ();
use ADAMK::Repository ();

use Object::Tiny::XS qw{
	repository
};

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.10';
	@ISA     = qw{
		ADAMK::Role::Trace
		ADAMK::Role::File
	};
}





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Create the repository from the root
	$self->{repository} = ADAMK::Repository->new(
		path  => $self->path,
		trace => $self->{trace},
	);

	return $self;
}





#####################################################################
# Information

sub usage {
	print ADAMK::Util::table(
		[ 'Command',                         'Params' ],
		[ 'usage',                                    ],
		[ 'report_module_install_versions',           ],
		[ 'module',                          'MODULE' ],
		[ 'compare_tarball_latest',          'MODULE' ],
		[ 'compare_tarball_stable',          'MODULE' ],
		[ 'compare_export_latest',           'MODULE' ],
		[ 'compare_export_stable',           'MODULE' ],
		[ 'update_current_release_datetime', 'MODULE' ],
		[ 'update_current_perl_versions',    'MODULE' ],
	);
}

sub module {
	my $self = shift;

	# Get the distribution
	my $name = $self->_distname(shift);
	my $dist = $self->repository->distribution($name);
	unless ( $dist ) {
		die("The distribution '$_[0]' does not exist");
	}

	# Show the information
	my $changes = $dist->changes;
	my $release = $dist->latest;
	print ADAMK::Util::table(
		[ 'Property',     'Value'     ],
		[ 'Name',         $dist->name ],
		[ 'Directory',    $dist->path ],
		( $changes ?
			[ 'Trunk   Version', $changes->current->version ]
		: () ),
		( $release ?
			[ 'Release Version', $release->version ]
		: () ),
		[ 'Trunk   SVN', $dist->svn_revision ],
		( $release ?
			[ 'Release SVN', $release->svn_revision ]
		: () ),
		[ 'Trunk   Author', $dist->svn_author ],
		( $release ?
			[ 'Release Author', $release->svn_author ]
		: () ),
		[ 'Trunk   Date', $dist->svn_date ],
		( $release ?
			[ 'Release Date', $release->svn_date ]
		: () ),
	);
}





#####################################################################
# Araxis Merge Commands

sub compare_tarball_latest {
	shift->repository->compare_tarball_latest(@_);
}

sub compare_tarball_stable {
	shift->repository->compare_tarball_stable(@_);
}

sub compare_export_latest {
	shift->repository->compare_export_latest(@_);
}

sub compare_export_stable {
	shift->repository->compare_export_stable(@_);
}





#####################################################################
# Reports

sub report_module_install_versions {
	my $self = shift;
	my $repo = $self->repository;
	my @rows = ();
	foreach my $dist ( $repo->distributions_released ) {
		my $name   = $dist->name;
		my $svn    = $dist->mi;
		my $latest = $dist->latest;

		# Add the final row to the table
		$svn = '~' unless defined $svn;
		push @rows, [ $name, $svn ];
	}

	# Generate the table
	my $version_order = !! $_[0];
	print ADAMK::Util::table(
		[ 'Name', 'Version' ],
		sort { $version_order
			? $b->[1] <=> $a->[1]
			: $a->[0] cmp $b->[0]
		}
		@rows,
	);
}





#####################################################################
# Custom Commands

sub update_current_release_datetime {
	my $self = shift;
	my $name = $self->_distname(shift);
	my $dist = $self->repository->distribution($name);

	# Is there an unreleased version
	my $checkout = $dist->checkout;
	my $released = $dist->latest->version;
	my $current  = $checkout->changes->current->version;
	if ( $released eq $current ) {
		# We have already released the current version
		die("Version $current has already been released");
	}

	# Update the Changes file
	my $date = $checkout->update_current_release_datetime;

	# Commit if we are allowed
	$checkout->svn_commit(
		-m => "[bot] Set version $current release date to $date",
		'Changes',
	);
}

sub update_current_perl_versions {
	my $self = shift;
	my $dist = $self->repository->distribution(shift);

	# Is there an unreleased version
	my $checkout = $dist->checkout;
	my $released = $dist->latest->version;
	my $current  = $checkout->changes->current->version;
	if ( $released eq $current ) {
		# We have already released the current version
		die("Version $current has already been released");
	}

	# Update the $VERSION strings
	my $changed = $checkout->update_current_perl_versions;
	unless ( $changed ) {
		$self->trace("No files were updated");
	}

	# Commit if we are allowed
	$checkout->svn_commit(
		-m => "[bot] Changed \$VERSION strings from $released to $current",
	);
}





#####################################################################
# Support Methods

sub _distname {
	my $self = shift;
	my $name = shift;
	$name =~ s/:+/-/g;
	return $name;
}

1;
