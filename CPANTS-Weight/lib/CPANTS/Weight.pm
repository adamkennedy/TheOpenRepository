package CPANTS::Weight;

=pod

=head1 NAME

CPAN::Weight - Graph based weights for CPAN Distributions

=head1 DESCRIPTION

C<CPAN::Weight> is a module that consumes the CPANTS database, and
generates a variety of graph-based weighting values for the distributions,
producing a SQLite database of the weighting data, for use in higher-level
applications that work with the CPANTS data.

=head1 METHODS

=cut

use 5.008;
use strict;
use warnings;
use File::Spec                         ();
use File::HomeDir                      ();
use Algorithm::Dependency              ();
use Algorithm::Dependency::Weight      ();
use Algorithm::Dependency::Source::DBI ();

# Generate the class tree
use ORLite 1.19 {
	file => File::Spec->catfile(
		File::HomeDir->my_data,
		($^O eq 'MSWin32' ? 'Perl' : '.perl'),
		'CPANTS-Weight',
	),
	create => sub {
		$_[0]->do(<<'END_SQL');
create table dist_weight (
	id         integer      not null primary key,
	dist       varchar(255) not null unique,
	weight     integer      not null,
	configure  integer      not null,
	build      integer      not null,
	test       integer      not null,
	runtime    integer      not null,
	volatility integer      not null,
)
	},
	user_version => 0,
};

# Load the CPANTS database (This could take a while...)
use ORDB::CPANTS;





#####################################################################
# Main Processing

sub run {
	my $class = shift;
	die('CODE INCOMPLETE');
}

sub source {
	my $class = shift;
	Algorithm::Dependency::Source::DBI->new(
		dbh            => $class->dbh,
		select_ids     => '',
		select_depends => '',
	);
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPANTS-Weight>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
