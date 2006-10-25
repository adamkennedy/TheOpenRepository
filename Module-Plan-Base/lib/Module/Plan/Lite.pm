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
	$VERSION = '0.04';
}

use base 'Module::Plan::Base';





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	# Parsing here isn't the best, but this is Lite after all
	foreach ( $self->lines ) {
		# Strip whitespace and comments
		next if /^\s*(?:\#|$)/;

		# The line is a file
		$self->add_file( $_ );
	}

	$self;
}

sub run {
	my $self = shift;
	foreach my $name ( $self->names ) {
		$self->_cpan_inject( $name );
		$self->_cpan_install( $name );
	}
}

1;
