#include<stdio.h>
#include<unistd.h>
#include<fcntl.h>

#define bufsize 1024

int main()
{
    char buffer[bufsize],so[100],dt[100];
    
    printf("Enter source filename:");
    scanf("%s",so);
    printf("enter destination file name:");
    scanf("%s",dt);
    
    int s=open(so,O_RDONLY);
    int d=open(dt,O_WRONLY | O_CREAT | O_TRUNC,0644);
    
    ssize_t n;
    if((n=read(s,buffer,bufsize))>0){
        write(d,buffer,n);
    }
    
    
    close(s);
    close(d);
    
    printf("file copied successfully");
    
    return 0;
    
    
}