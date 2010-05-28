package                                # Hide from PAUSE.
  WiX3::Util::StrictConstructor;

use 5.008001;
use Moose 0.74 qw();
use Moose::Exporter;
use Moose::Util::MetaRole;
use WiX3::Util::Role::StrictConstructor;
use WiX3::Util::Role::StrictConstructorMeta;

our $VERSION = '0.009100';
$VERSION =~ s/_//ms;

Moose::Exporter->setup_import_methods();

sub init_meta {
	shift;
	my %p = @_;

	Moose->init_meta(%p);

	my $caller = $p{for_class};

	Moose::Util::MetaRole::apply_metaclass_roles(
		for_class => $caller,
		constructor_class_roles =>
		  ['WiX3::Util::Role::StrictConstructorMeta'],
	);

	Moose::Util::MetaRole::apply_base_class_roles(
		for_class => $caller,
		roles     => ['WiX3::Util::Role::StrictConstructor'],
	);

	return $caller->meta();
} ## end sub init_meta

1;
