package HTTP::Online;

use strict;

our $VERSION = '0.01';





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
