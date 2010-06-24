package Padre::FormBuilder;

=pod

=head1 NAME

Padre::FormBuilder - wxFormBuilder to Padre dialog code generator

=head1 SYNOPSIS

  my $generator = Padre::FormBuilder->new(
      dialog => $fbp_object->dialog('MyDialog')
  );

=head1 DESCRIPTION

This is a Padre-specific variant of L<Wx::Perl::FormBuilder>.

It is currently packaged alongside with main L<Wx::Perl::FormBuilder>
module because Padre is currently the dominant consumer of FormBuilder
GUI designs.

=cut

use 5.008005;
use strict;
use warnings;
use Moose 1.05;

our $VERSION = '0.01';

extends 'Wx::Perl::FormBuilder';





######################################################################
# Dialog Generators

sub dialog_isa {
	my $self   = shift;
	my $dialog = shift;
	return [
		"our \@ISA     = qw{",
		"\tPadre::Wx::Role::Main",
		"\tWx::Dialog",
		"};",
	];
}

sub use_wx {
	my $self    = shift;
	my $dialog  = shift;
	return [
		"use Padre::Wx             ();",
		"use Padre::Wx::Role::Main ();",
	];
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
