package MyDialog1;

use 5.008;
use strict;
use warnings;
use Wx ':everything';

our $VERSION = '0.01';
our @ISA     = 'Wx::Dialog';

sub new {
	my $class  = shift;
	my $parent = shift;

	my $self = $class->SUPER::new(
		$parent,
		-1,
		'',
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxDEFAULT_DIALOG_STYLE,
	);

	my $m_staticText1 = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext('This is a test'),
	);

	$self->{m_button1} = Wx::Button->new(
		$self,
		-1,
		Wx::gettext('MyButton'),
	);
	$self->{m_button1}->SetDefault;

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{m_button1},
		sub {
			shift->m_button1(@_);
		},
	);

	my $m_staticline1 = Wx::StaticLine->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);

	$self->{m_choice1} = Wx::Choice->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		[ ],
	);

	$self->{m_comboBox1} = Wx::ComboBox->new(
		$self,
		-1,
		"Combo\!",
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		[ ],
		0,
	);

	$self->{m_listBox1} = Wx::ListBox->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		[ ],
		0,
	);

	$self->{m_listCtrl1} = Wx::ListCtrl->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxLC_ICON,
	);

	my $bSizer2 = Wx::BoxSizer->new( Wx::wxVERTICAL );
	$bSizer2->Add( $m_staticText1, 0, Wx::wxALL, 5 );
	$bSizer2->Add( 10, 5, 1, Wx::wxEXPAND, 5 );
	$bSizer2->Add( $self->{m_button1}, 0, Wx::wxALL, 5 );
	$bSizer2->Add( $m_staticline1, 0, Wx::wxEXPAND | Wx::wxALL, 5 );
	$bSizer2->Add( $self->{m_choice1}, 0, Wx::wxALL, 5 );
	$bSizer2->Add( $self->{m_comboBox1}, 0, Wx::wxALL, 5 );
	$bSizer2->Add( $self->{m_listBox1}, 0, Wx::wxALL, 5 );
	$bSizer2->Add( $self->{m_listCtrl1}, 0, Wx::wxALL | Wx::wxEXPAND, 5 );

	my $bSizer1 = Wx::BoxSizer->new( Wx::wxHORIZONTAL );
	$bSizer1->Add( $bSizer2, 1, Wx::wxEXPAND, 5 );

	$self->SetSizer($bSizer1);
	$self->Layout;
	$bSizer1->Fit($self);

	return $self;
}

sub m_button1 {
	my $self  = shift;
	my $event = shift;

	die 'TO BE COMPLETED';
}

1;
