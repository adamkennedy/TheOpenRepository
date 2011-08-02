package t::lib::Simple;

## no critic

use 5.008;
use strict;
use warnings;
use Wx ':everything';
use Wx::Html ();
use Wx::Locale ();

our $VERSION = '0.01';
our @ISA     = 'Wx::App';

sub run {
	shift->new(@_)->MainLoop;
}

sub OnInit {
	my $self = shift;

	require t::lib::MyFrame1;
	$self->SetTopWindow(
		t::lib::MyFrame1->new
	)->Show(1);

	return 1;
}

1;
