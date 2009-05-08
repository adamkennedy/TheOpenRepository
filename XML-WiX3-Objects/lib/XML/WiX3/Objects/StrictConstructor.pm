package # Hide from PAUSE.
	XML::WiX3::Objects::StrictConstructor;

use strict;
use warnings;

#our $VERSION = '0.08';
#$VERSION = eval $VERSION;

use Moose 0.74 ();
use Moose::Exporter;
use Moose::Util::MetaRole;
use XML::WiX3::Objects::::Role::StrictConstructor;
use XML::WiX3::Objects::::Role::StrictConstructorMeta;


Moose::Exporter->setup_import_methods();

sub init_meta
{
    shift;
    my %p = @_;

    Moose->init_meta(%p);

    my $caller = $p{for_class};

    Moose::Util::MetaRole::apply_metaclass_roles( 
	  for_class => $caller,
      constructor_class_roles =>
        ['XML::WiX3::Objects::::Role::StrictConstructorMeta'],
    );

    Moose::Util::MetaRole::apply_base_class_roles( 
	  for_class => $caller,
      roles =>
        [ 'XML::WiX3::Objects:::Role::StrictConstructor' ],
	);

    return $caller->meta();
}

1;
