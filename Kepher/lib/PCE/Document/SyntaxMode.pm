package PCE::Document::SyntaxMode;
$VERSION = '0.01';

use strict;
use Wx qw(
	wxSTC_LEX_NULL wxSTC_STYLE_DEFAULT
	wxSTC_STYLE_BRACELIGHT wxSTC_STYLE_BRACEBAD wxSTC_STYLE_INDENTGUIDE
);

# syntaxstyles
sub set {$PCE::document{'current'}{'syntaxmode'} = shift }
sub get {$PCE::document{'current'}{'syntaxmode'} 
	if exists $PCE::document{'current'}{'syntaxmode'}
}

sub _get_auto{ &_get_by_fileending }
sub _get_by_fileending {
	my $doc_nr = shift;
	$doc_nr = PCE::Document::_get_current_nr unless $doc_nr;
	my $file_ending = $PCE::internal{'document'}{'open'}[$doc_nr]{'ending'};
	my $language_id;
	chop $file_ending if $file_ending and (substr ($file_ending, -1) eq '~');
	if ($file_ending) {
		$language_id = $PCE::internal{'file'}{'end2langmap'}
				{ PCE::Document::_lc_utf($file_ending) };
	} else                                     { return "none" }
	if ( !$language_id  or $language_id eq '') { return "none" }
	elsif ( $language_id eq 'text' )           { return "none" }
	return $language_id;
}

sub change_to {
	my $ep     = PCE::App::STC::_get();
	my $style = shift;
	$style = _get_by_fileending() if $style eq 'auto';
	$style = 'none' unless $style;

	# prevent clash between big lexer & indicator
	if ( $style =~ /asp|html|php|xml/ ) { $ep->SetStyleBits(7) }
	else                                { $ep->SetStyleBits(5) }

	# clear style infos
	$ep->StyleClearAll;
	$ep->StyleResetDefault;
	PCE::App::STC::load_font();
	$ep->SetKeyWords( 0, '' );

	# load syntax style
	if ( $style eq 'none' ) { $ep->SetLexer(wxSTC_LEX_NULL) }
	else {
		eval("require syntaxhighlighter::$style");
		eval("syntaxhighlighter::$style" . '::load($ep)');
	}

	# restore bracelight, bracebadlight indentguide colors
	my $bracelight = \%{ $PCE::config{'editpanel'}{'indicator'}{'bracelight'} };
	if ( $bracelight->{'visible'} ) {
		$ep->StyleSetBold( wxSTC_STYLE_BRACELIGHT, 1 );
		$ep->StyleSetBold( wxSTC_STYLE_BRACEBAD,   1 );
		$ep->StyleSetForeground( wxSTC_STYLE_BRACELIGHT, Wx::Colour->new(
			@{ PCE::Config::_hex2dec_color_array( $bracelight->{'good_color'}
		)} ));
		$ep->StyleSetForeground( wxSTC_STYLE_BRACEBAD, Wx::Colour->new(
			@{ PCE::Config::_hex2dec_color_array( $bracelight->{'bad_color'}
		)} ));
		$ep->StyleSetForeground( wxSTC_STYLE_INDENTGUIDE, Wx::Colour->new(
			@{ PCE::Config::_hex2dec_color_array(
						$PCE::config{editpanel}{indicator}{indent_guide}{color}
		)} ));
	}

	# cleanup
	set($style);
	$ep->Colourise( 0, $ep->GetTextLength );# refreh editpanel painting
	PCE::App::EditPanel::Margin::apply_color();
	PCE::App::StatusBar::style_info($style);
	return $style;
}

sub change_to_auto    {change_to(_get_by_fileending())}
sub change_to_none    {change_to("none")}
sub change_to_ada     {change_to("ada")}
sub change_to_as      {change_to("as")}
sub change_to_asm     {change_to("asm")}
sub change_to_conf    {change_to("conf")}
sub change_to_context {change_to("context")}
sub change_to_cpp     {change_to("cpp")}
sub change_to_cs      {change_to("cs")}
sub change_to_css     {change_to("css")}
sub change_to_eiffel  {change_to("eiffel")}
sub change_to_forth   {change_to("forth")}
sub change_to_fortran {change_to("fortran")}
sub change_to_html    {change_to("html")}
sub change_to_idl     {change_to("idl")}
sub change_to_java    {change_to("java")}
sub change_to_js      {change_to("js")}
sub change_to_latex   {change_to("latex")}
sub change_to_lisp    {change_to("lisp")}
sub change_to_lua     {change_to("lua")}
sub change_to_nsis    {change_to("nsis")}
sub change_to_pascal  {change_to("pascal")}
sub change_to_perl    {change_to("perl")}
sub change_to_php     {change_to("php")}
sub change_to_ps      {change_to("ps")}
sub change_to_python  {change_to("python")}
sub change_to_ruby    {change_to("ruby")}
sub change_to_scheme  {change_to("scheme")}
sub change_to_sh      {change_to("sh")}
sub change_to_sql     {change_to("sql")}
sub change_to_tcl     {change_to("tcl")}
sub change_to_tex     {change_to("tex")}
sub change_to_vb      {change_to("vb")}
sub change_to_vbs     {change_to("vbs")}
sub change_to_xml     {change_to("xml")}
sub change_to_yaml    {change_to("yaml")}

1;