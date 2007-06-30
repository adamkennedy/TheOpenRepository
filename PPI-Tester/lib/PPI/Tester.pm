package PPI::Tester;

# The PPI Tester application

use 5.005;
use strict;

# The very first version
use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.11';
}

# Load in the PPI classes
use PPI ();
use PPI::Dumper ();

# Load the wxWindows library
use Wx;

sub new {
	PPI::Tester::App->new;
}





#####################################################################
package PPI::Tester::App;

# The main application class

use base 'Wx::App';

use constant APPLICATION_NAME => "PPI Tester $PPI::Tester::VERSION - PPI $PPI::VERSION";

sub OnInit {
	my $self = shift;
	$self->SetAppName(APPLICATION_NAME);

	# Create the one and only frame
	my $Frame = PPI::Tester::Window->new(
		undef,               # Parent Window
		-1,                  # Id
		APPLICATION_NAME,    # Title
		[-1, -1],             # Default size
		[-1, -1],             # Default position
		);
	$Frame->CentreOnScreen;

	# Set it as the top window and show it
	$self->SetTopWindow($Frame);
	$Frame->Show(1);

	# Do an initial parse
	$Frame->debug;

	1;
}





#####################################################################
package PPI::Tester::Window;

# The main window for the application

use base 'Wx::Frame';
use Wx        qw{:everything};
use Wx        qw{wxHIDE_READONLY};
use Wx::Event 'EVT_TOOL',
              'EVT_TEXT',
              'EVT_CHECKBOX';

# wxWindowIDs
use constant CMD_CLEAR        => 1;
use constant CMD_LOAD         => 2;
use constant CMD_DEBUG        => 3;
use constant CODE_BOX         => 4;
use constant STRIP_WHITESPACE => 5;

my $initial_code = 'my $code = "here";';

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	# Use the pretty Wx icon
	$self->SetIcon( Wx::GetWxPerlIcon() );

	# Create and populate the toolbar
	$self->CreateToolBar( wxNO_BORDER | wxTB_HORIZONTAL | wxTB_TEXT | wxTB_NOICONS );
	$self->GetToolBar->AddTool( CMD_CLEAR, 'Clear', wxNullBitmap );
	$self->GetToolBar->AddTool( CMD_LOAD,  'Load',  wxNullBitmap );
	# $self->GetToolBar->AddSeparator;
	# $self->GetToolBar->AddTool( CMD_DEBUG, 'Debug', wxNullBitmap );
	$self->GetToolBar->Realize;

	# Bind the events for the toolbar
	EVT_TOOL( $self, CMD_CLEAR, \&clear );
	EVT_TOOL( $self, CMD_LOAD,  \&load  );
	# EVT_TOOL( $self, CMD_DEBUG, \&debug );

	# Create the split window with the two panels in it
	my $Splitter = Wx::SplitterWindow->new(
		$self,             # Parent window
		-1,                # Default ID
		wxDefaultPosition, # Normal position
		wxDefaultSize,     # Automatic size
		);
	my $Left     = Wx::Panel->new( $Splitter, -1 );
	my $Right    = Wx::Panel->new( $Splitter, -1 );
	$Splitter->SplitVertically( $Left, $Right, 0 );
	$Left->SetSizer(  Wx::BoxSizer->new(wxVERTICAL) );
	$Right->SetSizer( Wx::BoxSizer->new(wxHORIZONTAL) );

	# Create the options checkboxes
	$Left->GetSizer->Add(
		$self->{Option}->{StripWhitespace} = Wx::CheckBox->new(
			$Left,               # Parent panel
			STRIP_WHITESPACE,    # ID
			'Ignore Whitespace', # Label
			wxDefaultPosition,   # Automatic position
			wxDefaultSize,       # Default size
			),
		0,        # Expands vertically
		wxALL,    # Border on all sides
		5,        # Small border area
		);
	$self->{Option}->{StripWhitespace}->SetValue(1);

	# Create the resizer code area on the left side
	$Left->GetSizer->Add(
		$self->{Code} = Wx::TextCtrl->new(
			$Left,                # Parent panel,
			CODE_BOX,             # ID
			$initial_code,        # Help new users get a clue
			wxDefaultPosition,    # Normal position
			wxDefaultSize,        # Minimum size
			wxTE_PROCESS_TAB      # We keep tab presses (not working?)
			| wxTE_MULTILINE,     # Textarea
			),
		1,        # Expands vertically
		wxEXPAND, # Expands horizontally
		);
	

	# Create the resizing output textbox for the right side
	$Right->GetSizer->Add(
		$self->{Output} = Wx::TextCtrl->new(
			$Right,                         # Parent panel,
			-1,                             # Default ID
			'',                             # Help new users get a clue
			wxDefaultPosition,              # Normal position
			wxDefaultSize,                  # Minimum size
			wxTE_READONLY                   # Output you can't change
			| wxTE_MULTILINE                # Textarea
			| wxHSCROLL,
			),
		1,        # Expands horizontally
		wxEXPAND, # Expands vertically
		);
	$self->{Output}->Enable(1);

	# Set the initial focus
	$self->{Code}->SetFocus;
	$self->{Code}->SetInsertionPointEnd;

	# Enable the sizers
	$Left->SetAutoLayout(1);
	$Right->SetAutoLayout(1);

	# When the user does just about anything, regenerate
	EVT_TEXT( $self, CODE_BOX, \&debug );
	EVT_CHECKBOX( $self, STRIP_WHITESPACE, \&debug);

	# Create the lexing and debugging objects
	$self->{Lexer} = PPI::Lexer->new;

	$self;
}

# Clear the two test areas
sub clear {
	my $self = shift;
	$self->{Code}->Clear;
	$self->{Output}->Clear;
	1;
}

# Load a file
sub load {
	my $self  = shift;
	my $event = shift;

	# Create the file selection dialog
	my $Dialog = Wx::FileDialog->new(
		$self,           # Parent window
		"Select a file", # Message to show on the dialog
		"",              # The default directory
		"",              # The default filename

		# Wildcard. Long and complicated, but very comprehensive
		"Modules(*.pm)|*.pm|perl header(.*ph)|*.ph|*.cgi|*.cgi|perl programs (*.pl)|*.pl|test files (*.t)|*.t|AutoSplit (*.al)|All files (*.*)|*.*",

		# The "Open as Read-Only" means nothing to us (I think)
		wxOPEN,
		);

	if ( $Dialog->ShowModal == wxID_CANCEL ) {
		# Do nothing if they cancel
	} else {
		my $file = $Dialog->GetPath;
		if ( open INFILE, $file ) {
			# Read the file
			binmode INFILE;
			my $code = join '', <INFILE>;

			# Set the code in the text control
			$self->{Code}->SetInsertionPoint(0);
			$self->{Code}->SetValue( $code );
		} else {
			Wx::LogMessage( "Couldn't open $file : $! " );
		}
	}

	$Dialog->Destroy;
}

# Do a processing run
sub debug {
	my $self   = shift;
	my $source = $self->{Code}->GetValue
		or return $self->_error("Nothing to parse");

	# Parse and dump the content
	my $Document = $self->{Lexer}->lex_source( $source )
		or return $self->_error("Error during lex");

	# Does the user want to strip whitespace?
	if ( $self->{Option}->{StripWhitespace}->IsChecked ) {
		$Document->prune('PPI::Token::Whitespace');
	}

	# Dump the Document to the dump screen
	my $Dumper = PPI::Dumper->new( $Document, indent => 2 )
		or return $self->_error("Failed to created PPI::Document dumper");
	my $output = $Dumper->string
		or return $self->_error("Dumper failed to generate output");
	$self->{Output}->SetValue( $output );

	# Keep the focus on the code
	$self->{Code}->SetFocus;

	1;
}

sub _error {
	my $self    = shift;
	my $message = join "\n", @_;
	$self->{Output}->SetValue( $message );
	1;
}

1;

=pod

=head1 NAME

PPI::Tester - A wxPerl-based interactive PPI debugger/tester

=head1 DESCRIPTION

This package implements a wxWindows desktop application which provides the
ability to interactively test the PPI perl parser.

The C<PPI::Tester> module implements the application, but is itself of no
use to the user. The launcher for the application 'ppitester' is installed
with this module, and can be launched by simply typing the following from
the command line.

  ppitester

When launched, the application consists of two vertical panels. The left
panel is where you should type in your code sample. As the left hand panel
is changed, a PPI::Dumper output is continuously updated in the right
hand panel.

There is a toolbar at the top of the application with two icon buttons,
currently without icons. The first toolbar button clears the panels, the
second is a placeholder for loading in code from a file, and is not yet
implemented. ( It's early days yet for this application ).

=head1 TO DO

- There are no icons on the toolbar buttons

- An option is needed to save both the left and right panels into
  a matching pair of files, compatible with the lexer testing script.

=head1 SUPPORT

To file a bug against this module, in a way you can keep track of, see the CPAN
bug tracking system.

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PPI-Tester>

For general comments, contact the maintainer.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Load function originally by 'DH' (email suppressed)

=head1 SEE ALSO

L<PPI::Manual>, L<http://sf.net/parseperl>

=head1 COPYRIGHT

Copyright 2004 - 2006 Adam Kennedy.

Some parts copyright 2004 'DH'.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
