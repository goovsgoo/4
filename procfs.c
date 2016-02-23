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
int mockFdInfo(struct inode *ip, char *buf);
int mockFdStatus(struct inode *ip, char * buf);
int mockStatusInfo(struct inode *ip, char * buf);

extern struct {
  struct spinlock lock;
  struct proc proc[NPROC];
} ptable;

char * fd_enums[3] = {"FD_NONE", "FD_PIPE", "FD_INODE"};
char * proc_run_state[6] = { "UNUSED", "EMBRYO", "SLEEPING", "RUNNABLE", "RUNNING", "ZOMBIE" };
  
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
	size = mockFdInfo(ip, buf);
	break;
      case STATUS:
	size = mockStatusInfo(ip, buf);
	break;
    }
  }
  else if (ip->minor >= 3) {  
    //cprintf("HEELO!\n");
    size = mockFdStatus(ip, buf);
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

int 
mockStatusInfo(struct inode *ip, char * buf) {
    struct proc *p = &ptable.proc[(ip->inum - STATUS) - NINODES];
    
    int sz = 0;
    memmove(buf, "run state: ", strlen("run state: ") + 1);
    sz += strlen("run state: ") + 1;
    
    char * str = proc_run_state[p->state];  
    memmove(buf + sz, str, strlen(str) + 1);
    sz += strlen(str) + 1;
    
    memmove(buf + sz, " memory usage: ", strlen(" memory usage: ") + 1);
    sz += strlen(" memory usage: ") + 1;
    
    char proc_sz[6];
    itoa((int)p->sz, proc_sz);
    memmove(buf + sz, proc_sz, strlen(proc_sz) + 1);
    sz += strlen(proc_sz) + 1;
    
    memmove(buf + sz, "\n", strlen("\n") + 1);
    sz += strlen("\n") + 1;
    
    return sz;
}

int
mockFdInfo(struct inode *ip, char *buf) {
    int count = 0;
    pushDirentToBuf(".", ip->inum, buf, &count);
    pushDirentToBuf("..", ROOTINO, buf, &count);
    
    int procIndex = ip->inum - FD_INFO - NINODES;
    //cprintf("proc index is: %d\n", procIndex);
    struct proc *p = &ptable.proc[procIndex];
    int i = 0;  
    char sFD[2];
    
    for (i = 0; i < NOFILE; i++){
      //cprintf("fd is %d, file %d, for proc %d\n", i, p->ofile[i], p->pid);
      if(p->ofile[i] && p->ofile[i]->type != FD_NONE)
      {		
	itoa(i, sFD);	
	int inum = FD_INFO + NINODES + NPROC + NOFILE * procIndex + i; // 4000 + 200 + 64 + 16*procIndex + i
	pushDirentToBuf(sFD, inum, buf, &count);
      }
    }
    return count * sizeof(struct dirent);
}


int
mockFdStatus(struct inode *ip, char * buf) {
  
    // NOFILE * procIndex + fdNum = inum - FD_INFO - NINODES - NPROC
    int procIndex = (ip->inum - FD_INFO - NINODES - NPROC) / NOFILE;
    int fdNum = (ip->inum - FD_INFO - NINODES - NPROC) % NOFILE;
    
    struct proc *p = &ptable.proc[procIndex];
    struct file *fd = p->ofile[fdNum];
    
    int sz = 0;
    memmove(buf, "type: ", strlen("type: ") + 1);
    sz += strlen("type: ") + 1;
    
    memmove(buf + sz,fd_enums[fd->type], strlen(fd_enums[fd->type]) + 1);
    sz += strlen(fd_enums[fd->type]) + 1;
    
    memmove(buf + sz, "\noffset: ", strlen("\noffset: ") + 1);
    sz += strlen("\noffset: ") + 1;
    
    char off[100];
    itoa((int)fd->off, off);
    memmove(buf + sz, off, strlen(off) + 1);
    sz += strlen(off) + 1;
    
    memmove(buf + sz, "\nflags: ", strlen("\nflags: ") + 1);
    sz += strlen("\nflags: ") + 1;
        
    memmove(buf + sz, "readable: ", strlen(" readable: ") + 1);
    sz += strlen(" readable: ") + 1;
    
    char read[1];
    itoa(fd->readable, read);
    memmove(buf + sz, read, strlen(read) + 1);
    sz += strlen(read) + 1;
    
    memmove(buf + sz, " writable: ", strlen(" writable: ") + 1);
    sz += strlen(" writable: ") + 1;
    
    char write[1];
    itoa(fd->writable, write);
    memmove(buf + sz, write, strlen(write) + 1);
    sz += strlen(write) + 1;
    
    memmove(buf + sz, "\n", strlen("\n") + 1);
    sz += strlen("\n") + 1;
    
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