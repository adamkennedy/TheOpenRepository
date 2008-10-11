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
	print CONFIG config()  or die "Failed to write letmein.conf";
	close CONFIG           or die "Failed to close letmein.conf";

	return $rv;
}

sub config {
	my $template_directory = default_template_directory();

	return <<"...";
---
# NOTE: You need to uncomment and edit the first three settings:

# The path to your htpasswd file. (required)
# htpasswd: /path/to/your/htpasswd

# The address that LetMeIn emails are from. (required)
# email_from: my.address\@example.com

# The type of email driver to use. (optional)
# Set to 'Sendmail' or 'SMTP'. 'Sendmail' is the default.
# email_driver: SMTP


# NOTE: The following settings are completely OPTIONAL, and are used for more
# advanced features. You can safely ignore them.

# Set to true (1) if you want to use the system installed LetMeIn.pm
# instead of the one embedded in the letmein program. You can also set
# this to the module name of the LetMeIn subclass you want to use.
# use_module: 1
# use_module: LetMeIn::Subclass

# The directory where your custom templates reside.
# template_directory: $template_directory

# The type of template syntax to use. ('simple' (default) or 'tt2')
# template_type: tt2

# Require a userid (in addition to an email address) from each user.
# require_userid: 1

# Store extra information in the htpasswd file as JSON. Requires JSON::XS.
# htpasswd_json: 1
...
}

sub default_template_directory {
        my $default = '/path/to/your/template/directory';

        eval "require File::ShareDir; 1"
                or return $default;

        my $base = File::ShareDir::dist_dir('LetMeIn')
                or return $default;

        my $path = File::Spec->catdir($base, 'template');

        return (-e $path)
        ? $path
        : $default;
}

1;
