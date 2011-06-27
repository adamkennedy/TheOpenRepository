package FBP::Perl;

=pod

=head1 NAME

FBP::Perl - Generate Perl GUI code from wxFormBuilder .fbp files

=head1 SYNOPSIS

  my $fbp = FBP->new;
  $fbp->parse_file( 'MyProject.fbp' );
  
  my $generator = FBP::Perl->new(
      project => $fbp->project
  );
  
  open( FILE, '>', 'MyDialog.pm');
  print $generator->flatten(
      $generator->dialog_class(
          $fbp->dialog('MyDialog')
      )
  );
  close FILE;

=head1 DESCRIPTION

B<FBP::Perl> is a cross-platform Perl code generator for the cross-platform
L<wxFormBuilder|http://wxformbuilder.org/> GUI designer application.

Used with the L<FBP> module for parsing native wxFormBuilder save files, it
allows the production of complete standalone classes representing a complete
L<Wx> dialog, frame or panel as it appears in wxFormBuilder.

As code generators go, the Wx code produced by B<FBP::Perl> is remarkebly
readable. The produced code can be used either as a starter template which
you modify, or as a pristine class which you subclass in order to customise.

Born from the L<Padre> Perl IDE project, the code generation API provided by
B<FBP::Perl> is also extremely amenable to being itself subclassed.

This allows you to relatively easily write customised code generators that
produce output more closely tailored to your large Wx-based application, or
to automatically integrate Perl Tidy or other beautifiers into your workflow.

=head1 METHODS

TO BE COMPLETED

=cut

use 5.008005;
use strict;
use warnings;
use FBP           0.31 ();
use Data::Dumper 2.122 ();

our $VERSION = '0.46';

# Event Binding Table
my %EVENT = (
	# Common low level painting events
	OnEraseBackground         => [ 'EVT_ERASE_BACKGROUND'           ],
	OnPaint                   => [ 'EVT_PAINT'                      ],
	OnSize                    => [ 'EVT_SIZE'                       ],
	OnUpdateUI                => [ 'EVT_UPDATE_UI'                  ],

	# wxActivateEvent
	OnActivate                => [ 'EVT_ACTIVATE'                   ],
	OnActivateApp             => [ 'EVT_ACTIVATE_APP'               ],

	# wxCommandEvent
	OnButtonClick             => [ 'EVT_BUTTON'                     ],
	OnCheckBox                => [ 'EVT_CHECKBOX'                   ],
	OnChoice                  => [ 'EVT_CHOICE'                     ],
	OnCombobox                => [ 'EVT_COMBOBOX'                   ],
	OnListBox                 => [ 'EVT_LISTBOX'                    ],
	OnListBoxDClick           => [ 'EVT_LISTBOX_DCLICK'             ],
	OnText                    => [ 'EVT_TEXT'                       ],
	OnTextEnter               => [ 'EVT_TEXT_ENTER'                 ],
	OnMenu                    => [ 'EVT_MENU'                       ],
	OnMenuRange               => [ 'EVT_MENU_RANGE'                 ],

	# wxColourPickerCtrl
	OnColourChanged           => [ 'EVT_COLOURPICKER_CHANGED'      ],

	# wxCloseEvent
	OnClose                   => [ 'EVT_CLOSE'                      ],

	# wxEraseEvent
	OnEraseBackground         => [ ''                               ],

	# wxFilePickerCtrl
	OnFileChanged             => [ 'EVT_FILEPICKER_CHANGED'         ],

	# wxFocusEvent
	OnKillFocus               => [ 'EVT_KILL_FOCUS'                 ],
	OnSetFocus                => [ 'EVT_SET_FOCUS'                  ],

	# wxFontPickerCtrl
	OnFontChanged             => [ 'EVT_FONTPICKER_CHANGED'        ],

	# wxIdleEvent
	OnIdle                    => [ 'EVT_IDLE'                       ],

	# wxKeyEvent
	OnChar                    => [ 'EVT_CHAR'                       ],
	OnKeyDown                 => [ 'EVT_KEY_DOWN'                   ],
	OnKeyUp                   => [ 'EVT_KEY_UP'                     ],

	# wxHtmlWindow
	OnHtmlCellClicked         => [ 'EVT_HTML_CELL_CLICKED'          ],
	OnHtmlCellHover           => [ 'EVT_HTML_CELL_HOVER'            ],
	OnHtmlLinkClicked         => [ 'EVT_HTML_LINK_CLICKED'          ],

	# wxMenuEvent
	OnMenuSelection           => [ 'EVT_MENU'                       ],

	# wxListEvent
	OnListBeginDrag           => [ 'EVT_LIST_BEGIN_DRAG'            ],
	OnListBeginRDrag          => [ 'EVT_LIST_BEGIN_RDRAG'           ],
	OnListBeginLabelEdit      => [ 'EVT_LIST_BEGIN_LABEL_EDIT'      ],
	OnListCacheHint           => [ 'EVT_LIST_CACHE_HINT'            ],
	OnListEndLabelEdit        => [ 'EVT_LIST_END_LABEL_EDIT'        ],
	OnListDeleteItem          => [ 'EVT_LIST_DELETE_ITEM'           ],
	OnListDeleteAllItems      => [ 'EVT_LIST_DELETE_ALL_ITEMS'      ],
	OnListInsertItem          => [ 'EVT_LIST_INSERT_ITEM'           ],
	OnListItemActivated       => [ 'EVT_LIST_ITEM_ACTIVATED'        ],
	OnListItemSelected        => [ 'EVT_LIST_ITEM_SELECTED'         ],
	OnListItemDeselected      => [ 'EVT_LIST_ITEM_DESELECTED'       ],
	OnListItemFocused         => [ 'EVT_LIST_ITEM_FOCUSED'          ],
	OnListItemMiddleClick     => [ 'EVT_LIST_MIDDLE_CLICK'          ],
	OnListItemRightClick      => [ 'EVT_LIST_RIGHT_CLICK'           ],
	OnListKeyDown             => [ 'EVT_LIST_KEY_DOWN'              ],
	OnListColClick            => [ 'EVT_LIST_COL_CLICK'             ],
	OnListColRightClick       => [ 'EVT_LIST_COL_RIGHT_CLICK'       ],
	OnListColBeginDrag        => [ 'EVT_LIST_COL_BEGIN_DRAG'        ],
	OnListColDragging         => [ 'EVT_LIST_COL_DRAGGING'          ],
	OnListColEndDrag          => [ 'EVT_LIST_COL_END_DRAG'          ],

	# wxMouseEvent
	OnEnterWindow             => [ 'EVT_ENTER_WINDOW'               ],
	OnLeaveWindow             => [ 'EVT_LEAVE_WINDOW'               ],
	OnLeftDClick              => [ 'EVT_LEFT_DCLICK'                ],
	OnLeftDown                => [ 'EVT_LEFT_DOWN'                  ],
	OnLeftUp                  => [ 'EVT_LEFT_UP'                    ],
	OnMiddleClick             => [ 'EVT_MIDDLE_CLICK'               ],
	OnMiddleDown              => [ 'EVT_MIDDLE_DOWN'                ],
	OnMiddleUp                => [ 'EVT_MIDDLE_UP'                  ],
	OnMotion                  => [ 'EVT_MOTION'                     ],
	OnMouseEvents             => [ 'EVT_MOUSE_EVENTS'               ],
	OnMouseWheel              => [ 'EVT_MOUSE_WHEEL'                ],
	OnRightDClick             => [ 'EVT_RIGHT_DCLICK'               ],
	OnRightDown               => [ 'EVT_RIGHT_DOWN'                 ],
	OnRightUp                 => [ 'EVT_RIGHT_UP'                   ],

	# wxNotebookEvent
	OnNotebookPageChanging    => [ 'EVT_NOTEBOOK_PAGE_CHANGING'     ],
	OnNotebookPageChanged     => [ 'EVT_NOTEBOOK_PAGE_CHANGED'      ],

	# wxRadioBox
	OnRadioBox                => [ 'EVT_RADIOBOX_SELECTED'          ],

	# wxSearchCtrl
	OnSearchButton            => [ 'EVT_SEARCHCTRL_SEARCH_BTN'      ],
	OnCancelButton            => [ 'EVT_SEARCHCTRL_CANCEL_BTN'      ],

	# wxSplitterEvent
	OnSplitterSashPosChanging => [ 'EVT_SPLITTER_SASH_POS_CHANGING' ],
	OnSplitterSashPosChanged  => [ 'EVT_SPLITTER_SASH_POS_CHANGED'  ],
	OnSplitterUnsplit         => [ 'EVT_SPLITTER_UNSPLIT'           ],
	OnSplitterDClick          => [ 'EVT_SPLITTER_DCLICK'            ],

	# Toolbar events
	OnToolClicked             => [ '' ],
	OnToolRClicked            => [ '' ],
	OnToolEnter               => [ '' ],
);





######################################################################
# Class Definition

use Mouse 0.61;

has project => (
	is       => 'ro',
	isa      => 'FBP::Project',
	required => 1,
);

no Mouse;





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
# Project Generators

sub project_class {
	my $self    = shift;
	my $project = shift;
	my $package = $self->project_package($project);
	my $pragma  = $self->use_pragma($project);
	my $wx      = $self->project_wx($project);
	my $forms   = $self->project_forms($project);
	my $version = $self->project_version($project);
	my $isa     = $self->project_isa($project);

	return [
		"package $package;",
		"",
		@$pragma,
		@$wx,
		# @$forms,
		"",
		@$version,
		@$isa,
		"",
		"1;"
	];
}

sub project_package {
	my $self    = shift;
	my $project = shift;

	# For the time being just use the plain name
	return $project->name;
}

sub project_wx {
	my $self    = shift;
	my $project = shift;
	my @lines   = (
		"use Wx ':everything';",
	);
	if ( $project->internationalize ) {
		push @lines, "use Wx::Locale ();";
	}
	return \@lines;
}

sub project_forms {
	my $self    = shift;
	my $project = shift;

	return [
		map {
			"use $_ ();"
		} map {
			$self->form_package($_)
		} $project->forms
	];
}

sub project_version {
	my $self    = shift;
	my $project = shift;

	return [
		"our \$VERSION = '0.01';",
	];
}

sub project_isa {
	my $self = shift;

	return [
		"our \@ISA     = 'Wx::App';",
	];
}





######################################################################
# Form Generators

sub dialog_class {
	shift->form_class(@_);
}

sub frame_class {
	shift->form_class(@_);
}

sub panel_class {
	shift->form_class(@_);
}

sub form_class {
	my $self    = shift;
	my $form    = shift;
	my $package = $self->form_package($form);
	my $pragma  = $self->use_pragma($form);
	my $wx      = $self->form_wx($form);
	my $more    = $self->form_custom($form);
	my $version = $self->form_version($form);
	my $isa     = $self->form_isa($form);
	my $new     = $self->form_new($form);
	my $methods = $self->form_methods($form);

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

sub form_package {
	my $self = shift;
	my $form = shift;

	# For the time being just use the plain name
	return $form->name;
}

sub form_wx {
	my $self  = shift;
	my $topic = shift;

	return [
		"use Wx ':everything';",
	];
}

sub form_custom {
	my $self = shift;
	my $form = shift;

	# Search for all the custom classes and load them
	my %seen = ();
	return [
		map {
			"use $_ ();"
		} sort grep {
			not $seen{$_}++
		} map {
			$_->header
		} $form->find( isa => 'FBP::Window' )
	];
}

sub form_version {
	my $self = shift;
	my $form = shift;

	# Ignore the form and inherit from the parent project
	return $self->project_version( $self->project );
}

sub form_isa {
	my $self = shift;
	my $form = shift;
	if ( $form->isa('FBP::Dialog') ) {
		return [
			"our \@ISA     = 'Wx::Dialog';",
		];

	} elsif ( $form->isa('FBP::Frame') ) {
		return [
			"our \@ISA     = 'Wx::Frame';",
		];

	} elsif ( $form->isa('FBP::Panel') ) {
		return [
			"our \@ISA     = 'Wx::Panel';",
		];

	} else {
		die "Unsupported form " . ref($form);
	}
}

sub form_new {
	my $self    = shift;
	my $form    = shift;
	my $super   = $self->form_super($form);
	my @windows = $self->children_create($form);
	my @sizers  = $self->form_sizers($form);
	my $status  = $form->find_first( isa => 'FBP::StatusBar' );

	my @set = ();
	if ( $self->form_setsizehints($form) ) {
		my $minsize = $self->wxsize($form->minimum_size);
		my $maxsize = $self->wxsize($form->maximum_size);
		push @set, "\$self->SetSizeHints( $minsize, $maxsize );";
	}
	if ( $status ) {
		my $statusbar = $self->statusbar_create($status, $form);
		push @set, @$statusbar;
	}

	return $self->nested(
		"sub new {",
		"my \$class  = shift;",
		"my \$parent = shift;",
		"",
		$super,
		@set,
		"",
		( map { @$_, "" } @windows ),
		( map { @$_, "" } @sizers  ),
		"return \$self;",
		"}",
	);
}

sub form_super {
	my $self = shift;
	my $form = shift;
	if ( $form->isa('FBP::Dialog') ) {
		return $self->dialog_super($form);
	} elsif ( $form->isa('FBP::Frame') ) {
		return $self->frame_super($form);
	} elsif ( $form->isa('FBP::Panel') ) {
		return $self->panel_super($form);
	} else {
		die "Unsupported top class " . ref($form);
	}
}

sub dialog_super {
	my $self     = shift;
	my $dialog     = shift;
	my $id       = $self->wx( $dialog->id );
	my $title    = $self->text( $dialog->title );
	my $position = $self->object_position($dialog);
	my $size     = $self->object_wxsize($dialog);

	return $self->nested(
		"my \$self = \$class->SUPER::new(",
		"\$parent,",
		"$id,",
		"$title,",
		"$position,",
		"$size,",
		$self->window_style($dialog, 'wxDEFAULT_DIALOG_STYLE'),
		");",
	);
}

sub frame_super {
	my $self     = shift;
	my $frame     = shift;
	my $id       = $self->wx( $frame->id );
	my $title    = $self->text( $frame->title );
	my $position = $self->object_position($frame);
	my $size     = $self->object_wxsize($frame);

	return $self->nested(
		"my \$self = \$class->SUPER::new(",
		"\$parent,",
		"$id,",
		"$title,",
		"$position,",
		"$size,",
		$self->window_style($frame, 'wxDEFAULT_FRAME_STYLE'),
		");",
	);
}

sub panel_super {
	my $self     = shift;
	my $panel     = shift;
	my $id       = $self->wx( $panel->id );
	my $position = $self->object_position($panel);
	my $size     = $self->object_wxsize($panel);

	return $self->nested(
		"my \$self = \$class->SUPER::new(",
		"\$parent,",
		"$id,",
		"$position,",
		"$size,",
		$self->window_style($panel),
		");",
	);
}

sub form_sizers {
	my $self     = shift;
	my $form     = shift;
	my $sizer    = $self->form_rootsizer($form);
	my $variable = $self->object_variable($sizer);
	my @children = $self->sizer_pack($sizer);

	return (
		@children,
		[
			"\$self->SetSizer($variable);",
			"\$self->Layout;",
			(
				$self->size($form->size)
				? ()
				: "$variable->Fit(\$self);"
			),
			(
				$self->form_setsizehints($form)
				? "$variable->SetSizeHints(\$self);"
				: ()
			),
		]
	);
}

sub form_rootsizer {
	my $self   = shift;
	my $form   = shift;
	my @sizers = grep { $_->isa('FBP::Sizer') } @{$form->children};
	unless ( @sizers ) {
		die "Form does not contain any sizers";
	}
	unless ( @sizers == 1 ) {
		die "Form contains more than one root sizer";
	}
	return $sizers[0];
}

sub form_setsizehints {
	my $self = shift;
	my $form = shift;

	# Only dialogs and frames can resize
	if ( $form->isa('FBP::Dialog') or $form->isa('FBP::Frame') ) {
		# If our borders are resizable we need to set size hints
		if ( $form->style =~ /\bwxRESIZE_BORDER\b/ ) {
			return 1;
		}
	}

	# If the dialog has size hints, we do need them
	if ( $self->size($form->minimum_size) ) {
		return 1;
	}
	if ( $self->size($form->maximum_size) ) {
		return 1;
	}

	return 0;
}

sub form_methods {
	my $self    = shift;
	my $form    = shift;
	my @objects = (
		$form->find( isa => 'FBP::Window' ),
		$form->find( isa => 'FBP::MenuItem' ),
	);
	my %seen    = ();
	my %done    = ();
	my @methods = ();

	# Add the accessor methods
	foreach my $object ( @objects ) {
		next unless $object->can('name');
		next unless $object->can('permission');
		next unless $object->permission eq 'public';

		# Protect against duplicates
		my $name = $object->name;
		if ( $seen{$name}++ ) {
			die "Duplicate method '$name' detected";
		}

		push @methods, $self->object_accessor($object);
	}

	# Add the event handler methods
	foreach my $object ( @objects ) {
		foreach my $event ( sort keys %EVENT ) {
			next unless $object->can($event);

			my $name   = $object->name;
			my $method = $object->$event();
			next unless defined $method;
			next unless length $method;

			# Protect against duplicates
			if ( $seen{$method} ) {
				die "Duplicate method '$method' detected";
			}
			next if $done{$method}++;

			push @methods, $self->object_event($object, $event);
		}
	}

	# Convert back to a single block of lines
	return [
		map { ( "", @$_ ) } @methods
	];
}





######################################################################
# Window and Control Generators

sub children_create {
	my $self    = shift;
	my $object  = shift;
	my $parent  = shift;
	my @windows = ();

	foreach my $child ( @{$object->children} ) {
		# Skip elements we create outside the main recursion
		next if $child->isa('FBP::StatusBar');

		if ( $child->isa('FBP::Window') ) {
			push @windows, $self->window_create($child, $parent);
		}

		# Descend to child windows
		next unless $child->does('FBP::Children');
		if ( $object->isa('FBP::Window') ) {
			push @windows, $self->children_create($child, $object);
		} else {
			push @windows, $self->children_create($child, $parent);
		}
	}

	return @windows;
}

sub window_create {
	my $self   = shift;
	my $window = shift;
	my $parent = shift;
	my $lines  = undef;

	if ( $window->isa('FBP::Button') ) {
		$lines = $self->button_create($window, $parent);
	} elsif ( $window->isa('FBP::CheckBox') ) {
		$lines = $self->checkbox_create($window, $parent);
	} elsif ( $window->isa('FBP::Choice') ) {
		$lines = $self->choice_create($window, $parent);
	} elsif ( $window->isa('FBP::ComboBox') ) {
		$lines = $self->combobox_create($window, $parent);
	} elsif ( $window->isa('FBP::ColourPickerCtrl') ) {
		$lines = $self->colourpickerctrl_create($window, $parent);
	} elsif ( $window->isa('FBP::CustomControl' ) ) {
		$lines = $self->customcontrol_create($window, $parent);
	} elsif ( $window->isa('FBP::DirPickerCtrl') ) {
		$lines = $self->dirpickerctrl_create($window, $parent);
	} elsif ( $window->isa('FBP::FilePickerCtrl') ) {
		$lines = $self->filepickerctrl_create($window, $parent);
	} elsif ( $window->isa('FBP::FontPickerCtrl') ) {
		$lines = $self->fontpickerctrl_create($window, $parent);
	} elsif ( $window->isa('FBP::Gauge') ) {
		$lines = $self->gauge_create($window, $parent);
	} elsif ( $window->isa('FBP::HtmlWindow') ) {
		$lines = $self->htmlwindow_create($window, $parent);
	} elsif ( $window->isa('FBP::HyperLink') ) {
		$lines = $self->hyperlink_create($window, $parent);
	} elsif ( $window->isa('FBP::Listbook') ) {
		# We emulate the creation of simple listbooks via treebooks
		if ( $window->wxclass eq 'Wx::Treebook' ) {
			$lines = $self->treebook_create($window, $parent);
		} else {
			$lines = $self->listbook_create($window, $parent);
		}
	} elsif ( $window->isa('FBP::ListBox') ) {
		$lines = $self->listbox_create($window, $parent);
	} elsif ( $window->isa('FBP::ListCtrl') ) {
		$lines = $self->listctrl_create($window, $parent);
	} elsif ( $window->isa('FBP::MenuBar') ) {
		$lines = $self->menubar_create($window, $parent);
	} elsif ( $window->isa('FBP::Panel') ) {
		$lines = $self->panel_create($window, $parent);
	} elsif ( $window->isa('FBP::RadioBox') ) {
		$lines = $self->radiobox_create($window, $parent);
	} elsif ( $window->isa('FBP::SearchCtrl') ) {
		$lines = $self->searchctrl_create($window, $parent);
	} elsif ( $window->isa('FBP::SpinCtrl') ) {
		$lines = $self->spinctrl_create($window, $parent);
	} elsif ( $window->isa('FBP::SplitterWindow') ) {
		$lines = $self->splitterwindow_create($window, $parent);
	} elsif ( $window->isa('FBP::StaticLine') ) {
		$lines = $self->staticline_create($window, $parent);
	} elsif ( $window->isa('FBP::StaticText') ) {
		$lines = $self->statictext_create($window, $parent);
	} elsif ( $window->isa('FBP::StatusBar') ) {
		$lines = $self->statusbar_create($window, $parent);
	} elsif ( $window->isa('FBP::TextCtrl') ) {
		$lines = $self->textctrl_create($window, $parent);
	} elsif ( $window->isa('FBP::ToolBar') ) {
		$lines = $self->toolbar_create($window, $parent);
	} else {
		die 'Cannot create constructor code for ' . ref($window);
	}

	# Add common modifications
	push @$lines, $self->window_selection($window);
	push @$lines, $self->window_minimum_size($window);
	push @$lines, $self->window_maximum_size($window);
	push @$lines, $self->window_fg($window);
	push @$lines, $self->window_bg($window);
	push @$lines, $self->window_font($window);
	push @$lines, $self->window_tooltip($window);
	push @$lines, $self->window_disable($window);
	push @$lines, $self->window_hide($window);
	push @$lines, $self->object_bindings($window);

	return $lines;
}

sub button_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->wx( $control->id );
	my $label    = $self->object_label($control);
	my $variable = $self->object_variable($control);

	my $lines = $self->nested(
		$self->window_new($control),
		"$parent,",
		"$id,",
		"$label,",
		");",
	);

	if ( $control->default ) {
		push @$lines, "$variable->SetDefault;";
	}

	return $lines;
}

sub checkbox_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->wx( $control->id );
	my $label    = $self->object_label($control);
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	return $self->nested(
		$self->window_new($control),
		"$parent,",
		"$id,",
		"$label,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);
}

sub choice_create {
	my $self      = shift;
	my $control   = shift;
	my $parent    = $self->object_parent(@_);
	my $id        = $self->wx( $control->id );
	my $position  = $self->object_position($control);
	my $size      = $self->object_wxsize($control);
	my $items     = $self->control_items($control);

	return $self->nested(
		$self->window_new($control),
		"$parent,",
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
	my $parent   = $self->object_parent(@_);
	my $id       = $self->wx( $control->id );
	my $value    = $self->quote( $control->value );
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);
	my $items    = $self->control_items($control);

	return $self->nested(
		$self->window_new($control),
		"$parent,",
		"$id,",
		"$value,",
		"$position,",
		"$size,",
		$items,
		$self->window_style($control),
		");",
	);
}

sub colourpickerctrl_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->wx( $control->id );
	my $colour   = $self->colour( $control->colour );
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	# Wx::ColourPickerCtrl does not support defaulting null colours.
	# Use an explicit black instead until we find a better option.
	if ( $colour eq 'undef' ) {
		$colour = $self->colour('0,0,0');
	}

	return $self->nested(
		$self->window_new($control),
		"$parent,",
		"$id,",
		"$colour,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);
}

# Completely generic custom control
sub customcontrol_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->wx( $control->id );

	return $self->nested(
		$self->window_new($control),
		"$parent,",
		"$id,",
		");",
	);
}

sub dirpickerctrl_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->wx( $control->id );
	my $value    = $self->quote( $control->value );
	my $message  = $self->quote( $control->message );
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	return $self->nested(
		$self->window_new($control),
		"$parent,",
		"$id,",
		"$value,",
		"$message,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);
}

sub filepickerctrl_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->wx( $control->id );
	my $value    = $self->quote( $control->value );
	my $message  = $self->quote( $control->message );
	my $wildcard = $self->quote( $control->wildcard );
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	return $self->nested(
		$self->window_new($control),
		"$parent,",
		"$id,",
		"$value,",
		"$message,",
		"$wildcard,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);
}

sub fontpickerctrl_create {
	my $self     = shift;
	my $control  = shift;
	my $variable = $self->object_variable($control);
	my $parent   = $self->object_parent(@_);
	my $id       = $self->wx( $control->id );
	my $font     = $self->font( $control->value );
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	my $lines = $self->nested(
		$self->window_new($control),
		"$parent,",
		"$id,",
		"$font,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);

	my $max_point_size = $control->max_point_size;
	if ( $max_point_size ) {
		push @$lines, "$variable->SetMaxPointSize($max_point_size);";
	}

	return $lines;
}

sub htmlwindow_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->wx( $control->id );
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	return $self->nested(
		$self->window_new($control),
		"$parent,",
		"$id,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);
}

sub hyperlink_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->wx( $control->id );
	my $label    = $self->object_label($control);
	my $url      = $self->quote( $control->url );
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	my $lines = $self->nested(
		$self->window_new($control),
		"$parent,",
		"$id,",
		"$label,",
		"$url,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);

	# Set additional properties
	my $variable = $self->object_variable($control);
	if ( $control->normal_color ) {
		my $colour = $self->colour( $control->normal_color );
		push @$lines, (
			"$variable->SetNormalColour(",
			"\t$colour",
			");",
		);
	}
	if ( $control->hover_color ) {
		my $colour = $self->colour( $control->hover_color );
		push @$lines, (
			"$variable->SetHoverColour(",
			"\t$colour",
			");",
		);
	}
	if ( $control->visited_color ) {
		my $colour = $self->colour( $control->visited_color );
		push @$lines, (
			"$variable->SetVisitedColour(",
			"\t$colour",
			");",
		);
	}

	return $lines;
}

sub gauge_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->wx( $control->id );
	my $range    = $control->range;
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	my $lines = $self->nested(
		$self->window_new($control),
		"$parent,",
		"$id,",
		"$range,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);

	# Set the value we are initially at
	my $variable = $self->object_variable($control);
	my $value    = $control->value;
	if ( $value ) {
		push @$lines, "$variable->SetValue($value);";
	}

	return $lines;
}

sub listbook_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->wx( $control->id );
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	return $self->nested(
		$self->window_new($control),
		"$parent,",
		"$id,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);
}

sub listbox_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->wx( $control->id );
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);
	my $items    = $self->control_items($control);

	return $self->nested(
		$self->window_new($control),
		"$parent,",
		"$id,",
		"$position,",
		"$size,",
		$items,
		$self->window_style($control),
		");",
	);
}

sub listctrl_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->wx( $control->id );
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	return $self->nested(
		$self->window_new($control),
		"$parent,",
		"$id,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);
}

sub menu_create {
	my $self     = shift;
	my $menu     = shift;
	my $scope    = $self->object_scope($menu);
	my $variable = $self->object_variable($menu);

	# Generate our children
	my @lines = (
		"$scope$variable = Wx::Menu->new;",
		"",
	);
	foreach my $child ( @{$menu->children} ) {
		if ( $child->isa('FBP::Menu') ) {
			push @lines, @{ $self->menu_create($child, $menu) };

		} elsif ( $child->isa('FBP::MenuItem') ) {
			push @lines, @{ $self->menuitem_create($child, $menu) };

		} else {
			next;
		}
		push @lines, "";
	}

	# Fill the menu
	foreach my $child ( @{$menu->children} ) {
		if ( $child->isa('FBP::Menu') ) {
			push @lines, $self->nested(
				"$variable->Append(",
				$self->object_variable($_) . ',',
				$self->object_label($_) . ',',
				");",
			);
		} elsif ( $child->isa('FBP::MenuItem') ) {
			push @lines, "$variable->Append( "
				. $self->object_variable($child)
				. " );";
		} elsif ( $child->isa('FBP::MenuSeparator') ) {
			push @lines, "$variable->AppendSeparator;";
		}
	}

	return \@lines;
}

sub menubar_create {
	my $self     = shift;
	my $window   = shift;
	my $parent   = $self->object_parent(@_);
	my $scope    = $self->object_scope($window);
	my $variable = $self->object_variable($window);
	my $style    = $self->wx($window->styles || 0);

	# Generate our children
	my @children = map {
		$self->menu_create($_, $self)
	} @{$window->children};

	# Build the append list
	my @append = map {
		$self->nested(
			"$variable->Append(",
			$self->object_variable($_) . ',',
			$self->object_label($_) . ',',
			");",
		)
	} @{$window->children};
 
	return [
		( map { @$_, "" } @children ),
		"$scope$variable = Wx::MenuBar->new($style);",
		"",
		@append,
		"",
		"$parent->SetMenuBar( $variable );",
	];
}

sub menuitem_create {
	my $self     = shift;
	my $menu     = shift;
	my $parent   = $self->object_parent(@_);
	my $scope    = $self->object_scope($menu);
	my $variable = $self->object_variable($menu);
	my $id       = $self->wx( $menu->id );
	my $label    = $self->object_label($menu);
	my $help     = $self->text( $menu->help );
	my $kind     = $self->wx( $menu->kind );

	# Create the menu item
	my $lines = $self->nested(
		"$scope$variable = Wx::MenuItem->new(",
		"$parent,",
		"$id,",
		"$label,",
		"$help,",
		"$kind,",
		");",
	);

	# Add the event bindings
	push @$lines, $self->object_bindings($menu);

	return $lines;
}

sub panel_create {
	my $self     = shift;
	my $window   = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->wx( $window->id );
	my $position = $self->object_position($window);
	my $size     = $self->object_wxsize($window);

	return $self->nested(
		$self->window_new($window),
		"$parent,",
		"$id,",
		"$position,",
		"$size,",
		$self->window_style($window),
		");",
	);
}

sub radiobox_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->wx( $control->id );
	my $label    = $self->quote( $control->label );
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);
	my $items    = $self->control_items($control);
	my $major    = $control->majorDimension || 1;

	return $self->nested(
		$self->window_new($control),
		"$parent,",
		"$id,",
		"$label,",
		"$position,",
		"$size,",
		$items,
		"$major,",
		$self->window_style($control),
		");",
	);
}

sub searchctrl_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->wx( $control->id );
	my $value    = $self->quote( $control->value );
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	my $lines = $self->nested(
		$self->window_new($control),
		"$parent,",
		"$id,",
		"$value,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);

	# Control which optional features we show
	my $platform      = $self->wx('wxMAC');
	my $variable      = $self->object_variable($control);
	my $search_button = $control->search_button;
	my $cancel_button = $control->cancel_button;
	push @$lines, (
		"unless ( $platform ) {",
		"\t$variable->ShowSearchButton($search_button);",
		"}",
		"$variable->ShowCancelButton($cancel_button);",
	);

	return $lines;
}

sub spinctrl_create {
	my $self     = shift;
	my $control  = shift;
	my $variable = $self->object_variable($control);
	my $parent   = $self->object_parent(@_);
	my $id       = $self->wx( $control->id );
	my $value    = $self->quote( $control->value );
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);
	my $style    = $self->wx( $control->styles );
	my $min      = $control->min;
	my $max      = $control->max;
	my $initial  = $control->initial;

	return $self->nested(
		$self->window_new($control),
		"$parent,",
		"$id,",
		"$value,",
		"$position,",
		"$size,",
		"$style,",
		"$min,",
		"$max,",
		"$initial,",
		");",
	);
}

sub splitterwindow_create {
	my $self     = shift;
	my $window   = shift;
	my $variable = $self->object_variable($window);
	my $parent   = $self->object_parent(@_);
	my $id       = $self->wx( $window->id );
	my $position = $self->object_position($window);
	my $size     = $self->object_wxsize($window);

	# Object constructor
	my $lines = $self->nested(
		$self->window_new($window),
		"$parent,",
		"$id,",
		"$position,",
		"$size,",
		$self->window_style($window),
		");",
	);

	# Optional settings
	my $sashsize      = $window->sashsize;
	my $sashgravity   = $window->sashgravity;
	my $min_pane_size = $window->min_pane_size;
	if ( $sashgravity > 0 ) {
		push @$lines, "$variable->SetSashGravity($sashgravity);";
	}
	if ( $sashsize >= 0 ) {
		push @$lines, "$variable->SetSashSize($sashsize);";
	}
	if ( $min_pane_size ) {
		push @$lines, "$variable->SetMinimumPaneSize($min_pane_size);";
	}

	return $lines;
}

sub statictext_create {
	my $self    = shift;
	my $control = shift;
	my $parent  = $self->object_parent(@_);
	my $id      = $self->wx( $control->id );
	my $label   = $self->object_label($control);

	return $self->nested(
		$self->window_new($control),
		"$parent,",
		"$id,",
		"$label,",
		");",
	);
}

sub staticline_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->wx( $control->id );
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);

	return $self->nested(
		$self->window_new($control),
		"$parent,",
		"$id,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);
}

sub statusbar_create {
	my $self     = shift;
	my $object   = shift;
	my $variable = $self->object_variable($object);
	my $parent   = $self->object_parent(@_);
	my $fields   = $object->fields;
	my $style    = $self->window_style($object, 0);
	my $id       = $self->wx( $object->id );

	# If the status bar is not stored for later reference,
	# don't create the variable at all to avoid perlcritic'ism
	if ( $self->object_lexical($object) ) {
		$variable = "";
	} else {
		$variable = "$variable = ";
	}

	return [
		"$variable$parent->CreateStatusBar( $fields, $style $id );",
	];
}

sub textctrl_create {
	my $self      = shift;
	my $control   = shift;
	my $parent    = $self->object_parent(@_);
	my $id        = $self->wx( $control->id );
	my $value     = $self->quote( $control->value );
	my $position  = $self->object_position($control);
	my $size      = $self->object_wxsize($control);

	my $lines = $self->nested(
		$self->window_new($control),
		"$parent,",
		"$id,",
		"$value,",
		"$position,",
		"$size,",
		$self->window_style($control),
		");",
	);

	my $maxlength = $control->maxlength;
	if ( $maxlength ) {
		my $variable = $self->object_variable($control);
		push @$lines, "$variable->SetMaxLength($maxlength);";
	}

	return $lines;
}

sub tool_create {
	my $self    = shift;
	my $tool    = shift;
	my $parent  = $self->object_parent(@_);
	my $id      = $self->wx( $tool->id );
	my $label   = $self->object_label($tool);
	my $bitmap  = $self->bitmap( $tool->bitmap );
	my $tooltip = $self->text( $tool->tooltip );
	my $kind    = $self->wx( $tool->kind );

	return $self->nested(
		"$parent->AddTool(",
		"$id,",
		"$label,",
		"$bitmap,",
		"$tooltip,",
		"$kind,",
		");",
	);
}

sub toolbar_create {
	my $self     = shift;
	my $window   = shift;
	my $parent   = $self->object_parent(@_);
	my $scope    = $self->object_scope($window);
	my $variable = $self->object_variable($window);
	my $style    = $self->wx($window->styles || 0);
	my $id       = $self->wx( $window->id );

	# Generate child constructor code
	my @children = map {
		$_->isa('FBP::Tool')
		? $self->tool_create($_, $window)
		: "$variable->AddSeparator;"
	} @{$window->children};

	return [
		"$scope$variable = $parent->CreateToolBar( $style, $id );",
		( map { ref $_ ? @$_ : $_ } @children ),
		"$variable->Realize;",
	];
}

sub treebook_create {
	my $self     = shift;
	my $control  = shift;
	my $parent   = $self->object_parent(@_);
	my $id       = $self->wx( $control->id );
	my $position = $self->object_position($control);
	my $size     = $self->object_wxsize($control);
	my $style    = $self->wx(
		# Strip listbook-specific styles
		join ' | ', grep { ! /^wxLB_/ } split /\s*\|\s*/, $control->styles
	);

	return $self->nested(
		$self->window_new($control),
		"$parent,",
		"$id,",
		"$position,",
		"$size,",
		( $style ? "$style," : () ),
		");",
	);
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
	my $scope    = $self->object_scope($sizer);
	my $variable = $self->object_variable($sizer);
	my $orient   = $self->wx( $sizer->orient );

	# Add the content for all our child sizers
	my @children = $self->children_pack($sizer);

	# Add the content for this sizer
	my @lines = (
		"$scope$variable = Wx::BoxSizer->new($orient);",
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
	my $scope    = $self->object_scope($sizer);
	my $variable = $self->object_variable($sizer);
	my $label    = $self->object_label($sizer);
	my $orient   = $self->wx( $sizer->orient );

	# Add the content for all our child sizers
	my @children = $self->children_pack($sizer);

	# Add the content for this sizer
	my @lines = (
		"$scope$variable = Wx::StaticBoxSizer->new(",
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
	my $scope    = $self->object_scope($sizer);
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
		"$scope$variable = Wx::GridSizer->new( $params );",
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
	my $scope     = $self->object_scope($sizer);
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
		"$scope$variable = Wx::FlexGridSizer->new( $params );",
	);
	foreach my $row ( split /,/, $sizer->growablerows ) {
		push @lines, "$variable->AddGrowableRow($row);";
	}
	foreach my $col ( split /,/, $sizer->growablecols ) {
		push @lines, "$variable->AddGrowableCol($col);";
	}
	push @lines, "$variable->SetFlexibleDirection($direction);";
	push @lines, "$variable->SetNonFlexibleGrowMode($growmode);";
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

	# Generate fragments for our child panels
	my @children = $self->children_pack($book);

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

	return ( @children, \@lines );
}

sub panel_pack {
	my $self     = shift;
	my $panel    = shift;
	my $sizer    = $panel->children->[0] or return ();
	my $variable = $self->object_variable($panel);
	my $sizervar = $self->object_variable($sizer);

	# Generate fragments for our (optional) child sizer
	my @children = $self->sizer_pack($sizer);

	# Attach the sizer to the panel
	return (
		@children,
		[
			"$variable->SetSizer($sizervar);",
			"$variable->Layout;",
			(
				$self->size($panel->size)
				? ()
				: "$sizervar->Fit($variable);"
			),
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
				( $sashpos ? "\t$sashpos," : () ),
				");",
			],
		);
	}

	die "Unexpected number of splitterwindow children";
}





######################################################################
# Window Statement Fragments

sub window_selection {
	my $self   = shift;
	my $window = shift;

	if ( $window->can('selection') ) {
		my $variable  = $self->object_variable($window);
		my $selection = $window->selection || 0;
		return (
			"$variable->SetSelection($selection);",
		);
	}

	return;
}

sub window_minimum_size {
	my $self   = shift;
	my $window = shift;

	if ( $window->minimum_size ) {
		my $variable = $self->object_variable($window);
		my $size     = $self->wxsize( $window->minimum_size );
		return (
			"$variable->SetMinSize( $size );",
		);
	}

	return;
}

sub window_maximum_size {
	my $self   = shift;
	my $window = shift;

	if ( $window->maximum_size ) {
		my $variable = $self->object_variable($window);
		my $size     = $self->wxsize( $window->maximum_size );
		return (
			"$variable->SetMaxSize( $size );",
		);
	}

	return;
}

sub window_fg {
	my $self   = shift;
	my $window = shift;

	if ( $window->fg ) {
		my $variable = $self->object_variable($window);
		my $colour   = $self->colour( $window->fg );
		return (
			"$variable->SetForegroundColour(",
			"\t$colour",
			");",
		);
	};

	return;
}

sub window_bg {
	my $self   = shift;
	my $window = shift;

	if ( $window->bg ) {
		my $variable = $self->object_variable($window);
		my $colour   = $self->colour( $window->bg );
		return (
			"$variable->SetBackgroundColour(",
			"\t$colour",
			");",
		);
	};

	return;
}

sub window_font {
	my $self   = shift;
	my $window = shift;

	if ( $window->font ) {
		my $variable = $self->object_variable($window);
		my $font     = $self->font( $window->font );
		return (
			"$variable->SetFont(",
			"\t$font",
			");",
		);
	}

	return;
}

sub window_tooltip {
	my $self   = shift;
	my $window = shift;

	if ( $window->tooltip ) {
		my $variable = $self->object_variable($window);
		my $tooltip  = $self->text( $window->tooltip );
		return (
			"$variable->SetToolTip(",
			"\t$tooltip",
			");",
		);
	}

	return;
}

sub window_disable {
	my $self   = shift;
	my $window = shift;

	unless ( $window->enabled ) {
		my $variable = $self->object_variable($window);
		return (
			"$variable->Disable;",
		);
	}

	return;
}

sub window_hide {
	my $self   = shift;
	my $window = shift;

	if ( $window->hidden ) {
		my $variable = $self->object_variable($window);
		return (
			"$variable->Hide;",
		);
	}

	return;
}

sub object_bindings {
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

	return @lines;
}





######################################################################
# Window Fragment Generators

sub object_lexical {
	$_[1]->permission !~ /^(?:protected|public)\z/;
}

sub object_label {
	$_[0]->text( $_[1]->label );
}

sub object_scope {
	my $self   = shift;
	my $object = shift;
	if ( $self->object_lexical($object) ) {
		return 'my ';
	} else {
		return '';
	}
}

sub object_variable {
	my $self   = shift;
	my $object = shift;
	if ( $self->object_lexical($object) ) {
		return '$' . $object->name;
	} else {
		return '$self->{' . $object->name . '}';
	}
}

sub object_parent {
	my $self   = shift;
	my $object = shift;
	if ( $object and not $object->DOES('FBP::Form') ) {
		return $self->object_variable($object);
	} else {
		return '$self';
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

sub object_wxsize {
	my $self   = shift;
	my $object = shift;
	return $self->wxsize($object->size);
}

# Is an object a top level project asset.
# i.e. A Dialog, Frame or top level Panel
sub object_top {
	my $self   = shift;
	my $object = shift;
	return 1 if $object->isa('FBP::Dialog');
	return 1 if $object->isa('FBP::Frame');
	return 0;
}

sub window_new {
	my $self     = shift;
	my $window   = shift;
	my $scope    = $self->object_scope($window);
	my $variable = $self->object_variable($window);
	my $wxclass  = $window->wxclass;
	return "$scope$variable = $wxclass->new(";
}

sub window_style {
	my $self    = shift;
	my $window  = shift;
	my $default = shift;
	my $styles  = $window->styles || $default;

	if ( defined $styles and length $styles ) {
		return $self->wx($styles) . ',';
	}

	return;
}

sub object_accessor {
	my $self   = shift;
	my $object = shift;
	my $name   = $object->name;

	return $self->nested(
		"sub $name {",
		"\$_[0]->{$name};",
		"}",
	);
}

sub object_event {
	my $self   = shift;
	my $window = shift;
	my $event  = shift;
	my $name   = $window->name;
	my $method = $window->$event();

	return $self->nested(
		"sub $method {",
		"die 'Handler method $method for event $name.$event not implemented';",
		"}",
	);
}

sub control_items {
	my $self    = shift;
	my $control = shift;
	my @items   = $control->items;
	unless ( @items ) {
		return '[],';
	}

	return $self->nested(
		'[',
		( map { $self->quote($_) . ',' } @items ),
		'],',
	);
}

sub control_params {
	my $self   = shift;
	my @params = @_;

	# Trim params off the end if the Wx defaults are valid
	while ( @params >= 2 ) {
		my $value = pop @params;
		my $key   = pop @params;
		if ( $key eq 'style' ) {
			next unless $value;
		} elsif ( $key eq 'size' ) {
			next if $value eq 'Wx::wxDefaultSize';
		} elsif ( $key eq 'position' ) {
			next if $value eq 'Wx::wxDefaultPosition';
		} elsif ( $key eq 'id' ) {
			next if $value eq '-1';
		}

		# We want to keep these, and everything else before it
		push @params, $key, $value;
		last;
	}

	# Turn the remaining params into a list
	my @list = ();
	while ( @params ) {
		my $key   = shift @params;
		my $value = shift @params;
		if ( @params ) {
			push @list, "$value,";
		} else {
			push @list, $value;
		}
	}

	return @list;
}





######################################################################
# Support Methods

sub use_pragma {
	my $self  = shift;
	my $topic = shift;

	return [
		"use 5.008;",
		"use strict;",
		"use warnings;",
	]
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

sub wxsize {
	my $self   = shift;
	my $string = $self->size(shift);
	return $self->wx('wxDefaultSize') unless $string;
	$string =~ s/,/, /;
	return "[ $string ]";
}

sub size {
	my $self   = shift;
	my $string = shift;
	return '' unless defined $string;
	return '' if $string eq '-1,-1';
	return $string;
}

sub colour {
	my $self   = shift;
	my $string = shift;

	# Default colour
	unless ( length $string ) {
		return 'undef';
	}

	# Explicit colour
	if ( $string =~ /^\d/ ) {
		$string =~ s/,(\d)/, $1/g; # Space the numbers a bit
		return "Wx::Colour->new( $string )";
	}

	# System colour
	if ( $string =~ /^wx/ ) {
		return "Wx::SystemSettings::GetColour( Wx::$string )";
	}

	die "Invalid or unsupported colour '$string'";
}

sub font {
	my $self   = shift;
	my $string = shift;

	# Default font
	unless ( length $string ) {
		return 'Wx::wxNullFont';
	}

	# Generate a font from the overcompact FBP format.
	# It will probably look something like ",90,92,-1,70,0"
	my @font = split /,/, $string;
	if ( @font == 6 ) {
		my $point_size = $font[3];
		my $family     = $font[4];
		my $style      = $font[1];
		my $weight     = $font[2];
		my $underlined = $font[5];
		my $face_name  = $font[0];
		my $params     = join( ', ',
			$self->points($point_size),
			$family,
			$style,
			$weight,
			$underlined,
			$self->quote($face_name),
		);
		return "Wx::Font->new( $params )";
	}

	die "Invalid or unsupported font '$string'";
}

sub points {
	my $self = shift;
	my $size = shift;
	if ( $size and $size > 0 ) {
		return $size;
	}
	$self->wx('wxNORMAL_FONT') . '->GetPointSize';
}

sub bitmap {
	my $self   = shift;
	my $bitmap = shift;
	unless ( defined $bitmap ) {
		return $self->wx('wxNullBitmap');
	}

	### To be completed
	return $self->wx('wxNullBitmap');
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
