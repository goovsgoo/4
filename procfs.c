#include "types.h"
#include "stat.h"
#include "defs.h"
#include "param.h"
#include "traps.h"
#include "spinlock.h"
#include "fs.h"
#include "file.h"
#include "memlayout.h"
#include "mmu.h"
#include "proc.h"
#include "x86.h"

#define NINODES 200
#define CMD_LINE 200
#define FD_INFO 400
#define STATUS 600

void pushDirentToBuf(char* dirName, int inum, char* buf, int * numDirsInBuf);
int mockPROCfld(struct inode *ip, char * buf);
int mockPIDfld(struct inode *ip, char * buf);

extern struct {
  struct spinlock lock;
  struct proc proc[NPROC];
} ptable;

int 
procfsisdir(struct inode *ip) {
  return ip->type == T_DIR;
}

void 
procfsiread(struct inode* dp, struct inode *ip) {
  ip->flags |= I_VALID;
  ip->type = T_DEV;
  ip->ref++;
  ip->size = 0;
  ip->major = PROCFS;
  if (ip->inum > dp->inum) {
    ip->minor = dp->minor + 1;
  }
  else if (ip->inum < dp->inum) {
    ip->minor = dp->minor - 1;
  }
  else {
    ip->minor = dp->minor;
  }
  
}

int
procfsread(struct inode *ip, char *dst, int off, int n) {
  char buf[BSIZE];
  int size = 0;
  
  if (ip->minor == 0) { // minor == 0 determines that we want to read from fld /PROC
    size = mockPROCfld(ip, buf);
  }
  else if (ip->minor == 1) {
    
  }
  else if (ip->minor == 2) {
    
  }
  
  if (off < size) {
      int remain = size - off;
      remain = remain < n ? remain : n;
      memmove(dst, buf + off, remain);
      return remain;
  }
  return 0;
}

int
procfswrite(struct inode *ip, char *buf, int n)
{
  panic("You shall not write");
  return 0;
}

void
procfsinit(void)
{
  devsw[PROCFS].isdir = procfsisdir;
  devsw[PROCFS].iread = procfsiread;
  devsw[PROCFS].write = procfswrite;
  devsw[PROCFS].read = procfsread;
}

/**
 * mocks the /PROC folder - Creates the file entries and push them to the buffer.
 * returns the size of the buffer
 */
int
mockPROCfld(struct inode *ip, char *buf) {
    int count = 0;
    pushDirentToBuf(".", ip->inum, buf, &count);
    pushDirentToBuf("..", ROOTINO, buf, &count);
    
    struct proc* p;
    int i = 0;  
    char sPid[BSIZE];
    
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != UNUSED)
      {	
	itoa(p->pid,sPid);
	pushDirentToBuf(sPid, NINODES + i, buf, &count);
      }
      i++;
    }
    return count * sizeof(struct dirent);
}

int
mockPIDfld(struct inode *ip, char * buf) {
    struct proc * p = &ptable.proc[ip->inum - NINODES];
    int count = 0;
    pushDirentToBuf(".", ip->inum, buf, &count);
    pushDirentToBuf("..", ROOTINO, buf, &count);
    
    if (p->state == UNUSED) {
      return count*(struct dirent);
    }
    
    pushDirentToBuf("cmdline", ip->inum + CMD_LINE, buf, &count);
    pushDirentToBuf("cwd", p->cwd->inum, buf, &count);
    pushDirentToBuf("exe", p->exe->inum, buf, &count);
    pushDirentToBuf("cmdline", ip->inum + CMD_LINE, buf, &count);   
    pushDirentToBuf("cmdline", ip->inum + CMD_LINE, buf, &count);
}

/**
 * gets directory name and inum, buffer, and a pointer to number of directories already in the buffer
 * push directory entry to buffer (as struct dirent), increase numDirsInBuf by 1 
 */
void pushDirentToBuf(char* dirName, int inum, char* buf, int* numDirsInBuf) {
  struct dirent dir;
  dir.inum = inum;
  memmove(dir.name, dirName, strlen(dirName)+1);
  memmove(buf + (*numDirsInBuf)*sizeof(dir), (char*)&dir, sizeof(dir));
  (*numDirsInBuf)++;
}