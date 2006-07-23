package PCE;     # KPR

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
use PCE::App;                   # App start&exit, namespace 4 wx related things
use PCE::App::ContextMenu;      # contextmenu manager
use PCE::App::EditPanel;        #
use PCE::App::EditPanel::Margin;#
use PCE::App::EventList;        # 
use PCE::App::Events;           # -DEP mouse, keyboard events, eventtable
use PCE::App::MainToolBar;      # 
use PCE::App::Menu;             # base menu builder
use PCE::App::MenuBar;          # main menu
use PCE::App::ToolBar;          # base toolbar builder
use PCE::App::SearchBar;        # Toolbar for searching and navigation
use PCE::App::StatusBar;        #
use PCE::App::TabBar;           # API 2 Wx::Notebook, FileSelector Notepad
use PCE::App::Window;           # API 2 Wx::Frame and more
use PCE::App::STC;              # -DEP scintilla controls
use PCE::App::CommandList;      #
use PCE::Config;                # low level config manipulation
use PCE::Config::File;          # API 2 ConfigParser Config::General
use PCE::Config::Global;        # API 4 config, general content level
use PCE::Config::Interface;     #
use PCE::Dialog;                # API 2 dialogs, submodules are loaded runtime
use PCE::Document;              # document menu funktions
use PCE::Document::Change;      # calls for changing current doc
use PCE::Document::Internal;    # doc handling helper methods
use PCE::Document::SyntaxMode;  # doc handling helper methods
use PCE::Edit;                  # basic edit menu funktions
use PCE::Edit::Comment;         # comment functions
use PCE::Edit::Convert;         # convert functions
use PCE::Edit::Format;          # formating functions
use PCE::Edit::Goto;            # editpanel textcursor navigation
use PCE::Edit::Search;          # search menu functions
use PCE::Edit::Select;          # text selection
use PCE::Edit::Bookmark;        # 
use PCE::File;                  # file menu funktions
use PCE::File::IO;              # API 2 FS, read write files
use PCE::File::Session;         # session handling
use PCE::Show;                  # -DEP display content: files, boxes

# internal modules / loaded when needed
#require PCE::Config::Embedded; # build in emergency settings
#require PCE::Dialog::Config;   # config dialog
#require PCE::Dialog::Exit;     # select files to be saved while exit program
#require PCE::Dialog::Info;     # info box
#require PCE::Dialog::Keymap;   #
#require PCE::Dialog::Search;   # find and replace dialog

# global data
our %app;           # ref to app parts and app data for GUI, Events, Parser
our %config;        # global settings, saved in /config/global/autosaved.conf
our %document;      # data of current documents, to be stored in session file
our %documentation; # -NI locations of documentation files in current language
our %internal;      # global internal temp data
our %localisation;  # all localisation strings in your currently selected lang
our %syntaxmode;    # -NI

# Wx App Events 
sub OnInit {&PCE::App::start}   # boot app: init core and load config files
sub quit   {&PCE::App::exit }   # save files & settings as configured


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

PCE - The PCE Perl Editor, a pure perl cross-platform editor

=head1 DESCRIPTION

PCE is ...

The PCE module itself serves as a class loader, configuration loader,
bootstrap and shutdown module, and provides some global variables.

=head1 TO DO

- Write the DESCRIPTION :)

- Complete CPANification

- Lots and lots of other things

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PCE>

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
