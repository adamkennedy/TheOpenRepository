package Kepher;

# See end of file for docs, -NI = not implemented, -DEP = depreciated

use 5.006;
use strict;

our $NAME       = 'Kepher';     # name of entire applikation
our $VERSION    = '0.3.3';      # program - version
our @ISA        = 'Wx::App';    # $NAME is a wx application

# used external modules (loaded at start)
use File::UserConfig;           # config dir manager
use Config::General;            # config file Parser
use YAML;                       # gui config file Parser

use Wx;                         # wxWidgets Framework Core
use Wx::STC;                    # Scintilla editor component
use Wx::DND;                    # Drag'n Drop & Clipboard support

# required external modules (loaded if needed in packages)
# require Hash::Merge;          # for config hash merging
# require Clone;                # Hash::Merge Dependency
# require Cwd;                  # for some Config::Settings
##require Perl::Tidy;           # -NI perl formating

# for adam                      # (use Scalar::Util 'weaken';)
#use PPI ();                    # For refactoring support
#use Params::Util ();           # Parameter checking
#use Class::Inspector ();       # Class checking

# used internal modules, parts of pce
use KEPHER::App;                   # App start&exit, namespace 4 wx related things
use KEPHER::App::ContextMenu;      # contextmenu manager
use KEPHER::App::EditPanel;        #
use KEPHER::App::EditPanel::Margin;#
use KEPHER::App::EventList;        # 
use KEPHER::App::Events;           # -DEP mouse, keyboard events, eventtable
use KEPHER::App::MainToolBar;      # 
use KEPHER::App::Menu;             # base menu builder
use KEPHER::App::MenuBar;          # main menu
use KEPHER::App::ToolBar;          # base toolbar builder
use KEPHER::App::SearchBar;        # Toolbar for searching and navigation
use KEPHER::App::StatusBar;        #
use KEPHER::App::TabBar;           # API 2 Wx::Notebook, FileSelector Notepad
use KEPHER::App::Window;           # API 2 Wx::Frame and more
use KEPHER::App::STC;              # -DEP scintilla controls
use KEPHER::App::CommandList;      #
use KEPHER::Config;                # low level config manipulation
use KEPHER::Config::File;          # API 2 ConfigParser Config::General
use KEPHER::Config::Global;        # API 4 config, general content level
use KEPHER::Config::Interface;     #
use KEPHER::Dialog;                # API 2 dialogs, submodules are loaded runtime
use KEPHER::Document;              # document menu funktions
use KEPHER::Document::Change;      # calls for changing current doc
use KEPHER::Document::Internal;    # doc handling helper methods
use KEPHER::Document::SyntaxMode;  # doc handling helper methods
use KEPHER::Edit;                  # basic edit menu funktions
use KEPHER::Edit::Comment;         # comment functions
use KEPHER::Edit::Convert;         # convert functions
use KEPHER::Edit::Format;          # formating functions
use KEPHER::Edit::Goto;            # editpanel textcursor navigation
use KEPHER::Edit::Search;          # search menu functions
use KEPHER::Edit::Select;          # text selection
use KEPHER::Edit::Bookmark;        # 
use KEPHER::File;                  # file menu funktions
use KEPHER::File::IO;              # API 2 FS, read write files
use KEPHER::File::Session;         # session handling
use KEPHER::Show;                  # -DEP display content: files, boxes

# internal modules / loaded when needed
#require KEPHER::Config::Embedded; # build in emergency settings
#require KEPHER::Dialog::Config;   # config dialog
#require KEPHER::Dialog::Exit;     # select files to be saved while exit program
#require KEPHER::Dialog::Info;     # info box
#require KEPHER::Dialog::Keymap;   #
#require KEPHER::Dialog::Search;   # find and replace dialog

# global data
our %app;           # ref to app parts and app data for GUI, Events, Parser
our %config;        # global settings, saved in /config/global/autosaved.conf
our %document;      # data of current documents, to be stored in session file
our %documentation; # -NI locations of documentation files in current language
our %internal;      # global internal temp data
our %localisation;  # all localisation strings in your currently selected lang
our %syntaxmode;    # -NI

# Wx App Events 
sub OnInit {&KEPHER::App::start}   # boot app: init core and load config files
sub quit   {&KEPHER::App::exit }   # save files & settings as configured


sub user_config {
	$_[0] and $_[0] eq 'PCE' and shift;
	File::UserConfig->new(@_);
}

sub configdir {
	$_[0] and $_[0] eq 'PCE' and shift;
	File::UserConfig->configdir(@_);
}

1;

__END__

=pod

=head1 NAME

Kepher - A pure-Perl cross-platform CPAN-installable programmer's editor

=head1 DESCRIPTION

The Kepher.pm module itself serves as a class loader, configuration loader,
bootstrap and shutdown module, and provides some global variables.

=head1 TO DO

- Write the DESCRIPTION :)

- Complete CPANification

- Lots and lots of other things

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Kepher>

For other issues, contact the author.

=head1 AUTHOR

Herbert Breunung E<lt>lichtkind@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 - 2006 Herbert Breunung. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the terms of the GNU GPL.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
