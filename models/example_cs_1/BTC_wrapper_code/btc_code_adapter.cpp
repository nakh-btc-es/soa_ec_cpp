
#include "SOA_demo_codegen.h"

// Global variables for data exchange
double a_f_u;
double a_f_y;
bool call_a_f;

// Object from SOA_demo_codegen class
SOA_demo_codegen soa_obj;

//Instantiation of Server service
SOA_demo_codegenaT new_aT_ServerService(soa_obj);

// Adapter to SWC Initialize function

// Void-void function main_step
void main_step() {
    // Exchange data with step function

    if (call_a_f) {
        new_aT_ServerService.f(a_f_u, &a_f_y);
    }
    
}