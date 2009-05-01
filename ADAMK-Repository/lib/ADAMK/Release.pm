package ADAMK::Release;

use 5.008;
use strict;
use warnings;
use Carp              ();
use File::Temp        ();
use File::Remove      ();
use Params::Util      ();
use Archive::Extract  ();
use ADAMK::Repository ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.11';
	@ISA     = qw{
		ADAMK::Role::SVN
	};
}

use Class::XSAccessor
	getters => {
		file       => 'file',
		path       => 'path',
		repository => 'repository',
		directory  => 'directory',
		distname   => 'distname',
		version    => 'version',
		extracted  => 'extracted',
	};





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check params
	unless ( Params::Util::_INSTANCE($self->repository, 'ADAMK::Repository') ) {
		Carp::croak("Did not provide a repository");
	}

	return $self;
}

sub stable {
	!! ($_[0]->version !~ /_/);
}

sub distribution {
	$_[0]->repository->distribution($_[0]->distname);
}

sub trace {
	shift->repository->trace(@_);
}

sub trunk {
	!! $_[0]->distribution;
}





#####################################################################
# SVN Integration

# Cache as we fetch
sub info {
	my $self = shift;
	$self->{_info} or
	$self->{_info} = $self->SUPER::info( $self->file, { cache => 1 } );
}

sub svn_commit {
	my $self = shift;
	$self->SUPER::svn_commit($self->file);
}

sub svn_subdir {
	die "Cannot call svn_subdir on a release";
}





#####################################################################
# Extraction

# Extracts the actual tarball into a temporary directory
sub extract {
	my $self = shift;
	unless ( $self->{extract_path} ) {
		my $temp = File::Temp::tempdir( CLEANUP => 1 );
		my $ae   = Archive::Extract->new(
			archive => $self->path,
		);
		# $self->trace("Extracting " . $self->file . "...\n");
		my $ok   = $ae->extract( to => $temp );
		Carp::croak(
			"Failed to extract " . $self->path
			. ": " . $ae->error
		) unless $ok;
		$self->{extract_path} = $ae->extract_path;
	}
	ADAMK::Release::Extract->new(
		path    => $self->{extract_path},
		release => $self,
	);
}

# Exports the distribution at the point in time that the
# release was created.
sub export {
	my $self = shift;
	unless ( $self->trunk ) {
		die("Cannot export non-trunk release " . $self->file);
	}
	$self->distribution->export( $self->info->revision, @_ );
}

sub clear {
	delete $_[0]->{extracted};
	return 1;
}





#####################################################################
# ORDB::CPAN Integration

sub upload {
	require ORDB::CPANUploads;
	ORDB::CPANUploads->import;
	ORDB::CPANUploads::Uploads->select('where filename = ?', $_[0]->file);
}





#####################################################################
# ORDB::CPANTesters Integration

sub cpan_testers {
	require ORDB::CPANTesters;
	ORDB::CPANTesters->import;
	my $rows = ORDB::CPANTesters->selectall_arrayref(
		'SELECT state, COUNT(*) AS count FROM cpanstats WHERE dist = ? and version = ? group by state',
		{}, $_[0]->distname, $_[0]->version,
	);
	my %hash = ( map { uc($_->[0]) => $_->[1] } @$rows );
	delete $hash{CPAN};
	return \%hash;
}

1;
