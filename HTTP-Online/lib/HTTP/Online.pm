package HTTP::Online;

=pod

=head1 NAME

HTTP::Online - Detect full "Internet" (HTTP) access using Microsoft NCSI

=head1 SYNOPSIS

    if ( HTTP::Online->new->online ) {
        print "Confirmed internet connection\n";
    } else {
        print "Internet is not available\n";
        exit(0);
    }
    
    # Now do your task that needs the internet...

=head1 DESCRIPTION

B<HTTP::Online> is a port of the older L<LWP::Online> module to L<HTTP::Tiny>
that uses only the (most accurate)
L<Microsoft NCSI|http://technet.microsoft.com/en-us/library/cc766017.aspx>
methodology.

=head1 METHODS

=cut

use 5.006;
use strict;
use HTTP::Tiny ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Apply defaults
	unless ( defined $self->{http} ) {
		$self->{http} = HTTP::Tiny->new(
			agent => "HTTP::Online/$VERSION",
		);
	}
	unless ( defined $self->{url} ) {
		$self->{url} = 'http://www.msftncsi.com/ncsi.txt';
	}
	unless ( defined $self->{content} ) {
		$self->{content} = 'Microsoft NCSI';
	}

	return $self;
}

sub http {
	$_[0]->{http};
}

sub url {
	$_[0]->{url};
}

sub content {
	$_[0]->{content};
}





######################################################################
# Main Methods

sub online {
	my $self     = shift;
	my $response = $self->http->get( $self->url, {
		headers => {
			Pragma => 'no-cache',
		},
	} );

	return (
		$response
		and
		$response->{success}
		and
		$response->{url} eq $self->url
		and
		$response->{content} eq $self->content
	);
}

sub offline {
	not $_[0]->online;
}

1;

=pod

=head1 SEE ALSO

L<LWP::Online>

L<HTTP::Tiny>

L<http://technet.microsoft.com/en-us/library/cc766017.aspx>

=cut
