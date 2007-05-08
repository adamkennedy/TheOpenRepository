package SimpleAuth::Schema::Email;

use 5.005;
use strict;
use base 'DBIx::Class';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

__PACKAGE__->load_components( 'Core' );
__PACKAGE__->table( 'email' );
__PACKAGE__->add_column( 'address', 'name', 'password', 'change' );
__PACKAGE__->set_primary_key( 'address' );

1;
