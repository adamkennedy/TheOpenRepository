package Kepher::Document;
$VERSION = '0.37';

# changing properties to current document
use strict;
use Wx qw(
	wxSTC_EOL_CR wxSTC_EOL_LF wxSTC_EOL_CRLF
	wxSTC_STYLE_CONTROLCHAR
);

# internal functions
# doc number
sub _get_count { @{ $Kepher::document{'open'} } }
sub _get_previous_nr{ $Kepher::document{'previous_nr'} }
sub _set_previous_nr{ $Kepher::document{'previous_nr'} = shift }
sub _get_current_nr { $Kepher::document{'current_nr'} }
sub _set_current_nr {
	my $nr = shift;
	$nr ||= 0;
	$Kepher::document{'current_nr'} = $nr;
	$Kepher::document{'current'}    = $Kepher::document{'open'}[$nr];
	$Kepher::internal{'current_doc'}= $Kepher::internal{'document'}{'open'}[$nr];
}
sub _get_last_nr      { $#{ $Kepher::document{'open'} } }
sub _get_nr_from_path {
	my $given_path = shift;
	my @answer = ();
	for ( 0 .. _get_last_nr() ) {
		push @answer, $_ if $Kepher::document{'open'}[$_]{'path'} eq $given_path;
	}
	$#answer == -1 ? return 0 : return \@answer;
}

sub _get_path_from_nr{
	my $nr = shift;
	$Kepher::document{'open'}[$nr]{'path'} if $nr <= _get_last_nr()
}

sub _get_current_file_path { 
	$Kepher::document{'current'}{'path'};
}

sub _get_all_pathes {
	my @pathes;
	my $docs = $Kepher::document{'open'};
	$pathes[$_] = $docs->[$_]{'path'} for 0 .. _get_last_nr();
	return \@pathes;
}

# file name 
sub set_file_path {
	my ( $file_path, $doc_nr ) = @_;
	$doc_nr ||= 0;
	$doc_nr = _get_current_nr() unless $doc_nr;
	$Kepher::document{'open'}[$doc_nr]{'path'} = $file_path;
	Kepher::Document::Internal::dissect_path( $file_path, $doc_nr );
	Kepher::App::TabBar::refresh_label($doc_nr);
	Kepher::App::Window::set_title($file_path);
}

sub _get_name_from_nr{
	my $nr = shift;
	$Kepher::internal{'document'}{'open'}[$nr]{'name'}  if $nr <= _get_last_nr()
}

sub _get_all_names {
	my @names;
	my $docs = \@{$Kepher::internal{'document'}{'open'}};
	$names[$_] = $docs->[$_]{'name'} for 0 .. _get_last_nr();
	return \@names;
}

sub _get_current_pos{
	return $Kepher::document{'current'}{'cursor_pos'}
		unless $Kepher::internal{'document'}{'loaded'};
}


#
sub set_codepage {
	my $ep = Kepher::App::STC::_get();
	# my $app_win = shift;
	#$ep->SetCodePage(65001); wxSTC_CP_UTF8 Wx::wxUNICODE()
	#Kepher::Dialog::msg_box(undef, Wx::wxUNICODE(), '');
use Wx::STC qw(wxSTC_CP_UTF8);
}

#
sub get_tab_size { $Kepher::document{'current'}{'tab_size'} }
sub set_tab_size {
	my $size = shift;
	return unless $size;
	$Kepher::document{'current'}{'tab_size'} = $size;
	Kepher::App::STC::set_tab_size($size);
}
sub set_tab_size_2 { set_tab_size(2) }
sub set_tab_size_3 { set_tab_size(3) }
sub set_tab_size_4 { set_tab_size(4) }
sub set_tab_size_5 { set_tab_size(5) }
sub set_tab_size_6 { set_tab_size(6) }
sub set_tab_size_8 { set_tab_size(8) }

#
sub get_tab_mode { $Kepher::document{'current'}{'tab_use'} }
sub set_tab_mode {
	my $mode = shift;
	$mode ||= 0;
	$Kepher::document{'current'}{'tab_use'} = $mode;
	Kepher::App::STC::_get()->SetUseTabs($mode);
	Kepher::App::StatusBar::tab_info();
}
sub set_tabs_hard  { set_tab_mode(1) }
sub set_tabs_soft  { set_tab_mode(0) }
sub switch_tab_mode{ get_tab_mode() ? set_tab_mode(0) : set_tab_mode(1) }
#
sub convert_indent2tabs   { convert_indention(1) }
sub convert_indent2spaces { convert_indention(0) }
sub convert_indention {
	my $use_tab = shift;
	my $ep = Kepher::App::STC::_get();
	my $indention = $ep->GetUseTabs;
	my $i;
	$ep->SetUseTabs($use_tab);
	$ep->BeginUndoAction();
	for ( 0 .. $ep->LineFromPosition( $ep->GetLength ) ) {
		$i = $ep->GetLineIndentation($_);
		$ep->SetLineIndentation( $_, $i + 1 );
		$ep->SetLineIndentation( $_, $i );
	}
	$ep->EndUndoAction;
	$ep->SetUseTabs($indention);
}

sub convert_spaces2tabs {
	Kepher::Edit::_save_positions();
	Kepher::Edit::Select::document();
	Kepher::Edit::Convert::spaces2tabs();
	Kepher::Edit::_restore_positions();
}

sub convert_tabs2spaces {
	Kepher::Edit::_save_positions();
	Kepher::Edit::Select::document();
	Kepher::Edit::Convert::tabs2spaces();
	Kepher::Edit::_restore_positions();
}

sub del_trailing_spaces {
	Kepher::Edit::_save_positions();
	Kepher::Edit::Select::document();
	Kepher::Edit::Format::del_trailing_spaces();
	Kepher::Edit::_restore_positions();
}

#
sub get_EOL_mode { $Kepher::document{'current'}{'EOL'} }
sub set_EOL_mode {
	my $ep = Kepher::App::STC::_get();
	my $mode      = shift;
	$mode = $Kepher::config{'file'}{'defaultsettings'}{'EOL_new'} if ( !$mode );
	my $eoll = \$Kepher::internal{'current_doc'}{'EOL_length'};
	$$eoll = 1;
	$mode = detect_EOL_mode() if $mode eq 'auto';
	if    ( $mode eq 'lf' or $mode eq 'lin' ) { $ep->SetEOLMode(wxSTC_EOL_LF) } 
	elsif ( $mode eq 'cr' or $mode eq 'mac' ) { $ep->SetEOLMode(wxSTC_EOL_CR) }
	elsif ( $mode eq 'cr+lf'or $mode eq 'win'){ $ep->SetEOLMode(wxSTC_EOL_CRLF);
		$$eoll = 2;
	}
	$Kepher::document{'current'}{'EOL'} = $mode;
	Kepher::App::StatusBar::EOL_info($mode);
}

sub set_EOL_mode_lf   { set_EOL_mode('lf') }
sub set_EOL_mode_cr   { set_EOL_mode('cr') }
sub set_EOL_mode_crlf { set_EOL_mode('cr+lf') }
sub set_EOL_mode_auto { set_EOL_mode('auto' ) }

sub convert_EOL {
	my $ep = Kepher::App::STC::_get();
	my $doc_nr    = &_get_current_nr;
	my $mode      = shift;
	$mode = $Kepher::config{'file'}{'defaultsettings'}{'EOL_new'} if ( !$mode );

	$mode = detect_EOL_mode() if $mode eq 'auto';
	if    ($mode eq 'lf' or $mode eq 'lin' )  {$ep->ConvertEOLs(wxSTC_EOL_LF)}
	elsif ($mode eq 'cr' or $mode eq 'mac' )  {$ep->ConvertEOLs(wxSTC_EOL_CR)}
	elsif ($mode eq 'cr+lf'or $mode eq 'win') {$ep->ConvertEOLs(wxSTC_EOL_CRLF)}
	set_EOL_mode($mode);
}

sub convert_EOL_2_lf   { convert_EOL('lf') }
sub convert_EOL_2_cr   { convert_EOL('cr') }
sub convert_EOL_2_crlf { convert_EOL('cr+lf') }

sub detect_EOL_mode {
	my $ep = Kepher::App::STC::_get();
	my $end_pos   = $ep->PositionFromLine(1);
	my $begin_pos = $end_pos - 3;
	$begin_pos = 0 if $begin_pos < 0;
	my $text = $ep->GetTextRange( $begin_pos, $end_pos );

	if ( length($text) < 1 ) { return 'auto' }
	else {
		return 'cr+lf' if $text =~ /\r\n/;
		return 'cr'    if $text =~ /\r/;
		return 'lf'    if $text =~ /\n/;
		return 'auto';
	}
}



# auto indention
sub get_autoindention { $Kepher::config{'editpanel'}{'auto'}{'indention'} }
sub switch_autoindention { 
	$Kepher::config{'editpanel'}{'auto'}{'indention'} ^= 1;
	Kepher::Edit::eval_newline_sub();
}
sub set_autoindent_on   {
	$Kepher::config{'editpanel'}{'auto'}{'indention'}  = 1; 
	Kepher::Edit::eval_newline_sub();
}
sub set_autoindent_off  { 
	$Kepher::config{'editpanel'}{'auto'}{'indention'}  = 0;
	Kepher::Edit::eval_newline_sub();
}

# brace indention
sub get_braceindention{ $Kepher::config{'editpanel'}{'auto'}{'brace'}{'indention'}}
sub switch_braceindention{ 
	$Kepher::config{'editpanel'}{'auto'}{'brace'}{'indention'} ^= 1;
	Kepher::Edit::eval_newline_sub();
}
sub set_blockindent_on {
	$Kepher::config{'editpanel'}{'auto'}{'brace'}{'indention'} = 1;
	Kepher::Edit::eval_newline_sub();
}
sub set_blockindent_off {
	$Kepher::config{'editpanel'}{'auto'}{'brace'}{'indention'} = 0;
	Kepher::Edit::eval_newline_sub();
}


# bracelight
sub bracelight_visible{
	$Kepher::config{'editpanel'}{'indicator'}{'bracelight'}{'visible'}
}
sub get_bracelight{ bracelight_visible() }
sub switch_bracelight{
	bracelight_visible() ? set_bracelight_off() : set_bracelight_on();
}
sub set_bracelight_on {
	$Kepher::config{'editpanel'}{'indicator'}{'bracelight'}{'visible'} = 1;
	Kepher::App::EditPanel::apply_bracelight_settings()
}
sub set_bracelight_off {
	$Kepher::config{'editpanel'}{'indicator'}{'bracelight'}{'visible'} = 0;
	Kepher::App::EditPanel::apply_bracelight_settings()
}
	#$Kepher::config{'editpanel'}{'indicator'}{'bracelight'}{'mode'} = 'adjacent';
	#$Kepher::config{'editpanel'}{'indicator'}{'bracelight'}{'mode'} = 'surround';


# write protection
sub get_readonly { $Kepher::document{'current'}{'readonly'} }
sub set_readonly {
	my $status     = shift;
	my $ep = Kepher::App::STC::_get();
	my $file_name  = _get_current_file_path();
	my $old_state  = $ep->GetReadOnly;

	if ( not $status or $status eq 'off' ) {
		$ep->SetReadOnly(0);
		$Kepher::document{'current'}{'readonly'} = 'off';
	} elsif ( $status eq 'on' or $status eq '1' ) {
		$ep->SetReadOnly(1);
		$Kepher::document{'current'}{'readonly'} = 'on';
	} elsif ( $status eq 'protect' or $status eq '2' ) {
		if ( $file_name and -e $file_name and not -w $file_name ) 
			{$ep->SetReadOnly(1)}
		else{$ep->SetReadOnly(0)}
		$Kepher::document{'current'}{'readonly'} = 'protect';
	}
	$Kepher::internal{'current_doc'}{'readonly'} = $ep->GetReadOnly ? 1 : 0;
	Kepher::App::TabBar::refresh_current_label()
		if $Kepher::config{'app'}{'tabbar'}{'info_symbol'};
}
sub set_readonly_on      { set_readonly('on') }
sub set_readonly_off     { set_readonly('off') }
sub set_readonly_protect { set_readonly('protect') }


sub _lc_utf {
	my ( $uc, $lc ) = shift;
	$lc .= lcfirst( substr( $uc, $_, 1 ) ) for 0 .. length($uc) - 1;
	$lc;
}

1;