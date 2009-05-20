/*
 * rbcGraph.c --
 *
 *      This module implements a graph widget for the rbc toolkit.
 *
 * Copyright (c) 2009 Samuel Green, Nicholas Hudson, Stanton Sievers, Jarrod Stormo
 * All rights reserved.
 *
 * See "license.terms" for details.
 */

/*
 * To do:
 *
 * 2) Update manual pages.
 *
 * 3) Update comments.
 *
 * 5) Surface, contour, and flow graphs
 *
 * 7) Arrows for line markers
 *
 */

#include "rbcGraph.h"
#include "rbcBind.h"
#include "rbcGrElem.h"
#include "rbcSwitch.h"
#include <X11/Xutil.h>

Rbc_Uid rbcXAxisUid;
Rbc_Uid rbcYAxisUid;
Rbc_Uid rbcBarElementUid;
Rbc_Uid rbcLineElementUid;
Rbc_Uid rbcStripElementUid;
Rbc_Uid rbcContourElementUid;
Rbc_Uid rbcLineMarkerUid;
Rbc_Uid rbcBitmapMarkerUid;
Rbc_Uid rbcImageMarkerUid;
Rbc_Uid rbcTextMarkerUid;
Rbc_Uid rbcPolygonMarkerUid;
Rbc_Uid rbcWindowMarkerUid;

Tk_ObjCustomOption rbcObjDistanceOption;
Tk_ObjCustomOption rbcObjBarModeOption;
Tk_ObjCustomOption rbcObjPadOption;
Tk_ObjCustomOption rbcObjTileOption;
Tk_ObjCustomOption rbcObjShadowOption;

#define DEF_GRAPH_ASPECT_RATIO		"0.0"
#define DEF_GRAPH_BAR_BASELINE		"0.0"
#define DEF_GRAPH_BAR_MODE		"normal"
#define DEF_GRAPH_BAR_WIDTH		"0.8"
#define DEF_GRAPH_BACKGROUND		STD_NORMAL_BACKGROUND
#define DEF_GRAPH_BG_MONO		STD_NORMAL_BG_MONO
#define DEF_GRAPH_BORDERWIDTH		STD_BORDERWIDTH
#define DEF_GRAPH_BUFFER_ELEMENTS	"1"
#define DEF_GRAPH_BUFFER_GRAPH		"1"
#define DEF_GRAPH_CURSOR		"crosshair"
#define DEF_GRAPH_FONT			STD_FONT_LARGE
#define DEF_GRAPH_HALO			"2m"
#define DEF_GRAPH_HALO_BAR		"0.1i"
#define DEF_GRAPH_HEIGHT		"4i"
#define DEF_GRAPH_HIGHLIGHT_BACKGROUND	STD_NORMAL_BACKGROUND
#define DEF_GRAPH_HIGHLIGHT_BG_MONO	STD_NORMAL_BG_MONO
#define DEF_GRAPH_HIGHLIGHT_COLOR	RGB_BLACK
#define DEF_GRAPH_HIGHLIGHT_WIDTH	"2"
#define DEF_GRAPH_INVERT_XY		"0"
#define DEF_GRAPH_JUSTIFY		"center"
#define DEF_GRAPH_MARGIN		"0"
#define DEF_GRAPH_MARGIN_VAR		(char *)NULL
#define DEF_GRAPH_PLOT_BACKGROUND		RGB_WHITE
#define DEF_GRAPH_PLOT_BG_MONO		RGB_WHITE
#define DEF_GRAPH_PLOT_BW_COLOR		STD_BORDERWIDTH
#define DEF_GRAPH_PLOT_BW_MONO		"0"
#define DEF_GRAPH_PLOT_PADX		"8"
#define DEF_GRAPH_PLOT_PADY		"8"
#define DEF_GRAPH_PLOT_RELIEF		"sunken"
#define DEF_GRAPH_RELIEF		"flat"
#define DEF_GRAPH_SHADOW_COLOR		(char *)NULL
#define DEF_GRAPH_SHADOW_MONO		(char *)NULL
#define DEF_GRAPH_SHOW_VALUES		"no"
#define DEF_GRAPH_TAKE_FOCUS		""
#define DEF_GRAPH_TITLE			(char *)NULL
#define DEF_GRAPH_TITLE_COLOR		STD_NORMAL_FOREGROUND
#define DEF_GRAPH_TITLE_MONO		STD_NORMAL_FG_MONO
#define DEF_GRAPH_WIDTH			"5i"
#define DEF_GRAPH_DATA			(char *)NULL
#define DEF_GRAPH_DATA_COMMAND		(char *)NULL

#define INVERTXY_MASK             1L << 1
#define RESET_WORLD_MASK          1L << 2
#define REDRAW_BACKING_STORE_MASK 1L << 3

static CONST84 char *subCmds[] = { "axis", "bar", "cget", "configure", "crosshairs", "element",
		                           "extents", "grid", "inside", "invtransform", "legend", "line",
		                           "marker", "pen", "postscript", "snap", "transform", "x2axis",
		                           "xaxis", "y2axis", "yaxis",
                                 NULL
                               };
enum cmdIdx {
	axisIdx,
	barIdx,
	cgetIdx,
	configureIdx,
	crosshairsIdx,
	elementIdx,
	extentsIdx,
	gridIdx,
	insideIdx,
	invtransformIdx,
	legendIdx,
	lineIdx,
	markerIdx,
	penIdx,
	postscriptIdx,
	snapIdx,
	transformIdx,
	x2axisIdx,
	xaxisIdx,
	y2axisIdx,
	yaxisIdx
};

static Tk_OptionSpec optionSpecs[] = {
    {TK_OPTION_DOUBLE, "-aspect", "aspect", "Aspect", DEF_GRAPH_ASPECT_RATIO, -1, Tk_Offset(Graph, aspect), TK_OPTION_DONT_SET_DEFAULT, 0, RESET_WORLD_MASK},
    {TK_OPTION_BORDER, "-background", "background", "Background", DEF_GRAPH_BACKGROUND, -1, Tk_Offset(Graph, border), 0, (ClientData)DEF_GRAPH_BG_MONO, 0},
    {TK_OPTION_CUSTOM, "-barmode", "barMode", "BarMode", DEF_GRAPH_BAR_MODE, -1, Tk_Offset(Graph, mode), TK_OPTION_DONT_SET_DEFAULT, &rbcObjBarModeOption, RESET_WORLD_MASK},
    {TK_OPTION_DOUBLE, "-barwidth", "barWidth", "BarWidth", DEF_GRAPH_BAR_WIDTH, -1, Tk_Offset(Graph, barWidth), 0, 0, RESET_WORLD_MASK},
    {TK_OPTION_DOUBLE, "-baseline", "baseline", "Baseline", DEF_GRAPH_BAR_BASELINE, -1, Tk_Offset(Graph, baseline), 0, 0, 0},
    {TK_OPTION_SYNONYM, "-bd", (char *) NULL, (char *) NULL, (char *) NULL, 0, -1, 0, (ClientData) "-borderwidth", RESET_WORLD_MASK},
    {TK_OPTION_SYNONYM, "-bg", (char *) NULL, (char *) NULL, (char *) NULL, 0, -1, 0, (ClientData) "-background", 0},
    {TK_OPTION_SYNONYM, "-bm", (char *) NULL, (char *) NULL, (char *) NULL, 0, -1, 0, (ClientData) "-bottommargin", RESET_WORLD_MASK},
    {TK_OPTION_CUSTOM, "-borderwidth", "borderWidth", "BorderWidth", DEF_GRAPH_BORDERWIDTH, -1, Tk_Offset(Graph, borderWidth), TK_OPTION_DONT_SET_DEFAULT, &rbcObjDistanceOption, RESET_WORLD_MASK},
    {TK_OPTION_CUSTOM, "-bottommargin", "bottomMargin", "Margin", DEF_GRAPH_MARGIN, -1, Tk_Offset(Graph, bottomMargin.reqSize), 0, &rbcObjDistanceOption, RESET_WORLD_MASK},
    {TK_OPTION_STRING, "-bottomvariable", "bottomVariable", "BottomVariable", DEF_GRAPH_MARGIN_VAR, -1, Tk_Offset(Graph, bottomMargin.varName), TK_OPTION_NULL_OK, 0, 0},
    {TK_OPTION_BOOLEAN, "-bufferelements", "bufferElements", "BufferElements", DEF_GRAPH_BUFFER_ELEMENTS, -1, Tk_Offset(Graph, backingStore), TK_OPTION_DONT_SET_DEFAULT, 0, 0},
    {TK_OPTION_BOOLEAN, "-buffergraph", "bufferGraph", "BufferGraph", DEF_GRAPH_BUFFER_GRAPH, -1, Tk_Offset(Graph, doubleBuffer), TK_OPTION_DONT_SET_DEFAULT, 0, 0},
    {TK_OPTION_CURSOR, "-cursor", "cursor", "Cursor", DEF_GRAPH_CURSOR, -1, Tk_Offset(Graph, cursor), TK_OPTION_NULL_OK, 0, 0},
    {TK_OPTION_STRING, "-data", "data", "Data", (char *)NULL, -1, Tk_Offset(Graph, data), TK_OPTION_DONT_SET_DEFAULT, 0, 0},
    {TK_OPTION_STRING, "-datacommand", "dataCommand", "DataCommand", (char *)NULL, -1, Tk_Offset(Graph, dataCmd), TK_OPTION_DONT_SET_DEFAULT, 0, 0},
    {TK_OPTION_SYNONYM, "-fg", (char *) NULL, (char *) NULL, (char *) NULL, 0, -1, 0, (ClientData) "-foreground", 0},
    {TK_OPTION_FONT, "-font", "font", "Font", DEF_GRAPH_FONT, -1, Tk_Offset(Graph, titleTextStyle.font), 0, 0, 0},
    {TK_OPTION_COLOR, "-foreground", "foreground", "Foreground", DEF_GRAPH_TITLE_COLOR, -1, Tk_Offset(Graph, titleTextStyle.color), 0, DEF_GRAPH_TITLE_MONO, 0},
    {TK_OPTION_CUSTOM, "-halo", "halo", "Halo", DEF_GRAPH_HALO, -1, Tk_Offset(Graph, halo), 0, &rbcObjDistanceOption, 0},
    {TK_OPTION_CUSTOM, "-height", "height", "Height", DEF_GRAPH_HEIGHT, -1, Tk_Offset(Graph, reqHeight), 0, &rbcObjDistanceOption, RESET_WORLD_MASK},
    {TK_OPTION_COLOR, "-highlightbackground", "highlightBackground", "HighlightBackground", DEF_GRAPH_HIGHLIGHT_BACKGROUND, -1, Tk_Offset(Graph, highlightBgColor), 0, DEF_GRAPH_HIGHLIGHT_BG_MONO, 0},
    {TK_OPTION_COLOR, "-highlightcolor", "highlightColor", "HighlightColor", DEF_GRAPH_HIGHLIGHT_COLOR, -1, Tk_Offset(Graph, highlightColor), 0, 0, 0},
    {TK_OPTION_PIXELS, "-highlightthickness", "highlightThickness", "HighlightThickness", DEF_GRAPH_HIGHLIGHT_WIDTH, -1, Tk_Offset(Graph, highlightWidth), TK_OPTION_DONT_SET_DEFAULT, 0, 0},
    {TK_OPTION_BOOLEAN, "-invertxy", "invertXY", "InvertXY", DEF_GRAPH_INVERT_XY, -1, Tk_Offset(Graph, inverted), TK_OPTION_DONT_SET_DEFAULT, 0, (INVERTXY_MASK|RESET_WORLD_MASK)},
    {TK_OPTION_JUSTIFY, "-justify", "justify", "Justify", DEF_GRAPH_JUSTIFY, -1, Tk_Offset(Graph, titleTextStyle.justify), TK_OPTION_DONT_SET_DEFAULT, 0, 0},
    {TK_OPTION_CUSTOM, "-leftmargin", "leftMargin", "Margin", DEF_GRAPH_MARGIN, -1, Tk_Offset(Graph, leftMargin.reqSize), TK_OPTION_DONT_SET_DEFAULT, &rbcObjDistanceOption, RESET_WORLD_MASK},
    {TK_OPTION_STRING, "-leftvariable", "leftVariable", "LeftVariable", DEF_GRAPH_MARGIN_VAR, -1, Tk_Offset(Graph, leftMargin.varName), TK_OPTION_NULL_OK, 0, 0},
    {TK_OPTION_SYNONYM, "-lm", (char *) NULL, (char *) NULL, (char *) NULL, 0, -1, 0, (ClientData) "-leftmargin", RESET_WORLD_MASK},
    {TK_OPTION_COLOR, "-plotbackground", "plotBackground", "Background", DEF_GRAPH_PLOT_BG_MONO, -1, Tk_Offset(Graph, plotBg), 0, DEF_GRAPH_HIGHLIGHT_BG_MONO, REDRAW_BACKING_STORE_MASK},
    {TK_OPTION_CUSTOM, "-plotborderwidth", "plotBorderWidth", "BorderWidth", DEF_GRAPH_PLOT_BW_COLOR, -1, Tk_Offset(Graph, plotBorderWidth), 0, &rbcObjDistanceOption, RESET_WORLD_MASK},
    {TK_OPTION_CUSTOM, "-plotpadx", "plotPadX", "PlotPad", DEF_GRAPH_PLOT_PADX, -1, Tk_Offset(Graph, padX), TK_OPTION_DONT_SET_DEFAULT, &rbcObjPadOption, RESET_WORLD_MASK},
	{TK_OPTION_CUSTOM, "-plotpady", "plotPadY", "PlotPad", DEF_GRAPH_PLOT_PADY, -1, Tk_Offset(Graph, padY), TK_OPTION_DONT_SET_DEFAULT, &rbcObjPadOption, RESET_WORLD_MASK},
	{TK_OPTION_RELIEF, "-plotrelief", "plotRelief", "Relief", DEF_GRAPH_PLOT_RELIEF, -1, Tk_Offset(Graph, plotRelief), TK_OPTION_DONT_SET_DEFAULT, 0, 0},
	{TK_OPTION_RELIEF, "-relief", "relief", "Relief", DEF_GRAPH_RELIEF, -1, Tk_Offset(Graph, relief), TK_OPTION_DONT_SET_DEFAULT, 0, 0},
	{TK_OPTION_CUSTOM, "-rightmargin", "rightMargin", "Margin", DEF_GRAPH_MARGIN, -1, Tk_Offset(Graph, rightMargin.reqSize), TK_OPTION_DONT_SET_DEFAULT, &rbcObjDistanceOption, RESET_WORLD_MASK},
	{TK_OPTION_STRING, "-rightvariable", "rightVariable", "RightVariable", DEF_GRAPH_MARGIN_VAR, -1, Tk_Offset(Graph, rightMargin.varName), TK_OPTION_NULL_OK, 0, 0},
	{TK_OPTION_SYNONYM, "-rm", (char *) NULL, (char *) NULL, (char *) NULL, 0, -1, 0, (ClientData) "-rightmargin", RESET_WORLD_MASK},
	{TK_OPTION_CUSTOM, "-shadow", "shadow", "Shadow", DEF_GRAPH_SHADOW_COLOR, -1, Tk_Offset(Graph, titleTextStyle.shadow), 0, &rbcObjShadowOption, 0},
	{TK_OPTION_STRING, "-takefocus", "takeFocus", "TakeFocus", DEF_GRAPH_TAKE_FOCUS, -1, Tk_Offset(Graph, takeFocus), TK_OPTION_NULL_OK, 0, 0},
	{TK_OPTION_CUSTOM, "-tile", "tile", "Tile", (char *)NULL, -1, Tk_Offset(Graph, tile), TK_OPTION_NULL_OK, &rbcObjTileOption, 0},
	{TK_OPTION_STRING, "-title", "title", "Title", DEF_GRAPH_TITLE, -1, Tk_Offset(Graph, title), TK_OPTION_NULL_OK, 0, RESET_WORLD_MASK},
	{TK_OPTION_SYNONYM, "-tm", (char *) NULL, (char *) NULL, (char *) NULL, 0, -1, 0, (ClientData) "-topmargin", RESET_WORLD_MASK},
	{TK_OPTION_CUSTOM, "-topmargin", "topMargin", "Margin", DEF_GRAPH_MARGIN, -1, Tk_Offset(Graph, topMargin.reqSize), TK_OPTION_DONT_SET_DEFAULT, &rbcObjDistanceOption, RESET_WORLD_MASK},
	{TK_OPTION_STRING, "-topvariable", "topVariable", "TopVariable", DEF_GRAPH_MARGIN_VAR, -1, Tk_Offset(Graph, topMargin.varName), TK_OPTION_NULL_OK, 0, 0},
	{TK_OPTION_CUSTOM, "-width", "width", "Width", DEF_GRAPH_WIDTH, -1, Tk_Offset(Graph, reqWidth), 0, &rbcObjDistanceOption, RESET_WORLD_MASK},
	{TK_OPTION_END, NULL, NULL, NULL, NULL, -1, 0, 0, 0, 0}
};

static Rbc_SwitchParseProc StringToFormat;
static Rbc_SwitchCustom formatSwitch = {
    StringToFormat, (Rbc_SwitchFreeProc *)NULL, (ClientData)0,
};

typedef struct {
    char *name;
    int width, height;
    int format;
} SnapData;

enum SnapFormats { FORMAT_PHOTO, FORMAT_EMF, FORMAT_WMF };

static Rbc_SwitchSpec snapSwitches[] = {
    {RBC_SWITCH_INT_POSITIVE, "-width", Rbc_Offset(SnapData, width), 0},
    {RBC_SWITCH_INT_POSITIVE, "-height", Rbc_Offset(SnapData, height), 0},
    {RBC_SWITCH_CUSTOM, "-format", Rbc_Offset(SnapData, format), 0, &formatSwitch},
    {RBC_SWITCH_END, NULL, 0, 0}
};

static Tcl_IdleProc DisplayGraph;
static Tcl_FreeProc DestroyGraph;
static Tk_EventProc GraphEventProc;

static Rbc_BindPickProc PickEntry;
static Tcl_ObjCmdProc StripchartObjCmd;
static Tcl_ObjCmdProc BarchartObjCmd;
static Tcl_ObjCmdProc GraphObjCmd;
static Tcl_CmdDeleteProc GraphInstCmdDeleteProc;
static Rbc_TileChangedProc TileChangedProc;

static void AdjustAxisPointers _ANSI_ARGS_((Graph *graphPtr));
static int InitPens _ANSI_ARGS_((Graph *graphPtr));
static Graph *CreateGraph _ANSI_ARGS_((Tcl_Interp *interp, ClientData clientData, int objc, Tcl_Obj *CONST *objv, Rbc_Uid classUid));
static void ConfigureGraph _ANSI_ARGS_((Graph *graphPtr, int mask));
static int GraphObjConfigure _ANSI_ARGS_((Tcl_Interp *interp, Graph *graphPtr, int objc, Tcl_Obj *CONST *objv));
static int NewGraph _ANSI_ARGS_((Tcl_Interp *interp, ClientData clientData, int objc, Tcl_Obj *CONST *objv, Rbc_Uid classUid));
static void DrawMargins _ANSI_ARGS_((Graph *graphPtr, Drawable drawable));
static void DrawPlotRegion _ANSI_ARGS_((Graph *graphPtr, Drawable drawable));
static void UpdateMarginTraces _ANSI_ARGS_((Graph *graphPtr));

static int XAxisOp _ANSI_ARGS_((Graph *graphPtr, Tcl_Interp *interp, int argc, char **argv));
static int X2AxisOp _ANSI_ARGS_((Graph *graphPtr, Tcl_Interp *interp, int argc, char **argv));
static int YAxisOp _ANSI_ARGS_((Graph *graphPtr, Tcl_Interp *interp, int objc, Tcl_Obj * const objv[]));
static int Y2AxisOp _ANSI_ARGS_((Graph *graphPtr, Tcl_Interp *interp, int argc, char **argv));
static int BarOp _ANSI_ARGS_((Graph *graphPtr, Tcl_Interp *interp, int objc, Tcl_Obj *CONST *objv));
static int LineOp _ANSI_ARGS_((Graph *graphPtr, Tcl_Interp *interp, int objc, Tcl_Obj *CONST *objv));
static int ElementOp _ANSI_ARGS_((Graph *graphPtr, Tcl_Interp *interp, int objc, Tcl_Obj *CONST *objv));
static int ConfigureOp _ANSI_ARGS_((Graph *graphPtr, Tcl_Interp *interp, int objc, Tcl_Obj *CONST *objv));
static int CgetOp _ANSI_ARGS_((Graph *graphPtr, Tcl_Interp *interp, int objc, Tcl_Obj *CONST *objv));
static int ExtentsOp _ANSI_ARGS_((Graph *graphPtr, Tcl_Interp *interp, int objc, Tcl_Obj *CONST *objv));
static int InsideOp _ANSI_ARGS_((Graph *graphPtr, Tcl_Interp *interp, int objc, Tcl_Obj *CONST *objv));
static int InvtransformOp _ANSI_ARGS_((Graph *graphPtr, Tcl_Interp *interp, int objc, Tcl_Obj *CONST *objv));
static int TransformOp _ANSI_ARGS_((Graph *graphPtr, Tcl_Interp *interp, int objc, Tcl_Obj *CONST *objv));
static int SnapOp _ANSI_ARGS_((Graph *graphPtr, Tcl_Interp *interp, int objc, Tcl_Obj *CONST *objv));

#ifdef WIN32
static int InitMetaFileHeader _ANSI_ARGS_((Tk_Window tkwin, int width, int height, APMHEADER *mfhPtr));
static int CreateAPMetaFile _ANSI_ARGS_((Tcl_Interp *interp, HANDLE hMetaFile, HDC hDC, APMHEADER *mfhPtr, char *fileName));
#endif

/*
 *--------------------------------------------------------------
 *
 * Rbc_EventuallyRedrawGraph --
 *
 *      Tells the Tk dispatcher to call the graph display routine at
 *      the next idle point.  This request is made only if the window
 *      is displayed and no other redraw request is pending.
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      The window is eventually redisplayed.
 *
 *--------------------------------------------------------------
 */
void
Rbc_EventuallyRedrawGraph(graphPtr)
    Graph *graphPtr; /* Graph widget record */
{
    if ((graphPtr->tkwin != NULL) && !(graphPtr->flags & REDRAW_PENDING)) {
        Tcl_DoWhenIdle(DisplayGraph, graphPtr);
        graphPtr->flags |= REDRAW_PENDING;
    }
}

/*
 *--------------------------------------------------------------
 *
 * GraphEventProc --
 *
 *      This procedure is invoked by the Tk dispatcher for various
 *      events on graphs.
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      When the window gets deleted, internal structures get
 *      cleaned up.  When it gets exposed, the graph is eventually
 *      redisplayed.
 *
 *--------------------------------------------------------------
 */
static void
GraphEventProc(clientData, eventPtr)
    ClientData clientData; /* Graph widget record */
    register XEvent *eventPtr; /* Event which triggered call to routine */
{
    Graph *graphPtr = clientData;

    if (eventPtr->type == Expose) {
        if (eventPtr->xexpose.count == 0) {
            graphPtr->flags |= REDRAW_WORLD;
            Rbc_EventuallyRedrawGraph(graphPtr);
        }
    } else if ((eventPtr->type == FocusIn) || (eventPtr->type == FocusOut)) {
        if (eventPtr->xfocus.detail != NotifyInferior) {
            if (eventPtr->type == FocusIn) {
                graphPtr->flags |= GRAPH_FOCUS;
            } else {
                graphPtr->flags &= ~GRAPH_FOCUS;
            }
            graphPtr->flags |= REDRAW_WORLD;
            Rbc_EventuallyRedrawGraph(graphPtr);
        }
    } else if (eventPtr->type == DestroyNotify) {
        if (graphPtr->tkwin != NULL) {
            Rbc_DeleteWindowInstanceData(graphPtr->tkwin);
            graphPtr->tkwin = NULL;
            Tcl_DeleteCommandFromToken(graphPtr->interp, graphPtr->cmdToken);
        }
        if (graphPtr->flags & REDRAW_PENDING) {
            Tcl_CancelIdleCall(DisplayGraph, graphPtr);
        }
        Tcl_EventuallyFree(graphPtr, DestroyGraph);
    } else if (eventPtr->type == ConfigureNotify) {
        graphPtr->flags |= (MAP_WORLD | REDRAW_WORLD);
        Rbc_EventuallyRedrawGraph(graphPtr);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * GraphInstCmdDeleteProc --
 *
 *      This procedure is invoked when a widget command is deleted.  If
 *      the widget isn't already in the process of being destroyed,
 *      this command destroys it.
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      The widget is destroyed.
 *
 *---------------------------------------------------------------------- */
static void
GraphInstCmdDeleteProc(clientData)
    ClientData clientData; /* Pointer to widget record. */
{
    Graph *graphPtr = clientData;

    if (graphPtr->tkwin != NULL) {	/* NULL indicates window has
					 * already been destroyed. */
        Tk_Window tkwin;

        tkwin = graphPtr->tkwin;
        graphPtr->tkwin = NULL;
#ifdef ITCL_NAMESPACES
        Itk_SetWidgetCommand(tkwin, (Tcl_Command) NULL);
#endif /* ITCL_NAMESPACES */
        Rbc_DeleteWindowInstanceData(tkwin);
        Tk_DestroyWindow(tkwin);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TileChangedProc --
 *
 *      Rebuilds the designated GC with the new tile pixmap.
 *
 * Results:
 *      None.
 *
 * Side Effects:
 *      TODO: Side Effects
 *
 *----------------------------------------------------------------------
 */
static void
TileChangedProc(clientData, tile)
    ClientData clientData;
    Rbc_Tile tile; /* Not used. */
{
    Graph *graphPtr = clientData;

    if (graphPtr->tkwin != NULL) {
        graphPtr->flags |= REDRAW_WORLD;
        Rbc_EventuallyRedrawGraph(graphPtr);
    }
}

/*
 *--------------------------------------------------------------
 *
 * AdjustAxisPointers --
 *
 *      Sets the axis pointers according to whether the axis is
 *      inverted on not.  The axis sites are also reset.
 *
 * Results:
 *      None.
 *
 * Side Effects:
 *      TODO: Side Effects
 *
 *--------------------------------------------------------------
 */
static void
AdjustAxisPointers(graphPtr)
    Graph *graphPtr; /* Graph widget record */
{
    if (graphPtr->inverted) {
        graphPtr->leftMargin.axes = graphPtr->axisChain[0];
        graphPtr->bottomMargin.axes = graphPtr->axisChain[1];
        graphPtr->rightMargin.axes = graphPtr->axisChain[2];
        graphPtr->topMargin.axes = graphPtr->axisChain[3];
    } else {
        graphPtr->leftMargin.axes = graphPtr->axisChain[1];
        graphPtr->bottomMargin.axes = graphPtr->axisChain[0];
        graphPtr->rightMargin.axes = graphPtr->axisChain[3];
        graphPtr->topMargin.axes = graphPtr->axisChain[2];
    }
}


/*
 *----------------------------------------------------------------------
 *
 * InitPens --
 *
 *      TODO: Description
 *
 * Results:
 *      TODO: Results
 *
 * Side Effects:
 *      TODO: Side Effects
 *
 *----------------------------------------------------------------------
 */
static int
InitPens(graphPtr)
    Graph *graphPtr;
{
    Tcl_InitHashTable(&graphPtr->penTable, TCL_STRING_KEYS);
    if (Rbc_CreatePen(graphPtr, "activeLine", rbcLineElementUid, 0, (char **)NULL) == NULL) {
        return TCL_ERROR;
    }
    if (Rbc_CreatePen(graphPtr, "activeBar", rbcBarElementUid, 0, (char **)NULL) == NULL) {
        return TCL_ERROR;
    }
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Rbc_GraphTags --
 *
 *      Sets the binding tags for a graph object. This routine is
 *      called by Tk when an event occurs in the graph.  It fills
 *      an array of pointers with bind tag addresses.
 *
 *      The object addresses are strings hashed in one of two tag
 *      tables: one for elements and the another for markers.  Note
 *      that there's only one binding table for elements and markers.
 *      [We don't want to trigger both a marker and element bind
 *      command for the same event.]  But we don't want a marker and
 *      element with the same tag name to activate the others
 *      bindings. A tag "all" for markers should mean all markers, not
 *      all markers and elements.  As a result, element and marker
 *      tags are stored in separate hash tables, which means we can't
 *      generate the same tag address for both an elements and marker,
 *      even if they have the same name.
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      This information will be used by the binding code in rbcUtil.c
 *      to determine what graph objects match the current event.  The
 *      tags are placed in tagArr and *nTagsPtr is set with the
 *      number of tags found.
 *
 *----------------------------------------------------------------------
 */
void
Rbc_GraphTags(table, object, context, list)
    Rbc_BindTable table;
    ClientData object;
    ClientData context; /* Not used. */
    Rbc_List list;
{
    Element *elemPtr;
    MakeTagProc *tagProc;
    Graph *graphPtr;

    graphPtr = (Graph *)Rbc_GetBindingData(table);
    /*
     * Trick:   Markers, elements, and axes have the same first few
     *          fields in their structures, such as "type", "name", or
     *          "tags".  This is so we can look at graph objects
     *          interchangably.  It doesn't matter what we cast the
     *          object to.
     */
    elemPtr = (Element *)object;

    if ((elemPtr->classUid == rbcLineElementUid)
            || (elemPtr->classUid == rbcStripElementUid)
            || (elemPtr->classUid == rbcBarElementUid)) {
        tagProc = Rbc_MakeElementTag;
    } else if ((elemPtr->classUid == rbcXAxisUid)
            || (elemPtr->classUid == rbcYAxisUid)) {
        tagProc = Rbc_MakeAxisTag;
    } else {
        tagProc = Rbc_MakeMarkerTag;
    }
    /*
     * Always add the name of the object to the tag array.
     */
    Rbc_ListAppend(list, (*tagProc) (graphPtr, elemPtr->name), 0);
    Rbc_ListAppend(list, (*tagProc) (graphPtr, elemPtr->classUid), 0);
    if (elemPtr->tags != NULL) {
        register char **p;

        for (p = elemPtr->tags; *p != NULL; p++) {
            Rbc_ListAppend(list, (*tagProc) (graphPtr, *p), 0);
        }
    }
}

/*
 *----------------------------------------------------------------------
 *
 * PickEntry --
 *
 *      Find the closest point from the set of displayed elements,
 *      searching the display list from back to front.  That way, if
 *      the points from two different elements overlay each other exactly,
 *      the one that's on top (visible) is picked.
 *
 * Results:
 *      TODO: Results
 *
 * Side Effects:
 *      TODO: Side Effects
 *
 *----------------------------------------------------------------------
 */
static ClientData
PickEntry(clientData, x, y, contextPtr)
    ClientData clientData;
    int x, y;
    ClientData *contextPtr; /* Not used. */
{
    Graph *graphPtr = clientData;
    Rbc_ChainLink *linkPtr;
    Element *elemPtr;
    Marker *markerPtr;
    Extents2D exts;

    if (graphPtr->flags & MAP_ALL) {
        /* Can't pick anything until the next
         * redraw occurs. */
        return NULL;
    }
    Rbc_GraphExtents(graphPtr, &exts);

    if ((x > exts.right) || (x < exts.left) || (y > exts.bottom) || (y < exts.top)) {
        /*
         * Sample coordinate is in one of the graph margins.  Can only
         * pick an axis.
         */
        return Rbc_NearestAxis(graphPtr, x, y);
    }

    /*
     * From top-to-bottom check:
     *	1. markers drawn on top (-under false).
     *	2. elements using its display list back to front.
     *  3. markers drawn under element (-under true).
     */
    markerPtr = (Marker *)Rbc_NearestMarker(graphPtr, x, y, FALSE);
    if (markerPtr != NULL) {
    	/* Found a marker (-under false). */
        return markerPtr;
    }
    {
        ClosestSearch search;

        search.along = SEARCH_BOTH;
        search.halo = graphPtr->halo + 1;
        search.index = -1;
        search.x = x;
        search.y = y;
        search.dist = (double)(search.halo + 1);
        search.mode = SEARCH_AUTO;

        for (linkPtr = Rbc_ChainLastLink(graphPtr->elements.displayList); linkPtr != NULL; linkPtr = Rbc_ChainPrevLink(linkPtr)) {
            elemPtr = Rbc_ChainGetValue(linkPtr);
            if ((elemPtr->flags & MAP_ITEM)
                    || (Rbc_VectorNotifyPending(elemPtr->x.clientId))
                    || (Rbc_VectorNotifyPending(elemPtr->y.clientId))) {
                continue;
            }
            if ((!elemPtr->hidden) && (elemPtr->state == STATE_NORMAL)) {
                (*elemPtr->procsPtr->closestProc) (graphPtr, elemPtr, &search);
            }
        }
        if (search.dist <= (double)search.halo) {
        	/* Found an element within the
        	 * minimum halo distance. */
            return search.elemPtr;
        }
    }
    markerPtr = (Marker *)Rbc_NearestMarker(graphPtr, x, y, TRUE);
    if (markerPtr != NULL) {
        /* Found a marker (-under true) */
        return markerPtr;
    }
    /* Nothing found. */
    return NULL;
}

/*
 *----------------------------------------------------------------------
 *
 * ConfigureGraph --
 *
 *      Allocates resources for the graph.
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      Configuration information, such as text string, colors, font,
 *      etc. get set for graphPtr;  old resources get freed, if there
 *      were any.  The graph is redisplayed.
 *
 *----------------------------------------------------------------------
 */
static void
ConfigureGraph(graphPtr, mask)
    Graph *graphPtr; /* Graph widget record */
	int mask;
{
    XColor *colorPtr;
    GC newGC;
    XGCValues gcValues;
    unsigned long gcMask;

    /* Don't allow negative bar widths. Reset to an arbitrary value (0.1) */
    if (graphPtr->barWidth <= 0.0) {
        graphPtr->barWidth = 0.1;
    }
    graphPtr->inset = graphPtr->borderWidth + graphPtr->highlightWidth + 1;
    if ((graphPtr->reqHeight != Tk_ReqHeight(graphPtr->tkwin))
             || (graphPtr->reqWidth != Tk_ReqWidth(graphPtr->tkwin))) {
        Tk_GeometryRequest(graphPtr->tkwin, graphPtr->reqWidth, graphPtr->reqHeight);
    }
    Tk_SetInternalBorder(graphPtr->tkwin, graphPtr->borderWidth);
    colorPtr = Tk_3DBorderColor(graphPtr->border);

    if (graphPtr->title != NULL) {
        int w, h;

        Rbc_GetTextExtents(&graphPtr->titleTextStyle, graphPtr->title, &w, &h);
        graphPtr->titleTextStyle.height = h + 10;
    } else {
        graphPtr->titleTextStyle.width = graphPtr->titleTextStyle.height = 0;
    }

    /*
     * Create GCs for interior and exterior regions, and a background
     * GC for clearing the margins with XFillRectangle
     */

    /* Margin GC */

    gcValues.foreground = graphPtr->titleTextStyle.color->pixel;
    gcValues.background = colorPtr->pixel;
    gcMask = (GCForeground | GCBackground);
    newGC = Tk_GetGC(graphPtr->tkwin, gcMask, &gcValues);
    if (graphPtr->drawGC != NULL) {
        Tk_FreeGC(graphPtr->display, graphPtr->drawGC);
    }
    graphPtr->drawGC = newGC;

    /* Plot fill GC (Background = Foreground) */

    gcValues.foreground = graphPtr->plotBg->pixel;
    newGC = Tk_GetGC(graphPtr->tkwin, gcMask, &gcValues);
    if (graphPtr->plotFillGC != NULL) {
        Tk_FreeGC(graphPtr->display, graphPtr->plotFillGC);
    }
    graphPtr->plotFillGC = newGC;

    /* Margin fill GC (Background = Foreground) */

    gcValues.foreground = colorPtr->pixel;
    gcValues.background = graphPtr->titleTextStyle.color->pixel;
    newGC = Tk_GetGC(graphPtr->tkwin, gcMask, &gcValues);
    if (graphPtr->fillGC != NULL) {
        Tk_FreeGC(graphPtr->display, graphPtr->fillGC);
    }
    graphPtr->fillGC = newGC;
    if (graphPtr->tile != NULL) {
        Rbc_SetTileChangedProc(graphPtr->tile, TileChangedProc, graphPtr);
    }

    Rbc_ResetTextStyle(graphPtr->tkwin, &graphPtr->titleTextStyle);

    if (mask & INVERTXY_MASK) {

        /*
         * If the -inverted option changed, we need to readjust the pointers
         * to the axes and recompute the their scales.
         */

        AdjustAxisPointers(graphPtr);
        graphPtr->flags |= RESET_AXES;
    }
    if ((!graphPtr->backingStore) && (graphPtr->backPixmap != None)) {

        /*
         * Free the pixmap if we're not buffering the display of elements
         * anymore.
         */

        Tk_FreePixmap(graphPtr->display, graphPtr->backPixmap);
        graphPtr->backPixmap = None;
    }
    /*
     * Reconfigure the crosshairs, just in case the background color of
     * the plotarea has been changed.
     */
    if (graphPtr->crosshairs != NULL) {
        Rbc_ConfigureCrosshairs(graphPtr);
    }

    /*
     *  Update the layout of the graph (and redraw the elements) if
     *  any of the following graph options which affect the size of
     *	the plotting area has changed.
     *
     *	    -aspect
     *      -borderwidth, -plotborderwidth
     *	    -font, -title
     *	    -width, -height
     *	    -invertxy
     *	    -bottommargin, -leftmargin, -rightmargin, -topmargin,
     *	    -barmode, -barwidth
     */
    if (mask & RESET_WORLD_MASK) {
        graphPtr->flags |= RESET_WORLD;
    }
    if (mask & REDRAW_BACKING_STORE_MASK) {
        graphPtr->flags |= REDRAW_BACKING_STORE;
    }
    graphPtr->flags |= REDRAW_WORLD;
}

/*
 *----------------------------------------------------------------------
 *
 * GraphObjConfigure --
 *
 *      Allocates resources for the graph.
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      Configuration information, such as text string, colors, font,
 *      etc. get set for graphPtr;  old resources get freed, if there
 *      were any.  The graph is redisplayed.
 *
 *----------------------------------------------------------------------
 */
static int
GraphObjConfigure(interp, graphPtr, objc, objv)
	Tcl_Interp *interp; /* For return values and errors */
	Graph *graphPtr; /* The per-instance data structure */
	int objc; /* Number of valid entries in argv */
	Tcl_Obj *CONST *objv; /* The command line arguments */
{
    Tk_SavedOptions savedOptions;
    int mask, error;
    Tcl_Obj *errorResult;

    for (error = 0; error <= 1; error++) {
        if (!error) {
            if (Tk_SetOptions(interp, (char *) graphPtr, graphPtr->optionTable, objc, objv, graphPtr->tkwin, &savedOptions, &mask) != TCL_OK) {
                continue;
            }
        } else {
            errorResult = Tcl_GetObjResult(interp);
            Tcl_IncrRefCount(errorResult);
            Tk_RestoreSavedOptions(&savedOptions);
        }
        ConfigureGraph(graphPtr, mask);
        break;
    }
    if (!error) {
    	Rbc_EventuallyRedrawGraph(graphPtr);
        Tk_FreeSavedOptions(&savedOptions);
        return TCL_OK;
    } else {
        Tcl_SetObjResult(interp, errorResult);
        Tcl_DecrRefCount(errorResult);
        return TCL_ERROR;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * DestroyGraph --
 *
 *      This procedure is invoked by Tcl_EventuallyFree or Tcl_Release
 *      to clean up the internal structure of a graph at a safe time
 *      (when no-one is using it anymore).
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      Everything associated with the widget is freed up.
 *
 *----------------------------------------------------------------------
 */
static void
DestroyGraph(dataPtr)
    DestroyData dataPtr;
{
    Graph *graphPtr = (Graph *)dataPtr;

    /* We used to free the config specs...Do we need to do that with Option Specs?
     * Tk_FreeConfigOptions((char *) graphPtr, graphPtr->optionTable, graphPtr->tkwin);
     */

    /*
     * Destroy the individual components of the graph: elements, markers,
     * X and Y axes, legend, display lists etc.
     */
    Rbc_DestroyMarkers(graphPtr);
    Rbc_DestroyElements(graphPtr);

    Rbc_DestroyAxes(graphPtr);
    Rbc_DestroyPens(graphPtr);

    if (graphPtr->legend != NULL) {
        Rbc_DestroyLegend(graphPtr);
    }
    if (graphPtr->postscript != NULL) {
        Rbc_DestroyPostScript(graphPtr);
    }
    if (graphPtr->crosshairs != NULL) {
        Rbc_DestroyCrosshairs(graphPtr);
    }
    if (graphPtr->gridPtr != NULL) {
        Rbc_DestroyGrid(graphPtr);
    }
    if (graphPtr->bindTable != NULL) {
        Rbc_DestroyBindingTable(graphPtr->bindTable);
    }

    /* Release allocated X resources and memory. */
    if (graphPtr->drawGC != NULL) {
        Tk_FreeGC(graphPtr->display, graphPtr->drawGC);
    }
    if (graphPtr->fillGC != NULL) {
        Tk_FreeGC(graphPtr->display, graphPtr->fillGC);
    }
    if (graphPtr->plotFillGC != NULL) {
        Tk_FreeGC(graphPtr->display, graphPtr->plotFillGC);
    }
    Rbc_FreeTextStyle(graphPtr->display, &graphPtr->titleTextStyle);
    if (graphPtr->backPixmap != None) {
        Tk_FreePixmap(graphPtr->display, graphPtr->backPixmap);
    }
    if (graphPtr->freqArr != NULL) {
        ckfree((char *)graphPtr->freqArr);
    }
    if (graphPtr->nStacks > 0) {
        Tcl_DeleteHashTable(&graphPtr->freqTable);
    }
    if (graphPtr->tile != NULL) {
        Rbc_FreeTile(graphPtr->tile);
    }
    ckfree((char *)graphPtr);
}

/*
 *----------------------------------------------------------------------
 *
 * CreateGraph --
 *
 *      This procedure creates and initializes a new widget.
 *
 * Results:
 *      The return value is a pointer to a structure describing
 *      the new widget.  If an error occurred, then the return
 *      value is NULL and an error message is left in interp->result.
 *
 * Side effects:
 *      Memory is allocated, a Tk_Window is created, etc.
 *
 *----------------------------------------------------------------------
 */
static Graph *
CreateGraph(interp, clientData, objc, objv, classUid)
    Tcl_Interp *interp;
	ClientData clientData;
    int objc;
    Tcl_Obj *CONST *objv;
    Rbc_Uid classUid;
{
    Graph *graphPtr;
    Tk_Window tkwin;
    Tk_OptionTable optionTable;

    optionTable = Tk_CreateOptionTable(interp, optionSpecs);

    /*
     * This is supposed to be a mechanism for caching the option table, but it errors.
     *
     * optionTable = (Tk_OptionTable) clientData;
     * if (optionTable == NULL) {
     *      Tcl_CmdInfo info;
     *      char *name;
     *
     *      optionTable = Tk_CreateOptionTable(interp, optionSpecs);
     *      name = Tcl_GetString(objv[0]);
     *      Tcl_GetCommandInfo(interp, name, &info);
     *      info.objClientData = (ClientData) optionTable;
     *      Tcl_SetCommandInfo(interp, name, &info);
     * }
     */
    tkwin = Tk_CreateWindowFromPath(interp, Tk_MainWindow(interp), Tcl_GetString(objv[1]), (char *) NULL);
    if (tkwin == NULL) {
        return NULL;
    }
    graphPtr = RbcCalloc(1, sizeof(Graph));
    assert(graphPtr);
    /* Initialize the graph data structure. */
    graphPtr->tkwin = tkwin;
    graphPtr->display = Tk_Display(tkwin);
    graphPtr->interp = interp;
    graphPtr->optionTable = optionTable;
    graphPtr->classUid = classUid;
    graphPtr->backingStore = TRUE;
    graphPtr->doubleBuffer = TRUE;
    graphPtr->highlightWidth = 2;
    graphPtr->plotRelief = TK_RELIEF_SUNKEN;
    graphPtr->relief = TK_RELIEF_FLAT;
    graphPtr->flags = (RESET_WORLD);
    graphPtr->nextMarkerId = 1;
    graphPtr->padLeft = graphPtr->padRight = 8;
    graphPtr->padTop = graphPtr->padBottom = 8;
    graphPtr->bottomMargin.site = MARGIN_BOTTOM;
    graphPtr->leftMargin.site = MARGIN_LEFT;
    graphPtr->topMargin.site = MARGIN_TOP;
    graphPtr->rightMargin.site = MARGIN_RIGHT;
    Rbc_InitTextStyle(&graphPtr->titleTextStyle);

    Tcl_InitHashTable(&graphPtr->axes.table, TCL_STRING_KEYS);
    Tcl_InitHashTable(&graphPtr->axes.tagTable, TCL_STRING_KEYS);
    Tcl_InitHashTable(&graphPtr->elements.table, TCL_STRING_KEYS);
    Tcl_InitHashTable(&graphPtr->elements.tagTable, TCL_STRING_KEYS);
    Tcl_InitHashTable(&graphPtr->markers.table, TCL_STRING_KEYS);
    Tcl_InitHashTable(&graphPtr->markers.tagTable, TCL_STRING_KEYS);
    graphPtr->elements.displayList = Rbc_ChainCreate();
    graphPtr->markers.displayList = Rbc_ChainCreate();
    graphPtr->axes.displayList = Rbc_ChainCreate();

    if (classUid == rbcLineElementUid) {
        Tk_SetClass(tkwin, "Graph");
    } else if (classUid == rbcBarElementUid) {
        Tk_SetClass(tkwin, "Barchart");
    } else if (classUid == rbcStripElementUid) {
        Tk_SetClass(tkwin, "Stripchart");
    }
    Rbc_SetWindowInstanceData(tkwin, graphPtr);

    if (InitPens(graphPtr) != TCL_OK) {
        goto error;
    }

    if ((Tk_InitOptions(interp, (char *) graphPtr, optionTable, tkwin) != TCL_OK)
            || (GraphObjConfigure(interp, graphPtr, objc - 2, objv + 2) != TCL_OK)) {
    	goto error;
    }
    if (Rbc_DefaultAxes(graphPtr) != TCL_OK) {
        goto error;
    }
    AdjustAxisPointers(graphPtr);

    if (Rbc_CreatePostScript(graphPtr) != TCL_OK) {
        goto error;
    }
    if (Rbc_CreateCrosshairs(graphPtr) != TCL_OK) {
        goto error;
    }
    if (Rbc_CreateLegend(graphPtr) != TCL_OK) {
        goto error;
    }
    if (Rbc_CreateGrid(graphPtr) != TCL_OK) {
        goto error;
    }
    Tk_CreateEventHandler(graphPtr->tkwin,
                          ExposureMask | StructureNotifyMask | FocusChangeMask, GraphEventProc,
                          graphPtr);

    /* Tk_PathName might be argv[1] but instead Tcl_GetString(objv[1]) */
    graphPtr->cmdToken = Tcl_CreateObjCommand(interp, Tk_PathName(graphPtr->tkwin), Rbc_GraphInstObjCmdProc, (ClientData) graphPtr, GraphInstCmdDeleteProc);
/**
 * TODO Not Implemented yet
#ifdef ITCL_NAMESPACES
    Itk_SetWidgetCommand(graphPtr->tkwin, graphPtr->cmdToken);
#endif
*/
    graphPtr->bindTable = Rbc_CreateBindingTable(interp, tkwin, graphPtr, PickEntry, Rbc_GraphTags);
    return graphPtr;

    error:
    DestroyGraph((DestroyData)graphPtr);
    return NULL;
}

/* Widget sub-commands */
/*
 *----------------------------------------------------------------------
 *
 * XAxisOp --
 *
 *      TODO: Description
 *
 * Results:
 *      TODO: Results
 *
 * Side Effects:
 *      TODO: Side Effects
 *
 *----------------------------------------------------------------------
 */
static int
XAxisOp(graphPtr, interp, argc, argv)
    Graph *graphPtr;
    Tcl_Interp *interp;
    int argc;
    char **argv;
{
    int margin;

    margin = (graphPtr->inverted) ? MARGIN_LEFT : MARGIN_BOTTOM;
    return Rbc_AxisOp(graphPtr, interp, margin, argc, argv);
}

/*
 *----------------------------------------------------------------------
 *
 * X2AxisOp --
 *
 *      TODO: Description
 *
 * Results:
 *      TODO: Results
 *
 * Side Effects:
 *      TODO: Side Effects
 *
 *----------------------------------------------------------------------
 */
static int
X2AxisOp(graphPtr, interp, argc, argv)
    Graph *graphPtr;
    Tcl_Interp *interp;
    int argc;
    char **argv;
{
    int margin;

    margin = (graphPtr->inverted) ? MARGIN_RIGHT : MARGIN_TOP;
    return Rbc_AxisOp(graphPtr, interp, margin, argc, argv);
}

/*
 *----------------------------------------------------------------------
 *
 * YAxisOp --
 *
 *      TODO: Description
 *
 * Results:
 *      TODO: Results
 *
 * Side Effects:
 *      TODO: Side Effects
 *
 *----------------------------------------------------------------------
 */
static int
YAxisOp(graphPtr, interp, objc, objv)
    Graph *graphPtr;
    Tcl_Interp *interp;
    int objc;
    Tcl_Obj * const objv[];
{
    int margin;

    margin = (graphPtr->inverted) ? MARGIN_BOTTOM : MARGIN_LEFT;
    return Rbc_AxisOp(graphPtr, interp, margin, objc, objv);
}

/*
 *----------------------------------------------------------------------
 *
 * Y2AxisOp --
 *
 *      TODO: Description
 *
 * Results:
 *      TODO: Results
 *
 * Side Effects:
 *      TODO: Side Effects
 *
 *----------------------------------------------------------------------
 */
static int
Y2AxisOp(graphPtr, interp, argc, argv)
    Graph *graphPtr;
    Tcl_Interp *interp;
    int argc;
    char **argv;
{
    int margin;

    margin = (graphPtr->inverted) ? MARGIN_TOP : MARGIN_RIGHT;
    return Rbc_AxisOp(graphPtr, interp, margin, argc, argv);
}

/*
 *----------------------------------------------------------------------
 *
 * BarOp --
 *
 *      TODO: Description
 *
 * Results:
 *      TODO: Results
 *
 * Side Effects:
 *      TODO: Side Effects
 *
 *----------------------------------------------------------------------
 */
static int
BarOp(graphPtr, interp, objc, objv)
    Graph *graphPtr;
    Tcl_Interp *interp;
    int objc;
    Tcl_Obj *CONST *objv;
{
    return Rbc_ElementOp(graphPtr, interp, objc, objv, rbcBarElementUid);
}

/*
 *----------------------------------------------------------------------
 *
 * LineOp --
 *
 *      TODO: Description
 *
 * Results:
 *      TODO: Results
 *
 * Side Effects:
 *      TODO: Side Effects
 *
 *----------------------------------------------------------------------
 */
static int
LineOp(graphPtr, interp, objc, objv)
    Graph *graphPtr;
    Tcl_Interp *interp;
    int objc;
    Tcl_Obj *CONST *objv;
{
    return Rbc_ElementOp(graphPtr, interp, objc, objv, rbcLineElementUid);
}

/*
 *----------------------------------------------------------------------
 *
 * ElementOp --
 *
 *      TODO: Description
 *
 * Results:
 *      TODO: Results
 *
 * Side Effects:
 *      TODO: Side Effects
 *
 *----------------------------------------------------------------------
 */
static int
ElementOp(graphPtr, interp, objc, objv)
    Graph *graphPtr;
    Tcl_Interp *interp;
    int objc;
    Tcl_Obj *CONST *objv;
{
    return Rbc_ElementOp(graphPtr, interp, objc, objv, graphPtr->classUid);
}

/*
 *----------------------------------------------------------------------
 *
 * ConfigureOp --
 *
 *      TODO: Description
 *
 * Results:
 *      TODO: Results
 *
 * Side Effects:
 *      TODO: Side Effects
 *
 *----------------------------------------------------------------------
 */
static int
ConfigureOp(graphPtr, interp, objc, objv)
    Graph *graphPtr;
    Tcl_Interp *interp;
    int objc;
    Tcl_Obj *CONST *objv;
{
	Tcl_Obj *objPtr;

	if (objc <= 3) {
		objPtr = Tk_GetOptionInfo(interp, (char *) graphPtr, graphPtr->optionTable, (objc == 3) ? objv[2] : NULL, graphPtr->tkwin);
		if (objPtr == NULL) {
			return TCL_ERROR;
		} else {
			Tcl_SetObjResult(interp, objPtr);
		}
	} else {
		return GraphObjConfigure(interp, graphPtr, objc - 2, objv + 2);
	}
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * CgetOp --
 *
 *      TODO: Description
 *
 * Results:
 *      TODO: Results
 *
 * Side Effects:
 *      TODO: Side Effects
 *
 *----------------------------------------------------------------------
 */
static int
CgetOp(graphPtr, interp, objc, objv)
    Graph *graphPtr;
    Tcl_Interp *interp;
    int objc;
    Tcl_Obj *CONST *objv;
{
	Tcl_Obj *objPtr;

	objPtr = Tk_GetOptionValue(interp, (char *) graphPtr, graphPtr->optionTable, objv[2], graphPtr->tkwin);
	if (objPtr == NULL) {
		return TCL_ERROR;
	} else {
		Tcl_SetObjResult(interp, objPtr);
	}
	return TCL_OK;
}

/*
 *--------------------------------------------------------------
 *
 * ExtentsOp --
 *
 *      Reports the size of one of several items within the graph.
 *      The following are valid items:
 *
 *        "bottommargin"    Height of the bottom margin
 *        "leftmargin"      Width of the left margin
 *        "legend"          x y w h of the legend
 *        "plotarea"        x y w h of the plotarea
 *        "plotheight"      Height of the plot area
 *        "rightmargin"     Width of the right margin
 *        "topmargin"       Height of the top margin
 *        "plotwidth"       Width of the plot area
 *
 * Results:
 *      Always returns TCL_OK.
 *
 * Side Effects:
 *      TODO: Side Effects
 *
 *--------------------------------------------------------------
 */
static int
ExtentsOp(graphPtr, interp, objc, objv)
    Graph *graphPtr;
    Tcl_Interp *interp;
    int objc; /* Not used. */
    Tcl_Obj *CONST *objv;
{
	Tcl_Obj *resultPtr;
    char *optionArg;
	char c;
    unsigned int length;
    char string[200];

    resultPtr = Tcl_NewStringObj("", -1);
    optionArg = Tcl_GetStringFromObj(objv[2], &length);
    c = optionArg[0];
    if ((c == 'p') && (length > 4) && (strncmp("plotheight", optionArg, length) == 0)) {
    	Tcl_AppendStringsToObj(resultPtr, Rbc_Itoa(graphPtr->bottom - graphPtr->top + 1), NULL);
    } else if ((c == 'p') && (length > 4) && (strncmp("plotwidth", optionArg, length) == 0)) {
        Tcl_AppendStringsToObj(resultPtr, Rbc_Itoa(graphPtr->right - graphPtr->left + 1), NULL);
    } else if ((c == 'p') && (length > 4) && (strncmp("plotarea", optionArg, length) == 0)) {
        sprintf(string, "%d %d %d %d", graphPtr->left, graphPtr->top,
                graphPtr->right - graphPtr->left + 1,
                graphPtr->bottom - graphPtr->top + 1);
        Tcl_AppendStringsToObj(resultPtr, string, NULL);
    } else if ((c == 'l') && (length > 2) && (strncmp("legend", optionArg, length) == 0)) {
        sprintf(string, "%d %d %d %d", Rbc_LegendX(graphPtr->legend),
                Rbc_LegendY(graphPtr->legend),
                Rbc_LegendWidth(graphPtr->legend),
                Rbc_LegendHeight(graphPtr->legend));
        Tcl_AppendStringsToObj(resultPtr, string, NULL);
    } else if ((c == 'l') && (length > 2) && (strncmp("leftmargin", optionArg, length) == 0)) {
        Tcl_AppendStringsToObj(resultPtr, Rbc_Itoa(graphPtr->leftMargin.width), NULL);
    } else if ((c == 'r') && (length > 1) && (strncmp("rightmargin", optionArg, length) == 0)) {
        Tcl_AppendStringsToObj(resultPtr, Rbc_Itoa(graphPtr->rightMargin.width), NULL);
    } else if ((c == 't') && (length > 1) && (strncmp("topmargin", optionArg, length) == 0)) {
    	Tcl_AppendStringsToObj(resultPtr, Rbc_Itoa(graphPtr->topMargin.height), NULL);
    } else if ((c == 'b') && (length > 1) && (strncmp("bottommargin", optionArg, length) == 0)) {
        Tcl_AppendStringsToObj(resultPtr, Rbc_Itoa(graphPtr->bottomMargin.height), NULL);
    } else {
        Tcl_AppendStringsToObj(
            resultPtr,
            "bad extent item \"",
            optionArg,
            "\": should be plotheight, plotwidth, leftmargin, rightmargin, topmargin, bottommargin, plotarea, or legend",
            NULL);
        Tcl_SetObjResult(interp, resultPtr);
        return TCL_ERROR;
    }

    Tcl_SetObjResult(interp, resultPtr);
    return TCL_OK;
}

/*
 *--------------------------------------------------------------
 *
 * InsideOp --
 *
 *      Returns true of false whether the given point is inside
 *      the plotting area (defined by left,bottom right, top).
 *
 * Results:
 *      Always returns TCL_OK.  interp->result will contain
 *      the boolean string representation.
 *
 * Side Effects:
 *      TODO: Side Effects
 *
 *--------------------------------------------------------------
 */
static int
InsideOp(graphPtr, interp, objc, objv)
    Graph *graphPtr;
    Tcl_Interp *interp;
    int objc; /* Not used. */
    Tcl_Obj *CONST *objv;
{
    int x, y;
    Extents2D exts;
    int result;

    if (Tk_GetPixels(interp, graphPtr->tkwin, Tcl_GetStringFromObj(objv[2], NULL), &x) != TCL_OK) {
        return TCL_ERROR;
    }
    if (Tk_GetPixels(interp, graphPtr->tkwin, Tcl_GetStringFromObj(objv[3], NULL), &y) != TCL_OK) {
        return TCL_ERROR;
    }
    Rbc_GraphExtents(graphPtr, &exts);
    result = PointInRegion(&exts, x, y);
    Rbc_SetBooleanResult(interp, result);
    return TCL_OK;
}

/*
 * -------------------------------------------------------------------------
 *
 * InvtransformOp --
 *
 *      This procedure returns a list of the graph coordinate
 *      values corresponding with the given window X and Y
 *      coordinate positions.
 *
 * Results:
 *      Returns a standard Tcl result.  If an error occurred while
 *      parsing the window positions, TCL_ERROR is returned, and
 *      interp->result will contain the error message.  Otherwise
 *      interp->result will contain a Tcl list of the x and y
 *      coordinates.
 *
 * Side Effects:
 *      TODO: Side Effects
 *
 * ------------------------------------------------------------------------
 */
static int
InvtransformOp(graphPtr, interp, objc, objv)
    Graph *graphPtr; /* Graph widget record */
    Tcl_Interp *interp;
    int objc; /* Not used. */
    Tcl_Obj *CONST *objv;
{
    double x, y;
    Point2D point;
    Axis2D axes;

    if (Tcl_ExprDoubleObj(interp, objv[2], &x) != TCL_OK ||
            Tcl_ExprDoubleObj(interp, objv[3], &y) != TCL_OK) {
        return TCL_ERROR;
    }
    if (graphPtr->flags & RESET_AXES) {
        Rbc_ResetAxes(graphPtr);
    }
    /* Perform the reverse transformation, converting from window
     * coordinates to graph data coordinates.  Note that the point is
     * always mapped to the bottom and left axes (which may not be
     * what the user wants).  */

    /*  Pick the first pair of axes */
    axes.x = Rbc_GetFirstAxis(graphPtr->axisChain[0]);
    axes.y = Rbc_GetFirstAxis(graphPtr->axisChain[1]);
    point = Rbc_InvMap2D(graphPtr, x, y, &axes);

    Tcl_AppendElement(interp, Rbc_Dtoa(interp, point.x));
    Tcl_AppendElement(interp, Rbc_Dtoa(interp, point.y));
    return TCL_OK;
}

/*
 * --------------------------------------------------------------------------
 *
 * TransformOp --
 *
 *      This procedure returns a list of the window coordinates
 *      corresponding with the given graph x and y coordinates.
 *
 * Results:
 *      Returns a standard Tcl result.  interp->result contains
 *      the list of the graph coordinates. If an error occurred
 *      while parsing the window positions, TCL_ERROR is returned,
 *      then interp->result will contain an error message.
 *
 * Side Effects:
 *      TODO: Side Effects
 *
 * -------------------------------------------------------------------------
 */
static int
TransformOp(graphPtr, interp, objc, objv)
    Graph *graphPtr; /* Graph widget record */
    Tcl_Interp *interp;
    int objc; /* Not used. */
    Tcl_Obj *CONST *objv;
{
    double x, y;
    Point2D point;
    Axis2D axes;

    if ((Tcl_ExprDoubleObj(interp, objv[2], &x) != TCL_OK) ||
            (Tcl_ExprDoubleObj(interp, objv[3], &y) != TCL_OK)) {
        return TCL_ERROR;
    }
    if (graphPtr->flags & RESET_AXES) {
        Rbc_ResetAxes(graphPtr);
    }
    /*
     * Perform the transformation from window to graph coordinates.
     * Note that the points are always mapped onto the bottom and left
     * axes (which may not be the what the user wants).
     */
    axes.x = Rbc_GetFirstAxis(graphPtr->axisChain[0]);
    axes.y = Rbc_GetFirstAxis(graphPtr->axisChain[1]);

    point = Rbc_Map2D(graphPtr, x, y, &axes);
    Tcl_AppendElement(interp, Rbc_Itoa(ROUND(point.x)));
    Tcl_AppendElement(interp, Rbc_Itoa(ROUND(point.y)));
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * StringToFormat --
 *
 *      Convert a string represent a node number into its integer
 *      value.
 *
 * Results:
 *      The return value is a standard Tcl result.
 *
 * Side Effects:
 *      TODO: Side Effects
 *
 *----------------------------------------------------------------------
 */
static int
StringToFormat(clientData, interp, switchName, string, record, offset)
    ClientData clientData; /* Contains a pointer to the tabset containing
                            * this image. */
    Tcl_Interp *interp; /* Interpreter to send results back to */
    char *switchName; /* Not used. */
    char *string; /* String representation */
    char *record; /* Structure record */
    int offset; /* Offset to field in structure */
{
    int *formatPtr = (int *)(record + offset);
    char c;

    c = string[0];
    if ((c == 'p') && (strcmp(string, "photo") == 0)) {
        *formatPtr = FORMAT_PHOTO;
#ifdef WIN32
    } else if ((c == 'e') && (strcmp(string, "emf") == 0)) {
        *formatPtr = FORMAT_EMF;
    } else if ((c == 'w') && (strcmp(string, "wmf") == 0)) {
        *formatPtr = FORMAT_WMF;
#endif /* WIN32 */
    } else {
#ifdef WIN32
        Tcl_AppendResult(interp, "bad format \"", string,
                         "\": should be photo, emf, or wmf.", (char *)NULL);
#else
        Tcl_AppendResult(interp, "bad format \"", string,
                         "\": should be photo.", (char *)NULL);
#endif /* WIN32 */
        return TCL_ERROR;
    }
    return TCL_OK;
}

#ifdef WIN32
/*
 *----------------------------------------------------------------------
 *
 * InitMetaFileHeader --
 *
 *      TODO: Description
 *
 * Results:
 *      TODO: Results
 *
 * Side Effects:
 *      TODO: Side Effects
 *
 *----------------------------------------------------------------------
 */
static int
InitMetaFileHeader(
    Tk_Window tkwin,
    int width, int height,
    APMHEADER *mfhPtr)
{
    unsigned int *p;
    unsigned int sum;
    Screen *screen;
#define MM_INCH		25.4
    double dpiX, dpiY;

    mfhPtr->key = 0x9ac6cdd7L;
    mfhPtr->hmf = 0;
    mfhPtr->inch = 1440;

    screen = Tk_Screen(tkwin);
    dpiX = (WidthOfScreen(screen) * MM_INCH) / WidthMMOfScreen(screen);
    dpiY = (HeightOfScreen(screen) * MM_INCH) / HeightMMOfScreen(screen);

    mfhPtr->bbox.Left = mfhPtr->bbox.Top = 0;
    mfhPtr->bbox.Bottom = (SHORT)((width * 1440)/ dpiX);
    mfhPtr->bbox.Right = (SHORT)((height * 1440) / dpiY);
    mfhPtr->reserved = 0;
    sum = 0;
    for (p = (unsigned int *)mfhPtr;
            p < (unsigned int *)&(mfhPtr->checksum); p++) {
        sum ^= *p;
    }
    mfhPtr->checksum = sum;
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * CreateAPMetaFile --
 *
 *      TODO: Description
 *
 * Results:
 *      TODO: Results
 *
 * Side Effects:
 *      TODO: Side Effects
 *
 *----------------------------------------------------------------------
 */
static int
CreateAPMetaFile(
    Tcl_Interp *interp,
    HANDLE hMetaFile,
    HDC hDC,
    APMHEADER *mfhPtr,
    char *fileName)
{
    HANDLE hFile;
    HANDLE hMem;
    LPVOID buffer;
    int result;
    DWORD count, nBytes;

    result = TCL_ERROR;
    hMem = NULL;
    hFile = CreateFile(
                fileName,	/* File path */
                GENERIC_WRITE,	/* Access mode */
                0,		/* No sharing. */
                NULL,		/* Security attributes */
                CREATE_ALWAYS,	/* Overwrite any existing file */
                FILE_ATTRIBUTE_NORMAL,
                NULL);			/* No template file */
    if (hFile == INVALID_HANDLE_VALUE) {
        Tcl_AppendResult(interp, "can't create metafile \"", fileName,
                         "\":", Rbc_LastError(), (char *)NULL);
        return TCL_ERROR;
    }
    if ((!WriteFile(hFile, (LPVOID)mfhPtr, sizeof(APMHEADER), &count,
                    NULL)) || (count != sizeof(APMHEADER))) {
        Tcl_AppendResult(interp, "can't create metafile header to \"",
                         fileName, "\":", Rbc_LastError(), (char *)NULL);
        goto error;
    }
    nBytes = GetWinMetaFileBits(hMetaFile, 0, NULL, MM_ANISOTROPIC, hDC);
    hMem = GlobalAlloc(GHND, nBytes);
    if (hMem == NULL) {
        Tcl_AppendResult(interp, "can't create allocate global memory:",
                         Rbc_LastError(), (char *)NULL);
        goto error;
    }
    buffer = (LPVOID)GlobalLock(hMem);
    if (!GetWinMetaFileBits(hMetaFile, nBytes, buffer, MM_ANISOTROPIC, hDC)) {
        Tcl_AppendResult(interp, "can't get metafile bits:",
                         Rbc_LastError(), (char *)NULL);
        goto error;
    }
    if ((!WriteFile(hFile, buffer, nBytes, &count, NULL)) ||
            (count != nBytes)) {
        Tcl_AppendResult(interp, "can't write metafile bits:",
                         Rbc_LastError(), (char *)NULL);
        goto error;
    }
    result = TCL_OK;
error:
    CloseHandle(hFile);
    if (hMem != NULL) {
        GlobalUnlock(hMem);
        GlobalFree(hMem);
    }
    return result;
}
#endif /*WIN32*/



/*
 * --------------------------------------------------------------------------
 *
 * SnapOp --
 *
 *      Snaps a picture of the graph and stores it in the specified image
 *
 * Results:
 *      Returns a standard Tcl result.  interp->result contains
 *      the list of the graph coordinates. If an error occurred
 *      while parsing the window positions, TCL_ERROR is returned,
 *      then interp->result will contain an error message.
 *
 * Side Effects:
 *      TODO: Side Effects
 *
 * -------------------------------------------------------------------------
 */
static int
SnapOp(graphPtr, interp, objc, objv)
    Graph *graphPtr; /* Graph widget record */
    Tcl_Interp *interp;
    int objc; /* Not used. */
    Tcl_Obj *CONST *objv;
{
    int result;
    Pixmap drawable;
    int noBackingStore = 0;
    register int i;
    SnapData data;

    /* .g snap ?switches? name */
    data.height = Tk_Height(graphPtr->tkwin);
    data.width = Tk_Width(graphPtr->tkwin);
    data.format = FORMAT_PHOTO;
    /* Process switches  */
    i = Rbc_ProcessSwitches(interp, snapSwitches, objc - 2, objv + 2, (char *)&data, RBC_SWITCH_OBJV_PARTIAL);
    if (i < 0) {
        return TCL_ERROR;
    }
    i += 2;
    if (i >= objc) {
        Tcl_AppendResult(interp, "missing name argument: should be \"",
                         objv[0], "snap ?switches? name\"", (char *)NULL);
        return TCL_ERROR;
    }
    data.name = Tcl_GetStringFromObj(objv[i], NULL);
    if (data.width < 2) {
        data.width = 400;
    }
    if (data.height < 2) {
        data.height = 400;
    }
    /* Always re-compute the layout of the graph before snapping the photo. */
    graphPtr->width = data.width;
    graphPtr->height = data.height;
    Rbc_LayoutGraph(graphPtr);

    drawable = Tk_WindowId(graphPtr->tkwin);
    if (data.format == FORMAT_PHOTO) {
        drawable = Tk_GetPixmap(graphPtr->display, drawable, graphPtr->width,
                                graphPtr->height, Tk_Depth(graphPtr->tkwin));
#ifdef WIN32
        assert(drawable != None);
#endif
        graphPtr->flags |= RESET_WORLD;
        Rbc_DrawGraph(graphPtr, drawable, noBackingStore);
        result = Rbc_SnapPhoto(interp, graphPtr->tkwin, drawable, 0, 0,
                               data.width, data.height, data.width, data.height, data.name, 1.0);
        Tk_FreePixmap(graphPtr->display, drawable);
#ifdef WIN32
    } else if ((data.format == FORMAT_WMF) || (data.format == FORMAT_EMF)) {
        TkWinDC drawableDC;
        TkWinDCState state;
        HDC hRefDC, hDC;
        HENHMETAFILE hMetaFile;
        Tcl_DString dString;
        char *title;

        hRefDC = TkWinGetDrawableDC(graphPtr->display, drawable, &state);

        Tcl_DStringInit(&dString);
        Tcl_DStringAppend(&dString, "RBC Graph ", -1);
        Tcl_DStringAppend(&dString, RBC_VERSION, -1);
        Tcl_DStringAppend(&dString, "\0", -1);
        Tcl_DStringAppend(&dString, Tk_PathName(graphPtr->tkwin), -1);
        Tcl_DStringAppend(&dString, "\0", -1);
        title = Tcl_DStringValue(&dString);
        hDC = CreateEnhMetaFile(hRefDC, NULL, NULL, title);
        Tcl_DStringFree(&dString);

        if (hDC == NULL) {
            Tcl_AppendResult(interp, "can't create metafile: ",
                             Rbc_LastError(), (char *)NULL);
            return TCL_ERROR;
        }

        drawableDC.hdc = hDC;
        drawableDC.type = TWD_WINDC;

        Rbc_LayoutGraph(graphPtr);
        graphPtr->flags |= RESET_WORLD;
        Rbc_DrawGraph(graphPtr, (Drawable)&drawableDC, FALSE);

        hMetaFile = CloseEnhMetaFile(hDC);
        if (strcmp(data.name, "CLIPBOARD") == 0) {
            HWND hWnd;

            hWnd = Tk_GetHWND(drawable);
            OpenClipboard(hWnd);
            EmptyClipboard();
            SetClipboardData(CF_ENHMETAFILE, hMetaFile);
            CloseClipboard();
            result = TCL_OK;
        } else {
            result = TCL_ERROR;
            if (data.format == FORMAT_WMF) {
                APMHEADER mfh;

                assert(sizeof(mfh) == 22);
                InitMetaFileHeader(graphPtr->tkwin, data.width, data.height,
                                   &mfh);
                result = CreateAPMetaFile(interp, hMetaFile, hRefDC, &mfh,
                                          data.name);
            } else {
                HENHMETAFILE hMetaFile2;

                hMetaFile2 = CopyEnhMetaFile(hMetaFile, data.name);
                if (hMetaFile2 != NULL) {
                    result = TCL_OK;
                    DeleteEnhMetaFile(hMetaFile2);
                }
            }
            DeleteEnhMetaFile(hMetaFile);
        }
        TkWinReleaseDrawableDC(drawable, hRefDC, &state);
#endif /*WIN32*/
    } else {
        Tcl_AppendResult(interp, "bad snapshot format", (char *)NULL);
        return TCL_ERROR;
    }
    graphPtr->flags = MAP_WORLD;
    Rbc_EventuallyRedrawGraph(graphPtr);
    return result;
}

static Rbc_OpSpec graphOps[] = {
    {"axis", 1, (Rbc_Op)Rbc_VirtualAxisOp, 2, 0, "oper ?args?",},
    {"bar", 2, (Rbc_Op)BarOp, 2, 0, "oper ?args?",},
    {"cget", 2, (Rbc_Op)CgetOp, 3, 3, "option",},
    {"configure", 2, (Rbc_Op)ConfigureOp, 2, 0, "?option value?...",},
    {"crosshairs", 2, (Rbc_Op)Rbc_CrosshairsOp, 2, 0, "oper ?args?",},
    {"element", 2, (Rbc_Op)ElementOp, 2, 0, "oper ?args?",},
    {"extents", 2, (Rbc_Op)ExtentsOp, 3, 3, "item",},
    {"grid", 1, (Rbc_Op)Rbc_GridOp, 2, 0, "oper ?args?",},
    {"inside", 3, (Rbc_Op)InsideOp, 4, 4, "winX winY",},
    {"invtransform", 3, (Rbc_Op)InvtransformOp, 4, 4, "winX winY",},
    {"legend", 2, (Rbc_Op)Rbc_LegendOp, 2, 0, "oper ?args?",},
    {"line", 2, (Rbc_Op)LineOp, 2, 0, "oper ?args?",},
    {"marker", 2, (Rbc_Op)Rbc_MarkerOp, 2, 0, "oper ?args?",},
    {"pen", 2, (Rbc_Op)Rbc_PenOp, 2, 0, "oper ?args?",},
    {"postscript", 2, (Rbc_Op)Rbc_PostScriptOp, 2, 0, "oper ?args?",},
    {"snap", 1, (Rbc_Op)SnapOp, 3, 0, "?switches? name",},
    {"transform", 1, (Rbc_Op)TransformOp, 4, 4, "x y",},
    {"x2axis", 2, (Rbc_Op)X2AxisOp, 2, 0, "oper ?args?",},
    {"xaxis", 2, (Rbc_Op)XAxisOp, 2, 0, "oper ?args?",},
    {"y2axis", 2, (Rbc_Op)Y2AxisOp, 2, 0, "oper ?args?",},
    {"yaxis", 2, (Rbc_Op)YAxisOp, 2, 0, "oper ?args?",},
};
static int nGraphOps = sizeof(graphOps) / sizeof(Rbc_OpSpec);

/*
 *----------------------------------------------------------------------
 *
 * Rbc_GraphInstCmdProc --
 *
 *      TODO: Description
 *
 * Results:
 *      TODO: Results
 *
 * Side Effects:
 *      TODO: Side Effects
 *
 *----------------------------------------------------------------------
 */
int
Rbc_GraphInstCmdProc(clientData, interp, argc, argv)
    ClientData clientData;
    Tcl_Interp *interp;
    int argc;
    CONST84 char *argv[];
{
    Rbc_Op proc;
    int result;
    Graph *graphPtr = clientData;

    proc = Rbc_GetOp(interp, nGraphOps, graphOps, RBC_OP_ARG1, argc, argv, 0);
    if (proc == NULL) {
        return TCL_ERROR;
    }
    Tcl_Preserve(graphPtr);
    result = (*proc) (graphPtr, interp, argc, argv);
    Tcl_Release(graphPtr);
    return result;
}

/*
 *----------------------------------------------------------------------
 *
 * Rbc_GraphInstObjCmdProc --
 *
 *      TODO: Description
 *
 * Results:
 *      TODO: Results
 *
 * Side Effects:
 *      TODO: Side Effects
 *
 *----------------------------------------------------------------------
 */
int
Rbc_GraphInstObjCmdProc (clientData, interp, objc, objv)
    ClientData clientData;
	Tcl_Interp *interp;
    int objc;
    Tcl_Obj *CONST *objv;
{
	int index;
	Graph *graphPtr = clientData;

	if (objc < 2) {
		Tcl_WrongNumArgs(interp, 1, objv, "option ?args?");
		return TCL_ERROR;
	}

	if (Tcl_GetIndexFromObj(interp, objv[1], subCmds, "option", 0, &index) != TCL_OK) {
		return TCL_ERROR;
	}

	switch(index) {
		case axisIdx: {
			if (objc < 3) {
				Tcl_WrongNumArgs(interp, 2, objv, "oper ?args?");
				return TCL_ERROR;
			} else {
				return TCL_OK;
			}

			break;
		}
		case barIdx: {
			if (objc < 4) {
				Tcl_WrongNumArgs(interp, 2, objv, "oper ?args?");
				return TCL_ERROR;
			} else {
				return BarOp(graphPtr, interp, objc, objv);
			}

			break;
		}
		case cgetIdx:{
			if (objc != 3) {
				Tcl_WrongNumArgs(interp, 2, objv, "option");
				return TCL_ERROR;
			} else {
				return CgetOp(graphPtr, interp, objc, objv);
			}

			break;
		}
		case configureIdx: {
			return ConfigureOp(graphPtr, interp, objc, objv);
			break;
		}
		case crosshairsIdx: {
			if (objc < 3) {
				Tcl_WrongNumArgs(interp, 2, objv, "oper ?args?");
				return TCL_ERROR;
			} else {
				return TCL_OK;
			}

			break;
		}
		case elementIdx: {
			if (objc < 3) {
				Tcl_WrongNumArgs(interp, 2, objv, "oper ?args?");
				return TCL_ERROR;
			} else {
				return ElementOp(graphPtr, interp, objc, objv);
			}

			break;
		}
		case extentsIdx: {
			if (objc != 3) {
				Tcl_WrongNumArgs(interp, 2, objv, "item");
				return TCL_ERROR;
			} else {
				return ExtentsOp(graphPtr, interp, objc, objv);
			}

			break;
		}
		case gridIdx: {
			if (objc < 3) {
				Tcl_WrongNumArgs(interp, 2, objv, "oper ?args?");
				return TCL_ERROR;
			} else {
				return TCL_OK;
			}

			break;
		}
		case insideIdx: {
			if (objc != 4) {
				Tcl_WrongNumArgs(interp, 2, objv, "winX winY");
				return TCL_ERROR;
			} else {
				return InsideOp(graphPtr, interp, objc, objv);
			}

			break;
		}
		case invtransformIdx: {
			if (objc != 4) {
				Tcl_WrongNumArgs(interp, 2, objv, "winX winY");
				return TCL_ERROR;
			} else {
				return InvtransformOp(graphPtr, interp, objc, objv);
			}

			break;
		}
		case legendIdx: {
			if (objc < 3) {
				Tcl_WrongNumArgs(interp, 2, objv, "oper ?args?");
				return TCL_ERROR;
			} else {
				return TCL_OK;
			}

			break;
		}
		case lineIdx: {
			if (objc < 3) {
				Tcl_WrongNumArgs(interp, 2, objv, "oper ?args?");
				return TCL_ERROR;
			} else {
				return LineOp(graphPtr, interp, objc, objv);
			}

			break;
		}
		case markerIdx: {
			if (objc < 3) {
				Tcl_WrongNumArgs(interp, 2, objv, "oper ?args?");
				return TCL_ERROR;
			} else {
				return TCL_OK;
			}

			break;
		}
		case penIdx: {
			if (objc < 3) {
				Tcl_WrongNumArgs(interp, 2, objv, "oper ?args?");
				return TCL_ERROR;
			} else {
				return TCL_OK;
			}

			break;
		}
		case postscriptIdx: {
			if (objc < 3) {
				Tcl_WrongNumArgs(interp, 2, objv, "oper ?args?");
				return TCL_ERROR;
			} else {
				return TCL_OK;
			}

			break;
		}
		case snapIdx: {
			if (objc < 3) {
				Tcl_WrongNumArgs(interp, 2, objv, "?switches? name");
				return TCL_ERROR;
			} else {
				return TCL_OK;
			}

			break;
		}
		case transformIdx: {
			if (objc != 4) {
				Tcl_WrongNumArgs(interp, 2, objv, "x y");
				return TCL_ERROR;
			} else {
				return TransformOp(graphPtr, interp, objc, objv);
			}

			break;
		}
		case x2axisIdx: {
			if (objc < 3) {
				Tcl_WrongNumArgs(interp, 2, objv, "oper ?args?");
				return TCL_ERROR;
			} else {
				return TCL_OK;
			}

			break;
		}
		case xaxisIdx: {
			if (objc < 3) {
				Tcl_WrongNumArgs(interp, 2, objv, "oper ?args?");
				return TCL_ERROR;
			} else {
				return TCL_OK;
			}

			break;
		}
		case y2axisIdx: {
			if (objc < 3) {
				Tcl_WrongNumArgs(interp, 2, objv, "oper ?args?");
				return TCL_ERROR;
			} else {
				return Y2AxisOp(graphPtr, interp, objc, objv);
			}

			break;
		}
		case yaxisIdx: {
			if (objc < 3) {
				Tcl_WrongNumArgs(interp, 2, objv, "oper ?args?");
				return TCL_ERROR;
			} else {
				return YAxisOp(graphPtr, interp, objc, objv);
			}

			break;
		}
	}

//	proc = Rbc_GetOp(interp, nGraphOps, graphOps, RBC_OP_ARG1, argc, argv, 0);
//
//	if (proc == NULL) {
//		return TCL_ERROR;
//	}
//	Tcl_Preserve(graphPtr);
//	result = (*proc) (graphPtr, interp, argc, argv);
//	Tcl_Release(graphPtr);
//	return result;
	return TCL_OK;
}

/*
 * --------------------------------------------------------------------------
 *
 * NewGraph --
 *
 *      Creates a new window and Tcl command representing an
 *      instance of a graph widget.
 *
 * Results:
 *      A standard Tcl result.
 *
 * Side effects:
 *      See the user documentation.
 *
 * --------------------------------------------------------------------------
 */
static int
NewGraph(interp, clientData, objc, objv, classUid)
    Tcl_Interp *interp;
	ClientData clientData;
    int objc;
    Tcl_Obj *CONST *objv;
    Rbc_Uid classUid;
{
    Graph *graphPtr;
    if (objc < 2) {
    	Tcl_WrongNumArgs(interp, 1, objv, "pathName ?option value?...");
        return TCL_ERROR;
    }

    graphPtr = CreateGraph(interp, clientData, objc, objv, classUid);
    if (graphPtr == NULL) {
        return TCL_ERROR;
    }
    Tcl_SetStringObj(Tcl_GetObjResult(interp), Tk_PathName(graphPtr->tkwin), -1);
    return TCL_OK;
}

/*
 * --------------------------------------------------------------------------
 *
 * GraphObjCmd --
 *
 *      Creates a new window and Tcl command representing an
 *      instance of a graph widget.
 *
 * Results:
 *      A standard Tcl result.
 *
 * Side effects:
 *      See the user documentation.
 *
 * --------------------------------------------------------------------------
 */
int
GraphObjCmd(clientData, interp, objc, objv)
    ClientData clientData;
	Tcl_Interp *interp;
    int objc;
    Tcl_Obj *CONST *objv;
{
	return NewGraph(interp, clientData, objc, objv, rbcLineElementUid);
}

/*
 *--------------------------------------------------------------
 *
 * BarchartObjCmd --
 *
 *      Creates a new window and Tcl command representing an
 *      instance of a barchart widget.
 *
 * Results:
 *      A standard Tcl result.
 *
 * Side effects:
 *      See the user documentation.
 *
 *--------------------------------------------------------------
 */
static int
BarchartObjCmd(clientData, interp, objc, objv)
    ClientData clientData;
	Tcl_Interp *interp;
    int objc;
    Tcl_Obj *CONST *objv;
{
    return NewGraph(interp, clientData, objc, objv, rbcBarElementUid);
}

/*
 *--------------------------------------------------------------
 *
 * StripchartObjCmd --
 *
 *      Creates a new window and Tcl command representing an
 *      instance of a barchart widget.
 *
 * Results:
 *      A standard Tcl result.
 *
 * Side effects:
 *      See the user documentation.
 *
 *--------------------------------------------------------------
 */
static int
StripchartObjCmd(clientData, interp, objc, objv)
    ClientData clientData;
	Tcl_Interp *interp;
    int objc;
    Tcl_Obj *CONST *objv;
{
    return NewGraph(interp, clientData, objc, objv, rbcStripElementUid);
}

/*
 * -----------------------------------------------------------------------
 *
 * DrawMargins --
 *
 *      Draws the exterior region of the graph (axes, ticks, titles, etc)
 *      onto a pixmap. The interior region is defined by the given
 *      rectangle structure.
 *
 *      ---------------------------------
 *          |                               |
 *          |           rectArr[0]          |
 *          |                               |
 *      ---------------------------------
 *          |     |top           right|     |
 *          |     |                   |     |
 *          |     |                   |     |
 *          | [1] |                   | [2] |
 *          |     |                   |     |
 *          |     |                   |     |
 *          |     |                   |     |
 *          |     |                   |     |
 *          |     |                   |     |
 *          |     |left         bottom|     |
 *      ---------------------------------
 *          |                               |
 *          |          rectArr[3]           |
 *          |                               |
 *      ---------------------------------
 *
 *          X coordinate axis
 *          Y coordinate axis
 *          legend
 *          interior border
 *          exterior border
 *          titles (X and Y axis, graph)
 *
 * Returns:
 *      None.
 *
 * Side Effects:
 *      Exterior of graph is displayed in its window.
 *
 * -----------------------------------------------------------------------
 */
static void
DrawMargins(graphPtr, drawable)
    Graph *graphPtr;
    Drawable drawable; /* Pixmap or window to draw into */
{
    XRectangle rects[4];
    /*
     * Draw the four outer rectangles which encompass the plotting
     * surface. This clears the surrounding area and clips the plot.
     */
    rects[0].x = rects[0].y = rects[3].x = rects[1].x = 0;
    rects[0].width = rects[3].width = (short int)graphPtr->width;
    rects[0].height = (short int)graphPtr->top;
    rects[3].y = graphPtr->bottom;
    rects[3].height = graphPtr->height - graphPtr->bottom;
    rects[2].y = rects[1].y = graphPtr->top;
    rects[1].width = graphPtr->left;
    rects[2].height = rects[1].height = graphPtr->bottom - graphPtr->top;
    rects[2].x = graphPtr->right;
    rects[2].width = graphPtr->width - graphPtr->right;

    if (graphPtr->tile != NULL) {
        Rbc_SetTileOrigin(graphPtr->tkwin, graphPtr->tile, 0, 0);
        Rbc_TileRectangles(graphPtr->tkwin, drawable, graphPtr->tile, rects, 4);
    } else {
        XFillRectangles(graphPtr->display, drawable, graphPtr->fillGC, rects,
                        4);
    }

    /* Draw 3D border around the plotting area */

    if (graphPtr->plotBorderWidth > 0) {
        int x, y, width, height;

        x = graphPtr->left - graphPtr->plotBorderWidth;
        y = graphPtr->top - graphPtr->plotBorderWidth;
        width = (graphPtr->right - graphPtr->left) +
                (2 * graphPtr->plotBorderWidth);
        height = (graphPtr->bottom - graphPtr->top) +
                 (2 * graphPtr->plotBorderWidth);
        Rbc_Draw3DRectangle(graphPtr->tkwin, drawable, graphPtr->border, x, y,
                            width, height, graphPtr->plotBorderWidth, graphPtr->plotRelief);
    }
    if (Rbc_LegendSite(graphPtr->legend) & LEGEND_IN_MARGIN) {
        /* Legend is drawn on one of the graph margins */
        Rbc_DrawLegend(graphPtr->legend, drawable);
    }
    if (graphPtr->title != NULL) {
        Rbc_DrawText(graphPtr->tkwin, drawable, graphPtr->title,
                     &graphPtr->titleTextStyle, graphPtr->titleX, graphPtr->titleY);
    }
    Rbc_DrawAxes(graphPtr, drawable);

}

/*
 *----------------------------------------------------------------------
 *
 * DrawPlotRegion --
 *
 *      Draws the contents of the plotting area.  This consists of
 *      the elements, markers (draw under elements), axis limits,
 *      grid lines, and possibly the legend.  Typically, the output
 *      will be cached into a backing store pixmap, so that redraws
 *      can occur quickly.
 *
 * Results:
 *      None.
 *
 * Side Effects:
 *      TODO: Side Effects
 *
 *----------------------------------------------------------------------
 */
static void
DrawPlotRegion(graphPtr, drawable)
    Graph *graphPtr;
    Drawable drawable; /* Pixmap or window to draw into */
{
    /* Clear the background of the plotting area. */
    XFillRectangle(graphPtr->display, drawable, graphPtr->plotFillGC,
                   graphPtr->left, graphPtr->top, graphPtr->right - graphPtr->left + 1,
                   graphPtr->bottom - graphPtr->top + 1);

    /* Draw the elements, markers, legend, and axis limits. */

    if (!graphPtr->gridPtr->hidden) {
        Rbc_DrawGrid(graphPtr, drawable);
    }
    Rbc_DrawMarkers(graphPtr, drawable, MARKER_UNDER);
    if ((Rbc_LegendSite(graphPtr->legend) & LEGEND_IN_PLOT) &&
            (!Rbc_LegendIsRaised(graphPtr->legend))) {
        Rbc_DrawLegend(graphPtr->legend, drawable);
    }
    Rbc_DrawAxisLimits(graphPtr, drawable);
    Rbc_DrawElements(graphPtr, drawable);
}

/*
 *----------------------------------------------------------------------
 *
 * Rbc_LayoutGraph --
 *
 *      TODO: Description
 *
 * Results:
 *      TODO: Results
 *
 * Side Effects:
 *      TODO: Side Effects
 *
 *----------------------------------------------------------------------
 */
void
Rbc_LayoutGraph(graphPtr)
    Graph *graphPtr;
{
    if (graphPtr->flags & RESET_AXES) {
        Rbc_ResetAxes(graphPtr);
    }
    if (graphPtr->flags & LAYOUT_NEEDED) {
        Rbc_LayoutMargins(graphPtr);
        graphPtr->flags &= ~LAYOUT_NEEDED;
    }
    /* Compute coordinate transformations for graph components */
    if ((graphPtr->vRange > 1) && (graphPtr->hRange > 1)) {
        if (graphPtr->flags & MAP_WORLD) {
            Rbc_MapAxes(graphPtr);
        }
        Rbc_MapElements(graphPtr);
        Rbc_MapMarkers(graphPtr);
        Rbc_MapGrid(graphPtr);
        graphPtr->flags &= ~(MAP_ALL);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * Rbc_DrawGraph --
 *
 *      TODO: Description
 *
 * Results:
 *      TODO: Results
 *
 * Side Effects:
 *      TODO: Side Effects
 *
 *----------------------------------------------------------------------
 */
void
Rbc_DrawGraph(graphPtr, drawable, backingStore)
    Graph *graphPtr;
    Drawable drawable; /* Pixmap or window to draw into */
    int backingStore; /* If non-zero, use backing store for
                       * plotting area. */
{
    if (backingStore) {
        /*
         * Create another pixmap to save elements if one doesn't
         * already exist or the size of the window has changed.
         */
        if ((graphPtr->backPixmap == None) ||
                (graphPtr->backWidth != graphPtr->width) ||
                (graphPtr->backHeight != graphPtr->height)) {

            if (graphPtr->backPixmap != None) {
                Tk_FreePixmap(graphPtr->display, graphPtr->backPixmap);
            }
            graphPtr->backPixmap = Tk_GetPixmap(graphPtr->display,
                                                Tk_WindowId(graphPtr->tkwin), graphPtr->width,
                                                graphPtr->height, Tk_Depth(graphPtr->tkwin));
            graphPtr->backWidth = graphPtr->width;
            graphPtr->backHeight = graphPtr->height;
            graphPtr->flags |= REDRAW_BACKING_STORE;
        }
        if (graphPtr->flags & REDRAW_BACKING_STORE) {
            /* The backing store is new or out-of-date. */
            DrawPlotRegion(graphPtr, graphPtr->backPixmap);
            graphPtr->flags &= ~REDRAW_BACKING_STORE;
        }

        /* Copy the pixmap to the one used for drawing the entire graph. */

        XCopyArea(graphPtr->display, graphPtr->backPixmap, drawable,
                  graphPtr->drawGC, graphPtr->left, graphPtr->top,
                  (graphPtr->right - graphPtr->left + 1),
                  (graphPtr->bottom - graphPtr->top + 1),
                  graphPtr->left, graphPtr->top);
    } else {
        DrawPlotRegion(graphPtr, drawable);
    }

    /* Draw markers above elements */
    Rbc_DrawMarkers(graphPtr, drawable, MARKER_ABOVE);
    Rbc_DrawActiveElements(graphPtr, drawable);

    if (graphPtr->flags & DRAW_MARGINS) {
        DrawMargins(graphPtr, drawable);
    }
    if ((Rbc_LegendSite(graphPtr->legend) & LEGEND_IN_PLOT) &&
            (Rbc_LegendIsRaised(graphPtr->legend))) {
        Rbc_DrawLegend(graphPtr->legend, drawable);
    }
    /* Draw 3D border just inside of the focus highlight ring. */
    if ((graphPtr->borderWidth > 0) && (graphPtr->relief != TK_RELIEF_FLAT)) {
        Rbc_Draw3DRectangle(graphPtr->tkwin, drawable, graphPtr->border,
                            graphPtr->highlightWidth, graphPtr->highlightWidth,
                            graphPtr->width - 2 * graphPtr->highlightWidth,
                            graphPtr->height - 2 * graphPtr->highlightWidth,
                            graphPtr->borderWidth, graphPtr->relief);
    }
    /* Draw focus highlight ring. */
    if ((graphPtr->highlightWidth > 0) && (graphPtr->flags & GRAPH_FOCUS)) {
        GC gc;

        gc = Tk_GCForColor(graphPtr->highlightColor, drawable);
        Tk_DrawFocusHighlight(graphPtr->tkwin, gc, graphPtr->highlightWidth,
                              drawable);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * UpdateMarginTraces --
 *
 *      TODO: Description
 *
 * Results:
 *      TODO: Results
 *
 * Side Effects:
 *      TODO: Side Effects
 *
 *----------------------------------------------------------------------
 */
static void
UpdateMarginTraces(graphPtr)
    Graph *graphPtr;
{
    Margin *marginPtr;
    int size;
    register int i;

    for (i = 0; i < 4; i++) {
        marginPtr = graphPtr->margins + i;
        if (marginPtr->varName != NULL) {	/* Trigger variable traces */
            if ((marginPtr->site == MARGIN_LEFT) ||
                    (marginPtr->site == MARGIN_RIGHT)) {
                size = marginPtr->width;
            } else {
                size = marginPtr->height;
            }
            Tcl_SetVar(graphPtr->interp, marginPtr->varName, Rbc_Itoa(size),
                       TCL_GLOBAL_ONLY);
        }
    }
}

/*
 *----------------------------------------------------------------------
 *
 * DisplayGraph --
 *
 *      This procedure is invoked to display a graph widget.
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      Commands are output to X to display the graph in its
 *      current mode.
 *
 *----------------------------------------------------------------------
 */
static void
DisplayGraph(clientData)
    ClientData clientData;
{
    Graph *graphPtr = clientData;
    Pixmap drawable;

    graphPtr->flags &= ~REDRAW_PENDING;
    if (graphPtr->tkwin == NULL) {
        return;			/* Window destroyed (should not get here) */
    }
#ifdef notdef
    fprintf(stderr, "Calling DisplayGraph(%s)\n", Tk_PathName(graphPtr->tkwin));
#endif
    if (Rbc_GraphUpdateNeeded(graphPtr)) {
        /*
         * One of the elements of the graph has a vector notification
         * pending.  This means that the vector will eventually notify
         * the graph that its data has changed.  Since the graph uses
         * the actual vector (not a copy) we need to keep in-sync.
         * Therefore don't draw right now but wait until we've been
         * notified before redrawing.
         */
        return;
    }
    graphPtr->width = Tk_Width(graphPtr->tkwin);
    graphPtr->height = Tk_Height(graphPtr->tkwin);
    Rbc_LayoutGraph(graphPtr);
    Rbc_UpdateCrosshairs(graphPtr);
    if (!Tk_IsMapped(graphPtr->tkwin)) {
        /* The graph's window isn't displayed, so don't bother
         * drawing anything.  By getting this far, we've at least
         * computed the coordinates of the graph's new layout.  */
        return;
    }

    /* Disable crosshairs before redisplaying to the screen */
    Rbc_DisableCrosshairs(graphPtr);
    /*
     * Create a pixmap the size of the window for double buffering.
     */
    if (graphPtr->doubleBuffer) {
        drawable = Tk_GetPixmap(graphPtr->display, Tk_WindowId(graphPtr->tkwin),
                                graphPtr->width, graphPtr->height, Tk_Depth(graphPtr->tkwin));
    } else {
        drawable = Tk_WindowId(graphPtr->tkwin);
    }
#ifdef WIN32
    assert(drawable != None);
#endif
    Rbc_DrawGraph(graphPtr, drawable, graphPtr->backingStore && graphPtr->doubleBuffer);
    if (graphPtr->flags & DRAW_MARGINS) {
        XCopyArea(graphPtr->display, drawable, Tk_WindowId(graphPtr->tkwin),
                  graphPtr->drawGC, 0, 0, graphPtr->width, graphPtr->height, 0, 0);
    } else {
        XCopyArea(graphPtr->display, drawable, Tk_WindowId(graphPtr->tkwin),
                  graphPtr->drawGC, graphPtr->left, graphPtr->top,
                  (graphPtr->right - graphPtr->left + 1),
                  (graphPtr->bottom - graphPtr->top + 1),
                  graphPtr->left, graphPtr->top);
    }
    if (graphPtr->doubleBuffer) {
        Tk_FreePixmap(graphPtr->display, drawable);
    }
    Rbc_EnableCrosshairs(graphPtr);
    graphPtr->flags &= ~RESET_WORLD;
    UpdateMarginTraces(graphPtr);
}

/*
 *----------------------------------------------------------------------
 *
 * Rbc_GraphInit --
 *
 *      TODO: Description
 *
 * Results:
 *      TODO: Results
 *
 * Side Effects:
 *      TODO: Side Effects
 *
 *----------------------------------------------------------------------
 */
int
Rbc_GraphInit(interp)
    Tcl_Interp *interp;
{
    rbcBarElementUid = (Rbc_Uid)Tk_GetUid("BarElement");
    rbcLineElementUid = (Rbc_Uid)Tk_GetUid("LineElement");
    rbcStripElementUid = (Rbc_Uid)Tk_GetUid("StripElement");
    rbcContourElementUid = (Rbc_Uid)Tk_GetUid("ContourElement");

    rbcLineMarkerUid = (Rbc_Uid)Tk_GetUid("LineMarker");
    rbcBitmapMarkerUid = (Rbc_Uid)Tk_GetUid("BitmapMarker");
    rbcImageMarkerUid = (Rbc_Uid)Tk_GetUid("ImageMarker");
    rbcTextMarkerUid = (Rbc_Uid)Tk_GetUid("TextMarker");
    rbcPolygonMarkerUid = (Rbc_Uid)Tk_GetUid("PolygonMarker");
    rbcWindowMarkerUid = (Rbc_Uid)Tk_GetUid("WindowMarker");

    rbcXAxisUid = (Rbc_Uid)Tk_GetUid("X");
    rbcYAxisUid = (Rbc_Uid)Tk_GetUid("Y");


    Tcl_CreateObjCommand(interp, "rbc::graph", GraphObjCmd, (ClientData)NULL, (Tcl_CmdDeleteProc *) NULL);
    Tcl_CreateObjCommand(interp, "rbc::barchart", BarchartObjCmd, (ClientData)NULL, (Tcl_CmdDeleteProc *) NULL);
    Tcl_CreateObjCommand(interp, "rbc::stripchart", StripchartObjCmd, (ClientData)NULL, (Tcl_CmdDeleteProc *) NULL);

    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Rbc_GetGraphFromWindowData --
 *
 *      TODO: Description
 *
 * Results:
 *      TODO: Results
 *
 * Side Effects:
 *      TODO: Side Effects
 *
 *----------------------------------------------------------------------
 */
Graph *
Rbc_GetGraphFromWindowData(tkwin)
    Tk_Window tkwin;
{
    Graph *graphPtr;

    while (tkwin != NULL) {
        graphPtr = (Graph *)Rbc_GetWindowInstanceData(tkwin);
        if (graphPtr != NULL) {
            return graphPtr;
        }
        tkwin = Tk_Parent(tkwin);
    }
    return NULL;
}

/*
 *----------------------------------------------------------------------
 *
 * Rbc_GraphType --
 *
 *      TODO: Description
 *
 * Results:
 *      TODO: Results
 *
 * Side Effects:
 *      TODO: Side Effects
 *
 *----------------------------------------------------------------------
 */
int
Rbc_GraphType(graphPtr)
    Graph *graphPtr;
{
    if (graphPtr->classUid == rbcLineElementUid) {
        return GRAPH;
    } else if (graphPtr->classUid == rbcBarElementUid) {
        return BARCHART;
    } else if (graphPtr->classUid == rbcStripElementUid) {
        return STRIPCHART;
    }
    return 0;
}
