package FBP::Demo::Main;

## no critic

use 5.008;
use strict;
use warnings;
use Wx ':everything';

our $VERSION = '0.01';
our @ISA     = 'Wx::Frame';

sub new {
	my $class  = shift;
	my $parent = shift;

	my $self = $class->SUPER::new(
		$parent,
		-1,
		"Main Window",
		wxDefaultPosition,
		[ 500, 300 ],
		wxDEFAULT_FRAME_STYLE | wxTAB_TRAVERSAL,
	);

	$self->{m_staticText1} = Wx::StaticText->new(
		$self,
		-1,
		"This is the FBP::Perl demonstration project.\n\nIt shows a complete working standalone application skeleton as produced by FBP::Perl.",
	);

	$self->{m_staticline1} = Wx::StaticLine->new(
		$self,
		-1,
		wxDefaultPosition,
		wxDefaultSize,
		wxLI_HORIZONTAL,
	);

	$self->{simple_button} = Wx::Button->new(
		$self,
		-1,
		"Simple buttin with click event",
		wxDefaultPosition,
		wxDefaultSize,
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{simple_button},
		sub {
			shift->simple_button_click(@_);
		},
	);

	my $bSizer1 = Wx::BoxSizer->new(wxVERTICAL);
	$bSizer1->Add( $self->{m_staticText1}, 0, wxALL, 5 );
	$bSizer1->Add( $self->{m_staticline1}, 0, wxEXPAND | wxALL, 5 );
	$bSizer1->Add( $self->{simple_button}, 0, wxALL, 5 );

	$self->SetSizer($bSizer1);
	$self->Layout;

	return $self;
}

sub simple_button_click {
	warn 'Handler method simple_button_click for event simple_button.OnButtonClick not implemented';
}

1;