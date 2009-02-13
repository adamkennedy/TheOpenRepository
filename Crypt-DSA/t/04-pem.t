use strict;

use Test::More;
BEGIN {
    eval { require Convert::PEM };
    if ($@) {
        Test::More->import( skip_all => 'no Convert::PEM' );
    }
    Test::More->import( tests => 26 );
}

use Crypt::DSA;
use Crypt::DSA::Key;
use Crypt::DSA::Signature;

my $keyfile = "./dsa-key.pem";

my $dsa = Crypt::DSA->new;
my $key = $dsa->keygen( Size => 512 );

## Serialize a signature.
my $sig = $dsa->sign( Message => 'foo', Key => $key );
ok($sig);
my $buf = $sig->serialize;
ok($buf);
my $sig2 = Crypt::DSA::Signature->new( Content => $buf );
ok($sig2);
is($sig2->r, $sig->r);
is($sig2->s, $sig->s);

my $key2;

ok($key->write( Type => 'PEM', Filename => $keyfile));
$key2 = Crypt::DSA::Key->new( Type => 'PEM', Filename => $keyfile );
ok($key2);
is($key->p, $key2->p);
is($key->q, $key2->q);
is($key->g, $key2->g);
is($key->pub_key, $key2->pub_key);
is($key->priv_key, $key2->priv_key);

ok($key->write( Type => 'PEM', Filename => $keyfile, Password => 'foo'));
$key2 = Crypt::DSA::Key->new( Type => 'PEM', Filename => $keyfile, Password => 'foo' );
ok($key2);
is($key->p, $key2->p);
is($key->q, $key2->q);
is($key->g, $key2->g);
is($key->pub_key, $key2->pub_key);
is($key->priv_key, $key2->priv_key);

## Now remove the private key portion of the key. write should automatically
## write a public key format instead, and new should be able to understand
## it.
$key->priv_key(undef);
ok($key->write( Type => 'PEM', Filename => $keyfile));
$key2 = Crypt::DSA::Key->new( Type => 'PEM', Filename => $keyfile );
ok($key2);
is($key->p, $key2->p);
is($key->q, $key2->q);
is($key->g, $key2->g);
is($key->pub_key, $key2->pub_key);
ok(!$key->priv_key);

unlink $keyfile;
