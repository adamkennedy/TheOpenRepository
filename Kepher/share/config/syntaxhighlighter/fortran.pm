package syntaxhighlighter::fortran;
$VERSION = '0.01';

sub load{
    use Wx qw(wxSTC_LEX_FORTRAN wxSTC_H_TAG);

    $_[0]->SetLexer(wxSTC_LEX_FORTRAN);	# Set Lexers to use keywords and io specifiers
    $_[0]->SetKeyWords(0, 'keywords and input/output specifiers
keywordclass.fortran=access action advance allocatable allocate
apostrophe assign assignment associate asynchronous backspace
bind blank blockdata call case character class close common
complex contains continue cycle data deallocate decimal delim
default dimension direct do dowhile double doubleprecision else
elseif elsewhere encoding end endassociate endblockdata enddo
endfile endforall endfunction endif endinterface endmodule endprogram
endselect endsubroutine endtype endwhere entry eor equivalence
err errmsg exist exit external file flush fmt forall form format
formatted function go goto id if implicit in include inout
integer inquire intent interface intrinsic iomsg iolength
iostat kind len logical module name named namelist nextrec nml
none nullify number only open opened operator optional out pad
parameter pass pause pending pointer pos position precision
print private program protected public quote read readwrite
real rec recl recursive result return rewind save select
selectcase selecttype sequential sign size stat status stop stream
subroutine target then to type unformatted unit use value
volatile wait where while write');

 #keywords2 is for highlighting intrinsic and extended functions
    $_[0]->SetKeyWords(1, 'abs achar acos acosd adjustl adjustr
aimag aimax0 aimin0 aint ajmax0 ajmin0 akmax0 akmin0 all allocated alog
alog10 amax0 amax1 amin0 amin1 amod anint any asin asind associated
atan atan2 atan2d atand bitest bitl bitlr bitrl bjtest bit_size bktest break
btest cabs ccos cdabs cdcos cdexp cdlog cdsin cdsqrt ceiling cexp char
clog cmplx conjg cos cosd cosh count cpu_time cshift csin csqrt dabs
dacos dacosd dasin dasind datan datan2 datan2d datand date
date_and_time dble dcmplx dconjg dcos dcosd dcosh dcotan ddim dexp
dfloat dflotk dfloti dflotj digits dim dimag dint dlog dlog10 dmax1 dmin1
dmod dnint dot_product dprod dreal dsign dsin dsind dsinh dsqrt dtan dtand
dtanh eoshift epsilon errsns exp exponent float floati floatj floatk floor fraction
free huge iabs iachar iand ibclr ibits ibset ichar idate idim idint idnint ieor ifix
iiabs iiand iibclr iibits iibset iidim iidint iidnnt iieor iifix iint iior iiqint iiqnnt iishft \
iishftc iisign ilen imax0 imax1 imin0 imin1 imod index inint inot int int1 int2 int4
int8 iqint iqnint ior ishft ishftc isign isnan izext jiand jibclr jibits jibset jidim jidint
jidnnt jieor jifix jint jior jiqint jiqnnt jishft jishftc jisign jmax0 jmax1 jmin0 jmin1
jmod jnint jnot jzext kiabs kiand kibclr kibits kibset kidim kidint kidnnt kieor kifix
kind kint kior kishft kishftc kisign kmax0 kmax1 kmin0 kmin1 kmod knint knot kzext
lbound leadz len len_trim lenlge lge lgt lle llt log log10 logical lshift malloc matmul
max max0 max1 maxexponent maxloc maxval merge min min0 min1 minexponent minloc
minval mod modulo mvbits nearest nint not nworkers number_of_processors pack popcnt
poppar precision present product radix random random_number random_seed range real
repeat reshape rrspacing rshift scale scan secnds selected_int_kind
selected_real_kind set_exponent shape sign sin sind sinh size sizeof sngl snglq spacing
spread sqrt sum system_clock tan tand tanh tiny transfer transpose trim ubound unpack verify');

 #keywords3 are nonstardard, extended and user defined functions
$_[0]->SetKeyWords(2, 'cdabs cdcos cdexp cdlog cdsin cdsqrt cotan cotand
dcmplx dconjg dcotan dcotand decode dimag dll_export dll_import doublecomplex dreal
dvchk encode find flen flush getarg getcharqq getcl getdat getenv gettim hfix ibchng
identifier imag int1 int2 int4 intc intrup invalop iostat_msg isha ishc ishl jfix
lacfar locking locnear map nargs nbreak ndperr ndpexc offset ovefl peekcharqq precfill
prompt qabs qacos qacosd qasin qasind qatan qatand qatan2 qcmplx qconjg qcos qcosd
qcosh qdim qexp qext qextd qfloat qimag qlog qlog10 qmax1 qmin1 qmod qreal qsign qsin
qsind qsinh qsqrt qtan qtand qtanh ran rand randu rewrite segment setdat settim system
timer undfl unlock union val virtual volatile zabs zcos zexp zlog zsin zsqrt');


 #$_[0]->StyleSetSpec( wxSTC_H_TAG, "fore:#000055" );

 $_[0]->StyleSetSpec(0,"fore:#202020");					# default
 $_[0]->StyleSetSpec(1,"fore:#bbbbbb");					# Comment
 $_[0]->StyleSetSpec(2,"fore:#007f7f");					# Number
 $_[0]->StyleSetSpec(3,"fore:#004000");					# Single quoted string
 $_[0]->StyleSetSpec(4,"fore:#007f7f");					# Doublequoted string
 $_[0]->StyleSetSpec(5,"fore:#000000,back:#E0C0E0,eolfilled");		# End of line where string is not closed
 $_[0]->StyleSetSpec(6,"fore:#ff5555,bold");				# Operators
 $_[0]->StyleSetSpec(7,"fore:#55aa55,italic");				# Identifiers
 $_[0]->StyleSetSpec(8,"fore:#3344bb");					# Keywords
 $_[0]->StyleSetSpec(9,"fore:#228833");					# Keywords2
 $_[0]->StyleSetSpec(10,"fore:#bb7799");				# Keywords3
 $_[0]->StyleSetSpec(11,"fore:#778899");				# Preprocessor
 $_[0]->StyleSetSpec(12,"fore:#228822");				# Operators in .NAME. format
 $_[0]->StyleSetSpec(13,"fore:#339933");				# Labels
 $_[0]->StyleSetSpec(14,"fore:#44aa44");				# Continuation
}

1;
