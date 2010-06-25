#!/usr/bin/perl

use strict;
BEGIN {
	$| = 1;
	$^W = 1;
}

use Test::More tests => 22;
use Test::NoWarnings;
use FBP::Perl;

sub code {
	my $left    = shift;
	my $right   = shift;
	if ( ref $left ) {
		$left = join '', map { "$_\n" } @$left;
	}
	if ( ref $right ) {
		$right = join '', map { "$_\n" } @$right;
	}
	is( $left, $right, $_[0] );
}

sub compiles {
	my $code = shift;
	if ( ref $code ) {
		$code = join '', map { "$_\n" } @$code;
	}
	my $rv = eval $code;
	diag( $@ ) if $@;
	ok( $rv, $_[0] );
}

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
my $code = FBP::Perl->new(
	project => $project,
);
isa_ok( $project, 'FBP::Project' );
isa_ok( $code, 'FBP::Perl' );

# Test Button string generators
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
	code( $new, <<'END_PERL', '->button_create ok' );
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

# Test StaticText string generators
SCOPE: {
	my $static = $project->find_first( isa => 'FBP::StaticText' );
	isa_ok( $static, 'FBP::StaticText' );
	my $new = $code->statictext_create($static);
	code( $new, <<'END_PERL', '->statictext ok' );
my $m_staticText1 = Wx::StaticText->new(
	$self,
	-1,
	Wx::gettext('This is a test'),
);
END_PERL
}

# Test StaticLine string generators
SCOPE: {
	my $line = $project->find_first( isa => 'FBP::StaticLine' );
	isa_ok( $line, 'FBP::StaticLine' );
	my $new = $code->staticline_create($line);
	code( $new, <<'END_PERL', '->staticline ok' );
my $m_staticline1 = Wx::StaticLine->new(
	$self,
	-1,
	Wx::wxDefaultPosition,
	Wx::wxDefaultSize,
);
END_PERL
}

# Test BoxSizer string generators
SCOPE: {
	my $sizer = $project->find_first( isa => 'FBP::BoxSizer' );
	isa_ok( $sizer, 'FBP::BoxSizer' );
	is(
		$code->object_lexical($sizer) => 1,
		'BoxSizer ->object_lexical ok',
	);
	my $new = $code->boxsizer_create($sizer);
	code( $new, <<'END_PERL', '->boxsizer_create ok' );
my $bSizer2 = Wx::BoxSizer->new( Wx::wxVERTICAL );
$bSizer2->Add( $m_staticText1, 0, Wx::wxALL, 5 );
$bSizer2->Add( $m_staticline1, 0, Wx::wxEXPAND | Wx::wxALL, 5 );
$bSizer2->Add( $self->{m_button1}, 0, Wx::wxALL, 5 );

my $bSizer1 = Wx::BoxSizer->new( Wx::wxHORIZONTAL );
$bSizer1->Add( $bSizer2, 1, Wx::wxEXPAND, 5 );
END_PERL
}

# Test Dialog string generators
SCOPE: {
	my $dialog = $project->find_first( isa => 'FBP::Dialog' );
	isa_ok( $dialog, 'FBP::Dialog' );

	# Generate the entire dialog constructor
	my $class = $code->dialog_class($dialog);
	code( $class, <<'END_PERL', '->dialog_super ok' );
package MyDialog1;

use 5.008;
use strict;
use warnings;
use Wx ':everything';

our $VERSION = '0.01';
our @ISA     = 'Wx::Dialog';

sub new {
	my $class  = shift;
	my $parent = shift;

	my $self = $class->SUPER::new(
		$parent,
		-1,
		'',
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxDEFAULT_DIALOG_STYLE,
	);

	my $m_staticText1 = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext('This is a test'),
	);

	my $m_staticline1 = Wx::StaticLine->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);

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

	my $bSizer2 = Wx::BoxSizer->new( Wx::wxVERTICAL );
	$bSizer2->Add( $m_staticText1, 0, Wx::wxALL, 5 );
	$bSizer2->Add( $m_staticline1, 0, Wx::wxEXPAND | Wx::wxALL, 5 );
	$bSizer2->Add( $self->{m_button1}, 0, Wx::wxALL, 5 );

	my $bSizer1 = Wx::BoxSizer->new( Wx::wxHORIZONTAL );
	$bSizer1->Add( $bSizer2, 1, Wx::wxEXPAND, 5 );

	$self->SetSizer($bSizer1);
	$bSizer1->SetSizeHints($self);

	return $self;
}

sub m_button1 {
	my $self  = shift;
	my $event = shift;

	die 'TO BE COMPLETED';
}

1;
END_PERL

	compiles( $class, 'Dialog class compiled' );
}
