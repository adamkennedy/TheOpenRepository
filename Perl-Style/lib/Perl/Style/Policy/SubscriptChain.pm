package Perl::Style::Policy::SubscriptChain;

=pod

=head1 NAME

Perl::Style::Policy::SubscriptChain - Should we join subscripts with an arrow

=head1 DESCRIPTION



=head1 METHODS

=cut

use 5.008;
use strict;
use warnings;
use PPI::Transform ();

our $VERSION = '0.01';
our @ISA     = 'PPI::Transform';

=pod

=head2 new

Creates a new policy transform object. Takes a single required parameter
C<arrow> which should be true if we should always join sequential subscript
braces with an arrow operator, or false if we should never do so.

=cut

sub new {
	my $class = shift;
	my %param = @_ == 1 ? ( arrow => shift ) : @_;
	my $self  = bless \%param, $class;

	# Check params
	unless ( defined $self->{arrow} ) {
		die "Did not provide an 'arrow' param to " . __PACKAGE__;
	}

	return $self;
}





######################################################################
# Transform Implementation

sub document {
	my $self     = shift;
	my $document = shift;

	if ( $self->{arrow} ) {
		# Find all subscript chains that do not have an arrow
		my $bad = $document->find( sub {
			$_[1]->isa('PPI::Structure::Subscript') or return 0;
			my $post = $_[1]->next_sibling          or return 0;
			$post->isa('PPI::Structure::Subscript') or return 0;
			return 1;
		} ) or return undef;

		# Add the arrow operator between them
		foreach my $token ( @$bad ) {
			$token->insert_after(
				PPI::Token::Operator->new('->')
			);
		}

		return scalar @$bad;

	} else {
		# Find arrow operators with subscript blocks on either side
		my $bad = $document->find( sub {
			$_[1]->isa('PPI::Token::Operator')       or return 0;
			$_[1]->content eq '->'                   or return 0;
			my $left = $_[1]->previous_sibling       or return 0;
			$left->isa('PPI::Structure::Subscript')  or return 0;
			my $right = $_[1]->next_sibling          or return 0;
			$right->isa('PPI::Structure::Subscript') or return 0;
			return 1;
		} ) or return undef;

		# Remove the =paragraph
		foreach my $token ( @$bad ) {
			$token->delete;
		}

		return scalar @$bad;
	}
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Style>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Tidy>, L<Perl::Style>

=head1 COPYRIGHT

Copyright 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
