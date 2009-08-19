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
use warnings;
use File::Spec          0.80 ();
use HTML::Spry::DataSet 0.01 ();
use CPANDB 0.10 {
	maxage => 0
};

our $VERSION = '0.07';





#####################################################################
# Main Methods

sub run {
	my $class = shift;

	# Check the target directory
	my $dir = shift;
	unless ( -d $dir ) {
		die "Missing or invalid directory";
	}

	# Prepare the dataset object
	my $dataset = HTML::Spry::DataSet->new;

	# Build the Heavy 100 index
	$dataset->add( 'ds1',
		[ 'Rank', 'Dependencies', 'Author', 'Distribution' ],
		$class->report(
			sql_score => 'd.weight',
		),
	);

	# Build the Volatile 100 index
	$dataset->add( 'ds2',
		[ 'Rank', 'Dependents', 'Author', 'Distribution' ],
		$class->report(
			sql_score => 'd.volatility',
		),
	);

	# Build the Debian 100 index
	$dataset->add( 'ds3',
		[ 'Rank', 'Dependents', 'Author', 'Distribution' ],
		$class->report(
			sql_score => 'd.volatility * 0',
		)
	);

	# Build the Downstream 100 index
	$dataset->add( 'ds4',
		[ 'Rank', 'Dependents', 'Author', 'Distribution' ],
		$class->report(
			sql_score => 'd.volatility * 0',
		),
	);

	# Build the Meta 100 (Level 1)
	$dataset->add( 'ds5',
		[ 'Rank', 'Dependents', 'Author', 'Distribution' ],
		$class->report(
			sql_score => 'd.volatility * d.meta',
		),
	);

	# Build the Meta 100 index (Level 2)
	$dataset->add( 'ds6',
		[ 'Rank', 'Dependents', 'Author', 'Distribution' ],
		$class->report(
			sql_score => 'd.volatility * 0',
		),
	);

	# Build the Meta 100 index (Level 3)
	$dataset->add( 'ds7',
		[ 'Rank', 'Dependents', 'Author', 'Distribution' ],
		$class->report(
			sql_score => 'd.volatility * 0',
		),
	);

	# Build the FAIL 100 index
	$dataset->add( 'ds8',
		[ 'Rank', 'Score', 'Author', 'Distribution' ],
		$class->report(
			sql_score => 'd.volatility * (d.fail + d.unknown)',
		),
	);

	# Write out the daa file
	$dataset->write(
		File::Spec->catfile( $dir, 'data.html' )
	);

	return 1;
}

sub report {
	my $class  = shift;
	my %param = @_;
	my $list  = CPANDB->selectall_arrayref(
		$class->_distsql( %param ),
	);
	unless ( $list ) {
		die("Report SQL failed in " . CPANDB->dsn);
	}
	$class->_rank( $list );
	return @$list;
}





#####################################################################
# Support Methods

# Prepends ranks in place (ugly, but who cares for now)
sub _rank {
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

sub _distsql {
	my $class = shift;
	my %param = @_;
	$param{sql_limit} ||= 100;
	unless ( defined $param{sql_score} ) {
		die "Failed to define a score metric";
	}
	return <<"END_SQL";
select
	$param{sql_score} as score,
	d.author as author,
	d.distribution as distribution
from
	distribution d
order by
	score desc,
	author asc,
	distribution asc
limit
	$param{sql_limit}
END_SQL
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
