package FBP::Demo;

use 5.008;
use strict;
use warnings;
use Wx ':everything';

our $VERSION = '0.02';
our @ISA     = 'Wx::App';

sub run {
	my $class = shift;
	my $self  = $class->new(@_);
	$self->MainLoop;
	return 1;
}

sub OnInit {
	my $self = shift;

	# Set the application name
	$self->SetAppName('FBP Demonstration Application');

	# Create the main window
	require FBP::Demo::Frame::Main;
	$self->SetTopWindow(
		FBP::Demo::Frame::Main->new
	);
	$self->GetTopWindow->Show(1);

	return 1;
}

1;

__END__

=pod

=head1 NAME

FBP::Demo - FBP::Perl Demonstration Application

=head1 DESCRIPTION

B<FBP::Demo> is a Perl distribution which represents the target output of the
code generation functionality in L<FBP::Perl>.

It has been completed (or at least initially aims to be) generated from a
wxFormBuilder project file, and represents approximately what your own own
generated distribution should look like when you use a front end such as
L<Padre::Plugin::FormBuilder> to generate a Perl distributions.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FBP-Demo>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
