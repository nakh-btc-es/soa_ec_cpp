#ifndef _ECP_STUB_SWC_SCHEDULER_ET_C_
#define _ECP_STUB_SWC_SCHEDULER_ET_C_

#include "ecp_stub_swc_scheduler.h"

unsigned long stub_swc_cnt = 0;

void swc_wrapper_scheduler_init(void){
    Runnable_Init();
}

void swc_wrapper_scheduler_step(void){

    if (stub_swc_cnt % 5 == 0) {
        Runnable3();
    }

    Runnable1();

    Runnable2();

    stub_swc_cnt++;
}

#endif //_ECP_STUB_SWC_SCHEDULER_ET_C_
