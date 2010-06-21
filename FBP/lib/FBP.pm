package FBP;

=pod

=head1 NAME

FBP - Parser and Object Model for wxFormBuilder Project Files (.fpb files)

=head1 SYNOPSIS

  my $object = FBP->new;
  
  $object->parse_file( 'MyProject.fbp' );

=head1 DESCRIPTION

wxFormBuilder is currently the best and most sophisticated program for
designing wxWidgets dialogs and generating code from these designs.

However wxFormBuilder does not currently support the generation of Perl code.
And so if we are to produce Perl code for the designs it creates, the code
generation must be done independantly.

B<FBP> is a SAX-based parser and object model for the XML project files that
are saved by wxFormBuilder. While it does itself the creation of generated
Perl code, it should serve as a common base for anyone who wishes to produce
a code generator for these files.

B<NOTE: Documentation is limited as this module is in active development>

=head1 METHODS

=head2 new

  my $fbp = PBP->new;

The C<new> constructor takes no arguments and creates a new parser/model object.

=cut

use 5.008005;
use Moose        1.05;
use Params::Util 1.00 ();
use IO::File     1.14 ();
use XML::SAX     0.96 ();
use FBP::Parser       ();
use FBP::Project      ();
use FBP::Dialog       ();
use FBP::BoxSizer     ();
use FBP::Button       ();
use FBP::SizerItem    ();
use FBP::StaticText   ();
use FBP::StaticLine   ();

our $VERSION = '0.02';

has children => (
	is      => 'rw',
	isa     => "ArrayRef[FBP::Object]",
	default => sub { [ ] },
);





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

=pod

=head2 find_first

  my $dialog = $object->find_first(
      isa  => 'FBP::Dialog',
      name => 'MyDialog1',
  );

The C<find_first> method implements a generic depth-first search of the object
model. It takes a series of condition pairs that are used in the provided order
(allowing the caller to tune the way in which the filter is done).

Each pair is treated as a method + value set. First, the object is checked to
ensure it has that method, and then the method output is string-matched to the
output of the method via C<$object-E<gt>$method() eq $value>.

The special condition "isa" is applied as C<$object-E<gt>isa($value)> instead.

Returns the first object located that matches the provided criteria,
or C<undef> if nothing in the object model matches the conditions.

=cut

sub find_first {
	my $self  = shift;
	my @where = @_;
	my @queue = @{ $self->children };
	while ( @queue ) {
		my $object = shift @queue;

		# First add any children to the queue so that we
		# will process the model in depth first order.
		my $children = $object->children;
		unshift @queue, @$children if $children;

		# Filter to see if we want it
		my $i = 0;
		while ( my $method = $where[$i] ) {
			if ( $method eq 'isa' ) {
				last unless $object->isa($where[$i + 1]);
			} else {
				last unless $object->can($method);
				my $value = $object->$method();
				unless ( defined $value and $value eq $where[$i + 1] ) {
					last;
				}
			}
			$i += 2;
		}

		# If we hit the final $i += 2 we have found a match
		unless ( defined $where[$i] ) {
			return $object;
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
