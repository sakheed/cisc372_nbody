//Sakhee Desai and Aman Singh
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "vector.h"
#include "config.h"

__global__
void computePairwiseAccels(v3 *acceleration, v3 *position, double *mass){
	int k;
	v3 dist;

	int i = blockIdx.x*blockDim.x + threadIdx.x;
   	int j = blockIdx.y*blockDim.y + threadIdx.y;
	
	double magnitude, magA, mag_square;

	if(i < NUMENTITIES && j < NUMENTITIES){
			if (i==j) {
				FILL_VECTOR(acceleration[i*NUMENTITIES+j],0,0,0);
			}
			else{
				for (k=0;k<3;k++) {
					dist[k]= position[i][k]- position[j][k];
				}
				mag_square = dist[0]*dist[0]+dist[1]*dist[1]+dist[2]*dist[2];
				magnitude = sqrt(mag_square);
				magA = -1 * GRAV_CONSTANT * mass[j]/mag_square;
				FILL_VECTOR(acceleration[i*NUMENTITIES +j],
						magA*dist[0]/magnitude,	
						magA*dist[1]/magnitude,
						magA*dist[2]/magnitude);
			}
	}
}

__global__
void sumRowsandUpdate(v3* acceleration, v3* velocity, v3* position, double* mass){
	int i = blockIdx.x*blockDim.x + threadIdx.x;
        int j,k;
	v3 total_acceleration = {0,0,0};	
	if (i<NUMENTITIES){
		for (j=0;j<NUMENTITIES;j++){
			for (k=0;k<3;k++){
				total_acceleration[k]+=acceleration[i*NUMENTITIES + j][k];
			}
		}
		 for (k=0;k<3;k++){
                  	velocity[i][k] += total_acceleration[k]*INTERVAL;
                  	position[i][k] += velocity[i][k]*INTERVAL;
          	}
	}
}

//compute: Updates the positions and locations of the objects in the system based on gravity.
//Parameters: None
//Returns: None
//Side Effect: Modifies the hPos and hVel arrays with the new positions and accelerations after 1 INTERVAL

void compute(){
	new_dim szBlk(16,16);
	new_dim nBlk((NUMENTITIES*NUMENTITIES +szBlk.x-1)/szBlk.x, (NUMENTITIES*NUMENTITIES +szBlk.y-1)/szBlk.y);
	int new_BS = 256;	
	int new_num_blocks = (NUMENTITIES*NUMENTITIES + newBS - 1)/newBS;

	computePairwiseAccels<<<nBlk, szBlk>>>(acceleration, position, new_mass);
	sumRowsandUpdate<<<new_num_blocks, newBS>>>(acceleration, velocity, position, new_mass);	
	
}
