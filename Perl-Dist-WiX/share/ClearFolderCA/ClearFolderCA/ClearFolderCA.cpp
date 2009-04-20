// ClearFolderCA.cpp : Defines the Clear Folder custom action.
//
// Copyright (c) Curtis Jewell 2009.
//
// This code is free software; you can redistribute it and/or modify it
// under the same terms as Perl itself.

#include "stdafx.h"

BOOL APIENTRY DllMain(HMODULE hModule,
                      DWORD  ul_reason_for_call,
                      LPVOID lpReserved
					 )
{
    return TRUE;
}

UINT LogString(MSIHANDLE hModule, LPCTSTR sMessage) 
{
	PMSIHANDLE hRecord = ::MsiCreateRecord(2);

	TCHAR szTemp[MAX_PATH * 2];

	_stprintf_s(szTemp, MAX_PATH * 2, TEXT("-- MSI_LOGGING --   %s"), sMessage); 

	::MsiRecordSetString(hRecord, 0, szTemp);
	return ::MsiProcessMessage(hModule, INSTALLMESSAGE(INSTALLMESSAGE_INFO), hRecord);
}

UINT GetDirectoryIDView(MSIHANDLE hModule, 
					    LPCTSTR sParentDirID,
					    MSIHANDLE& hView)
{
	TCHAR* sSQL = 
		TEXT("SELECT `Directory`,`DefaultDir` FROM `Directory` WHERE `Directory_Parent`= ?");

	UINT uiAnswer = ERROR_SUCCESS;

	uiAnswer = ::MsiDatabaseOpenView(hModule, sSQL, &hView);

	if (uiAnswer != ERROR_SUCCESS) {
		return uiAnswer;
	}

	PMSIHANDLE phRecord = ::MsiCreateRecord(1);
	// ERROR: phRecord == NULL

	uiAnswer = ::MsiRecordSetString(phRecord, 1, sParentDirID);

	uiAnswer = ::MsiViewExecute(hView, phRecord);

	return uiAnswer;
}

UINT GetDirectoryID(MSIHANDLE hView, LPCTSTR sDirectory, LPTSTR sDirectoryID)
{
	PMSIHANDLE phRecord = MsiCreateRecord(2);
	UINT uiAnswer = ERROR_SUCCESS;
	TCHAR sDir[MAX_PATH + 1];
	
	sDirectoryID = NULL;
	uiAnswer = MsiViewFetch(hView, &phRecord);

	while (uiAnswer == ERROR_SUCCESS) {

		DWORD dwLengthDir = MAX_PATH + 1;
		uiAnswer = ::MsiRecordGetString(phRecord, 2, sDir, &dwLengthDir);

		if (_tcscmp(sDirectory, sDir) == 0) {
			DWORD dwLengthID = 0;
			uiAnswer = ::MsiRecordGetString(phRecord, 1, _T(""), &dwLengthID);
			if (uiAnswer == ERROR_MORE_DATA) {
				dwLengthID++;
				sDirectoryID = (TCHAR *)malloc(dwLengthID * sizeof(TCHAR));
				uiAnswer = ::MsiRecordGetString(phRecord, 1,sDirectoryID, &dwLengthID);
			}
			::MsiViewClose(hView);
			return ERROR_SUCCESS;
		}

		uiAnswer = ::MsiViewFetch(hView, &phRecord);
	}

	if (uiAnswer == ERROR_NO_MORE_ITEMS) {
		uiAnswer = ERROR_SUCCESS;
	}

	return uiAnswer;
}

UINT IsFileInstalled(MSIHANDLE hModule, 
					 LPCTSTR sDirectoryID, 
					 LPCTSTR sFilename, 
					 BOOL& bInstalled)
{
	TCHAR* sSQL = 
		TEXT("SELECT `File` FROM `Component`,`File` WHERE `Component`.`Component`='File`.`Component_` AND 'Component`.`` = ?");
	PMSIHANDLE phView;
	bInstalled = FALSE;

	UINT uiAnswer = ERROR_SUCCESS;

	uiAnswer = ::MsiDatabaseOpenView(hModule, sSQL, &phView);

	if (uiAnswer != ERROR_SUCCESS) {
		return uiAnswer;
	}

	PMSIHANDLE phRecord = MsiCreateRecord(1);
	if (phRecord == NULL) {
		return ERROR_INSTALL_FAILURE;
	}

	uiAnswer = ::MsiRecordSetString(phRecord, 1, sDirectoryID);

	if (uiAnswer != ERROR_SUCCESS) {
		return uiAnswer;
	}

	uiAnswer = ::MsiViewExecute(phView, phRecord);

	if (uiAnswer != ERROR_SUCCESS) {
		return uiAnswer;
	}

	TCHAR sFile[MAX_PATH + 1];
	TCHAR* sPipeLocation = NULL;
	
	// Fetch the first row.
	uiAnswer = ::MsiViewFetch(phView, &phRecord);

	while (uiAnswer == ERROR_SUCCESS) {

		// Get the filename.
		DWORD dwLengthFile = MAX_PATH + 1;
		uiAnswer = ::MsiRecordGetString(phRecord, 2, sFile, &dwLengthFile);

		// Compare the filename.
		if (_tcscmp(sFilename, sFile) == 0) {
			bInstalled = TRUE;
			::MsiViewClose(phView);
			return ERROR_SUCCESS;
		}

		sPipeLocation = _tcschr(sFile, _T('|'));
		if (sPipeLocation != NULL) {
			// Adjust the position past the pipe character.
			sPipeLocation = _tcsninc(sPipeLocation, 1); 

			// NOW compare the filename!
			if (_tcscmp(sFilename, sPipeLocation) == 0) {
				bInstalled = TRUE;
				::MsiViewClose(phView);
				return ERROR_SUCCESS;
			}
		}

		// Fetch the next row.
		uiAnswer = ::MsiViewFetch(phView, &phRecord);
	}

	// It's not an error if we had no more rows to search for.
	if (uiAnswer == ERROR_NO_MORE_ITEMS) {
		uiAnswer = ERROR_SUCCESS;
	}

	// Close out and get out of here.
	uiAnswer = ::MsiViewClose(phView);
	return uiAnswer;
}

UINT AddDirectory(MSIHANDLE hModule, LPCTSTR sDirectory, LPCTSTR sParentDirID)
{
	TCHAR * sFind = (TCHAR *)malloc((MAX_PATH + 1) * sizeof(TCHAR));

	_tcscpy_s(sFind, MAX_PATH, sDirectory); // strcpy
	_tcscat_s(sFind, MAX_PATH, TEXT("\\*"));

	TCHAR* sNewDir = NULL;
	LPWIN32_FIND_DATA lpFound;
	TCHAR* sDirectoryID = NULL;

	HANDLE hFindHandle;

	UINT uiFoundFilesToDelete = 0;
	BOOL bAnswer = FALSE;
	UINT uiAnswer = ERROR_SUCCESS;
	
	hFindHandle = ::FindFirstFile(sFind, lpFound);
	
	if (hFindHandle != INVALID_HANDLE_VALUE) {
		bAnswer = TRUE;
	}

	MSIHANDLE hView;
	
	if (sParentDirID != NULL) {
		uiAnswer = GetDirectoryIDView(hModule, sParentDirID, hView);
	}

	while (bAnswer & (uiAnswer == ERROR_SUCCESS)) {
		if (lpFound->dwFileAttributes && FILE_ATTRIBUTE_DIRECTORY) {
			sNewDir = (TCHAR *)malloc((MAX_PATH + 1) * sizeof(TCHAR));
			_tcscpy_s(sNewDir, MAX_PATH, sDirectory);
			_tcscat_s(sNewDir, MAX_PATH, TEXT("\\"));
			_tcscat_s(sNewDir, MAX_PATH, lpFound->cFileName);

			if (sParentDirID != NULL) {
				uiAnswer = GetDirectoryID(hView, 
					lpFound->cFileName, 
					sDirectoryID);
			}

			uiAnswer = AddDirectory(hModule, sNewDir, sDirectoryID);
			free((void *)sNewDir);
		} else {
			uiFoundFilesToDelete++;
			// Verify that it wasn't installed by this MSI.
			if (sDirectoryID != NULL) {
				BOOL bInstalled;
				uiAnswer = IsFileInstalled(hModule, sDirectoryID, lpFound->cFileName, bInstalled);
			} 
		}
	
		bAnswer = ::FindNextFile(hFindHandle, lpFound);
	}
	
	::FindClose(hFindHandle);
	free(sFind);
	if (hView != NULL) {
		::MsiViewClose(hView);
	}

	if (uiAnswer != ERROR_SUCCESS) {
		return uiAnswer;
	}

	if (uiFoundFilesToDelete > 0) {
		if (sDirectoryID != NULL) {
			// HELP: Add entry to RemoveFiles table for *.* in this directory
		} else {
			// TODO: Insert directory ID.
			// HELP: Add entry to RemoveFiles table for *.* in this directory
		}
	}
	

	// HELP: Add entry to RemoveFiles table for this directory with empty filename
	// (in order to delete the directory)
	
	return uiAnswer;
}

UINT __stdcall ClearFolder(MSIHANDLE hModule)
{
	TCHAR sInstallDirectory[MAX_PATH + 1];
	UINT uiAnswer;
	DWORD dwPropLength = MAX_PATH; 

	uiAnswer = MsiGetProperty(hModule, TEXT("INSTALLDIR"), sInstallDirectory, &dwPropLength); 

	if (uiAnswer != ERROR_SUCCESS) {
		return uiAnswer;
	}

	uiAnswer = AddDirectory(hModule, sInstallDirectory, TEXT("TARGETDIR"));
	
	if (uiAnswer != ERROR_SUCCESS) {
		return uiAnswer;
	}
	
	uiAnswer = MsiDoAction(hModule, _T("RemoveFiles"));
	
    return uiAnswer;
}

