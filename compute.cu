//Sakhee Desai and Aman Singh
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "vector.h"
#include "config.h"

__global__ void acceleration_computation(v3 *acceleration, v3 *position, double *mass){
	int k;
	int l;
	v3 dist;

	int i = blockIdx.x*blockDim.x + threadIdx.x;
   	int j = blockIdx.y*blockDim.y + threadIdx.y;
	
	double magnitude;
	double magA;
	double mag_square;

	if(i < NUMENTITIES && j < NUMENTITIES){
			if (i==j) {
				FILL_VECTOR(acceleration[NUMENTITIES * i + j], 0, 0, 0);
			} else {
				for (k = 0; k < 3; k++) dist[k] = position[i][k] - position[j][k];
				for (l = 0; l < 3; l++) mag_square += dist[l] * dist[l];

				magnitude = sqrt(mag_square);
				magA = GRAV_CONSTANT * (mass[j] / mag_square) * -1;

				FILL_VECTOR(acceleration[NUMENTITIES * i + j],
						dist[0] * magA / magnitude,	
						dist[1] * magA / magnitude,
						dist[2] * magA / magnitude);
			}
	}
}

__global__ void row_summation(v3* acceleration, v3* velocity, v3* position, double* mass){
	int i = threadIdx.x + (blockIdx.x * blockDim.x);
        int j;
	int k;

	v3 total_acceleration = {0, 0, 0};

	if (i < NUMENTITIES) {
		for (j = 0; j < NUMENTITIES; j++) {
			for (k = 0; k < 3; k++) total_acceleration[k] += acceleration[j + NUMENTITIES * i][k];
		}
		for (k = 0; k < 3; k++) {
                  	velocity[i][k] += INTERVAL * total_acceleration[k];
                  	position[i][k] += INTERVAL * velocity[i][k];
          	}
	}
}

//compute: Updates the positions and locations of the objects in the system based on gravity.
//Parameters: None
//Returns: None
//Side Effect: Modifies the hPos and hVel arrays with the new positions and accelerations after 1 INTERVAL

void compute(){
	new_dim szBlk(16, 16);
	int new_BS = 256;
	new_dim nBlk((NUMENTITIES*NUMENTITIES + szBlk.x - 1) / szBlk.x, (NUMENTITIES * NUMENTITIES +szBlk.y - 1) / szBlk.y);
	int new_num_blocks = (NUMENTITIES*NUMENTITIES + newBS - 1) / newBS;

	acceleration_computation<<<nBlk, szBlk>>>(acceleration, position, new_mass);
	row_summation<<<new_num_blocks, newBS>>>(acceleration, velocity, position, new_mass);	
	
}
