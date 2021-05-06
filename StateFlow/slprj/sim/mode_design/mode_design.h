#ifndef RTW_HEADER_mode_design_h_
#define RTW_HEADER_mode_design_h_
#include <string.h>
#include <stddef.h>
#include "rtw_modelmap_simtarget.h"
#ifndef mode_design_COMMON_INCLUDES_
#define mode_design_COMMON_INCLUDES_
#include "rtwtypes.h"
#include "slsv_diagnostic_codegen_c_api.h"
#include "sl_AsyncioQueue/AsyncioQueueCAPI.h"
#include "simstruc.h"
#include "fixedpoint.h"
#include "sf_runtime/sfc_sdi.h"
#endif
#include "mode_design_types.h"
#include "multiword_types.h"
#include "rt_nonfinite.h"
typedef struct { sdiBlockID_t hpjk4qcnoc ; SignalExportStruct lsg3yqlgvr ;
SignalExportStruct jqtcc3npv3 ; SignalExportStruct jonozqtnqd ;
SignalExportStruct nf01304b0g ; SignalExportStruct bzawreyuej ;
SignalExportStruct ae0s2tvefv ; SignalExportStruct bvc2t2g3ef ;
SignalExportStruct e12j4k5szq ; uint8_T mf5prq1shh ; uint8_T ejirwfemzh [ 5 ]
; uint8_T mjwyljo4t3 [ 5 ] ; uint8_T fvnju2hztr ; uint8_T dnoeire1ul ; }
bcwjk1v1yl ; struct kkxjgr4c35 { struct SimStruct_tag * _mdlRefSfcnS ; struct
{ rtwCAPI_ModelMappingInfo mmi ; rtwCAPI_ModelMapLoggingInstanceInfo
mmiLogInstanceInfo ; sysRanDType * systemRan [ 3 ] ; int_T systemTid [ 3 ] ;
} DataMapInfo ; struct { int_T mdlref_GlobalTID [ 1 ] ; } Timing ; } ;
typedef struct { bcwjk1v1yl rtdw ; mlyn3llnfw rtm ; } dkcrvwdagj0 ; extern
void b45ft12ktd ( SimStruct * _mdlRefSfcnS , int_T mdlref_TID0 , mlyn3llnfw *
const ivdj2ug3fr , bcwjk1v1yl * localDW , void * sysRanPtr , int contextTid ,
rtwCAPI_ModelMappingInfo * rt_ParentMMI , const char_T * rt_ChildPath , int_T
rt_ChildMMIIdx , int_T rt_CSTATEIdx ) ; extern void
mr_mode_design_MdlInfoRegFcn ( SimStruct * mdlRefSfcnS , char_T * modelName ,
int_T * retVal ) ; extern mxArray * mr_mode_design_GetDWork ( const
dkcrvwdagj0 * mdlrefDW ) ; extern void mr_mode_design_SetDWork ( dkcrvwdagj0
* mdlrefDW , const mxArray * ssDW ) ; extern void
mr_mode_design_RegisterSimStateChecksum ( SimStruct * S ) ; extern mxArray *
mr_mode_design_GetSimStateDisallowedBlocks ( ) ; extern const
rtwCAPI_ModelMappingStaticInfo * mode_design_GetCAPIStaticMap ( void ) ;
extern void pd20lwrpwx ( mlyn3llnfw * const ivdj2ug3fr , uint8_T * a0qfcphyqf
, uint8_T * jecjf0o5yi , bcwjk1v1yl * localDW ) ; extern void cf51bmfou0 (
uint8_T * a0qfcphyqf , uint8_T * jecjf0o5yi , bcwjk1v1yl * localDW ) ; extern
void gejyfpldk5 ( uint8_T * a0qfcphyqf , uint8_T * jecjf0o5yi , bcwjk1v1yl *
localDW ) ; extern void fyfh3ujdpf ( bcwjk1v1yl * localDW ) ; extern void
mode_design ( const uint8_T * pq0zofnyuc , uint8_T * a0qfcphyqf , uint8_T *
jecjf0o5yi , bcwjk1v1yl * localDW ) ; extern void itmfaucbif ( mlyn3llnfw *
const ivdj2ug3fr ) ;
#endif
