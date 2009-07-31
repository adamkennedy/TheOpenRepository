use strict;
use warnings;

use Test::More tests => 10;
BEGIN { use_ok('PPI::XS::Tokenizer') };
require PPI;

SCOPE: {
  my $t = PPI::XS::Tokenizer->new("Test");
  isa_ok($t, 'PPI::XS::Tokenizer');
  #ok($t->tokenizeLine("Test") == PPI::XS::Tokenizer::reached_eol, 'simple tokenizeLine call returns reached_eol');
  my $token = $t->get_token();
  ok(defined $token, "Token defined");
  ok($token->isa("PPI::Token::Word"), "Token is a PPI::Token::Word");
  is($token->content, 'Test', "Token contains the word 'Test'");
  is_deeply($token, bless({content => 'Test'}=>'PPI::Token::Word'), 'Check deep structure of Word token');
}


SCOPE: {
  my $t = PPI::XS::Tokenizer->new(<<'HERE');
<<'HEREDOC'
blah
HEREDOC
HERE
  isa_ok($t, 'PPI::XS::Tokenizer');
  my $token = $t->get_token();
  ok(defined $token, "Token defined");
  ok($token->isa("PPI::Token::HereDoc"), "Token is a PPI::Token::HereDoc");
  print $token->content(),"\n";
  is($token->content, 'Test', "Token contains the word 'Test'");
}


