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
use File::Spec    ();
use File::HomeDir ();
use DBI           ();

# Where do we store the data
use constant FILE => File::Spec->catfile(
	File::HomeDir->my_data,
	($^O eq 'MSWin32' ? 'Perl' : '.perl'),
	'CPANTS-Weight',
);

# Generate the class tree
use ORLite {
	file   => FILE,
	create => 1,
};
