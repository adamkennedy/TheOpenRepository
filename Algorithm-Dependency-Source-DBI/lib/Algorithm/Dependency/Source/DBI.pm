package Algorithm::Dependency::Source::DBI;

=pod

=head1 NAME

Algorithm::Dependency::Source::DBI - Database source for Algorithm::Dependency

=head1 SYNOPSIS

  The author is an idiot

=head1 DESCRIPTION

The author is lame

=head1 METHODS

=cut

use 5.005;
use strict;
use base 'Algorithm::Dependency::Source';
use Params::Util qw{ _INSTANCE _STRING };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.104';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;

	# Create the object
	my $self = bless { @_ }, $class;

	# Check params
	unless ( _INSTANCE($self->dbh, 'DBI::dbh') ) {
		Carp::croak("The dbh param is not a DBI database handle");
	}
	unless ( $self->select_ids ) {
		Carp::croak("Did not provide the select_ids query");
	}
	unless ( $self->select_depends ) {
		Carp::croak("Did not provide the select_depends query");
	}

	return $self;
}

sub dbh {
	$_[0]->{dbh};
}

sub select_ids {
	$_[0]->{select_ids};
}

sub select_depends {
	$_[0]->{select_depends};
}

1;

=pod

=head1 SUPPORT

To file a bug against this module, use the CPAN bug tracking system

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Algorithm-Dependency-Source-DBI>

For other comments, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>

=head1 SEE ALSO

L<Algorithm::Dependency>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
