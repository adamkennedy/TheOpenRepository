// The following ifdef block is the standard way of creating macros which make exporting 
// from a DLL simpler. All files within this DLL are compiled with the RELOCATIONCA_EXPORTS
// symbol defined on the command line. this symbol should not be defined on any project
// that uses this DLL. This way any other project whose source files include this file see 
// RELOCATIONCA_API functions as being imported from a DLL, whereas this DLL sees symbols
// defined with this macro as being exported.
#ifdef RELOCATIONCA_EXPORTS
#define RELOCATIONCA_API __declspec(dllexport)
#else
#define RELOCATIONCA_API __declspec(dllimport)
#endif

// This class is exported from the RelocationCA.dll
class RELOCATIONCA_API CRelocationCA {
public:
	CRelocationCA(void);
	// TODO: add your methods here.
};

extern RELOCATIONCA_API int nRelocationCA;

RELOCATIONCA_API int fnRelocationCA(void);
