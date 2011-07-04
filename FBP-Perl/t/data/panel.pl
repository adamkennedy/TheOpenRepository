package MyPanel1;

use 5.008;
use strict;
use warnings;
use Wx ':everything';

our $VERSION = '0.01';
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
		Wx::gettext("Long 2 column spanning text"),
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
		Wx::gettext("Right Button"),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);

	my $gbSizer2 = Wx::GridBagSizer->new( 0, 0 );
	$gbSizer2->SetFlexibleDirection(Wx::wxBOTH);
	$gbSizer2->SetNonFlexibleGrowMode(Wx::wxFLEX_GROWMODE_SPECIFIED);
	$gbSizer2->Add( $self->{m_staticText6}, Wx::wxALIGN_CENTER_HORIZONTAL | Wx::wxALL, 5 );
	$gbSizer2->Add( $self->{m_button5}, Wx::wxALL, 5 );
	$gbSizer2->Add( $self->{m_button51}, Wx::wxALL, 5 );

	my $bSizer8 = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$bSizer8->Add( $gbSizer2, 1, Wx::wxEXPAND, 5 );

	$self->SetSizer($bSizer8);
	$self->Layout;
	$bSizer8->Fit($self);

	return $self;
}

1;
