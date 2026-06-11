#ifndef HPS_FPGA_COMM_H
#define HPS_FPGA_COMM_H

#include <stdint.h>
#include "shared_protocol.h"

/* Map the shared region, retrying until it succeeds (daemon-safe). */
int hps_fpga_init(uint32_t phys_addr, uint32_t size);
volatile shared_audio_mem_t *hps_fpga_get_shared(void);
void hps_fpga_close(void);

#endif /* HPS_FPGA_COMM_H */