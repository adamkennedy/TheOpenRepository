package Perl::Dist::Util::Toolchain;

use 5.005;
use strict;
use base 'Process::Delegatable',
         'Process::Storable',
         'Process';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.50';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	return bless {
		modules => [ @_ ],
		dists   => [    ],
	}, $class;
}

sub prepare {
	my $self = shift;

	# Load the CPAN client
	require CPAN;
	CPAN->import();

	# Load the latest index
	SCOPE: {
		local $SIG{__WARN__} = sub { 1 };
		CPAN::Index->reload;
	}

	return 1;
}

sub run {
	my $self = shift;

	# Find the module
	my %seen = ();
	foreach my $name ( @{$self->{modules}} ) {
		my $module = CPAN::Shell->expand('Module', $name);
		unless ( $module ) {
			$self->{errstr} = "Failed to find '$name'";
			return 0;
		}

		# Filter out already seen dists
		my $file = $module->cpan_file;
		$file =~ s/^[A-Z]\/[A-Z][A-Z]\///;
		next if $seen{$file}++;

		push @{$self->{dists}}, $file;
	}

	return 1;
}

1;
