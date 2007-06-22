package Games::EVE::Killmail::Store::Schema::Killmail;

use 5.005;
use strict;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw{PK::Auto Core});
__PACKAGE__->table('killmail');
__PACKAGE__->add_columns(qw{ killid rawmail datetime victim ship signature });
__PACKAGE__->set_primary_key(qw{ killid });

1;
