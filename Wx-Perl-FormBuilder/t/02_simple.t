#!/usr/bin/perl

use strict;
BEGIN {
	$| = 1;
	$^W = 1;
}

use Test::More tests => 12;
use Test::NoWarnings;
use Wx::Perl::FormBuilder;

# Find the sample file
my $file = File::Spec->catfile( 't', 'data', 'simple.fbp' );
ok( -f $file, "Found test file $file" );

# Load the sample file
my $fbp = FBP->new;
isa_ok( $fbp, 'FBP' );
ok( $fbp->parse_file($file), '->parse_file ok' );

# Create the generator object
my $project = $fbp->find_first(
	isa => 'FBP::Project',
);
my $code = Wx::Perl::FormBuilder->new(
	project => $project,
);
isa_ok( $project, 'FBP::Project' );
isa_ok( $code, 'Wx::Perl::FormBuilder' );

# Test button string generators
SCOPE: {
	my $button = $project->find_first( isa => 'FBP::Button' );
	isa_ok( $button, 'FBP::Button' );
	is(
		$code->object_lexical($button) => 0,
		'Button ->object_lexical ok',
	);
	is(
		$code->object_variable($button) => '$self->{m_button1}',
		'Button ->object_variable ok',
	);
	is(
		$code->object_label($button) => "Wx::gettext('MyButton')",
		'Button ->object_label ok',
	);
	my $new = $code->button_create($button);
	is( ref($new), 'ARRAY', '->button_create returns ARRAY' );
	is( join( '', map { "$_\n" } @$new ), <<'END_PERL', '->button_create ok' );
$self->{m_button1} = Wx::Button->new(
	$self,
	-1,
	Wx::gettext('MyButton'),
);
$self->{m_button1}->SetDefault;

Wx::Event::EVT_BUTTON(
	$self,
	$self->{m_button1},
	sub {
		shift->m_button1(@_);
	},
);
END_PERL
}
