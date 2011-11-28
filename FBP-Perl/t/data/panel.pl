package MyPanel1;

use 5.008005;
use utf8;
use strict;
use warnings;
use Wx 0.98 ':everything';

our $VERSION = '0.67';
our @ISA     = 'Wx::Panel';

sub new {
	my $class  = shift;
	my $parent = shift;

	my $self = $class->SUPER::new(
		$parent,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTAB_TRAVERSAL,
	);

	$self->{m_staticText6} = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext(": Long 2 column spanning text :"),
	);

	$self->{m_button5} = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("Left Button"),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);

	$self->{m_button51} = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("Right Button..."),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);

	$self->{m_staticText61} = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("Don't press this:"),
	);

	my $bSizer11 = Wx::BoxSizer->new(Wx::wxVERTICAL);
	$bSizer11->Add( $self->{m_button51}, 0, Wx::wxALL, 5 );
	$bSizer11->Add( $self->{m_staticText61}, 0, Wx::wxALL, 5 );

	my $gbSizer2 = Wx::GridBagSizer->new( 0, 0 );
	$gbSizer2->SetFlexibleDirection(Wx::wxBOTH);
	$gbSizer2->SetNonFlexibleGrowMode(Wx::wxFLEX_GROWMODE_SPECIFIED);
	$gbSizer2->AddWindow(
		$self->{m_staticText6},
		Wx::GBPosition->new( 0, 0 ),
		Wx::GBSpan->new( 1, 3 ),
		Wx::wxALIGN_CENTER_HORIZONTAL | Wx::wxALL,
		5,
	);
	$gbSizer2->AddWindow(
		$self->{m_button5},
		Wx::GBPosition->new( 1, 0 ),
		Wx::GBSpan->new( 1, 1 ),
		Wx::wxALL,
		5,
	);
	$gbSizer2->AddSpacer(
		20,
		10,
		Wx::GBPosition->new( 1, 1 ),
		Wx::GBSpan->new( 1, 1 ),
		Wx::wxEXPAND,
		5,
	);
	$gbSizer2->AddSizer(
		$bSizer11,
		Wx::GBPosition->new( 1, 2 ),
		Wx::GBSpan->new( 1, 1 ),
		Wx::wxEXPAND,
		5,
	);

	my $bSizer8 = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$bSizer8->Add( $gbSizer2, 1, Wx::wxEXPAND, 5 );

	$self->SetSizerAndFit($bSizer8);
	$self->Layout;

	return $self;
}

1;
