package Kepher;

# See end of file for docs, -NI = not implemented, -DEP = depreciated

use 5.006;
use strict;

our $NAME       = 'Kephra';     # name of entire application
our $VERSION    = '0.3.3.3';    # program - version
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
use Kepher::App;                   # App start&exit, namespace 4 wx related things
use Kepher::App::ContextMenu;      # contextmenu manager
use Kepher::App::EditPanel;        #
use Kepher::App::EditPanel::Margin;#
use Kepher::App::EventList;        # 
use Kepher::App::Events;           # -DEP mouse, keyboard events, eventtable
use Kepher::App::MainToolBar;      # 
use Kepher::App::Menu;             # base menu builder
use Kepher::App::MenuBar;          # main menu
use Kepher::App::ToolBar;          # base toolbar builder
use Kepher::App::SearchBar;        # Toolbar for searching and navigation
use Kepher::App::StatusBar;        #
use Kepher::App::TabBar;           # API 2 Wx::Notebook, FileSelector Notepad
use Kepher::App::Window;           # API 2 Wx::Frame and more
use Kepher::App::CommandList;      #
use Kepher::Config;                # low level config manipulation
use Kepher::Config::File;          # API 2 ConfigParser Config::General
use Kepher::Config::Global;        # API 4 config, general content level
use Kepher::Config::Interface;     #
use Kepher::Dialog;                # API 2 dialogs, submodules are loaded runtime
use Kepher::Document;              # document menu funktions
use Kepher::Document::Change;      # calls for changing current doc
use Kepher::Document::Internal;    # doc handling helper methods
use Kepher::Document::SyntaxMode;  # doc handling helper methods
use Kepher::Edit;                  # basic edit menu funktions
use Kepher::Edit::Comment;         # comment functions
use Kepher::Edit::Convert;         # convert functions
use Kepher::Edit::Format;          # formating functions
use Kepher::Edit::Goto;            # editpanel textcursor navigation
use Kepher::Edit::Search;          # search menu functions
use Kepher::Edit::Select;          # text selection
use Kepher::Edit::Bookmark;        # 
use Kepher::File;                  # file menu funktions
use Kepher::File::IO;              # API 2 FS, read write files
use Kepher::File::Session;         # session handling
use Kepher::Show;                  # -DEP display content: files, boxes

# internal modules / loaded when needed
#require Kepher::Config::Embedded; # build in emergency settings
#require Kepher::Dialog::Config;   # config dialog
#require Kepher::Dialog::Exit;     # select files to be saved while exit program
#require Kepher::Dialog::Info;     # info box
#require Kepher::Dialog::Keymap;   #
#require Kepher::Dialog::Search;   # find and replace dialog

# global data
our %app;           # ref to app parts and app data for GUI, Events, Parser
our %config;        # global settings, saved in /config/global/autosaved.conf
our %document;      # data of current documents, to be stored in session file
our %documentation; # -NI locations of documentation files in current language
our %internal;      # global internal temp data
our %localisation;  # all localisation strings in your currently selected lang
our %syntaxmode;    # -NI

# Wx App Events 
sub OnInit {&Kepher::App::start}   # boot app: init core and load config files
sub quit   {&Kepher::App::exit }   # save files & settings as configured


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

Kepher - A pure-Perl cross-platform CPAN-installable programmer's editor for 
         multiple languages, designed along Perl's Paradigms

=head1 DESCRIPTION

The Kepher.pm module itself serves as a class loader, configuration loader,
bootstrap and shutdown module, and provides some global variables.

=head1 TO DO

- Find Name 

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
