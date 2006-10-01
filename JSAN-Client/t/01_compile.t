#!/usr/bin/perl -w

# Compile testing for JSAN client-libs

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 15;

# Check their perl version
ok( $] >= 5.005, "Your perl is new enough" );

# Does the module load
require_ok('JSAN::Transport');
require_ok('JSAN::URI'      );
require_ok('JSAN::Index'    );
require_ok('JSAN::Client'   );

# Was everything loaded?
ok( $JSAN::Client::VERSION,              'JSAN::Client loaded ok'              );
ok( $JSAN::Transport::VERSION,           'JSAN::Transport loaded ok'           );
ok( $JSAN::URI::VERSION,                 'JSAN::URI loaded ok'                 );
ok( $JSAN::Index::VERSION,               'JSAN::Index loaded ok'               );
ok( $JSAN::Index::CDBI::VERSION,         'JSAN::Index::CDBI loaded ok'         );
ok( $JSAN::Index::Extractable::VERSION,  'JSAN::Index::Extractable loaded ok'  );
ok( $JSAN::Index::Author::VERSION,       'JSAN::Index::Author loaded ok'       );
ok( $JSAN::Index::Release::VERSION,      'JSAN::Index::Release loaded ok'      );
ok( $JSAN::Index::Distribution::VERSION, 'JSAN::Index::Distribution loaded ok' );
ok( $JSAN::Index::Library::VERSION,      'JSAN::Index::Release loaded ok'      );

exit(0);
