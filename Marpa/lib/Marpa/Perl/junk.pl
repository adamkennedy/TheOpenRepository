#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use PPI;
use Data::Dumper;

my $Tokenizer = PPI::Tokenizer->new( '../../../lib/Marpa/Internal.pm' );
# Return all the tokens for the document
print Data::Dumper::Dumper( $Tokenizer->all_tokens );

