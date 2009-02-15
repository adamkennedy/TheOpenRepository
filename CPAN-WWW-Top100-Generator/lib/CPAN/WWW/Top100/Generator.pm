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
use CPANTS::Weight      ();
use HTML::Spry::DataSet ();

our $VERSION = '0.01';

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
	
	# Raw data for the Heavy 100
	my $h100 = CPANTS::Weight->selectall_arrayref( <<'END_SQL' );
select
	d.weight,
	a.pauseid,
	d.dist
from
	dist_weight d,
	author_weight a
where
	d.author = a.id
order by
	d.weight desc,
	a.pauseid asc,
	d.dist asc
limit 100
END_SQL

	# Calculate the ranks
	SCOPE: {
		my $rank  = 0;
		my @ranks = ();
		foreach my $i ( 0 .. $#$h100 ) {
			if ( $i == 0 ) {
				$rank = 1;
			} elsif ( $h100->[$i]->[0] ne $h100->[$i - 1]->[0] ) {
				$rank = $i + 1;
			}
			#if ( $i > 0 and $h100->[$i]->[0] eq $h100->[$i - 1]->[0] ) {
			#	push @ranks, "$rank=";
			#} elsif ( $i < $#$h100 and $h100->[$i]->[0] eq $h100->[$i + 1]->[0] ) {
			#	push @ranks, "$rank=";
			#} else {
				push @ranks, $rank;
			#}
		}

		# Add the merged rank + h100 to the dataset
		$dataset->add( 'ds1',
			[ 'Rank', 'Dependencies', 'Author', 'Distribution' ],
			map { [
				$ranks[$_],
				@{$h100->[$_]}
			] } (0 .. $#$h100)
		);
	}

	# Raw data for the Heavy 100
	my $v100 = CPANTS::Weight->selectall_arrayref( <<'END_SQL' );
select
	d.volatility,
	a.pauseid,
	d.dist
from
	dist_weight d,
	author_weight a
where
	d.author = a.id
order by
	d.volatility desc,
	a.pauseid asc,
	d.dist asc
limit 100
END_SQL

	# Calculate the ranks
	SCOPE: {
		my $rank  = 0;
		my @ranks = ();
		foreach my $i ( 0 .. $#$v100 ) {
			if ( $i == 0 ) {
				$rank = 1;
			} elsif ( $v100->[$i]->[0] ne $v100->[$i - 1]->[0] ) {
				$rank = $i + 1;
			}
			#if ( $i > 0 and $v100->[$i]->[0] eq $v100->[$i - 1]->[0] ) {
			#	push @ranks, "$rank=";
			#} elsif ( $i < $#$v100 and $v100->[$i]->[0] eq $v100->[$i + 1]->[0] ) {
			#	push @ranks, "$rank=";
			#} else {
				push @ranks, $rank;
			#}
		}

		# Add the merged rank + v100 to the dataset
		$dataset->add( 'ds2',
			[ 'Rank', 'Dependents', 'Author', 'Distribution' ],
			map { [
				$ranks[$_],
				@{$v100->[$_]}
			] } (0 .. $#$v100)
		);
	}

	# Write out the daa file
	$dataset->write(
		File::Spec->catfile( $dir, 'data.html' )
	);

	1;
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
