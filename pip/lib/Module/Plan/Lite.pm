package Module::Plan::Lite;

=pod

=head1 NAME

Module::Script::Lite - Lite installation scripts for third-party modules

=head1 SYNOPSIS

The following is the contents of your default.pip file.

  Module::Plan::Lite
  
  Install-This-First-1.00.tar.gz
  Install-This-Second.1.31.tar.gz
  extensions/This-This-0.02.tar.gz
  /absolute/Module-Location-4.12.tar.gz

=cut

use strict;
use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.05';
}

use base 'Module::Plan::Base';
use URI ();





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	# Parsing here isn't the best, but this is Lite after all
	foreach ( $self->lines ) {
		# Strip whitespace and comments
		next if /^\s*(?:\#|$)/;

		# Create the URI
		my $uri = URI->new_abs( $_, $self->p5i_uri );
		unless ( $uri ) {
			croak("Failed to get the URI for $_");
		}

		# Add the uri
		$self->add_uri( $uri );
	}

	$self;
}

sub fetch {
	my $self = shift;

	# Download the needed modules
	foreach my $name ( $self->names ) {
		next if $self->{dists}->{$name};
		$self->_fetch_uri( $name );
	}

	return 1;
}

sub run {
	my $self = shift;

	# Fetch again
	$self->fetch;

	# Download the needed modules
	foreach my $name ( $self->names ) {
		next if $self->{dists}->{$name};
		$self->_fetch_uri( $name );
	}

	# Inject them into CPAN and install
	foreach my $name ( $self->names ) {
		$self->_cpan_inject( $name );
		$self->_cpan_install( $name );
	}
}

1;
