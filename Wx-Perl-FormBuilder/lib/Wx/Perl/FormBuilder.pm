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

sub dialog_super {
	my $self     = shift;
	my $dialog   = shift;
	my $id       = $self->wx($dialog->id);
	my $label    = $self->object_label($dialog);
	my $position = $self->object_position($dialog);
	my $size     = $self->object_size($dialog);
	my $style    = $self->wx( $dialog->style || 'wxDEFAULT_DIALOG_STYLE' );
	my @lines    = (
		"my \$self = \$class->SUPER::new(",
		"\t\$parent,",
		"\t$id,",
		"\t$label,",
		"\t$position,",
		"\t$size,",
		"\t$style,",
		");",
	);
	return \@lines;
}

sub button_create {
	my $self     = shift;
	my $button   = shift;
	my $lexical  = $self->object_lexical($button) ? 'my ' : '';
	my $variable = $self->object_variable($button);
	my $id       = $self->wx($button->id);
	my $label    = $self->object_label($button);
	my @lines    = (
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

sub boxsizer_create {
	my $self     = shift;
	my $sizer    = shift;
	my $lexical  = $self->object_lexical($sizer) ? 'my ' : '';
	my $variable = $self->object_variable($sizer);
	my $orient   = $self->wx($sizer->orient);
	my @lines    = (
		"$lexical$variable = Wx::BoxSizer->new( $orient );"
	);
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
	my $label  = $object->label;
	unless ( defined $label and length $label ) {
		return "''";
	}

	# Quote and translate the label
	$label = "'$label'";
	if ( $self->project->internationalize ) {
		$label = "Wx::gettext($label)";
	}

	return $label;
}

sub object_position {
	my $self     = shift;
	my $object   = shift;
	my $position = $object->pos;
	unless ( $position ) {
		return 'Wx::wxDefaultPosition';
	}
	return $position;
}

sub object_size {
	my $self   = shift;
	my $object = shift;
	my $size   = $object->size;
	unless ( $size ) {
		return 'Wx::wxDefaultSize';
	}
	return $size;
}





######################################################################
# Support Methods

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
