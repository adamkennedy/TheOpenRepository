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
 
#define MSI_OK_FIND(x, y) \
	if (ERROR_SUCCESS != x) { \
		::FindClose(y); \
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

void StartLogString(
	LPCTSTR s) // String to start logging. [in]
{
	_tcscpy_s(sLogString, 512, s);
}

void AppendLogString(
	LPCTSTR s) // String to append to log. [in]
{
	_tcscat_s(sLogString, 512, s);
}

/* All routines after this point return UINT error codes,
 * as defined by the Win32 API reference under the Installer Functions
 * area (at http://msdn.microsoft.com/en-us/library/aa369426(VS.85).aspx ) 
 */

// Logs string in MSI log.

UINT LogString(
	MSIHANDLE hModule) // Handle of MSI being installed. [in]
{
	// Set up variables.
	PMSIHANDLE hRecord = ::MsiCreateRecord(2);
    HANDLE_OK(hRecord)

	UINT uiAnswer = ::MsiRecordSetString(hRecord, 0, sLogString);
	MSI_OK(uiAnswer)
	
	// Send the message
	uiAnswer = ::MsiProcessMessage(hModule, INSTALLMESSAGE(INSTALLMESSAGE_INFO), hRecord);

	// Corrects return value for use with MSI_OK.
	switch (uiAnswer) {
	case IDOK:
	case 0: // Means no action was taken...
		return ERROR_SUCCESS;
	case IDCANCEL:
		return ERROR_INSTALL_USEREXIT;
	default:
		return ERROR_INSTALL_FAILURE;
	}
}

UINT RelocateFile(
	MSIHANDLE hModule,    // Handle of MSI being installed. [in]
	LPCTSTR sFilename,    // Filename to relocate. [in]
	int iRelocationType)  // Whether to search for file specifications/url's with
	                      // single-backslashes (1), double-backslashes (2), or
						  // single-slashes. (3) [in]
{
	return ERROR_SUCCESS;
//	return ERROR_CALL_NOT_IMPLEMENTED;
}

UINT SearchPacklist(
	MSIHANDLE hModule,   // Handle of MSI being installed. [in]
	LPCTSTR sDirectory)  // Directory to search in. [in]
{
	// Set up the wildcard for the files to find.
	TCHAR sFind[MAX_PATH + 1];
	_tcscpy_s(sFind, MAX_PATH, sDirectory);
	_tcscat_s(sFind, MAX_PATH, TEXT("\\*"));

	// Set up other variables.
	TCHAR sSubDir[MAX_PATH + 1];
	WIN32_FIND_DATA found;
	BOOL bFileFound = FALSE;
	UINT uiAnswer = ERROR_SUCCESS;
	HANDLE hFindHandle;

	// Start finding files and directories.
	hFindHandle = ::FindFirstFile(sFind, &found);
	if (hFindHandle != INVALID_HANDLE_VALUE) {
		bFileFound = TRUE;
	}

	while (bFileFound & (uiAnswer == ERROR_SUCCESS)) {
		if ((found.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == FILE_ATTRIBUTE_DIRECTORY) {

			// Handle . and ..
			if (0 == _tcscmp(found.cFileName, TEXT("."))) {
				bFileFound = ::FindNextFile(hFindHandle, &found);
				continue;
			}

			if (0 == _tcscmp(found.cFileName, TEXT(".."))) {
				bFileFound = ::FindNextFile(hFindHandle, &found);
				continue;
			}

			// Create a new directory spec to recurse into.
			_tcscpy_s(sSubDir, MAX_PATH, sFind);
			_tcscat_s(sSubDir, MAX_PATH, found.cFileName);

			uiAnswer = SearchPacklist(hModule, sSubDir);
		} else {
			if (0 == _tcscmp(found.cFileName, TEXT(".packlist"))) {

				// Create a new directory spec to recurse into.
				_tcscpy_s(sSubDir, MAX_PATH, sFind);
				_tcscat_s(sSubDir, MAX_PATH, found.cFileName);
				uiAnswer = RelocateFile(hModule, sSubDir, 1);
				MSI_OK_FIND(uiAnswer, hFindHandle)

				StartLogString(TEXT("SP: Relocating file: "));
				AppendLogString(sSubDir);
				uiAnswer = LogString(hModule);
				MSI_OK_FIND(uiAnswer, hFindHandle)
			}
		}

		// Find the next file spec.
		bFileFound = ::FindNextFile(hFindHandle, &found);
	}

	// Close the find handle.
	::FindClose(hFindHandle);

	return uiAnswer;
}

UINT SearchPacklistCore(
	MSIHANDLE hModule,          // Handle of MSI being installed. [in]
	LPCTSTR sInstallDirectory)  // Filename to relocate. [in]
{
	TCHAR sFilename[MAX_PATH + 1];

	_tcscpy_s(sFilename, MAX_PATH, sInstallDirectory);
	_tcscat_s(sFilename, MAX_PATH, _T("perl\\lib\\auto"));

	return SearchPacklist(hModule, sFilename);
}

UINT SearchPacklistVendor(
	MSIHANDLE hModule,          // Handle of MSI being installed. [in]
	LPCTSTR sInstallDirectory)  // Filename to relocate. [in]
{
	TCHAR sFilename[MAX_PATH + 1];

	_tcscpy_s(sFilename, MAX_PATH, sInstallDirectory);
	_tcscat_s(sFilename, MAX_PATH, _T("perl\\vendor\\lib\\auto"));

	return SearchPacklist(hModule, sFilename);
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

	uiAnswer = SearchPacklistCore(hModule, sInstallDirectory);

	uiAnswer = SearchPacklistVendor(hModule, sInstallDirectory);

	// TODO: Search for the files in perl\bin that are not *.exe and *.dll files.

	_tcscpy_s(sFilename, MAX_PATH, sInstallDirectory);
	_tcscat_s(sFilename, MAX_PATH, _T("perl\\lib\\CORE\\config.h"));
	uiAnswer = RelocateFile(hModule, sFilename, 2);
	MSI_OK(uiAnswer)

	_tcscpy_s(sFilename, MAX_PATH, sInstallDirectory);
	_tcscat_s(sFilename, MAX_PATH, _T("perl\\lib\\Config.pm"));
	uiAnswer = RelocateFile(hModule, sFilename, 2);
	MSI_OK(uiAnswer)

	_tcscpy_s(sFilename, MAX_PATH, sInstallDirectory);
	_tcscat_s(sFilename, MAX_PATH, _T("perl\\lib\\Config_heavy.pl"));
	uiAnswer = RelocateFile(hModule, sFilename, 1);
	MSI_OK(uiAnswer)

	_tcscpy_s(sFilename, MAX_PATH, sInstallDirectory);
	_tcscat_s(sFilename, MAX_PATH, _T("perl\\lib\\CPANPLUS\\Config.pm"));
	uiAnswer = RelocateFile(hModule, sFilename, 1);
	MSI_OK(uiAnswer)

	_tcscpy_s(sFilename, MAX_PATH, sInstallDirectory);
	_tcscat_s(sFilename, MAX_PATH, _T("perl\\lib\\CPAN\\Config.pm"));
	uiAnswer = RelocateFile(hModule, sFilename, 2);
	MSI_OK(uiAnswer)
	uiAnswer = RelocateFile(hModule, sFilename, 3);
	MSI_OK(uiAnswer)

	_tcscpy_s(sFilename, MAX_PATH, sInstallDirectory);
	_tcscat_s(sFilename, MAX_PATH, _T("win32\\Strawberry Perl Release Notes.url"));
	uiAnswer = RelocateFile(hModule, sFilename, 1);
	MSI_OK(uiAnswer)

	_tcscpy_s(sFilename, MAX_PATH, sInstallDirectory);
	_tcscat_s(sFilename, MAX_PATH, _T("win32\\Strawberry Perl Website.url"));
	uiAnswer = RelocateFile(hModule, sFilename, 1);
	MSI_OK(uiAnswer)

	_tcscpy_s(sFilename, MAX_PATH, sInstallDirectory);
	_tcscat_s(sFilename, MAX_PATH, _T("perl\\site\\lib\\ppm.xml"));
	uiAnswer = RelocateFile(hModule, sFilename, 1);
	MSI_OK(uiAnswer)

	_tcscpy_s(sFilename, MAX_PATH, sInstallDirectory);
	_tcscat_s(sFilename, MAX_PATH, _T("perl\\vendor\\lib\\ppm.xml"));
	uiAnswer = RelocateFile(hModule, sFilename, 1);
    return uiAnswer;
}
