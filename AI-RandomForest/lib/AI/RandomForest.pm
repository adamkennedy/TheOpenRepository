package AI::RandomForest;

use 5.16.0;
use strict;
use warnings;
use Params::Util           1.00 ();
use List::MoreUtils        0.30 ();
use AI::RandomForest::Tree      ();
use AI::RandomForest::Branch    ();
use AI::RandomForest::Sample    ();
use AI::RandomForest::Table     ();
use AI::RandomForest::Frame     ();
use AI::RandomForest::Selection ();

our $VERSION = '0.01';





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless {
		trees => [ ],
	}, $class;

	return $self;
}

sub count {
	return scalar @{$_[0]->{trees}};
}

sub trees {
	return @{$_[0]->{trees}};
}





######################################################################
# Main Methods

sub add {
	push @{$_[0]->{trees}}, $_[1];
}

sub classify {
	my $self   = shift;
	my $sample = shift;
	my $total  = 0;
	foreach my $tree ( $self->trees ) {
		$total += $tree->classify($sample);
	}
	return $total / $self->trees;
}

1;

__END__

=pod

=head1 NAME

AI::RandomForest - A basic implementation of a Random Forest in Perl

=head1 DESCRIPTION

B<AI::RandomForest> is a simple implementation of a random forest in Perl.

=head1 SUPPORT

Bugs should always be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AI-RandomForest>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2012 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
