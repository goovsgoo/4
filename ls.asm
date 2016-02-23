
_ls:     file format elf32-i386


Disassembly of section .text:

00000000 <fmtname>:
#include "user.h"
#include "fs.h"

char*
fmtname(char *path)
{
   0:	55                   	push   %ebp
   1:	89 e5                	mov    %esp,%ebp
   3:	53                   	push   %ebx
   4:	83 ec 24             	sub    $0x24,%esp
  static char buf[DIRSIZ+1];
  char *p;
  
  // Find first character after last slash.
  for(p=path+strlen(path); p >= path && *p != '/'; p--)
   7:	8b 45 08             	mov    0x8(%ebp),%eax
   a:	89 04 24             	mov    %eax,(%esp)
   d:	e8 e3 03 00 00       	call   3f5 <strlen>
  12:	8b 55 08             	mov    0x8(%ebp),%edx
  15:	01 d0                	add    %edx,%eax
  17:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1a:	eb 04                	jmp    20 <fmtname+0x20>
  1c:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
  20:	8b 45 f4             	mov    -0xc(%ebp),%eax
  23:	3b 45 08             	cmp    0x8(%ebp),%eax
  26:	72 0a                	jb     32 <fmtname+0x32>
  28:	8b 45 f4             	mov    -0xc(%ebp),%eax
  2b:	0f b6 00             	movzbl (%eax),%eax
  2e:	3c 2f                	cmp    $0x2f,%al
  30:	75 ea                	jne    1c <fmtname+0x1c>
    ;
  p++;
  32:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  
  // Return blank-padded name.
  if(strlen(p) >= DIRSIZ)
  36:	8b 45 f4             	mov    -0xc(%ebp),%eax
  39:	89 04 24             	mov    %eax,(%esp)
  3c:	e8 b4 03 00 00       	call   3f5 <strlen>
  41:	83 f8 0d             	cmp    $0xd,%eax
  44:	76 05                	jbe    4b <fmtname+0x4b>
    return p;
  46:	8b 45 f4             	mov    -0xc(%ebp),%eax
  49:	eb 5f                	jmp    aa <fmtname+0xaa>
  memmove(buf, p, strlen(p));
  4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  4e:	89 04 24             	mov    %eax,(%esp)
  51:	e8 9f 03 00 00       	call   3f5 <strlen>
  56:	89 44 24 08          	mov    %eax,0x8(%esp)
  5a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  5d:	89 44 24 04          	mov    %eax,0x4(%esp)
  61:	c7 04 24 14 0e 00 00 	movl   $0xe14,(%esp)
  68:	e8 17 05 00 00       	call   584 <memmove>
  memset(buf+strlen(p), ' ', DIRSIZ-strlen(p));
  6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  70:	89 04 24             	mov    %eax,(%esp)
  73:	e8 7d 03 00 00       	call   3f5 <strlen>
  78:	ba 0e 00 00 00       	mov    $0xe,%edx
  7d:	89 d3                	mov    %edx,%ebx
  7f:	29 c3                	sub    %eax,%ebx
  81:	8b 45 f4             	mov    -0xc(%ebp),%eax
  84:	89 04 24             	mov    %eax,(%esp)
  87:	e8 69 03 00 00       	call   3f5 <strlen>
  8c:	05 14 0e 00 00       	add    $0xe14,%eax
  91:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  95:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
  9c:	00 
  9d:	89 04 24             	mov    %eax,(%esp)
  a0:	e8 77 03 00 00       	call   41c <memset>
  return buf;
  a5:	b8 14 0e 00 00       	mov    $0xe14,%eax
}
  aa:	83 c4 24             	add    $0x24,%esp
  ad:	5b                   	pop    %ebx
  ae:	5d                   	pop    %ebp
  af:	c3                   	ret    

000000b0 <ls>:

void
ls(char *path)
{
  b0:	55                   	push   %ebp
  b1:	89 e5                	mov    %esp,%ebp
  b3:	57                   	push   %edi
  b4:	56                   	push   %esi
  b5:	53                   	push   %ebx
  b6:	81 ec 5c 02 00 00    	sub    $0x25c,%esp
  char buf[512], *p;
  int fd;
  struct dirent de;
  struct stat st;
  
  if((fd = open(path, 0)) < 0){
  bc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  c3:	00 
  c4:	8b 45 08             	mov    0x8(%ebp),%eax
  c7:	89 04 24             	mov    %eax,(%esp)
  ca:	e8 3a 05 00 00       	call   609 <open>
  cf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  d2:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  d6:	79 20                	jns    f8 <ls+0x48>
    printf(2, "ls: cannot open %s\n", path);
  d8:	8b 45 08             	mov    0x8(%ebp),%eax
  db:	89 44 24 08          	mov    %eax,0x8(%esp)
  df:	c7 44 24 04 15 0b 00 	movl   $0xb15,0x4(%esp)
  e6:	00 
  e7:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
  ee:	e8 56 06 00 00       	call   749 <printf>
    return;
  f3:	e9 07 02 00 00       	jmp    2ff <ls+0x24f>
  }
  
  if(fstat(fd, &st) < 0){
  f8:	8d 85 bc fd ff ff    	lea    -0x244(%ebp),%eax
  fe:	89 44 24 04          	mov    %eax,0x4(%esp)
 102:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 105:	89 04 24             	mov    %eax,(%esp)
 108:	e8 14 05 00 00       	call   621 <fstat>
 10d:	85 c0                	test   %eax,%eax
 10f:	79 2b                	jns    13c <ls+0x8c>
    printf(2, "ls: cannot stat %s\n", path);
 111:	8b 45 08             	mov    0x8(%ebp),%eax
 114:	89 44 24 08          	mov    %eax,0x8(%esp)
 118:	c7 44 24 04 29 0b 00 	movl   $0xb29,0x4(%esp)
 11f:	00 
 120:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
 127:	e8 1d 06 00 00       	call   749 <printf>
    close(fd);
 12c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 12f:	89 04 24             	mov    %eax,(%esp)
 132:	e8 ba 04 00 00       	call   5f1 <close>
    return;
 137:	e9 c3 01 00 00       	jmp    2ff <ls+0x24f>
  }
  
  switch(st.type){
 13c:	0f b7 85 bc fd ff ff 	movzwl -0x244(%ebp),%eax
 143:	98                   	cwtl   
 144:	83 f8 02             	cmp    $0x2,%eax
 147:	74 0f                	je     158 <ls+0xa8>
 149:	83 f8 03             	cmp    $0x3,%eax
 14c:	74 54                	je     1a2 <ls+0xf2>
 14e:	83 f8 01             	cmp    $0x1,%eax
 151:	74 4f                	je     1a2 <ls+0xf2>
 153:	e9 9c 01 00 00       	jmp    2f4 <ls+0x244>
  case T_FILE:
    printf(1, "%s %d %d %d\n", fmtname(path), st.type, st.ino, st.size);
 158:	8b bd cc fd ff ff    	mov    -0x234(%ebp),%edi
 15e:	8b b5 c4 fd ff ff    	mov    -0x23c(%ebp),%esi
 164:	0f b7 85 bc fd ff ff 	movzwl -0x244(%ebp),%eax
 16b:	0f bf d8             	movswl %ax,%ebx
 16e:	8b 45 08             	mov    0x8(%ebp),%eax
 171:	89 04 24             	mov    %eax,(%esp)
 174:	e8 87 fe ff ff       	call   0 <fmtname>
 179:	89 7c 24 14          	mov    %edi,0x14(%esp)
 17d:	89 74 24 10          	mov    %esi,0x10(%esp)
 181:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
 185:	89 44 24 08          	mov    %eax,0x8(%esp)
 189:	c7 44 24 04 3d 0b 00 	movl   $0xb3d,0x4(%esp)
 190:	00 
 191:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
 198:	e8 ac 05 00 00       	call   749 <printf>
    break;
 19d:	e9 52 01 00 00       	jmp    2f4 <ls+0x244>

  case T_DEV:
  case T_DIR:
	if(strlen(path) + 1 + DIRSIZ + 1 > sizeof buf){
 1a2:	8b 45 08             	mov    0x8(%ebp),%eax
 1a5:	89 04 24             	mov    %eax,(%esp)
 1a8:	e8 48 02 00 00       	call   3f5 <strlen>
 1ad:	83 c0 10             	add    $0x10,%eax
 1b0:	3d 00 02 00 00       	cmp    $0x200,%eax
 1b5:	76 19                	jbe    1d0 <ls+0x120>
      printf(1, "ls: path too long\n");
 1b7:	c7 44 24 04 4a 0b 00 	movl   $0xb4a,0x4(%esp)
 1be:	00 
 1bf:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
 1c6:	e8 7e 05 00 00       	call   749 <printf>
      break;
 1cb:	e9 24 01 00 00       	jmp    2f4 <ls+0x244>
    }
    strcpy(buf, path);
 1d0:	8b 45 08             	mov    0x8(%ebp),%eax
 1d3:	89 44 24 04          	mov    %eax,0x4(%esp)
 1d7:	8d 85 e0 fd ff ff    	lea    -0x220(%ebp),%eax
 1dd:	89 04 24             	mov    %eax,(%esp)
 1e0:	e8 a1 01 00 00       	call   386 <strcpy>
    p = buf+strlen(buf);
 1e5:	8d 85 e0 fd ff ff    	lea    -0x220(%ebp),%eax
 1eb:	89 04 24             	mov    %eax,(%esp)
 1ee:	e8 02 02 00 00       	call   3f5 <strlen>
 1f3:	8d 95 e0 fd ff ff    	lea    -0x220(%ebp),%edx
 1f9:	01 d0                	add    %edx,%eax
 1fb:	89 45 e0             	mov    %eax,-0x20(%ebp)
    *p++ = '/';
 1fe:	8b 45 e0             	mov    -0x20(%ebp),%eax
 201:	8d 50 01             	lea    0x1(%eax),%edx
 204:	89 55 e0             	mov    %edx,-0x20(%ebp)
 207:	c6 00 2f             	movb   $0x2f,(%eax)
    while(read(fd, &de, sizeof(de)) == sizeof(de)){
 20a:	e9 be 00 00 00       	jmp    2cd <ls+0x21d>
      if(de.inum == 0)
 20f:	0f b7 85 d0 fd ff ff 	movzwl -0x230(%ebp),%eax
 216:	66 85 c0             	test   %ax,%ax
 219:	75 05                	jne    220 <ls+0x170>
        continue;
 21b:	e9 ad 00 00 00       	jmp    2cd <ls+0x21d>
      memmove(p, de.name, DIRSIZ);
 220:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
 227:	00 
 228:	8d 85 d0 fd ff ff    	lea    -0x230(%ebp),%eax
 22e:	83 c0 02             	add    $0x2,%eax
 231:	89 44 24 04          	mov    %eax,0x4(%esp)
 235:	8b 45 e0             	mov    -0x20(%ebp),%eax
 238:	89 04 24             	mov    %eax,(%esp)
 23b:	e8 44 03 00 00       	call   584 <memmove>
      p[DIRSIZ] = 0;
 240:	8b 45 e0             	mov    -0x20(%ebp),%eax
 243:	83 c0 0e             	add    $0xe,%eax
 246:	c6 00 00             	movb   $0x0,(%eax)
      if(stat(buf, &st) < 0){
 249:	8d 85 bc fd ff ff    	lea    -0x244(%ebp),%eax
 24f:	89 44 24 04          	mov    %eax,0x4(%esp)
 253:	8d 85 e0 fd ff ff    	lea    -0x220(%ebp),%eax
 259:	89 04 24             	mov    %eax,(%esp)
 25c:	e8 88 02 00 00       	call   4e9 <stat>
 261:	85 c0                	test   %eax,%eax
 263:	79 20                	jns    285 <ls+0x1d5>
        printf(1, "ls: cannot stat %s\n", buf);
 265:	8d 85 e0 fd ff ff    	lea    -0x220(%ebp),%eax
 26b:	89 44 24 08          	mov    %eax,0x8(%esp)
 26f:	c7 44 24 04 29 0b 00 	movl   $0xb29,0x4(%esp)
 276:	00 
 277:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
 27e:	e8 c6 04 00 00       	call   749 <printf>
        continue;
 283:	eb 48                	jmp    2cd <ls+0x21d>
      }
      printf(1, "%s %d %d %d\n", fmtname(buf), st.type, st.ino, st.size);
 285:	8b bd cc fd ff ff    	mov    -0x234(%ebp),%edi
 28b:	8b b5 c4 fd ff ff    	mov    -0x23c(%ebp),%esi
 291:	0f b7 85 bc fd ff ff 	movzwl -0x244(%ebp),%eax
 298:	0f bf d8             	movswl %ax,%ebx
 29b:	8d 85 e0 fd ff ff    	lea    -0x220(%ebp),%eax
 2a1:	89 04 24             	mov    %eax,(%esp)
 2a4:	e8 57 fd ff ff       	call   0 <fmtname>
 2a9:	89 7c 24 14          	mov    %edi,0x14(%esp)
 2ad:	89 74 24 10          	mov    %esi,0x10(%esp)
 2b1:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
 2b5:	89 44 24 08          	mov    %eax,0x8(%esp)
 2b9:	c7 44 24 04 3d 0b 00 	movl   $0xb3d,0x4(%esp)
 2c0:	00 
 2c1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
 2c8:	e8 7c 04 00 00       	call   749 <printf>
      break;
    }
    strcpy(buf, path);
    p = buf+strlen(buf);
    *p++ = '/';
    while(read(fd, &de, sizeof(de)) == sizeof(de)){
 2cd:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
 2d4:	00 
 2d5:	8d 85 d0 fd ff ff    	lea    -0x230(%ebp),%eax
 2db:	89 44 24 04          	mov    %eax,0x4(%esp)
 2df:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 2e2:	89 04 24             	mov    %eax,(%esp)
 2e5:	e8 f7 02 00 00       	call   5e1 <read>
 2ea:	83 f8 10             	cmp    $0x10,%eax
 2ed:	0f 84 1c ff ff ff    	je     20f <ls+0x15f>
        printf(1, "ls: cannot stat %s\n", buf);
        continue;
      }
      printf(1, "%s %d %d %d\n", fmtname(buf), st.type, st.ino, st.size);
    }
    break;
 2f3:	90                   	nop
  }
  close(fd);
 2f4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 2f7:	89 04 24             	mov    %eax,(%esp)
 2fa:	e8 f2 02 00 00       	call   5f1 <close>
}
 2ff:	81 c4 5c 02 00 00    	add    $0x25c,%esp
 305:	5b                   	pop    %ebx
 306:	5e                   	pop    %esi
 307:	5f                   	pop    %edi
 308:	5d                   	pop    %ebp
 309:	c3                   	ret    

0000030a <main>:

int
main(int argc, char *argv[])
{
 30a:	55                   	push   %ebp
 30b:	89 e5                	mov    %esp,%ebp
 30d:	83 e4 f0             	and    $0xfffffff0,%esp
 310:	83 ec 20             	sub    $0x20,%esp
  int i;

  if(argc < 2){
 313:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
 317:	7f 11                	jg     32a <main+0x20>
    ls(".");
 319:	c7 04 24 5d 0b 00 00 	movl   $0xb5d,(%esp)
 320:	e8 8b fd ff ff       	call   b0 <ls>
    exit();
 325:	e8 9f 02 00 00       	call   5c9 <exit>
  }
  for(i=1; i<argc; i++)
 32a:	c7 44 24 1c 01 00 00 	movl   $0x1,0x1c(%esp)
 331:	00 
 332:	eb 1f                	jmp    353 <main+0x49>
    ls(argv[i]);
 334:	8b 44 24 1c          	mov    0x1c(%esp),%eax
 338:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
 33f:	8b 45 0c             	mov    0xc(%ebp),%eax
 342:	01 d0                	add    %edx,%eax
 344:	8b 00                	mov    (%eax),%eax
 346:	89 04 24             	mov    %eax,(%esp)
 349:	e8 62 fd ff ff       	call   b0 <ls>

  if(argc < 2){
    ls(".");
    exit();
  }
  for(i=1; i<argc; i++)
 34e:	83 44 24 1c 01       	addl   $0x1,0x1c(%esp)
 353:	8b 44 24 1c          	mov    0x1c(%esp),%eax
 357:	3b 45 08             	cmp    0x8(%ebp),%eax
 35a:	7c d8                	jl     334 <main+0x2a>
    ls(argv[i]);
  exit();
 35c:	e8 68 02 00 00       	call   5c9 <exit>

00000361 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
 361:	55                   	push   %ebp
 362:	89 e5                	mov    %esp,%ebp
 364:	57                   	push   %edi
 365:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
 366:	8b 4d 08             	mov    0x8(%ebp),%ecx
 369:	8b 55 10             	mov    0x10(%ebp),%edx
 36c:	8b 45 0c             	mov    0xc(%ebp),%eax
 36f:	89 cb                	mov    %ecx,%ebx
 371:	89 df                	mov    %ebx,%edi
 373:	89 d1                	mov    %edx,%ecx
 375:	fc                   	cld    
 376:	f3 aa                	rep stos %al,%es:(%edi)
 378:	89 ca                	mov    %ecx,%edx
 37a:	89 fb                	mov    %edi,%ebx
 37c:	89 5d 08             	mov    %ebx,0x8(%ebp)
 37f:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
 382:	5b                   	pop    %ebx
 383:	5f                   	pop    %edi
 384:	5d                   	pop    %ebp
 385:	c3                   	ret    

00000386 <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, char *t)
{
 386:	55                   	push   %ebp
 387:	89 e5                	mov    %esp,%ebp
 389:	83 ec 10             	sub    $0x10,%esp
  char *os;

  os = s;
 38c:	8b 45 08             	mov    0x8(%ebp),%eax
 38f:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while((*s++ = *t++) != 0)
 392:	90                   	nop
 393:	8b 45 08             	mov    0x8(%ebp),%eax
 396:	8d 50 01             	lea    0x1(%eax),%edx
 399:	89 55 08             	mov    %edx,0x8(%ebp)
 39c:	8b 55 0c             	mov    0xc(%ebp),%edx
 39f:	8d 4a 01             	lea    0x1(%edx),%ecx
 3a2:	89 4d 0c             	mov    %ecx,0xc(%ebp)
 3a5:	0f b6 12             	movzbl (%edx),%edx
 3a8:	88 10                	mov    %dl,(%eax)
 3aa:	0f b6 00             	movzbl (%eax),%eax
 3ad:	84 c0                	test   %al,%al
 3af:	75 e2                	jne    393 <strcpy+0xd>
    ;
  return os;
 3b1:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 3b4:	c9                   	leave  
 3b5:	c3                   	ret    

000003b6 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 3b6:	55                   	push   %ebp
 3b7:	89 e5                	mov    %esp,%ebp
  while(*p && *p == *q)
 3b9:	eb 08                	jmp    3c3 <strcmp+0xd>
    p++, q++;
 3bb:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 3bf:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
  while(*p && *p == *q)
 3c3:	8b 45 08             	mov    0x8(%ebp),%eax
 3c6:	0f b6 00             	movzbl (%eax),%eax
 3c9:	84 c0                	test   %al,%al
 3cb:	74 10                	je     3dd <strcmp+0x27>
 3cd:	8b 45 08             	mov    0x8(%ebp),%eax
 3d0:	0f b6 10             	movzbl (%eax),%edx
 3d3:	8b 45 0c             	mov    0xc(%ebp),%eax
 3d6:	0f b6 00             	movzbl (%eax),%eax
 3d9:	38 c2                	cmp    %al,%dl
 3db:	74 de                	je     3bb <strcmp+0x5>
    p++, q++;
  return (uchar)*p - (uchar)*q;
 3dd:	8b 45 08             	mov    0x8(%ebp),%eax
 3e0:	0f b6 00             	movzbl (%eax),%eax
 3e3:	0f b6 d0             	movzbl %al,%edx
 3e6:	8b 45 0c             	mov    0xc(%ebp),%eax
 3e9:	0f b6 00             	movzbl (%eax),%eax
 3ec:	0f b6 c0             	movzbl %al,%eax
 3ef:	29 c2                	sub    %eax,%edx
 3f1:	89 d0                	mov    %edx,%eax
}
 3f3:	5d                   	pop    %ebp
 3f4:	c3                   	ret    

000003f5 <strlen>:

uint
strlen(char *s)
{
 3f5:	55                   	push   %ebp
 3f6:	89 e5                	mov    %esp,%ebp
 3f8:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
 3fb:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
 402:	eb 04                	jmp    408 <strlen+0x13>
 404:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 408:	8b 55 fc             	mov    -0x4(%ebp),%edx
 40b:	8b 45 08             	mov    0x8(%ebp),%eax
 40e:	01 d0                	add    %edx,%eax
 410:	0f b6 00             	movzbl (%eax),%eax
 413:	84 c0                	test   %al,%al
 415:	75 ed                	jne    404 <strlen+0xf>
    ;
  return n;
 417:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 41a:	c9                   	leave  
 41b:	c3                   	ret    

0000041c <memset>:

void*
memset(void *dst, int c, uint n)
{
 41c:	55                   	push   %ebp
 41d:	89 e5                	mov    %esp,%ebp
 41f:	83 ec 0c             	sub    $0xc,%esp
  stosb(dst, c, n);
 422:	8b 45 10             	mov    0x10(%ebp),%eax
 425:	89 44 24 08          	mov    %eax,0x8(%esp)
 429:	8b 45 0c             	mov    0xc(%ebp),%eax
 42c:	89 44 24 04          	mov    %eax,0x4(%esp)
 430:	8b 45 08             	mov    0x8(%ebp),%eax
 433:	89 04 24             	mov    %eax,(%esp)
 436:	e8 26 ff ff ff       	call   361 <stosb>
  return dst;
 43b:	8b 45 08             	mov    0x8(%ebp),%eax
}
 43e:	c9                   	leave  
 43f:	c3                   	ret    

00000440 <strchr>:

char*
strchr(const char *s, char c)
{
 440:	55                   	push   %ebp
 441:	89 e5                	mov    %esp,%ebp
 443:	83 ec 04             	sub    $0x4,%esp
 446:	8b 45 0c             	mov    0xc(%ebp),%eax
 449:	88 45 fc             	mov    %al,-0x4(%ebp)
  for(; *s; s++)
 44c:	eb 14                	jmp    462 <strchr+0x22>
    if(*s == c)
 44e:	8b 45 08             	mov    0x8(%ebp),%eax
 451:	0f b6 00             	movzbl (%eax),%eax
 454:	3a 45 fc             	cmp    -0x4(%ebp),%al
 457:	75 05                	jne    45e <strchr+0x1e>
      return (char*)s;
 459:	8b 45 08             	mov    0x8(%ebp),%eax
 45c:	eb 13                	jmp    471 <strchr+0x31>
}

char*
strchr(const char *s, char c)
{
  for(; *s; s++)
 45e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 462:	8b 45 08             	mov    0x8(%ebp),%eax
 465:	0f b6 00             	movzbl (%eax),%eax
 468:	84 c0                	test   %al,%al
 46a:	75 e2                	jne    44e <strchr+0xe>
    if(*s == c)
      return (char*)s;
  return 0;
 46c:	b8 00 00 00 00       	mov    $0x0,%eax
}
 471:	c9                   	leave  
 472:	c3                   	ret    

00000473 <gets>:

char*
gets(char *buf, int max)
{
 473:	55                   	push   %ebp
 474:	89 e5                	mov    %esp,%ebp
 476:	83 ec 28             	sub    $0x28,%esp
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 479:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
 480:	eb 4c                	jmp    4ce <gets+0x5b>
    cc = read(0, &c, 1);
 482:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 489:	00 
 48a:	8d 45 ef             	lea    -0x11(%ebp),%eax
 48d:	89 44 24 04          	mov    %eax,0x4(%esp)
 491:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
 498:	e8 44 01 00 00       	call   5e1 <read>
 49d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(cc < 1)
 4a0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 4a4:	7f 02                	jg     4a8 <gets+0x35>
      break;
 4a6:	eb 31                	jmp    4d9 <gets+0x66>
    buf[i++] = c;
 4a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
 4ab:	8d 50 01             	lea    0x1(%eax),%edx
 4ae:	89 55 f4             	mov    %edx,-0xc(%ebp)
 4b1:	89 c2                	mov    %eax,%edx
 4b3:	8b 45 08             	mov    0x8(%ebp),%eax
 4b6:	01 c2                	add    %eax,%edx
 4b8:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 4bc:	88 02                	mov    %al,(%edx)
    if(c == '\n' || c == '\r')
 4be:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 4c2:	3c 0a                	cmp    $0xa,%al
 4c4:	74 13                	je     4d9 <gets+0x66>
 4c6:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 4ca:	3c 0d                	cmp    $0xd,%al
 4cc:	74 0b                	je     4d9 <gets+0x66>
gets(char *buf, int max)
{
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 4ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
 4d1:	83 c0 01             	add    $0x1,%eax
 4d4:	3b 45 0c             	cmp    0xc(%ebp),%eax
 4d7:	7c a9                	jl     482 <gets+0xf>
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
      break;
  }
  buf[i] = '\0';
 4d9:	8b 55 f4             	mov    -0xc(%ebp),%edx
 4dc:	8b 45 08             	mov    0x8(%ebp),%eax
 4df:	01 d0                	add    %edx,%eax
 4e1:	c6 00 00             	movb   $0x0,(%eax)
  return buf;
 4e4:	8b 45 08             	mov    0x8(%ebp),%eax
}
 4e7:	c9                   	leave  
 4e8:	c3                   	ret    

000004e9 <stat>:

int
stat(char *n, struct stat *st)
{
 4e9:	55                   	push   %ebp
 4ea:	89 e5                	mov    %esp,%ebp
 4ec:	83 ec 28             	sub    $0x28,%esp
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 4ef:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
 4f6:	00 
 4f7:	8b 45 08             	mov    0x8(%ebp),%eax
 4fa:	89 04 24             	mov    %eax,(%esp)
 4fd:	e8 07 01 00 00       	call   609 <open>
 502:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0)
 505:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 509:	79 07                	jns    512 <stat+0x29>
    return -1;
 50b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
 510:	eb 23                	jmp    535 <stat+0x4c>
  r = fstat(fd, st);
 512:	8b 45 0c             	mov    0xc(%ebp),%eax
 515:	89 44 24 04          	mov    %eax,0x4(%esp)
 519:	8b 45 f4             	mov    -0xc(%ebp),%eax
 51c:	89 04 24             	mov    %eax,(%esp)
 51f:	e8 fd 00 00 00       	call   621 <fstat>
 524:	89 45 f0             	mov    %eax,-0x10(%ebp)
  close(fd);
 527:	8b 45 f4             	mov    -0xc(%ebp),%eax
 52a:	89 04 24             	mov    %eax,(%esp)
 52d:	e8 bf 00 00 00       	call   5f1 <close>
  return r;
 532:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
 535:	c9                   	leave  
 536:	c3                   	ret    

00000537 <atoi>:

int
atoi(const char *s)
{
 537:	55                   	push   %ebp
 538:	89 e5                	mov    %esp,%ebp
 53a:	83 ec 10             	sub    $0x10,%esp
  int n;

  n = 0;
 53d:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  while('0' <= *s && *s <= '9')
 544:	eb 25                	jmp    56b <atoi+0x34>
    n = n*10 + *s++ - '0';
 546:	8b 55 fc             	mov    -0x4(%ebp),%edx
 549:	89 d0                	mov    %edx,%eax
 54b:	c1 e0 02             	shl    $0x2,%eax
 54e:	01 d0                	add    %edx,%eax
 550:	01 c0                	add    %eax,%eax
 552:	89 c1                	mov    %eax,%ecx
 554:	8b 45 08             	mov    0x8(%ebp),%eax
 557:	8d 50 01             	lea    0x1(%eax),%edx
 55a:	89 55 08             	mov    %edx,0x8(%ebp)
 55d:	0f b6 00             	movzbl (%eax),%eax
 560:	0f be c0             	movsbl %al,%eax
 563:	01 c8                	add    %ecx,%eax
 565:	83 e8 30             	sub    $0x30,%eax
 568:	89 45 fc             	mov    %eax,-0x4(%ebp)
atoi(const char *s)
{
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 56b:	8b 45 08             	mov    0x8(%ebp),%eax
 56e:	0f b6 00             	movzbl (%eax),%eax
 571:	3c 2f                	cmp    $0x2f,%al
 573:	7e 0a                	jle    57f <atoi+0x48>
 575:	8b 45 08             	mov    0x8(%ebp),%eax
 578:	0f b6 00             	movzbl (%eax),%eax
 57b:	3c 39                	cmp    $0x39,%al
 57d:	7e c7                	jle    546 <atoi+0xf>
    n = n*10 + *s++ - '0';
  return n;
 57f:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 582:	c9                   	leave  
 583:	c3                   	ret    

00000584 <memmove>:

void*
memmove(void *vdst, void *vsrc, int n)
{
 584:	55                   	push   %ebp
 585:	89 e5                	mov    %esp,%ebp
 587:	83 ec 10             	sub    $0x10,%esp
  char *dst, *src;
  
  dst = vdst;
 58a:	8b 45 08             	mov    0x8(%ebp),%eax
 58d:	89 45 fc             	mov    %eax,-0x4(%ebp)
  src = vsrc;
 590:	8b 45 0c             	mov    0xc(%ebp),%eax
 593:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0)
 596:	eb 17                	jmp    5af <memmove+0x2b>
    *dst++ = *src++;
 598:	8b 45 fc             	mov    -0x4(%ebp),%eax
 59b:	8d 50 01             	lea    0x1(%eax),%edx
 59e:	89 55 fc             	mov    %edx,-0x4(%ebp)
 5a1:	8b 55 f8             	mov    -0x8(%ebp),%edx
 5a4:	8d 4a 01             	lea    0x1(%edx),%ecx
 5a7:	89 4d f8             	mov    %ecx,-0x8(%ebp)
 5aa:	0f b6 12             	movzbl (%edx),%edx
 5ad:	88 10                	mov    %dl,(%eax)
{
  char *dst, *src;
  
  dst = vdst;
  src = vsrc;
  while(n-- > 0)
 5af:	8b 45 10             	mov    0x10(%ebp),%eax
 5b2:	8d 50 ff             	lea    -0x1(%eax),%edx
 5b5:	89 55 10             	mov    %edx,0x10(%ebp)
 5b8:	85 c0                	test   %eax,%eax
 5ba:	7f dc                	jg     598 <memmove+0x14>
    *dst++ = *src++;
  return vdst;
 5bc:	8b 45 08             	mov    0x8(%ebp),%eax
}
 5bf:	c9                   	leave  
 5c0:	c3                   	ret    

000005c1 <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
 5c1:	b8 01 00 00 00       	mov    $0x1,%eax
 5c6:	cd 40                	int    $0x40
 5c8:	c3                   	ret    

000005c9 <exit>:
SYSCALL(exit)
 5c9:	b8 02 00 00 00       	mov    $0x2,%eax
 5ce:	cd 40                	int    $0x40
 5d0:	c3                   	ret    

000005d1 <wait>:
SYSCALL(wait)
 5d1:	b8 03 00 00 00       	mov    $0x3,%eax
 5d6:	cd 40                	int    $0x40
 5d8:	c3                   	ret    

000005d9 <pipe>:
SYSCALL(pipe)
 5d9:	b8 04 00 00 00       	mov    $0x4,%eax
 5de:	cd 40                	int    $0x40
 5e0:	c3                   	ret    

000005e1 <read>:
SYSCALL(read)
 5e1:	b8 05 00 00 00       	mov    $0x5,%eax
 5e6:	cd 40                	int    $0x40
 5e8:	c3                   	ret    

000005e9 <write>:
SYSCALL(write)
 5e9:	b8 10 00 00 00       	mov    $0x10,%eax
 5ee:	cd 40                	int    $0x40
 5f0:	c3                   	ret    

000005f1 <close>:
SYSCALL(close)
 5f1:	b8 15 00 00 00       	mov    $0x15,%eax
 5f6:	cd 40                	int    $0x40
 5f8:	c3                   	ret    

000005f9 <kill>:
SYSCALL(kill)
 5f9:	b8 06 00 00 00       	mov    $0x6,%eax
 5fe:	cd 40                	int    $0x40
 600:	c3                   	ret    

00000601 <exec>:
SYSCALL(exec)
 601:	b8 07 00 00 00       	mov    $0x7,%eax
 606:	cd 40                	int    $0x40
 608:	c3                   	ret    

00000609 <open>:
SYSCALL(open)
 609:	b8 0f 00 00 00       	mov    $0xf,%eax
 60e:	cd 40                	int    $0x40
 610:	c3                   	ret    

00000611 <mknod>:
SYSCALL(mknod)
 611:	b8 11 00 00 00       	mov    $0x11,%eax
 616:	cd 40                	int    $0x40
 618:	c3                   	ret    

00000619 <unlink>:
SYSCALL(unlink)
 619:	b8 12 00 00 00       	mov    $0x12,%eax
 61e:	cd 40                	int    $0x40
 620:	c3                   	ret    

00000621 <fstat>:
SYSCALL(fstat)
 621:	b8 08 00 00 00       	mov    $0x8,%eax
 626:	cd 40                	int    $0x40
 628:	c3                   	ret    

00000629 <link>:
SYSCALL(link)
 629:	b8 13 00 00 00       	mov    $0x13,%eax
 62e:	cd 40                	int    $0x40
 630:	c3                   	ret    

00000631 <mkdir>:
SYSCALL(mkdir)
 631:	b8 14 00 00 00       	mov    $0x14,%eax
 636:	cd 40                	int    $0x40
 638:	c3                   	ret    

00000639 <chdir>:
SYSCALL(chdir)
 639:	b8 09 00 00 00       	mov    $0x9,%eax
 63e:	cd 40                	int    $0x40
 640:	c3                   	ret    

00000641 <dup>:
SYSCALL(dup)
 641:	b8 0a 00 00 00       	mov    $0xa,%eax
 646:	cd 40                	int    $0x40
 648:	c3                   	ret    

00000649 <getpid>:
SYSCALL(getpid)
 649:	b8 0b 00 00 00       	mov    $0xb,%eax
 64e:	cd 40                	int    $0x40
 650:	c3                   	ret    

00000651 <sbrk>:
SYSCALL(sbrk)
 651:	b8 0c 00 00 00       	mov    $0xc,%eax
 656:	cd 40                	int    $0x40
 658:	c3                   	ret    

00000659 <sleep>:
SYSCALL(sleep)
 659:	b8 0d 00 00 00       	mov    $0xd,%eax
 65e:	cd 40                	int    $0x40
 660:	c3                   	ret    

00000661 <uptime>:
SYSCALL(uptime)
 661:	b8 0e 00 00 00       	mov    $0xe,%eax
 666:	cd 40                	int    $0x40
 668:	c3                   	ret    

00000669 <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 669:	55                   	push   %ebp
 66a:	89 e5                	mov    %esp,%ebp
 66c:	83 ec 18             	sub    $0x18,%esp
 66f:	8b 45 0c             	mov    0xc(%ebp),%eax
 672:	88 45 f4             	mov    %al,-0xc(%ebp)
  write(fd, &c, 1);
 675:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 67c:	00 
 67d:	8d 45 f4             	lea    -0xc(%ebp),%eax
 680:	89 44 24 04          	mov    %eax,0x4(%esp)
 684:	8b 45 08             	mov    0x8(%ebp),%eax
 687:	89 04 24             	mov    %eax,(%esp)
 68a:	e8 5a ff ff ff       	call   5e9 <write>
}
 68f:	c9                   	leave  
 690:	c3                   	ret    

00000691 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 691:	55                   	push   %ebp
 692:	89 e5                	mov    %esp,%ebp
 694:	56                   	push   %esi
 695:	53                   	push   %ebx
 696:	83 ec 30             	sub    $0x30,%esp
  static char digits[] = "0123456789ABCDEF";
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
 699:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  if(sgn && xx < 0){
 6a0:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
 6a4:	74 17                	je     6bd <printint+0x2c>
 6a6:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
 6aa:	79 11                	jns    6bd <printint+0x2c>
    neg = 1;
 6ac:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
    x = -xx;
 6b3:	8b 45 0c             	mov    0xc(%ebp),%eax
 6b6:	f7 d8                	neg    %eax
 6b8:	89 45 ec             	mov    %eax,-0x14(%ebp)
 6bb:	eb 06                	jmp    6c3 <printint+0x32>
  } else {
    x = xx;
 6bd:	8b 45 0c             	mov    0xc(%ebp),%eax
 6c0:	89 45 ec             	mov    %eax,-0x14(%ebp)
  }

  i = 0;
 6c3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
 6ca:	8b 4d f4             	mov    -0xc(%ebp),%ecx
 6cd:	8d 41 01             	lea    0x1(%ecx),%eax
 6d0:	89 45 f4             	mov    %eax,-0xc(%ebp)
 6d3:	8b 5d 10             	mov    0x10(%ebp),%ebx
 6d6:	8b 45 ec             	mov    -0x14(%ebp),%eax
 6d9:	ba 00 00 00 00       	mov    $0x0,%edx
 6de:	f7 f3                	div    %ebx
 6e0:	89 d0                	mov    %edx,%eax
 6e2:	0f b6 80 00 0e 00 00 	movzbl 0xe00(%eax),%eax
 6e9:	88 44 0d dc          	mov    %al,-0x24(%ebp,%ecx,1)
  }while((x /= base) != 0);
 6ed:	8b 75 10             	mov    0x10(%ebp),%esi
 6f0:	8b 45 ec             	mov    -0x14(%ebp),%eax
 6f3:	ba 00 00 00 00       	mov    $0x0,%edx
 6f8:	f7 f6                	div    %esi
 6fa:	89 45 ec             	mov    %eax,-0x14(%ebp)
 6fd:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 701:	75 c7                	jne    6ca <printint+0x39>
  if(neg)
 703:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 707:	74 10                	je     719 <printint+0x88>
    buf[i++] = '-';
 709:	8b 45 f4             	mov    -0xc(%ebp),%eax
 70c:	8d 50 01             	lea    0x1(%eax),%edx
 70f:	89 55 f4             	mov    %edx,-0xc(%ebp)
 712:	c6 44 05 dc 2d       	movb   $0x2d,-0x24(%ebp,%eax,1)

  while(--i >= 0)
 717:	eb 1f                	jmp    738 <printint+0xa7>
 719:	eb 1d                	jmp    738 <printint+0xa7>
    putc(fd, buf[i]);
 71b:	8d 55 dc             	lea    -0x24(%ebp),%edx
 71e:	8b 45 f4             	mov    -0xc(%ebp),%eax
 721:	01 d0                	add    %edx,%eax
 723:	0f b6 00             	movzbl (%eax),%eax
 726:	0f be c0             	movsbl %al,%eax
 729:	89 44 24 04          	mov    %eax,0x4(%esp)
 72d:	8b 45 08             	mov    0x8(%ebp),%eax
 730:	89 04 24             	mov    %eax,(%esp)
 733:	e8 31 ff ff ff       	call   669 <putc>
    buf[i++] = digits[x % base];
  }while((x /= base) != 0);
  if(neg)
    buf[i++] = '-';

  while(--i >= 0)
 738:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
 73c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 740:	79 d9                	jns    71b <printint+0x8a>
    putc(fd, buf[i]);
}
 742:	83 c4 30             	add    $0x30,%esp
 745:	5b                   	pop    %ebx
 746:	5e                   	pop    %esi
 747:	5d                   	pop    %ebp
 748:	c3                   	ret    

00000749 <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, char *fmt, ...)
{
 749:	55                   	push   %ebp
 74a:	89 e5                	mov    %esp,%ebp
 74c:	83 ec 38             	sub    $0x38,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
 74f:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  ap = (uint*)(void*)&fmt + 1;
 756:	8d 45 0c             	lea    0xc(%ebp),%eax
 759:	83 c0 04             	add    $0x4,%eax
 75c:	89 45 e8             	mov    %eax,-0x18(%ebp)
  for(i = 0; fmt[i]; i++){
 75f:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
 766:	e9 7c 01 00 00       	jmp    8e7 <printf+0x19e>
    c = fmt[i] & 0xff;
 76b:	8b 55 0c             	mov    0xc(%ebp),%edx
 76e:	8b 45 f0             	mov    -0x10(%ebp),%eax
 771:	01 d0                	add    %edx,%eax
 773:	0f b6 00             	movzbl (%eax),%eax
 776:	0f be c0             	movsbl %al,%eax
 779:	25 ff 00 00 00       	and    $0xff,%eax
 77e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(state == 0){
 781:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 785:	75 2c                	jne    7b3 <printf+0x6a>
      if(c == '%'){
 787:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 78b:	75 0c                	jne    799 <printf+0x50>
        state = '%';
 78d:	c7 45 ec 25 00 00 00 	movl   $0x25,-0x14(%ebp)
 794:	e9 4a 01 00 00       	jmp    8e3 <printf+0x19a>
      } else {
        putc(fd, c);
 799:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 79c:	0f be c0             	movsbl %al,%eax
 79f:	89 44 24 04          	mov    %eax,0x4(%esp)
 7a3:	8b 45 08             	mov    0x8(%ebp),%eax
 7a6:	89 04 24             	mov    %eax,(%esp)
 7a9:	e8 bb fe ff ff       	call   669 <putc>
 7ae:	e9 30 01 00 00       	jmp    8e3 <printf+0x19a>
      }
    } else if(state == '%'){
 7b3:	83 7d ec 25          	cmpl   $0x25,-0x14(%ebp)
 7b7:	0f 85 26 01 00 00    	jne    8e3 <printf+0x19a>
      if(c == 'd'){
 7bd:	83 7d e4 64          	cmpl   $0x64,-0x1c(%ebp)
 7c1:	75 2d                	jne    7f0 <printf+0xa7>
        printint(fd, *ap, 10, 1);
 7c3:	8b 45 e8             	mov    -0x18(%ebp),%eax
 7c6:	8b 00                	mov    (%eax),%eax
 7c8:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
 7cf:	00 
 7d0:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
 7d7:	00 
 7d8:	89 44 24 04          	mov    %eax,0x4(%esp)
 7dc:	8b 45 08             	mov    0x8(%ebp),%eax
 7df:	89 04 24             	mov    %eax,(%esp)
 7e2:	e8 aa fe ff ff       	call   691 <printint>
        ap++;
 7e7:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 7eb:	e9 ec 00 00 00       	jmp    8dc <printf+0x193>
      } else if(c == 'x' || c == 'p'){
 7f0:	83 7d e4 78          	cmpl   $0x78,-0x1c(%ebp)
 7f4:	74 06                	je     7fc <printf+0xb3>
 7f6:	83 7d e4 70          	cmpl   $0x70,-0x1c(%ebp)
 7fa:	75 2d                	jne    829 <printf+0xe0>
        printint(fd, *ap, 16, 0);
 7fc:	8b 45 e8             	mov    -0x18(%ebp),%eax
 7ff:	8b 00                	mov    (%eax),%eax
 801:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
 808:	00 
 809:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
 810:	00 
 811:	89 44 24 04          	mov    %eax,0x4(%esp)
 815:	8b 45 08             	mov    0x8(%ebp),%eax
 818:	89 04 24             	mov    %eax,(%esp)
 81b:	e8 71 fe ff ff       	call   691 <printint>
        ap++;
 820:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 824:	e9 b3 00 00 00       	jmp    8dc <printf+0x193>
      } else if(c == 's'){
 829:	83 7d e4 73          	cmpl   $0x73,-0x1c(%ebp)
 82d:	75 45                	jne    874 <printf+0x12b>
        s = (char*)*ap;
 82f:	8b 45 e8             	mov    -0x18(%ebp),%eax
 832:	8b 00                	mov    (%eax),%eax
 834:	89 45 f4             	mov    %eax,-0xc(%ebp)
        ap++;
 837:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
        if(s == 0)
 83b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 83f:	75 09                	jne    84a <printf+0x101>
          s = "(null)";
 841:	c7 45 f4 5f 0b 00 00 	movl   $0xb5f,-0xc(%ebp)
        while(*s != 0){
 848:	eb 1e                	jmp    868 <printf+0x11f>
 84a:	eb 1c                	jmp    868 <printf+0x11f>
          putc(fd, *s);
 84c:	8b 45 f4             	mov    -0xc(%ebp),%eax
 84f:	0f b6 00             	movzbl (%eax),%eax
 852:	0f be c0             	movsbl %al,%eax
 855:	89 44 24 04          	mov    %eax,0x4(%esp)
 859:	8b 45 08             	mov    0x8(%ebp),%eax
 85c:	89 04 24             	mov    %eax,(%esp)
 85f:	e8 05 fe ff ff       	call   669 <putc>
          s++;
 864:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      } else if(c == 's'){
        s = (char*)*ap;
        ap++;
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 868:	8b 45 f4             	mov    -0xc(%ebp),%eax
 86b:	0f b6 00             	movzbl (%eax),%eax
 86e:	84 c0                	test   %al,%al
 870:	75 da                	jne    84c <printf+0x103>
 872:	eb 68                	jmp    8dc <printf+0x193>
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 874:	83 7d e4 63          	cmpl   $0x63,-0x1c(%ebp)
 878:	75 1d                	jne    897 <printf+0x14e>
        putc(fd, *ap);
 87a:	8b 45 e8             	mov    -0x18(%ebp),%eax
 87d:	8b 00                	mov    (%eax),%eax
 87f:	0f be c0             	movsbl %al,%eax
 882:	89 44 24 04          	mov    %eax,0x4(%esp)
 886:	8b 45 08             	mov    0x8(%ebp),%eax
 889:	89 04 24             	mov    %eax,(%esp)
 88c:	e8 d8 fd ff ff       	call   669 <putc>
        ap++;
 891:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 895:	eb 45                	jmp    8dc <printf+0x193>
      } else if(c == '%'){
 897:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 89b:	75 17                	jne    8b4 <printf+0x16b>
        putc(fd, c);
 89d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 8a0:	0f be c0             	movsbl %al,%eax
 8a3:	89 44 24 04          	mov    %eax,0x4(%esp)
 8a7:	8b 45 08             	mov    0x8(%ebp),%eax
 8aa:	89 04 24             	mov    %eax,(%esp)
 8ad:	e8 b7 fd ff ff       	call   669 <putc>
 8b2:	eb 28                	jmp    8dc <printf+0x193>
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 8b4:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
 8bb:	00 
 8bc:	8b 45 08             	mov    0x8(%ebp),%eax
 8bf:	89 04 24             	mov    %eax,(%esp)
 8c2:	e8 a2 fd ff ff       	call   669 <putc>
        putc(fd, c);
 8c7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 8ca:	0f be c0             	movsbl %al,%eax
 8cd:	89 44 24 04          	mov    %eax,0x4(%esp)
 8d1:	8b 45 08             	mov    0x8(%ebp),%eax
 8d4:	89 04 24             	mov    %eax,(%esp)
 8d7:	e8 8d fd ff ff       	call   669 <putc>
      }
      state = 0;
 8dc:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
  for(i = 0; fmt[i]; i++){
 8e3:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
 8e7:	8b 55 0c             	mov    0xc(%ebp),%edx
 8ea:	8b 45 f0             	mov    -0x10(%ebp),%eax
 8ed:	01 d0                	add    %edx,%eax
 8ef:	0f b6 00             	movzbl (%eax),%eax
 8f2:	84 c0                	test   %al,%al
 8f4:	0f 85 71 fe ff ff    	jne    76b <printf+0x22>
        putc(fd, c);
      }
      state = 0;
    }
  }
}
 8fa:	c9                   	leave  
 8fb:	c3                   	ret    

000008fc <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 8fc:	55                   	push   %ebp
 8fd:	89 e5                	mov    %esp,%ebp
 8ff:	83 ec 10             	sub    $0x10,%esp
  Header *bp, *p;

  bp = (Header*)ap - 1;
 902:	8b 45 08             	mov    0x8(%ebp),%eax
 905:	83 e8 08             	sub    $0x8,%eax
 908:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 90b:	a1 2c 0e 00 00       	mov    0xe2c,%eax
 910:	89 45 fc             	mov    %eax,-0x4(%ebp)
 913:	eb 24                	jmp    939 <free+0x3d>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 915:	8b 45 fc             	mov    -0x4(%ebp),%eax
 918:	8b 00                	mov    (%eax),%eax
 91a:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 91d:	77 12                	ja     931 <free+0x35>
 91f:	8b 45 f8             	mov    -0x8(%ebp),%eax
 922:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 925:	77 24                	ja     94b <free+0x4f>
 927:	8b 45 fc             	mov    -0x4(%ebp),%eax
 92a:	8b 00                	mov    (%eax),%eax
 92c:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 92f:	77 1a                	ja     94b <free+0x4f>
free(void *ap)
{
  Header *bp, *p;

  bp = (Header*)ap - 1;
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 931:	8b 45 fc             	mov    -0x4(%ebp),%eax
 934:	8b 00                	mov    (%eax),%eax
 936:	89 45 fc             	mov    %eax,-0x4(%ebp)
 939:	8b 45 f8             	mov    -0x8(%ebp),%eax
 93c:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 93f:	76 d4                	jbe    915 <free+0x19>
 941:	8b 45 fc             	mov    -0x4(%ebp),%eax
 944:	8b 00                	mov    (%eax),%eax
 946:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 949:	76 ca                	jbe    915 <free+0x19>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
 94b:	8b 45 f8             	mov    -0x8(%ebp),%eax
 94e:	8b 40 04             	mov    0x4(%eax),%eax
 951:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
 958:	8b 45 f8             	mov    -0x8(%ebp),%eax
 95b:	01 c2                	add    %eax,%edx
 95d:	8b 45 fc             	mov    -0x4(%ebp),%eax
 960:	8b 00                	mov    (%eax),%eax
 962:	39 c2                	cmp    %eax,%edx
 964:	75 24                	jne    98a <free+0x8e>
    bp->s.size += p->s.ptr->s.size;
 966:	8b 45 f8             	mov    -0x8(%ebp),%eax
 969:	8b 50 04             	mov    0x4(%eax),%edx
 96c:	8b 45 fc             	mov    -0x4(%ebp),%eax
 96f:	8b 00                	mov    (%eax),%eax
 971:	8b 40 04             	mov    0x4(%eax),%eax
 974:	01 c2                	add    %eax,%edx
 976:	8b 45 f8             	mov    -0x8(%ebp),%eax
 979:	89 50 04             	mov    %edx,0x4(%eax)
    bp->s.ptr = p->s.ptr->s.ptr;
 97c:	8b 45 fc             	mov    -0x4(%ebp),%eax
 97f:	8b 00                	mov    (%eax),%eax
 981:	8b 10                	mov    (%eax),%edx
 983:	8b 45 f8             	mov    -0x8(%ebp),%eax
 986:	89 10                	mov    %edx,(%eax)
 988:	eb 0a                	jmp    994 <free+0x98>
  } else
    bp->s.ptr = p->s.ptr;
 98a:	8b 45 fc             	mov    -0x4(%ebp),%eax
 98d:	8b 10                	mov    (%eax),%edx
 98f:	8b 45 f8             	mov    -0x8(%ebp),%eax
 992:	89 10                	mov    %edx,(%eax)
  if(p + p->s.size == bp){
 994:	8b 45 fc             	mov    -0x4(%ebp),%eax
 997:	8b 40 04             	mov    0x4(%eax),%eax
 99a:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
 9a1:	8b 45 fc             	mov    -0x4(%ebp),%eax
 9a4:	01 d0                	add    %edx,%eax
 9a6:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 9a9:	75 20                	jne    9cb <free+0xcf>
    p->s.size += bp->s.size;
 9ab:	8b 45 fc             	mov    -0x4(%ebp),%eax
 9ae:	8b 50 04             	mov    0x4(%eax),%edx
 9b1:	8b 45 f8             	mov    -0x8(%ebp),%eax
 9b4:	8b 40 04             	mov    0x4(%eax),%eax
 9b7:	01 c2                	add    %eax,%edx
 9b9:	8b 45 fc             	mov    -0x4(%ebp),%eax
 9bc:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 9bf:	8b 45 f8             	mov    -0x8(%ebp),%eax
 9c2:	8b 10                	mov    (%eax),%edx
 9c4:	8b 45 fc             	mov    -0x4(%ebp),%eax
 9c7:	89 10                	mov    %edx,(%eax)
 9c9:	eb 08                	jmp    9d3 <free+0xd7>
  } else
    p->s.ptr = bp;
 9cb:	8b 45 fc             	mov    -0x4(%ebp),%eax
 9ce:	8b 55 f8             	mov    -0x8(%ebp),%edx
 9d1:	89 10                	mov    %edx,(%eax)
  freep = p;
 9d3:	8b 45 fc             	mov    -0x4(%ebp),%eax
 9d6:	a3 2c 0e 00 00       	mov    %eax,0xe2c
}
 9db:	c9                   	leave  
 9dc:	c3                   	ret    

000009dd <morecore>:

static Header*
morecore(uint nu)
{
 9dd:	55                   	push   %ebp
 9de:	89 e5                	mov    %esp,%ebp
 9e0:	83 ec 28             	sub    $0x28,%esp
  char *p;
  Header *hp;

  if(nu < 4096)
 9e3:	81 7d 08 ff 0f 00 00 	cmpl   $0xfff,0x8(%ebp)
 9ea:	77 07                	ja     9f3 <morecore+0x16>
    nu = 4096;
 9ec:	c7 45 08 00 10 00 00 	movl   $0x1000,0x8(%ebp)
  p = sbrk(nu * sizeof(Header));
 9f3:	8b 45 08             	mov    0x8(%ebp),%eax
 9f6:	c1 e0 03             	shl    $0x3,%eax
 9f9:	89 04 24             	mov    %eax,(%esp)
 9fc:	e8 50 fc ff ff       	call   651 <sbrk>
 a01:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(p == (char*)-1)
 a04:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
 a08:	75 07                	jne    a11 <morecore+0x34>
    return 0;
 a0a:	b8 00 00 00 00       	mov    $0x0,%eax
 a0f:	eb 22                	jmp    a33 <morecore+0x56>
  hp = (Header*)p;
 a11:	8b 45 f4             	mov    -0xc(%ebp),%eax
 a14:	89 45 f0             	mov    %eax,-0x10(%ebp)
  hp->s.size = nu;
 a17:	8b 45 f0             	mov    -0x10(%ebp),%eax
 a1a:	8b 55 08             	mov    0x8(%ebp),%edx
 a1d:	89 50 04             	mov    %edx,0x4(%eax)
  free((void*)(hp + 1));
 a20:	8b 45 f0             	mov    -0x10(%ebp),%eax
 a23:	83 c0 08             	add    $0x8,%eax
 a26:	89 04 24             	mov    %eax,(%esp)
 a29:	e8 ce fe ff ff       	call   8fc <free>
  return freep;
 a2e:	a1 2c 0e 00 00       	mov    0xe2c,%eax
}
 a33:	c9                   	leave  
 a34:	c3                   	ret    

00000a35 <malloc>:

void*
malloc(uint nbytes)
{
 a35:	55                   	push   %ebp
 a36:	89 e5                	mov    %esp,%ebp
 a38:	83 ec 28             	sub    $0x28,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 a3b:	8b 45 08             	mov    0x8(%ebp),%eax
 a3e:	83 c0 07             	add    $0x7,%eax
 a41:	c1 e8 03             	shr    $0x3,%eax
 a44:	83 c0 01             	add    $0x1,%eax
 a47:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((prevp = freep) == 0){
 a4a:	a1 2c 0e 00 00       	mov    0xe2c,%eax
 a4f:	89 45 f0             	mov    %eax,-0x10(%ebp)
 a52:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 a56:	75 23                	jne    a7b <malloc+0x46>
    base.s.ptr = freep = prevp = &base;
 a58:	c7 45 f0 24 0e 00 00 	movl   $0xe24,-0x10(%ebp)
 a5f:	8b 45 f0             	mov    -0x10(%ebp),%eax
 a62:	a3 2c 0e 00 00       	mov    %eax,0xe2c
 a67:	a1 2c 0e 00 00       	mov    0xe2c,%eax
 a6c:	a3 24 0e 00 00       	mov    %eax,0xe24
    base.s.size = 0;
 a71:	c7 05 28 0e 00 00 00 	movl   $0x0,0xe28
 a78:	00 00 00 
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a7b:	8b 45 f0             	mov    -0x10(%ebp),%eax
 a7e:	8b 00                	mov    (%eax),%eax
 a80:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(p->s.size >= nunits){
 a83:	8b 45 f4             	mov    -0xc(%ebp),%eax
 a86:	8b 40 04             	mov    0x4(%eax),%eax
 a89:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 a8c:	72 4d                	jb     adb <malloc+0xa6>
      if(p->s.size == nunits)
 a8e:	8b 45 f4             	mov    -0xc(%ebp),%eax
 a91:	8b 40 04             	mov    0x4(%eax),%eax
 a94:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 a97:	75 0c                	jne    aa5 <malloc+0x70>
        prevp->s.ptr = p->s.ptr;
 a99:	8b 45 f4             	mov    -0xc(%ebp),%eax
 a9c:	8b 10                	mov    (%eax),%edx
 a9e:	8b 45 f0             	mov    -0x10(%ebp),%eax
 aa1:	89 10                	mov    %edx,(%eax)
 aa3:	eb 26                	jmp    acb <malloc+0x96>
      else {
        p->s.size -= nunits;
 aa5:	8b 45 f4             	mov    -0xc(%ebp),%eax
 aa8:	8b 40 04             	mov    0x4(%eax),%eax
 aab:	2b 45 ec             	sub    -0x14(%ebp),%eax
 aae:	89 c2                	mov    %eax,%edx
 ab0:	8b 45 f4             	mov    -0xc(%ebp),%eax
 ab3:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 ab6:	8b 45 f4             	mov    -0xc(%ebp),%eax
 ab9:	8b 40 04             	mov    0x4(%eax),%eax
 abc:	c1 e0 03             	shl    $0x3,%eax
 abf:	01 45 f4             	add    %eax,-0xc(%ebp)
        p->s.size = nunits;
 ac2:	8b 45 f4             	mov    -0xc(%ebp),%eax
 ac5:	8b 55 ec             	mov    -0x14(%ebp),%edx
 ac8:	89 50 04             	mov    %edx,0x4(%eax)
      }
      freep = prevp;
 acb:	8b 45 f0             	mov    -0x10(%ebp),%eax
 ace:	a3 2c 0e 00 00       	mov    %eax,0xe2c
      return (void*)(p + 1);
 ad3:	8b 45 f4             	mov    -0xc(%ebp),%eax
 ad6:	83 c0 08             	add    $0x8,%eax
 ad9:	eb 38                	jmp    b13 <malloc+0xde>
    }
    if(p == freep)
 adb:	a1 2c 0e 00 00       	mov    0xe2c,%eax
 ae0:	39 45 f4             	cmp    %eax,-0xc(%ebp)
 ae3:	75 1b                	jne    b00 <malloc+0xcb>
      if((p = morecore(nunits)) == 0)
 ae5:	8b 45 ec             	mov    -0x14(%ebp),%eax
 ae8:	89 04 24             	mov    %eax,(%esp)
 aeb:	e8 ed fe ff ff       	call   9dd <morecore>
 af0:	89 45 f4             	mov    %eax,-0xc(%ebp)
 af3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 af7:	75 07                	jne    b00 <malloc+0xcb>
        return 0;
 af9:	b8 00 00 00 00       	mov    $0x0,%eax
 afe:	eb 13                	jmp    b13 <malloc+0xde>
  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
  if((prevp = freep) == 0){
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 b00:	8b 45 f4             	mov    -0xc(%ebp),%eax
 b03:	89 45 f0             	mov    %eax,-0x10(%ebp)
 b06:	8b 45 f4             	mov    -0xc(%ebp),%eax
 b09:	8b 00                	mov    (%eax),%eax
 b0b:	89 45 f4             	mov    %eax,-0xc(%ebp)
      return (void*)(p + 1);
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
 b0e:	e9 70 ff ff ff       	jmp    a83 <malloc+0x4e>
}
 b13:	c9                   	leave  
 b14:	c3                   	ret    
