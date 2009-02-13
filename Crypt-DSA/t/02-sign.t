use strict;

use Test;
use Crypt::DSA;

BEGIN { plan tests => 4 }

my $message = "Je suis l'homme a tete de chou.";

my $dsa = Crypt::DSA->new;
my $key = $dsa->keygen( Size => 512 );

for (1..4) {
    $message .= "\n$message";

    my $sig = $dsa->sign( Message => $message, Key => $key );
    my $verified = $dsa->verify(
                    Key       => $key,
                    Message   => $message,
                    Signature => $sig
            );
    ok($verified);
}
