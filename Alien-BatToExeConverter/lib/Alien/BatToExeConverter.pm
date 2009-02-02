package Alien::BatToExeConverter;

=pod

=head1 NAME

Alien::BatToExeConverter - Convert a DOS Batch Script to an Executable

=head1 SYNOPSIS

  # Convert a batch script to an executable that won't show a DOS box
  Alien::BatToExeConverter::bat2exe(
      bat => 'C:\strawberry\perl\bin\foo.bat',
      exe => 'C:\strawberry\perl\bin\foo.exe',
  );

=head1 DESCRIPTION

Bat_2

=cut

use 5.008;
use strict;
use warnings;
use Carp           ();
use File::Which    ();
use File::ShareDir ();
use IPC::Run3      ();

our $VERSION = '0.01';

sub bat2exe_path {
	# Check for the installed version
	my $installed = File::Which::which('Bat_To_Exe_Converter');
	return $installed if $installed;

	# Default to the bundled version
	File::ShareDir::dist_file(
		'Alien-BatToExeConverter',
		'Bat_To_Exe_Converter.exe',
	);
}

sub bat2exe {
	my %atr = @_;

	# Required input batch script
	my $bat = $param{bat};
	unless ( $bat and $bat =~ /\.bat$/ and -f $bat ) {
		Carp::croak("Missing or invalid bat file");
	}

	# Required output executable application
	my $exe = $param{exe};
	unless ( $exe and $exe =~ /\.exe$/ ) {
		Carp::croak("Missing or invalid exe file");
	}
	if ( -f $exe ) {
		Carp::croak("The target exe '$exe' already exists");
	}

	# Optional icon file
	my $ico = $param{ico} || '';
	if ( $ico and not -f $ico ) {
		Carp::croak("Invalid ico file");
	}

	# DOS or GUI application?
	my $dos = !! $param{dos};

	# Hand off to the executable
	my $bat2exe = bat2exe_path();
	
}

1;

=pod

=head1 SUPPORT

Bugs should be submitted via the CPAN bug tracker, located at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Alien-BatToExeConverter>

For general comments, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
