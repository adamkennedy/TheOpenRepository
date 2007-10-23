package Perl::Dist::Asset::Perl;

# Perl::Dist asset for the Perl source code itself

use strict;
use Carp 'croak';
use Params::Util qw{ _STRING };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.10';
}

use Object::Tiny qw{
	name
	share
	url
	license
	unpack_to
	install_to
	after
};





#####################################################################
# Constructor

sub new {
	my $self = shift->SUPER::new(@_);

	# Apply defaults and shortcuts
	if ( $self->share and ! defined $self->url ) {
		# If a share, map to a URI
		my ($dist, $name) = split /\s+/, $self->share;
		$self->trace("Finding $name in $dist... ");
		my $file = File::Spec->rel2abs(
			File::ShareDir::dist_file( $dist, $name )
		);
		unless ( -f $file ) {
			croak("Failed to find $file");
		}
		$self->{url} = URI::file->new($file)->as_string;
		$self->trace(" found\n");
	}
	$self->{unpack_to} = '' unless defined $self->unpack_to;

	# Check params
	unless ( _STRING($self->name) ) {
		croak("Missing or invalid name param");
	}
	unless ( _STRING($self->url) ) {
		croak("Missing or invalid url param");
	}
	unless ( _HASH($self->license) ) {
		croak("Missing or invalid license param");
	}
	unless ( defined $self->unpack_to and ! ref $self->unpack_to ) {
		croak("Missing or invalid unpack_to param");
	}
	unless ( _STRING($self->install_to) ) {
		croak("Missing or invalid install_to param");
	}
	unless ( _HASH($self->after) ) {
		croak("Missing or invalid after param");
	}

	return $self;
}





#####################################################################
# Support Methods

sub trace {
	print $_[0];
}

1;
