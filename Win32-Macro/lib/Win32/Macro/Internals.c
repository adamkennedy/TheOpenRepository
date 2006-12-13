/*
 * This file was generated automatically by ExtUtils::ParseXS version 2.15 from the
 * contents of Internals.xs. Do not edit this file, edit Internals.xs instead.
 *
 *	ANY CHANGES MADE HERE WILL BE LOST! 
 *
 */

#line 1 "lib/Win32/Macro/Internals.xs"
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <windows.h>

#include "const-c.inc"

#ifndef PERL_UNUSED_VAR
#  define PERL_UNUSED_VAR(var) if (0) var = var
#endif

#line 25 "lib/Win32/Macro/Internals.c"

/* INCLUDE:  Including 'const-xs.inc' from 'Internals.xs' */


XS(XS_Win32__Macro__Internals_constant); /* prototype to pass -Wmissing-prototypes */
XS(XS_Win32__Macro__Internals_constant)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: Win32::Macro::Internals::constant(sv)");
    PERL_UNUSED_VAR(cv); /* -W */
    PERL_UNUSED_VAR(ax); /* -Wall */
    SP -= items;
    {
#line 4 "lib/Win32/Macro/Internals.xs"
#ifdef dXSTARG
	dXSTARG; /* Faster if we have it.  */
#else
	dTARGET;
#endif
	STRLEN		len;
        int		type;
	IV		iv;
	/* NV		nv;	Uncomment this if you need to return NVs */
	/* const char	*pv;	Uncomment this if you need to return PVs */
#line 51 "lib/Win32/Macro/Internals.c"
	SV *	sv = ST(0);
	const char *	s = SvPV(sv, len);
#line 18 "lib/Win32/Macro/Internals.xs"
        /* Change this to constant(aTHX_ s, len, &iv, &nv);
           if you need to return both NVs and IVs */
	type = constant(aTHX_ s, len, &iv);
      /* Return 1 or 2 items. First is error message, or undef if no error.
           Second, if present, is found value */
        switch (type) {
        case PERL_constant_NOTFOUND:
          sv = sv_2mortal(newSVpvf("%s is not a valid Win32::Macro::Internals macro", s));
          PUSHs(sv);
          break;
        case PERL_constant_NOTDEF:
          sv = sv_2mortal(newSVpvf(
	    "Your vendor has not defined Win32::Macro::Internals macro %s, used", s));
          PUSHs(sv);
          break;
        case PERL_constant_ISIV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHi(iv);
          break;
	/* Uncomment this if you need to return NOs
        case PERL_constant_ISNO:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHs(&PL_sv_no);
          break; */
	/* Uncomment this if you need to return NVs
        case PERL_constant_ISNV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHn(nv);
          break; */
	/* Uncomment this if you need to return PVs
        case PERL_constant_ISPV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHp(pv, strlen(pv));
          break; */
	/* Uncomment this if you need to return PVNs
        case PERL_constant_ISPVN:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHp(pv, iv);
          break; */
	/* Uncomment this if you need to return SVs
        case PERL_constant_ISSV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHs(sv);
          break; */
	/* Uncomment this if you need to return UNDEFs
        case PERL_constant_ISUNDEF:
          break; */
	/* Uncomment this if you need to return UVs
        case PERL_constant_ISUV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHu((UV)iv);
          break; */
	/* Uncomment this if you need to return YESs
        case PERL_constant_ISYES:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHs(&PL_sv_yes);
          break; */
        default:
          sv = sv_2mortal(newSVpvf(
	    "Unexpected return type %d while processing Win32::Macro::Internals macro %s, used",
               type, s));
          PUSHs(sv);
        }
#line 126 "lib/Win32/Macro/Internals.c"
	PUTBACK;
	return;
    }
}


/* INCLUDE: Returning to 'Internals.xs' from 'const-xs.inc' */


XS(XS_Win32__Macro__Internals_WindowFromPoint); /* prototype to pass -Wmissing-prototypes */
XS(XS_Win32__Macro__Internals_WindowFromPoint)
{
    dXSARGS;
    if (items != 2)
	Perl_croak(aTHX_ "Usage: Win32::Macro::Internals::WindowFromPoint(x, y)");
    PERL_UNUSED_VAR(cv); /* -W */
    {
	LONG	x = (LONG)SvIV(ST(0));
	LONG	y = (LONG)SvIV(ST(1));
#line 26 "lib/Win32/Macro/Internals.xs"
    POINT myPoint;
#line 148 "lib/Win32/Macro/Internals.c"
	HWND	RETVAL;
	dXSTARG;
#line 28 "lib/Win32/Macro/Internals.xs"
    myPoint.x = x;
    myPoint.y = y;
    RETVAL = WindowFromPoint(myPoint);
#line 155 "lib/Win32/Macro/Internals.c"
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


XS(XS_Win32__Macro__Internals_GetForegroundWindow); /* prototype to pass -Wmissing-prototypes */
XS(XS_Win32__Macro__Internals_GetForegroundWindow)
{
    dXSARGS;
    if (items != 0)
	Perl_croak(aTHX_ "Usage: Win32::Macro::Internals::GetForegroundWindow()");
    PERL_UNUSED_VAR(cv); /* -W */
    {
	HWND	RETVAL;
	dXSTARG;
#line 43 "lib/Win32/Macro/Internals.xs"
   RETVAL = GetForegroundWindow();
#line 174 "lib/Win32/Macro/Internals.c"
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


XS(XS_Win32__Macro__Internals_GetDesktopWindow); /* prototype to pass -Wmissing-prototypes */
XS(XS_Win32__Macro__Internals_GetDesktopWindow)
{
    dXSARGS;
    if (items != 0)
	Perl_croak(aTHX_ "Usage: Win32::Macro::Internals::GetDesktopWindow()");
    PERL_UNUSED_VAR(cv); /* -W */
    {
	HWND	RETVAL;
	dXSTARG;
#line 56 "lib/Win32/Macro/Internals.xs"
   RETVAL = GetDesktopWindow();
#line 193 "lib/Win32/Macro/Internals.c"
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


XS(XS_Win32__Macro__Internals_GetActiveWindow); /* prototype to pass -Wmissing-prototypes */
XS(XS_Win32__Macro__Internals_GetActiveWindow)
{
    dXSARGS;
    if (items != 0)
	Perl_croak(aTHX_ "Usage: Win32::Macro::Internals::GetActiveWindow()");
    PERL_UNUSED_VAR(cv); /* -W */
    {
	HWND	RETVAL;
	dXSTARG;
#line 69 "lib/Win32/Macro/Internals.xs"
    RETVAL = GetActiveWindow();
#line 212 "lib/Win32/Macro/Internals.c"
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


XS(XS_Win32__Macro__Internals_GetWindow); /* prototype to pass -Wmissing-prototypes */
XS(XS_Win32__Macro__Internals_GetWindow)
{
    dXSARGS;
    if (items != 2)
	Perl_croak(aTHX_ "Usage: Win32::Macro::Internals::GetWindow(handle, command)");
    PERL_UNUSED_VAR(cv); /* -W */
    {
	HWND	handle = (HWND)SvIV(ST(0));
	UINT	command = (UINT)SvUV(ST(1));
	HWND	RETVAL;
	dXSTARG;
#line 84 "lib/Win32/Macro/Internals.xs"
    RETVAL = GetWindow(handle, command);
#line 233 "lib/Win32/Macro/Internals.c"
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


XS(XS_Win32__Macro__Internals_FindWindow); /* prototype to pass -Wmissing-prototypes */
XS(XS_Win32__Macro__Internals_FindWindow)
{
    dXSARGS;
    if (items != 2)
	Perl_croak(aTHX_ "Usage: Win32::Macro::Internals::FindWindow(classname, windowname)");
    PERL_UNUSED_VAR(cv); /* -W */
    {
	LPCTSTR	classname = (LPCTSTR)SvPV_nolen(ST(0));
	LPCTSTR	windowname = (LPCTSTR)SvPV_nolen(ST(1));
	HWND	RETVAL;
	dXSTARG;
#line 99 "lib/Win32/Macro/Internals.xs"
    if(strlen(classname) == 0) classname = NULL;
    if(strlen(windowname) == 0) windowname = NULL;
    RETVAL = FindWindow(classname, windowname);
#line 256 "lib/Win32/Macro/Internals.c"
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


XS(XS_Win32__Macro__Internals_ShowWindow); /* prototype to pass -Wmissing-prototypes */
XS(XS_Win32__Macro__Internals_ShowWindow)
{
    dXSARGS;
    if (items < 1 || items > 2)
	Perl_croak(aTHX_ "Usage: Win32::Macro::Internals::ShowWindow(handle, command=SW_SHOWNORMAL)");
    PERL_UNUSED_VAR(cv); /* -W */
    {
	HWND	handle = (HWND)SvIV(ST(0));
	int	command;
	BOOL	RETVAL;
	dXSTARG;

	if (items < 2)
	    command = SW_SHOWNORMAL;
	else {
	    command = (int)SvIV(ST(1));
	}
#line 116 "lib/Win32/Macro/Internals.xs"
    RETVAL = ShowWindow(handle, command);
#line 283 "lib/Win32/Macro/Internals.c"
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


XS(XS_Win32__Macro__Internals_GetCursorPos); /* prototype to pass -Wmissing-prototypes */
XS(XS_Win32__Macro__Internals_GetCursorPos)
{
    dXSARGS;
    if (items != 0)
	Perl_croak(aTHX_ "Usage: Win32::Macro::Internals::GetCursorPos()");
    PERL_UNUSED_VAR(cv); /* -W */
    PERL_UNUSED_VAR(ax); /* -Wall */
    SP -= items;
    {
#line 129 "lib/Win32/Macro/Internals.xs"
    POINT point;
#line 302 "lib/Win32/Macro/Internals.c"
#line 131 "lib/Win32/Macro/Internals.xs"
    if(GetCursorPos(&point)) {
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(point.x)));
        PUSHs(sv_2mortal(newSViv(point.y)));
        XSRETURN(2);
    } else {
        XSRETURN_NO;
    }
#line 312 "lib/Win32/Macro/Internals.c"
	PUTBACK;
	return;
    }
}


XS(XS_Win32__Macro__Internals_SetCursorPos); /* prototype to pass -Wmissing-prototypes */
XS(XS_Win32__Macro__Internals_SetCursorPos)
{
    dXSARGS;
    if (items != 2)
	Perl_croak(aTHX_ "Usage: Win32::Macro::Internals::SetCursorPos(x, y)");
    PERL_UNUSED_VAR(cv); /* -W */
    {
	int	x = (int)SvIV(ST(0));
	int	y = (int)SvIV(ST(1));
	BOOL	RETVAL;
	dXSTARG;
#line 151 "lib/Win32/Macro/Internals.xs"
    RETVAL = SetCursorPos(x, y);
#line 333 "lib/Win32/Macro/Internals.c"
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


XS(XS_Win32__Macro__Internals_GetClientRect); /* prototype to pass -Wmissing-prototypes */
XS(XS_Win32__Macro__Internals_GetClientRect)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: Win32::Macro::Internals::GetClientRect(handle)");
    PERL_UNUSED_VAR(cv); /* -W */
    PERL_UNUSED_VAR(ax); /* -Wall */
    SP -= items;
    {
	HWND	handle = (HWND)SvIV(ST(0));
#line 165 "lib/Win32/Macro/Internals.xs"
    RECT myRect;
#line 353 "lib/Win32/Macro/Internals.c"
#line 167 "lib/Win32/Macro/Internals.xs"
    if(GetClientRect(handle, &myRect)) {
        EXTEND(SP, 4);
        PUSHs(sv_2mortal(newSViv(myRect.left  )));
        PUSHs(sv_2mortal(newSViv(myRect.top   )));
        PUSHs(sv_2mortal(newSViv(myRect.right )));
        PUSHs(sv_2mortal(newSViv(myRect.bottom)));
        XSRETURN(4);
    } else {
        XSRETURN_NO;
    }
#line 365 "lib/Win32/Macro/Internals.c"
	PUTBACK;
	return;
    }
}


XS(XS_Win32__Macro__Internals_GetWindowRect); /* prototype to pass -Wmissing-prototypes */
XS(XS_Win32__Macro__Internals_GetWindowRect)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: Win32::Macro::Internals::GetWindowRect(handle)");
    PERL_UNUSED_VAR(cv); /* -W */
    PERL_UNUSED_VAR(ax); /* -Wall */
    SP -= items;
    {
	HWND	handle = (HWND)SvIV(ST(0));
#line 188 "lib/Win32/Macro/Internals.xs"
    RECT myRect;
#line 385 "lib/Win32/Macro/Internals.c"
#line 190 "lib/Win32/Macro/Internals.xs"
    if(GetWindowRect(handle, &myRect)) {
        EXTEND(SP, 4);
        PUSHs(sv_2mortal(newSViv(myRect.left  )));
        PUSHs(sv_2mortal(newSViv(myRect.top   )));
        PUSHs(sv_2mortal(newSViv(myRect.right )));
        PUSHs(sv_2mortal(newSViv(myRect.bottom)));
        XSRETURN(4);
    } else {
        XSRETURN_NO;
    }
#line 397 "lib/Win32/Macro/Internals.c"
	PUTBACK;
	return;
    }
}


XS(XS_Win32__Macro__Internals_BringWindowToTop); /* prototype to pass -Wmissing-prototypes */
XS(XS_Win32__Macro__Internals_BringWindowToTop)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: Win32::Macro::Internals::BringWindowToTop(handle)");
    PERL_UNUSED_VAR(cv); /* -W */
    {
	HWND	handle = (HWND)SvIV(ST(0));
	BOOL	RETVAL;
	dXSTARG;
#line 211 "lib/Win32/Macro/Internals.xs"
    RETVAL = BringWindowToTop(handle);
#line 417 "lib/Win32/Macro/Internals.c"
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


XS(XS_Win32__Macro__Internals_GetWindowText); /* prototype to pass -Wmissing-prototypes */
XS(XS_Win32__Macro__Internals_GetWindowText)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: Win32::Macro::Internals::GetWindowText(handle)");
    PERL_UNUSED_VAR(cv); /* -W */
    PERL_UNUSED_VAR(ax); /* -Wall */
    SP -= items;
    {
	HWND	handle = (HWND)SvIV(ST(0));
#line 225 "lib/Win32/Macro/Internals.xs"
    char *myBuffer;
    int myLength;
#line 438 "lib/Win32/Macro/Internals.c"
#line 228 "lib/Win32/Macro/Internals.xs"
    myLength = GetWindowTextLength(handle)+1;
    if(myLength) {
      myBuffer = (char *) safemalloc(myLength);
      if(GetWindowText(handle, myBuffer, myLength)) {
        EXTEND(SP, 1);
        PUSHs(sv_2mortal(newSVpvn((char*) myBuffer, myLength)));
        safefree(myBuffer);
        XSRETURN(1);
      }
      safefree(myBuffer);
    }
    XSRETURN_NO;
#line 452 "lib/Win32/Macro/Internals.c"
	PUTBACK;
	return;
    }
}


XS(XS_Win32__Macro__Internals_Restore); /* prototype to pass -Wmissing-prototypes */
XS(XS_Win32__Macro__Internals_Restore)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: Win32::Macro::Internals::Restore(handle)");
    PERL_UNUSED_VAR(cv); /* -W */
    {
	HWND	handle = (HWND)SvIV(ST(0));
	BOOL	RETVAL;
	dXSTARG;
#line 251 "lib/Win32/Macro/Internals.xs"
    RETVAL = OpenIcon(handle);
#line 472 "lib/Win32/Macro/Internals.c"
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


XS(XS_Win32__Macro__Internals_Minimize); /* prototype to pass -Wmissing-prototypes */
XS(XS_Win32__Macro__Internals_Minimize)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: Win32::Macro::Internals::Minimize(handle)");
    PERL_UNUSED_VAR(cv); /* -W */
    {
	HWND	handle = (HWND)SvIV(ST(0));
	BOOL	RETVAL;
	dXSTARG;
#line 265 "lib/Win32/Macro/Internals.xs"
    RETVAL = CloseWindow(handle);
#line 492 "lib/Win32/Macro/Internals.c"
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


XS(XS_Win32__Macro__Internals_IsVisible); /* prototype to pass -Wmissing-prototypes */
XS(XS_Win32__Macro__Internals_IsVisible)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: Win32::Macro::Internals::IsVisible(handle)");
    PERL_UNUSED_VAR(cv); /* -W */
    {
	HWND	handle = (HWND)SvIV(ST(0));
	BOOL	RETVAL;
	dXSTARG;
#line 279 "lib/Win32/Macro/Internals.xs"
    RETVAL = IsWindowVisible(handle);
#line 512 "lib/Win32/Macro/Internals.c"
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


XS(XS_Win32__Macro__Internals_GetTopWindow); /* prototype to pass -Wmissing-prototypes */
XS(XS_Win32__Macro__Internals_GetTopWindow)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: Win32::Macro::Internals::GetTopWindow(handle)");
    PERL_UNUSED_VAR(cv); /* -W */
    {
	HWND	handle = (HWND)SvIV(ST(0));
	HWND	RETVAL;
	dXSTARG;
#line 293 "lib/Win32/Macro/Internals.xs"
    RETVAL = GetTopWindow(handle);
#line 532 "lib/Win32/Macro/Internals.c"
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


XS(XS_Win32__Macro__Internals_ScrollWindow); /* prototype to pass -Wmissing-prototypes */
XS(XS_Win32__Macro__Internals_ScrollWindow)
{
    dXSARGS;
    if (items != 3)
	Perl_croak(aTHX_ "Usage: Win32::Macro::Internals::ScrollWindow(handle, delta_x, delta_y)");
    PERL_UNUSED_VAR(cv); /* -W */
    {
	HWND	handle = (HWND)SvIV(ST(0));
	int	delta_x = (int)SvIV(ST(1));
	int	delta_y = (int)SvIV(ST(2));
	BOOL	RETVAL;
	dXSTARG;
#line 309 "lib/Win32/Macro/Internals.xs"
    RETVAL = ScrollWindowEx(handle, delta_x, delta_y, NULL, NULL, NULL, NULL, SW_INVALIDATE);
#line 554 "lib/Win32/Macro/Internals.c"
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


XS(XS_Win32__Macro__Internals_JoinRawData); /* prototype to pass -Wmissing-prototypes */
XS(XS_Win32__Macro__Internals_JoinRawData)
{
    dXSARGS;
    if (items != 5)
	Perl_croak(aTHX_ "Usage: Win32::Macro::Internals::JoinRawData(ww1, ww2, hh, raw1, raw2)");
    PERL_UNUSED_VAR(cv); /* -W */
    PERL_UNUSED_VAR(ax); /* -Wall */
    SP -= items;
    {
	LONG	ww1 = (LONG)SvIV(ST(0));
	LONG	ww2 = (LONG)SvIV(ST(1));
	LONG	hh = (LONG)SvIV(ST(2));
	LPVOID	raw1 = (LPVOID)SvPV_nolen(ST(3));
	LPVOID	raw2 = (LPVOID)SvPV_nolen(ST(4));
#line 327 "lib/Win32/Macro/Internals.xs"
    long	i;
    long	bufferlen;
    char *	buffer;
    char *	ptr_dest;
    char *	ptr_raw1;
    char *	ptr_raw2;
#line 583 "lib/Win32/Macro/Internals.c"
#line 334 "lib/Win32/Macro/Internals.xs"
    /* allocate output buffer */
    bufferlen = hh * ww1 * 4 + hh * ww2 * 4;
    buffer = (LPVOID) safemalloc(bufferlen);

    /* copy the scan lines */
    ptr_dest = buffer;
    ptr_raw1 = raw1;
    ptr_raw2 = raw2;
    for ( i=0 ; i<hh ; i++ ) {
      memcpy( ptr_dest, ptr_raw1, ww1 * 4 );
      ptr_dest += ww1 * 4;
      ptr_raw1 += ww1 * 4;
      memcpy( ptr_dest, ptr_raw2, ww2 * 4 );
      ptr_dest += ww2 * 4;
      ptr_raw2 += ww2 * 4;
    }

    /* output */
    EXTEND(SP, 1);
    PUSHs(sv_2mortal(newSVpvn((char*) buffer, bufferlen)));
    safefree(buffer);
    XSRETURN(1);
#line 607 "lib/Win32/Macro/Internals.c"
	PUTBACK;
	return;
    }
}


XS(XS_Win32__Macro__Internals_CaptureHwndRect); /* prototype to pass -Wmissing-prototypes */
XS(XS_Win32__Macro__Internals_CaptureHwndRect)
{
    dXSARGS;
    if (items != 5)
	Perl_croak(aTHX_ "Usage: Win32::Macro::Internals::CaptureHwndRect(handle, xx, yy, ww, hh)");
    PERL_UNUSED_VAR(cv); /* -W */
    PERL_UNUSED_VAR(ax); /* -Wall */
    SP -= items;
    {
	HWND	handle = (HWND)SvIV(ST(0));
	LONG	xx = (LONG)SvIV(ST(1));
	LONG	yy = (LONG)SvIV(ST(2));
	LONG	ww = (LONG)SvIV(ST(3));
	LONG	hh = (LONG)SvIV(ST(4));
#line 370 "lib/Win32/Macro/Internals.xs"
    HDC		hdc;
    HDC		my_hdc;
    HBITMAP	my_hbmp;
    BITMAPINFO  my_binfo;
    long	bufferlen;
    LPVOID	buffer;
    int		out;
    long	i;
    long	*p;
#line 639 "lib/Win32/Macro/Internals.c"
#line 381 "lib/Win32/Macro/Internals.xs"
    hdc = GetDC(handle);

    /* create in-memory bitmap for storing the copy of the screen */
    my_hdc  = CreateCompatibleDC(hdc);
    my_hbmp = CreateCompatibleBitmap(hdc, ww, hh);
    SelectObject(my_hdc, my_hbmp);

    /* copy the part of screen to our in-memory place */
    BitBlt(my_hdc, 0, 0, ww, hh, hdc, xx, yy, SRCCOPY);

    /* now get a 32bit device independent bitmap */
    ZeroMemory(&my_binfo, sizeof(BITMAPINFO));

    /* prepare a buffer to hold the screen data */
    bufferlen = hh * ww * 4;
    buffer = (LPVOID) safemalloc(bufferlen);

    /* prepare directions for GetDIBits */
    my_binfo.bmiHeader.biSize 	     = sizeof(BITMAPINFOHEADER);
    my_binfo.bmiHeader.biWidth       = ww;
    my_binfo.bmiHeader.biHeight      = -hh; /* negative because we want top-down bitmap */
    my_binfo.bmiHeader.biPlanes      = 1;
    my_binfo.bmiHeader.biBitCount    = 32; /* we want RGBQUAD data */
    my_binfo.bmiHeader.biCompression = BI_RGB;

    if(GetDIBits(my_hdc, my_hbmp, 0, hh, buffer, &my_binfo, DIB_RGB_COLORS)) {

        /* Convert RGBQUADs to format expected by Image::Magick .rgba file (BGRX -> RGBX) */
        p = buffer;
        for( i = 0 ; i < bufferlen/4 ; i++  ) {
          *p = ((*p & 0x000000ff) << 16) | ((*p & 0x00ff0000) >> 16) | (*p & 0x0000ff00) | 0xff000000;
          p++;
        }

        EXTEND(SP, 3);
        PUSHs(sv_2mortal(newSViv(my_binfo.bmiHeader.biWidth)));
        PUSHs(sv_2mortal(newSViv(abs(my_binfo.bmiHeader.biHeight))));
        PUSHs(sv_2mortal(newSVpvn((char*) buffer, bufferlen)));
        out = 1;
    } else {
      out = 0;
    }

    safefree(buffer);
    DeleteDC(my_hdc);
    ReleaseDC(handle, hdc);
    DeleteObject(my_hbmp);

    if ( out == 1 ) { XSRETURN(3); } else { XSRETURN_NO; }
#line 690 "lib/Win32/Macro/Internals.c"
	PUTBACK;
	return;
    }
}

#ifdef __cplusplus
extern "C"
#endif
XS(boot_Win32__Macro__Internals); /* prototype to pass -Wmissing-prototypes */
XS(boot_Win32__Macro__Internals)
{
    dXSARGS;
    char* file = __FILE__;

    PERL_UNUSED_VAR(cv); /* -W */
    PERL_UNUSED_VAR(items); /* -W */
    XS_VERSION_BOOTCHECK ;

        newXS("Win32::Macro::Internals::constant", XS_Win32__Macro__Internals_constant, file);
        newXS("Win32::Macro::Internals::WindowFromPoint", XS_Win32__Macro__Internals_WindowFromPoint, file);
        newXS("Win32::Macro::Internals::GetForegroundWindow", XS_Win32__Macro__Internals_GetForegroundWindow, file);
        newXS("Win32::Macro::Internals::GetDesktopWindow", XS_Win32__Macro__Internals_GetDesktopWindow, file);
        newXS("Win32::Macro::Internals::GetActiveWindow", XS_Win32__Macro__Internals_GetActiveWindow, file);
        newXS("Win32::Macro::Internals::GetWindow", XS_Win32__Macro__Internals_GetWindow, file);
        newXS("Win32::Macro::Internals::FindWindow", XS_Win32__Macro__Internals_FindWindow, file);
        newXS("Win32::Macro::Internals::ShowWindow", XS_Win32__Macro__Internals_ShowWindow, file);
        newXS("Win32::Macro::Internals::GetCursorPos", XS_Win32__Macro__Internals_GetCursorPos, file);
        newXS("Win32::Macro::Internals::SetCursorPos", XS_Win32__Macro__Internals_SetCursorPos, file);
        newXS("Win32::Macro::Internals::GetClientRect", XS_Win32__Macro__Internals_GetClientRect, file);
        newXS("Win32::Macro::Internals::GetWindowRect", XS_Win32__Macro__Internals_GetWindowRect, file);
        newXS("Win32::Macro::Internals::BringWindowToTop", XS_Win32__Macro__Internals_BringWindowToTop, file);
        newXS("Win32::Macro::Internals::GetWindowText", XS_Win32__Macro__Internals_GetWindowText, file);
        newXS("Win32::Macro::Internals::Restore", XS_Win32__Macro__Internals_Restore, file);
        newXS("Win32::Macro::Internals::Minimize", XS_Win32__Macro__Internals_Minimize, file);
        newXS("Win32::Macro::Internals::IsVisible", XS_Win32__Macro__Internals_IsVisible, file);
        newXS("Win32::Macro::Internals::GetTopWindow", XS_Win32__Macro__Internals_GetTopWindow, file);
        newXS("Win32::Macro::Internals::ScrollWindow", XS_Win32__Macro__Internals_ScrollWindow, file);
        newXS("Win32::Macro::Internals::JoinRawData", XS_Win32__Macro__Internals_JoinRawData, file);
        newXS("Win32::Macro::Internals::CaptureHwndRect", XS_Win32__Macro__Internals_CaptureHwndRect, file);
    XSRETURN_YES;
}

