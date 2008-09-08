package Mirror::URI;

# Abstract base module to allow easy extension to other file formats.

use 5.00503;
use strict;
use Carp         ();
use File::Spec   ();
use Time::HiRes  ();
use Time::Local  ();
use URI          ();
use URI::file    ();
use URI::http    ();
use Params::Util qw{ _STRING _POSINT _ARRAY0 _INSTANCE };
use LWP::Simple  ();

# Time values have an extra 5 minute fudge factor
use constant ONE_DAY     => 86700;
use constant TWO_DAYS    => 172800;
use constant THIRTY_DAYS => 2592000;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.04_01';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Clean up params
	$self->{class} = $class;
	$self->{valid} = !! $self->valid;
	if ( $self->valid ) {
		if ( _STRING($self->master) ) {
			$self->{master} = URI->new( $self->master );
		}
		unless ( _INSTANCE($self->master, 'URI') ) {
			Carp::croak("Missing or invalid 'master' value");
		}
		if ( _STRING($self->{timestamp}) and ! _POSINT($self->{timestamp}) ) {
			unless ( $self->{timestamp} =~ /^(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)Z$/ ) {
				Carp::croak("Invalid timestamp format");
			}
			$self->{timestamp} = Time::Local::timegm( $6, $5, $4, $3, $2 - 1, $1 );
		}
		my $mirrors = $self->{mirrors};
		unless ( _ARRAY0($mirrors) ) {
			croak("Invalid mirror list");
		}
		foreach my $i ( 0 .. $#$mirrors ) {
			next unless _STRING($mirrors->[$i]);
			$mirrors->[$i] = URI->new( $mirrors->[$i] );
		}
	}

	return $self;
}

sub class {
	$_[0]->{class};
}

sub version {
	$_[0]->{version};
}

sub uri {
	$_[0]->{uri};
}

sub name {
	$_[0]->{name};
}

sub master {
	$_[0]->{master};
}

sub timestamp {
	$_[0]->{timestamp};
}

sub mirrors {
	return ( @{ $_[0]->{mirrors} } );
}

sub valid {
	$_[0]->{valid};
}

sub lastget {
	$_[0]->{lastget};
}

sub lag {
	$_[0]->{lag};
}

sub age {
	$_[0]->{lastget} - $_[0]->{timestamp};
}





#####################################################################
# Load Methods

sub read {
	my $class = shift;

	# Check the file to read
	my $root = shift;
	unless ( defined _STRING($root) and -d $root ) {
		Carp::croak("Directory '$root' does not exist");
	}

	# Convert to a usable URI
	my $uri = URI::file->new(
		File::Spec->canonpath(
			File::Spec->rel2abs($root)
		)
	)->canonical;

	# In a URI a directory must have an explicit trailing slash
	$uri->path( $uri->path . '/' );

	# Hand off to the URI fetcher
	return $class->get( $uri, @_ );
}

sub get {
	my $class = shift;

	# Check the URI
	my $base = shift;
	unless ( _INSTANCE($base, 'URI') ) {
		Carp::croak("Missing or invalid URI");
	}
	unless ( $base->path =~ /\/$/ ) {
		Carp::croak("URI must have a trailing slash");
	}

	# Find the file within the root path
	my %self = (
		uri => URI->new( $class->filename )->abs($base)->canonical,
	);

	# Pull the file and time it
	$self{lastget} = Time::HiRes::time;
	$self{string}  = LWP::Simple::get($self{uri});
	$self{lag}     = Time::HiRes::time - $self{lastget};
	unless ( defined $self{string} ) {
		return $class->new( %self, valid => 0 );
	}

	# Parse the file
	my $hash = $class->parse( $self{string} );
	unless ( ref $hash eq 'HASH' ) {
		return $class->new( %self, valid => 0 );
	}

	# Create the object
	return $class->new( %$hash, %self, valid => 1 );
}





#####################################################################
# Populate Elements

sub get_master {
	my $self = shift;
	if ( _INSTANCE($self->master, 'URI') ) {
		# Load the master
		my $master = $self->class->get($self->master);
		$self->{master} = $master;
	}
	return $self->master;
}

sub get_mirror {
	my $self = shift;
	my $i    = shift;
	my $uri  = $self->{mirrors}->[$i];
	unless ( defined $uri ) {
		Carp::croak("No mirror with index $i");
	}
	if ( _INSTANCE($uri, 'URI') ) {
		my $mirror = $self->class->get($uri);
		$self->{mirrors}->[$i] = $mirror;
	}
	return $self->{mirrors}->[$i];
}

1;
