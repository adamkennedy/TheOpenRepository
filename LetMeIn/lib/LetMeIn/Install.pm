package LetMeIn::Install;

use 5.005;
use strict;
use base 'Module::CGI::Install';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.98';
}

sub prepare {
	my $self = shift;

	# Add the files to install
	$self->add_script('LetMeIn', 'letmein');

	# Hand off to the parent class
	return $self->SUPER::prepare(@_);
}

sub run {
	my $self = shift;

	# Install the script/lib files
	my $rv = $self->SUPER::run;

	# Create the default config file
	my $to = $self->cgi_map->catfile('letmein.conf')->path;
	open( CONFIG, ">$to" ) or die "Failed to open letmein.conf";
	print CONFIG <<'...'   or die "Failed to write letmein.conf";
---
# The address that LetMeIn emails are from. (required)
# email_from: adamk@example.com

# The type of email driver to use. (SMTP or Sendmail) (required)
# email_driver: SMTP

# The path to your htpasswd file. (required)
# htpasswd: /path/to/your/htpasswd

# Set to true if you want to use the system installed LetMeIn.pm
# instead of the one embedded in the letmein program. (optional; advanced)
# use_module: 1
...
	close CONFIG           or die "Failed to close letmein.conf";

	return $rv;
}

1;
