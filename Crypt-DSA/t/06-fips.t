use strict;

use Test::More;
use File::Which;
BEGIN {
	if ( $^O eq 'MSWin32' and not $INC{'Math/BigInt/GMP.pm'} and not $ENV{AUTOMATED_TESTING} ) {
		plan( skip_all => 'Test is excessively slow without GMP' );
	} else {
		plan( tests => 18 );
	}
}

use Crypt::DSA;
use Crypt::DSA::KeyChain;

## Test with data from fips 186 (appendix 5) doc (using SHA1
## instead of SHA digests).
my @seed_hex = "d5014e4b60ef2ba8b6211b4062ba3224e0427dd3" =~ /(..)/g;
my $start_seed = join '', map chr hex, @seed_hex;
my $expected_p = "7434410770759874867539421675728577177024889699586189000788950934679315164676852047058354758883833299702695428196962057871264685291775577130504050839126673";
my $expected_q = "1138656671590261728308283492178581223478058193247";
my $expected_g = "5154978420348751798752390524304908179080782918903280816528537868887210221705817467399501053627846983235883800157945206652168013881208773209963452245182466";

## We'll need this later to sign and verify.
my $dsa = Crypt::DSA->new;
is($dsa);

## Create a keychain to generate our keys. Generally you
## don't need to be this explicit (just call keygen), but if
## you want the extra state data (counter, h, seed) you need
## to use the actual methods themselves.
my $keychain = Crypt::DSA::KeyChain->new;
is($keychain);

## generate_params builds p, q, and g.
my($key, $counter, $h, $seed) =
    $keychain->generate_params(Size => 512, Seed => $start_seed);
is("@{[ $key->p ]}", $expected_p);
is("@{[ $key->q ]}", $expected_q);
is("@{[ $key->g ]}", $expected_g);

## Explanation: p should have been found when the counter was at
## 105; g should have been found when h was 2; and g should have
## been discovered directly from the start seed.
is($counter, 105);
is($h, 2);
is($seed, $start_seed);

## Generate random public and private keys.
$keychain->generate_keys($key);

my $str1 = "12345678901234567890";

## Test key generation by signing and verifying a message.
my $sig = $dsa->sign(Message => $str1, Key => $key);
is($dsa->verify(Message => $str1, Key => $key, Signature => $sig));
