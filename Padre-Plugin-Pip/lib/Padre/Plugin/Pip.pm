package Padre::Plugin::Pip;

=pod

=head1 NAME

Padre::Plugin::Pip - A Padre plugin for the pip installer tool

=head1 DESCRIPTION

This plugin provides relatively simple GUI access to the L<pip> command
line installation tool.

After installation there should be a menu items I<Padre - Plugins - Pip -
Install Distribution File> and I<Padre - Plugins - Pip - Install
Distribution URI>.

As the distribution installs, the output will be spooled to the output
window.

=cut

use 5.008;
use strict;
use warnings;
use File::Basename ();
use Padre::Wx      ();
use Padre          ();
use Wx             ();

our $VERSION = '0.13';

sub menu {
	return (
		[ "Install Distribution", \&install_string ],
		# [ "Install Distribution File", \&install_file ],
		# [ "Install Distribution URI",  \&install_uri  ],
	);
}

sub install_string {
	my $window = shift;

	# Ask what we should install
	my $dialog = Wx::TextEntryDialog->new(
		$window,
		"Enter file or URI to install",
		"pip",
		'',
	);
	if ( $dialog->ShowModal == Wx::wxID_CANCEL ) {
		return;
	}
	my $string = $dialog->GetValue;
	$dialog->Destroy;
	unless ( defined $string and $string =~ /\S/ ) {
		Wx::MessageBox(
			"Failed",
			"Did not provide a distribution",
			Wx::wxOK | Wx::wxCENTRE,
			$window,
		);
		return;
	}

	# Execute the command
	$DB::single = 1;
	run_command( $window, $string );
}

sub run_command {
	my $window = shift;
	my $target = shift;
	my $perl   = Padre->perl_interpreter;
	my $dir    = File::Basename::dirname( $perl );
	my $pip    = File::Spec->catfile( $dir, 'pip' );
	unless ( -f $pip ) {
		die "pip is unexpectedly not installed";
	}
	$window->run_command( join ' ', 'perl', $pip, $target );
}

1;

=pod

=head1 TO DO

Add variants that use a file selector, and that sniff the Clipboard for a
URL to install.

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker, located at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Padre-Plugin-Pip>

For general comments, contact the author.

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

=head1 SEE ALSO

L<Padre>

=head1 COPYRIGHT

Copyright 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
