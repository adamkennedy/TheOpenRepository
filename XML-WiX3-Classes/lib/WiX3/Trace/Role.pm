package                                # Hide from PAUSE.
  WiX3::Trace::Role;

use 5.008001;
use strict;
use warnings;
use Moose::Role;
use WiX3::Types qw(Tracelevel);

use version; our $VERSION = version->new('0.005')->numify;

has tracelevel => (
	isa     => Tracelevel,
	reader  => 'get_tracelevel',
	writer  => 'set_tracelevel',
	default => 1,
);

has testing => (
	isa     => 'Bool',
	reader  => 'get_testing',
	default => 0,
);

has email_from => (
	isa     => 'Maybe[Str]',
	reader  => '_get_email_from',
	default => undef,
);

has email_to => (
	isa     => 'ArrayRef[Str]',
	reader  => '_get_email_to',
	default => sub { return []; },
);

has smtp => (
	isa     => 'Maybe[Str]',
	reader  => '_get_smtp',
	default => undef,
);

has smtp_user => (
	isa     => 'Maybe[Str]',
	reader  => '_get_smtp_user',
	default => q{},
);

has smtp_pass => (
	isa     => 'Maybe[Str]',
	reader  => '_get_smtp_pass',
	default => undef,
);

has smtp_port => (
	isa     => 'Maybe[Int]',
	reader  => '_get_smtp_port',
	default => undef,
);

no Moose::Role;

1;                                     # Magic true value required at end of module
