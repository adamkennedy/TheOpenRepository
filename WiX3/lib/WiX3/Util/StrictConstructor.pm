package                                # Hide from PAUSE.
  WiX3::Util::StrictConstructor;

# Corresponds to MooseX::StrictConstructor.

use 5.008001;
use Moose 0.94 qw();
use Moose::Exporter;
use Moose::Util::MetaRole;
use WiX3::Util::Role::StrictConstructor;
use WiX3::Util::Role::StrictConstructorMeta;

our $VERSION = '0.010';
$VERSION =~ s/_//ms;

Moose::Exporter->setup_import_methods(
	class_metaroles =>
	  { constructor => ['WiX3::Util::Role::StrictConstructorMeta'] },
	base_class_roles => ['WiX3::Util::Role::StrictConstructor'],
);

1;
