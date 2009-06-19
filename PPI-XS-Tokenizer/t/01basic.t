use strict;
use warnings;

use Test::More tests => 5;
BEGIN { use_ok('PPI::XS::Tokenizer') };
require PPI::Token::Word;

SCOPE: {
  my $t = PPI::XS::Tokenizer->new("Test");
  isa_ok($t, 'PPI::XS::Tokenizer');
  #ok($t->tokenizeLine("Test") == PPI::XS::Tokenizer::reached_eol, 'simple tokenizeLine call returns reached_eol');
  my $token = $t->get_token();
  ok(defined $token, "Token defined");
  ok($token->isa("PPI::Token::Word"), "Token is a PPI::Token::Word");
  is($token->content, 'Test', "Token contains the word 'Test'");
}



