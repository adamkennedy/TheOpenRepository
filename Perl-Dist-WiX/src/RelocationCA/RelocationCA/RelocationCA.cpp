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

<Property Id='FilesRelocateSingle'>5</Property>
<Property Id='FileRelocateSingle1'>perl\X\Y</Property>
<Property Id='FilesRelocateDouble'>7</Property>
<Property Id='FileRelocateDouble1'>perl\X\Y</Property>
<Property Id='FilesRelocateSlashes'>2</Property>
<Property Id='FileRelocateSlashes1'>perl\X\Y</Property>
<Property Id='RelocateFrom'>C:\strawberry</Property>


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

static char sRelocateFrom_a[MAX_PATH + 1];
static char sRelocateTo_a[MAX_PATH + 1];

static char sRelocateFromDouble_a[MAX_PATH + 11];
static char sRelocateToDouble_a[MAX_PATH + 11];

static char sRelocateFromSlashes_a[MAX_PATH + 1];
static char sRelocateToSlashes_a[MAX_PATH + 1];


UINT RelocateFile(
	MSIHANDLE hModule,          // Handle of MSI being installed. [in]
	LPCTSTR sFilename,          // Filename to relocate. [in]
	int iRelocationType)        // Whether to search for file specifications/url's with
	                            // single-backslashes (1), double-backslashes (2), or
						        // single-slashes. (3) [in]
{
	return ERROR_SUCCESS;
//	return ERROR_CALL_NOT_IMPLEMENTED;
}

UINT RelocateBatchFile(         // iRelocationType = 1.
	MSIHANDLE hModule,          // Handle of MSI being installed. [in]
	LPCTSTR sFilename)          // Filename to relocate. [in]
{
	FILE* fileRead;
	FILE* fileWrite;
	UINT uiAnswer;

	DWORD dwLength = MAX_PATH;
	TCHAR sTempPath[MAX_PATH + 1];
	uiAnswer = ::GetTempPath(dwLength, sTempPath);
	if (uiAnswer == 0) {
		return ERROR_INSTALL_FAILURE;
	}

	TCHAR sTempFile[MAX_PATH + 1];
	uiAnswer = ::GetTempFileName(sTempPath, TEXT("PerlRelocate"), 0, sTempFile);
	if (uiAnswer == 0) {
		return ERROR_INSTALL_FAILURE;
	}

	uiAnswer = ::CopyFile(sFilename, sTempFile, FALSE);
	if (uiAnswer == 0) {
		return ERROR_INSTALL_FAILURE;
	}

	_tfopen_s(&fileRead, sTempFile, TEXT("rSD"));
	_tfopen_s(&fileWrite, sFilename, TEXT("wc"));
	if ((fileRead == NULL) || (fileWrite == NULL)) {
		return ERROR_INSTALL_FAILURE;
	}
	char sWork[32768];
	char sNew[32768];

	char* ch;
	int iLocation;
	size_t iLengthAfter;
	size_t iLength;

	// For batch files, we only need to relocate the first line.
	fgets(sWork, 32767, fileRead);

	ch = strstr(sWork, sRelocateFrom_a);  // TODO: Need a Unicode conversion.
	iLocation = (int)(ch - sWork + 1);
	iLength = strlen(sRelocateTo_a);
	iLengthAfter = strlen(sWork) - iLocation + iLength + 1;

	strncat_s(sNew, 32768, sWork, iLocation);
	strcat_s(sNew, 32768, sRelocateTo_a);
	strncat_s(sNew, 32768, sWork + iLocation + iLength, iLengthAfter);

	fputs(sNew, fileWrite);

	size_t iCount = 1;

	// Quickly scan the rest of the file.
	while((iCount != 0) && !feof(fileRead)) {
		iCount = fread((void*)sWork, 1, 32767, fileRead);
		if (iCount > 0) {
			fwrite((void*)sWork, 1, iCount, fileWrite);
		}
	}

	fclose(fileRead);
	fclose(fileWrite);

	::DeleteFile(sTempFile);
	if (uiAnswer == 0) {
		return ERROR_INSTALL_FAILURE;
	}

	return ERROR_SUCCESS;
}

UINT SearchPacklist(
	MSIHANDLE hModule,          // Handle of MSI being installed. [in]
	LPCTSTR sDirectory)         // Directory to search in. [in]
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

UINT SearchBatchFiles(
	MSIHANDLE hModule,          // Handle of MSI being installed. [in]
	LPCTSTR sDirectory)         // Directory to search in. [in]
{
	// Set up the wildcard for the files to find.
	TCHAR sFind[MAX_PATH + 1];
	_tcscpy_s(sFind, MAX_PATH, sDirectory);
	_tcscat_s(sFind, MAX_PATH, TEXT("\\*.bat"));

	// Set up other variables.
	TCHAR sFile[MAX_PATH + 1];
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

			bFileFound = ::FindNextFile(hFindHandle, &found);
			continue;
		} else {
			// Relocate the file.
			_tcscpy_s(sFile, MAX_PATH, sDirectory);
			_tcscat_s(sFile, MAX_PATH, TEXT("\\"));
			_tcscat_s(sFile, MAX_PATH, found.cFileName);
			uiAnswer = RelocateBatchFile(hModule, sFile);
			MSI_OK_FIND(uiAnswer, hFindHandle)

			StartLogString(TEXT("SP: Relocating file: "));
			AppendLogString(sFile);
			uiAnswer = LogString(hModule);
			MSI_OK_FIND(uiAnswer, hFindHandle)
		}

		// Find the next file spec.
		bFileFound = ::FindNextFile(hFindHandle, &found);
	}

	// Close the find handle.
	::FindClose(hFindHandle);

	return uiAnswer;
}


UINT SearchPacklistCore(
	MSIHANDLE hModule)          // Handle of MSI being installed. [in]
{
	TCHAR sFilename[MAX_PATH + 1];

	_tcscpy_s(sFilename, MAX_PATH, sRelocateTo);
	_tcscat_s(sFilename, MAX_PATH, _T("perl\\lib\\auto"));

	return SearchPacklist(hModule, sFilename);
}

UINT SearchPacklistVendor(
	MSIHANDLE hModule)          // Handle of MSI being installed. [in]
{
	TCHAR sFilename[MAX_PATH + 1];

	_tcscpy_s(sFilename, MAX_PATH, sRelocateTo);
	_tcscat_s(sFilename, MAX_PATH, _T("perl\\vendor\\lib\\auto"));

	return SearchPacklist(hModule, sFilename);
}

UINT FileLoop(
	MSIHANDLE hModule,          // Handle of MSI being installed. [in]
	int iNumberFiles,           // Number of files to attempt to find. [in]
	LPCTSTR sFilePropertyName,  // Base of property name for files. [in]
	LPCTSTR sMergeModuleID,     // Merge Module ID. [in]
	int iRelocationType,        // Type of relocation to do. [in]
	LPCTSTR sRelocateFrom,      // Directory to relocate from. [in]
	LPCTSTR sRelocateTo)        // Directory to relocate to. [in]
{

	UINT uiAnswer;
	DWORD dwPropLength = MAX_PATH;
	TCHAR sProperty[81];
	TCHAR sFilename[MAX_PATH + 1];

	int i;
	for (i = 1; i <= iNumberFiles; i++) {
		_stprintf_s(sProperty, 80, TEXT("%s%d"), sFilePropertyName, i);
		if (sMergeModuleID != NULL) {
			_tcscat_s(sProperty, 80, TEXT("."));
			_tcscat_s(sProperty, 80, sMergeModuleID);
		}
		dwPropLength = MAX_PATH; 
		uiAnswer = ::MsiGetProperty(hModule, sProperty, sFilename, &dwPropLength); 
		MSI_OK(uiAnswer)

		uiAnswer = RelocateFile(hModule, sFilename, iRelocationType);
		MSI_OK(uiAnswer)
	}

	return ERROR_SUCCESS;
}

/* Fills the variables needed for the other types of relocation. */
UINT FixPaths(
	MSIHANDLE /* hModule */)   // Handle of MSI being installed. [in]
{
	/* Make the forward-slash version. */

	_tcscpy_s(sRelocateFromSlashes, MAX_PATH, sRelocateFrom);
	_tcscpy_s(sRelocateToSlashes,   MAX_PATH, sRelocateTo);

	TCHAR *ch;

	ch = _tcschr(sRelocateFromSlashes, _T('\\'));
	while (NULL != ch) {
		*ch = '/';
		ch = _tcschr(ch + 1, _T('\\'));
	}

	ch = _tcschr(sRelocateToSlashes, _T('\\'));
	while (NULL != ch) {
		*ch = '/';
		ch = _tcschr(ch + 1, _T('\\'));
	}

	/* Make the double-slash version. */

	TCHAR sWork[MAX_PATH + 11];
	int iLocation;
	size_t iLengthAfter;

	ch = _tcschr(sRelocateFromDouble, _T('\\'));
	while (NULL != ch) {
		iLocation = (int)(ch - sRelocateFromDouble + 1);
		iLengthAfter = _tcslen(sRelocateFromDouble) - iLocation;
		_tcsncat_s(sWork, MAX_PATH + 10, sRelocateFromDouble, iLocation);
		_tcscat_s(sWork, MAX_PATH + 10, _T("\\\\"));
		_tcsncat_s(sWork, MAX_PATH + 10, sRelocateFromDouble + iLocation, iLengthAfter);

		_tcscpy_s(sRelocateFromDouble, MAX_PATH + 10, sWork);
		ch = _tcschr(ch + 2, _T('\\'));
	}

	ch = _tcschr(sRelocateToDouble, _T('\\'));
	while (NULL != ch) {
		iLocation = (int)(ch - sRelocateToDouble + 1);
		iLengthAfter = _tcslen(sRelocateToDouble) - iLocation;;
		_tcsncat_s(sWork, MAX_PATH + 10, sRelocateToDouble, iLocation);
		_tcscat_s(sWork, MAX_PATH + 10, _T("\\\\"));
		_tcsncat_s(sWork, MAX_PATH + 10, sRelocateToDouble + iLocation, iLengthAfter);

		_tcscpy_s(sRelocateToDouble, MAX_PATH + 10, sWork);
		ch = _tcschr(ch + 2, _T('\\'));
	}

	if (0 == WideCharToMultiByte(CP_ACP, 0, sRelocateFrom, -1, sRelocateFrom_a,
		MAX_PATH, NULL, NULL)) {
		return ERROR_INSTALL_FAILURE;
	}

	if (0 == WideCharToMultiByte(CP_ACP, 0, sRelocateTo, -1, sRelocateTo_a,
		MAX_PATH, NULL, NULL)) {
		return ERROR_INSTALL_FAILURE;
	}

	if (0 == WideCharToMultiByte(CP_ACP, 0, sRelocateFromSlashes, -1, sRelocateFromSlashes_a,
		MAX_PATH, NULL, NULL)) {
		return ERROR_INSTALL_FAILURE;
	}

	if (0 == WideCharToMultiByte(CP_ACP, 0, sRelocateToSlashes, -1, sRelocateToSlashes_a,
		MAX_PATH, NULL, NULL)) {
		return ERROR_INSTALL_FAILURE;
	}

	if (0 == WideCharToMultiByte(CP_ACP, 0, sRelocateFromDouble, -1, sRelocateFromDouble_a,
		MAX_PATH, NULL, NULL)) {
		return ERROR_INSTALL_FAILURE;
	}

	if (0 == WideCharToMultiByte(CP_ACP, 0, sRelocateToDouble, -1, sRelocateToDouble_a,
		MAX_PATH, NULL, NULL)) {
		return ERROR_INSTALL_FAILURE;
	}

	return ERROR_SUCCESS;
}

UINT __stdcall Relocation(
	MSIHANDLE hModule) // Handle of MSI being installed. [in]
	                   // Passed to most other routines.
{
	UINT uiAnswer;
	DWORD dwPropLength = MAX_PATH; 

	// Get merge module ID.
	TCHAR sPerlModuleID[40];
	dwPropLength = 39; 
	uiAnswer = ::MsiGetProperty(hModule, TEXT("PerlModuleID"), sPerlModuleID, &dwPropLength); 
	MSI_OK(uiAnswer)

	// Get directory to relocate to.
	TCHAR sRelocateTo[MAX_PATH + 1];
	dwPropLength = MAX_PATH; 
	uiAnswer = ::MsiGetProperty(hModule, TEXT("INSTALLDIR"), sRelocateTo, &dwPropLength); 
	MSI_OK(uiAnswer)

	// Get directory to relocate from.
	TCHAR sRelocateFrom[MAX_PATH + 1];
	dwPropLength = MAX_PATH; 
	uiAnswer = ::MsiGetProperty(hModule, TEXT("RelocateFrom"), sRelocateFrom, &dwPropLength); 
	MSI_OK(uiAnswer)

	uiAnswer = FixPaths(hModule);
	MSI_OK(uiAnswer)

	uiAnswer = SearchPacklistCore(hModule);
	MSI_OK(uiAnswer)

	uiAnswer = SearchPacklistVendor(hModule);
	MSI_OK(uiAnswer)

	TCHAR sFilename[MAX_PATH + 1];
	_tcscpy_s(sFilename, MAX_PATH, sRelocateTo);
	_tcscat_s(sFilename, MAX_PATH, _T("perl\\bin"));
	uiAnswer = SearchBatchFiles(hModule, sFilename);
	MSI_OK(uiAnswer)

	TCHAR sNumber[6];
	int iNumber;
	TCHAR sProperty[71];

	// Relocate single-backslash files.
	//

	if (_tcscmp(sPerlModuleID, TEXT("")) != 0) {
		// Get number of files to search in merge module.
		_tcscpy_s(sProperty, 70, TEXT("FilesRelocateSingle"));
		_tcscat_s(sProperty, 70, sPerlModuleID);
		dwPropLength = 5; 
		uiAnswer = ::MsiGetProperty(hModule, sProperty, sNumber, &dwPropLength); 
		MSI_OK(uiAnswer)

		uiAnswer = _stscanf_s(sNumber, TEXT("%d"), &iNumber);
		if (uiAnswer != 1) {
			return ERROR_INSTALL_FAILURE;
		}

		uiAnswer = FileLoop(hModule, iNumber, TEXT("FileRelocateSingle"), sPerlModuleID, 1, sRelocateFrom, sRelocateTo);
	}

	// Get number of files to search.
	dwPropLength = 5; 
	uiAnswer = ::MsiGetProperty(hModule, TEXT("FilesRelocateSingle"), sNumber, &dwPropLength); 
	MSI_OK(uiAnswer)

	uiAnswer = _stscanf_s(sNumber, TEXT("%d"), &iNumber);
	if (uiAnswer != 1) {
		return ERROR_INSTALL_FAILURE;
	}

	uiAnswer = FileLoop(hModule, iNumber, TEXT("FileRelocateSingle"), NULL, 1, sRelocateFrom, sRelocateTo);

	// Relocate double-backslash files.
	//

	if (_tcscmp(sPerlModuleID, TEXT("")) != 0) {
		// Get number of files to search.
		_tcscpy_s(sProperty, 70, TEXT("FilesRelocateDouble"));
		_tcscat_s(sProperty, 70, sPerlModuleID);
		dwPropLength = 5; 
		uiAnswer = ::MsiGetProperty(hModule, sProperty, sNumber, &dwPropLength); 
		MSI_OK(uiAnswer)

		uiAnswer = _stscanf_s(sNumber, TEXT("%d"), &iNumber);
		if (uiAnswer != 1) {
			return ERROR_INSTALL_FAILURE;
		}

		uiAnswer = FileLoop(hModule, iNumber, TEXT("FileRelocateDouble"), sPerlModuleID, 2, sRelocateFrom, sRelocateTo);
	}

	dwPropLength = 5;
	uiAnswer = ::MsiGetProperty(hModule, TEXT("FilesRelocateDouble"), sNumber, &dwPropLength); 
	MSI_OK(uiAnswer)

	uiAnswer = _stscanf_s(sNumber, TEXT("%d"), &iNumber);
	if (uiAnswer != 1) {
		return ERROR_INSTALL_FAILURE;
	}

	uiAnswer = FileLoop(hModule, iNumber, TEXT("FileRelocateDouble"), NULL, 2, sRelocateFrom, sRelocateTo);

	// Relocate single-slash files.
	//
	//

	if (_tcscmp(sPerlModuleID, TEXT("")) != 0) {
		// Get number of files to search.
		_tcscpy_s(sProperty, 70, TEXT("FilesRelocateSlashes"));
		_tcscat_s(sProperty, 70, sPerlModuleID);
		dwPropLength = 5; 
		uiAnswer = ::MsiGetProperty(hModule, sProperty, sNumber, &dwPropLength); 
		MSI_OK(uiAnswer)

		uiAnswer = _stscanf_s(sNumber, TEXT("%d"), &iNumber);
		if (uiAnswer != 1) {
			return ERROR_INSTALL_FAILURE;
		}

		uiAnswer = FileLoop(hModule, iNumber, TEXT("FileRelocateSlashes"), sPerlModuleID, 3, sRelocateFrom, sRelocateTo);
	}

	dwPropLength = 5; 
	uiAnswer = ::MsiGetProperty(hModule, TEXT("FilesRelocateSlashes"), sNumber, &dwPropLength); 
	MSI_OK(uiAnswer)

	uiAnswer = _stscanf_s(sNumber, TEXT("%d"), &iNumber);
	if (uiAnswer != 1) {
		return ERROR_INSTALL_FAILURE;
	}

	uiAnswer = FileLoop(hModule, iNumber, TEXT("FileRelocateSlashes"), NULL, 3, sRelocateFrom, sRelocateTo);

    return uiAnswer;
}
