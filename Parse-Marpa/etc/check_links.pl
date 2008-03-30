use 5.010_000;
use strict;
use warnings;
use LWP::UserAgent;
use URI::URL;
use HTML::LinkExtor;

my $url_base = "http://search.cpan.org/~jkegl/Parse-Marpa-0.205_007/lib/Parse/";
my @url = qw(
    Marpa.pm
    Marpa/Evaluator.pm
    Marpa/Grammar.pm
    Marpa/Lex.pm
    Marpa/MDL.pm
    Marpa/Recognizer.pm
    Marpa/Doc/Algorithm.pod
    Marpa/Doc/Bibliography.pod
    Marpa/Doc/Diagnostics.pod
    Marpa/Doc/Internals.pod
    Marpa/Doc/MDL.pod
    Marpa/Doc/Plumbing.pod
    Marpa/Doc/To_Do.pod
);

my %link;

sub cb {
    my($tag, %links) = @_;
    return unless $tag eq "a";
    my $href = $links{href};
    return if $href =~ /^#/;
    $link{$href} = 1;
}

PAGE: for my $url (@url) {
    $url = $url_base . $url;

    my $p = HTML::LinkExtor->new(\&cb);
    my $ua = LWP::UserAgent->new;

    %link = ();
    # Request document and parse it as it arrives
    my $response = $ua->request(
	HTTP::Request->new( GET => $url),
	sub {$p->parse($_[0])}
    );

    say "PAGE: ", $response->status_line, " ", $url;
    next PAGE if $response->code != 200;

    LINK: for my $link (keys %link) {
	$link = 'http://search.cpan.org' . $link
	    if $link =~ m(^/);
	my $response = $ua->request(HTTP::Request->new(GET => $link));
	next LINK if $response->code == 200;
	say "LINK: ", $response->status_line, " ", $link;
    }

}
