package Data::Package::CSV;

=pod

=head1 NAME

Data::Package::CSV - A Data::Package class for CSV data using Parse::CSV

=head1 DESCRIPTION

=head1 METHODS

=cut

use 5.005;
use strict;
use File::Spec     ();
use Parse::CSV     ();
use File::ShareDir ();
use base 'Data::Package';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

sub _provides {
	return ( 'Parse::CSV' );
}

sub __as_Parse_CSV {
	my $class = shift;

	# Get the main options
	my %options = $class->csv_options;
	unless ( $options{handle} or $options{file} ) {
		# Locate the data
		my $csv_handle = $class->csv_handle;
		if ( $csv_handle ) {
			$options{handle} = $cvs_handle;
			delete $options{file};
		} else {
			my $csv_file = $class->csv_file;
			if ( $csv_file ) {
				$options{file} = $class->csv_file;
				delete $options{handle};
			} else {
				die "No CSV data source found for $class";		
			}
		}
	}

	# Create the parser object
	my $parse_csv = Parse::CSV->new( %options );
	unless ( $parse_csv ) {
		die "Failed to create Parse::CSV object";
	}

	return $parse_csv;
}

=pod

=head2 csv_options

The B<cvs_options> method is the most direct method, with full control
over the creation of the L<Parse::CSV> object. If a fully compliant options
hash is returned (as a list) then no other methods need to be defined.

The list returned by the B<cvs_options> method will be passed directly to
the L<Parse::CSV> constructor. Read the documentation for L<Parse::CSV> for
more details on what you should return to match your data.

By default, the null list is return, specifying entirely default options
to the L<Parse::CSV> constructor (array mode) and not specifying 

If it list that is returned does not have either a data source (either a
C<handle> param or C<file> param) additional methods will be called (in
the same order as documented below).

=cut

sub csv_options {
	return ();
}

=pod

=head2 cvs_handle

If the B<cvs_options> method does not return a C<handle> or C<file> param
the first method tried for a data source is B<cvs_handle>.

If defined, it should return a value that L<Parse::CSV> will accept as its
C<handle> param.

It B<cvs_handle> is not defined or returns C<undef>, the next method that
will be tried is B<cvs_file>.

=cut

sub csv_handle {
	return undef;
}

=pod

=head2 cvs_file

If the B<cvs_options> method does not return a C<handle> or C<file> param
the second method tried for a data source is B<cvs_file>.

If defined, it should return a value that L<Parse::CSV> will accept as its
C<file> param.

If B<cvs_file> is not defined or returns C<undef>, the filal method that
will be tried is B<csv_module_file>.

=cut

sub csv_file {
	my $class = shift;

	# Check the cvs_module_file method
	my @module_file = $class->csv_module_file;
	if ( @module_file ) {
		# Handle the auto-class case
		if ( @module_file == 1 ) {
			unshift @module_file, $class;
		}

		# Get the file from File::ShareDir
		return File::ShareDir::module_file( @module_file );
	}

	# Check the cvs_dist_file method
	my @dist_file = $class->csv_dist_file;
	if ( @dist_file ) {
		# Get the file from File::ShareDir
		return File::ShareDir::dist_file( @dist_file );
	}

	return undef;
}

=pod

=head2 cvs_module_file
  
  # In a package of this name, the two following
  # methods are equivalent to each other.
  package Module::Name;
  
  # A File::ShareDir file with the package class
  sub csv_module_file {
      return File::Spec->catfile('subdir', 'data.csv');
  }
  
  # A File::ShareDir file with an explicit class
  sub csv_module_file {
      return ( 'Module::Name', 'data.csv' );
  }

If the B<cvs_options> method does not return a C<handle> or C<file> param
the final method tried for a data source is B<csv_module_file>, which
provides integration with L<File::ShareDir>.

It can be used in two modes.

Returning a two-param list will cause the two values to be passed
directly to B<File::ShareDir::module_file>.

Returning a single param will cause the value to be passed through to
B<File::ShareDir::module_file> with the first param as your class.

=cut

sub csv_module_file {
	return ();
}

=head2 cvs_dist_file

  package Module::Name::Subpackage;
  
  use strict;
  use base 'Data::Package::CSV';
  
  # A File::ShareDir file with the package class
  sub csv_dist_file {
      return ('Module-Name', File::Spec->catfile('dir', 'data.csv'));
  }
  
  1;

If the B<cvs_options> method does not return a C<handle> or C<file> param
the fourth method tried for a data source is B<csv_dist_file>, which
provides integration with L<File::ShareDir>.

It returns two values which will be passed to B<File::ShareDir::dist_file>.

=cut

sub csv_dist_file {
	return ();
}

1;

=pod

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker.

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Package-CSV>

For other issues, contact the maintainer

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
