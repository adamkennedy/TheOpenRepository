package Kephra::Document;
$VERSION = '0.38';

# changing properties to current document
use strict;
use Wx qw(
	wxSTC_EOL_CR wxSTC_EOL_LF wxSTC_EOL_CRLF
	wxSTC_STYLE_CONTROLCHAR
);

# internal functions
# doc number
sub _get_count      { @{ $Kephra::document{'open'} } }
sub _get_previous_nr{ $Kephra::document{'previous_nr'} }
sub _set_previous_nr{ $Kephra::document{'previous_nr'} = shift }
sub _get_current_nr { $Kephra::document{'current_nr'} }
sub _set_current_nr {
	my $nr = shift;
	$nr ||= 0;
	$Kephra::document{'current_nr'} = $nr;
	$Kephra::document{'current'}    = $Kephra::document{'open'}[$nr];
	$Kephra::temp{'current_doc'}= $Kephra::temp{'document'}{'open'}[$nr];
}
sub _get_last_nr      { $#{ $Kephra::document{'open'} } }
sub _get_nr_from_path {
	my $given_path = shift;
	my @answer = ();
	for ( 0 .. _get_last_nr() ) {
		push @answer, $_ if $Kephra::document{'open'}[$_]{'file_path'} eq $given_path;
	}
	$#answer == -1 ? return 0 : return \@answer;
}

sub _get_path_from_nr{
	my $nr = shift;
	$Kephra::document{'open'}[$nr]{'file_path'} if $nr <= _get_last_nr()
}

sub _get_current_file_path { 
	$Kephra::document{'current'}{'file_path'};
}

sub _get_all_pathes {
	my @pathes;
	my $docs = $Kephra::document{'open'};
	$pathes[$_] = $docs->[$_]{'file_path'} for 0 .. _get_last_nr();
	return \@pathes;
}

sub set_file_path {
	my ( $file_path, $doc_nr ) = @_;
	$doc_nr ||= 0;
	$doc_nr = _get_current_nr() unless $doc_nr;
	$Kephra::document{'open'}[$doc_nr]{'file_path'} = $file_path;
	Kephra::Document::Internal::dissect_path( $file_path, $doc_nr );
	Kephra::App::TabBar::refresh_label($doc_nr);
	Kephra::App::Window::refresh_title();
}

sub _get_name_from_nr{
	my $nr = shift;
	$Kephra::temp{'document'}{'open'}[$nr]{'name'}  if $nr <= _get_last_nr()
}

sub _get_all_names {
	my @names;
	my $docs = \@{$Kephra::temp{'document'}{'open'}};
	$names[$_] = $docs->[$_]{'name'} for 0 .. _get_last_nr();
	return \@names;
}

sub _get_current_pos{
	return $Kephra::document{'current'}{'cursor_pos'}
		unless $Kephra::temp{'document'}{'loaded'};
}


#
sub set_codepage {
	my $ep = Kephra::App::EditPanel::_get();
	# my $app_win = shift;
	#$ep->SetCodePage(65001); wxSTC_CP_UTF8 Wx::wxUNICODE()
	#Kephra::Dialog::msg_box(undef, Wx::wxUNICODE(), '');
#use Wx::STC qw(wxSTC_CP_UTF8);
}

#
sub get_tab_size { $Kephra::document{'current'}{'tab_size'} }
sub set_tab_size {
	my $size = shift;
	return unless $size;
	$Kephra::document{'current'}{'tab_size'} = $size;
	Kephra::App::EditPanel::set_tab_size($size);
}
sub set_tab_size_2 { set_tab_size(2) }
sub set_tab_size_3 { set_tab_size(3) }
sub set_tab_size_4 { set_tab_size(4) }
sub set_tab_size_5 { set_tab_size(5) }
sub set_tab_size_6 { set_tab_size(6) }
sub set_tab_size_8 { set_tab_size(8) }

#
sub get_tab_mode { $Kephra::document{'current'}{'tab_use'} }
sub set_tab_mode {
	my $mode = shift;
	$mode ||= 0;
	$Kephra::document{'current'}{'tab_use'} = $mode;
	Kephra::App::EditPanel::_get()->SetUseTabs($mode);
	Kephra::App::StatusBar::tab_info();
}
sub set_tabs_hard  { set_tab_mode(1) }
sub set_tabs_soft  { set_tab_mode(0) }
sub switch_tab_mode{ get_tab_mode() ? set_tab_mode(0) : set_tab_mode(1) }
#
sub convert_indent2tabs   { _edit( \&Kephra::Edit::Convert::indent2tabs  )}
sub convert_indent2spaces { _edit( \&Kephra::Edit::Convert::indent2spaces)}
sub convert_spaces2tabs   { _edit( \&Kephra::Edit::Convert::spaces2tabs  )}
sub convert_tabs2spaces   { _edit( \&Kephra::Edit::Convert::tabs2spaces  )}
sub del_trailing_spaces   { _edit( \&Kephra::Edit::Format::del_trailing_spaces)}

sub _edit{
	my $coderef = shift;
	return unless ref $coderef eq 'CODE';
	my @txt_events = ('document.text.change','document.text.select','caret.move');
	Kephra::App::EventList::freeze(@txt_events);
	Kephra::Edit::_save_positions();
	Kephra::Edit::Select::document();
	&$coderef();
	Kephra::Edit::_restore_positions();
	Kephra::App::EventList::thaw(@txt_events);
	Kephra::App::EventList::trigger(@txt_events);
	1;
}

#
sub get_EOL_mode { $Kephra::document{'current'}{'EOL'} }
sub set_EOL_mode {
	my $ep = Kephra::App::EditPanel::_get();
	my $mode      = shift;
	$mode = $Kephra::config{'file'}{'defaultsettings'}{'EOL_new'} if ( !$mode );
	my $eoll = \$Kephra::temp{'current_doc'}{'EOL_length'};
	$$eoll = 1;
	$mode = detect_EOL_mode() if $mode eq 'auto';
	if    ( $mode eq 'lf' or $mode eq 'lin' ) { $ep->SetEOLMode(wxSTC_EOL_LF) } 
	elsif ( $mode eq 'cr' or $mode eq 'mac' ) { $ep->SetEOLMode(wxSTC_EOL_CR) }
	elsif ( $mode eq 'cr+lf'or $mode eq 'win'){ $ep->SetEOLMode(wxSTC_EOL_CRLF);
		$$eoll = 2;
	}
	$Kephra::document{'current'}{'EOL'} = $mode;
	Kephra::App::StatusBar::EOL_info($mode);
}

sub set_EOL_mode_lf   { set_EOL_mode('lf') }
sub set_EOL_mode_cr   { set_EOL_mode('cr') }
sub set_EOL_mode_crlf { set_EOL_mode('cr+lf') }
sub set_EOL_mode_auto { set_EOL_mode('auto' ) }

sub convert_EOL {
	my $ep = Kephra::App::EditPanel::_get();
	my $doc_nr    = &_get_current_nr;
	my $mode      = shift;
	$mode = $Kephra::config{'file'}{'defaultsettings'}{'EOL_new'} if ( !$mode );

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
	my $ep = Kephra::App::EditPanel::_get();
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
sub get_autoindention { $Kephra::config{'editpanel'}{'auto'}{'indention'} }
sub switch_autoindention { 
	$Kephra::config{'editpanel'}{'auto'}{'indention'} ^= 1;
	Kephra::Edit::eval_newline_sub();
}
sub set_autoindent_on   {
	$Kephra::config{'editpanel'}{'auto'}{'indention'}  = 1; 
	Kephra::Edit::eval_newline_sub();
}
sub set_autoindent_off  { 
	$Kephra::config{'editpanel'}{'auto'}{'indention'}  = 0;
	Kephra::Edit::eval_newline_sub();
}

# brace indention
sub get_braceindention{ $Kephra::config{'editpanel'}{'auto'}{'brace'}{'indention'}}
sub switch_braceindention{ 
	$Kephra::config{'editpanel'}{'auto'}{'brace'}{'indention'} ^= 1;
	Kephra::Edit::eval_newline_sub();
}
sub set_blockindent_on {
	$Kephra::config{'editpanel'}{'auto'}{'brace'}{'indention'} = 1;
	Kephra::Edit::eval_newline_sub();
}
sub set_blockindent_off {
	$Kephra::config{'editpanel'}{'auto'}{'brace'}{'indention'} = 0;
	Kephra::Edit::eval_newline_sub();
}


# bracelight
sub bracelight_visible{
	$Kephra::config{'editpanel'}{'indicator'}{'bracelight'}{'visible'}
}
sub get_bracelight{ bracelight_visible() }
sub switch_bracelight{
	bracelight_visible() ? set_bracelight_off() : set_bracelight_on();
}
sub set_bracelight_on {
	$Kephra::config{'editpanel'}{'indicator'}{'bracelight'}{'visible'} = 1;
	Kephra::App::EditPanel::apply_bracelight_settings()
}
sub set_bracelight_off {
	$Kephra::config{'editpanel'}{'indicator'}{'bracelight'}{'visible'} = 0;
	Kephra::App::EditPanel::apply_bracelight_settings()
}
#$Kephra::config{'editpanel'}{'indicator'}{'bracelight'}{'mode'} = 'adjacent';
#$Kephra::config{'editpanel'}{'indicator'}{'bracelight'}{'mode'} = 'surround';


# write protection
sub get_readonly { $Kephra::document{'current'}{'readonly'} }
sub set_readonly {
	my $status     = shift;
	my $ep = Kephra::App::EditPanel::_get();
	my $file_name  = _get_current_file_path();
	my $old_state  = $ep->GetReadOnly;

	if ( not $status or $status eq 'off' ) {
		$ep->SetReadOnly(0);
		$Kephra::document{'current'}{'readonly'} = 'off';
	} elsif ( $status eq 'on' or $status eq '1' ) {
		$ep->SetReadOnly(1);
		$Kephra::document{'current'}{'readonly'} = 'on';
	} elsif ( $status eq 'protect' or $status eq '2' ) {
		if ( $file_name and -e $file_name and not -w $file_name ) 
			{$ep->SetReadOnly(1)}
		else{$ep->SetReadOnly(0)}
		$Kephra::document{'current'}{'readonly'} = 'protect';
	}
	$Kephra::temp{'current_doc'}{'readonly'} = $ep->GetReadOnly ? 1 : 0;
	Kephra::App::TabBar::refresh_current_label()
		if $Kephra::config{'app'}{'tabbar'}{'info_symbol'};
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