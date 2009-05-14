use strict;
use warnings;

use Test::More tests => 3;
BEGIN { use_ok('PPI::XS::Tokenizer') };

SCOPE: {
  my $t = PPI::XS::Tokenizer->new();
  isa_ok($t, 'PPI::XS::Tokenizer');
  # TODO: this is really an enum
  # TODO: Can ExtUtils::Constant help for exporting the enum to perl?
  ok($t->tokenizeLine("Test") == PPI::XS::Tokenizer::reached_eol, 'simple tokenizeLine call returns reached_eol');
}



