#!/usr/bin/perl

use 5.008;
use strict;
use warnings;
use Test::More tests => 11;

use_ok( 'ADAMK::Lacuna::Client::Builder'    );
use_ok( 'ADAMK::Lacuna::Client::Module'     );
use_ok( 'ADAMK::Lacuna::Client'             );
use_ok( 'ADAMK::Lacuna::Bot'                );
use_ok( 'ADAMK::Lacuna::Bot::Summary'       );
use_ok( 'ADAMK::Lacuna::Bot::Alerts'        );
use_ok( 'ADAMK::Lacuna::Bot::Archaeology'   );
use_ok( 'ADAMK::Lacuna::Bot::RecycleWaste'  );
use_ok( 'ADAMK::Lacuna::Bot::Repair'        );
use_ok( 'ADAMK::Lacuna::Bot::MoveWaste'     );
use_ok( 'ADAMK::Lacuna::Bot::MoveResources' );
