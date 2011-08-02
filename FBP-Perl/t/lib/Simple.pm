package t::lib::Simple;

## no critic

use 5.008;
use strict;
use warnings;
use Wx ':everything';
use Wx::Html ();
use Wx::Locale ();

our $VERSION = '0.59';
our @ISA     = 'Wx::App';

sub run {
	shift->new(@_)->MainLoop;
}

sub OnInit {
	my $self = shift;

	# Create the primary frame
	require t::lib::MyFrame1;
	$self->SetTopWindow( t::lib::MyFrame1->new );

	# Don't flash frames on the screen in tests
	unless ( $ENV{HARNESS_ACTIVE} ) {
		$self->GetTopWindow->Show(1);
	}

	return 1;
}

1;
