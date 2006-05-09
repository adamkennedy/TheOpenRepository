package CPAN::Data::Author;

use strict;
use base 'DBIx::Class';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

__PACKAGE__->load_components('Core');

__PACKAGE__->table('author');

__PACKAGE__->add_columns(
	id => {
		data_type         => 'varchar',
		size              => 16,
		is_nullable       => 0,
		is_auto_increment => 0,
		default_value     => '',
		},
	name => {
		data_type         => 'varchar',
		size              => 255,
		is_nullable       => 0,
		is_auto_increment => 0,
		default_value     => '',
		},
	email => {
		data_type         => 'varchar',
		size              => 255,
		is_nullable       => 0,
		is_auto_increment => 0,
		default_value     => '',
		},
	);

__PACKAGE__->set_primary_key('id');

1;
