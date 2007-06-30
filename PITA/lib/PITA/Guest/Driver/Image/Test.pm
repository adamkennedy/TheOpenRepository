package PITA::Guest::Driver::Image::Test;

use 5.005;
use strict;
use base 'PITA::Guest::Driver::Image';
use PITA::Image ();
use File::Spec::Functions ':ALL';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.30';
}

my $image_bin = catfile( 't', 'bin', 'pita-imagetest' );

sub support_server {
	my $self = shift;
	PITA::POE::SupportServer->new(
		execute => [
			$image_bin,
			'--injector',
			$self->injector_dir,
			],
		http_local_addr       => $self->support_server_addr,
		http_local_port       => $self->support_server_port,
		http_mirrors          => {},
		http_result           => $self->support_server_results,
		http_startup_timeout  => 30,
		http_activity_timeout => 60,
		http_shutdown_timeout => 30,
		) or die "Failed to create support server";		
}

1;
