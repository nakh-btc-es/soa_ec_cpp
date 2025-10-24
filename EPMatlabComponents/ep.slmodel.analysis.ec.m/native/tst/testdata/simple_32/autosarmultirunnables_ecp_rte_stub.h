#ifndef _AUTOSARMULTIRUNNABLES_ECP_RTE_STUB_ET_H_
#define _AUTOSARMULTIRUNNABLES_ECP_RTE_STUB_ET_H_

#include "autosarmultirunnables.h"

extern  real_T RteStub_Interface1_RPort_DE1;
extern  uint8_T RteStub_Interface1_DE1_errorstatus;
extern  int8_T RteStub_IRV3;
extern  int8_T RteStub_Interface2_PPort_DE1;
extern  real_T RteStub_IRV1;
extern  real_T RteStub_IRV2;
extern  int8_T RteStub_Interface2_PPort_DE3[2];
extern  real_T RteStub_Interface2_PPort_DE4;
extern  real_T RteStub_IRV4;
extern  real_T RteStub_Interface1_RPort_DE2[2];
extern  int8_T RteStub_Interface2_PPort_DE2;
 real_T Rte_IRead_ASWC_Runnable1_RPort_DE1(void);

 Std_ReturnType Rte_IStatus_ASWC_Runnable1_RPort_DE1(void);

 int8_T Rte_IrvIRead_ASWC_Runnable1_IRV3(void);

void Rte_IWrite_ASWC_Runnable1_PPort_DE1(  int8_T argIn);

void Rte_IrvIWrite_ASWC_Runnable1_IRV1(  real_T argIn);

 real_T Rte_IrvIRead_ASWC_Runnable2_IRV1(void);

 real_T Rte_IrvIRead_ASWC_Runnable2_IRV2(void);

void Rte_IWrite_ASWC_Runnable2_PPort_DE3( const int8_T *argIn);

void Rte_IWrite_ASWC_Runnable2_PPort_DE4(  real_T argIn);

void Rte_IrvIWrite_ASWC_Runnable2_IRV4(  real_T argIn);

 real_T Rte_IrvIRead_ASWC_Runnable3_IRV4(void);

const real_T* Rte_IRead_ASWC_Runnable3_RPort_DE2(void);

void Rte_IrvIWrite_ASWC_Runnable3_IRV3(  int8_T argIn);

void Rte_IWrite_ASWC_Runnable3_PPort_DE2(  int8_T argIn);

void Rte_IrvIWrite_ASWC_Runnable3_IRV2(  real_T argIn);

void Rte_IWrite_ASWC_Runnable_Init_PPort_DE1(  int8_T argIn);

void Rte_IrvIWrite_ASWC_Runnable_Init_IRV1(  real_T argIn);

void Rte_IWrite_ASWC_Runnable_Init_PPort_DE3( const int8_T *argIn);

void Rte_IWrite_ASWC_Runnable_Init_PPort_DE4(  real_T argIn);

void Rte_IrvIWrite_ASWC_Runnable_Init_IRV4(  real_T argIn);

void Rte_IrvIWrite_ASWC_Runnable_Init_IRV3(  int8_T argIn);

void Rte_IWrite_ASWC_Runnable_Init_PPort_DE2(  int8_T argIn);

void Rte_IrvIWrite_ASWC_Runnable_Init_IRV2(  real_T argIn);

#endif //_AUTOSARMULTIRUNNABLES_ECP_RTE_STUB_ET_H_
