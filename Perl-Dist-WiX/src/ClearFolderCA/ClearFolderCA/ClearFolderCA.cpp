// ClearFolderCA.cpp : Defines the Clear Folder custom action.
//
// Copyright (c) Curtis Jewell 2009.
//
// This code is free software; you can redistribute it and/or modify it
// under the same terms as Perl itself.

/* 
<CustomAction Id='CA_ClearFolder' BinaryKey='B_ClearFolder' DllEntry='ClearFolder' />

<InstallExecuteSequence>
  <Custom Action='CA_ClearFolder' Before='InstallInitialize'>REMOVE="ALL"</Custom>
</InstallExecuteSequence>

<Binary Id='B_ClearFolder' SourceFile='share\ClearFolderCA.dll' />
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

// The component for TARGET_DIR/perl/bin/perl.exe
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

// Gets GUID for Directory columns. Return value needs to be free()'d.

LPTSTR CreateDirectoryGUID()
{
	GUID guid;
	::CoCreateGuid(&guid);

	LPTSTR sGUID = (LPTSTR)malloc(40 * sizeof(TCHAR)); 

	// Formatting GUID correctly.
	_stprintf_s(sGUID, 40, 
		TEXT("DX_%.08X_%.04X_%.04X_%.02X%.02X_%.02X%.02X%.02X%.02X%.02X%.02X"),
		guid.Data1, guid.Data2, guid.Data3, 
		guid.Data4[0], guid.Data4[1], guid.Data4[2], guid.Data4[3], 
		guid.Data4[4], guid.Data4[5], guid.Data4[6], guid.Data4[7]);

	return sGUID;
}

// Gets GUID for FileKey column. Return value needs to be free()'d.

LPTSTR CreateFileGUID()
{
	GUID guid;
	::CoCreateGuid(&guid);

	LPTSTR sGUID = (LPTSTR)malloc(40 * sizeof(TCHAR)); 

	// Formatting GUID correctly.
	_stprintf_s(sGUID, 40, 
		TEXT("FX_%.08X_%.04X_%.04X_%.02X%.02X_%.02X%.02X%.02X%.02X%.02X%.02X"),
		guid.Data1, guid.Data2, guid.Data3, 
		guid.Data4[0], guid.Data4[1], guid.Data4[2], guid.Data4[3], 
		guid.Data4[4], guid.Data4[5], guid.Data4[6], guid.Data4[7]);

	return sGUID;
}

// Operations on string to log to MSI log.

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

// Finds directory ID for directory named in sDirectory.

UINT GetDirectoryID(
	MSIHANDLE hModule,    // Handle of MSI being installed. [in]
	LPCTSTR sParentDirID, // ID of parent directory (to search in). [in]
	LPCTSTR sDirectory,   // Directory to find the ID for. [in]
	LPTSTR &sDirectoryID) // ID of directory. Can be NULL. 
	                      // Must be free()'d if not. [out]
{
	TCHAR* sSQL = 
		TEXT("SELECT `Directory`,`DefaultDir` FROM `Directory` WHERE `Directory_Parent`= ?");

	UINT uiAnswer = ERROR_SUCCESS;
	PMSIHANDLE phView;

	// Get database handle
	PMSIHANDLE phDB = ::MsiGetActiveDatabase(hModule);
	HANDLE_OK(phDB)

	// Open the view.
	uiAnswer = ::MsiDatabaseOpenView(phDB, sSQL, &phView);
	MSI_OK(uiAnswer)

	// Create and fill the record.
	PMSIHANDLE phRecordSelect = ::MsiCreateRecord(1);
	HANDLE_OK(phRecordSelect)

	uiAnswer = ::MsiRecordSetString(phRecordSelect, 1, sParentDirID);
	MSI_OK(uiAnswer)

	// Execute the SQL statement.
	uiAnswer = ::MsiViewExecute(phView, phRecordSelect);
	MSI_OK(uiAnswer)

	PMSIHANDLE phRecord = MsiCreateRecord(2);
	TCHAR sDir[MAX_PATH + 1];
	TCHAR* sPipeLocation = NULL;
	DWORD dwLengthID = 0;
	
	// Fetch the first row from the view.
	sDirectoryID = NULL;
	uiAnswer = ::MsiViewFetch(phView, &phRecord);

	while (uiAnswer == ERROR_SUCCESS) {

		// Get the directory.
		DWORD dwLengthDir = MAX_PATH;
		uiAnswer = ::MsiRecordGetString(phRecord, 2, sDir, &dwLengthDir);

		// We found our directory.
		if (_tcscmp(sDirectory, sDir) == 0) {
			dwLengthID = 0;
			uiAnswer = ::MsiRecordGetString(phRecord, 1, _T(""), &dwLengthID);
			if (uiAnswer == ERROR_MORE_DATA) {
				dwLengthID++;
				sDirectoryID = (TCHAR *)malloc(dwLengthID * sizeof(TCHAR));
				uiAnswer = ::MsiRecordGetString(phRecord, 1,sDirectoryID, &dwLengthID);
			}

			// We're done! Hurray!
			uiAnswer = ::MsiViewClose(phView);
			MSI_OK_FREE(uiAnswer, (TCHAR *)sDirectoryID)

			return uiAnswer;
		}

		sPipeLocation = _tcschr(sDir, _T('|'));
		if (sPipeLocation != NULL) {
			// Adjust the position past the pipe character.
			sPipeLocation = _tcsninc(sPipeLocation, 1); 

			// NOW compare the filename!
			if (_tcscmp(sDirectory, sPipeLocation) == 0) {
				dwLengthID = 0;
				uiAnswer = ::MsiRecordGetString(phRecord, 1, _T(""), &dwLengthID);
				if (uiAnswer == ERROR_MORE_DATA) {
					dwLengthID++;
					sDirectoryID = (TCHAR *)malloc(dwLengthID * sizeof(TCHAR));
					uiAnswer = ::MsiRecordGetString(phRecord, 1,sDirectoryID, &dwLengthID);
				}
				
				// We're done! Hurray!
				uiAnswer = ::MsiViewClose(phView);
				MSI_OK_FREE(uiAnswer, (TCHAR *)sDirectoryID)

				return uiAnswer;
			}
		}

		// Fetch the next row.
		uiAnswer = ::MsiViewFetch(phView, &phRecord);
	}

	// No more items is not an error.
	if (uiAnswer == ERROR_NO_MORE_ITEMS) {
		uiAnswer = ERROR_SUCCESS;
	}

	return uiAnswer;
}

// Is the file in sFilename in the directory referred to by sDirectoryID installed by this MSI? 
// Returned in bInstalled.

UINT IsFileInstalled(
	MSIHANDLE hModule,    // Handle of MSI being installed. [in]
	LPCTSTR sDirectoryID, // ID of directory being checked. [in]
	LPCTSTR sFilename,    // Filename to check. [in]
	bool& bInstalled)     // Whether file was installed by MSI or not. [out]
{
	TCHAR* sSQL = 
		TEXT("SELECT `File`.`FileName` FROM `Component`,`File` WHERE `Component`.`Component`=`File`.`Component_` AND `Component`.`Directory_` = ?");
	PMSIHANDLE phView;
	bInstalled = false;

	UINT uiAnswer = ERROR_SUCCESS;

	// Get database handle
	PMSIHANDLE phDB = ::MsiGetActiveDatabase(hModule);
	HANDLE_OK(phDB)

	// Open the view.
	uiAnswer = ::MsiDatabaseOpenView(phDB, sSQL, &phView);
	MSI_OK(uiAnswer)

	// Create and fill the record.
	PMSIHANDLE phRecord = MsiCreateRecord(1);
	HANDLE_OK(phRecord)

	uiAnswer = ::MsiRecordSetString(phRecord, 1, sDirectoryID);
	MSI_OK(uiAnswer)

	// Execute the view.
	uiAnswer = ::MsiViewExecute(phView, phRecord);
	MSI_OK(uiAnswer)

	TCHAR sFile[MAX_PATH + 1];
	TCHAR* sPipeLocation = NULL;
	
	// Fetch the first row.
	uiAnswer = ::MsiViewFetch(phView, &phRecord);

	while (uiAnswer == ERROR_SUCCESS) {

		// Get the filename.
		DWORD dwLengthFile = MAX_PATH + 1;
		uiAnswer = ::MsiRecordGetString(phRecord, 1, sFile, &dwLengthFile);

		// Compare the filename.
		if (_tcscmp(sFilename, sFile) == 0) {
			bInstalled = true;
			uiAnswer = ::MsiViewClose(phView);
			return uiAnswer;
		}

		sPipeLocation = _tcschr(sFile, _T('|'));
		if (sPipeLocation != NULL) {
			// Adjust the position past the pipe character.
			sPipeLocation = _tcsninc(sPipeLocation, 1); 

			// NOW compare the filename!
			if (_tcscmp(sFilename, sPipeLocation) == 0) {
				bInstalled = true;
				uiAnswer = ::MsiViewClose(phView);
				return uiAnswer;
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

// Adds a record to remove all files in the directory referred to by sDirectoryID.

UINT AddRemoveFileRecord(
	MSIHANDLE hModule,    // Handle of MSI being installed. [in]
	LPCTSTR sDirectoryID, // ID of directory to remove files from. [in]
	LPCTSTR sFileName)    // Filename to remove.
{
	LPCTSTR sSQL = 
		_TEXT("INSERT INTO `RemoveFile` (`FileKey`, `Component_`, `DirProperty`, `FileName`, `InstallMode`) VALUES (?, ?, ?, ?, 2) TEMPORARY");

	PMSIHANDLE phView;
	UINT uiAnswer = ERROR_SUCCESS;

	// Get database handle
	PMSIHANDLE phDB = ::MsiGetActiveDatabase(hModule);
	HANDLE_OK(phDB)

	// Open the view.
	uiAnswer = ::MsiDatabaseOpenView(phDB, sSQL, &phView);
	MSI_OK(uiAnswer)

	// Create a record storing the values to add.
	PMSIHANDLE phRecord = MsiCreateRecord(4);
	HANDLE_OK(phRecord)

	// Fill the record.
	LPTSTR sFileID = CreateFileGUID();

	uiAnswer = ::MsiRecordSetString(phRecord, 1, sFileID);
	MSI_OK_FREE(uiAnswer, (LPTSTR)sFileID)

	uiAnswer = ::MsiRecordSetString(phRecord, 2, sComponent);
	MSI_OK_FREE(uiAnswer, (LPTSTR)sFileID)

	uiAnswer = ::MsiRecordSetString(phRecord, 3, sDirectoryID);
	MSI_OK_FREE(uiAnswer, (LPTSTR)sFileID)

	uiAnswer = ::MsiRecordSetString(phRecord, 4, sFileName);
	MSI_OK_FREE(uiAnswer, (LPTSTR)sFileID)

	// Execute the SQL statement and close the view.
	uiAnswer = ::MsiViewExecute(phView, phRecord);
	MSI_OK_FREE(uiAnswer, (LPTSTR)sFileID)

	uiAnswer = ::MsiViewClose(phView);
	free((LPTSTR)sFileID);
	return uiAnswer;	
}

// Adds a record to remove the directory referred to by sDirectoryID.

UINT AddRemoveDirectoryRecord(
	MSIHANDLE hModule,    // Handle of MSI being installed. [in]
	LPCTSTR sDirectoryID) // ID of directory to remove. [in]
{
	LPCTSTR sSQL = 
		_TEXT("INSERT INTO `RemoveFile` (`FileKey`, `Component_`, `DirProperty`, `FileName`, `InstallMode`) VALUES (?, ?, ?, ?, 2) TEMPORARY");

	PMSIHANDLE phView;
	UINT uiAnswer = ERROR_SUCCESS;

	// Get database handle
	PMSIHANDLE phDB = ::MsiGetActiveDatabase(hModule);
	HANDLE_OK(phDB)

	// Open the view.
	uiAnswer = ::MsiDatabaseOpenView(phDB, sSQL, &phView);
	MSI_OK(uiAnswer)

	// Create a record storing the values to add.
	PMSIHANDLE phRecord = MsiCreateRecord(4);
	HANDLE_OK(phRecord)

	// Fill the record.
	LPTSTR sFileID = CreateFileGUID();

	uiAnswer = ::MsiRecordSetString(phRecord, 1, sFileID);
	MSI_OK_FREE(uiAnswer, (LPTSTR)sFileID)

	uiAnswer = ::MsiRecordSetString(phRecord, 2, sComponent);
	MSI_OK_FREE(uiAnswer, (LPTSTR)sFileID)

	uiAnswer = ::MsiRecordSetString(phRecord, 3, sDirectoryID);
	MSI_OK_FREE(uiAnswer, (LPTSTR)sFileID)

	uiAnswer = ::MsiRecordSetString(phRecord, 4, NULL);
	MSI_OK_FREE(uiAnswer, (LPTSTR)sFileID)

	// Execute the SQL statement and close the view.
	uiAnswer = ::MsiViewExecute(phView, phRecord);
	MSI_OK_FREE(uiAnswer, (LPTSTR)sFileID)

	uiAnswer = ::MsiViewClose(phView);
	free((LPTSTR)sFileID);
	return uiAnswer;	
}

// Adds a record to reference the directory referred to by sParentDirID and sName
// in sDirectoryID.
// sDirectoryID will need free()'d when done.

UINT AddDirectoryRecord(
	MSIHANDLE hModule,     // Handle of MSI being installed. [in]
	LPCTSTR sParentDirID,  // ID of parent directory. [in]
	LPCTSTR sName,         // Name of directory being added to MSI. [in]
	LPTSTR &sDirectoryID)  // ID to use when adding directory. [out]
{
	LPCTSTR sSQL = 
		_TEXT("INSERT INTO `Directory` (`Directory`, `Directory_Parent`, `DefaultDir`) VALUES (?, ?, ?) TEMPORARY");

	PMSIHANDLE phView;
	UINT uiAnswer = ERROR_SUCCESS;

	// Get database handle
	PMSIHANDLE phDB = ::MsiGetActiveDatabase(hModule);
	HANDLE_OK(phDB)

	// Open the view.
	uiAnswer = ::MsiDatabaseOpenView(phDB, sSQL, &phView);
	MSI_OK(uiAnswer)

	// Create a record storing the values to add.
	PMSIHANDLE phRecord = MsiCreateRecord(3);
	HANDLE_OK(phRecord)

	// Get the ID to add.
	sDirectoryID = CreateDirectoryGUID();

	// Fill the record.
	uiAnswer = ::MsiRecordSetString(phRecord, 1, sDirectoryID);
	MSI_OK(uiAnswer)

	uiAnswer = ::MsiRecordSetString(phRecord, 2, sParentDirID);
	MSI_OK(uiAnswer)

	uiAnswer = ::MsiRecordSetString(phRecord, 3, sName);
	MSI_OK(uiAnswer)

	// Execute the SQL statement and close the view.
	uiAnswer = ::MsiViewExecute(phView, phRecord);
	MSI_OK(uiAnswer)

	uiAnswer = ::MsiViewClose(phView);
	return uiAnswer;	
}

UINT UpdateActionData(
	MSIHANDLE hModule,  // Database Handle of MSI being installed. [in]
	LPCTSTR sDir)       // Directory to print. [in]
{
	UINT uiAnswer;

	PMSIHANDLE phRecord = ::MsiCreateRecord(1);
	HANDLE_OK(phRecord)

	uiAnswer = ::MsiRecordSetString(phRecord, 1, sDir);
	MSI_OK(uiAnswer)

	uiAnswer = ::MsiProcessMessage(hModule, INSTALLMESSAGE_ACTIONDATA, phRecord);

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

// The main routine

UINT AddDirectory(
	MSIHANDLE hModule,         // Handle of MSI being installed. [in]
	LPCTSTR sCurrentDir,       // Directory being searched. [in]
	LPCTSTR sCurrentDirID,     // ID of directory being searched. [in]
	bool bCurrentIDExisted,    // Did current ID exist in the MSI originally? [in]
	bool& bDeleteEntryCreated) // Was a delete-directory entry created by this call? [out]
{
	UINT uiAnswer = ERROR_SUCCESS;

	// Update the information 
	uiAnswer = UpdateActionData(hModule, sCurrentDir);
	MSI_OK(uiAnswer)

	// Set up the wildcard for the files to find.
	TCHAR sFind[MAX_PATH + 1];
	_tcscpy_s(sFind, MAX_PATH, sCurrentDir);
	_tcscat_s(sFind, MAX_PATH, TEXT("\\*"));

	// Set up other variables.
	TCHAR sSubDir[MAX_PATH + 1];
	WIN32_FIND_DATA found;
	TCHAR* sSubDirID = NULL;
	bool bDeleteEntryCreatedBelow = false;

	HANDLE hFindHandle;

	BOOL bFileFound = FALSE;
	bool bDirectoryFound = false;
	bool bInstalled = false;

	LPTSTR sID = CreateDirectoryGUID();

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
			_tcscpy_s(sSubDir, MAX_PATH, sCurrentDir);
			_tcscat_s(sSubDir, MAX_PATH, found.cFileName);
			_tcscat_s(sSubDir, MAX_PATH, TEXT("\\"));

			if (bCurrentIDExisted) {
				// Try and get the ID that already exists.
				uiAnswer = GetDirectoryID(hModule, 
					sCurrentDirID, 
					found.cFileName, 
					sSubDirID);
				MSI_OK_FREE(uiAnswer, LPTSTR(sID))
			}

			if (bCurrentIDExisted && (sSubDirID != NULL)) {
				// We have an existing directory ID.
				uiAnswer = AddDirectory(
					hModule, sSubDir, sSubDirID, true, bDeleteEntryCreatedBelow);
				MSI_OK_FREE_2(uiAnswer, (LPTSTR)sID, (TCHAR*)sSubDirID)
			} else {
				// We need to get a directory ID, add the property, then go down 
				// into this directory.
				sID = CreateDirectoryGUID(); 
				uiAnswer = ::MsiSetProperty(hModule, sID, sSubDir); 
				MSI_OK_FREE(uiAnswer, (LPTSTR)sID)

				StartLogString(TEXT("MSP: Added directory property with ID string: "));
				AppendLogString(sID);
				AppendLogString(TEXT(" and name: "));
				AppendLogString(sSubDir);
				uiAnswer = LogString(hModule);
				MSI_OK_FREE(uiAnswer, (LPTSTR)sID)
				
				uiAnswer = AddDirectory(
					hModule, sSubDir, sID, false, bDeleteEntryCreatedBelow);
				MSI_OK_FREE(uiAnswer, (LPTSTR)sID)
			}
		} else {
			// Verify that the file wasn't installed by this MSI.
			if (bCurrentIDExisted) {
				bInstalled = false;

				uiAnswer = IsFileInstalled(hModule, sCurrentDirID, 
					found.cFileName, bInstalled);
				MSI_OK_FREE(uiAnswer, (LPTSTR)sID)

				if (!bInstalled) {
					uiAnswer = AddRemoveFileRecord(hModule, sCurrentDirID, found.cFileName);
					MSI_OK_FREE(uiAnswer, (LPTSTR)sID)

					StartLogString(TEXT("ARFR1: Added remove file record entry with ID string: "));
					AppendLogString(sCurrentDirID);
					AppendLogString(TEXT(" and name: "));
					AppendLogString(found.cFileName);
					uiAnswer = LogString(hModule);
					MSI_OK_FREE(uiAnswer, (LPTSTR)sID)
				}
			} else {
				uiAnswer = AddRemoveFileRecord(hModule, sCurrentDirID, found.cFileName);
				MSI_OK_FREE(uiAnswer, (LPTSTR)sID)

				StartLogString(TEXT("ARFR2: Added remove file record entry with ID string: "));
				AppendLogString(sCurrentDirID);
				AppendLogString(TEXT(" and name: "));
				AppendLogString(found.cFileName);
				uiAnswer = LogString(hModule);
				MSI_OK_FREE(uiAnswer, (LPTSTR)sID)
			}
		}
	
		// Check and see if there is another file to process.
		bFileFound = ::FindNextFile(hFindHandle, &found);
	}
	
	// Close the find handle.
	::FindClose(hFindHandle);
	
	// If we are an extra directory, add an entry to delete ourselves.
	if ((!bCurrentIDExisted) || (bDeleteEntryCreatedBelow)){
		uiAnswer = AddRemoveDirectoryRecord(hModule, sCurrentDirID);
		bDeleteEntryCreated = true;
		MSI_OK_FREE(uiAnswer, (LPTSTR)sID)

		StartLogString(TEXT("ARDR: Added remove directory entry with ID string: "));
		AppendLogString(sCurrentDirID);
		AppendLogString(TEXT(" and name: "));
		AppendLogString(sCurrentDir);
		AppendLogString(TEXT("\n"));
		uiAnswer = LogString(hModule);
		MSI_OK_FREE(uiAnswer, (LPTSTR)sID)		
	} 

	if (sSubDirID != NULL) {
		free(sSubDirID);
	}

	// Clean up after ourselves.
	free((LPTSTR)sID);	
	return uiAnswer;
}

UINT GetComponent(
	MSIHANDLE hModule ) // Database Handle of MSI being installed. [in]
{
	LPCTSTR sSQL = 
		TEXT("SELECT `Directory` FROM `Directory` WHERE `Directory_Parent`= ? AND `DefaultDir` = ?");

	// Get database handle
	PMSIHANDLE phDB = ::MsiGetActiveDatabase(hModule);
	HANDLE_OK(phDB)

	PMSIHANDLE phView;
	UINT uiAnswer = ERROR_SUCCESS;

	uiAnswer = ::MsiDatabaseOpenView(phDB, sSQL, &phView);
	MSI_OK(uiAnswer)

	PMSIHANDLE phRecord = ::MsiCreateRecord(2);
	HANDLE_OK(phRecord)

	uiAnswer = ::MsiRecordSetString(phRecord, 1, TEXT("D_Perl"));
	MSI_OK(uiAnswer)

	uiAnswer = ::MsiRecordSetString(phRecord, 2, TEXT("bin"));
	MSI_OK(uiAnswer)

	uiAnswer = ::MsiViewExecute(phView, phRecord);
	MSI_OK(uiAnswer)
	
	PMSIHANDLE phAnswerRecord = ::MsiCreateRecord(1);
	HANDLE_OK(phAnswerRecord)

	uiAnswer = ::MsiViewFetch(phView, &phAnswerRecord);
	MSI_OK(uiAnswer)
	
	// Get the ID.
	TCHAR sID[40];
	DWORD dwLengthID = 39;
	uiAnswer = ::MsiRecordGetString(phAnswerRecord, 1, sID, &dwLengthID);
	MSI_OK(uiAnswer);
		
	uiAnswer = ::MsiViewClose(phView);
	MSI_OK(uiAnswer)

	LPCTSTR sSQLFile = 
		TEXT("SELECT `Component`.`Component` FROM `Component`,`File` WHERE `Component`.`Directory_` = ? AND `File`.`FileName`= ? AND `File`.`Component_` = `Component`.`Component`");

	uiAnswer = ::MsiDatabaseOpenView(phDB, sSQLFile, &phView);
	MSI_OK(uiAnswer)

	uiAnswer = ::MsiRecordSetString(phRecord, 1, sID);
	MSI_OK(uiAnswer)

	uiAnswer = ::MsiRecordSetString(phRecord, 2, TEXT("perl.exe"));
	MSI_OK(uiAnswer)

	uiAnswer = ::MsiViewExecute(phView, phRecord);
	MSI_OK(uiAnswer)

	uiAnswer = ::MsiViewFetch(phView, &phAnswerRecord);
	MSI_OK(uiAnswer)
	
	// Get the ID.
	dwLengthID = 39;
	uiAnswer = ::MsiRecordGetString(phAnswerRecord, 1, sComponent, &dwLengthID);
	MSI_OK(uiAnswer);
	
	uiAnswer = ::MsiViewClose(phView);	
	return uiAnswer; 
}

UINT InitializeActionData(
	MSIHANDLE hModule ) // Database Handle of MSI being installed. [in]
{
	UINT uiAnswer;

	PMSIHANDLE phRecord = ::MsiCreateRecord(3);
	HANDLE_OK(phRecord)

	uiAnswer = ::MsiRecordSetString(phRecord, 1, TEXT("CA_ClearFolder"));
	MSI_OK(uiAnswer)

	uiAnswer = ::MsiRecordSetString(phRecord, 2, TEXT("Searching for additional files to delete"));
	MSI_OK(uiAnswer)

	uiAnswer = ::MsiRecordSetString(phRecord, 3, TEXT("Directory: [1]"));
	MSI_OK(uiAnswer)

	uiAnswer = ::MsiProcessMessage(hModule, INSTALLMESSAGE_ACTIONSTART, phRecord);

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

UINT __stdcall ClearFolder(
	MSIHANDLE hModule) // Handle of MSI being installed. [in]
	                   // Passed to most other routines.
{
	TCHAR sInstallDirectory[MAX_PATH + 1];
	UINT uiAnswer;
	DWORD dwPropLength = MAX_PATH; 

	uiAnswer = InitializeActionData(hModule);
	MSI_OK(uiAnswer)

	// Get directory to search.
	uiAnswer = ::MsiGetProperty(hModule, TEXT("INSTALLDIR"), sInstallDirectory, &dwPropLength); 
	MSI_OK(uiAnswer)

	// Get component to add files to delete to.
	uiAnswer = GetComponent(hModule);
	MSI_OK(uiAnswer)
	
	// Start getting files to delete (recursive)
	bool bDeleteEntryCreated = false;
	uiAnswer = AddDirectory(
		hModule, sInstallDirectory, TEXT("INSTALLDIR"), true, bDeleteEntryCreated);	
	
    return uiAnswer;
}

