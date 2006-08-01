package Kepher::App::STC;
$VERSION = '0.18';

use strict;
use constant APPROOT => 'editpanel';
use constant CFGROOT => 'editpanel';
#use base qw(Wx::Panel);    #Kepher::Dialog::msg_box(undef,$fr,"");
use Wx qw(wxDEFAULT wxNORMAL wxDefaultPosition wxDefaultSize
	wxBOTTOM wxRED wxBLUE wxLIGHT_GREY wxBLACK wxLIGHT wxBOLD wxSLANT wxITALIC
	wxSTC_EDGE_NONE wxSTC_EDGE_LINE wxSTC_WRAP_NONE wxSTC_WRAP_WORD
	wxSTC_CACHE_PAGE wxSTC_SEL_RECTANGLE
	wxSTC_FOLDLEVELHEADERFLAG wxSTC_MASK_FOLDERS wxSTC_MARGIN_NUMBER
	wxSTC_STYLE_DEFAULT wxSTC_STYLE_CONTROLCHAR wxSTC_STYLE_INDENTGUIDE
);
# wxSTC_WS_INVISIBLE wxSTC_WS_VISIBLEALWAYS
#use Wx::STC qw(wxSTC_CP_UTF8 wxSTC_CP_UTF16);
#$ep->GetSelectionMode; #SetSTCFocus(focus)


sub _get { Kepher::App::EditPanel::_get() } # -DEP

sub _get_config { $Kepher::config{(CFGROOT)} }


sub apply_settings {
	my $ep       = _get();
	$ep = Kepher::App::EditPanel::_create() unless $ep;
	my $conf     = $Kepher::config{(CFGROOT)};
	my $indicator= $conf->{'indicator'};
	$Kepher::internal{'edit'}{'caret'}{'positions'} = ();

	# text visuals: font whitespaces EOL
	load_font();
	load_view_whitespace();
	$ep->SetWhitespaceForeground(1, Wx::Colour->new(
		@{_scan2dec_color_array( $indicator->{'whitespace'}{'color'} )} ));
	load_view_EOL();

	# indicators: caret, selection, ...
	$ep->SetCaretLineBack( Wx::Colour->new(
			@{ _scan2dec_color_array( $indicator->{'caret_line'}{'color'} ) } )
	);
	$ep->SetCaretPeriod( $indicator->{'caret'}{'period'} );
	$ep->SetCaretWidth( $indicator->{'caret'}{'width'} );
	$ep->SetCaretForeground( Wx::Colour->new(
		@{_scan2dec_color_array( $indicator->{'caret'}{'color'} ) } )
	);
	if ( $indicator->{'selection'}{'fore_color'} ne '-1' ) {
		$ep->SetSelForeground( 1, Wx::Colour->new(
			@{_scan2dec_color_array( $indicator->{'selection'}{'fore_color'} )} )
		);
	}
	$ep->SetSelBackground( 1, Wx::Colour->new(
		@{_scan2dec_color_array($indicator->{'selection'}{'back_color'} )} ));
	set_LLI();
	load_view_caret_line();
	load_view_indention_guide();

	Kepher::App::EditPanel::Margin::apply_settings();

	#folding
	#$ep->SetEdgeColumn(100);
	# $ep->SetFoldFlags(16);
	$ep->SetMarginMask( 2, wxSTC_MASK_FOLDERS );

	#$ep->SetMarginSensitive(0, 1);
	$ep->SetMarginSensitive( 2, 1 );

	#misc: scroll width, codepage, wordcharss
	load_view_autowrap();

#$ep->StyleSetForeground (wxSTC_STYLE_CONTROLCHAR, Wx::Colour->new(0x55, 0x55, 0x55));
#$ep->StyleSetBackground (wxSTC_STYLE_CONTROLCHAR, Wx::Colour->new(0xff, 0xff, 0xff));
#$ep->SetScrollWidth($Kepher::config{'editpanel'}{'scroll_width'}); #defaultbreite
	$ep->SetScrollWidth( $ep->GetEndAtLastLine() );
	$ep->SetCodePage(0);    #wxSTC_CP_UTF8 Wx::wxUNICODE()
	$ep->SetWordChars( $conf->{'word_chars'} );

	#interna
	$ep->SetLayoutCache(wxSTC_CACHE_PAGE);
	$ep->SetBufferedDraw(1);

	#hilfe
	#  $ep->CallTipShow(3,"testtooltip\n next line"); #tips
	#  $ep->SetSelectionMode(wxSTC_SEL_RECTANGLE); #rect selection
	Kepher::Edit::eval_newline_sub();
	Kepher::App::EditPanel::apply_bracelight_settings();
}


sub set_tab_size {
	my $ep = &_get;
	my $size      = shift;
	$ep->SetTabWidth($size);
	$ep->SetIndent($size);
	$ep->SetHighlightGuide($size);
}

#
# indicators
sub set_LLI {
	my $ep = &_get;
	my $config = \%{$Kepher::config{editpanel}{indicator}{right_margin}};

	$ep->SetEdgeColour(
		Wx::Colour->new( @{_scan2dec_color_array( $config->{color} )} ) );
	$ep->SetEdgeColumn( $config->{position} );
	&load_LLI;
}
sub load_LLI {
	_get->SetEdgeMode(
		$Kepher::config{(CFGROOT)}{'indicator'}{'right_margin'}{'style'} );
}
sub switch_view_LLI {
	my $config = $Kepher::config{(CFGROOT)}{'indicator'}{'right_margin'};
	if ( &_get->GetEdgeMode == wxSTC_EDGE_NONE ) {
			$config->{'style'} = wxSTC_EDGE_LINE
	} else { $config->{'style'}= wxSTC_EDGE_NONE }
	&load_LLI;
}
sub get_view_LLI { 
	$Kepher::config{(CFGROOT)}{indicator}{right_margin}{style} == wxSTC_EDGE_LINE
}


sub get_view_indention_guide { 
	$Kepher::config{(CFGROOT)}{'indicator'}{'indent_guide'}{'visible'}
}
sub load_view_indention_guide {
	_get->SetIndentationGuides(
		$Kepher::config{(CFGROOT)}{'indicator'}{'indent_guide'}{'visible'} );
}
sub switch_view_IG {
	$Kepher::config{(CFGROOT)}{'indicator'}{'indent_guide'}{'visible'} ^= 1;
	load_view_indention_guide();
}


sub get_view_caret_line { 
	$Kepher::config{(CFGROOT)}{'indicator'}{'caret_line'}{'visible'}
}
sub load_view_caret_line {
	_get()->SetCaretLineVisible(
		$Kepher::config{(CFGROOT)}{'indicator'}{'caret_line'}{'visible'} );
}
sub switch_view_caret_line {
	$Kepher::config{(CFGROOT)}{'indicator'}{'caret_line'}{'visible'} ^= 1;
	&load_view_caret_line;
}


sub load_view_autowrap {
	_get()->SetWrapMode( $Kepher::config{(CFGROOT)}{'line_wrap'} );
	Kepher::App::EventList::trigger('editpanel.autowrap');

}
sub get_view_autowrap { $Kepher::config{(CFGROOT)}{'line_wrap'} == wxSTC_WRAP_WORD}
sub switch_view_autowrap {
	if ($Kepher::config{(CFGROOT)}{'line_wrap'} == wxSTC_WRAP_WORD) {
		$Kepher::config{(CFGROOT)}{'line_wrap'} = wxSTC_WRAP_NONE
	} else {$Kepher::config{(CFGROOT)}{'line_wrap'} = wxSTC_WRAP_WORD}
	&load_view_autowrap;
}

sub load_view_EOL {
	_get()->SetViewEOL($Kepher::config{editpanel}{indicator}{end_of_line_marker} );
}

sub switch_view_EOL {
	$Kepher::config{editpanel}{indicator}{end_of_line_marker} ^= 1;
	&load_view_EOL;
}

#
# textstyle font
sub get_view_whitespace {$Kepher::config{editpanel}{indicator}{whitespace}{visible}}
sub load_view_whitespace {
	_get()->SetViewWhiteSpace(
			$Kepher::config{editpanel}{indicator}{whitespace}{visible} );
}

sub switch_view_whitespace {
	$Kepher::config{editpanel}{indicator}{whitespace}{visible} ^= 1;
	load_view_whitespace();
	return $Kepher::config{editpanel}{indicator}{whitespace}{visible};
}

sub load_font {
	my $ep = _get();
	my ( $fontweight, $fontstyle ) = ( wxNORMAL, wxNORMAL );
	my $font = $Kepher::config{(CFGROOT)}{'font'};
	$fontweight = wxLIGHT  if $font->{'weight'} eq 'light';
	$fontweight = wxBOLD   if $font->{'weight'} eq 'bold';
	$fontstyle  = wxSLANT  if $font->{'style'}  eq 'slant';
	$fontstyle  = wxITALIC if $font->{'style'}  eq 'italic';
	my $wx_font = Wx::Font->new( $font->{'size'}, wxDEFAULT, 
		$fontstyle, $fontweight, 0, $font->{'family'} );
	$ep->StyleSetFont( wxSTC_STYLE_DEFAULT, $wx_font ) if $wx_font->Ok > 0;
}

sub change_font {
	my ( $fontweight, $fontstyle ) = ( wxNORMAL, wxNORMAL );
	my $font_config = $Kepher::config{(CFGROOT)}{'font'};
	$fontweight = wxLIGHT  if ( $$font_config{'weight'} eq 'light' );
	$fontweight = wxBOLD   if ( $$font_config{'weight'} eq 'bold' );
	$fontstyle  = wxSLANT  if ( $$font_config{'style'}  eq 'slant' );
	$fontstyle  = wxITALIC if ( $$font_config{'style'}  eq 'italic' );
	my $oldfont = Wx::Font->new( $$font_config{'size'}, wxDEFAULT, $fontstyle,
		$fontweight, 0, $$font_config{'family'} );
	my $newfont = Kepher::Dialog::get_font( Kepher::App::Window::_get(), $oldfont );

	if ( $newfont->Ok > 0 ) {
		($fontweight, $fontstyle) = ($newfont->GetWeight, $newfont->GetStyle);
		$$font_config{'size'}   = $newfont->GetPointSize;
		$$font_config{'family'} = $newfont->GetFaceName;
		$$font_config{'weight'} = 'normal';
		$$font_config{'weight'} = 'light' if $fontweight == wxLIGHT;
		$$font_config{'weight'} = 'bold' if $fontweight == wxBOLD;
		$$font_config{'style'}  = 'normal';
		$$font_config{'style'}  = 'slant' if $fontstyle == wxSLANT;
		$$font_config{'style'}  = 'italic' if $fontstyle == wxITALIC;
		&load_font;
		Kepher::Document::SyntaxMode::reload();
		Kepher::App::EditPanel::Margin::apply_line_number_width();
	}
}

sub _scan2dec_color_array {
	my $color  = shift;
	my @values = (
		hex( substr( $color, 0, 2 ) ),
		hex( substr( $color, 2, 2 ) ),
		hex( substr( $color, 4, 2 ) )
	);
	#split /,/, $color; #if ($#values == 0) {@values =
	return \@values;
}


1;
