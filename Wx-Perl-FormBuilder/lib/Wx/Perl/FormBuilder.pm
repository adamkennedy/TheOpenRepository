package Wx::Perl::FormBuilder;

=pod

=head1 NAME

Wx::Perl::FormBuilder - Generate Perl GUI code from wxFormBuilder .fbp files

=head1 SYNOPSIS

  my $generator = Wx::Perl::FormBuilder->new(
      dialog => $fbp_object->dialog('MyDialog')
  );

=head1 DESCRIPTION

TO BE COMPLETED

=cut

use 5.008005;
use strict;
use warnings;
use Moose 1.05;
use FBP   0.02 ();

our $VERSION = '0.01';

has project => (
	is       => 'ro',
	isa      => 'FBP::Project',
	required => 1,
);





######################################################################
# Button Generators

sub button_create {
	my $self     = shift;
	my $button   = shift;
	my $lexical  = $self->object_lexical($button) ? 'my ' : '';
	my $variable = $self->object_variable($button);
	my $id       = $self->wx($button->id);
	my $label    = $self->object_label($button);
	my @lines  = (
		"$lexical$variable = Wx::Button->new(",
		"\t\$self,",
		"\t$id,",
		"\t$label,",
		");",
	);
	if ( $button->default ) {
		push @lines, "$variable->SetDefault;";
	}
	unless ( $button->enabled ) {
		push @lines, "$variable->Disable;";
	}
	if ( $button->OnButtonClick ) {
		my $method = $button->OnButtonClick;
		push @lines, (
			"",
			"Wx::Event::EVT_BUTTON(",
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





######################################################################
# String Fragment Generators

my %OBJECT_UNLEXICAL = (
	'FBP::Button' => 1,
);

sub object_lexical {
	$OBJECT_UNLEXICAL{ref $_[1]} ? 0 : 1;
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
	my $string = "'" . $object->label . "'";
	if ( $self->i18n ) {
		$string = "Wx::gettext($string)";
	}
	return $string;
}





######################################################################
# Support Methods

sub i18n {
	shift->project->internationalize
}

sub wx {
	my $self   = shift;
	my $string = shift;
	if ( $string eq 'wxID_ANY' ) {
		return -1;
	}
	$string =~ s/\bwx/Wx::wx/g;
	return $string;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Wx-Perl-FormBuilder>

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
