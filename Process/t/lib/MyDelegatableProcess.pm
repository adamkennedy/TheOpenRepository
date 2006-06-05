package MyDelegatableProcess;

use strict;
use base 'Process::Delegatable',
         'Process::Storable',
         'Process';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	$self;
}

sub prepare { 1 }

sub run {
	my $self = shift;
	$self->{launcher_version} = $Process::Launcher::VERSION;
	$self->{process_version}  = $Process::VERSION;
	if ( $self->{pleasedie} ) {
		die "You wanted me to die";
		return '';
	} else {
		$self->{somedata} = 'foo';
		return 1;
	}
}

1;
