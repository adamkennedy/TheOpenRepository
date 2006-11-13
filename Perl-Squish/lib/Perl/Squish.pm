package Perl::Squish;

=pod

=head1 NAME

Perl::Squish - Reduce Perl code to a few characters as possible

=head1 DESCRIPTION

Perl source code can often be quite large, with copious amounts of
comments, inline POD documentation, and inline tests and other padding.

The actual code can represent as little as 10-20% of the content of
well-written modules.

In situations where the Perl files need to be included, but do not need
to be readable, this module will "squish" them. That is, it will strip
out as many characters as it can from the source, while leaving the
function of the code identical to the original.

=head1 METHODS

C<Perl::Squish> is a fully L<PPI::Transform>-compatible class. See that
module's documentation for more information.

=cut

use strict;
use Params::Util '_INSTANCE';
use base 'PPI::Transform';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}





#####################################################################
# Main Methods

sub document {
	my $self     = shift;
	my $Document = _INSTANCE(shift, 'PPI::Document') or return undef;

	# Remove the easy things
	$Document->prune('Statement::End');
	$Document->prune('Token::Comment');
	$Document->prune('Token::Pod');

	# Remove redundant braces from ->method()
	$Document->prune( sub {
		my $Braces = $_[1];
		$Braces->isa('PPI::Structure::List')      or return '';
		$Braces->children == 0                    or return '';
		my $Method = $Braces->sprevious_sibling   or return '';
		$Method->isa('PPI::Token::Word')          or return '';
		$Method->content !~ /:/                   or return '';
		my $Operator = $Method->sprevious_sibling or return '';
		$Operator->isa('PPI::Token::Operator')    or return '';
		$Operator->content eq '->'                or return '';
		return 1;
		} );

	# Lets also do some whitespace cleanup
	$Document->index_locations or return undef;
	my $whitespace = $Document->find('Token::Whitespace');
	foreach ( @$whitespace ) {
		if ( $_->location->[1] == 1 and $_->{content} =~ /\n\z/s ) {
			$_->delete;
		} else {
			$_->{content} = $_->{content} =~ /\n/ ? "\n" : " ";
		}
	}
	$Document->flush_locations;

	$Document;
}

1;

=pod

=head1 TO DO

To keep things simple for the talk, I really don't get into some of the
more in depth stuff that could make things even smaller.

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker, located at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Squish>

For general comments, contact the author.

=head1 AUTHOR

Adam Kennedy, L<http://ali.as/>, cpan@ali.as

=head1 SEE ALSO

L<PPI>

=head1 COPYRIGHT

Copyright (c) 2005 Adam Kennedy. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
