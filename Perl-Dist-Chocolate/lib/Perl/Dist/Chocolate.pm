package Perl::Dist::Chocolate;

=pod

=head1 NAME

Perl::Dist::Chocolate - The "Strawberry Perl Professional" distribution.

=head1 DESCRIPTION

This is the distribution builder used to create Strawberry Perl Professional 
(formerly called Chocolate Perl)

=head1 Building

Unlike Strawberry Perl, this does not have a standalone build script.

To build Strawberry Perl Professional, run the following.

  perldist Chocolate

=cut

use 5.008001;
use strict;
use warnings;
use parent                  qw( Perl::Dist::Strawberry );
use File::Spec::Functions   qw( catfile catdir         );
use File::ShareDir          qw();

our $VERSION = '2.02';
$VERSION = eval $VERSION;





#####################################################################
# Configuration

# Apply some default paths
sub new {

	if ($Perl::Dist::Strawberry::VERSION < 2.00_02) {
		PDWiX->throw('Perl::Dist::Strawberry version is not high enough.')
	}

	shift->SUPER::new(
		app_id            => 'chocolate',
		app_name          => 'Strawberry Perl Professional',
		app_publisher     => 'Vanilla Perl Project',
		app_publisher_url => 'http://vanillaperl.org/',
		image_dir         => 'C:\\strawberry',

		# Tasks to complete to create Chocolate
		tasklist => [
			'final_initialization',
			'install_c_toolchain',
			'install_strawberry_c_toolchain',
			'install_c_libraries',
			'install_strawberry_c_libraries',
			'install_perl',
			'install_perl_toolchain',
			'install_cpan_upgrades',
			'install_strawberry_modules_1',
			'install_strawberry_modules_2',
			'install_strawberry_modules_3',
			'install_strawberry_modules_4',
			'install_padre_prereq_modules_1',
			'install_padre_prereq_modules_2',
			'install_padre_modules',
			'install_satori_modules_1',
			'install_satori_modules_2',
			'install_satori_modules_3',
			'install_satori_modules_4',
			'install_other_modules_4',
			'install_win32_extras',
			'install_strawberry_extras',
			'install_chocolate_extras',
			'remove_waste',
			'add_forgotten_files',
			'create_distribution_list',
			'regenerate_fragments',
			'write',
		],

		# Build msi and zip versions.
		msi               => 1,
		zip               => 1,

		@_,
	);
}

# Lazily default the file name
# Supports building multiple versions of Perl.
sub output_base_filename {
	$_[0]->{output_base_filename} or
	'strawberry-perl-' . $_[0]->perl_version_human 
	. '.' . $_[0]->build_number
	. ($_[0]->beta_number ? '-beta-' . $_[0]->beta_number : '');
}






#####################################################################
# Customisations for Perl assets

sub patch_include_path {
	my $self  = shift;

	# Find the share path for this distribution
	my $share = File::ShareDir::dist_dir('Perl-Dist-Chocolate');
	my $path  = catdir( $share, 'chocolate' );
	unless ( -d $path ) {
		PDWiX->throw("Directory $path does not exist");
	}

	# Prepend it to the default include path
	return [ $path,
		@{ $self->SUPER::patch_include_path },
	];
}

sub install_padre_prereq_modules_1 {
	my $self = shift;

	# Manually install our non-Wx dependencies first to isolate
	# them from the Wx problems
	$self->install_modules( qw{
		  File::Glob::Windows
		  File::Next
		  App::Ack
		  Class::Adapter
		  Class::Inspector
		  Class::Unload
		  AutoXS::Header
		  Class::XSAccessor
		  Devel::Dumpvar
		  File::Copy::Recursive
		  File::ShareDir
		  File::ShareDir::PAR
		  Test::Object
		  Config::Tiny
		  Test::ClassAPI
		  Clone
		  Hook::LexWrap
	} );

	return 1;
}


sub install_padre_prereq_modules_2 {
	my $self = shift;

	# Manually install our non-Wx dependencies first to isolate
	# them from the Wx problems
	$self->install_modules( qw{
		  Test::SubCalls
		  List::MoreUtils
		  Task::Weaken
		  PPI
		  Module::Refresh
		  Devel::Symdump
		  Pod::Coverage
		  Test::Pod::Coverage
		  Test::Pod
		  Module::Starter
		  ORLite
		  ORLite::Migrate
		  Algorithm::Diff
		  Text::Diff
		  Test::Differences
		  File::Slurp
		  Pod::POM
		  Parse::ErrorString::Perl
		  Text::FindIndent
		  Pod::Abstract
		  Devel::StackTrace
		  Class::Data::Inheritable
		  Exception::Class
		  Test::Exception
		  Test::Most
		  Class::XSAccessor::Array
		  Parse::ExuberantCTags
		  CPAN::Mini
		  Win32API::File
		  Capture::Tiny
		  prefork
		  PPIx::EditorTools
		  Spiffy
		  Test::Base
		  ExtUtils::XSpp
		  Locale::Msgfmt
	} );

# Does Padre still need Portable? If so, put it after CPAN::Mini.

	return 1;
}
	
sub install_padre_modules {
	my $self = shift;

	# The rest of the modules are order-specific,
	# for reasons maybe involving CPAN.pm but not fully understodd.

	# Install the Alien module
	if ( defined $ENV{PERL_DIST_PADRE_ALIENWXWIDGETS_PAR_LOCATION} ) {
		my $filelist = $self->install_par(
			name => 'Alien_wxWidgets',
			url  => URI::file->new(
				$ENV{PERL_DIST_PADRE_ALIENWXWIDGETS_PAR_LOCATION}
			  )->as_string(),
		);
	} else {
		$self->install_module( name => 'Alien::wxWidgets' );
	}

	# Install the Wx module over the top of alien module
	$self->install_module( name => 'Wx' );

	# Install modules that add more Wx functionality
	$self->install_module( 
		name => 'Wx::Perl::ProcessStream',
		force => 1 # since it fails on vista
	);

	# And finally, install Padre itself
	$self->install_module(
		name  => 'Padre',
		force => 1,
	);

	return 1;
} ## end sub install_padre_modules

sub install_satori_modules_1 {
	my $self = shift;

	# Basic Toolchain is already installed in Strawberry.
	
	# Testing prerequisites.
	$self->install_modules( qw{	
		PadWalker
		Devel::Cycle
	} );
	
	# Testing: Test::Simple is already installed in Strawberry.
	# Test::Exception and Test::Most are above.
	# Test::Pod and Test::Pod::Coverage are also above.
	$self->install_modules( qw{
		Test::Memory::Cycle
	} );

	# Config Modules and prerequisites
	$self->install_modules( qw{
		JSON::Syck
		Config::General
		Config::Any
	} );

	# Object Oriented Programming
	
	# Moose and prerequisites
	$self->install_modules( qw{
		Algorithm::C3
		Class::C3
		MRO::Compat
		Sub::Install
		Data::OptList
		Sub::Exporter
		Scope::Guard
		Devel::GlobalDestruction
		Sub::Name
		Class::MOP
		Try::Tiny
		Moose
	} );
	
	# Other Object Oriented Programming prereqs.
	$self->install_modules( qw{
		autobox
		Perl6::Junction
		Path::Class
		Test::use::ok
		Params::Validate
		Getopt::Long::Descriptive
		Variable::Magic
		B::Hooks::EndOfScope
		namespace::clean
		Carp::Clan
		MooseX::Types
		MooseX::Types::Path::Class
		MooseX::ConfigFromFile
	} );
	
	# File::NFSLock fails tests. 
	# Considering the name, should this really
	# be required by Temp::TempDir on Win32?
	$self->install_module(
		name => 'File::NFSLock',
		force => 1,
	);
	$self->install_modules( qw{
		Test::TempDir
		Best
		JSON::Any
		Test::JSON
		Test::YAML::Valid
	} );
	
	# Object Oriented Programming (MooseX::Types needs to be before Test::TempDir.)
	$self->install_modules( qw{
		Moose::Autobox
		MooseX::AttributeHelpers
		MooseX::Storage
		MooseX::Getopt
		MooseX::SimpleConfig
		MooseX::StrictConstructor
		namespace::autoclean
	} );

	return 1;
}
	
sub install_satori_modules_2 {
	my $self = shift;

	# XML development prerequisites
	$self->install_modules( qw{
		XML::Filter::BufferText
		Text::Iconv
	} );

	# XML Development: XML::LibXML and XML::SAX are already installed.
	$self->install_modules( qw{
		XML::Generator::PerlData
		XML::SAX::Writer
	} );

	# Module Development prerequisites
	$self->install_modules( qw{
		Regexp::Common
		Pod::Readme
		Data::Section
		Text::Template
		Software::License
		Module::ScanDeps
		File::Slurp
	} );
	
	# Module Development
	$self->install_modules( qw{
		Module::Starter
		Module::Starter::CSJEWELL
		Module::Install
		Devel::NYTProf
		Perl::Tidy
		Carp::Always
		Modern::Perl
		Perl::Version
	} );

	# Database Development: DBI and DBD::SQLite are already installed.
	# Because of the large numbers of prerequisites, I'm
	# doing this one module at a time.
	
	# DBIx::Class and prerequisites.
	$self->install_modules( qw{
		Sub::Identify
		Class::Inspector
		Class::Accessor::Grouped
		Clone
		SQL::Abstract
		SQL::Abstract::Limit
		Class::Accessor
		Class::Accessor::Chained::Fast
		Data::Page
		Class::C3::Componentised
		Module::Find
		DBIx::Class
	} );

	return 1;
}
	
sub install_satori_modules_3 {
	my $self = shift;

	# SQL::Translator and prerequisites
	$self->install_modules( qw{
		Class::Base
		Parse::RecDescent
		Class::MakeMethods
		XML::Writer
		File::ShareDir
		SQL::Translator
	} );

	# DBIx::Class::Schema::Loader and prereqs
	# Note: DBD::Oracle and DBD::DB2 you're 
	# on your own for.
	$self->install_modules( qw{
		Lingua::EN::Inflect
		Lingua::EN::Inflect::Number
		Class::Data::Accessor
		UNIVERSAL::require
		Data::Dump
		DBIx::Class::Schema::Loader
	} );

	# Web Development

	# Catalyst::Runtime and prerequisites
	$self->install_modules( qw{
		Text::SimpleTable
		Class::C3::Adopt::NEXT
		MooseX::MethodAttributes::Inheritable
		HTTP::Request::AsCGI
		Tree::Simple
		String::RewritePrefix
		Tree::Simple::Visitor::FindByPath
		CGI::Simple::Cookie
		HTTP::Body
		MooseX::Emulate::Class::Accessor::Fast
		Catalyst::Runtime
	} );
		
	# Catalyst::Devel and prerequisites
	$self->install_modules( qw{
		MIME::Types
		Catalyst::Plugin::Static::Simple
		Devel::Caller
		MooseX::Params::Validate
		MooseX::SemiAffordanceAccessor
		File::ChangeNotify
		UNIVERSAL::isa
		UNIVERSAL::can
		Test::MockObject
		Tie::ToObject
		Data::Visitor
		Catalyst::Action::RenderView
		File::Copy::Recursive
		AppConfig
		Template
		Mouse
		Any::Moose
		Catalyst::Plugin::ConfigLoader
		Proc::Background
		Catalyst::Devel
	} );

	return 1;
}
	
sub install_satori_modules_4 {
	my $self = shift;
	
	# Prerequisites for the rest of web development
	$self->install_modules( qw{
		Template::Timer
		Tie::IxHash
		MooseX::Traits::Pluggable
		CatalystX::Component::Traits
		Error
		Cache::FileCache
		DBIx::Class::Cursor::Cached
		Hash::Merge
		Object::Signature
	} );

	# The rest of Web Development
	$self->install_modules( qw{
		Catalyst::View::TT
		Catalyst::Model::DBIC::Schema
		Catalyst::Plugin::Session
		Catalyst::Plugin::Authentication
		Catalyst::Plugin::StackTrace
	} );

	# Web Crawling and prereqs: LWP::Simple and everything 
	# in Bundle::LWP are already installed.
	# WWW::Mechanize is forced because the back test fails on the 
	# '404 check' test if the firewall is too severe.
	$self->install_module( name => 'HTTP::Server::Simple', );
	$self->install_module( name => 'WWW::Mechanize', force => 1, );
	
	# Date Modules prerequisites
	$self->install_modules( qw{
		Class::Singleton
		DateTime::TimeZone
		DateTime::Locale
	} );

	# Date Modules
	$self->install_modules( qw{
		DateTime
		Date::Tiny
	} );

	# Time::y2038 fails to build on Strawberry. 
	# It's a Strawberry bug, not a bug of the module.
	# Fix before January 2010 Chocolate release.
	
	# Localizing changes to environment for building purposes.
	{
		local $ENV{TZ} = 'PST8PDT';
		$self->install_module( name => 'Time::ParseDate' );
	}
	
	# Useful Command-line Tools prerequisites
	$self->install_modules( qw{
		File::Next
		MooseX::Object::Pluggable
		ExtUtils::Depends
		B::Utils
		Data::Dump::Streamer
		Devel::LexAlias
		Lexical::Persistence
		Test::Object
		B::Keywords
		WWW::Pastebin::PastebinCom::Create
		WWW::Pastebin::RafbNet::Create
		Win32::Clipboard
		Spiffy
		Clipboard
		Mixin::Linewise
		Config::INI::Reader
		App::Nopaste
		Module::Refresh
	} );

	# Useful Command-line Tools: Module::CoreList is 
	# already installed by Strawberry, and App::Ack 
	# is above.
	$self->install_modules( qw{
		Devel::REPL
	} );

	# Script Hackery prerequisites
	$self->install_modules( qw{
		File::ReadBackwards
		MLDBM
	} );

	# Script Hackery
	$self->install_modules( qw{
		Smart::Comments
		IO::All
	} );

	# Socket6 would be nice to include, but it 
	# doesn't build due to referring to ws2_32.lib 
	# directly. A patch will be offered.
	
	# Asynchronous Programming and prerequisites
	$self->install_modules( qw{
		Win32::Console
		POE::Test::Loops
		POE
	} );

	return 1;
}
	
sub install_other_modules_1 {
	my $self = shift;

	$self->install_modules( qw{
		Perl::Critic
		Perl::Critic::More
	} ); # 185

	return 1;
}

	
	
1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-Chocolate>

Please note that B<only> bugs in the distribution itself or the CPAN
configuration should be reported to RT. Bugs in individual modules
should be reported to their respective distributions.

For more support information and places for discussion, see the
Strawberry Perl Support page L<http://strawberryperl.com/support.html>.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 - 2009 Adam Kennedy.  Copyright 2009 Curtis Jewell.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
