package Kephra;

# See end of file for docs
# -NI = not implemented or used, -DEP = depreciated

use 5.006;
use strict;

our $NAME       = 'Kephra';     # name of entire application
our $VERSION    = '0.3.3.17';   # program - version
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
use Kephra::App;                   # App start&exit, namespace 4 wx related things
use Kephra::App::ContextMenu;      # contextmenu manager
use Kephra::App::EditPanel;        #
use Kephra::App::EditPanel::Margin;#
use Kephra::App::EventList;        # 
use Kephra::App::Events;           # -DEP mouse, keyboard events, eventtable
use Kephra::App::MainToolBar;      # 
use Kephra::App::Menu;             # base menu builder
use Kephra::App::MenuBar;          # main menu
use Kephra::App::ToolBar;          # base toolbar builder
use Kephra::App::SearchBar;        # Toolbar for searching and navigation
use Kephra::App::StatusBar;        #
use Kephra::App::TabBar;           # API 2 Wx::Notebook, FileSelector
use Kephra::App::Window;           # API 2 Wx::Frame and more
use Kephra::App::CommandList;      #
use Kephra::Config;                # low level config manipulation
use Kephra::Config::File;          # API 2 ConfigParser: Config::General, YAML
use Kephra::Config::Global;        # API 4 config, general content level
use Kephra::Config::Interface;     #
use Kephra::Config::Tree;          #
use Kephra::Dialog;                # API 2 dialogs, submodules are loaded runtime
use Kephra::Document;              # document menu funktions
use Kephra::Document::Change;      # calls for changing current doc
use Kephra::Document::Internal;    # doc handling helper methods
use Kephra::Document::SyntaxMode;  # doc handling helper methods
use Kephra::Edit;                  # basic edit menu funktions
use Kephra::Edit::Changes;         # undo redo etc.
use Kephra::Edit::Comment;         # comment functions
use Kephra::Edit::Convert;         # convert functions
use Kephra::Edit::Format;          # formating functions
use Kephra::Edit::Goto;            # editpanel textcursor navigation
use Kephra::Edit::Search;          # search menu functions
use Kephra::Edit::Select;          # text selection
use Kephra::Edit::Bookmark;        # doc spanning bookmarks
use Kephra::File;                  # file menu funktions
use Kephra::File::IO;              # API 2 FS, read write files
use Kephra::File::Session;         # file session handling
use Kephra::Show;                  # -DEP display content: files, boxes

# internal modules / loaded when needed
#require Kephra::Config::Embedded; # build in emergency settings
#require Kephra::Dialog::Config;   # config dialog
#require Kephra::Dialog::Exit;     # select files to be saved while exit program
#require Kephra::Dialog::Info;     # info box
#require Kephra::Dialog::Keymap;   #
#require Kephra::Dialog::Search;   # find and replace dialog

# global data
our %app;           # ref to app parts and app data for GUI, Events, Parser
our %config;        # global settings, saved in /config/global/autosaved.conf
our %document;      # data of current documents, to be stored in session file
our %help;          # -NI locations of documentation files in current language
our %temp;          # global internal temp data
our %localisation;  # all localisation strings in your currently selected lang
our %syntaxmode;    # -NI


# Wx App Events 
sub OnInit {&Kephra::App::start}   # boot app: init core and load config files
sub quit   {&Kephra::App::exit }   # save files & settings as configured


sub user_config {
	$_[0] and $_[0] eq $NAME and shift;
	File::UserConfig->new(@_);
}

sub configdir {
	$_[0] and $_[0] eq $NAME and shift;
	File::UserConfig->configdir(@_);
}

1;

__END__

=pod

=head1 NAME

Kephra - A pure-Perl cross-platform CPAN-installable programmer's editor for 
         multiple languages, designed along Perl's Paradigms

=head1 DESCRIPTION

The Kephra.pm module itself serves as a class loader, configuration loader,
bootstrap and shutdown module, and provides some global variables.

=head1 TO DO

- Find Name 

- Write the DESCRIPTION :)

- Complete CPANification

- Lots and lots of other things

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Kephra>

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
