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
		Wx::gettext("MyLabel"),
	);

	$self->{m_button5} = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("MyButton"),
	);

	my $bSizer8 = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$bSizer8->Add( $self->{m_staticText6}, 0, Wx::wxALIGN_CENTER_VERTICAL | Wx::wxALL, 5 );
	$bSizer8->Add( $self->{m_button5}, 0, Wx::wxALL, 5 );

	$self->SetSizer($bSizer8);
	$self->Layout;
	$bSizer8->Fit($self);

	return $self;
}

1;
