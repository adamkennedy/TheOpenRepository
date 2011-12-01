package FBP::Demo::FBP::Popup;

## no critic

use 5.008005;
use utf8;
use strict;
use warnings;
use Wx 0.98 ':everything';

our $VERSION = '0.03';
our @ISA     = 'Wx::Dialog';

sub new {
	my $class  = shift;
	my $parent = shift;

	my $self = $class->SUPER::new(
		$parent,
		-1,
		'',
		wxDefaultPosition,
		wxDefaultSize,
		wxDEFAULT_DIALOG_STYLE,
	);

	$self->{m_staticText2} = Wx::StaticText->new(
		$self,
		-1,
		"This is a modal popup dialog",
	);

	$self->{m_staticline2} = Wx::StaticLine->new(
		$self,
		-1,
		wxDefaultPosition,
		wxDefaultSize,
		wxLI_HORIZONTAL,
	);

	$self->{cancel} = Wx::Button->new(
		$self,
		wxID_CANCEL,
		"Close",
		wxDefaultPosition,
		wxDefaultSize,
	);
	$self->{cancel}->SetDefault;

	my $bSizer4 = Wx::BoxSizer->new(wxHORIZONTAL);
	$bSizer4->Add( 0, 0, 1, wxEXPAND, 5 );
	$bSizer4->Add( $self->{cancel}, 0, wxALL, 5 );

	my $bSizer3 = Wx::BoxSizer->new(wxVERTICAL);
	$bSizer3->Add( $self->{m_staticText2}, 0, wxALL, 50 );
	$bSizer3->Add( $self->{m_staticline2}, 0, wxEXPAND | wxALL, 5 );
	$bSizer3->Add( $bSizer4, 1, wxEXPAND, 5 );

	my $bSizer2 = Wx::BoxSizer->new(wxHORIZONTAL);
	$bSizer2->Add( $bSizer3, 1, wxEXPAND, 5 );

	$self->SetSizerAndFit($bSizer2);
	$self->Layout;

	return $self;
}

1;
