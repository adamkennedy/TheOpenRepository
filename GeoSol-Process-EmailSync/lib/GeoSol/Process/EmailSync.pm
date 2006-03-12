package GeoSol::Process::EmailSync;

use 5.006;
use strict;
use lib              ();
use Carp             ();
use File::Spec       ();
use Params::Util     '_STRING',
                     '_POSINT';
use Class::Inspector ();
use LVAS             ();
use base 'Process';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';

	# Set up the GeoSol environment if it isn't already loaded
	unless ( Class::Inspector->loaded('GeoSol') ) {

		# Can we find the GeoSol project directory
		unless ( $ENV{GEOSOL_ROOT} ) {
			Carp::croak("GEOSOL_ROOT is not defined, unable to load GeoSol modules");
		}
		unless ( -d $ENV{GEOSOL_ROOT} ) {
			Carp::croak("GEOSOL_ROOT directory '$ENV{GEOSOL_ROOT}' does not exist");
		}

		# Locate the GeoSol lib directory
		my $lib = File::Spec->catdir( $ENV{GEOSOL_ROOT}, 'cgi-bin', 'lib' );
		lib->import( $lib );

		# Load the GeoSol modules
		require GeoSol::Config;
		GeoSol::Config->import( root => $ENV{GEOSOL_ROOT} );
		require GeoSol;
		GeoSol->import();

	}
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check params
	unless ( _STRING($self->lvas_host) ) {
		Carp::croak("Did not provide a lvas_host param");
	}
	unless ( _POSINT($self->lvas_port) ) {
		Carp::croak("Did not provide a lvas_port param");
	}
	unless ( _STRING($self->lvas_login) ) {
		Carp::croak("Did not provide a lvas_login param");
	}
	unless ( _STRING($self->lvas_password) ) {
		Carp::croak("Did not provide a lvas_password param");
	}
	unless ( _STRING($self->lvas_domain) ) {
		Carp::croak("Did not provide a lvas_domain param");
	}

	# Create the LVAS client object
	$self->{lvas} = LVAS->new( $self->lvas_host, $self->lvas_port )
		or Carp::croak("Failed to create LVAS client");

	$self;
}

sub default {
	my $class = shift;

	# Create with data from the config file
	return $class->new(
		lvas_host     => GeoSol::Config->get( __PACKAGE__, 'lvas_host'     ),
		lvas_port     => GeoSol::Config->get( __PACKAGE__, 'lvas_port'     ),
		lvas_login    => GeoSol::Config->get( __PACKAGE__, 'lvas_login'    ),
		lvas_password => GeoSol::Config->get( __PACKAGE__, 'lvas_password' ),
		lvas_domain   => GeoSol::Config->get( __PACKAGE__, 'lvas_domain'   ),
		);
}

sub lvas_host {
	$_[0]->{lvas_host};
}

sub lvas_port {
	$_[0]->{lvas_port};
}

sub lvas_login {
	$_[0]->{lvas_login};
}

sub lvas_password {
	$_[0]->{lvas_password};
}

sub lvas_domain {
	$_[0]->{lvas_domain};
}

sub lvas {
	$_[0]->{lvas};
}

sub users {
	$_[0]->{users};
}

sub vs_id {
	$_[0]->{vs_id};
}

sub dns_id {
	$_[0]->{dns_id};
}

sub wanted_aliases {
	$_[0]->{wanted_aliases};
}

sub existing_aliases {
	$_[0]->{existing_aliases};
}





#####################################################################
# Main Process Methods

sub prepare {
	my $self = shift;

	# Fetch the list of users from the GeoSol database
	$self->{users} = GeoSol::Entity::User->findAll;
	unless ( defined $self->{users} ) {
		Carp::croak("Database error while finding User objects: ",
			GeoSol::Entity::User->errstr );
	}
	unless ( $self->{users} ) {
		Carp::croak("Failed to find any User objects in the database");
	}

	# Build the wanted aliases
	$self->{wanted_aliases} = {
		map  { $_->getUsername->toString => $_->getEmail->toString }
		grep { $_->role('email') } @{$self->{users}}
		};

	# Connect and login to LVAS
	$self->lvas->connect( $self->lvas_host, $self->lvas_port )
		or Carp::croak( "LVAS client failed to connect" );
	$self->lvas->authenticate( $self->lvas_login, $self->lvas_password )
		or Carp::croak( "LVAS client failed to login" );

	# Find the domain ids
	$self->{vs_id} = $self->lvas->locate_vserver( $self->lvas_domain )
		or Carp::croak( "Failed to find VSID for "
			. $self->lvas_domain );
	$self->{dns_id} = $self->lvas->locate_domain( $self->lvas_domain )
		or Carp::croak( "Failed to find DNSID for "
			. $self->lvas_domain );

	# Get the hash of existing aliases
	my @existing_list = $self->lvas->vserver_list_mail_aliases( $self->vs_id );
	if ( @existing_list and ! defined $existing_list[0] ) {
		Carp::croak( "Failed to find existing mail aliases" );
	}
	@existing_list = grep {
		$_->[3] eq 'remote'
		and
		length($_->[1])
		} @existing_list;
	$self->{existing_aliases} = {
		map { $_->[1] => $_->[2] } @existing_list
		};

	1;
}

sub run {
	my $self = shift;

	# Find the emails to add
	foreach my $email ( keys %{$self->{wanted_aliases}} ) {
		next if $self->{existing_aliases}->{$email};
		$self->lvas->vserver_create_remote_mail_alias(
			$self->vs_id, $self->dns_id,
			$email => $self->{wanted_aliases}->{$email},
			) or Carp::croak(
				"Failed to add $email => $self->{wanted_aliases}->{$email} address"
				);
	}

	# Find the emails to remove
	foreach my $email ( keys %{$self->{existing_aliases}} ) {
		next if $self->{wanted_aliases}->{$email};
		$self->lvas->vserver_remove_mail_alias(
			$self->vs_id, $self->dns_id,
			$email,
			) or Carp::croak(
				"Failed to remove $email address redirect"
				);
	}

	# Clean up
	$self->lvas->disconnect;

	1;
}

1;
