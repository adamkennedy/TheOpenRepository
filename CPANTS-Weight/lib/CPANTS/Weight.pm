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
use File::Spec                            ();
use File::HomeDir                         ();
use Algorithm::Dependency 1.108           ();
use Algorithm::Dependency::Weight         ();
use Algorithm::Dependency::Source::DBI    ();
use Algorithm::Dependency::Source::Invert ();

# Generate the class tree
use ORLite 1.19 {
	file => File::Spec->catfile(
		File::HomeDir->my_data,
		($^O eq 'MSWin32' ? 'Perl' : '.perl'),
		'CPANTS-Weight',
		'CPANTS-Weight.sqlite',
	),
	create => sub {
		$_[0]->do(<<'END_SQL');
create table author_weight (
	id         integer      not null primary key,
	pauseid    varchar(255) not null unique
);
END_SQL

		$_[0]->do(<<'END_SQL');
create table dist_weight (
	id         integer      not null primary key,
	dist       varchar(255) not null unique,
	author     integer      not null,
	weight     integer          null,
	volatility integer          null
)
END_SQL
	},
	user_version => 0,
};

# Load the CPANTS database (This could take a while...)
use ORDB::CPANTS;

# Common string fragments
my $SELECT_IDS     = <<'END_SQL';
select
	id
from
	dist
where
	id > 0
END_SQL

my $SELECT_DEPENDS = <<'END_SQL';
select
	dist,
	in_dist
from
	prereq
where
	in_dist is not null
	and
	dist > 0
	and
	in_dist > 0
END_SQL





#####################################################################
# Main Method

sub run {
	my $class = shift;

	# Skip if the output database is newer than the input database
	# (but is not a new database)
	my $input_t  = (stat(ORDB::CPANTS->sqlite))[9];
	my $output_t = (stat(CPANTS::Weight->sqlite))[9];
	# if ( $output_t > $input_t and CPANTS::Weight::AuthorWeight->count ) {
	#	return 1;
	# }
	
	# Get the various dist scores
	my $weight     = CPANTS::Weight->all_weights;
	my $volatility = CPANTS::Weight->all_volatility;

	# Populate the AuthorWeight objects
	CPANTS::Weight->begin;
	CPANTS::Weight::AuthorWeight->truncate;
	foreach my $author (
		ORDB::CPANTS::Author->select('where pauseid is not null')
	) {
		CPANTS::Weight::AuthorWeight->create(
			id      => $author->id,
			pauseid => $author->pauseid,
		);
	}
	CPANTS::Weight->commit;

	# Populate the DistWeight objects
	CPANTS::Weight->begin;
	CPANTS::Weight::DistWeight->truncate;
	foreach my $dist (
		ORDB::CPANTS::Dist->select(
			'where author not in ( select id from author where pauseid is null )'
		)
	) {
		my $id = $dist->id;
		CPANTS::Weight::DistWeight->create(
			id         => $id,
			dist       => $dist->dist,
			author     => $dist->author,
			weight     => $weight->{$id},
			volatility => $volatility->{$id},
		);
	}
	CPANTS::Weight->commit;

	return 1;
}





#####################################################################
# Methods for all dependencies

sub all_source {
	Algorithm::Dependency::Source::DBI->new(
		dbh            => ORDB::CPANTS->dbh,
		select_ids     => "$SELECT_IDS",
		select_depends => "$SELECT_DEPENDS and ( is_prereq = 1 or is_build_prereq = 1 )",
	);
}

sub all_weights {
	Algorithm::Dependency::Weight->new(
		source => $_[0]->all_source,
	)->weight_all;
}

sub all_volatility {
	Algorithm::Dependency::Weight->new(
		source => Algorithm::Dependency::Source::Invert->new(
			$_[0]->all_source,
		),
	)->weight_all;
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
