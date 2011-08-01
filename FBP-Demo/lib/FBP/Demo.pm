package FBP::Demo;

use 5.008;
use strict;
use warnings;
use Wx ':everything';

our $VERSION = '0.01';
our @ISA     = 'Wx::App';

sub OnInit {
	my $self = shift;

	# Set the application name
	$self->SetAppName('FBP Demonstration Application');

	# Create the main window
	require FBP::Demo::Frame::Main;
	$self->SetTopWindow(
		FBP::Demo::Frame::Main->new
	);
	$self->GetTopWindow->Show(1);

	return 1;
}

1;
