# rbc.decls -- -*- tcl -*-
#
# This file contains the declarations for all supported public functions
# that are exported by the RBC library via the stubs table. This file
# is used to generate the rbcDecls.h/rbcStubsLib.c/rbcStubsInit.c
# files.
#

# Declare each of the functions in the public RBC interface.  Note that
# the an index should never be reused for a different function in order
# to preserve backwards compatibility.

library rbc

interface rbc
scspec RBCAPI

#########################################################################
###  Reading and writing image data from channels and/or strings.

declare 0 {
    int Rbc_CreateVector(Tcl_Interp *interp, char *vecName, int size, Rbc_Vector ** vecPtrPtr)
}

declare 1 {
    int Rbc_GetVector (Tcl_Interp *interp, char *vecName, Rbc_Vector **vecPtrPtr)
}

declare 2 {
    int Rbc_ResizeVector (Rbc_Vector *vecPtr, int nValues)
}

declare 3 {
    char *Rbc_NameOfVector (Rbc_Vector *vecPtr)
}

declare 4 {
    int Rbc_ResetVector (Rbc_Vector *vecPtr, double *dataArr, int nValues, int arraySize, Tcl_FreeProc *freeProc)
}

declare 5 {
    double *Rbc_VecData (Rbc_Vector *v)
}

declare 6 {
    int Rbc_VecLength (Rbc_Vector *v)
}

declare 7 {
    int Rbc_VecSize (Rbc_Vector *v)
}

declare 8 {
    int Rbc_VecDirty (Rbc_Vector *v)
}
