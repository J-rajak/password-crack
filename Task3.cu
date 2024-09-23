//importing all the header files
#include <stdio.h>
#include <stdlib.h>
#include <time.h>


//compile with nvcc Task3.cu -o Task3
//./Task3 Passpassword twouppercaseandtwodigits
//__global__ --> GPU function which can be launched by many blocks and threads, defination of kernel which is launched on the GPU whenever called from the CPU
//__device__ --> GPU function or variables
//__host__ --> CPU function or variables

//Function called on GPU executed in GPU for password encryption on the cmd argument
__device__ char* CudaCrypt(char* Plainpassword){

       //typecasting for memory allocation on GPU for encrypt password
	char * Freshpassword = (char *) malloc(sizeof(char) * 11);
	
        //limiting the encrypt password to display till 10th index and terminating it after when it reaches the 11th index
	Freshpassword[0] = Plainpassword[0] + 2;  
	Freshpassword[1] = Plainpassword[0] - 2;
	Freshpassword[2] = Plainpassword[0] + 1;  
	Freshpassword[3] = Plainpassword[1] + 3;
	Freshpassword[4] = Plainpassword[1] - 3;
	Freshpassword[5] = Plainpassword[1] - 1;
	Freshpassword[6] = Plainpassword[2] + 2;
	Freshpassword[7] = Plainpassword[2] - 2;
	Freshpassword[8] = Plainpassword[3] + 4;
	Freshpassword[9] = Plainpassword[3] - 4;
	Freshpassword[10] = '\0';
//loop for checking password character by character and number by number
	for(int i =0; i<10; i++){
		if(i >= 0 && i < 6){ //checking all upper case letter limits
		//ASCII value of A-Z = 65-90
		//ASCII value of 0-9 = 48-57
			if(Freshpassword[i] > 90){
				Freshpassword[i] = (Freshpassword[i] - 90) + 65;
			}else if(Freshpassword[i] < 65){
				Freshpassword[i] = (65 - Freshpassword[i]) + 65;
			}
		}else{ //checking number limits
			if(Freshpassword[i] > 57){
				Freshpassword[i] = (Freshpassword[i] - 57) + 48;
			}else if(Freshpassword[i] < 48){
				Freshpassword[i] = (48 - Freshpassword[i]) + 48;
			}
		}
	}
	return Freshpassword; //encrypted password is returned
}
//function for comparing two strings runs on GPU which stores value of the password and stores in encPassword
__device__ int compareTwoString(char* StringOne, char* StringTwo){
	
    while(*StringOne)
    {
        //two strings being compared
        if (*StringOne != *StringTwo)
            break;
 
        //Changing Pointer location
        StringOne++;
        StringTwo++;
    }
 
    // if the two strings matches it returns 0 
    return *(const unsigned char*)StringOne - *(const unsigned char*)StringTwo;
}

//function called on the CPU which is executed on the GPU here the user given password is hashed
__global__ void crack(char * Alpha, char * Num, char * Plainpassword){

char genFreshPass[4];
//Adding test passwords to genFreshPass
genFreshPass[0] = Alpha[blockIdx.x];
genFreshPass[1] = Alpha[blockIdx.y];

genFreshPass[2] = Num[threadIdx.x];
genFreshPass[3] = Num[threadIdx.y];

//Plain Password being encrypted
char *encPassword = CudaCrypt(Plainpassword);
	
	//Comparing encrypted genFreshPass with encPassword
	if(compareTwoString(CudaCrypt(genFreshPass),encPassword) == 0){
		printf("Your to be cracked password is : %s = %s\n",genFreshPass, Plainpassword);
		printf("Your cracked password is : %s = %s\n", encPassword);

	}
}

int time_difference(struct timespec *initial, struct timespec *final, long long int *Diff){
  long long int ds =  final->tv_sec - initial->tv_sec; 
  long long int dn =  final->tv_nsec - initial->tv_nsec; 

  if(dn < 0 ) {
    ds--;
    dn += 1000000000; 
  } 
  *Diff = ds * 1000000000 + dn;
  return !(*Diff > 0);
}


//Main function which is executed on the CPU
int main(int argc, char ** argv){
//storing all the 26 alphabets in the variable cpuAlpha
char CPUAlpha[26] = {'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'};
//storing the 10 numbers in the variable name cpuNum
char CPUNum[10] = {'0','1','2','3','4','5','6','7','8','9'};

char * GPUAlpha;
// allocating GPU memory
cudaMalloc( (void**) &GPUAlpha, sizeof(char) * 26); 
// copy back the result array of the alphabeth to the CPU
cudaMemcpy(GPUAlpha, CPUAlpha, sizeof(char) * 26, cudaMemcpyHostToDevice);

char * GPUNum;
// allocating GPU memory
cudaMalloc( (void**) &GPUNum, sizeof(char) * 10); 
// copy back the result array of the number to the CPU
cudaMemcpy(GPUNum, CPUNum, sizeof(char) * 10, cudaMemcpyHostToDevice);

char * PASSW;
// allocating GPU memory
cudaMalloc( (void**) &PASSW, sizeof(char) * 26); 
// copy back the result array of the result password to the CPU
cudaMemcpy(PASSW, argv[1], sizeof(char) * 26, cudaMemcpyHostToDevice);

	struct timespec initial, final;
	long long int time_taken;
	
//Starting to monitor the time duration 
	clock_gettime(CLOCK_MONOTONIC, &initial);
	// launching the kernel
	crack<<< dim3(26,26,1), dim3(10,10,1) >>>( GPUAlpha, GPUNum, PASSW);
	cudaDeviceSynchronize();

//Ending the duration of the program
	clock_gettime(CLOCK_MONOTONIC, &final);
	
//Calculating the duration of the time for exection of the program
	time_difference(&initial, &final, &time_taken);
	
//Printing the duration taken for execution of the program
	printf("Time taken was %lldns or %0.9lfs\n", time_taken,
                                         (time_taken/1.0e9));

return 0;
}


	


