package syntaxhighlighter::xml;
$VERSION = '0.01';

sub load{
use Wx qw(wxSTC_LEX_XML wxSTC_H_TAG);

 $_[0]->StyleClearAll();
 $_[0]->SetLexer( wxSTC_LEX_XML );            # Set Lexers to use

 my $html_elements = "a abbr acronym address applet area b base basefont \
bdo big blockquote body br button caption center \
cite code col colgroup dd del dfn dir div dl dt em \
fieldset font form frame frameset h1 h2 h3 h4 h5 h6 \
head hr html i iframe img input ins isindex kbd label \
legend li link map menu meta noframes noscript \
object ol optgroup option p param pre q s samp \
script select small span strike strong style sub sup \
table tbody td textarea tfoot th thead title tr tt u ul \
var xml xmlns";

my $html_attributes = 'abbr accept-charset accept accesskey action align alink \
alt archive axis background bgcolor border \
cellpadding cellspacing char charoff charset checked cite \
class classid clear codebase codetype color cols colspan \
compact content coords \
data datafld dataformatas datapagesize datasrc datetime \
declare defer dir disabled enctype event \
face for frame frameborder \
headers height href hreflang hspace http-equiv \
id ismap label lang language leftmargin link longdesc \
marginwidth marginheight maxlength media method multiple \
name nohref noresize noshade nowrap \
object onblur onchange onclick ondblclick onfocus \
onkeydown onkeypress onkeyup onload onmousedown \
onmousemove onmouseover onmouseout onmouseup \
onreset onselect onsubmit onunload \
profile prompt readonly rel rev rows rowspan rules \
scheme scope selected shape size span src standby start style \
summary tabindex target text title topmargin type usemap \
valign value valuetype version vlink vspace width \
text password checkbox radio submit reset \
file hidden image';

 $_[0]->SetKeyWords(1,$html_elements.$html_attributes."public !doctype");  # Add new keyword.
 $_[0]->StyleSetSpec( wxSTC_H_TAG, "fore:#000055" ); # Apply tag style for selected lexer (blue)


 $_[0]->StyleSetSpec(0,"fore:#995544,bold");				# Text
 $_[0]->StyleSetSpec(1,"fore:#222288");                        # Tags
 $_[0]->StyleSetSpec(2,"fore:#222288,back:#FFFFFF");           # Unknown TagsFFE0E0
 $_[0]->StyleSetSpec(3,"fore:#008800");                        # Attributes
 $_[0]->StyleSetSpec(4,"fore:#004040,back:#FFFFFF");           # Unknown Attributes#FFE0E0
 $_[0]->StyleSetSpec(5,"fore:#007f7f,bold");                   # Numbers
 $_[0]->StyleSetSpec(6,"fore:#dd5544");					# Double quoted strings
 $_[0]->StyleSetSpec(7,"fore:#dd5544");					# Single quoted string
 $_[0]->StyleSetSpec(8,"fore:#bbbb44");					# Other inside tag
 $_[0]->StyleSetSpec(9,"fore:#bbbbbb");                        # Comment
 $_[0]->StyleSetSpec(10,"fore:#004000,bold");                  # Entities
 $_[0]->StyleSetSpec(11,"fore:#000000,bold");                  # XML style tag ends '/>'
 $_[0]->StyleSetSpec(12,"fore:#228822");                       # XML identifier start '<?'
 $_[0]->StyleSetSpec(13,"fore:#339933");                       # XML identifier end '?>'
 $_[0]->StyleSetSpec(14,"fore:#44aa44");                       #  SCRIPT
 $_[0]->StyleSetSpec(15,"fore:#55bb55");
 $_[0]->StyleSetSpec(17,"fore:#000000,back:#A0FFA0");          # CDATA
 $_[0]->StyleSetSpec(18,"fore:#000000,back:#F0E080");          # Question
 $_[0]->StyleSetSpec(19,"fore:#FFFF00,back:#8080A0");          # Unquoted Value
 $_[0]->StyleSetSpec(20,"fore:#FFFF00,back:#A08080");
 $_[0]->StyleSetSpec(21,"fore:#600000,back:#FFF0D8");
 $_[0]->StyleSetSpec(22,"fore:#000000,back:#DDD0DD");
 $_[0]->StyleSetSpec(23,"fore:#7F007F,back:#DDD0DD,notbold");
 $_[0]->StyleSetSpec(24,"fore:#7F007F,back:#DDD0DD,bold");
 $_[0]->StyleSetSpec(25,"fore:#7F007F,back:#DDD0DD,italics");
 $_[0]->StyleSetSpec(26,"fore:#7F007F,notbold");
 $_[0]->StyleSetSpec(27,"fore:#000000");
 $_[0]->StyleSetSpec(28,"fore:#000000");
 $_[0]->StyleSetSpec(29,"fore:#000000");
 $_[0]->StyleSetSpec(30,"fore:#000000");
 $_[0]->StyleSetSpec(31,"fore:#000000");                       # No brace matching in XML
}

1;
