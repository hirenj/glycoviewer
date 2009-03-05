#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

long fileSize(char* filename)
{
  struct stat stbuf;
  stat(filename, &stbuf);
  return stbuf.st_size;
}

int main(int argc, char *argv[])
{
  FILE *fp;
  char *in_line;
  char *data;

  int struct_id;
  char *seq;

  unsigned long long int bitfield1 = 0;
  unsigned long long int bitfield2 = 0;
  unsigned long long int bitfield3 = 0;

  unsigned long long int test1 = 0;
  unsigned long long int test2 = 0;
  unsigned long long int test3 = 0;

  int nbytes = 1024;
  int count;  
  int counter;
  int current_struct_id = -1;
  int current_struct_count = 0;
  long filesize = 0;
  unsigned long long int bytes_read = 0;

  filesize = fileSize(argv[1]);

  if((fp=fopen(argv[1],"r")) == NULL) {
    printf("Cannot open file.\n");
    exit(1);
  }
  
  sscanf(argv[2],"%llx",&test1);
  sscanf(argv[3],"%llx",&test2);
  sscanf(argv[4],"%llx",&test3);


  in_line = (char *) malloc (nbytes + 1);
  seq = (char *) malloc (nbytes + 1);

  counter = 0;
  while(fgets(in_line, nbytes, fp)) {
	bytes_read += strlen(in_line);
	
	data = strtok(in_line,"#");
	struct_id = atoi(data);
	data = strtok(NULL,"#");
	strlcpy(seq,data,nbytes);
	data = strtok(NULL,"#");
	count = atoi(data);
	data = strtok(NULL,"#");
	sscanf(data,"%llu",&bitfield1);
	data = strtok(NULL,"#");
	sscanf(data,"%llu",&bitfield2);
	data = strtok(NULL,"#");
	sscanf(data,"%llu",&bitfield3);
	
//	fprintf(stdout, "%llx,%llx,%llx against %llx,%llx,%llx\n",bitfield1,bitfield2,bitfield3,test1,test2,test3);
	
    if (((bitfield1 & test1) > 0) ||
       ((bitfield2 & test2) > 0) ||
       ((bitfield3 & test3) > 0)) {
//		fprintf(stdout,"PASS (%llx,%llx,%llx)\n",(bitfield1 & test1),(bitfield2 & test2),(bitfield3 & test3));
	    if (current_struct_id == struct_id) {
			current_struct_count++;
			if (count == current_struct_count) {
				fprintf(stdout, "%d#%s#%d\n",struct_id,seq,count);
   			}
		} else {
			current_struct_id = struct_id;
			current_struct_count = 1;
		}
	}
	fprintf(stderr,"%llu/%llu\n",bytes_read,filesize);
  }
  fclose(fp);
  return 0;
}
