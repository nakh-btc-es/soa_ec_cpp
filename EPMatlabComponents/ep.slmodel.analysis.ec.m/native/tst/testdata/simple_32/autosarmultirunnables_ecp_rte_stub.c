#ifndef _AUTOSARMULTIRUNNABLES_ECP_RTE_STUB_ET_C_
#define _AUTOSARMULTIRUNNABLES_ECP_RTE_STUB_ET_C_

#include "autosarmultirunnables_ecp_rte_stub.h"

real_T RteStub_Interface1_RPort_DE1;
uint8_T RteStub_Interface1_DE1_errorstatus;
int8_T RteStub_IRV3;
int8_T RteStub_Interface2_PPort_DE1;
real_T RteStub_IRV1;
real_T RteStub_IRV2;
int8_T RteStub_Interface2_PPort_DE3[2];
real_T RteStub_Interface2_PPort_DE4;
real_T RteStub_IRV4;
real_T RteStub_Interface1_RPort_DE2[2];
int8_T RteStub_Interface2_PPort_DE2;
 real_T Rte_IRead_ASWC_Runnable1_RPort_DE1(void){
   return RteStub_Interface1_RPort_DE1;
}

 Std_ReturnType Rte_IStatus_ASWC_Runnable1_RPort_DE1(void){
   return RteStub_Interface1_DE1_errorstatus;
}

 int8_T Rte_IrvIRead_ASWC_Runnable1_IRV3(void){
   return RteStub_IRV3;
}

void Rte_IWrite_ASWC_Runnable1_PPort_DE1(  int8_T argIn){
   RteStub_Interface2_PPort_DE1 = argIn;
}

void Rte_IrvIWrite_ASWC_Runnable1_IRV1(  real_T argIn){
   RteStub_IRV1 = argIn;
}

 real_T Rte_IrvIRead_ASWC_Runnable2_IRV1(void){
   return RteStub_IRV1;
}

 real_T Rte_IrvIRead_ASWC_Runnable2_IRV2(void){
   return RteStub_IRV2;
}

void Rte_IWrite_ASWC_Runnable2_PPort_DE3( const int8_T *argIn){
  int i;
  for(i=0; i<2;i++) {
    RteStub_Interface2_PPort_DE3[i] = argIn[i];
  }}

void Rte_IWrite_ASWC_Runnable2_PPort_DE4(  real_T argIn){
   RteStub_Interface2_PPort_DE4 = argIn;
}

void Rte_IrvIWrite_ASWC_Runnable2_IRV4(  real_T argIn){
   RteStub_IRV4 = argIn;
}

 real_T Rte_IrvIRead_ASWC_Runnable3_IRV4(void){
   return RteStub_IRV4;
}

const real_T* Rte_IRead_ASWC_Runnable3_RPort_DE2(void){
   return &RteStub_Interface1_RPort_DE2[0];
}

void Rte_IrvIWrite_ASWC_Runnable3_IRV3(  int8_T argIn){
   RteStub_IRV3 = argIn;
}

void Rte_IWrite_ASWC_Runnable3_PPort_DE2(  int8_T argIn){
   RteStub_Interface2_PPort_DE2 = argIn;
}

void Rte_IrvIWrite_ASWC_Runnable3_IRV2(  real_T argIn){
   RteStub_IRV2 = argIn;
}

void Rte_IWrite_ASWC_Runnable_Init_PPort_DE1(  int8_T argIn){
   RteStub_Interface2_PPort_DE1 = argIn;
}

void Rte_IrvIWrite_ASWC_Runnable_Init_IRV1(  real_T argIn){
   RteStub_IRV1 = argIn;
}

void Rte_IWrite_ASWC_Runnable_Init_PPort_DE3( const int8_T *argIn){
  int i;
  for(i=0; i<2;i++) {
    RteStub_Interface2_PPort_DE3[i] = argIn[i];
  }}

void Rte_IWrite_ASWC_Runnable_Init_PPort_DE4(  real_T argIn){
   RteStub_Interface2_PPort_DE4 = argIn;
}

void Rte_IrvIWrite_ASWC_Runnable_Init_IRV4(  real_T argIn){
   RteStub_IRV4 = argIn;
}

void Rte_IrvIWrite_ASWC_Runnable_Init_IRV3(  int8_T argIn){
   RteStub_IRV3 = argIn;
}

void Rte_IWrite_ASWC_Runnable_Init_PPort_DE2(  int8_T argIn){
   RteStub_Interface2_PPort_DE2 = argIn;
}

void Rte_IrvIWrite_ASWC_Runnable_Init_IRV2(  real_T argIn){
   RteStub_IRV2 = argIn;
}

#endif //_AUTOSARMULTIRUNNABLES_ECP_RTE_STUB_ET_C_
