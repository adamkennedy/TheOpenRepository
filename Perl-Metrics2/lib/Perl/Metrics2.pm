package Perl::Metrics2;

=pod

=head1 NAME

Perl::Metrics2 - Perl metrics storage and processing engine

=head1 DESCRIPTION

B<THIS IS AN EXPERIMENTAL MODULE AND MAY CHANGE WITHOUT NOTICE>

B<Perl::Metrics2> is a 2nd-generation implementation of the Perl Code
Metrics System.

The Perl Code Metrics System is a module which provides a Perl document
metrics processing engine, and a database in which to store the
resulting metrics data.

The intent is to be able to take a large collection of Perl documents,
and relatively easily parse the files and run a series of processes on
the documents.

The resulting data can then be stored, and later used to generate useful
information about the documents.

=head2 General Structure

Perl::Metrics2 consists of two primary elements. Firstly, an
L<ORLite> database that stores the metrics informationg.

See L<Perl::Metrics2::FileMetrics> for the data class stored in the
database.

The second element is a plugin structure for creating metrics packages,
so that the metrics capture can be done independant of the underlying
mechanisms used for parsing, storage and analysis.

See L<Perl::Metrics2::Plugin> for more information.

=head2 Getting Started

C<Perl::Metrics2> comes with on default plugin,
L<Perl::Metrics2::Plugin::Core>, which provides a sampling of metrics.

To get started load the module, providing the database location as a
param (it will create it if needed). Then call the C<process_directory>
method, providing it with an absolute path to a directory of Perl code
on the local filesystem.

C<Perl::Metrics> will work on the files in the directory, and when it
finishes you will have a nice database full of metrics data about your
files.

Of course, how you actually USE that data is up to you, but you can
query L<Perl::Metrics2::FileMetric> just like any other L<ORLite>
database once you have collected it all.

=head1 METHODS

=cut

use 5.008005;
use strict;
use Carp                   ();
use DBI                    ();
use File::Spec             ();
use File::HomeDir          ();
use File::ShareDir         ();
use File::Find::Rule       ();
use File::Find::Rule::Perl ();
use Params::Util           ();
use PPI::Util              ();
use PPI::Document          ();
use Module::Pluggable;

our $VERSION = '0.01';

use constant ORLITE_FILE => File::Spec->catfile(
	File::HomeDir->my_data,
	($^O eq 'MSWin32' ? 'Perl' : '.perl'),
	'Perl-Metrics2',
	'Perl-Metrics2.sqlite',
);

use constant ORLITE_TIMELINE => File::Spec->catdir(
	File::ShareDir::dist_dir('Perl-Metrics2'),
	'timeline',
);

use ORLite          1.20 ();
use ORLite::Migrate 0.03 {
	file         => ORLITE_FILE,
	create       => 1,
	timeline     => ORLITE_TIMELINE,
	user_version => 1,
};





#####################################################################
# Main Methods

sub process_file {
	my $class = shift;

	# Get and check the filename
	my $path = File::Spec->canonpath(shift);
	unless ( defined Params::Util::_STRING($path) ) {
		Carp::croak("Did not pass a file name to index_file");
	}
	unless ( File::Spec->file_name_is_absolute($path) ) {
		Carp::croak("Cannot index relative path '$path'. Must be absolute");
	}
	Carp::croak("Cannot index '$path'. File does not exist") unless -f $path;
	Carp::croak("Cannot index '$path'. No read permissions") unless -r _;

	# Load the document
	my $document = PPI::Document->new( $path,
		readonly => 1,
	) or die("Failed to parse '$path'");

	# Create the plugin objects
	foreach my $plugin ( $class->plugins ) {
		$class->trace("STARTING PLUGIN $plugin");
		eval "require $plugin";
		die $@ if $@;
		$plugin->new->process_document($document);
	}

	return 1;
}





#####################################################################
# Support Methods

sub trace {
	print STDERR map { "# $_\n" } @_[1..$#_];
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Metrics2>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2005 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
