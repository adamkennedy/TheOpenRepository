package Perl::Style::Policy::SubscriptArrow;

=pod

=head1 NAME

Perl::Style::Policy::SubscriptArrow - Should POD have =pod at the start

=head1 DESCRIPTION

The use of a =pod tag to open a section of POD documentation is optional, but
the use of an explicit =pod tag is varied amoungst Perl developers.

Some people prefer explicit open, some people consider it to be a waste of
space.

Some editors (like Ultraedit as one example) have trouble syntax highlighting
Perl code properly when POD doesn't open with an explicit =pod.

The C<PodExplicitOpen> policy indicates whether or not POD should always,
or never have explicit =pod tags (where addition or removal of the POD would
not result in breaking the document).

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
C<pod> which should be true if we should always have explicit =pod tags,
or false if we should never have explicit =pod tags.

=cut

sub new {
	my $class = shift;
	my %param = @_ == 1 ? ( pod => shift ) : @_;
	my $self  = bless \%param, $class;

	# Check params
	unless ( defined $self->{pod} ) {
		die "Did not provide a 'pod' param to " . __PACKAGE__;
	}

	return $self;
}





######################################################################
# Transform Implementation

sub document {
	my $self     = shift;
	my $document = shift;

	if ( $self->{pod} ) {
		# Find all POD blocks that do not start with =pod
		my $bad = $document->find( sub {
			$_[1]->isa('PPI::Token::Pod') or return 0;
			$_[1]->content !~ /^=pod\b/   or return 0;
			return 1;
		} ) or return undef;

		# Prepend the =pod paragraph
		foreach my $token ( @$bad ) {
			substr( $token->{content}, 0, 0, "=pod\n\n" );
		}

		return scalar @$bad;

	} else {
		# Find all POD blocks that start with =pod, followed by
		# another paragraph starting with =foo that also indicates POD.
		my $bad = $document->find( sub {
			$_[1]->isa('PPI::Token::Pod')         or return 0;
			$_[1]->content =~ /^=pod\s*\n{2,}=\w/ or return 0;
			return 1;
		} ) or return undef;

		# Remove the =paragraph
		foreach my $token ( @$bad ) {
			$token->{content} =~ s/^=pod\s*\n{2,}//;
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
