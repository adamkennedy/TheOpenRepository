#!/usr/bin/perl

# Things to do in Jita

use 5.008;
use strict;
use warnings;
use EVE::Plan ();
# use Aspect::Library::Memoize qr/^EVE::(?:DB|Trade)::load$/;

EVE::DB->begin;
EVE::Trade->begin;
EVE::Plan->report_assets;
