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
use Google::Chart 0.05013;
use CPANDB 0.10 {
	maxage => 0
};

our $VERSION = '0.09';





#####################################################################
# Main Methods

sub new {
	my $class = shift;

	# Create the basic object
	my $self = bless {
		spry => HTML::Spry::DataSet->new,
		@_,
	}, $class;

	# Check params
	unless ( defined $self->dir and -d $self->dir ) {
		die "Missing or invalid directory";
	}

	return $self;
}

sub spry {
	$_[0]->{spry};
}

sub dir {
	$_[0]->{dir};
}

sub file {
	File::Spec->catfile( $_[0]->dir, $_[1] );
}

sub run {
	my $self = shift;

	# Build the Heavy 100 index
	$self->dataset( 'ds1' => 'Heavy 100',
		'd.weight',
		[ 'Rank', 'Dependencies', 'Author', 'Distribution' ]
	);

	# Build the Volatile 100 index
	$self->dataset( 'ds2' => 'Volatile 100',
		'd.volatility',
		[ 'Rank', 'Dependents', 'Author', 'Distribution' ]
	);

	# Build the Debian 100 index
	$self->dataset( 'ds3' => 'Debian 100',
		'd.volatility * 0',
		[ 'Rank', 'Dependents', 'Author', 'Distribution' ]
	);

	# Build the Downstream 100 index
	$self->dataset( 'ds4' => 'Downstream 100',
		'd.volatility * 0',
		[ 'Rank', 'Dependents', 'Author', 'Distribution' ]
	);

	# Build the Meta 100 (Level 1)
	$self->dataset( 'ds5' => 'Meta 100',
		'd.volatility * ( 1 - d.meta )',
		[ 'Rank', 'Dependents', 'Author', 'Distribution' ]
	);

	# Build the Meta 100 index (Level 2)
	$self->dataset( 'ds6' => 'Meta 100',
		'd.volatility * 0',
		[ 'Rank', 'Dependents', 'Author', 'Distribution' ]
	);

	# Build the Meta 100 index (Level 3)
	$self->dataset( 'ds7' => 'Meta 100',
		'd.volatility * 0',
		[ 'Rank', 'Dependents', 'Author', 'Distribution' ]
	);

	# Build the FAIL 100 index
	$self->dataset( 'ds8' => 'FAIL 100',
		'd.volatility * (d.fail + d.unknown)',
		[ 'Rank', 'Score', 'Author', 'Distribution' ]
	);

	# Write out the daa file
	$self->spry->write( $self->file('data.html') );

	return 1;
}

sub dataset {
	my ($self, $name, $title, $score, $header) = @_;
	my @report = $self->report(
		sql_score => $score,
	);
	$self->spry->add( $name, $header, @report );
	$self->chart( $title, @report )->render_to_file(
		filename => $self->file( "$name.png" ),
	);
}

sub report {
	my $self  = shift;
	my %param = @_;
	my $list  = CPANDB->selectall_arrayref(
		$self->_distsql( %param ),
	);
	unless ( $list ) {
		die("Report SQL failed in " . CPANDB->dsn);
	}
	$self->_rank( $list );
	return @$list;
}

sub chart {
	my $self   = shift;
	my $title  = shift;
	my @report = map { $_->[1] } @_;
	my $scale  = List::Util::max @report;
	my @data   = map {
		$scale ? ($_ / $scale * 100) : 0
	} @report;
	Google::Chart->new(
		title => $title,
		type  => 'Line',
		data  => \@data,
	);
}





#####################################################################
# Support Methods

# Prepends ranks in place (ugly, but who cares for now)
sub _rank {
	my $self = shift;
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
	my $self = shift;
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
