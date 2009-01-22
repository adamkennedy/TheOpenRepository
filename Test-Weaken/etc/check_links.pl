use 5.010;
use strict;
use warnings;
use LWP::UserAgent;
use URI::URL;
use HTML::LinkExtor;
use English qw( -no_match_vars ) ;

my $cpan_base = 'http://search.cpan.org';
my $marpa_doc_base = $cpan_base . '/~jkegl/Test-Weaken-1.001_000/lib/Test/';

my @url = qw(
    Weaken.pm
);

my %link;

sub cb {
    my($tag, %links) = @_;
    return unless $tag eq "a";
    my $href = $links{href};
    return if $href =~ /^#/;
    $link{$href} = 1;
}

my %link_ok;

$OUTPUT_AUTOFLUSH = 1;

PAGE: for my $url (@url) {
    $url = $marpa_doc_base . $url;

    my $p = HTML::LinkExtor->new(\&cb);
    my $ua = LWP::UserAgent->new;

    %link = ();
    # Request document and parse it as it arrives
    my $response = $ua->request(
	HTTP::Request->new( GET => $url),
	sub {$p->parse($_[0])}
    );

    my $page_response_status_line = $response->status_line;
    if ($response->code != 200) {
        say "PAGE: ", $page_response_status_line, " ", $url;
        next PAGE;
    }

    LINK: for my $link (keys %link) {

	$link = 'http://search.cpan.org' . $link
	    if $link =~ m(^/);
        next LINK if $link_ok{$link};

	my $response = $ua->request(HTTP::Request->new(GET => $link));

	if ($response->code == 200) {
            $link_ok{$link} = 1;
            print ".";
            next LINK;
        }

	say "LINK: ", $response->status_line, " ", $link;

    }

    say " PAGE: $page_response_status_line: $url";

}
