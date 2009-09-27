use strict;
use warnings;

use Test::More tests => 26;
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
    { %$token },
    {content => 'Test'},
    'Check deep structure of Word token'
  );
}


SCOPE: {
  my $t = PPI::XS::Tokenizer->new("qq{foo}");
  isa_ok($t, 'PPI::XS::Tokenizer');
  my $token = $t->get_token();
  ok(defined $token, "Token defined");
  isa_ok($token, "PPI::Token::Quote::Interpolate");
  is($token->content, 'qq{foo}', "Token content check");
  is_deeply(
    { %$token },
    {
      'operator' => 'qq',
      '_sections' => 1,
      'braced' => 1,
      'separator' => undef,
      'content' => 'qq{foo}',
      'sections' => [ { 'position' => 3, 'type' => '{}', 'size' => 3 } ],
    },
    'Check deep structure of Interpolate token'
  );
}


SCOPE: {
  my $t = PPI::XS::Tokenizer->new("'foo'");
  isa_ok($t, 'PPI::XS::Tokenizer');
  my $token = $t->get_token();
  ok(defined $token, "Token defined");
  isa_ok($token, "PPI::Token::Quote::Single");
  is($token->content, "'foo'", "Token content check");
  is_deeply(
    { %$token },
    { 'separator' => "'", 'content' => "'foo'" },
    'Check deep structure of Quote::Single token'
  );
}


SCOPE: {
  my $t = PPI::XS::Tokenizer->new('"foo"');
  isa_ok($t, 'PPI::XS::Tokenizer');
  my $token = $t->get_token();
  ok(defined $token, "Token defined");
  isa_ok($token, "PPI::Token::Quote::Double");
  is($token->content, '"foo"', "Token content check");
  is_deeply(
    { %$token },
    { 'separator' => '"', 'content' => '"foo"' },
    'Check deep structure of Quote::Double token'
  );
}


SCOPE: {
  my $text = <<'HERE';
<<'HEREDOC'
blah
blubb
HEREDOC
HERE

  my $t = PPI::XS::Tokenizer->new($text);
  isa_ok($t, 'PPI::XS::Tokenizer');
  my $token = $t->get_token();
  ok(defined $token, "Token defined");
  ok($token->isa("PPI::Token::HereDoc"), "Token is a PPI::Token::HereDoc");
  is($token->content, '<<\'HEREDOC\'', "Token 'content' is the heredoc marker");
  is($token->content, '<<\'HEREDOC\'', "Token 'content' is the heredoc marker");
  is_deeply(
    { %$token },
    {
      '_mode' => 'literal',
      '_heredoc' => ["blah\n", "blubb\n"],
      '_terminator' => 'HEREDOC',
      'content' => '<<\'HEREDOC\'',
      '_terminator_line' => "HEREDOC\n",
    },
    'Check deep structure of the HEREDOC'
  );
}


