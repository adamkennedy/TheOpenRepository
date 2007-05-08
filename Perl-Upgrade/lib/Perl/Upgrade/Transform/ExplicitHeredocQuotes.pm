package Perl::PortForward::Transform::ExplicitHeredocQuotes.pm

use strict;
use base 'PPI::Transform';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Main Methods

sub document {
	my ($self, $doc) = @_;

	# Find any heredocs without quotes
	my @heredocs = $doc->find( sub {
		$_[1]->isa('PPI::Token::Heredoc')
		and
		$_[1]->content !~ /['"]/
		} );

	foreach my $heredoc ( @heredocs ) {
		$heredoc->{content} =~ /(\w+)/\"$1\"/;
	}

	$self;
}

1;
