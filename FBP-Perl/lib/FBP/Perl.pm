package FBP::Perl;

=pod

=head1 NAME

FBP::Perl - Generate Perl GUI code from wxFormBuilder .fbp files

=head1 SYNOPSIS

  my $generator = FBP::Perl->new(
      dialog => $fbp_object->dialog('MyDialog')
  );

=head1 DESCRIPTION

TO BE COMPLETED

=cut

use 5.008005;
use strict;
use warnings;
use Mouse         0.61;
use FBP           0.18 ();
use Data::Dumper 2.122 ();

our $VERSION = '0.17';

has project => (
	is       => 'ro',
	isa      => 'FBP::Project',
	required => 1,
);





######################################################################
# High Level Methods

sub dialog_write {
	my $self   = shift;
	my $dialog = shift;
	my $path   = shift;

	# Generate the code
	my $code = $self->flatten(
		$self->dialog_class($dialog)
	);

	# Write it to the file
	open( my $file, '>', $path ) or die "open($path): $!";
	$file->print( $code );
	$file->close;

	return 1;
}





######################################################################
# Dialog Generators

sub dialog_class {
	my $self    = shift;
	my $dialog  = shift;
	my $package = $dialog->name;
	my $pragma  = $self->use_pragma($dialog);
	my $wx      = $self->use_wx($dialog);
	my $more    = $self->use_more($dialog);
	my $version = $self->dialog_version($dialog);
	my $isa     = $self->dialog_isa($dialog);
	my $new     = $self->dialog_new($dialog);
	my $methods = $self->dialog_methods($dialog);

	return [
		"package $package;",
		"",
		@$pragma,
		@$wx,
		@$more,
		"",
		@$version,
		@$isa,
		"",
		@$new,
		@$methods,
		"",
		"1;",
	];
}

sub dialog_new {
	my $self    = shift;
	my $dialog  = shift;
	my $super   = $self->dialog_super($dialog);
	my @windows = $self->dialog_windows($dialog);
	my @sizers  = $self->dialog_sizers($dialog);

	return $self->nested(
		"sub new {",
		"my \$class  = shift;",
		"my \$parent = shift;",
		"",
		$super,
		"",
		@windows,
		( map { @$_, "" } @sizers ),
		"return \$self;",
		"}",
	);
}

sub dialog_super {
	my $self     = shift;
	my $dialog   = shift;
	my $id       = $self->wx( $dialog->id );
	my $title    = $self->text( $dialog->title );
	my $position = $self->object_position($dialog);
	my $size     = $self->object_size($dialog);
	my $style    = $self->wx(
		$dialog->styles || 'wxDEFAULT_DIALOG_STYLE'
	);

	return $self->nested(
		"my \$self = \$class->SUPER::new(",
		"\$parent,",
		"$id,",
		"$title,",
		"$position,",
		"$size,",
		( $style ? "$style," : () ),
		");",
	);
}

sub dialog_windows {
	my $self   = shift;
	my $dialog = shift;

	return map {
		$self->window_create($_), ""
	} $dialog->find( isa => 'FBP::Window' );
}

sub dialog_sizers {
	my $self     = shift;
	my $dialog   = shift;
	my $sizer    = $dialog->children->[0];
	my $variable = $self->object_variable($sizer);

	# Check the sizer within the dialog
	unless ( $sizer->isa('FBP::Sizer') ) {
		die 'Dialog root sizer is not a BoxSizer';
	}

	# Generate fragments
	my @children = $self->sizer_pack($sizer);

	return (
		@children,
		[
			"\$self->SetSizer($variable);",
			"\$self->Layout;",
			"$variable->Fit(\$self);",
			(
				$dialog->style =~ /\bwxRESIZE_BORDER\b/
				? "$variable->SetSizeHints(\$self);"
				: ()
			),
		]
	);
}

sub dialog_version {
	my $self   = shift;
	my $dialog = shift;

	return [
		"our \$VERSION = '0.01';",
	];
}

sub dialog_isa {
	my $self   = shift;
	my $dialog = shift;

	return [
		"our \@ISA     = 'Wx::Dialog';",
	];
}





######################################################################
# Window and Control Generators

sub window_create {
	my $self   = shift;
	my $window = shift;
	my $lines  = undef;
	if ( $window->isa('FBP::Button') ) {
		$lines = $self->button_create($window);
	} elsif ( $window->isa('FBP::CheckBox') ) {
		$lines = $self->checkbox_create($window);
	} elsif ( $window->isa('FBP::Choice') ) {
		$lines = $self->choice_create($window);
	} elsif ( $window->isa('FBP::ComboBox') ) {
		$lines = $self->combobox_create($window);
	} elsif ( $window->isa('FBP::HtmlWindow') ) {
		$lines = $self->htmlwindow_create($window);
	} elsif ( $window->isa('FBP::Listbook') ) {
		$lines = $self->listbook_create($window);
	} elsif ( $window->isa('FBP::ListBox') ) {
		$lines = $self->listbox_create($window);
	} elsif ( $window->isa('FBP::ListCtrl') ) {
		$lines = $self->listctrl_create($window);
	} elsif ( $window->isa('FBP::Panel') ) {
		$lines = $self->panel_create($window);
	} elsif ( $window->isa('FBP::SplitterWindow') ) {
		$lines = $self->splitterwindow_create($window);
	} elsif ( $window->isa('FBP::StaticLine') ) {
		$lines = $self->staticline_create($window);
	} elsif ( $window->isa('FBP::StaticText') ) {
		$lines = $self->statictext_create($window);
	} elsif ( $window->isa('FBP::TextCtrl') ) {
		$lines = $self->textctrl_create($window);
	} else {
		die 'Cannot create constructor code for ' . ref($window);
	}

	# Add the bindings the window
	my $bindings = $self->window_bindings($window);
	push @$lines, @$bindings;

	return $lines;
}

sub button_create {
	my $self     = shift;
	my $control  = shift;
	my $id       = $self->wx( $control->id );
	my $label    = $self->object_label($control);
	my $variable = $self->object_variable($control);

	my $lines = $self->nested(
		$self->window_new($control),
		"\$self,",
		"$id,",
		"$label,",
		");",
	);

	if ( $control->default ) {
		push @$lines, "$variable->SetDefault;";
	}
	unless ( $control->enabled ) {
		push @$lines, "$variable->Disable;";
	}

	return $lines;
}

sub checkbox_create {
	my $self     = shift;
	my $control  = shift;
	my $id       = $self->wx( $control->id );
	my $label    = $self->object_label($control);
	my $position = $self->object_position($control);
	my $size     = $self->object_size($control);
	my $style    = $self->wx( $control->styles );

	return $self->nested(
		$self->window_new($control),
		"\$self,",
		"$id,",
		"$label,",
		"$position,",
		"$size,",
		( $style ? "$style," : () ),
		");",
	);
}

sub choice_create {
	my $self     = shift;
	my $control  = shift;
	my $id       = $self->wx( $control->id );
	my $position = $self->object_position($control);
	my $size     = $self->object_size($control);
	my $items    = $self->control_items($control);

	return $self->nested(
		$self->window_new($control),
		"\$self,",
		"$id,",
		"$position,",
		"$size,",
		$items,
		");",
	);
}

sub combobox_create {
	my $self     = shift;
	my $control  = shift;
	my $id       = $self->wx( $control->id );
	my $value    = $self->quote( $control->value );
	my $position = $self->object_position($control);
	my $size     = $self->object_size($control);
	my $items    = $self->control_items($control);
	my $style    = $self->wx( $control->styles );

	return $self->nested(
		$self->window_new($control),
		"\$self,",
		"$id,",
		"$value,",
		"$position,",
		"$size,",
		$items,
		( $style ? "$style," : () ),
		");",
	);
}

sub htmlwindow_create {
	my $self     = shift;
	my $control  = shift;
	my $id       = $self->wx( $control->id );
	my $position = $self->object_position($control);
	my $size     = $self->object_size($control);
	my $style    = $self->wx( $control->styles );

	return $self->nested(
		$self->window_new($control),
		"\$self,",
		"$id,",
		"$position,",
		"$size,",
		( $style ? "$style," : () ),
		");",
	);
}

sub listbook_create {
	my $self     = shift;
	my $control  = shift;
	my $id       = $self->wx( $control->id );
	my $position = $self->object_position($control);
	my $size     = $self->object_size($control);
	my $style    = $self->wx( $control->styles );

	return $self->nested(
		$self->window_new($control),
		"\$self,",
		"$id,",
		"$position,",
		"$size,",
		( $style ? "$style," : () ),
		");",
	);
}

sub listbox_create {
	my $self     = shift;
	my $control  = shift;
	my $id       = $self->wx( $control->id );
	my $position = $self->object_position($control);
	my $size     = $self->object_size($control);
	my $items    = $self->control_items($control);
	my $style    = $self->wx( $control->styles );

	return $self->nested(
		$self->window_new($control),
		"\$self,",
		"$id,",
		"$position,",
		"$size,",
		$items,
		( $style ? "$style," : () ),
		");",
	);
}

sub listctrl_create {
	my $self     = shift;
	my $control  = shift;
	my $id       = $self->wx( $control->id );
	my $position = $self->object_position($control);
	my $size     = $self->object_size($control);
	my $style    = $self->wx( $control->styles );

	return $self->nested(
		$self->window_new($control),
		"\$self,",
		"$id,",
		"$position,",
		"$size,",
		( $style ? "$style," : () ),
		");",
	);
}

sub panel_create {
	my $self     = shift;
	my $window   = shift;
	my $id       = $self->wx( $window->id );
	my $position = $self->object_position($window);
	my $size     = $self->object_size($window);
	my $style    = $self->wx( $window->styles );

	return $self->nested(
		$self->window_new($window),
		"\$self,",
		"$id,",
		"$position,",
		"$size,",
		( $style ? "$style," : () ),
		");",
	);
}

sub splitterwindow_create {
	my $self    = shift;
	my $window  = shift;
	my $id       = $self->wx( $window->id );
	my $position = $self->object_position($window);
	my $size     = $self->object_size($window);
	my $style    = $self->wx( $window->styles );

	return $self->nested(
		$self->window_new($window),
		"\$self,",
		"$id,",
		"$position,",
		"$size,",
		( $style ? "$style," : () ),
		");",
	);
}

sub statictext_create {
	my $self    = shift;
	my $control = shift;
	my $id      = $self->wx( $control->id );
	my $label   = $self->object_label($control);

	return $self->nested(
		$self->window_new($control),
		"\$self,",
		"$id,",
		"$label,",
		");",
	);
}

sub staticline_create {
	my $self     = shift;
	my $control  = shift;
	my $id       = $self->wx( $control->id );
	my $position = $self->object_position($control);
	my $size     = $self->object_size($control);
	my $style    = $self->wx( $control->styles );

	return $self->nested(
		$self->window_new($control),
		"\$self,",
		"$id,",
		"$position,",
		"$size,",
		( $style ? "$style," : () ),
		");",
	);
}

sub textctrl_create {
	my $self      = shift;
	my $control   = shift;
	my $id        = $self->wx( $control->id );
	my $value     = $self->quote( $control->value );
	my $position  = $self->object_position($control);
	my $size      = $self->object_size($control);
	my $style     = $self->wx( $control->styles );
	my $maxlength = $control->maxlength;

	my $lines = $self->nested(
		$self->window_new($control),
		"\$self,",
		"$id,",
		"$value,",
		"$position,",
		"$size,",
		( $style ? "$style," : () ),
		");",
	);
	if ( $maxlength ) {
		my $variable = $self->object_variable($control);
		push @$lines, "$variable->SetMaxLength( $maxlength );";
	}

	return $lines;
}





######################################################################
# Sizer Generators

sub children_pack {
	my $self     = shift;
	my $object   = shift;
	my @children = ();

	foreach my $item ( @{$object->children} ) {
		my $child = $item->children->[0];
		if ( $child->isa('FBP::Sizer') ) {
			push @children, $self->sizer_pack($child);
		} elsif ( $child->isa('FBP::Listbook') ) {
			push @children, $self->listbook_pack($child);
		} elsif ( $child->isa('FBP::Panel') ) {
			push @children, $self->panel_pack($child);
		} elsif ( $child->isa('FBP::SplitterWindow') ) {
			push @children, $self->splitterwindow_pack($child);
		} elsif ( $child->does('FBP::Children') ) {
			if ( @{$child->children} ) {
				die "Unsupported parent " . ref($child);
			}
		}
	}

	return @children;
}

sub sizer_pack {
	my $self  = shift;
	my $sizer = shift;

	if ( $sizer->isa('FBP::FlexGridSizer') ) { 
		return $self->flexgridsizer_pack($sizer);
	} elsif ( $sizer->isa('FBP::GridSizer') ) {
		return $self->gridsizer_pack($sizer);
	} elsif ( $sizer->isa('FBP::StaticBoxSizer') ) {
		return $self->staticboxsizer_pack($sizer);
	} elsif ( $sizer->isa('FBP::BoxSizer') ) {
		return $self->boxsizer_pack($sizer);
	} else {
		die "Unsupported sizer " . ref($sizer);
	}
}

sub boxsizer_pack {
	my $self     = shift;
	my $sizer    = shift;
	my $lexical  = $self->object_lexical($sizer) ? 'my ' : '';
	my $variable = $self->object_variable($sizer);
	my $orient   = $self->wx( $sizer->orient );

	# Add the content for all our child sizers
	my @children = $self->children_pack($sizer);

	# Add the content for this sizer
	my @lines = (
		"$lexical$variable = Wx::BoxSizer->new( $orient );",
	);
	foreach my $item ( @{$sizer->children} ) {
		my $child  = $item->children->[0];
		if ( $child->isa('FBP::Spacer') ) {
			my $params = join(
				', ',
				$child->width,
				$child->height,
				$item->proportion,
				$self->wx( $item->flag ),
				$item->border,
			);
			push @lines, "$variable->Add( $params );";
		} else {
			my $params = join(
				', ',
				$self->object_variable($child),
				$item->proportion,
				$self->wx( $item->flag ),
				$item->border,
			);
			push @lines, "$variable->Add( $params );";
		}
	}

	return ( @children, \@lines );
}

sub staticboxsizer_pack {
	my $self     = shift;
	my $sizer    = shift;
	my $lexical  = $self->object_lexical($sizer) ? 'my ' : '';
	my $variable = $self->object_variable($sizer);
	my $label    = $self->object_label($sizer);
	my $orient   = $self->wx( $sizer->orient );

	# Add the content for all our child sizers
	my @children = $self->children_pack($sizer);

	# Add the content for this sizer
	my @lines = (
		"$lexical$variable = Wx::StaticBoxSizer->new(",
		"\tWx::StaticBox->new(",
		"\t\t\$self,",
		"\t\t-1,",
		"\t\t$label,",
		"\t),",
		"\t$orient,",
		");",
	);
	foreach my $item ( @{$sizer->children} ) {
		my $child  = $item->children->[0];
		if ( $child->isa('FBP::Spacer') ) {
			my $params = join(
				', ',
				$child->width,
				$child->height,
				$item->proportion,
				$self->wx( $item->flag ),
				$item->border,
			);
			push @lines, "$variable->Add( $params );";
		} else {
			my $params = join(
				', ',
				$self->object_variable($child),
				$item->proportion,
				$self->wx( $item->flag ),
				$item->border,
			);
			push @lines, "$variable->Add( $params );";
		}
	}

	return ( @children, \@lines );
}

sub gridsizer_pack {
	my $self     = shift;
	my $sizer    = shift;
	my $lexical  = $self->object_lexical($sizer) ? 'my ' : '';
	my $variable = $self->object_variable($sizer);
	my $params   = join( ', ',
		$sizer->rows,
		$sizer->cols,
		$sizer->vgap,
		$sizer->hgap,
	);

	# Add the content for all our child sizers
	my @children = $self->children_pack($sizer);

	# Add the content for this sizer
	my @lines = (
		"$lexical$variable = Wx::GridSizer->new( $params );",
	);
	foreach my $item ( @{$sizer->children} ) {
		my $child  = $item->children->[0];
		if ( $child->isa('FBP::Spacer') ) {
			my $params = join(
				', ',
				$child->width,
				$child->height,
				$item->proportion,
				$self->wx( $item->flag ),
				$item->border,
			);
			push @lines, "$variable->Add( $params );";
		} else {
			my $params = join(
				', ',
				$self->object_variable($child),
				$item->proportion,
				$self->wx( $item->flag ),
				$item->border,
			);
			push @lines, "$variable->Add( $params );";
		}
	}

	return ( @children, \@lines );
}

sub flexgridsizer_pack {
	my $self      = shift;
	my $sizer     = shift;
	my $lexical   = $self->object_lexical($sizer) ? 'my ' : '';
	my $variable  = $self->object_variable($sizer);
	my $direction = $self->wx( $sizer->flexible_direction );
	my $growmode  = $self->wx( $sizer->non_flexible_grow_mode );
	my $params    = join( ', ',
		$sizer->rows,
		$sizer->cols,
		$sizer->vgap,
		$sizer->hgap,
	);

	# Add the content for all our child sizers
	my @children = $self->children_pack($sizer);

	# Add the content for this sizer
	my @lines = (
		"$lexical$variable = Wx::FlexGridSizer->new( $params );",
	);
	foreach my $row ( split /,/, $sizer->growablerows ) {
		push @lines, "$variable->AddGrowableRow( $row );";
	}
	foreach my $col ( split /,/, $sizer->growablecols ) {
		push @lines, "$variable->AddGrowableCol( $col );";
	}
	push @lines, "$variable->SetFlexibleDirection( $direction );";
	push @lines, "$variable->SetNonFlexibleGrowMode( $growmode );";
	foreach my $item ( @{$sizer->children} ) {
		my $child  = $item->children->[0];
		if ( $child->isa('FBP::Spacer') ) {
			my $params = join(
				', ',
				$child->width,
				$child->height,
				$item->proportion,
				$self->wx( $item->flag ),
				$item->border,
			);
			push @lines, "$variable->Add( $params );";
		} else {
			my $params = join(
				', ',
				$self->object_variable($child),
				$item->proportion,
				$self->wx( $item->flag ),
				$item->border,
			);
			push @lines, "$variable->Add( $params );";
		}
	}

	return ( @children, \@lines );
}

sub listbook_pack {
	my $self     = shift;
	my $book     = shift;
	my $variable = $self->object_variable($book);

	# Add each of our child pages
	my @lines = ();
	foreach my $item ( @{$book->children} ) {
		my $child = $item->children->[0];
		if ( $child->isa('FBP::Panel') ) {
			my $params = join(
				', ',
				$self->object_variable($child),
				$self->object_label($item),
				$item->select ? 1 : 0,
			);
			push @lines, "$variable->AddPage( $params );";

		} else {
			die "Unknown or unsupported book child " . ref($child);
		}
	}

	return \@lines;
}

sub panel_pack {
	my $self     = shift;
	my $panel    = shift;
	my $sizer    = $panel->children->[0];
	my $variable = $self->object_variable($panel);
	my $sizervar = $self->object_variable($sizer);

	# Generate fragments for our child sizer
	my @children = $self->sizer_pack($sizer);

	# Attach the sizer to the panel
	return (
		@children,
		[
			"$variable->SetSizer($sizervar);",
			"$variable->Layout;",
			"$sizervar->Fit($variable);",
		]
	);
}

sub splitterwindow_pack {
	my $self     = shift;
	my $window   = shift;
	my $variable = $self->object_variable($window);
	my @windows  = map { $_->children->[0] } @{$window->children};

	# Add the content for all our child sizers
	my @children = $self->children_pack($window);

	if ( @windows == 1 ) {
		# One child window
		my $window1 = $self->object_variable($windows[0]);
		return (
			@children,
			[
				"$variable->Initialize(",
				"\t$window1,",
				");",
			],
		);
	}

	if ( @windows == 2 ) {
		# Two child windows
		my $sashpos = $window->sashpos;
		my $window1 = $self->object_variable($windows[0]);
		my $window2 = $self->object_variable($windows[1]);
		my $method  = $window->splitmode eq 'wxVERTICAL'
		            ? 'SplitHorizontally'
		            : 'SplitVertically';
		return (
			@children,
			[
				"$variable->$method(",
				"\t$window1,",
				"\t$window2,",
				$sashpos ? ( "\t$sashpos," ) : (),
				");",
			],
		);
	}

	die "Unexpected number of splitterwindow children";
}





######################################################################
# Window Fragment Generators

my %EVENT = (
	# wxActivateEvent
	OnActivate             => [ 'EVT_ACTIVATE'               ],
	OnActivateApp          => [ 'EVT_ACTIVATE_APP'           ],

	# wxCommandEvent
	OnButtonClick          => [ 'EVT_BUTTON'                 ],
	OnCheckBox             => [ 'EVT_CHECKBOX'               ],
	OnChoice               => [ 'EVT_CHOICE'                 ],
	OnCombobox             => [ 'EVT_COMBOBOX'               ],
	OnListBox              => [ 'EVT_LISTBOX'                ],
	OnListBoxDClick        => [ 'EVT_LISTBOX_DCLICK'         ],
	OnText                 => [ 'EVT_TEXT'                   ],
	OnTextEnter            => [ 'EVT_TEXT_ENTER'             ],
	OnMenu                 => [ 'EVT_MENU'                   ],
	OnMenuRange            => [ 'EVT_MENU_RANGE'             ],

	# wxCloseEvent
	OnClose                => [ 'EVT_CLOSE'                  ],

	# wxEraseEvent
	OnEraseBackground      => [ ''                           ],

	# wxFocusEvent
	OnKillFocus            => [ 'EVT_KILL_FOCUS'             ],
	OnSetFocus             => [ 'EVT_SET_FOCUS'              ],

	# wxIdleEvent
	OnIdle                 => [ 'EVT_IDLE'                   ],

	# wxKeyEvent
	OnChar                 => [ 'EVT_CHAR'                   ],
	OnKeyDown              => [ 'EVT_KEY_DOWN'               ],
	OnKeyUp                => [ 'EVT_KEY_UP'                 ],

	# wxHtmlWindow
	OnHtmlCellClicked      => [ 'EVT_HTML_CELL_CLICKED'      ],
	OnHtmlCellHover        => [ 'EVT_HTML_CELL_HOVER'        ],
	OnHtmlLinkClicked      => [ 'EVT_HTML_LINK_CLICKED'      ],

	# wxListEvent
	OnListBeginDrag        => [ 'EVT_LIST_BEGIN_DRAG'        ],
	OnListBeginRDrag       => [ 'EVT_LIST_BEGIN_RDRAG'       ],
	OnListBeginLabelEdit   => [ 'EVT_LIST_BEGIN_LABEL_EDIT'  ],
	OnListCacheHint        => [ 'EVT_LIST_CACHE_HINT'        ],
	OnListEndLabelEdit     => [ 'EVT_LIST_END_LABEL_EDIT'    ],
	OnListDeleteItem       => [ 'EVT_LIST_DELETE_ITEM'       ],
	OnListDeleteAllItems   => [ 'EVT_LIST_DELETE_ALL_ITEMS'  ],
	OnListInsertItem       => [ 'EVT_LIST_INSERT_ITEM'       ],
	OnListItemActivated    => [ 'EVT_LIST_ITEM_ACTIVATED'    ],
	OnListItemSelected     => [ 'EVT_LIST_ITEM_SELECTED'     ],
	OnListItemDeselected   => [ 'EVT_LIST_ITEM_DESELECTED'   ],
	OnListItemFocused      => [ 'EVT_LIST_ITEM_FOCUSED'      ],
	OnListItemMiddleClick  => [ 'EVT_LIST_MIDDLE_CLICK'      ],
	OnListItemRightClick   => [ 'EVT_LIST_RIGHT_CLICK'       ],
	OnListKeyDown          => [ 'EVT_LIST_KEY_DOWN'          ],
	OnListColClick         => [ 'EVT_LIST_COL_CLICK'         ],
	OnListColRightClick    => [ 'EVT_LIST_COL_RIGHT_CLICK'   ],
	OnListColBeginDrag     => [ 'EVT_LIST_COL_BEGIN_DRAG'    ],
	OnListColDragging      => [ 'EVT_LIST_COL_DRAGGING'      ],
	OnListColEndDrag       => [ 'EVT_LIST_COL_END_DRAG'      ],

	# wxMouseEvent
	OnEnterWindow          => [ 'EVT_ENTER_WINDOW'           ],
	OnLeaveWindow          => [ 'EVT_LEAVE_WINDOW'           ],
	OnLeftDClick           => [ 'EVT_LEFT_DCLICK'            ],
	OnLeftDown             => [ 'EVT_LEFT_DOWN'              ],
	OnLeftUp               => [ 'EVT_LEFT_UP'                ],
	OnMiddleClick          => [ 'EVT_MIDDLE_CLICK'           ],
	OnMiddleDown           => [ 'EVT_MIDDLE_DOWN'            ],
	OnMiddleUp             => [ 'EVT_MIDDLE_UP'              ],
	OnMotion               => [ 'EVT_MOTION'                 ],
	OnMouseEvents          => [ 'EVT_MOUSE_EVENTS'           ],
	OnMouseWheel           => [ 'EVT_MOUSE_WHEEL'            ],
	OnRightDClick          => [ 'EVT_RIGHT_DCLICK'           ],
	OnRightDown            => [ 'EVT_RIGHT_DOWN'             ],
	OnRightUp              => [ 'EVT_RIGHT_UP'               ],

	# wxNotebookEvent
	OnNotebookPageChanging => [ 'EVT_NOTEBOOK_PAGE_CHANGING' ],
	OnNotebookPageChanged  => [ 'EVT_NOTEBOOK_PAGE_CHANGED'  ],
);

sub window_bindings {
	my $self     = shift;
	my $window   = shift;
	my $variable = $self->object_variable($window);

	my @lines = ();
	foreach my $attribute ( sort keys %EVENT ) {
		next unless $window->can($attribute);

		# Is there something to bind to
		my $method = $window->$attribute() or next;

		# Add the binding for it
		my $macro = $EVENT{$attribute}->[0];
		push @lines, (
			"",
			"Wx::Event::$macro(",
			"\t\$self,",
			"\t$variable,",
			"\tsub {",
			"\t\tshift->$method(\@_);",
			"\t},",
			");",
		);
	}

	return \@lines;
}

sub dialog_methods {
	my $self    = shift;
	my $dialog  = shift;
	my @windows = $dialog->find( isa => 'FBP::Window' );
	my %seen    = ();
	my @lines   = ();

	# Add the accessor methods
	foreach my $window ( @windows ) {
		next unless $window->can('name');
		next unless $window->can('permission');
		next unless $window->permission eq 'public';

		# Protect against duplicates
		my $name = $window->name;
		if ( $seen{$name}++ ) {
			die "Duplicate method '$name' detected";
		}

		push @lines, (
			"",
			"sub $name {",
			"\t\$_[0]->{$name};",
			"}",
		);
	}

	# Add the event handler methods
	foreach my $window ( @windows ) {
		foreach my $event ( sort keys %EVENT ) {
			next unless $window->can($event);

			my $name = $window->$event();
			next unless defined $name;
			next unless length $name;

			# Protect against duplicates
			if ( $seen{$name}++ ) {
				die "Duplicate method '$name' detected";
			}

			push @lines, (
				"",
				"sub $name {",
				"\tmy \$self  = shift;",
				"\tmy \$event = shift;",
				"",
				"\tdie 'EVENT HANDLER NOT IMPLEMENTED';",
				"}",
			);
		}
	}

	return \@lines;
}





######################################################################
# Common Fragment Generators

my %OBJECT_UNLEXICAL = (
	'FBP::Button'     => 1,
	'FBP::CheckBox'   => 1,
	'FBP::Choice'     => 1,
	'FBP::ComboBox'   => 1,
	'FBP::HtmlWindow' => 1,
	'FBP::ListBox'    => 1,
	'FBP::ListCtrl'   => 1,
);

sub object_lexical {
	unless ( $_[1] and $_[1]->can('permission') ) {
		$DB::single = 1;
	}
	$_[1]->permission !~ /^(?:protected|public)\z/;
}

sub object_label {
	$_[0]->text( $_[1]->label );
}

sub object_variable {
	my $self    = shift;
	my $object  = shift;
	my $lexical = $self->object_lexical($object);
	if ( $lexical ) {
		return '$' . $object->name;
	} else {
		return '$self->{' . $object->name . '}';
	}
}

sub object_position {
	my $self     = shift;
	my $object   = shift;
	my $position = $object->pos;
	unless ( $position ) {
		return 'Wx::wxDefaultPosition';
	}
	$position =~ s/,/, /;
	return "[ $position ]";
}

sub object_size {
	my $self   = shift;
	my $object = shift;
	my $size   = $object->size;
	unless ( $size ) {
		return 'Wx::wxDefaultSize';
	}
	$size =~ s/,/, /;
	return "[ $size ]";
}

sub window_new {
	my $self     = shift;
	my $window   = shift;
	my $lexical  = $self->object_lexical($window) ? 'my ' : '';
	my $variable = $self->object_variable($window);
	my $wxclass  = $window->wxclass;
	return "$lexical$variable = $wxclass->new(";
}

sub control_items {
	my $self    = shift;
	my $control = shift;
	my @items   = $control->items;
	unless ( @items ) {
		return '[ ],';
	}

	return $self->nested(
		'[',
		( map { $self->quote($_) . ',' } @items ),
		'],',
	);
}





######################################################################
# Support Methods

sub use_pragma {
	my $self   = shift;
	my $dialog = shift;
	return [
		"use 5.008;",
		"use strict;",
		"use warnings;",
	]
}

sub use_wx {
	my $self   = shift;
	my $object = shift;
	return [
		"use Wx ':everything';",
	];
}

sub use_more {
	my $self   = shift;
	my $object = shift;

	# Search for all the custom classes and load them
	my %seen = ();
	return [
		map {
			"use $_ ();"
		} sort grep {
			not $seen{$_}++
		} map {
			$_->wxclass
		} grep {
			$_->subclass =~ /^[^;]/
		} $object->find( isa => 'FBP::Window' )
	];
}

sub wx {
	my $self   = shift;
	my $string = shift;
	return 0  if $string eq '';
	return -1 if $string eq 'wxID_ANY';
	$string =~ s/\bwx/Wx::wx/g;
	$string =~ s/\s*\|\s*/ | /g;
	return $string;
}

sub text {
	my $self   = shift;
	my $string = shift;
	unless ( defined $string and length $string ) {
		return "''";
	}

	# Quote and translate the label
	$string = $self->quote($string);
	if ( $self->project->internationalize ) {
		$string = "Wx::gettext($string)";
	}

	return $string;
}

sub quote {
	my $self   = shift;
	my $string = shift;

	# This gets tricky if you ever hit weird characters
	# or Unicode, so hand off to an expert.
	my $code = do {
		local $Data::Dumper::Terse = 1;
		local $Data::Dumper::Useqq = 1;
		Data::Dumper::Dumper($string);
	};

	# Trim off the trailing space it will add.
	$code =~ s/\s+\z//;
	return $code;
}

sub indent {
	map { /\S/ ? "\t$_" : $_ } @{$_[1]};
}

# Indent except for the first and last lines.
# Return as an array reference.
sub nested {
	my $self   = shift;
	my @lines  = map { ref $_ ? @$_ : $_ } @_;
	my $top    = shift @lines;
	my $bottom = pop @lines;
	return [
		$top,
		( map { /\S/ ? "\t$_" : $_ } @lines ),
		$bottom,
	];
}

sub flatten {
	join '', map { "$_\n" } @{$_[1]};
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FBP-Perl>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2010 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
