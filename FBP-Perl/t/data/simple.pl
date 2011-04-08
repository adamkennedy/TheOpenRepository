package MyDialog1;

use 5.008;
use strict;
use warnings;
use Wx ':everything';
use t::lib::Custom ();
use t::lib::MyClass ();

our $VERSION = '0.01';
our @ISA     = 'Wx::Dialog';

sub new {
	my $class  = shift;
	my $parent = shift;

	my $self = $class->SUPER::new(
		$parent,
		-1,
		Wx::gettext("Dialog Title"),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxDEFAULT_DIALOG_STYLE | Wx::wxRESIZE_BORDER,
	);

	$self->{m_staticText1} = t::lib::MyClass->new(
		$self,
		-1,
		Wx::gettext("Michael \"Killer\" O'Reilly <michael\@localhost>"),
	);
	$self->{m_staticText1}->SetFont(
		Wx::Font->new( Wx::wxNORMAL_FONT->GetPointSize, 70, 90, 92, 0, "" )
	);
	$self->{m_staticText1}->SetToolTip(
		Wx::gettext("Who is awesome")
	);

	$self->{m_textCtrl1} = Wx::TextCtrl->new(
		$self,
		-1,
		"This is also a test",
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTE_CENTRE,
	);
	$self->{m_textCtrl1}->SetMaxLength(50);
	$self->{m_textCtrl1}->SetBackgroundColour(
		Wx::Colour->new( 255, 128, 0 )
	);

	Wx::Event::EVT_TEXT(
		$self,
		$self->{m_textCtrl1},
		sub {
			shift->refresh(@_);
		},
	);

	$self->{m_button1} = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("MyButton"),
	);
	$self->{m_button1}->SetDefault;
	$self->{m_button1}->SetToolTip(
		Wx::gettext("Click to do nothing")
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{m_button1},
		sub {
			shift->m_button1(@_);
		},
	);

	$self->{m_staticline1} = Wx::StaticLine->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxLI_HORIZONTAL | Wx::wxNO_BORDER,
	);

	$self->{m_splitter1} = Wx::SplitterWindow->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxSP_3D,
	);
	$self->{m_splitter1}->SetSashGravity(0.5);
	$self->{m_splitter1}->SetMinimumPaneSize(50);

	$self->{m_panel3} = Wx::Panel->new(
		$self->{m_splitter1},
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTAB_TRAVERSAL,
	);

	$self->{m_choice1} = Wx::Choice->new(
		$self->{m_panel3},
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		[],
	);
	$self->{m_choice1}->SetSelection(0);

	Wx::Event::EVT_CHOICE(
		$self,
		$self->{m_choice1},
		sub {
			shift->refresh(@_);
		},
	);

	$self->{m_comboBox1} = Wx::ComboBox->new(
		$self->{m_panel3},
		-1,
		"Combo!",
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		[
			"one",
			"two",
			"a'b",
			"c\"d\\\"",
		],
	);

	Wx::Event::EVT_TEXT(
		$self,
		$self->{m_comboBox1},
		sub {
			shift->refresh(@_);
		},
	);

	$self->{m_listBox1} = Wx::ListBox->new(
		$self->{m_panel3},
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		[],
	);

	$self->{m_listCtrl1} = Wx::ListCtrl->new(
		$self->{m_panel3},
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxLC_ICON,
	);

	Wx::Event::EVT_LIST_COL_CLICK(
		$self,
		$self->{m_listCtrl1},
		sub {
			shift->list_col_click(@_);
		},
	);

	Wx::Event::EVT_LIST_ITEM_ACTIVATED(
		$self,
		$self->{m_listCtrl1},
		sub {
			shift->list_item_activated(@_);
		},
	);

	Wx::Event::EVT_LIST_ITEM_SELECTED(
		$self,
		$self->{m_listCtrl1},
		sub {
			shift->list_item_selected(@_);
		},
	);

	$self->{m_customControl1} = My::CustomControl->new(
		$self->{m_panel3},
		-1,
	);

	$self->{m_panel4} = Wx::Panel->new(
		$self->{m_splitter1},
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTAB_TRAVERSAL,
	);

	$self->{m_htmlWin1} = Wx::HtmlWindow->new(
		$self->{m_panel4},
		-1,
		Wx::wxDefaultPosition,
		[ 200, 200 ],
		Wx::wxHW_SCROLLBAR_AUTO,
	);

	$self->{m_checkBox1} = Wx::CheckBox->new(
		$self,
		-1,
		Wx::gettext("Check Me!"),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);

	$self->{m_checkBox2} = Wx::CheckBox->new(
		$self,
		-1,
		Wx::gettext("Check Me!"),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);

	$self->{m_checkBox3} = Wx::CheckBox->new(
		$self,
		-1,
		Wx::gettext("Check Me!"),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);

	$self->{m_checkBox4} = Wx::CheckBox->new(
		$self,
		-1,
		Wx::gettext("Check Me!"),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);

	$self->{m_listbook1} = Wx::Listbook->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxLB_DEFAULT,
	);

	$self->{m_panel1} = Wx::Panel->new(
		$self->{m_listbook1},
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTAB_TRAVERSAL,
	);

	$self->{m_staticText2} = Wx::StaticText->new(
		$self->{m_panel1},
		-1,
		Wx::gettext("This is a test"),
	);
	$self->{m_staticText2}->SetForegroundColour(
		Wx::Colour->new( 0, 0, 255 )
	);

	$self->{m_spinCtrl1} = Wx::SpinCtrl->new(
		$self->{m_panel1},
		-1,
		"",
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxSP_ARROW_KEYS,
		0,
		10,
		5,
	);

	$self->{m_panel2} = Wx::Panel->new(
		$self->{m_listbook1},
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTAB_TRAVERSAL,
	);

	$self->{m_textCtrl2} = Wx::TextCtrl->new(
		$self->{m_panel2},
		-1,
		"This is a test",
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);

	$self->{m_colourPicker1} = Wx::ColourPickerCtrl->new(
		$self->{m_panel2},
		-1,
		Wx::Colour->new( 255, 0, 0 ),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxCLRP_DEFAULT_STYLE,
	);

	$self->{m_colourPicker2} = Wx::ColourPickerCtrl->new(
		$self->{m_panel2},
		-1,
		Wx::SystemSettings::GetColour( Wx::wxSYS_COLOUR_INFOBK ),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxCLRP_DEFAULT_STYLE,
	);

	$self->{m_fontPicker1} = Wx::FontPickerCtrl->new(
		$self->{m_panel2},
		-1,
		Wx::wxNullFont,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxFNTP_DEFAULT_STYLE,
	);
	$self->{m_fontPicker1}->SetMaxPointSize(100);

	$self->{m_filePicker1} = Wx::FilePickerCtrl->new(
		$self->{m_panel2},
		-1,
		"",
		"Select a file",
		"*.*",
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxFLP_DEFAULT_STYLE,
	);

	$self->{m_dirPicker1} = Wx::DirPickerCtrl->new(
		$self->{m_panel2},
		-1,
		"",
		"Select a folder",
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxDIRP_DEFAULT_STYLE,
	);

	$self->{m_panel5} = Wx::Panel->new(
		$self->{m_listbook1},
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTAB_TRAVERSAL,
	);

	$self->{m_listbook2} = Wx::Treebook->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);

	$self->{m_panel6} = Wx::Panel->new(
		$self->{m_listbook2},
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTAB_TRAVERSAL,
	);

	$self->{m_button2} = Wx::Button->new(
		$self->{m_panel6},
		-1,
		Wx::gettext("MyButton"),
	);

	$self->{m_panel7} = Wx::Panel->new(
		$self->{m_listbook2},
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTAB_TRAVERSAL,
	);

	$self->{m_staticText3} = Wx::StaticText->new(
		$self->{m_panel7},
		-1,
		Wx::gettext("MyLabel"),
	);

	my $fgSizer1 = Wx::FlexGridSizer->new( 1, 2, 3, 4 );
	$fgSizer1->AddGrowableCol(0);
	$fgSizer1->AddGrowableCol(1);
	$fgSizer1->SetFlexibleDirection(Wx::wxBOTH);
	$fgSizer1->SetNonFlexibleGrowMode(Wx::wxFLEX_GROWMODE_SPECIFIED);
	$fgSizer1->Add( $self->{m_choice1}, 0, Wx::wxALL, 5 );
	$fgSizer1->Add( $self->{m_comboBox1}, 0, Wx::wxALL | Wx::wxEXPAND, 5 );
	$fgSizer1->Add( $self->{m_listBox1}, 0, Wx::wxALL, 5 );
	$fgSizer1->Add( $self->{m_listCtrl1}, 0, Wx::wxALL | Wx::wxEXPAND, 5 );
	$fgSizer1->Add( $self->{m_customControl1}, 0, Wx::wxALL | Wx::wxEXPAND, 5 );

	$self->{m_panel3}->SetSizer($fgSizer1);
	$self->{m_panel3}->Layout;
	$fgSizer1->Fit($self->{m_panel3});

	my $sbSizer1 = Wx::StaticBoxSizer->new(
		Wx::StaticBox->new(
			$self,
			-1,
			Wx::gettext("The Interweb"),
		),
		Wx::wxVERTICAL,
	);
	$sbSizer1->Add( $self->{m_htmlWin1}, 0, Wx::wxALL | Wx::wxEXPAND, 5 );

	$self->{m_panel4}->SetSizer($sbSizer1);
	$self->{m_panel4}->Layout;
	$sbSizer1->Fit($self->{m_panel4});

	$self->{m_splitter1}->SplitVertically(
		$self->{m_panel3},
		$self->{m_panel4},
	);

	my $gSizer1 = Wx::GridSizer->new( 1, 2, 3, 4 );
	$gSizer1->Add( $self->{m_checkBox1}, 0, Wx::wxALL, 5 );
	$gSizer1->Add( $self->{m_checkBox2}, 0, Wx::wxALL, 5 );
	$gSizer1->Add( $self->{m_checkBox3}, 0, Wx::wxALL, 5 );
	$gSizer1->Add( $self->{m_checkBox4}, 0, Wx::wxALL, 5 );

	my $bSizer3 = Wx::BoxSizer->new(Wx::wxVERTICAL);
	$bSizer3->Add( $self->{m_staticText2}, 0, Wx::wxALL, 5 );
	$bSizer3->Add( $self->{m_spinCtrl1}, 0, Wx::wxALL, 5 );

	$self->{m_panel1}->SetSizer($bSizer3);
	$self->{m_panel1}->Layout;
	$bSizer3->Fit($self->{m_panel1});

	my $bSizer4 = Wx::BoxSizer->new(Wx::wxVERTICAL);
	$bSizer4->Add( $self->{m_textCtrl2}, 0, Wx::wxALL, 5 );
	$bSizer4->Add( $self->{m_colourPicker1}, 0, Wx::wxALL, 5 );
	$bSizer4->Add( $self->{m_colourPicker2}, 0, Wx::wxALL, 5 );
	$bSizer4->Add( $self->{m_fontPicker1}, 0, Wx::wxALL, 5 );
	$bSizer4->Add( $self->{m_filePicker1}, 0, Wx::wxALL, 5 );
	$bSizer4->Add( $self->{m_dirPicker1}, 0, Wx::wxALL, 5 );

	$self->{m_panel2}->SetSizer($bSizer4);
	$self->{m_panel2}->Layout;
	$bSizer4->Fit($self->{m_panel2});

	$self->{m_listbook1}->AddPage( $self->{m_panel1}, Wx::gettext("Page One"), 1 );
	$self->{m_listbook1}->AddPage( $self->{m_panel2}, Wx::gettext("Page Two"), 0 );
	$self->{m_listbook1}->AddPage( $self->{m_panel5}, Wx::gettext("Page Three"), 0 );

	my $bSizer5 = Wx::BoxSizer->new(Wx::wxVERTICAL);
	$bSizer5->Add( $self->{m_button2}, 0, Wx::wxALL, 5 );

	$self->{m_panel6}->SetSizer($bSizer5);
	$self->{m_panel6}->Layout;
	$bSizer5->Fit($self->{m_panel6});

	my $bSizer6 = Wx::BoxSizer->new(Wx::wxVERTICAL);
	$bSizer6->Add( $self->{m_staticText3}, 0, Wx::wxALL, 5 );

	$self->{m_panel7}->SetSizer($bSizer6);
	$self->{m_panel7}->Layout;
	$bSizer6->Fit($self->{m_panel7});

	$self->{m_listbook2}->AddPage( $self->{m_panel6}, Wx::gettext("Page One"), 0 );
	$self->{m_listbook2}->AddPage( $self->{m_panel7}, Wx::gettext("Page Two"), 1 );

	my $bSizer2 = Wx::BoxSizer->new(Wx::wxVERTICAL);
	$bSizer2->Add( $self->{m_staticText1}, 0, Wx::wxALL, 5 );
	$bSizer2->Add( 10, 5, 0, Wx::wxEXPAND, 5 );
	$bSizer2->Add( $self->{m_textCtrl1}, 0, Wx::wxALL, 5 );
	$bSizer2->Add( $self->{m_button1}, 0, Wx::wxALL, 5 );
	$bSizer2->Add( $self->{m_staticline1}, 0, Wx::wxEXPAND | Wx::wxALL, 5 );
	$bSizer2->Add( $self->{m_splitter1}, 1, Wx::wxEXPAND, 5 );
	$bSizer2->Add( $gSizer1, 0, Wx::wxEXPAND, 5 );
	$bSizer2->Add( $self->{m_listbook1}, 1, Wx::wxEXPAND | Wx::wxALL, 5 );
	$bSizer2->Add( $self->{m_listbook2}, 1, Wx::wxEXPAND | Wx::wxALL, 5 );

	my $bSizer1 = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$bSizer1->Add( $bSizer2, 1, Wx::wxEXPAND, 5 );

	$self->SetSizer($bSizer1);
	$self->Layout;
	$bSizer1->Fit($self);
	$bSizer1->SetSizeHints($self);

	return $self;
}

sub m_htmlWin1 {
	$_[0]->{m_htmlWin1};
}

sub refresh {
	die 'Handler method refresh for event m_textCtrl1.OnText not implemented';
}

sub m_button1 {
	die 'Handler method m_button1 for event m_button1.OnButtonClick not implemented';
}

sub list_col_click {
	die 'Handler method list_col_click for event m_listCtrl1.OnListColClick not implemented';
}

sub list_item_activated {
	die 'Handler method list_item_activated for event m_listCtrl1.OnListItemActivated not implemented';
}

sub list_item_selected {
	die 'Handler method list_item_selected for event m_listCtrl1.OnListItemSelected not implemented';
}

1;
