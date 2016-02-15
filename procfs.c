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
#define CMD_LINE 2000
#define FD_INFO 4000
#define STATUS 6000

void pushDirentToBuf(char* dirName, int inum, char* buf, int * numDirsInBuf);
int mockPROCfld(struct inode *ip, char * buf);
int mockPIDfld(struct inode *ip, char * buf);
int mockCmdLine(struct inode *ip, char * buf);

extern struct {
  struct spinlock lock;
  struct proc proc[NPROC];
} ptable;

int 
procfsisdir(struct inode *ip) {
  return ip->type == T_DEV && ip->major == PROCFS;
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
  else if (ip->minor == 1) { // minor == 1 determines that we want to read from fld /PROC/<PID>
    size = mockPIDfld(ip, buf);
  }
  else if (ip->minor == 2) { // minor == 2 determines that we want to read from file /PROC/<PID>/<file>
    int file = (ip->inum/1000)*1000;
    switch (file) {
      case CMD_LINE:
	size = mockCmdLine(ip, buf);
	break;
      case FD_INFO:
	break;
      case STATUS:
	break;
    }
  }
  
  if (off < size) {
      int remain = size - off;
      remain = remain < n ? remain : n;
      memmove(dst, buf + off, remain);
      //cprintf("dst is: %s\n", dst);
      return remain;
  }
  //cprintf("buf is: %s BAD\n", buf);
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
    
    if (p->state != UNUSED) {    
      pushDirentToBuf("cmdline", ip->inum + CMD_LINE, buf, &count);
      pushDirentToBuf("cwd", p->cwd->inum, buf, &count);
      pushDirentToBuf("exe", p->exe->inum, buf, &count);
      pushDirentToBuf("fdinfo", ip->inum + FD_INFO, buf, &count);   
      pushDirentToBuf("status", ip->inum + STATUS, buf, &count);    
    }
    
    return count*(sizeof(struct dirent)); 
}

int
mockCmdLine(struct inode *ip, char * buf) {
    struct proc *p = &ptable.proc[(ip->inum - CMD_LINE) - NINODES];
    int sz = strlen(p->cmdline);
    memmove(buf, p->cmdline, sz);
    return sz;
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