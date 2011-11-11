// SpecialRefresh.cpp : broadcast a WM_SETTINGCHANGE message to all windows in the system
// see http://support.microsoft.com/kb/104011
//
// This code is free software; you can redistribute it and/or modify it
// under the same terms as Perl itself.

#include "stdafx.h"

UINT __stdcall SpecialRefresh(MSIHANDLE hModule) {    
    DWORD dwReturnValue = 0;
    SendMessageTimeout( HWND_BROADCAST, WM_SETTINGCHANGE, 0,
                        (LPARAM) "Environment", SMTO_ABORTIFHUNG,
                        5000, &dwReturnValue );

    return ERROR_SUCCESS;
}
