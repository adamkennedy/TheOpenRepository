// CleanFolderCA.c : Defines the CleanFolder Custom Action.
//
// Copyright (c) 2009 Curtis Jewell 
//
// This code is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

#include "CleanFolderCA.h"

BOOL APIENTRY DllMain( HANDLE hModule, DWORD ul_reason_for_call, LPVOID lpReserved )
{
    return TRUE;
}

UINT __stdcall CleanFolder ( MSIHANDLE hModule )
{
	LPCTSTR sInstallDirectory;
	UINT uiAnswer;
	
	// HELP: Query hModule for installation directory. [INSTALLDIR] property, IIRC.
	// Answer needs to eventually go into sInstallDirectory. 
	
	uiAnswer = AddDirectory(hModule, sInstallDirectory);
	
	if (uiAnswer != ERROR_SUCCESS) {
		return uiAnswer;
	}
	
	uiAnswer = MsiDoAction(hModule, _T("RemoveFiles"));
	
    return uiAnswer;
}

UINT __stdcall AddDirectory ( MSIHANDLE hModule, LPCTSTR sDirectory )
{
	LPCTSTR sFind = sDirectory + "\\*";
	LPCTSTR sNewDir;
	LPWIN32_FIND_DATA lpFound;
	HANDLE hFindHandle;
	UINT uiFoundFilesToDelete = 0;
	BOOL bAnswer = FALSE;
	UINT uiAnswer = ERROR_SUCCESS
	
	hFindHandle = FindFirstFile(sFind, lpFound);
	
	if (hFindHandle != INVALID_HANDLE_VALUE) {
		bAnswer = TRUE;
	}
	
	while (bAnswer & (uiAnswer == ERROR_SUCCESS))
		if (lpFound->dwFileAttributes && FILE_ATTRIBUTES_DIRECTORY) {
			sNewDir = sDirectory;
			sNewDir += "\\";
			sNewDir += lpFound + cFileName; 
			uiAnswer = AddDirectory(hModule, sNewDir);
		} else {
			uiFoundFilesToDelete++;
		}
	
		bAnswer = FindNextFile(hFindHandle, lpFound);
	}
	
	FindClose(hFindHandle);

	if (uiAnswer != ERROR_SUCCESS) {
		return uiAnswer;
	}
	
	if (uiFoundFilesToDelete > 0) {
		// HELP: Add entry to RemoveFiles table for *.* in this directory
	}
	
	// HELP: Add entry to RemoveFiles table for this directory with empty filename
	// (in order to delete the directory)
	
	return uiAnswer;
}