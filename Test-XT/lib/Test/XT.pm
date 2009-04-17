package Test::XT;

=pod

=head1 NAME

Test::XT - Generate best practice author tests

=head1 SYNOPSIS

  use Test::XT 'WriteXT';
  
  WriteXT(
      'Test::Pod'            => 't/pod.t',
      'Test::CPAN::Meta'     => 't/meta.t',
      'Test::MinimumVersion' => 't/minimumversion.t',
  );

=head1 DESCRIPTION

A number of Test modules have been written over the years to support
authors. Typically, these modules have standard short test scripts
documented in them that you can cut and paste into your distribution.

Unfortunately almost all of these cut-and-paste test scripts are wrong.

Either the test script runs during install time, or it runs with an
out-of-date version of the test module, or the author adds the test
modules as an (unnecesary) dependency at install time, or for automated
testing.

B<Test::XT> is a module intended for use in code generators, release
automation and other ancillary systems. It generates an appropriate test
script for various testing modules that runs in the appropriate mode for
each type of execution environment.

1. End User Install

At installation time, test scripts should never ever run, even if the
test modules are installed and available.

2. Automated Testing

  # Enable automated testing
  $ENV{AUTOMATED_TESTING} = 1

During automated testing we should run the tests, but only if the testing
module are already installed and at the current/latest version.

However, we should not install dependencies during automated testing,
because failing to install a testing dependency means B<less> runs
on your code when the entire point of the author tests is to improve
the standard of testing, not reduce it.

3. Release/Author Testing

  # Enable author tests
  $ENV{RELEASE_TESTING} = 1;

All tests should run at release time by the author. Despite this, the
dependencies STILL should not be checked for in your F<Makefile.PL> or
F<Build.PL>, because you could end up accidentally having these extra
dependencies bleed through into your published META.yml.

This would cause inaccuracies in tools that track dependencies
across the entire repository via the META.yml files.

=cut

use 5.008;
use strict;
use warnings;
use Exporter ();

use vars qw{$VERSION @ISA @EXPORT_OK};
BEGIN {
	$VERSION   = '0.01';
	@ISA       = 'Exporter';
	@EXPORT_OK = qw{
		WriteTest
		WriteXT
	};
}

# Data for standard tests
my %STANDARD = (
	'Test::Pod' => {
		test    => 'all_pod_files_ok',
		comment => 'Test that the syntax of our POD documentation is valid',
		modules => {
			'Pod::Simple' => '3.07',
			'Test::Pod'   => '1.26',
		},
	},
	'Test::CPAN::Meta' => {
		test    => 'meta_yaml_ok',
		comment => 'Test that our META.yml file matches the specification',
		modules => {
			'Test::CPAN::Meta' => '0.12',
		},
	},
	'Test::MinimumVersion' => {
		test    => 'all_minimum_version_from_metayml_ok',
		comment => 'Test that our declared minimum Perl version matches our syntax',
		modules => {
			'Perl::MinimumVersion' => '1.20',
			'Test::MinimumVersion' => '0.008',
		},
	},
);





#####################################################################
# Exportable Functions

sub WriteTest {
	my $file = shift;
	Test::XT->new( @_ )->write( $file );
}

sub WriteXT {
	while ( @_ ) {
		my $module = shift;
		my $file   = shift;
		unless ( $STANDARD{$module} ) {
			die "Unknown standard test script $module";
		}
		Test::XT->new(
			%{$STANDARD{$module}}
		)->write( $file );
	}
}





#####################################################################
# Object Form

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	return $self;
}

sub module {
	$_[0]->{modules}->{$_[1]}->{$_[2]};
}

sub test {
	$_[0]->{test} = $_[1];
}

sub write {
	my $self   = shift;

	# Write the file
	open( FILE, '>', $_[0 ] ) or die "open: $!";
	print FILE $self->write_string;
	close FILE;

	return 1;
}

sub write_string {
	my $self    = shift;
	my $comment = $self->{comment} ? "\n# $self->{comment}" : '';
	my $modules = join "\n", map {
		"\t'$_ $self->{modules}->{$_}',"
	} sort keys %{$self->{modules}};
	return <<"END_TEST";
#!/usr/bin/perl
$comment
use strict;
BEGIN {
	\$|  = 1;
	\$^W = 1;
}

my \@MODULES = (
$modules
);

# Don't run tests during end-user installs
use Test::More;
unless ( \$ENV{AUTOMATED_TESTING} or \$ENV{RELEASE_TESTING} ) {
	plan( skip_all => "Author tests not required for installation" );
}

# Load the testing modules
foreach my \$MODULE ( \@MODULES ) {
	eval "use \$MODULE";
	if ( \$@ ) {
		\$ENV{RELEASE_TESTING}
		? die( "Failed to load required release-testing module \$MODULE" )
		: plan( skip_all => "\$MODULE not available for testing" );
	}
}

$self->{test}();

1;
END_TEST

}

1;

=pod

=head1 SUPPORT

Bugs should be submitted via the CPAN bug tracker, located at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-XT>

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
