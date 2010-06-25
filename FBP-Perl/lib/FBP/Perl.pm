package FBP::Perl;

=pod

=head1 NAME

FBP::Perl - Generate Perl GUI code from wxFormBuilder .fbp files

=head1 SYNOPSIS

  my $generator = FBP::Perl->new(
      dialog => $fbp_object->dialog('MyDialog')
  );

=head1 DESCRIPTION

TO BE COMPLETED

=cut

use 5.008005;
use strict;
use warnings;
use Mouse 0.61;
use FBP   0.02 ();

our $VERSION = '0.01';

has project => (
	is       => 'ro',
	isa      => 'FBP::Project',
	required => 1,
);





######################################################################
# High Level Methods

sub dialog_write {
	my $self   = shift;
	my $dialog = shift;
	my $path   = shift;

	# Generate the code
	my $code = $self->flatten(
		$self->dialog_class($dialog)
	);

	# Write it to the file
	open( my $file, '>', $path ) or die "open($path): $!";
	$file->print( $code );
	$file->close;

	return 1;
}






######################################################################
# Dialog Generators

sub dialog_class {
	my $self    = shift;
	my $dialog  = shift;
	my $package = $dialog->name;
	my $pragma  = $self->use_pragma($dialog);
	my $wx      = $self->use_wx($dialog);
	my $isa     = $self->dialog_isa($dialog);
	my $new     = $self->dialog_new($dialog);
	my @methods = map { @$_, "" } $self->dialog_methods($dialog);
	my @lines   = (
		"package $package;",
		"",
		@$pragma,
		@$wx,
		"",
		"our \$VERSION = '0.01';",
		@$isa,
		"",
		@$new,
		"",
		@methods,
		"1;",
	);
	return \@lines;
}

sub dialog_new {
	my $self    = shift;
	my $dialog  = shift;
	my $super   = $self->dialog_super($dialog);
	my @sizers  = $self->indent( $self->dialog_sizers($dialog) );
	my @windows = map { $self->indent($_), "" }
	              map { $self->window_create($_) }
	              $dialog->find( isa => 'FBP::Window' );

	my @lines  = (
		"sub new {",
		"\tmy \$class  = shift;",
		"\tmy \$parent = shift;",
		"",
		$self->indent($super),
		"",
		@windows,
		@sizers,
		"\treturn \$self;",
		"}",
	);

	return \@lines;
}

sub dialog_super {
	my $self     = shift;
	my $dialog   = shift;
	my $id       = $self->wx( $dialog->id );
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

sub dialog_methods {
	my $self    = shift;
	my $dialog  = shift;
	my @methods = ();

	# Only one type of event is currently supported.
	# Eventually this needs to be a lot more in depth.
	my @buttons = grep {
		$_->OnButtonClick
	} $dialog->find( isa => 'FBP::Button' );
	foreach my $button ( @buttons ) {
		push @methods, $self->button_method( $button->OnButtonClick );
	}

	return @methods;
}

sub dialog_sizers {
	my $self   = shift;
	my $dialog = shift;

	# Check the root sizer
	my $sizer = $dialog->children->[0];
	unless ( $sizer->isa('FBP::BoxSizer') ) {
		die 'Dialog root sizer is not a BoxSizer';
	}

	# Generate fragments
	my $variable = $self->object_variable($sizer);
	my $boxsizer = $self->boxsizer_create($sizer);

	my @lines = (
		@$boxsizer,
		"",
		"\$self->SetSizer($variable);",
		"$variable->SetSizeHints(\$self);",
		"",
	);

	return \@lines;
}

sub dialog_isa {
	my $self   = shift;
	my $dialog = shift;
	return [
		"our \@ISA     = 'Wx::Dialog';",
	];
}





######################################################################
# Window and Control Generators

sub window_create {
	my $self   = shift;
	my $window = shift;
	if ( $window->isa('FBP::Button') ) {
		return $self->button_create($window);
	} elsif ( $window->isa('FBP::StaticText') ) {
		return $self->statictext_create($window);
	} elsif ( $window->isa('FBP::StaticLine') ) {
		return $self->staticline_create($window);
	} elsif ( $window->isa('FBP::ComboBox') ) {
		return $self->combobox_create($window);
	} else {
		die "Cannot create constructor code for " . ref($window);
	}
}

sub button_create {
	my $self     = shift;
	my $button   = shift;
	my $lexical  = $self->object_lexical($button) ? 'my ' : '';
	my $variable = $self->object_variable($button);
	my $id       = $self->wx( $button->id );
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

sub button_method {
	my $self   = shift;
	my $method = shift;
	my @lines  = (
		"sub $method {",
		"\tmy \$self  = shift;",
		"\tmy \$event = shift;",
		"",
		"\tdie 'TO BE COMPLETED';",
		"}",
	);
	return \@lines;
}

sub combobox_create {
	my $self     = shift;
	my $combo    = shift;
	my $lexical  = $self->object_lexical($combo) ? 'my ' : '';
	my $variable = $self->object_variable($combo);
	my $id       = $self->wx( $combo->id );
	my $value    = $self->quote( $combo->value );
	my $position = $self->object_position($combo);
	my $size     = $self->object_size($combo);
	my $style    = $self->wx( $combo->style );
	my @lines    = (
		"$lexical$variable = Wx::ComboBox->new(",
		"\t\$self,",
		"\t$id,",
		"\t$value,",
		"\t$position,",
		"\t$size,",
		"\t[ ],",
		"\t$style,",
		");",
	);
	return \@lines;
}

sub statictext_create {
	my $self     = shift;
	my $text     = shift;
	my $lexical  = $self->object_lexical($text) ? 'my ' : '';
	my $variable = $self->object_variable($text);
	my $id       = $self->wx( $text->id );
	my $label    = $self->object_label($text);
	my @lines    = (
		"$lexical$variable = Wx::StaticText->new(",
		"\t\$self,",
		"\t$id,",
		"\t$label,",
		");",
	);
	return \@lines;
}

sub staticline_create {
	my $self     = shift;
	my $line     = shift;
	my $lexical  = $self->object_lexical($line) ? 'my ' : '';
	my $variable = $self->object_variable($line);
	my $id       = $self->wx( $line->id );
	my $position = $self->object_position($line);
	my $size     = $self->object_size($line);
	my @lines    = (
		"$lexical$variable = Wx::StaticLine->new(",
		"\t\$self,",
		"\t$id,",
		"\t$position,",
		"\t$size,",
		");",
	);
	return \@lines;
}

sub boxsizer_create {
	my $self     = shift;
	my $sizer    = shift;
	my $lexical  = $self->object_lexical($sizer) ? 'my ' : '';
	my $variable = $self->object_variable($sizer);
	my $orient   = $self->wx( $sizer->orient );

	# Add the content for child sizers
	my @lines = map {
		( @$_, "" )
	} map {
		$self->boxsizer_create($_)
	} grep {
		$_->isa('FBP::Sizer')
	} map {
		$_->children->[0]
	} @{$sizer->children};

	# Add the content for this sizer
	push @lines, "$lexical$variable = Wx::BoxSizer->new( $orient );";
	foreach my $item ( @{$sizer->children} ) {
		my $child  = $item->children->[0];
		my $params = join(
			', ',
			$self->object_variable($child),
			$item->proportion,
			$self->wx( $item->flag ),
			$item->border,
		);
		push @lines, "$variable->Add( $params );";
	}

	return \@lines;
}





######################################################################
# Common Fragment Generators

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
	$position =~ s/,/, /;
	return "[ $position ]";
}

sub object_size {
	my $self   = shift;
	my $object = shift;
	my $size   = $object->size;
	unless ( $size ) {
		return 'Wx::wxDefaultSize';
	}
	$size =~ s/,/, /;
	return "[ $size ]";
}





######################################################################
# Support Methods

sub use_pragma {
	my $self = shift;
	my $dialog  = shift;
	return [
		"use 5.008;",
		"use strict;",
		"use warnings;",
	]
}

sub use_wx {
	my $self    = shift;
	my $dialog  = shift;
	return [
		"use Wx ':everything';",
	];
}

sub wx {
	my $self   = shift;
	my $string = shift;
	if ( $string eq 'wxID_ANY' ) {
		return -1;
	}
	$string =~ s/\bwx/Wx::wx/g;
	$string =~ s/\s*\|\s*/ | /g;
	return $string;
}

sub quote {
	my $self = shift;
	my $string = shift;
	return '"' . quotemeta($string) . '"';
}

sub indent {
	map { /\S/ ? "\t$_" : $_ } @{$_[1]};
}

sub flatten {
	join '', map { "$_\n" } @{$_[1]};
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FBP-Perl>

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
