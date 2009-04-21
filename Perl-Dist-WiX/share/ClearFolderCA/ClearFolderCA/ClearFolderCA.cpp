// ClearFolderCA.cpp : Defines the Clear Folder custom action.
//
// Copyright (c) Curtis Jewell 2009.
//
// This code is free software; you can redistribute it and/or modify it
// under the same terms as Perl itself.

#include "stdafx.h"

#define MSI_OK(x) if (ERROR_SUCCESS != x) { \
                     return x; \
				  }

BOOL APIENTRY DllMain(HMODULE hModule,
                      DWORD  ul_reason_for_call,
                      LPVOID lpReserved
					 )
{
    return TRUE;
}

LPTSTR CreateDirectoryGUID ()
{
	GUID guid;
	CoCreateGuid(&guid);

	LPTSTR sGUID = malloc(40 * sizeof(TCHAR)); 

	_stprintf_s(sGUID, 40, 
		TEXT("DX_%.08X-%.04X-%.04X-%.02X%.02X-%.02X%.02X%.02X%.02X%.02X%.02X"),
		guid.Data1, guid.Data2, guid.Data3, 
		guid.Data4[0], guid.Data4[1], guid.Data4[2], guid.Data4[3], 
		guid.Data4[4], guid.Data4[5], guid.Data4[6], guid.Data4[7]);
		
	return sGUID;
}

LPTSTR CreateFileGUID ()
{
	GUID guid;
	CoCreateGuid(&guid);

	LPTSTR sGUID = malloc(40 * sizeof(TCHAR)); 

	_stprintf_s(sGUID, 40, 
		TEXT("FX_%.08X-%.04X-%.04X-%.02X%.02X-%.02X%.02X%.02X%.02X%.02X%.02X"),
		guid.Data1, guid.Data2, guid.Data3, 
		guid.Data4[0], guid.Data4[1], guid.Data4[2], guid.Data4[3], 
		guid.Data4[4], guid.Data4[5], guid.Data4[6], guid.Data4[7]);
		
	return sGUID;
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
	MSI_OK(uiAnswer)

	PMSIHANDLE phRecord = ::MsiCreateRecord(1);
	// ERROR: phRecord == NULL

	uiAnswer = ::MsiRecordSetString(phRecord, 1, sParentDirID);
	MSI_OK(uiAnswer)

	uiAnswer = ::MsiViewExecute(hView, phRecord);
	return uiAnswer;
}

UINT GetDirectoryID(MSIHANDLE hView, LPCTSTR sDirectory, LPTSTR sDirectoryID)
{
	PMSIHANDLE phRecord = MsiCreateRecord(2);
	UINT uiAnswer = ERROR_SUCCESS;
	TCHAR sDir[MAX_PATH + 1];
	
	sDirectoryID = NULL;
	uiAnswer = ::MsiViewFetch(hView, &phRecord);

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
	MSI_OK(uiAnswer)

	PMSIHANDLE phRecord = MsiCreateRecord(1);
	if (phRecord == NULL) {
		return ERROR_INSTALL_FAILURE;
	}

	uiAnswer = ::MsiRecordSetString(phRecord, 1, sDirectoryID);
	MSI_OK(uiAnswer)

	uiAnswer = ::MsiViewExecute(phView, phRecord);
	MSI_OK(uiAnswer)

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
	} else {
		return uiAnswer;
	}

	// Close out and get out of here.
	uiAnswer = ::MsiViewClose(phView);
	return uiAnswer;
}

UINT AddFileRecord(MSIHANDLE hModule, LPCTSTR sDirectoryID, )
{
    // FileKey = GUID, Component_ = Component key to use, Filename = "*", 
	// DirProperty = sDirectoryID, InstallMode = 2
 
}

UINT AddDirectoryRecord(MSIHANDLE hModule, LPCTSTR sParentDirID, LPCTSTR sName, LPTSTR sDirectoryID)
{
	LPCTSTR sSQL = 
		_TEXT("INSERT INTO `Directory` (`Directory`, `Directory_Parent`, `DefaultDir`) VALUES (?, ?, ?)");

	PMSIHANDLE phView;
	sDirectoryID = CreateDirectoryGUID();

	UINT uiAnswer = ERROR_SUCCESS;

	uiAnswer = ::MsiDatabaseOpenView(hModule, sSQL, &phView);
	MSI_OK(uiAnswer)

	PMSIHANDLE phRecord = MsiCreateRecord(3);
	if (phRecord == NULL) {
		return ERROR_INSTALL_FAILURE;
	}

	uiAnswer = ::MsiRecordSetString(phRecord, 1, sDirectoryID);
	MSI_OK(uiAnswer)

	uiAnswer = ::MsiRecordSetString(phRecord, 2, sParentDirID);
	MSI_OK(uiAnswer)

	uiAnswer = ::MsiRecordSetString(phRecord, 3, sName);
	MSI_OK(uiAnswer)

	uiAnswer = ::MsiViewExecute(phView, phRecord);
	MSI_OK(uiAnswer)

	uiAnswer = ::MsiViewClose(phView);
	return uiAnswer;	
}

UINT AddDirectory(MSIHANDLE hModule, LPCTSTR sDirectory, LPCTSTR sParentDirID, bool bParentIDExisted)
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
	
	if (bParentDirIDExisted) {
		uiAnswer = GetDirectoryIDView(hModule, sParentDirID, hView);
	}

	while (bAnswer & (uiAnswer == ERROR_SUCCESS)) {
		if (lpFound->dwFileAttributes && FILE_ATTRIBUTE_DIRECTORY) {
			sNewDir = (TCHAR *)malloc((MAX_PATH + 1) * sizeof(TCHAR));
			_tcscpy_s(sNewDir, MAX_PATH, sDirectory);
			_tcscat_s(sNewDir, MAX_PATH, TEXT("\\"));
			_tcscat_s(sNewDir, MAX_PATH, lpFound->cFileName);

			if (bParentDirIDExisted) {
				uiAnswer = GetDirectoryID(hView, 
					lpFound->cFileName, 
					sDirectoryID);
				MSI_OK(uiAnswer)
				if (sDirectoryID != NULL) {
					uiAnswer = AddDirectory(hModule, sNewDir, sDirectoryID, true);
					MSI_OK(uiAnswer)
				} else {
					LPTSTR sID = CreateDirectoryGUID()
					uiAnswer = AddDirectoryRecord(hModule, sDirectoryID, 
						lpFound->cFileName, 
						sID);
					MSI_OK(uiAnswer)
					
					uiAnswer = AddDirectory(hModule, sNewDir, sID, false);
					MSI_OK(uiAnswer)
				}
			} else {
				LPTSTR sID = CreateDirectoryGUID()
				uiAnswer = AddDirectoryRecord(hModule, sDirectoryID, 
					lpFound->cFileName, 
					sID);
				MSI_OK(uiAnswer)
				
				uiAnswer = AddDirectory(hModule, sNewDir, sID, false);
				MSI_OK(uiAnswer)
			}

			free((void *)sNewDir);
		} else {
			// Verify that it wasn't installed by this MSI.
			if (sDirectoryID != NULL) {
				BOOL bInstalled = FALSE;
				uiAnswer = IsFileInstalled(hModule, sDirectoryID, lpFound->cFileName, bInstalled);
				if (!bInstalled) {
					uiFoundFilesToDelete++;
				}
			} else {
				uiFoundFilesToDelete++;
			}
		}
	
		bAnswer = ::FindNextFile(hFindHandle, lpFound);
	}
	
	::FindClose(hFindHandle);
	free(sFind);
	if (hView != NULL) {
		::MsiViewClose(hView);
	}

	MSI_OK(uiAnswer)

	if (uiFoundFilesToDelete > 0) {
		// HELP: Add entry to RemoveFiles table for *.* in this directory
	}
	
	// HELP: Add entry to RemoveFiles table for this directory with empty filename
	// (in order to delete the directory)
	
	return uiAnswer;
}

// The component for TARGET_DIR/perl/bin/perl.exe
static TCHAR sComponent[40];

UINT GetComponent(MSIHANDLE hModule)
{
	LPCTSTR sSQL = 
		TEXT("SELECT `Directory` FROM `Directory` WHERE `Directory_Parent`= ?" AND `DefaultDir` = ?);

	PMSIHANDLE phView;
	UINT uiAnswer = ERROR_SUCCESS;

	uiAnswer = ::MsiDatabaseOpenView(hModule, sSQL, &phView);
	MSI_OK(uiAnswer)

	PMSIHANDLE phRecord = ::MsiCreateRecord(2);
	if (phRecord == NULL) {
		return ERROR_INSTALL_FAILURE;
	}

	uiAnswer = ::MsiRecordSetString(phRecord, 1, TEXT("TARGETDIR"));
	MSI_OK(uiAnswer)

	uiAnswer = ::MsiRecordSetString(phRecord, 2, TEXT("perl"));
	MSI_OK(uiAnswer)

	uiAnswer = ::MsiViewExecute(phView, phRecord);
	MSI_OK(uiAnswer)
	
	PMSIHANDLE phRecord = ::MsiCreateRecord(1);
	if (phAnswerRecord == NULL) {
		return ERROR_INSTALL_FAILURE;
	}

	uiAnswer = ::MsiViewFetch(hView, &phAnswerRecord);
	MSI_OK(uiAnswer)
	
	// Get the ID.
	TCHAR sID[40]
	DWORD dwLengthID = 39;
	uiAnswer = ::MsiRecordGetString(phAnswerRecord, 1, sID, &dwLengthID);
	MSI_OK(uiAnswer);
	
	uiAnswer = ::MsiRecordSetString(phRecord, 1, sID);
	MSI_OK(uiAnswer)

	uiAnswer = ::MsiRecordSetString(phRecord, 2, TEXT("bin"));
	MSI_OK(uiAnswer)

	uiAnswer = ::MsiViewExecute(phView, phRecord);
	MSI_OK(uiAnswer)

	uiAnswer = ::MsiViewFetch(hView, &phAnswerRecord);
	MSI_OK(uiAnswer)
	
	// Get the ID.
	dwLengthID = 39;
	uiAnswer = ::MsiRecordGetString(phAnswerRecord, 1, sID, &dwLengthID);
	MSI_OK(uiAnswer);
	
	uiAnswer = ::MsiViewClose(hView, &phAnswerRecord);
	MSI_OK(uiAnswer)

	LPCTSTR sSQLFile = 
		TEXT("SELECT `Component`.`Component` FROM `Component`,`File` WHERE `Component`.`Directory_` = ? AND `File`.`FileName`= ? AND `File`.`Component_` = `Component`.`Component`");

	uiAnswer = ::MsiDatabaseOpenView(hModule, sSQLFile, &phView);
	MSI_OK(uiAnswer)

	uiAnswer = ::MsiRecordSetString(phRecord, 1, sID);
	MSI_OK(uiAnswer)

	uiAnswer = ::MsiRecordSetString(phRecord, 2, TEXT("perl.exe"));
	MSI_OK(uiAnswer)

	uiAnswer = ::MsiViewExecute(phView, phRecord);
	MSI_OK(uiAnswer)

	// Get the ID.
	dwLengthID = 39;
	uiAnswer = ::MsiRecordGetString(phAnswerRecord, 1, sComponent, &dwLengthID);
	MSI_OK(uiAnswer);
	
	uiAnswer = ::MsiViewClose(hView, &phAnswerRecord);	
	return uiAnswer; 
}

UINT __stdcall ClearFolder(MSIHANDLE hModule)
{
	TCHAR sInstallDirectory[MAX_PATH + 1];
	UINT uiAnswer;
	DWORD dwPropLength = MAX_PATH; 

	uiAnswer = MsiGetProperty(hModule, TEXT("INSTALLDIR"), sInstallDirectory, &dwPropLength); 
	MSI_OK(uiAnswer)

	uiAnswer = GetComponent(hModule);
	MSI_OK(uiAnswer)
	
	uiAnswer = AddDirectory(hModule, sInstallDirectory, TEXT("TARGETDIR"), true);	
	MSI_OK(uiAnswer)
	
	uiAnswer = MsiDoAction(hModule, _T("RemoveFiles"));
	
    return uiAnswer;
}

