#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 226;
use Test::NoWarnings;
use Scalar::Util 'refaddr';
use File::Spec::Functions ':ALL';
use FBP ();

my $FILE = catfile( 't', 'data', 'simple.fbp' );
ok( -f $FILE, "Found test file '$FILE'" );





######################################################################
# Simple Tests

# Create the empty object
my $fbp = FBP->new;
isa_ok( $fbp, 'FBP' );

# Parse the file
my $ok = eval {
	$fbp->parse_file( $FILE );
};
is( $@, '', "Parsed '$FILE' without error" );
ok( $ok, '->parse_file returned true' );

# Check the project properties
my $project = $fbp->project;
isa_ok( $project, 'FBP::Project' );
is( $project->name, 'Simple', '->name ok' );
is( $project->relative_path, '1', '->relative_path ok' );
is( $project->internationalize, '1', '->internationalize ok' );

# Find a particular named dialog
my $dialog1 = $fbp->dialog('MyDialog1');
isa_ok( $dialog1, 'FBP::Dialog' );
my $form1 = $fbp->form('MyDialog1');
isa_ok( $dialog1, 'FBP::Dialog' );
is( refaddr($form1), refaddr($dialog1), 'Got the same thing with ->form and ->dialog' );
is( $dialog1->name,     'MyDialog1',  '->name ok'     );
is( $dialog1->subclass, '',           '->subclass ok' );
is( $dialog1->wxclass,  'Wx::Dialog', '->class ok'    );

# Repeat using the generic search
my $dialog2 = $fbp->find_first(
	isa  => 'FBP::Dialog',
	name => 'MyDialog1',
);
isa_ok( $dialog2, 'FBP::Dialog' );
is(
	$fbp->find_first( name => 'does_not_exists' ),
	undef,
	'->find_first(bad) returns undef',
);

# The search should work as well from children of the main object as well
my $dialog3 = $project->find_first( isa => 'FBP::Dialog' );
isa_ok( $dialog3, 'FBP::Dialog' );

# Multiple-search query equivalent
my @dialog4 = $project->find( isa => 'FBP::Dialog' );
is( scalar(@dialog4), 1, '->find(single) ok' );
isa_ok( $dialog4[0], 'FBP::Dialog' );

# Multiple-search query with multiple results
my @window = $project->find( isa => 'FBP::Window' );
is( scalar(@window), 44, '->find(multiple) ok' );
foreach ( @window ) {
	isa_ok( $_, 'FBP::Window' );
}

# Frame properties
my $frame1 = $fbp->form('MyFrame1');
isa_ok( $frame1, 'FBP::Frame' );
ok( $frame1->DOES('FBP::Form'), 'DOES FBP::Form' );
can_ok( $frame1, 'OnInitDialog' );

# Top level Panel properties
my $panel1 = $fbp->form('MyPanel1');
isa_ok( $panel1, 'FBP::FormPanel' );
isa_ok( $panel1, 'FBP::Panel' );
ok( $panel1->DOES('FBP::Form'), 'DOES FBP::Form' );

# Text properties
my $text = $fbp->find_first(
	isa => 'FBP::StaticText',
);
isa_ok( $text, 'FBP::StaticText' );
is( $text->id,         'wxID_ANY',       '->id ok'         );
is( $text->name,       'm_staticText1',  '->name ok'       );
is( $text->permission, 'protected',      '->permission ok' );
is( $text->subclass,   'My::Class;',     '->subclass ok'   );
is( $text->wxclass,    'My::Class',      '->class ok'      );
is( $text->wrap,       '-1',             '->wrap ok'       );
is(
	$text->label,
	'Michael "Killer" O\'Reilly <michael@localhost>',
	'->label ok',
);

# TextCtrl properties
my $textctrl = $fbp->find_first(
	isa => 'FBP::TextCtrl',
);
isa_ok( $textctrl, 'FBP::TextCtrl' );
is( $textctrl->value, 'This is also a test', '->value ok' );
is( $textctrl->maxlength, '50',        '->maxlength ok' );
is( $textctrl->fg,        '',          '->fg ok'        );
is( $textctrl->bg,        '255,128,0', '->bg ok'        );

# Button properties
my $button = $fbp->find_first(
	isa => 'FBP::Button',
);
isa_ok( $button, 'FBP::Button' );
is( $button->id,            'wxID_ANY',    '->id ok'            );
is( $button->name,          'm_button1',   '->name ok'          );
is( $button->label,         'MyButton',    '->label ok'         );
is( $button->default,       '1',           '->default ok'       );
is( $button->subclass,      '',            '->subclass ok'      );
is( $button->wxclass,       'Wx::Button',  '->wxclass ok'       );
is( $button->permission,    'protected',   '->permission ok'    );
is( $button->fg,            '',            '->fg ok'            );
is( $button->bg,            '',            '->bg ok'            );
is( $button->tooltip, 'This is a tooltip', '->tooltip ok'       );
is( $button->OnButtonClick, 'm_button1',   '->OnButtonClick ok' );

# ListCtrl properties
my $listctrl = $fbp->find_first(
	isa => 'FBP::ListCtrl',
);
isa_ok( $listctrl, 'FBP::ListCtrl' );
is( $listctrl->name, 'm_listCtrl1', '->name ok' );
is( $listctrl->minimum_size, '100,100', '->minimum_size ok' );
is( $listctrl->maximum_size, '200,200', '->maximum_size ok' );

# Choice box properties
my $choice = $fbp->find_first(
	isa => 'FBP::Choice',
);
isa_ok( $choice, 'FBP::Choice' );
is( $choice->id,      'wxID_ANY',  '->id ok'      );
is( $choice->name,    'm_choice1', '->name ok'    );
is( $choice->wxclass, 'Wx::Foo',   '->wxclass ok' );
is( scalar($choice->header), undef, '->header ok' );

# Combo properties
my $combo = $fbp->find_first(
	isa => 'FBP::ComboBox',
);
isa_ok( $combo, 'FBP::ComboBox' );
is( $combo->id,      'wxID_ANY',    '->id ok'      );
is( $combo->name,    'm_comboBox1', '->name ok'    );
is( $combo->value,   'Combo!',      '->value ok'   );
is( $combo->wxclass, 'Wx::Bar',     '->wxclass ok' );
is( scalar($combo->header), 'Wx::Bar', '->header ok' );
is(
	$combo->choices,
	'"one" "two" "a\'b" "c\\"d \\\\\\""',
	'->choices ok',
);
is( scalar($combo->items), 4, 'Scalar ->items ok' );
is_deeply(
	[ $combo->items ],
	[ 'one', 'two', "a'b", 'c"d \\"' ],
	'->items ok',
);

# Line properties
my $line = $fbp->find_first(
	isa => 'FBP::StaticLine',
);
isa_ok( $line, 'FBP::StaticLine' );
is( $line->id,           'wxID_ANY',                    '->id ok'           );
is( $line->name,         'm_staticline1',               '->name ok'         );
is( $line->enabled,      '1',                           '->enabled ok'      );
is( $line->pos,          '',                            '->pos ok'          );
is( $line->size,         '',                            '->size ok'         );
is( $line->style,        'wxLI_HORIZONTAL',             '->style ok'        );
is( $line->window_style, 'wxNO_BORDER',                 '->window_style ok' );
is( $line->styles,       'wxLI_HORIZONTAL|wxNO_BORDER', '->styles ok'       );

# Sizer properties
my $sizer = $fbp->find_first(
	isa => 'FBP::Sizer',
);
isa_ok( $sizer, 'FBP::Sizer' );
is( $sizer->name,       'bSizer1',      '->name ok'       );
is( $sizer->orient,     'wxHORIZONTAL', '->orient ok'     );
is( $sizer->permission, 'none',         '->permission ok' );

# Listbook properties
my $listbook = $fbp->find_first(
	isa => 'FBP::Listbook',
);
isa_ok( $listbook, 'FBP::Listbook' );
is( $listbook->style, 'wxLB_DEFAULT', '->style ok' );

# SplitterWindow properties
my $splitterwindow = $fbp->find_first(
	isa => 'FBP::SplitterWindow',
);
isa_ok( $splitterwindow, 'FBP::SplitterWindow' );
is( $splitterwindow->style, 'wxSP_3D', '->style ok' );
is( $splitterwindow->splitmode, 'wxSPLIT_VERTICAL', '->splitmode ok' );
is( $splitterwindow->sashpos, '0', '->sashpos ok' );
is( $splitterwindow->sashsize, '-1', '->sashsize ok' );
is( $splitterwindow->sashgravity, '0.0', '->sashgravity ok' );
is( $splitterwindow->min_pane_size, '0', '->min_pane_size ok' );
is( $splitterwindow->permission, 'protected', '->permission ok' );

# SplitterItem properties
my $splitteritem = $fbp->find_first(
	isa => 'FBP::SplitterItem',
);
isa_ok( $splitteritem, 'FBP::SplitterItem' );

# ColourPickerCtrl properties
my @colourpickerctrl = $fbp->find(
	isa => 'FBP::ColourPickerCtrl',
);
isa_ok( $colourpickerctrl[0], 'FBP::ColourPickerCtrl' );
isa_ok( $colourpickerctrl[1], 'FBP::ColourPickerCtrl' );
is( $colourpickerctrl[0]->style, 'wxCLRP_DEFAULT_STYLE', '->style ok' );
is( $colourpickerctrl[0]->colour, '255,0,0', '->colour ok' );
is( $colourpickerctrl[1]->colour, 'wxSYS_COLOUR_INFOBK', '->colour ok' );

# Test support for hidden
is( $colourpickerctrl[0]->hidden, 0, '->hidden false for visible element' );
is( $colourpickerctrl[1]->hidden, 1, '->hidden true for hidden element' );

# FontPickerCtrl properties
my $fontpickerctrl = $fbp->find_first(
	isa => 'FBP::FontPickerCtrl',
);
isa_ok( $fontpickerctrl, 'FBP::FontPickerCtrl' );
is( $fontpickerctrl->value, 'Times New Roman,90,92,10,74,0', '->value ok' );
is( $fontpickerctrl->max_point_size, 100, '->max_point_size ok' );
is( $fontpickerctrl->style, 'wxFNTP_DEFAULT_STYLE', '->stlye ok' );

# FilePickerCtrl properties
my $filepickerctrl = $fbp->find_first(
	isa => 'FBP::FilePickerCtrl',
);
isa_ok( $filepickerctrl, 'FBP::FilePickerCtrl' );
is( $filepickerctrl->value, '', '->value ok' );
is( $filepickerctrl->message, 'Select a file', '->message ok' );
is( $filepickerctrl->wildcard, '*.*', '->wildcard ok' );
is( $filepickerctrl->style, 'wxFLP_DEFAULT_STYLE', '->stlye ok' );

# DirPickerCtrl properties
my $dirpickerctrl = $fbp->find_first(
	isa => 'FBP::DirPickerCtrl',
);
isa_ok( $dirpickerctrl, 'FBP::DirPickerCtrl' );
is( $dirpickerctrl->value, '', '->value ok' );
is( $dirpickerctrl->message, 'Select a folder', '->message ok' );
is( $dirpickerctrl->style, 'wxDIRP_DEFAULT_STYLE', '->style ok' );

# SpinCtrl properties
my $spinctrl = $fbp->find_first(
	isa => 'FBP::SpinCtrl',
);
isa_ok( $spinctrl, 'FBP::SpinCtrl' );
is( $spinctrl->value,   '',   '->value ok'   );
is( $spinctrl->min,     '0',  '->min ok'     );
is( $spinctrl->max,     '10', '->max ok'     );
is( $spinctrl->initial, '5',  '->initial ok' );
is( $spinctrl->style, 'wxSP_ARROW_KEYS', '->style ok' );

# CustomControl properties
my $custom = $fbp->find_first(
	isa => 'FBP::CustomControl',
);
isa_ok( $custom, 'FBP::CustomControl' );
is( $custom->class, 'My::Class' );
is( $custom->wxclass, 'My::Class' );
is( $custom->include, 'My::Module' );
is( $custom->header, 'My::Module' );

# RadioBox properties
my $radiobox = $fbp->find_first(
	isa => 'FBP::RadioBox',
);
isa_ok( $radiobox, 'FBP::RadioBox' );
is( $radiobox->label, 'Radio Gaga', '->label ok' );
is( $radiobox->choices, '"One" "Two" "Three" "Four"', '->choices ok' );
is( $radiobox->selection, 2, '->selection ok' );
is( $radiobox->majorDimension, 2, '->majorDimension ok' );
is( $radiobox->style, 'wxRA_SPECIFY_COLS', '->style ok' );

# HyperLink properties
my $hyperlink = $fbp->find_first(
	isa => 'FBP::HyperLink',
);
isa_ok( $hyperlink, 'FBP::HyperLink' );
is( $hyperlink->name, 'm_hyperlink1', '->name ok' );
is( $hyperlink->label, 'wxFormBuilder Website', '->label ok' );
is( $hyperlink->url, 'http://www.wxformbuilder.org', '->url ok' );
is( $hyperlink->normal_color, 'wxSYS_COLOUR_WINDOWTEXT', '->normal_color ok' );

# Gauge properties
my $gauge = $fbp->find_first(
	isa => 'FBP::Gauge',
);
isa_ok( $gauge, 'FBP::Gauge' );
is( $gauge->name, 'm_gauge1', '->name ok' );
is( $gauge->value, 80, '->value ok' );
is( $gauge->range, 100, '->range ok' );

# SearchCtrl properties
my $searchctrl = $fbp->find_first(
	isa => 'FBP::SearchCtrl',
);
isa_ok( $searchctrl, 'FBP::SearchCtrl' );
is( $searchctrl->value, 'A search', '->value ok' );
is( $searchctrl->search_button, 1, '->search_button ok' );
is( $searchctrl->cancel_button, 0, '->cancel_button ok' );

# StatusBar properties
my $statusbar = $fbp->find_first(
	isa => 'FBP::StatusBar',
);
isa_ok( $statusbar, 'FBP::StatusBar' );
is( $statusbar->name, 'm_statusBar1', '->name ok' );
is( $statusbar->fields, 2, '->fields ok' );

# ToolBar properties
my $toolbar = $fbp->find_first(
	isa => 'FBP::ToolBar',
);
isa_ok( $toolbar, 'FBP::ToolBar' );
is( $toolbar->name, 'm_toolBar1', '->name ok' );
is( $toolbar->packing, 2, '->packing ok' );
is( $toolbar->separation, 5, '->separation ok' );
is( $toolbar->bitmapsize, '', '->bitmapsize ok' );
is( $toolbar->margins, '', '->margins ok' );
is( $toolbar->style, 'wxTB_HORIZONTAL', '->style ok' );

# Tool properties
my $tool = $fbp->find_first(
	isa => 'FBP::Tool',
);
isa_ok( $tool, 'FBP::Tool' );
is( $tool->name, 'm_tool1', '->name ok' );
is( $tool->label, 'tool', '->label ok' );
is( $tool->bitmap, '', '->bitmap ok' );
is( $tool->kind, 'wxITEM_NORMAL', '->kind ok' );
is( $tool->tooltip, 'Tool 1 tooltip', '->tooltip ok' );
is( $tool->statusbar, 'Tool 1 status bar', '->statusbar ok' );

# ToolSeparator properties
my $toolseparator = $fbp->find_first(
	isa => 'FBP::ToolSeparator',
);
isa_ok( $toolseparator, 'FBP::ToolSeparator' );
is( $toolseparator->permission, 'none', '->permission ok' );

# MenuBar properties
my $menubar = $fbp->find_first(
	isa => 'FBP::MenuBar',
);
isa_ok( $menubar, 'FBP::MenuBar' );
is( $menubar->name, 'm_menubar1', '->name ok' );
is( $menubar->label, 'MyMenuBar', '->label ok' );
is( $menubar->style, 'wxMB_DOCKABLE', '->style ok' );

# Menu properties
my $menu = $fbp->find_first(
	isa => 'FBP::Menu',
);
isa_ok( $menu, 'FBP::Menu' );
is( $menu->name, 'm_menu1', '->name ok' );
is( $menu->label, 'File', '->label ok' );

# MenuItem properties
my $menuitem = $fbp->find_first(
	isa => 'FBP::MenuItem',
);
isa_ok( $menuitem, 'FBP::MenuItem' );
is( $menuitem->name, 'm_menuItem1', '->name ok' );
is( $menuitem->label, 'This', '->label ok' );
is( $menuitem->shortcut, '', '->shortcut ok' );
is( $menuitem->help, 'This is help text', '->help ok' );
is( $menuitem->bitmap, '; Load From File', '->bitmap ok' );
is( $menuitem->unchecked_bitmap, '', '->unchecked_bitmap ok' );
is( $menuitem->checked, 0, '->checked ok' );
is( $menuitem->enabled, 1, '->enabled ok' );
is( $menuitem->kind, 'wxITEM_NORMAL', '->kind ok' );

# MenuSeparator properties
my $menuseparator = $fbp->find_first(
	isa => 'FBP::MenuSeparator',
);
isa_ok( $menuseparator, 'FBP::MenuSeparator' );
is( $menuseparator->name, 'm_separator1', '->name ok' );
