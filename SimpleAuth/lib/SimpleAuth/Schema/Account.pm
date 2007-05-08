package SimpleAuth::Schema::Account;

use 5.005;
use strict;
use base 'DBIx::Class';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

__PACKAGE__->load_components( 'PK::Auto', 'Core' );
__PACKAGE__->table( 'account' );
__PACKAGE__->add_column( 'id', 'email', 'service', 'password', 'rights' );
__PACKAGE__->set_primary_key( 'id' );

1;
