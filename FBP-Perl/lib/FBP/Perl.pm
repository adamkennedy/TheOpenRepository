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
use Mouse 0.61;
use FBP   0.11 ();

our $VERSION = '0.08';

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
	my $isa     = $self->dialog_isa($dialog);
	my $new     = $self->dialog_new($dialog);
	my $methods = $self->dialog_methods($dialog);

	return [
		"package $package;",
		"",
		@$pragma,
		@$wx,
		"",
		"our \$VERSION = '0.01';",
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
	my @sizers  = $self->indent( $self->dialog_sizers($dialog) );
	my @windows = map { $self->indent($_), "" }
	              map { $self->window_create($_) }
	              $dialog->find( isa => 'FBP::Window' );

	return [
		"sub new {",
		"\tmy \$class  = shift;",
		"\tmy \$parent = shift;",
		"",
		$self->indent($super),
		"",
		@windows,
		@sizers,
		"\treturn \$self;",
		"}",
	];
}

sub dialog_super {
	my $self     = shift;
	my $dialog   = shift;
	my $id       = $self->wx( $dialog->id );
	my $label    = $self->object_label($dialog);
	my $position = $self->object_position($dialog);
	my $size     = $self->object_size($dialog);
	my $style    = $self->wx( $dialog->styles || 'wxDEFAULT_DIALOG_STYLE' );

	return [
		"my \$self = \$class->SUPER::new(",
		"\t\$parent,",
		"\t$id,",
		"\t$label,",
		"\t$position,",
		"\t$size,",
		( $style ? "\t$style," : () ),
		");",
	];
}

sub dialog_sizers {
	my $self   = shift;
	my $dialog = shift;

	# Check the root sizer
	my $sizer = $dialog->children->[0];
	unless ( $sizer->isa('FBP::BoxSizer') ) {
		die 'Dialog root sizer is not a BoxSizer';
	}

	# Generate fragments
	my $variable = $self->object_variable($sizer);
	my $boxsizer = $self->boxsizer_create($sizer);

	return [
		@$boxsizer,
		"",
		"\$self->SetSizer($variable);",
		"\$self->Layout;",
		"$variable->Fit(\$self);",
		"",
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
	} elsif ( $window->isa('FBP::ListBox') ) {
		$lines = $self->listbox_create($window);
	} elsif ( $window->isa('FBP::ListCtrl') ) {
		$lines = $self->listctrl_create($window);
	} elsif ( $window->isa('FBP::StaticLine') ) {
		$lines = $self->staticline_create($window);
	} elsif ( $window->isa('FBP::StaticText') ) {
		$lines = $self->statictext_create($window);
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
	my $lexical  = $self->object_lexical($control) ? 'my ' : '';
	my $variable = $self->object_variable($control);
	my $id       = $self->wx( $control->id );
	my $label    = $self->object_label($control);
	my @lines    = (
		"$lexical$variable = Wx::Button->new(",
		"\t\$self,",
		"\t$id,",
		"\t$label,",
		");",
	);
	if ( $control->default ) {
		push @lines, "$variable->SetDefault;";
	}
	unless ( $control->enabled ) {
		push @lines, "$variable->Disable;";
	}

	return \@lines;
}

sub checkbox_create {
	my $self     = shift;
	my $control  = shift;
	my $lexical  = $self->object_lexical($control) ? 'my ' : '';
	my $variable = $self->object_variable($control);
	my $id       = $self->wx( $control->id );
	my $label    = $self->object_label($control);
	my $position = $self->object_position($control);
	my $size     = $self->object_size($control);
	my $style    = $self->wx( $control->styles );

	return [
		"$lexical$variable = Wx::CheckBox->new(",
		"\t\$self,",
		"\t$id,",
		"\t$label,",
		"\t$position,",
		"\t$size,",
		( $style ? "\t$style," : () ),
		");",
	];
}

sub choice_create {
	my $self     = shift;
	my $control  = shift;
	my $lexical  = $self->object_lexical($control) ? 'my ' : '';
	my $variable = $self->object_variable($control);
	my $id       = $self->wx( $control->id );
	my $position = $self->object_position($control);
	my $size     = $self->object_size($control);

	return [
		"$lexical$variable = Wx::Choice->new(",
		"\t\$self,",
		"\t$id,",
		"\t$position,",
		"\t$size,",
		"\t[ ],",
		");",
	];
}

sub combobox_create {
	my $self     = shift;
	my $control  = shift;
	my $lexical  = $self->object_lexical($control) ? 'my ' : '';
	my $variable = $self->object_variable($control);
	my $id       = $self->wx( $control->id );
	my $value    = $self->quote( $control->value );
	my $position = $self->object_position($control);
	my $size     = $self->object_size($control);
	my $style    = $self->wx( $control->styles );

	return [
		"$lexical$variable = Wx::ComboBox->new(",
		"\t\$self,",
		"\t$id,",
		"\t$value,",
		"\t$position,",
		"\t$size,",
		"\t[ ],",
		( $style ? "\t$style," : () ),
		");",
	];
}

sub htmlwindow_create {
	my $self     = shift;
	my $control  = shift;
	my $lexical  = $self->object_lexical($control) ? 'my ' : '';
	my $variable = $self->object_variable($control);
	my $id       = $self->wx( $control->id );
	my $position = $self->object_position($control);
	my $size     = $self->object_size($control);
	my $style    = $self->wx( $control->styles );

	return [
		"$lexical$variable = Wx::HtmlWindow->new(",
		"\t\$self,",
		"\t$id,",
		"\t$position,",
		"\t$size,",
		( $style ? "\t$style," : () ),
		");",
	];
}

sub listbox_create {
	my $self     = shift;
	my $control  = shift;
	my $lexical  = $self->object_lexical($control) ? 'my ' : '';
	my $variable = $self->object_variable($control);
	my $id       = $self->wx( $control->id );
	my $position = $self->object_position($control);
	my $size     = $self->object_size($control);
	my $style    = $self->wx( $control->styles );
	
	return [
		"$lexical$variable = Wx::ListBox->new(",
		"\t\$self,",
		"\t$id,",
		"\t$position,",
		"\t$size,",
		"\t[ ],",
		( $style ? "\t$style," : () ),
		");",
	];
}

sub listctrl_create {
	my $self     = shift;
	my $control  = shift;
	my $lexical  = $self->object_lexical($control) ? 'my ' : '';
	my $variable = $self->object_variable($control);
	my $id       = $self->wx( $control->id );
	my $position = $self->object_position($control);
	my $size     = $self->object_size($control);
	my $style    = $self->wx( $control->styles );	

	return [
		"$lexical$variable = Wx::ListCtrl->new(",
		"\t\$self,",
		"\t$id,",
		"\t$position,",
		"\t$size,",
		( $style ? "\t$style," : () ),
		");",
	];
}

sub statictext_create {
	my $self     = shift;
	my $control  = shift;
	my $lexical  = $self->object_lexical($control) ? 'my ' : '';
	my $variable = $self->object_variable($control);
	my $id       = $self->wx( $control->id );
	my $label    = $self->object_label($control);

	return [
		"$lexical$variable = Wx::StaticText->new(",
		"\t\$self,",
		"\t$id,",
		"\t$label,",
		");",
	];
}

sub staticline_create {
	my $self     = shift;
	my $control  = shift;
	my $lexical  = $self->object_lexical($control) ? 'my ' : '';
	my $variable = $self->object_variable($control);
	my $id       = $self->wx( $control->id );
	my $position = $self->object_position($control);
	my $size     = $self->object_size($control);
	my $style    = $self->wx( $control->styles );

	return [
		"$lexical$variable = Wx::StaticLine->new(",
		"\t\$self,",
		"\t$id,",
		"\t$position,",
		"\t$size,",
		( $style ? "\t$style," : () ),
		");",
	];
}

sub boxsizer_create {
	my $self     = shift;
	my $sizer    = shift;
	my $lexical  = $self->object_lexical($sizer) ? 'my ' : '';
	my $variable = $self->object_variable($sizer);
	my $orient   = $self->wx( $sizer->orient );

	# Add the content for child sizers
	my @lines = map {
		( @$_, "" )
	} map {
		$self->boxsizer_create($_)
	} grep {
		$_->isa('FBP::Sizer')
	} map {
		$_->children->[0]
	} @{$sizer->children};

	# Add the content for this sizer
	push @lines, "$lexical$variable = Wx::BoxSizer->new( $orient );";
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

	return \@lines;
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
	my $self   = shift;
	my $dialog = shift;

	# Generate the list of all methods
	my @methods = ();
	foreach my $window ( $dialog->find( isa => 'FBP::Window' ) ) {
		push @methods, grep {
			defined $_ and length $_
		} map {
			$window->$_()
		} grep {
			$window->can($_)
		} sort keys %EVENT;
	}

	# Generate the code for the methods
	return [
		map { (
			"",
			"sub $_ {",
			"\tmy \$self  = shift;",
			"\tmy \$event = shift;",
			"",
			"\tdie 'TO BE COMPLETED';",
			"}"
		) } sort @methods
	];
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
	my $self    = shift;
	my $object  = shift;
	if ( $object->permission eq 'protected' ) {
		return 0;
	} else {
		return 1;
	}
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

sub object_label {
	my $self   = shift;
	my $object = shift;
	my $label  = $object->label;
	unless ( defined $label and length $label ) {
		return "''";
	}

	# Quote and translate the label
	$label = "'$label'";
	if ( $self->project->internationalize ) {
		$label = "Wx::gettext($label)";
	}

	return $label;
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

sub wx {
	my $self   = shift;
	my $string = shift;
	return 0  if $string eq '';
	return -1 if $string eq 'wxID_ANY';
	$string =~ s/\bwx/Wx::wx/g;
	$string =~ s/\s*\|\s*/ | /g;
	return $string;
}

sub quote {
	my $self   = shift;
	my $string = shift;
	return '"' . quotemeta($string) . '"';
}

sub indent {
	map { /\S/ ? "\t$_" : $_ } @{$_[1]};
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

Copyright 2010 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
