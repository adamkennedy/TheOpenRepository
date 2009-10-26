// RelocationCA.cpp : Defines the Relocation custom action.
//
// Copyright (c) Curtis Jewell 2009.
//
// This code is free software; you can redistribute it and/or modify it
// under the same terms as Perl itself.

/* 
<CustomAction Id='CA_Relocation' BinaryKey='B_Relocation' DllEntry='Relocation' />

<InstallExecuteSequence>
  <Custom Action='CA_Relocation' Before='InstallInitialize'>REMOVE="ALL"</Custom>
</InstallExecuteSequence>

<Binary Id='B_Relocation' SourceFile='share\RelocationCA.dll' />
*/

#include "stdafx.h"

// Helper macros for error checking.

#define MSI_OK(x) \
	if (ERROR_SUCCESS != x) { \
		return x; \
	}
 
#define MSI_OK_FREE(x, y) \
	if (ERROR_SUCCESS != x) { \
		free(y); \
		return x; \
	}

#define MSI_OK_FREE_2(x, y, z) \
	if (ERROR_SUCCESS != x) { \
		free(y); \
		free(z); \
		return x; \
	}

#define HANDLE_OK(x) \
	if (NULL == x) { \
		return ERROR_INSTALL_FAILURE; \
	}

// The component for TARGET_DIR/perl/bin/perl.exe
static TCHAR sComponent[41];

// The string to be logged to Windows Installer.
static TCHAR sLogString[513];

// Default DllMain, since nothing special
// is happening here.

BOOL APIENTRY DllMain(
	HMODULE hModule,
	DWORD   ul_reason_for_call,
	LPVOID  lpReserved)
{
    return TRUE;
}

UINT RelocateFile(
	MSIHANDLE hModule,    // Handle of MSI being installed. [in]
	LPCTSTR sFilename,    // Filename to relocate. [in]
	int iRelocationType)  // Whether to search for file specifications/url's with
	                      // single-backslashes (1), double-backslashes (2), or
						  // single-slashes. (3) [in]
{
	return ERROR_CALL_NOT_IMPLEMENTED;
}


UINT __stdcall Relocation(
	MSIHANDLE hModule) // Handle of MSI being installed. [in]
	                   // Passed to most other routines.
{
	TCHAR sInstallDirectory[MAX_PATH + 1];
	TCHAR sFilename[MAX_PATH + 1];
	UINT uiAnswer;
	DWORD dwPropLength = MAX_PATH; 

	// Get directory to search.
	uiAnswer = ::MsiGetProperty(hModule, TEXT("INSTALLDIR"), sInstallDirectory, &dwPropLength); 
	MSI_OK(uiAnswer)

	// TODO: Search for .packlist files.

	// TODO: Search for the files in perl\bin that are not *.exe and *.dll files.

	_tcscpy_s(sFilename, MAX_PATH + 1, sInstallDirectory);
	_tcscat_s(sFilename, MAX_PATH + 1, _T("perl\\lib\\CORE\\config.h"));
	uiAnswer = RelocateFile(hModule, sFilename, 2);
	MSI_OK(uiAnswer);

	_tcscpy_s(sFilename, MAX_PATH + 1, sInstallDirectory);
	_tcscat_s(sFilename, MAX_PATH + 1, _T("perl\\lib\\Config.pm"));
	uiAnswer = RelocateFile(hModule, sFilename, 2);
	MSI_OK(uiAnswer);

	_tcscpy_s(sFilename, MAX_PATH + 1, sInstallDirectory);
	_tcscat_s(sFilename, MAX_PATH + 1, _T("perl\\lib\\Config_heavy.pl"));
	uiAnswer = RelocateFile(hModule, sFilename, 1);
	MSI_OK(uiAnswer);

	_tcscpy_s(sFilename, MAX_PATH + 1, sInstallDirectory);
	_tcscat_s(sFilename, MAX_PATH + 1, _T("perl\\lib\\CPANPLUS\\Config.pm"));
	uiAnswer = RelocateFile(hModule, sFilename, 1);
	MSI_OK(uiAnswer);

	_tcscpy_s(sFilename, MAX_PATH + 1, sInstallDirectory);
	_tcscat_s(sFilename, MAX_PATH + 1, _T("perl\\lib\\CPAN\\Config.pm"));
	uiAnswer = RelocateFile(hModule, sFilename, 2);
	MSI_OK(uiAnswer);
	uiAnswer = RelocateFile(hModule, sFilename, 3);
	MSI_OK(uiAnswer);

	_tcscpy_s(sFilename, MAX_PATH + 1, sInstallDirectory);
	_tcscat_s(sFilename, MAX_PATH + 1, _T("win32\\Strawberry Perl Release Notes.url"));
	uiAnswer = RelocateFile(hModule, sFilename, 1);
	MSI_OK(uiAnswer);

	_tcscpy_s(sFilename, MAX_PATH + 1, sInstallDirectory);
	_tcscat_s(sFilename, MAX_PATH + 1, _T("win32\\Strawberry Perl Website.url"));
	uiAnswer = RelocateFile(hModule, sFilename, 1);
	MSI_OK(uiAnswer);

	_tcscpy_s(sFilename, MAX_PATH + 1, sInstallDirectory);
	_tcscat_s(sFilename, MAX_PATH + 1, _T("perl\\site\\lib\\ppm.xml"));
	uiAnswer = RelocateFile(hModule, sFilename, 1);
	MSI_OK(uiAnswer);

	_tcscpy_s(sFilename, MAX_PATH + 1, sInstallDirectory);
	_tcscat_s(sFilename, MAX_PATH + 1, _T("perl\\vendor\\lib\\ppm.xml"));
	uiAnswer = RelocateFile(hModule, sFilename, 1);
	MSI_OK(uiAnswer);

    return uiAnswer;
}
