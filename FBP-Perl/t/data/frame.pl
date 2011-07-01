package MyFrame1;

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
		Wx::gettext("Frame Title"),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxDEFAULT_FRAME_STYLE | Wx::wxTAB_TRAVERSAL,
	);
	$self->CreateStatusBar( 2, Wx::wxST_SIZEGRIP, -1 );

	$self->{m_menu1} = Wx::Menu->new;

	my $m_menuItem1 = Wx::MenuItem->new(
		$self->{m_menu1},
		-1,
		Wx::gettext("MyMenuItem"),
		'',
		Wx::wxITEM_NORMAL,
	);

	Wx::Event::EVT_MENU(
		$self,
		$m_menuItem1,
		sub {
			shift->menu_event(@_);
		},
	);

	my $m_menuItem2 = Wx::MenuItem->new(
		$self->{m_menu1},
		-1,
		Wx::gettext("MyMenuItem"),
		'',
		Wx::wxITEM_NORMAL,
	);

	$self->{m_menu1}->Append( $m_menuItem1 );
	$self->{m_menu1}->AppendSeparator;
	$self->{m_menu1}->Append( $m_menuItem2 );

	$self->{m_menubar1} = Wx::MenuBar->new(0);

	$self->{m_menubar1}->Append(
		$self->{m_menu1},
		Wx::gettext("File"),
	);

	$self->SetMenuBar( $self->{m_menubar1} );

	$self->{m_toolBar1} = $self->CreateToolBar( Wx::wxTB_HORIZONTAL, -1 );
	$self->{m_toolBar1}->AddTool(
		-1,
		Wx::gettext("Tool 1"),
		Wx::Bitmap->new( "padre-plugin.png", Wx::wxBITMAP_TYPE_ANY ),
		'',
		Wx::wxITEM_NORMAL,
	);
	$self->{m_toolBar1}->AddSeparator;
	$self->{m_toolBar1}->AddTool(
		-1,
		Wx::gettext("Tool 2"),
		Wx::wxNullBitmap,
		'',
		Wx::wxITEM_NORMAL,
	);
	$self->{m_toolBar1}->Realize;

	$self->{m_staticText5} = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("MyLabel"),
	);

	$self->{m_button4} = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("MyButton"),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);

	my $bSizer7 = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$bSizer7->Add( $self->{m_staticText5}, 0, Wx::wxALIGN_CENTER_VERTICAL | Wx::wxALL, 5 );
	$bSizer7->Add( $self->{m_button4}, 0, Wx::wxALL, 5 );

	$self->SetSizer($bSizer7);
	$self->Layout;
	$bSizer7->Fit($self);

	return $self;
}

sub menu_event {
	die 'Handler method menu_event for event m_menuItem1.OnMenuSelection not implemented';
}

1;
