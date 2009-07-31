use strict;
use warnings;

use Test::More tests => 15;
BEGIN { use_ok('PPI::XS::Tokenizer') };
require PPI;

SCOPE: {
  my $t = PPI::XS::Tokenizer->new("Test");
  isa_ok($t, 'PPI::XS::Tokenizer');
  #ok($t->tokenizeLine("Test") == PPI::XS::Tokenizer::reached_eol, 'simple tokenizeLine call returns reached_eol');
  my $token = $t->get_token();
  ok(defined $token, "Token defined");
  isa_ok($token, "PPI::Token::Word");
  is($token->content, 'Test', "Token contains the word 'Test'");
  is_deeply(
    $token,
    bless( {content => 'Test'} => 'PPI::Token::Word' ),
    'Check deep structure of Word token'
  );
}

SCOPE: {
  my $t = PPI::XS::Tokenizer->new("qq{foo}");
  isa_ok($t, 'PPI::XS::Tokenizer');
  my $token = $t->get_token();
  ok(defined $token, "Token defined");
  use Data::Dumper; warn Dumper $token;
  isa_ok($token, "PPI::Token::Quote::Interpolate");
  is($token->content, 'qq{foo}', "Token content check");
  is_deeply(
    $token,
    bless( {
        'operator' => 'qq',
        '_sections' => 1,
        'braced' => 1,
        'separator' => undef,
        'content' => 'qq{foo}',
        'sections' => [ { 'position' => 3, 'type' => '{}', 'size' => 3 } ],
      }, 'PPI::Token::Quote::Interpolate'
    ),
    'Check deep structure of Interpolate token'
  );
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


