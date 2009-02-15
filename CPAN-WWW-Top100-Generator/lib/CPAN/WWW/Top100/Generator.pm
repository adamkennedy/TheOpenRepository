package CPAN::WWW::Top100::Generator;

=pod

=head1 NAME

CPAN::WWW::Top100::Generator - Create or update the website for http://ali.as/top100

=head1 DESCRIPTION

This module is used to generate the website content for the B<CPAN Top 100> website.

This module (for now) has no moving parts...

=cut

use 5.008;
use strict;
use CPANTS::Weight 0.02 ();
use HTML::Spry::DataSet ();

our $VERSION = '0.02';

# SQL to select the Heavy 100
use constant SQL_H100 => <<'END_SQL';
select
	d.weight as score,
	a.pauseid,
	d.dist
from
	dist_weight d,
	author_weight a
where
	d.author = a.id
order by
	score desc,
	a.pauseid asc,
	d.dist asc
limit 100
END_SQL

# SQL to select the Volatile 100
use constant SQL_V100 => <<'END_SQL';
select
	d.volatility as score,
	a.pauseid,
	d.dist
from
	dist_weight d,
	author_weight a
where
	d.author = a.id
order by
	score desc,
	a.pauseid asc,
	d.dist asc
limit 100
END_SQL

# SQL to select the Debian Most Wanted
use constant SQL_D100 => <<'END_SQL';
select
	d.volatility * d.debian_candidate as score,
	a.pauseid,
	d.dist
from
	dist_weight d,
	author_weight a
where
	d.author = a.id
order by
	score desc,
	a.pauseid asc,
	d.dist asc
limit 100
END_SQL





#####################################################################
# Main Methods

sub run {
	my $class = shift;

	# Check the target directory
	my $dir = shift;
	unless ( -d $dir ) {
		die "Missing or invalid directory";
	}

	# Create or update the weighting database
	CPANTS::Weight->run;

	# Prepare the dataset object
	my $dataset = HTML::Spry::DataSet->new;
	
	# Build the Heavy 100 index
	my $h100 = CPANTS::Weight->selectall_arrayref( SQL_H100 );
	$class->prepend_rank( $h100 );
	$dataset->add( 'ds1',
		[ 'Rank', 'Dependencies', 'Author', 'Distribution' ],
		@$h100,
	);

	# Build the Volatile 100 index
	my $v100 = CPANTS::Weight->selectall_arrayref( SQL_V100 );
	$class->prepend_rank( $v100 );
	$dataset->add( 'ds2',
		[ 'Rank', 'Dependents', 'Author', 'Distribution' ],
		@$v100,
	);

	# Build the Debian 100 index
	my $d100 = CPANTS::Weight->selectall_arrayref( SQL_D100 );
	$class->prepend_rank( $d100 );
	$dataset->add( 'ds3',
		[ 'Rank', 'Dependents', 'Author', 'Distribution' ],
		@$d100,
	);

	# Write out the daa file
	$dataset->write(
		File::Spec->catfile( $dir, 'data.html' )
	);

	return 1;
}

# Prepends ranks in place (ugly, but who cares for now)
sub prepend_rank {
	my $class = shift;
	my $table = shift;

	my $rank  = 0;
	my @ranks = ();
	foreach my $i ( 0 .. $#$table ) {
		if ( $i == 0 ) {
			$rank = 1;
		} elsif ( $table->[$i]->[0] ne $table->[$i - 1]->[0] ) {
			$rank = $i + 1;
		}
		#if ( $i > 0 and $table->[$i]->[0] eq $table->[$i - 1]->[0] ) {
		#	push @ranks, "$rank=";
		#} elsif ( $i < $#$table and $table->[$i]->[0] eq $table->[$i + 1]->[0] ) {
		#	push @ranks, "$rank=";
		#} else {
			push @ranks, $rank;
		#}
	}

	# Prepend the rank to the table
	foreach my $i ( 0 .. $#$table ) {
		unshift @{ $table->[$i] }, $ranks[$i];
	}

	return $table;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPAN-WWW-Top100-Generator>

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
