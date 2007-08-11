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
use Params::Util qw{  _STRING _ARRAY _INSTANCE };
use Algorithm::Dependency::Item ();

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

	# Apply defaults
	if ( _STRING($self->{select_ids}) ) {
		$self->{select_ids} = [ $self->{select_ids} ];
	}
	if ( _STRING($self->{select_depends}) ) {
		$self->{select_depends} = [ $self->{select_depends} ];
	}

	# Check params
	unless ( _INSTANCE($self->dbh, 'DBI::db') ) {
		Carp::croak("The dbh param is not a DBI database handle");
	}
	unless ( _ARRAY($self->select_ids) and _STRING($self->select_ids->[0]) ) {
		Carp::croak("Missing or invalid select_ids param");
	}
	unless ( _ARRAY($self->select_depends) and _STRING($self->select_depends->[0]) ) {
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





#####################################################################
# Main Functionality

sub _load_item_list {
	my $self = shift;

	# Get the list of ids
	my $ids  = $self->dbh->selectcol_arrayref(
		$self->select_ids->[0],
		{}, # No options
		@{$self->select_ids}[1..-1],
		);
	my %hash = map { $_ => [ ] } @$ids;

	# Get the list of links
	my $depends = $self->dbh->selectall_arrayref(
		$self->select_depends->[0],
		{}, # No options
		@{$self->select_depends}[1..-1],
		);
	foreach my $depend ( @$depends ) {
		next unless $hash{$depend->[0]};
		push @{$hash{$depend->[0]}}, $depend->[1];
	}

	# Now convert to items
	my @items = map {
		Algorithm::Dependency::Item->new( $_, @{$hash{$_}} )
		or return undef;
		} keys %hash;

	\@items;
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
