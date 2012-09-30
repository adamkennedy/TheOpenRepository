package GitHub::Extract;

use strict;
use warnings;
use HTTP::Tiny       ();
use Archive::Extract ();

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	
	# Generate the URL from the pieces
	unless ( $self->url ) {
		# Apply defaults
		unless ( $self->branch ) {
			$self->{branch} = 'master';
		}

		# Check params to make the url
		my $username = $self->username;
		unless ( $username ) {
			die "Did not provide a username";
		}

		my $repository = $self->repository;
		unless ( $repository ) {
			die "Did not provide a repository name";
		}

		my $branch = $self->branch;
		unless ( $branch ) {
			die "Did not provide a branch name";
		}

		$self->{url} = "https://github.com/$username/$repository/zipball/$branch";
	}

	return $self;
}

sub username {
	$_[0]->{username};
}

sub repository {
	$_[0]->{repository};
}

sub branch {
	$_[0]->{branch};
}

sub url {
	$_[0]->{url};
}

1;
