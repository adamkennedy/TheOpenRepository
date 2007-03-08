use strict;
use inc::Module::Install;

name         'Task-TWiki';
all_from     'lib/Task/TWiki.pm';



### Required programs
# requires_external_bin 'rcs';  # TWiki embeds rcs, so do we need this?
requires_external_bin 'diff';
requires_external_bin 'fgrep';
requires_external_bin 'egrep';
if ( $^O eq 'MSWin32' ) {
	# Dunno what to do about Win32,
	# but apparently it's not cron...
} else {
	# requires_external_bin 'cron'; Because generally a root-only thing,
	#                               this can't be detected unless Makefile.PL
	#                               is also done as root... hmm...
}
# requires_external_bin 'apache' # Yeah right :) So what instead...



### Requires modules
requires 'Algorithm::Diff' => 0;
requires 'CGI::Carp'       => '1.26';
requires 'Config'          => 0;
requires 'Cwd'             => '3.05';
requires 'Data::Dumper'    => '2.121';
requires 'Error'           => 0;
requires 'File::Copy'      => '2.06';
requires 'File::Find'      => '1.05';
requires 'File::Spec'      => '3.05';
requires 'FileHandle'      => '2.01';
requires 'IO::File'        => '1.10';
requires 'Text::Diff'      => 0;
requires 'Time::Local'     => '1.11';




### Optional modules
feature( 'Session Support',
	-default       => 1,
	'CGI::Cookie'  => '1.24',
	'CGI::Session' => '3.95',
);
requires 'Digest::base' => 0; # Dun't know why
requires 'Digest::SHA1' => 0; # Don't know why

# I18N support
if ( $^V >= 5.008 ) {
	feature( 'Internationalisation (I18N) Support',
		-default                    => 1,
		'Locale::Maketext::Lexicon' => 0,
	);
} else {
	feature( 'Internationalisation (I18N) Support',
		-default                    => 1,
		'Jcode'                     => 0,
		'Locale::Maketext::Lexicon' => 0,
		'Unicode::Map'              => 0,
		'Unicode::Map8'             => 0,
		'Unicode::MapUTF8'          => 0,
		'Unicode::String'           => 0,
	);
}

# Now that there's mail-confirmations for accounts,
# we probably want this always.
requires 'Net::SMTP';

# Only used for configuration, but make it compulsory
requires 'URI'             => 0;



### Installation commands
auto_install;
WriteAll;
