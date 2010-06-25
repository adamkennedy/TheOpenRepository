package FBP;

=pod

=head1 NAME

FBP - Parser and Object Model for wxFormBuilder Project Files (.fpb files)

=head1 SYNOPSIS

  my $object = FBP->new;
  
  $object->parse_file( 'MyProject.fbp' );

=head1 DESCRIPTION

B<NOTE: Documentation is limited as this module is in active development>

wxFormBuilder is currently the best and most sophisticated program for
designing wxWidgets dialogs, and generating the code for these designs.

However, wxFormBuilder does not currently support the generation of Perl code.
If we are to produce Perl code for the designs it creates, the code generation
must be done independantly, outside of wxFormBuilder itself.

B<FBP> is a SAX-based parser and object model for the XML project files that
are created by wxFormBuilder. While it does B<NOT> do the creation of Perl code
itself, it should serve as a solid base for anyone who wishes to produce a code
generator for these saved files.

=head1 METHODS

=head2 new

  my $fbp = PBP->new;

The C<new> constructor takes no arguments and creates a new parser/model object.

=cut

use 5.008005;
use Mouse        0.61;
use Params::Util 1.00 ();
use IO::File     1.14 ();
use XML::SAX     0.96 ();
use FBP::Parser       ();
use FBP::Project      ();
use FBP::Dialog       ();
use FBP::BoxSizer     ();
use FBP::Button       ();
use FBP::CheckBox     ();
use FBP::ComboBox     ();
use FBP::HtmlWindow   ();
use FBP::ListCtrl     ();
use FBP::SizerItem    ();
use FBP::Spacer       ();
use FBP::StaticText   ();
use FBP::StaticLine   ();

our $VERSION = '0.05';

extends 'FBP::Object';
with    'FBP::Children';





######################################################################
# Search Methods

=pod

=head2 dialog

  my $dialog = $fbp->dialog('MyDialog1');

Convience method which finds and returns the root L<FBP::Dialog> object
for a specific named dialog box in the object model.

=cut

sub dialog {
	my $self = shift;
	my $name = shift;

	# Scan downwards under the project to find it
	my $project = $self->children->[0];
	unless ( Params::Util::_INSTANCE($project, 'FBP::Project') ) {
		return undef;
	}

	foreach my $dialog ( $project->dialogs ) {
		if ( $dialog->name and $dialog->name eq $name ) {
			return $dialog;
		}
	}

	return undef;
}





######################################################################
# Parsing Code

=pod

  my $ok = $fbp->parse_file( 'foo/bar.fbp' );

The C<parse_file> method takes a named fbp project file, and parses it to
produce an object model.

Returns true if the parsing run succeeds, or throws an exception on error.

=cut

sub parse_file {
	my $self = shift;
	my $file = shift;
	unless ( -f $file and -r $file ) {
		die("Missing or unreadable file '$file'");
	}

	# Open the file
	my $fh = IO::File->new( $file );
	unless ( $fh ) {
		die("Failed to open file '$file'");
	}

	# Create the parser
	my $handler = FBP::Parser->new($self);
	my $parser  = XML::SAX::ParserFactory->parser(
		Handler => $handler,
	);

	# Parse the file
	eval {
		$parser->parse_file( $fh );
	};
	if ( $@ ) {
		die("Error while parsing '$file': $@");
	}

	return 1;
}

sub add_object {
	my $self = shift;
	unless ( Params::Util::_INSTANCE($_[0], 'FBP::Object') ) {
		die("Can only add a 'FBP::Object' object");
	}
	my $objects = $self->children;
	push @$objects, shift;
	return 1;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FBP>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 - 2010 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
