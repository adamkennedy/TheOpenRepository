package Perl::Dist::Util::Toolchain;

use 5.005;
use strict;
use IO::Capture::Stdout ();
use IO::Capture::Stderr ();
use base 'Process::Delegatable',
         'Process::Storable',
         'Process';

use vars qw{$VERSION @DELEGATE};
BEGIN {
	$VERSION  = '0.50';
	@DELEGATE = ();
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

	# Squash all output that CPAN might spew during this process
	my $stdout = IO::Capture::Stdout->new;
	my $stderr = IO::Capture::Stderr->new;
	$stdout->start;
	$stderr->start;

	# Load the CPAN client
	require CPAN;
	CPAN->import();

	# Load the latest index
	SCOPE: {
		local $SIG{__WARN__} = sub { 1 };
		CPAN::Index->reload;
	}

	$stdout->stop;
	$stderr->stop;
	return 1;
}

sub run {
	my $self = shift;

	# Squash all output that CPAN might spew during this process
	my $stdout = IO::Capture::Stdout->new;
	my $stderr = IO::Capture::Stderr->new;
	$stdout->start;
	$stderr->start;
	
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

	# Free up stdout/stderr for normal output again
	$stdout->stop;
	$stderr->stop;

	return 1;
}

sub delegate {
	return shift->SUPER::delegate( @DELEGATE );
}

1;

