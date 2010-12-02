#!/usr/bin/perl

use 5.008;
use strict;
use warnings;
use Test::More tests => 8;

use_ok( 'Games::Lacuna::Client::Module'    );
use_ok( 'Games::Lacuna::Client'            );
use_ok( 'Games::Lacuna::Bot'               );
use_ok( 'Games::Lacuna::Bot::Summary'      );
use_ok( 'Games::Lacuna::Bot::Alerts'       );
use_ok( 'Games::Lacuna::Bot::Archaeology'  );
use_ok( 'Games::Lacuna::Bot::RecycleWaste' );
use_ok( 'Games::Lacuna::Bot::MoveWaste'    );
