
kernel:     file format elf32-i386


Disassembly of section .text:

80100000 <multiboot_header>:
80100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
80100006:	00 00                	add    %al,(%eax)
80100008:	fe 4f 52             	decb   0x52(%edi)
8010000b:	e4 0f                	in     $0xf,%al

8010000c <entry>:

# Entering xv6 on boot processor, with paging off.
.globl entry
entry:
  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
8010000c:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax
8010000f:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
80100012:	0f 22 e0             	mov    %eax,%cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
80100015:	b8 00 b0 10 00       	mov    $0x10b000,%eax
  movl    %eax, %cr3
8010001a:	0f 22 d8             	mov    %eax,%cr3
  # Turn on paging.
  movl    %cr0, %eax
8010001d:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
80100020:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
80100025:	0f 22 c0             	mov    %eax,%cr0

  # Set up the stack pointer.
  movl $(stack + KSTACKSIZE), %esp
80100028:	bc 70 d6 10 80       	mov    $0x8010d670,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 ea 38 10 80       	mov    $0x801038ea,%eax
  jmp *%eax
80100032:	ff e0                	jmp    *%eax

80100034 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
80100034:	55                   	push   %ebp
80100035:	89 e5                	mov    %esp,%ebp
80100037:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  initlock(&bcache.lock, "bcache");
8010003a:	c7 44 24 04 18 92 10 	movl   $0x80109218,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
80100049:	e8 67 5a 00 00       	call   80105ab5 <initlock>

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
8010004e:	c7 05 90 15 11 80 84 	movl   $0x80111584,0x80111590
80100055:	15 11 80 
  bcache.head.next = &bcache.head;
80100058:	c7 05 94 15 11 80 84 	movl   $0x80111584,0x80111594
8010005f:	15 11 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100062:	c7 45 f4 b4 d6 10 80 	movl   $0x8010d6b4,-0xc(%ebp)
80100069:	eb 3a                	jmp    801000a5 <binit+0x71>
    b->next = bcache.head.next;
8010006b:	8b 15 94 15 11 80    	mov    0x80111594,%edx
80100071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100074:	89 50 10             	mov    %edx,0x10(%eax)
    b->prev = &bcache.head;
80100077:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010007a:	c7 40 0c 84 15 11 80 	movl   $0x80111584,0xc(%eax)
    b->dev = -1;
80100081:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100084:	c7 40 04 ff ff ff ff 	movl   $0xffffffff,0x4(%eax)
    bcache.head.next->prev = b;
8010008b:	a1 94 15 11 80       	mov    0x80111594,%eax
80100090:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100093:	89 50 0c             	mov    %edx,0xc(%eax)
    bcache.head.next = b;
80100096:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100099:	a3 94 15 11 80       	mov    %eax,0x80111594

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010009e:	81 45 f4 18 02 00 00 	addl   $0x218,-0xc(%ebp)
801000a5:	81 7d f4 84 15 11 80 	cmpl   $0x80111584,-0xc(%ebp)
801000ac:	72 bd                	jb     8010006b <binit+0x37>
    b->prev = &bcache.head;
    b->dev = -1;
    bcache.head.next->prev = b;
    bcache.head.next = b;
  }
}
801000ae:	c9                   	leave  
801000af:	c3                   	ret    

801000b0 <bget>:
// Look through buffer cache for sector on device dev.
// If not found, allocate a buffer.
// In either case, return B_BUSY buffer.
static struct buf*
bget(uint dev, uint sector)
{
801000b0:	55                   	push   %ebp
801000b1:	89 e5                	mov    %esp,%ebp
801000b3:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  acquire(&bcache.lock);
801000b6:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
801000bd:	e8 14 5a 00 00       	call   80105ad6 <acquire>

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
801000c2:	a1 94 15 11 80       	mov    0x80111594,%eax
801000c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801000ca:	eb 63                	jmp    8010012f <bget+0x7f>
    if(b->dev == dev && b->sector == sector){
801000cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000cf:	8b 40 04             	mov    0x4(%eax),%eax
801000d2:	3b 45 08             	cmp    0x8(%ebp),%eax
801000d5:	75 4f                	jne    80100126 <bget+0x76>
801000d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000da:	8b 40 08             	mov    0x8(%eax),%eax
801000dd:	3b 45 0c             	cmp    0xc(%ebp),%eax
801000e0:	75 44                	jne    80100126 <bget+0x76>
      if(!(b->flags & B_BUSY)){
801000e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000e5:	8b 00                	mov    (%eax),%eax
801000e7:	83 e0 01             	and    $0x1,%eax
801000ea:	85 c0                	test   %eax,%eax
801000ec:	75 23                	jne    80100111 <bget+0x61>
        b->flags |= B_BUSY;
801000ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000f1:	8b 00                	mov    (%eax),%eax
801000f3:	83 c8 01             	or     $0x1,%eax
801000f6:	89 c2                	mov    %eax,%edx
801000f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000fb:	89 10                	mov    %edx,(%eax)
        release(&bcache.lock);
801000fd:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
80100104:	e8 2f 5a 00 00       	call   80105b38 <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 80 d6 10 	movl   $0x8010d680,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 e0 4b 00 00       	call   80104d04 <sleep>
      goto loop;
80100124:	eb 9c                	jmp    801000c2 <bget+0x12>

  acquire(&bcache.lock);

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
80100126:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100129:	8b 40 10             	mov    0x10(%eax),%eax
8010012c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010012f:	81 7d f4 84 15 11 80 	cmpl   $0x80111584,-0xc(%ebp)
80100136:	75 94                	jne    801000cc <bget+0x1c>
  }

  // Not cached; recycle some non-busy and clean buffer.
  // "clean" because B_DIRTY and !B_BUSY means log.c
  // hasn't yet committed the changes to the buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100138:	a1 90 15 11 80       	mov    0x80111590,%eax
8010013d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100140:	eb 4d                	jmp    8010018f <bget+0xdf>
    if((b->flags & B_BUSY) == 0 && (b->flags & B_DIRTY) == 0){
80100142:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100145:	8b 00                	mov    (%eax),%eax
80100147:	83 e0 01             	and    $0x1,%eax
8010014a:	85 c0                	test   %eax,%eax
8010014c:	75 38                	jne    80100186 <bget+0xd6>
8010014e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100151:	8b 00                	mov    (%eax),%eax
80100153:	83 e0 04             	and    $0x4,%eax
80100156:	85 c0                	test   %eax,%eax
80100158:	75 2c                	jne    80100186 <bget+0xd6>
      b->dev = dev;
8010015a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010015d:	8b 55 08             	mov    0x8(%ebp),%edx
80100160:	89 50 04             	mov    %edx,0x4(%eax)
      b->sector = sector;
80100163:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100166:	8b 55 0c             	mov    0xc(%ebp),%edx
80100169:	89 50 08             	mov    %edx,0x8(%eax)
      b->flags = B_BUSY;
8010016c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010016f:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
      release(&bcache.lock);
80100175:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
8010017c:	e8 b7 59 00 00       	call   80105b38 <release>
      return b;
80100181:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100184:	eb 1e                	jmp    801001a4 <bget+0xf4>
  }

  // Not cached; recycle some non-busy and clean buffer.
  // "clean" because B_DIRTY and !B_BUSY means log.c
  // hasn't yet committed the changes to the buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100186:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100189:	8b 40 0c             	mov    0xc(%eax),%eax
8010018c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010018f:	81 7d f4 84 15 11 80 	cmpl   $0x80111584,-0xc(%ebp)
80100196:	75 aa                	jne    80100142 <bget+0x92>
      b->flags = B_BUSY;
      release(&bcache.lock);
      return b;
    }
  }
  panic("bget: no buffers");
80100198:	c7 04 24 1f 92 10 80 	movl   $0x8010921f,(%esp)
8010019f:	e8 96 03 00 00       	call   8010053a <panic>
}
801001a4:	c9                   	leave  
801001a5:	c3                   	ret    

801001a6 <bread>:

// Return a B_BUSY buf with the contents of the indicated disk sector.
struct buf*
bread(uint dev, uint sector)
{
801001a6:	55                   	push   %ebp
801001a7:	89 e5                	mov    %esp,%ebp
801001a9:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  b = bget(dev, sector);
801001ac:	8b 45 0c             	mov    0xc(%ebp),%eax
801001af:	89 44 24 04          	mov    %eax,0x4(%esp)
801001b3:	8b 45 08             	mov    0x8(%ebp),%eax
801001b6:	89 04 24             	mov    %eax,(%esp)
801001b9:	e8 f2 fe ff ff       	call   801000b0 <bget>
801001be:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(!(b->flags & B_VALID))
801001c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001c4:	8b 00                	mov    (%eax),%eax
801001c6:	83 e0 02             	and    $0x2,%eax
801001c9:	85 c0                	test   %eax,%eax
801001cb:	75 0b                	jne    801001d8 <bread+0x32>
    iderw(b);
801001cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001d0:	89 04 24             	mov    %eax,(%esp)
801001d3:	e8 9c 27 00 00       	call   80102974 <iderw>
  return b;
801001d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801001db:	c9                   	leave  
801001dc:	c3                   	ret    

801001dd <bwrite>:

// Write b's contents to disk.  Must be B_BUSY.
void
bwrite(struct buf *b)
{
801001dd:	55                   	push   %ebp
801001de:	89 e5                	mov    %esp,%ebp
801001e0:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
801001e3:	8b 45 08             	mov    0x8(%ebp),%eax
801001e6:	8b 00                	mov    (%eax),%eax
801001e8:	83 e0 01             	and    $0x1,%eax
801001eb:	85 c0                	test   %eax,%eax
801001ed:	75 0c                	jne    801001fb <bwrite+0x1e>
    panic("bwrite");
801001ef:	c7 04 24 30 92 10 80 	movl   $0x80109230,(%esp)
801001f6:	e8 3f 03 00 00       	call   8010053a <panic>
  b->flags |= B_DIRTY;
801001fb:	8b 45 08             	mov    0x8(%ebp),%eax
801001fe:	8b 00                	mov    (%eax),%eax
80100200:	83 c8 04             	or     $0x4,%eax
80100203:	89 c2                	mov    %eax,%edx
80100205:	8b 45 08             	mov    0x8(%ebp),%eax
80100208:	89 10                	mov    %edx,(%eax)
  iderw(b);
8010020a:	8b 45 08             	mov    0x8(%ebp),%eax
8010020d:	89 04 24             	mov    %eax,(%esp)
80100210:	e8 5f 27 00 00       	call   80102974 <iderw>
}
80100215:	c9                   	leave  
80100216:	c3                   	ret    

80100217 <brelse>:

// Release a B_BUSY buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
80100217:	55                   	push   %ebp
80100218:	89 e5                	mov    %esp,%ebp
8010021a:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
8010021d:	8b 45 08             	mov    0x8(%ebp),%eax
80100220:	8b 00                	mov    (%eax),%eax
80100222:	83 e0 01             	and    $0x1,%eax
80100225:	85 c0                	test   %eax,%eax
80100227:	75 0c                	jne    80100235 <brelse+0x1e>
    panic("brelse");
80100229:	c7 04 24 37 92 10 80 	movl   $0x80109237,(%esp)
80100230:	e8 05 03 00 00       	call   8010053a <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
8010023c:	e8 95 58 00 00       	call   80105ad6 <acquire>

  b->next->prev = b->prev;
80100241:	8b 45 08             	mov    0x8(%ebp),%eax
80100244:	8b 40 10             	mov    0x10(%eax),%eax
80100247:	8b 55 08             	mov    0x8(%ebp),%edx
8010024a:	8b 52 0c             	mov    0xc(%edx),%edx
8010024d:	89 50 0c             	mov    %edx,0xc(%eax)
  b->prev->next = b->next;
80100250:	8b 45 08             	mov    0x8(%ebp),%eax
80100253:	8b 40 0c             	mov    0xc(%eax),%eax
80100256:	8b 55 08             	mov    0x8(%ebp),%edx
80100259:	8b 52 10             	mov    0x10(%edx),%edx
8010025c:	89 50 10             	mov    %edx,0x10(%eax)
  b->next = bcache.head.next;
8010025f:	8b 15 94 15 11 80    	mov    0x80111594,%edx
80100265:	8b 45 08             	mov    0x8(%ebp),%eax
80100268:	89 50 10             	mov    %edx,0x10(%eax)
  b->prev = &bcache.head;
8010026b:	8b 45 08             	mov    0x8(%ebp),%eax
8010026e:	c7 40 0c 84 15 11 80 	movl   $0x80111584,0xc(%eax)
  bcache.head.next->prev = b;
80100275:	a1 94 15 11 80       	mov    0x80111594,%eax
8010027a:	8b 55 08             	mov    0x8(%ebp),%edx
8010027d:	89 50 0c             	mov    %edx,0xc(%eax)
  bcache.head.next = b;
80100280:	8b 45 08             	mov    0x8(%ebp),%eax
80100283:	a3 94 15 11 80       	mov    %eax,0x80111594

  b->flags &= ~B_BUSY;
80100288:	8b 45 08             	mov    0x8(%ebp),%eax
8010028b:	8b 00                	mov    (%eax),%eax
8010028d:	83 e0 fe             	and    $0xfffffffe,%eax
80100290:	89 c2                	mov    %eax,%edx
80100292:	8b 45 08             	mov    0x8(%ebp),%eax
80100295:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80100297:	8b 45 08             	mov    0x8(%ebp),%eax
8010029a:	89 04 24             	mov    %eax,(%esp)
8010029d:	e8 3e 4b 00 00       	call   80104de0 <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 80 d6 10 80 	movl   $0x8010d680,(%esp)
801002a9:	e8 8a 58 00 00       	call   80105b38 <release>
}
801002ae:	c9                   	leave  
801002af:	c3                   	ret    

801002b0 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801002b0:	55                   	push   %ebp
801002b1:	89 e5                	mov    %esp,%ebp
801002b3:	83 ec 14             	sub    $0x14,%esp
801002b6:	8b 45 08             	mov    0x8(%ebp),%eax
801002b9:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801002bd:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
801002c1:	89 c2                	mov    %eax,%edx
801002c3:	ec                   	in     (%dx),%al
801002c4:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
801002c7:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801002cb:	c9                   	leave  
801002cc:	c3                   	ret    

801002cd <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801002cd:	55                   	push   %ebp
801002ce:	89 e5                	mov    %esp,%ebp
801002d0:	83 ec 08             	sub    $0x8,%esp
801002d3:	8b 55 08             	mov    0x8(%ebp),%edx
801002d6:	8b 45 0c             	mov    0xc(%ebp),%eax
801002d9:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801002dd:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801002e0:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801002e4:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801002e8:	ee                   	out    %al,(%dx)
}
801002e9:	c9                   	leave  
801002ea:	c3                   	ret    

801002eb <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
801002eb:	55                   	push   %ebp
801002ec:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
801002ee:	fa                   	cli    
}
801002ef:	5d                   	pop    %ebp
801002f0:	c3                   	ret    

801002f1 <printint>:
  int locking;
} cons;

static void
printint(int xx, int base, int sign)
{
801002f1:	55                   	push   %ebp
801002f2:	89 e5                	mov    %esp,%ebp
801002f4:	56                   	push   %esi
801002f5:	53                   	push   %ebx
801002f6:	83 ec 30             	sub    $0x30,%esp
  static char digits[] = "0123456789abcdef";
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
801002f9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801002fd:	74 1c                	je     8010031b <printint+0x2a>
801002ff:	8b 45 08             	mov    0x8(%ebp),%eax
80100302:	c1 e8 1f             	shr    $0x1f,%eax
80100305:	0f b6 c0             	movzbl %al,%eax
80100308:	89 45 10             	mov    %eax,0x10(%ebp)
8010030b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010030f:	74 0a                	je     8010031b <printint+0x2a>
    x = -xx;
80100311:	8b 45 08             	mov    0x8(%ebp),%eax
80100314:	f7 d8                	neg    %eax
80100316:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100319:	eb 06                	jmp    80100321 <printint+0x30>
  else
    x = xx;
8010031b:	8b 45 08             	mov    0x8(%ebp),%eax
8010031e:	89 45 f0             	mov    %eax,-0x10(%ebp)

  i = 0;
80100321:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
80100328:	8b 4d f4             	mov    -0xc(%ebp),%ecx
8010032b:	8d 41 01             	lea    0x1(%ecx),%eax
8010032e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100331:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80100334:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100337:	ba 00 00 00 00       	mov    $0x0,%edx
8010033c:	f7 f3                	div    %ebx
8010033e:	89 d0                	mov    %edx,%eax
80100340:	0f b6 80 04 a0 10 80 	movzbl -0x7fef5ffc(%eax),%eax
80100347:	88 44 0d e0          	mov    %al,-0x20(%ebp,%ecx,1)
  }while((x /= base) != 0);
8010034b:	8b 75 0c             	mov    0xc(%ebp),%esi
8010034e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100351:	ba 00 00 00 00       	mov    $0x0,%edx
80100356:	f7 f6                	div    %esi
80100358:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010035b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010035f:	75 c7                	jne    80100328 <printint+0x37>

  if(sign)
80100361:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100365:	74 10                	je     80100377 <printint+0x86>
    buf[i++] = '-';
80100367:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010036a:	8d 50 01             	lea    0x1(%eax),%edx
8010036d:	89 55 f4             	mov    %edx,-0xc(%ebp)
80100370:	c6 44 05 e0 2d       	movb   $0x2d,-0x20(%ebp,%eax,1)

  while(--i >= 0)
80100375:	eb 18                	jmp    8010038f <printint+0x9e>
80100377:	eb 16                	jmp    8010038f <printint+0x9e>
    consputc(buf[i]);
80100379:	8d 55 e0             	lea    -0x20(%ebp),%edx
8010037c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010037f:	01 d0                	add    %edx,%eax
80100381:	0f b6 00             	movzbl (%eax),%eax
80100384:	0f be c0             	movsbl %al,%eax
80100387:	89 04 24             	mov    %eax,(%esp)
8010038a:	e8 c1 03 00 00       	call   80100750 <consputc>
  }while((x /= base) != 0);

  if(sign)
    buf[i++] = '-';

  while(--i >= 0)
8010038f:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
80100393:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100397:	79 e0                	jns    80100379 <printint+0x88>
    consputc(buf[i]);
}
80100399:	83 c4 30             	add    $0x30,%esp
8010039c:	5b                   	pop    %ebx
8010039d:	5e                   	pop    %esi
8010039e:	5d                   	pop    %ebp
8010039f:	c3                   	ret    

801003a0 <cprintf>:
//PAGEBREAK: 50

// Print to the console. only understands %d, %x, %p, %s.
void
cprintf(char *fmt, ...)
{
801003a0:	55                   	push   %ebp
801003a1:	89 e5                	mov    %esp,%ebp
801003a3:	83 ec 38             	sub    $0x38,%esp
  int i, c, locking;
  uint *argp;
  char *s;

  locking = cons.locking;
801003a6:	a1 14 c6 10 80       	mov    0x8010c614,%eax
801003ab:	89 45 e8             	mov    %eax,-0x18(%ebp)
  if(locking)
801003ae:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801003b2:	74 0c                	je     801003c0 <cprintf+0x20>
    acquire(&cons.lock);
801003b4:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
801003bb:	e8 16 57 00 00       	call   80105ad6 <acquire>

  if (fmt == 0)
801003c0:	8b 45 08             	mov    0x8(%ebp),%eax
801003c3:	85 c0                	test   %eax,%eax
801003c5:	75 0c                	jne    801003d3 <cprintf+0x33>
    panic("null fmt");
801003c7:	c7 04 24 3e 92 10 80 	movl   $0x8010923e,(%esp)
801003ce:	e8 67 01 00 00       	call   8010053a <panic>

  argp = (uint*)(void*)(&fmt + 1);
801003d3:	8d 45 0c             	lea    0xc(%ebp),%eax
801003d6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
801003d9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801003e0:	e9 21 01 00 00       	jmp    80100506 <cprintf+0x166>
    if(c != '%'){
801003e5:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
801003e9:	74 10                	je     801003fb <cprintf+0x5b>
      consputc(c);
801003eb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801003ee:	89 04 24             	mov    %eax,(%esp)
801003f1:	e8 5a 03 00 00       	call   80100750 <consputc>
      continue;
801003f6:	e9 07 01 00 00       	jmp    80100502 <cprintf+0x162>
    }
    c = fmt[++i] & 0xff;
801003fb:	8b 55 08             	mov    0x8(%ebp),%edx
801003fe:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100402:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100405:	01 d0                	add    %edx,%eax
80100407:	0f b6 00             	movzbl (%eax),%eax
8010040a:	0f be c0             	movsbl %al,%eax
8010040d:	25 ff 00 00 00       	and    $0xff,%eax
80100412:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(c == 0)
80100415:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100419:	75 05                	jne    80100420 <cprintf+0x80>
      break;
8010041b:	e9 06 01 00 00       	jmp    80100526 <cprintf+0x186>
    switch(c){
80100420:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100423:	83 f8 70             	cmp    $0x70,%eax
80100426:	74 4f                	je     80100477 <cprintf+0xd7>
80100428:	83 f8 70             	cmp    $0x70,%eax
8010042b:	7f 13                	jg     80100440 <cprintf+0xa0>
8010042d:	83 f8 25             	cmp    $0x25,%eax
80100430:	0f 84 a6 00 00 00    	je     801004dc <cprintf+0x13c>
80100436:	83 f8 64             	cmp    $0x64,%eax
80100439:	74 14                	je     8010044f <cprintf+0xaf>
8010043b:	e9 aa 00 00 00       	jmp    801004ea <cprintf+0x14a>
80100440:	83 f8 73             	cmp    $0x73,%eax
80100443:	74 57                	je     8010049c <cprintf+0xfc>
80100445:	83 f8 78             	cmp    $0x78,%eax
80100448:	74 2d                	je     80100477 <cprintf+0xd7>
8010044a:	e9 9b 00 00 00       	jmp    801004ea <cprintf+0x14a>
    case 'd':
      printint(*argp++, 10, 1);
8010044f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100452:	8d 50 04             	lea    0x4(%eax),%edx
80100455:	89 55 f0             	mov    %edx,-0x10(%ebp)
80100458:	8b 00                	mov    (%eax),%eax
8010045a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80100461:	00 
80100462:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80100469:	00 
8010046a:	89 04 24             	mov    %eax,(%esp)
8010046d:	e8 7f fe ff ff       	call   801002f1 <printint>
      break;
80100472:	e9 8b 00 00 00       	jmp    80100502 <cprintf+0x162>
    case 'x':
    case 'p':
      printint(*argp++, 16, 0);
80100477:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010047a:	8d 50 04             	lea    0x4(%eax),%edx
8010047d:	89 55 f0             	mov    %edx,-0x10(%ebp)
80100480:	8b 00                	mov    (%eax),%eax
80100482:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100489:	00 
8010048a:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80100491:	00 
80100492:	89 04 24             	mov    %eax,(%esp)
80100495:	e8 57 fe ff ff       	call   801002f1 <printint>
      break;
8010049a:	eb 66                	jmp    80100502 <cprintf+0x162>
    case 's':
      if((s = (char*)*argp++) == 0)
8010049c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010049f:	8d 50 04             	lea    0x4(%eax),%edx
801004a2:	89 55 f0             	mov    %edx,-0x10(%ebp)
801004a5:	8b 00                	mov    (%eax),%eax
801004a7:	89 45 ec             	mov    %eax,-0x14(%ebp)
801004aa:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801004ae:	75 09                	jne    801004b9 <cprintf+0x119>
        s = "(null)";
801004b0:	c7 45 ec 47 92 10 80 	movl   $0x80109247,-0x14(%ebp)
      for(; *s; s++)
801004b7:	eb 17                	jmp    801004d0 <cprintf+0x130>
801004b9:	eb 15                	jmp    801004d0 <cprintf+0x130>
        consputc(*s);
801004bb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004be:	0f b6 00             	movzbl (%eax),%eax
801004c1:	0f be c0             	movsbl %al,%eax
801004c4:	89 04 24             	mov    %eax,(%esp)
801004c7:	e8 84 02 00 00       	call   80100750 <consputc>
      printint(*argp++, 16, 0);
      break;
    case 's':
      if((s = (char*)*argp++) == 0)
        s = "(null)";
      for(; *s; s++)
801004cc:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
801004d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004d3:	0f b6 00             	movzbl (%eax),%eax
801004d6:	84 c0                	test   %al,%al
801004d8:	75 e1                	jne    801004bb <cprintf+0x11b>
        consputc(*s);
      break;
801004da:	eb 26                	jmp    80100502 <cprintf+0x162>
    case '%':
      consputc('%');
801004dc:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004e3:	e8 68 02 00 00       	call   80100750 <consputc>
      break;
801004e8:	eb 18                	jmp    80100502 <cprintf+0x162>
    default:
      // Print unknown % sequence to draw attention.
      consputc('%');
801004ea:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004f1:	e8 5a 02 00 00       	call   80100750 <consputc>
      consputc(c);
801004f6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801004f9:	89 04 24             	mov    %eax,(%esp)
801004fc:	e8 4f 02 00 00       	call   80100750 <consputc>
      break;
80100501:	90                   	nop

  if (fmt == 0)
    panic("null fmt");

  argp = (uint*)(void*)(&fmt + 1);
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100502:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100506:	8b 55 08             	mov    0x8(%ebp),%edx
80100509:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010050c:	01 d0                	add    %edx,%eax
8010050e:	0f b6 00             	movzbl (%eax),%eax
80100511:	0f be c0             	movsbl %al,%eax
80100514:	25 ff 00 00 00       	and    $0xff,%eax
80100519:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010051c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100520:	0f 85 bf fe ff ff    	jne    801003e5 <cprintf+0x45>
      consputc(c);
      break;
    }
  }

  if(locking)
80100526:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010052a:	74 0c                	je     80100538 <cprintf+0x198>
    release(&cons.lock);
8010052c:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100533:	e8 00 56 00 00       	call   80105b38 <release>
}
80100538:	c9                   	leave  
80100539:	c3                   	ret    

8010053a <panic>:

void
panic(char *s)
{
8010053a:	55                   	push   %ebp
8010053b:	89 e5                	mov    %esp,%ebp
8010053d:	83 ec 48             	sub    $0x48,%esp
  int i;
  uint pcs[10];
  
  cli();
80100540:	e8 a6 fd ff ff       	call   801002eb <cli>
  cons.locking = 0;
80100545:	c7 05 14 c6 10 80 00 	movl   $0x0,0x8010c614
8010054c:	00 00 00 
  cprintf("cpu%d: panic: ", cpu->id);
8010054f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80100555:	0f b6 00             	movzbl (%eax),%eax
80100558:	0f b6 c0             	movzbl %al,%eax
8010055b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010055f:	c7 04 24 4e 92 10 80 	movl   $0x8010924e,(%esp)
80100566:	e8 35 fe ff ff       	call   801003a0 <cprintf>
  cprintf(s);
8010056b:	8b 45 08             	mov    0x8(%ebp),%eax
8010056e:	89 04 24             	mov    %eax,(%esp)
80100571:	e8 2a fe ff ff       	call   801003a0 <cprintf>
  cprintf("\n");
80100576:	c7 04 24 5d 92 10 80 	movl   $0x8010925d,(%esp)
8010057d:	e8 1e fe ff ff       	call   801003a0 <cprintf>
  getcallerpcs(&s, pcs);
80100582:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100585:	89 44 24 04          	mov    %eax,0x4(%esp)
80100589:	8d 45 08             	lea    0x8(%ebp),%eax
8010058c:	89 04 24             	mov    %eax,(%esp)
8010058f:	e8 f3 55 00 00       	call   80105b87 <getcallerpcs>
  for(i=0; i<10; i++)
80100594:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059b:	eb 1b                	jmp    801005b8 <panic+0x7e>
    cprintf(" %p", pcs[i]);
8010059d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a0:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801005a8:	c7 04 24 5f 92 10 80 	movl   $0x8010925f,(%esp)
801005af:	e8 ec fd ff ff       	call   801003a0 <cprintf>
  cons.locking = 0;
  cprintf("cpu%d: panic: ", cpu->id);
  cprintf(s);
  cprintf("\n");
  getcallerpcs(&s, pcs);
  for(i=0; i<10; i++)
801005b4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801005b8:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
801005bc:	7e df                	jle    8010059d <panic+0x63>
    cprintf(" %p", pcs[i]);
  panicked = 1; // freeze other CPU
801005be:	c7 05 c0 c5 10 80 01 	movl   $0x1,0x8010c5c0
801005c5:	00 00 00 
  for(;;)
    ;
801005c8:	eb fe                	jmp    801005c8 <panic+0x8e>

801005ca <cgaputc>:
#define CRTPORT 0x3d4
static ushort *crt = (ushort*)P2V(0xb8000);  // CGA memory

static void
cgaputc(int c)
{
801005ca:	55                   	push   %ebp
801005cb:	89 e5                	mov    %esp,%ebp
801005cd:	83 ec 28             	sub    $0x28,%esp
  int pos;
  
  // Cursor position: col + 80*row.
  outb(CRTPORT, 14);
801005d0:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
801005d7:	00 
801005d8:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
801005df:	e8 e9 fc ff ff       	call   801002cd <outb>
  pos = inb(CRTPORT+1) << 8;
801005e4:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
801005eb:	e8 c0 fc ff ff       	call   801002b0 <inb>
801005f0:	0f b6 c0             	movzbl %al,%eax
801005f3:	c1 e0 08             	shl    $0x8,%eax
801005f6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  outb(CRTPORT, 15);
801005f9:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80100600:	00 
80100601:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
80100608:	e8 c0 fc ff ff       	call   801002cd <outb>
  pos |= inb(CRTPORT+1);
8010060d:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100614:	e8 97 fc ff ff       	call   801002b0 <inb>
80100619:	0f b6 c0             	movzbl %al,%eax
8010061c:	09 45 f4             	or     %eax,-0xc(%ebp)

  if(c == '\n')
8010061f:	83 7d 08 0a          	cmpl   $0xa,0x8(%ebp)
80100623:	75 30                	jne    80100655 <cgaputc+0x8b>
    pos += 80 - pos%80;
80100625:	8b 4d f4             	mov    -0xc(%ebp),%ecx
80100628:	ba 67 66 66 66       	mov    $0x66666667,%edx
8010062d:	89 c8                	mov    %ecx,%eax
8010062f:	f7 ea                	imul   %edx
80100631:	c1 fa 05             	sar    $0x5,%edx
80100634:	89 c8                	mov    %ecx,%eax
80100636:	c1 f8 1f             	sar    $0x1f,%eax
80100639:	29 c2                	sub    %eax,%edx
8010063b:	89 d0                	mov    %edx,%eax
8010063d:	c1 e0 02             	shl    $0x2,%eax
80100640:	01 d0                	add    %edx,%eax
80100642:	c1 e0 04             	shl    $0x4,%eax
80100645:	29 c1                	sub    %eax,%ecx
80100647:	89 ca                	mov    %ecx,%edx
80100649:	b8 50 00 00 00       	mov    $0x50,%eax
8010064e:	29 d0                	sub    %edx,%eax
80100650:	01 45 f4             	add    %eax,-0xc(%ebp)
80100653:	eb 35                	jmp    8010068a <cgaputc+0xc0>
  else if(c == BACKSPACE){
80100655:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
8010065c:	75 0c                	jne    8010066a <cgaputc+0xa0>
    if(pos > 0) --pos;
8010065e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100662:	7e 26                	jle    8010068a <cgaputc+0xc0>
80100664:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
80100668:	eb 20                	jmp    8010068a <cgaputc+0xc0>
  } else
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
8010066a:	8b 0d 00 a0 10 80    	mov    0x8010a000,%ecx
80100670:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100673:	8d 50 01             	lea    0x1(%eax),%edx
80100676:	89 55 f4             	mov    %edx,-0xc(%ebp)
80100679:	01 c0                	add    %eax,%eax
8010067b:	8d 14 01             	lea    (%ecx,%eax,1),%edx
8010067e:	8b 45 08             	mov    0x8(%ebp),%eax
80100681:	0f b6 c0             	movzbl %al,%eax
80100684:	80 cc 07             	or     $0x7,%ah
80100687:	66 89 02             	mov    %ax,(%edx)
  
  if((pos/80) >= 24){  // Scroll up.
8010068a:	81 7d f4 7f 07 00 00 	cmpl   $0x77f,-0xc(%ebp)
80100691:	7e 53                	jle    801006e6 <cgaputc+0x11c>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
80100693:	a1 00 a0 10 80       	mov    0x8010a000,%eax
80100698:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
8010069e:	a1 00 a0 10 80       	mov    0x8010a000,%eax
801006a3:	c7 44 24 08 60 0e 00 	movl   $0xe60,0x8(%esp)
801006aa:	00 
801006ab:	89 54 24 04          	mov    %edx,0x4(%esp)
801006af:	89 04 24             	mov    %eax,(%esp)
801006b2:	e8 42 57 00 00       	call   80105df9 <memmove>
    pos -= 80;
801006b7:	83 6d f4 50          	subl   $0x50,-0xc(%ebp)
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801006bb:	b8 80 07 00 00       	mov    $0x780,%eax
801006c0:	2b 45 f4             	sub    -0xc(%ebp),%eax
801006c3:	8d 14 00             	lea    (%eax,%eax,1),%edx
801006c6:	a1 00 a0 10 80       	mov    0x8010a000,%eax
801006cb:	8b 4d f4             	mov    -0xc(%ebp),%ecx
801006ce:	01 c9                	add    %ecx,%ecx
801006d0:	01 c8                	add    %ecx,%eax
801006d2:	89 54 24 08          	mov    %edx,0x8(%esp)
801006d6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801006dd:	00 
801006de:	89 04 24             	mov    %eax,(%esp)
801006e1:	e8 44 56 00 00       	call   80105d2a <memset>
  }
  
  outb(CRTPORT, 14);
801006e6:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
801006ed:	00 
801006ee:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
801006f5:	e8 d3 fb ff ff       	call   801002cd <outb>
  outb(CRTPORT+1, pos>>8);
801006fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801006fd:	c1 f8 08             	sar    $0x8,%eax
80100700:	0f b6 c0             	movzbl %al,%eax
80100703:	89 44 24 04          	mov    %eax,0x4(%esp)
80100707:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
8010070e:	e8 ba fb ff ff       	call   801002cd <outb>
  outb(CRTPORT, 15);
80100713:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
8010071a:	00 
8010071b:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
80100722:	e8 a6 fb ff ff       	call   801002cd <outb>
  outb(CRTPORT+1, pos);
80100727:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010072a:	0f b6 c0             	movzbl %al,%eax
8010072d:	89 44 24 04          	mov    %eax,0x4(%esp)
80100731:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100738:	e8 90 fb ff ff       	call   801002cd <outb>
  crt[pos] = ' ' | 0x0700;
8010073d:	a1 00 a0 10 80       	mov    0x8010a000,%eax
80100742:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100745:	01 d2                	add    %edx,%edx
80100747:	01 d0                	add    %edx,%eax
80100749:	66 c7 00 20 07       	movw   $0x720,(%eax)
}
8010074e:	c9                   	leave  
8010074f:	c3                   	ret    

80100750 <consputc>:

void
consputc(int c)
{
80100750:	55                   	push   %ebp
80100751:	89 e5                	mov    %esp,%ebp
80100753:	83 ec 18             	sub    $0x18,%esp
  if(panicked){
80100756:	a1 c0 c5 10 80       	mov    0x8010c5c0,%eax
8010075b:	85 c0                	test   %eax,%eax
8010075d:	74 07                	je     80100766 <consputc+0x16>
    cli();
8010075f:	e8 87 fb ff ff       	call   801002eb <cli>
    for(;;)
      ;
80100764:	eb fe                	jmp    80100764 <consputc+0x14>
  }

  if(c == BACKSPACE){
80100766:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
8010076d:	75 26                	jne    80100795 <consputc+0x45>
    uartputc('\b'); uartputc(' '); uartputc('\b');
8010076f:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100776:	e8 dd 70 00 00       	call   80107858 <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 d1 70 00 00       	call   80107858 <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 c5 70 00 00       	call   80107858 <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 b8 70 00 00       	call   80107858 <uartputc>
  cgaputc(c);
801007a0:	8b 45 08             	mov    0x8(%ebp),%eax
801007a3:	89 04 24             	mov    %eax,(%esp)
801007a6:	e8 1f fe ff ff       	call   801005ca <cgaputc>
}
801007ab:	c9                   	leave  
801007ac:	c3                   	ret    

801007ad <consoleintr>:

#define C(x)  ((x)-'@')  // Control-x

void
consoleintr(int (*getc)(void))
{
801007ad:	55                   	push   %ebp
801007ae:	89 e5                	mov    %esp,%ebp
801007b0:	83 ec 28             	sub    $0x28,%esp
  int c;

  acquire(&input.lock);
801007b3:	c7 04 24 a0 17 11 80 	movl   $0x801117a0,(%esp)
801007ba:	e8 17 53 00 00       	call   80105ad6 <acquire>
  while((c = getc()) >= 0){
801007bf:	e9 37 01 00 00       	jmp    801008fb <consoleintr+0x14e>
    switch(c){
801007c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801007c7:	83 f8 10             	cmp    $0x10,%eax
801007ca:	74 1e                	je     801007ea <consoleintr+0x3d>
801007cc:	83 f8 10             	cmp    $0x10,%eax
801007cf:	7f 0a                	jg     801007db <consoleintr+0x2e>
801007d1:	83 f8 08             	cmp    $0x8,%eax
801007d4:	74 64                	je     8010083a <consoleintr+0x8d>
801007d6:	e9 91 00 00 00       	jmp    8010086c <consoleintr+0xbf>
801007db:	83 f8 15             	cmp    $0x15,%eax
801007de:	74 2f                	je     8010080f <consoleintr+0x62>
801007e0:	83 f8 7f             	cmp    $0x7f,%eax
801007e3:	74 55                	je     8010083a <consoleintr+0x8d>
801007e5:	e9 82 00 00 00       	jmp    8010086c <consoleintr+0xbf>
    case C('P'):  // Process listing.
      procdump();
801007ea:	e8 97 46 00 00       	call   80104e86 <procdump>
      break;
801007ef:	e9 07 01 00 00       	jmp    801008fb <consoleintr+0x14e>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
801007f4:	a1 5c 18 11 80       	mov    0x8011185c,%eax
801007f9:	83 e8 01             	sub    $0x1,%eax
801007fc:	a3 5c 18 11 80       	mov    %eax,0x8011185c
        consputc(BACKSPACE);
80100801:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100808:	e8 43 ff ff ff       	call   80100750 <consputc>
8010080d:	eb 01                	jmp    80100810 <consoleintr+0x63>
    switch(c){
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
8010080f:	90                   	nop
80100810:	8b 15 5c 18 11 80    	mov    0x8011185c,%edx
80100816:	a1 58 18 11 80       	mov    0x80111858,%eax
8010081b:	39 c2                	cmp    %eax,%edx
8010081d:	74 16                	je     80100835 <consoleintr+0x88>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
8010081f:	a1 5c 18 11 80       	mov    0x8011185c,%eax
80100824:	83 e8 01             	sub    $0x1,%eax
80100827:	83 e0 7f             	and    $0x7f,%eax
8010082a:	0f b6 80 d4 17 11 80 	movzbl -0x7feee82c(%eax),%eax
    switch(c){
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
80100831:	3c 0a                	cmp    $0xa,%al
80100833:	75 bf                	jne    801007f4 <consoleintr+0x47>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
80100835:	e9 c1 00 00 00       	jmp    801008fb <consoleintr+0x14e>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
8010083a:	8b 15 5c 18 11 80    	mov    0x8011185c,%edx
80100840:	a1 58 18 11 80       	mov    0x80111858,%eax
80100845:	39 c2                	cmp    %eax,%edx
80100847:	74 1e                	je     80100867 <consoleintr+0xba>
        input.e--;
80100849:	a1 5c 18 11 80       	mov    0x8011185c,%eax
8010084e:	83 e8 01             	sub    $0x1,%eax
80100851:	a3 5c 18 11 80       	mov    %eax,0x8011185c
        consputc(BACKSPACE);
80100856:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
8010085d:	e8 ee fe ff ff       	call   80100750 <consputc>
      }
      break;
80100862:	e9 94 00 00 00       	jmp    801008fb <consoleintr+0x14e>
80100867:	e9 8f 00 00 00       	jmp    801008fb <consoleintr+0x14e>
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
8010086c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100870:	0f 84 84 00 00 00    	je     801008fa <consoleintr+0x14d>
80100876:	8b 15 5c 18 11 80    	mov    0x8011185c,%edx
8010087c:	a1 54 18 11 80       	mov    0x80111854,%eax
80100881:	29 c2                	sub    %eax,%edx
80100883:	89 d0                	mov    %edx,%eax
80100885:	83 f8 7f             	cmp    $0x7f,%eax
80100888:	77 70                	ja     801008fa <consoleintr+0x14d>
        c = (c == '\r') ? '\n' : c;
8010088a:	83 7d f4 0d          	cmpl   $0xd,-0xc(%ebp)
8010088e:	74 05                	je     80100895 <consoleintr+0xe8>
80100890:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100893:	eb 05                	jmp    8010089a <consoleintr+0xed>
80100895:	b8 0a 00 00 00       	mov    $0xa,%eax
8010089a:	89 45 f4             	mov    %eax,-0xc(%ebp)
        input.buf[input.e++ % INPUT_BUF] = c;
8010089d:	a1 5c 18 11 80       	mov    0x8011185c,%eax
801008a2:	8d 50 01             	lea    0x1(%eax),%edx
801008a5:	89 15 5c 18 11 80    	mov    %edx,0x8011185c
801008ab:	83 e0 7f             	and    $0x7f,%eax
801008ae:	89 c2                	mov    %eax,%edx
801008b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801008b3:	88 82 d4 17 11 80    	mov    %al,-0x7feee82c(%edx)
        consputc(c);
801008b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801008bc:	89 04 24             	mov    %eax,(%esp)
801008bf:	e8 8c fe ff ff       	call   80100750 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801008c4:	83 7d f4 0a          	cmpl   $0xa,-0xc(%ebp)
801008c8:	74 18                	je     801008e2 <consoleintr+0x135>
801008ca:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
801008ce:	74 12                	je     801008e2 <consoleintr+0x135>
801008d0:	a1 5c 18 11 80       	mov    0x8011185c,%eax
801008d5:	8b 15 54 18 11 80    	mov    0x80111854,%edx
801008db:	83 ea 80             	sub    $0xffffff80,%edx
801008de:	39 d0                	cmp    %edx,%eax
801008e0:	75 18                	jne    801008fa <consoleintr+0x14d>
          input.w = input.e;
801008e2:	a1 5c 18 11 80       	mov    0x8011185c,%eax
801008e7:	a3 58 18 11 80       	mov    %eax,0x80111858
          wakeup(&input.r);
801008ec:	c7 04 24 54 18 11 80 	movl   $0x80111854,(%esp)
801008f3:	e8 e8 44 00 00       	call   80104de0 <wakeup>
        }
      }
      break;
801008f8:	eb 00                	jmp    801008fa <consoleintr+0x14d>
801008fa:	90                   	nop
consoleintr(int (*getc)(void))
{
  int c;

  acquire(&input.lock);
  while((c = getc()) >= 0){
801008fb:	8b 45 08             	mov    0x8(%ebp),%eax
801008fe:	ff d0                	call   *%eax
80100900:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100903:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100907:	0f 89 b7 fe ff ff    	jns    801007c4 <consoleintr+0x17>
        }
      }
      break;
    }
  }
  release(&input.lock);
8010090d:	c7 04 24 a0 17 11 80 	movl   $0x801117a0,(%esp)
80100914:	e8 1f 52 00 00       	call   80105b38 <release>
}
80100919:	c9                   	leave  
8010091a:	c3                   	ret    

8010091b <consoleread>:

int
consoleread(struct inode *ip, char *dst, int off, int n)
{
8010091b:	55                   	push   %ebp
8010091c:	89 e5                	mov    %esp,%ebp
8010091e:	83 ec 28             	sub    $0x28,%esp
  uint target;
  int c;

  iunlock(ip);
80100921:	8b 45 08             	mov    0x8(%ebp),%eax
80100924:	89 04 24             	mov    %eax,(%esp)
80100927:	e8 35 11 00 00       	call   80101a61 <iunlock>
  target = n;
8010092c:	8b 45 14             	mov    0x14(%ebp),%eax
8010092f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&input.lock);
80100932:	c7 04 24 a0 17 11 80 	movl   $0x801117a0,(%esp)
80100939:	e8 98 51 00 00       	call   80105ad6 <acquire>
  while(n > 0){
8010093e:	e9 aa 00 00 00       	jmp    801009ed <consoleread+0xd2>
    while(input.r == input.w){
80100943:	eb 42                	jmp    80100987 <consoleread+0x6c>
      if(proc->killed){
80100945:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010094b:	8b 40 24             	mov    0x24(%eax),%eax
8010094e:	85 c0                	test   %eax,%eax
80100950:	74 21                	je     80100973 <consoleread+0x58>
        release(&input.lock);
80100952:	c7 04 24 a0 17 11 80 	movl   $0x801117a0,(%esp)
80100959:	e8 da 51 00 00       	call   80105b38 <release>
        ilock(ip);
8010095e:	8b 45 08             	mov    0x8(%ebp),%eax
80100961:	89 04 24             	mov    %eax,(%esp)
80100964:	e8 aa 0f 00 00       	call   80101913 <ilock>
        return -1;
80100969:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010096e:	e9 a5 00 00 00       	jmp    80100a18 <consoleread+0xfd>
      }
      sleep(&input.r, &input.lock);
80100973:	c7 44 24 04 a0 17 11 	movl   $0x801117a0,0x4(%esp)
8010097a:	80 
8010097b:	c7 04 24 54 18 11 80 	movl   $0x80111854,(%esp)
80100982:	e8 7d 43 00 00       	call   80104d04 <sleep>

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
    while(input.r == input.w){
80100987:	8b 15 54 18 11 80    	mov    0x80111854,%edx
8010098d:	a1 58 18 11 80       	mov    0x80111858,%eax
80100992:	39 c2                	cmp    %eax,%edx
80100994:	74 af                	je     80100945 <consoleread+0x2a>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &input.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
80100996:	a1 54 18 11 80       	mov    0x80111854,%eax
8010099b:	8d 50 01             	lea    0x1(%eax),%edx
8010099e:	89 15 54 18 11 80    	mov    %edx,0x80111854
801009a4:	83 e0 7f             	and    $0x7f,%eax
801009a7:	0f b6 80 d4 17 11 80 	movzbl -0x7feee82c(%eax),%eax
801009ae:	0f be c0             	movsbl %al,%eax
801009b1:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(c == C('D')){  // EOF
801009b4:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
801009b8:	75 19                	jne    801009d3 <consoleread+0xb8>
      if(n < target){
801009ba:	8b 45 14             	mov    0x14(%ebp),%eax
801009bd:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801009c0:	73 0f                	jae    801009d1 <consoleread+0xb6>
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
801009c2:	a1 54 18 11 80       	mov    0x80111854,%eax
801009c7:	83 e8 01             	sub    $0x1,%eax
801009ca:	a3 54 18 11 80       	mov    %eax,0x80111854
      }
      break;
801009cf:	eb 26                	jmp    801009f7 <consoleread+0xdc>
801009d1:	eb 24                	jmp    801009f7 <consoleread+0xdc>
    }
    *dst++ = c;
801009d3:	8b 45 0c             	mov    0xc(%ebp),%eax
801009d6:	8d 50 01             	lea    0x1(%eax),%edx
801009d9:	89 55 0c             	mov    %edx,0xc(%ebp)
801009dc:	8b 55 f0             	mov    -0x10(%ebp),%edx
801009df:	88 10                	mov    %dl,(%eax)
    --n;
801009e1:	83 6d 14 01          	subl   $0x1,0x14(%ebp)
    if(c == '\n')
801009e5:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
801009e9:	75 02                	jne    801009ed <consoleread+0xd2>
      break;
801009eb:	eb 0a                	jmp    801009f7 <consoleread+0xdc>
  int c;

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
801009ed:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801009f1:	0f 8f 4c ff ff ff    	jg     80100943 <consoleread+0x28>
    *dst++ = c;
    --n;
    if(c == '\n')
      break;
  }
  release(&input.lock);
801009f7:	c7 04 24 a0 17 11 80 	movl   $0x801117a0,(%esp)
801009fe:	e8 35 51 00 00       	call   80105b38 <release>
  ilock(ip);
80100a03:	8b 45 08             	mov    0x8(%ebp),%eax
80100a06:	89 04 24             	mov    %eax,(%esp)
80100a09:	e8 05 0f 00 00       	call   80101913 <ilock>

  return target - n;
80100a0e:	8b 45 14             	mov    0x14(%ebp),%eax
80100a11:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100a14:	29 c2                	sub    %eax,%edx
80100a16:	89 d0                	mov    %edx,%eax
}
80100a18:	c9                   	leave  
80100a19:	c3                   	ret    

80100a1a <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
80100a1a:	55                   	push   %ebp
80100a1b:	89 e5                	mov    %esp,%ebp
80100a1d:	83 ec 28             	sub    $0x28,%esp
  int i;

  iunlock(ip);
80100a20:	8b 45 08             	mov    0x8(%ebp),%eax
80100a23:	89 04 24             	mov    %eax,(%esp)
80100a26:	e8 36 10 00 00       	call   80101a61 <iunlock>
  acquire(&cons.lock);
80100a2b:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100a32:	e8 9f 50 00 00       	call   80105ad6 <acquire>
  for(i = 0; i < n; i++)
80100a37:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100a3e:	eb 1d                	jmp    80100a5d <consolewrite+0x43>
    consputc(buf[i] & 0xff);
80100a40:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100a43:	8b 45 0c             	mov    0xc(%ebp),%eax
80100a46:	01 d0                	add    %edx,%eax
80100a48:	0f b6 00             	movzbl (%eax),%eax
80100a4b:	0f be c0             	movsbl %al,%eax
80100a4e:	0f b6 c0             	movzbl %al,%eax
80100a51:	89 04 24             	mov    %eax,(%esp)
80100a54:	e8 f7 fc ff ff       	call   80100750 <consputc>
{
  int i;

  iunlock(ip);
  acquire(&cons.lock);
  for(i = 0; i < n; i++)
80100a59:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100a5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100a60:	3b 45 10             	cmp    0x10(%ebp),%eax
80100a63:	7c db                	jl     80100a40 <consolewrite+0x26>
    consputc(buf[i] & 0xff);
  release(&cons.lock);
80100a65:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100a6c:	e8 c7 50 00 00       	call   80105b38 <release>
  ilock(ip);
80100a71:	8b 45 08             	mov    0x8(%ebp),%eax
80100a74:	89 04 24             	mov    %eax,(%esp)
80100a77:	e8 97 0e 00 00       	call   80101913 <ilock>

  return n;
80100a7c:	8b 45 10             	mov    0x10(%ebp),%eax
}
80100a7f:	c9                   	leave  
80100a80:	c3                   	ret    

80100a81 <consoleinit>:

void
consoleinit(void)
{
80100a81:	55                   	push   %ebp
80100a82:	89 e5                	mov    %esp,%ebp
80100a84:	83 ec 18             	sub    $0x18,%esp
  initlock(&cons.lock, "console");
80100a87:	c7 44 24 04 63 92 10 	movl   $0x80109263,0x4(%esp)
80100a8e:	80 
80100a8f:	c7 04 24 e0 c5 10 80 	movl   $0x8010c5e0,(%esp)
80100a96:	e8 1a 50 00 00       	call   80105ab5 <initlock>
  initlock(&input.lock, "input");
80100a9b:	c7 44 24 04 6b 92 10 	movl   $0x8010926b,0x4(%esp)
80100aa2:	80 
80100aa3:	c7 04 24 a0 17 11 80 	movl   $0x801117a0,(%esp)
80100aaa:	e8 06 50 00 00       	call   80105ab5 <initlock>

  devsw[CONSOLE].write = consolewrite;
80100aaf:	c7 05 1c 22 11 80 1a 	movl   $0x80100a1a,0x8011221c
80100ab6:	0a 10 80 
  devsw[CONSOLE].read = consoleread;
80100ab9:	c7 05 18 22 11 80 1b 	movl   $0x8010091b,0x80112218
80100ac0:	09 10 80 
  cons.locking = 1;
80100ac3:	c7 05 14 c6 10 80 01 	movl   $0x1,0x8010c614
80100aca:	00 00 00 

  picenable(IRQ_KBD);
80100acd:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100ad4:	e8 b3 34 00 00       	call   80103f8c <picenable>
  ioapicenable(IRQ_KBD, 0);
80100ad9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100ae0:	00 
80100ae1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100ae8:	e8 43 20 00 00       	call   80102b30 <ioapicenable>
}
80100aed:	c9                   	leave  
80100aee:	c3                   	ret    

80100aef <exec>:
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
{
80100aef:	55                   	push   %ebp
80100af0:	89 e5                	mov    %esp,%ebp
80100af2:	53                   	push   %ebx
80100af3:	81 ec 34 01 00 00    	sub    $0x134,%esp
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;

  begin_op();
80100af9:	e8 e5 2a 00 00       	call   801035e3 <begin_op>
  if((ip = namei(path)) == 0){
80100afe:	8b 45 08             	mov    0x8(%ebp),%eax
80100b01:	89 04 24             	mov    %eax,(%esp)
80100b04:	e8 d0 1a 00 00       	call   801025d9 <namei>
80100b09:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b0c:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b10:	75 0f                	jne    80100b21 <exec+0x32>
    end_op();
80100b12:	e8 50 2b 00 00       	call   80103667 <end_op>
    return -1;
80100b17:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100b1c:	e9 98 04 00 00       	jmp    80100fb9 <exec+0x4ca>
  }
  ilock(ip);
80100b21:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b24:	89 04 24             	mov    %eax,(%esp)
80100b27:	e8 e7 0d 00 00       	call   80101913 <ilock>
  pgdir = 0;
80100b2c:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)


  proc->exe= idup(ip); //Handle and change the exe cell by dup inode ~ yoed
80100b33:	65 8b 1d 04 00 00 00 	mov    %gs:0x4,%ebx
80100b3a:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b3d:	89 04 24             	mov    %eax,(%esp)
80100b40:	e8 9c 0d 00 00       	call   801018e1 <idup>
80100b45:	89 43 7c             	mov    %eax,0x7c(%ebx)

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
80100b48:	c7 44 24 0c 34 00 00 	movl   $0x34,0xc(%esp)
80100b4f:	00 
80100b50:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100b57:	00 
80100b58:	8d 85 08 ff ff ff    	lea    -0xf8(%ebp),%eax
80100b5e:	89 44 24 04          	mov    %eax,0x4(%esp)
80100b62:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b65:	89 04 24             	mov    %eax,(%esp)
80100b68:	e8 b3 12 00 00       	call   80101e20 <readi>
80100b6d:	83 f8 33             	cmp    $0x33,%eax
80100b70:	77 05                	ja     80100b77 <exec+0x88>
    goto bad;
80100b72:	e9 16 04 00 00       	jmp    80100f8d <exec+0x49e>
  if(elf.magic != ELF_MAGIC)
80100b77:	8b 85 08 ff ff ff    	mov    -0xf8(%ebp),%eax
80100b7d:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100b82:	74 05                	je     80100b89 <exec+0x9a>
    goto bad;
80100b84:	e9 04 04 00 00       	jmp    80100f8d <exec+0x49e>

  if((pgdir = setupkvm()) == 0)
80100b89:	e8 1b 7e 00 00       	call   801089a9 <setupkvm>
80100b8e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80100b91:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100b95:	75 05                	jne    80100b9c <exec+0xad>
    goto bad;
80100b97:	e9 f1 03 00 00       	jmp    80100f8d <exec+0x49e>

  // Load program into memory.
  sz = 0;
80100b9c:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100ba3:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80100baa:	8b 85 24 ff ff ff    	mov    -0xdc(%ebp),%eax
80100bb0:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100bb3:	e9 cb 00 00 00       	jmp    80100c83 <exec+0x194>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
80100bb8:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100bbb:	c7 44 24 0c 20 00 00 	movl   $0x20,0xc(%esp)
80100bc2:	00 
80100bc3:	89 44 24 08          	mov    %eax,0x8(%esp)
80100bc7:	8d 85 e8 fe ff ff    	lea    -0x118(%ebp),%eax
80100bcd:	89 44 24 04          	mov    %eax,0x4(%esp)
80100bd1:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100bd4:	89 04 24             	mov    %eax,(%esp)
80100bd7:	e8 44 12 00 00       	call   80101e20 <readi>
80100bdc:	83 f8 20             	cmp    $0x20,%eax
80100bdf:	74 05                	je     80100be6 <exec+0xf7>
      goto bad;
80100be1:	e9 a7 03 00 00       	jmp    80100f8d <exec+0x49e>
    if(ph.type != ELF_PROG_LOAD)
80100be6:	8b 85 e8 fe ff ff    	mov    -0x118(%ebp),%eax
80100bec:	83 f8 01             	cmp    $0x1,%eax
80100bef:	74 05                	je     80100bf6 <exec+0x107>
      continue;
80100bf1:	e9 80 00 00 00       	jmp    80100c76 <exec+0x187>
    if(ph.memsz < ph.filesz)
80100bf6:	8b 95 fc fe ff ff    	mov    -0x104(%ebp),%edx
80100bfc:	8b 85 f8 fe ff ff    	mov    -0x108(%ebp),%eax
80100c02:	39 c2                	cmp    %eax,%edx
80100c04:	73 05                	jae    80100c0b <exec+0x11c>
      goto bad;
80100c06:	e9 82 03 00 00       	jmp    80100f8d <exec+0x49e>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
80100c0b:	8b 95 f0 fe ff ff    	mov    -0x110(%ebp),%edx
80100c11:	8b 85 fc fe ff ff    	mov    -0x104(%ebp),%eax
80100c17:	01 d0                	add    %edx,%eax
80100c19:	89 44 24 08          	mov    %eax,0x8(%esp)
80100c1d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100c20:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c24:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100c27:	89 04 24             	mov    %eax,(%esp)
80100c2a:	e8 48 81 00 00       	call   80108d77 <allocuvm>
80100c2f:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100c32:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100c36:	75 05                	jne    80100c3d <exec+0x14e>
      goto bad;
80100c38:	e9 50 03 00 00       	jmp    80100f8d <exec+0x49e>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100c3d:	8b 8d f8 fe ff ff    	mov    -0x108(%ebp),%ecx
80100c43:	8b 95 ec fe ff ff    	mov    -0x114(%ebp),%edx
80100c49:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
80100c4f:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80100c53:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100c57:	8b 55 d8             	mov    -0x28(%ebp),%edx
80100c5a:	89 54 24 08          	mov    %edx,0x8(%esp)
80100c5e:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c62:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100c65:	89 04 24             	mov    %eax,(%esp)
80100c68:	e8 1f 80 00 00       	call   80108c8c <loaduvm>
80100c6d:	85 c0                	test   %eax,%eax
80100c6f:	79 05                	jns    80100c76 <exec+0x187>
      goto bad;
80100c71:	e9 17 03 00 00       	jmp    80100f8d <exec+0x49e>
  if((pgdir = setupkvm()) == 0)
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100c76:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100c7a:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100c7d:	83 c0 20             	add    $0x20,%eax
80100c80:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100c83:	0f b7 85 34 ff ff ff 	movzwl -0xcc(%ebp),%eax
80100c8a:	0f b7 c0             	movzwl %ax,%eax
80100c8d:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80100c90:	0f 8f 22 ff ff ff    	jg     80100bb8 <exec+0xc9>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }
  iunlockput(ip);
80100c96:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100c99:	89 04 24             	mov    %eax,(%esp)
80100c9c:	e8 f6 0e 00 00       	call   80101b97 <iunlockput>
  end_op();
80100ca1:	e8 c1 29 00 00       	call   80103667 <end_op>
  ip = 0;
80100ca6:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
80100cad:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cb0:	05 ff 0f 00 00       	add    $0xfff,%eax
80100cb5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80100cba:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100cbd:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cc0:	05 00 20 00 00       	add    $0x2000,%eax
80100cc5:	89 44 24 08          	mov    %eax,0x8(%esp)
80100cc9:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100ccc:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cd0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100cd3:	89 04 24             	mov    %eax,(%esp)
80100cd6:	e8 9c 80 00 00       	call   80108d77 <allocuvm>
80100cdb:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100cde:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100ce2:	75 05                	jne    80100ce9 <exec+0x1fa>
    goto bad;
80100ce4:	e9 a4 02 00 00       	jmp    80100f8d <exec+0x49e>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100ce9:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cec:	2d 00 20 00 00       	sub    $0x2000,%eax
80100cf1:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cf5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100cf8:	89 04 24             	mov    %eax,(%esp)
80100cfb:	e8 a7 82 00 00       	call   80108fa7 <clearpteu>
  sp = sz;
80100d00:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d03:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // Push argument strings, prepare rest of stack in ustack.
  int cmdlen = 0;
80100d06:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
  for(argc = 0; argv[argc]; argc++) {
80100d0d:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80100d14:	e9 2e 01 00 00       	jmp    80100e47 <exec+0x358>
    if(argc >= MAXARG)
80100d19:	83 7d e4 1f          	cmpl   $0x1f,-0x1c(%ebp)
80100d1d:	76 05                	jbe    80100d24 <exec+0x235>
      goto bad;
80100d1f:	e9 69 02 00 00       	jmp    80100f8d <exec+0x49e>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100d24:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d27:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100d2e:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d31:	01 d0                	add    %edx,%eax
80100d33:	8b 00                	mov    (%eax),%eax
80100d35:	89 04 24             	mov    %eax,(%esp)
80100d38:	e8 57 52 00 00       	call   80105f94 <strlen>
80100d3d:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100d40:	29 c2                	sub    %eax,%edx
80100d42:	89 d0                	mov    %edx,%eax
80100d44:	83 e8 01             	sub    $0x1,%eax
80100d47:	83 e0 fc             	and    $0xfffffffc,%eax
80100d4a:	89 45 dc             	mov    %eax,-0x24(%ebp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100d4d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d50:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100d57:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d5a:	01 d0                	add    %edx,%eax
80100d5c:	8b 00                	mov    (%eax),%eax
80100d5e:	89 04 24             	mov    %eax,(%esp)
80100d61:	e8 2e 52 00 00       	call   80105f94 <strlen>
80100d66:	83 c0 01             	add    $0x1,%eax
80100d69:	89 c2                	mov    %eax,%edx
80100d6b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d6e:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
80100d75:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d78:	01 c8                	add    %ecx,%eax
80100d7a:	8b 00                	mov    (%eax),%eax
80100d7c:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100d80:	89 44 24 08          	mov    %eax,0x8(%esp)
80100d84:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100d87:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d8b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d8e:	89 04 24             	mov    %eax,(%esp)
80100d91:	e8 d6 83 00 00       	call   8010916c <copyout>
80100d96:	85 c0                	test   %eax,%eax
80100d98:	79 05                	jns    80100d9f <exec+0x2b0>
      goto bad;
80100d9a:	e9 ee 01 00 00       	jmp    80100f8d <exec+0x49e>
    //take the args from stack into proc struc
    
    memmove(proc->cmdline + cmdlen, argv[argc], strlen(argv[argc]) + 1);
80100d9f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100da2:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100da9:	8b 45 0c             	mov    0xc(%ebp),%eax
80100dac:	01 d0                	add    %edx,%eax
80100dae:	8b 00                	mov    (%eax),%eax
80100db0:	89 04 24             	mov    %eax,(%esp)
80100db3:	e8 dc 51 00 00       	call   80105f94 <strlen>
80100db8:	83 c0 01             	add    $0x1,%eax
80100dbb:	89 c2                	mov    %eax,%edx
80100dbd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dc0:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
80100dc7:	8b 45 0c             	mov    0xc(%ebp),%eax
80100dca:	01 c8                	add    %ecx,%eax
80100dcc:	8b 00                	mov    (%eax),%eax
80100dce:	65 8b 0d 04 00 00 00 	mov    %gs:0x4,%ecx
80100dd5:	8b 5d d0             	mov    -0x30(%ebp),%ebx
80100dd8:	83 eb 80             	sub    $0xffffff80,%ebx
80100ddb:	01 d9                	add    %ebx,%ecx
80100ddd:	89 54 24 08          	mov    %edx,0x8(%esp)
80100de1:	89 44 24 04          	mov    %eax,0x4(%esp)
80100de5:	89 0c 24             	mov    %ecx,(%esp)
80100de8:	e8 0c 50 00 00       	call   80105df9 <memmove>
    cmdlen += strlen(argv[argc]);
80100ded:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100df0:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100df7:	8b 45 0c             	mov    0xc(%ebp),%eax
80100dfa:	01 d0                	add    %edx,%eax
80100dfc:	8b 00                	mov    (%eax),%eax
80100dfe:	89 04 24             	mov    %eax,(%esp)
80100e01:	e8 8e 51 00 00       	call   80105f94 <strlen>
80100e06:	01 45 d0             	add    %eax,-0x30(%ebp)
    memmove(proc->cmdline + cmdlen, " ", 2);	
80100e09:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e0f:	8b 55 d0             	mov    -0x30(%ebp),%edx
80100e12:	83 ea 80             	sub    $0xffffff80,%edx
80100e15:	01 d0                	add    %edx,%eax
80100e17:	c7 44 24 08 02 00 00 	movl   $0x2,0x8(%esp)
80100e1e:	00 
80100e1f:	c7 44 24 04 71 92 10 	movl   $0x80109271,0x4(%esp)
80100e26:	80 
80100e27:	89 04 24             	mov    %eax,(%esp)
80100e2a:	e8 ca 4f 00 00       	call   80105df9 <memmove>
    cmdlen +=1;
80100e2f:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
    
    ustack[3+argc] = sp;
80100e33:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e36:	8d 50 03             	lea    0x3(%eax),%edx
80100e39:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e3c:	89 84 95 3c ff ff ff 	mov    %eax,-0xc4(%ebp,%edx,4)
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  int cmdlen = 0;
  for(argc = 0; argv[argc]; argc++) {
80100e43:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80100e47:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e4a:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100e51:	8b 45 0c             	mov    0xc(%ebp),%eax
80100e54:	01 d0                	add    %edx,%eax
80100e56:	8b 00                	mov    (%eax),%eax
80100e58:	85 c0                	test   %eax,%eax
80100e5a:	0f 85 b9 fe ff ff    	jne    80100d19 <exec+0x22a>
    ustack[3+argc] = sp;
  }
  //cprintf("%s\n", proc->cmdline);
  
  //proc->argc=argc;				//~yoed
  ustack[3+argc] = 0;
80100e60:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e63:	83 c0 03             	add    $0x3,%eax
80100e66:	c7 84 85 3c ff ff ff 	movl   $0x0,-0xc4(%ebp,%eax,4)
80100e6d:	00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
80100e71:	c7 85 3c ff ff ff ff 	movl   $0xffffffff,-0xc4(%ebp)
80100e78:	ff ff ff 
  ustack[1] = argc;
80100e7b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e7e:	89 85 40 ff ff ff    	mov    %eax,-0xc0(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100e84:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e87:	83 c0 01             	add    $0x1,%eax
80100e8a:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100e91:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e94:	29 d0                	sub    %edx,%eax
80100e96:	89 85 44 ff ff ff    	mov    %eax,-0xbc(%ebp)

  sp -= (3+argc+1) * 4;
80100e9c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e9f:	83 c0 04             	add    $0x4,%eax
80100ea2:	c1 e0 02             	shl    $0x2,%eax
80100ea5:	29 45 dc             	sub    %eax,-0x24(%ebp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100ea8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100eab:	83 c0 04             	add    $0x4,%eax
80100eae:	c1 e0 02             	shl    $0x2,%eax
80100eb1:	89 44 24 0c          	mov    %eax,0xc(%esp)
80100eb5:	8d 85 3c ff ff ff    	lea    -0xc4(%ebp),%eax
80100ebb:	89 44 24 08          	mov    %eax,0x8(%esp)
80100ebf:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100ec2:	89 44 24 04          	mov    %eax,0x4(%esp)
80100ec6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100ec9:	89 04 24             	mov    %eax,(%esp)
80100ecc:	e8 9b 82 00 00       	call   8010916c <copyout>
80100ed1:	85 c0                	test   %eax,%eax
80100ed3:	79 05                	jns    80100eda <exec+0x3eb>
    goto bad;
80100ed5:	e9 b3 00 00 00       	jmp    80100f8d <exec+0x49e>

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100eda:	8b 45 08             	mov    0x8(%ebp),%eax
80100edd:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100ee0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100ee3:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100ee6:	eb 17                	jmp    80100eff <exec+0x410>
    if(*s == '/')
80100ee8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100eeb:	0f b6 00             	movzbl (%eax),%eax
80100eee:	3c 2f                	cmp    $0x2f,%al
80100ef0:	75 09                	jne    80100efb <exec+0x40c>
      last = s+1;
80100ef2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100ef5:	83 c0 01             	add    $0x1,%eax
80100ef8:	89 45 f0             	mov    %eax,-0x10(%ebp)
  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100efb:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100eff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f02:	0f b6 00             	movzbl (%eax),%eax
80100f05:	84 c0                	test   %al,%al
80100f07:	75 df                	jne    80100ee8 <exec+0x3f9>
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
80100f09:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f0f:	8d 50 6c             	lea    0x6c(%eax),%edx
80100f12:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80100f19:	00 
80100f1a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100f1d:	89 44 24 04          	mov    %eax,0x4(%esp)
80100f21:	89 14 24             	mov    %edx,(%esp)
80100f24:	e8 21 50 00 00       	call   80105f4a <safestrcpy>

  // Commit to the user image.
  oldpgdir = proc->pgdir;
80100f29:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f2f:	8b 40 04             	mov    0x4(%eax),%eax
80100f32:	89 45 cc             	mov    %eax,-0x34(%ebp)
  proc->pgdir = pgdir;
80100f35:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f3b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80100f3e:	89 50 04             	mov    %edx,0x4(%eax)
  proc->sz = sz;
80100f41:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f47:	8b 55 e0             	mov    -0x20(%ebp),%edx
80100f4a:	89 10                	mov    %edx,(%eax)
  proc->tf->eip = elf.entry;  // main
80100f4c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f52:	8b 40 18             	mov    0x18(%eax),%eax
80100f55:	8b 95 20 ff ff ff    	mov    -0xe0(%ebp),%edx
80100f5b:	89 50 38             	mov    %edx,0x38(%eax)
  proc->tf->esp = sp;
80100f5e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f64:	8b 40 18             	mov    0x18(%eax),%eax
80100f67:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100f6a:	89 50 44             	mov    %edx,0x44(%eax)
  switchuvm(proc);
80100f6d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f73:	89 04 24             	mov    %eax,(%esp)
80100f76:	e8 1f 7b 00 00       	call   80108a9a <switchuvm>
  freevm(oldpgdir);
80100f7b:	8b 45 cc             	mov    -0x34(%ebp),%eax
80100f7e:	89 04 24             	mov    %eax,(%esp)
80100f81:	e8 87 7f 00 00       	call   80108f0d <freevm>
  return 0;
80100f86:	b8 00 00 00 00       	mov    $0x0,%eax
80100f8b:	eb 2c                	jmp    80100fb9 <exec+0x4ca>

 bad:
  if(pgdir)
80100f8d:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100f91:	74 0b                	je     80100f9e <exec+0x4af>
    freevm(pgdir);
80100f93:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100f96:	89 04 24             	mov    %eax,(%esp)
80100f99:	e8 6f 7f 00 00       	call   80108f0d <freevm>
  if(ip){
80100f9e:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100fa2:	74 10                	je     80100fb4 <exec+0x4c5>
    iunlockput(ip);
80100fa4:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100fa7:	89 04 24             	mov    %eax,(%esp)
80100faa:	e8 e8 0b 00 00       	call   80101b97 <iunlockput>
    end_op();
80100faf:	e8 b3 26 00 00       	call   80103667 <end_op>
  }
  return -1;
80100fb4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100fb9:	81 c4 34 01 00 00    	add    $0x134,%esp
80100fbf:	5b                   	pop    %ebx
80100fc0:	5d                   	pop    %ebp
80100fc1:	c3                   	ret    

80100fc2 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100fc2:	55                   	push   %ebp
80100fc3:	89 e5                	mov    %esp,%ebp
80100fc5:	83 ec 18             	sub    $0x18,%esp
  initlock(&ftable.lock, "ftable");
80100fc8:	c7 44 24 04 73 92 10 	movl   $0x80109273,0x4(%esp)
80100fcf:	80 
80100fd0:	c7 04 24 60 18 11 80 	movl   $0x80111860,(%esp)
80100fd7:	e8 d9 4a 00 00       	call   80105ab5 <initlock>
}
80100fdc:	c9                   	leave  
80100fdd:	c3                   	ret    

80100fde <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100fde:	55                   	push   %ebp
80100fdf:	89 e5                	mov    %esp,%ebp
80100fe1:	83 ec 28             	sub    $0x28,%esp
  struct file *f;

  acquire(&ftable.lock);
80100fe4:	c7 04 24 60 18 11 80 	movl   $0x80111860,(%esp)
80100feb:	e8 e6 4a 00 00       	call   80105ad6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100ff0:	c7 45 f4 94 18 11 80 	movl   $0x80111894,-0xc(%ebp)
80100ff7:	eb 29                	jmp    80101022 <filealloc+0x44>
    if(f->ref == 0){
80100ff9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100ffc:	8b 40 04             	mov    0x4(%eax),%eax
80100fff:	85 c0                	test   %eax,%eax
80101001:	75 1b                	jne    8010101e <filealloc+0x40>
      f->ref = 1;
80101003:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101006:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
      release(&ftable.lock);
8010100d:	c7 04 24 60 18 11 80 	movl   $0x80111860,(%esp)
80101014:	e8 1f 4b 00 00       	call   80105b38 <release>
      return f;
80101019:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010101c:	eb 1e                	jmp    8010103c <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
8010101e:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
80101022:	81 7d f4 f4 21 11 80 	cmpl   $0x801121f4,-0xc(%ebp)
80101029:	72 ce                	jb     80100ff9 <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
8010102b:	c7 04 24 60 18 11 80 	movl   $0x80111860,(%esp)
80101032:	e8 01 4b 00 00       	call   80105b38 <release>
  return 0;
80101037:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010103c:	c9                   	leave  
8010103d:	c3                   	ret    

8010103e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
8010103e:	55                   	push   %ebp
8010103f:	89 e5                	mov    %esp,%ebp
80101041:	83 ec 18             	sub    $0x18,%esp
  acquire(&ftable.lock);
80101044:	c7 04 24 60 18 11 80 	movl   $0x80111860,(%esp)
8010104b:	e8 86 4a 00 00       	call   80105ad6 <acquire>
  if(f->ref < 1)
80101050:	8b 45 08             	mov    0x8(%ebp),%eax
80101053:	8b 40 04             	mov    0x4(%eax),%eax
80101056:	85 c0                	test   %eax,%eax
80101058:	7f 0c                	jg     80101066 <filedup+0x28>
    panic("filedup");
8010105a:	c7 04 24 7a 92 10 80 	movl   $0x8010927a,(%esp)
80101061:	e8 d4 f4 ff ff       	call   8010053a <panic>
  f->ref++;
80101066:	8b 45 08             	mov    0x8(%ebp),%eax
80101069:	8b 40 04             	mov    0x4(%eax),%eax
8010106c:	8d 50 01             	lea    0x1(%eax),%edx
8010106f:	8b 45 08             	mov    0x8(%ebp),%eax
80101072:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80101075:	c7 04 24 60 18 11 80 	movl   $0x80111860,(%esp)
8010107c:	e8 b7 4a 00 00       	call   80105b38 <release>
  return f;
80101081:	8b 45 08             	mov    0x8(%ebp),%eax
}
80101084:	c9                   	leave  
80101085:	c3                   	ret    

80101086 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
80101086:	55                   	push   %ebp
80101087:	89 e5                	mov    %esp,%ebp
80101089:	83 ec 38             	sub    $0x38,%esp
  struct file ff;

  acquire(&ftable.lock);
8010108c:	c7 04 24 60 18 11 80 	movl   $0x80111860,(%esp)
80101093:	e8 3e 4a 00 00       	call   80105ad6 <acquire>
  if(f->ref < 1)
80101098:	8b 45 08             	mov    0x8(%ebp),%eax
8010109b:	8b 40 04             	mov    0x4(%eax),%eax
8010109e:	85 c0                	test   %eax,%eax
801010a0:	7f 0c                	jg     801010ae <fileclose+0x28>
    panic("fileclose");
801010a2:	c7 04 24 82 92 10 80 	movl   $0x80109282,(%esp)
801010a9:	e8 8c f4 ff ff       	call   8010053a <panic>
  if(--f->ref > 0){
801010ae:	8b 45 08             	mov    0x8(%ebp),%eax
801010b1:	8b 40 04             	mov    0x4(%eax),%eax
801010b4:	8d 50 ff             	lea    -0x1(%eax),%edx
801010b7:	8b 45 08             	mov    0x8(%ebp),%eax
801010ba:	89 50 04             	mov    %edx,0x4(%eax)
801010bd:	8b 45 08             	mov    0x8(%ebp),%eax
801010c0:	8b 40 04             	mov    0x4(%eax),%eax
801010c3:	85 c0                	test   %eax,%eax
801010c5:	7e 11                	jle    801010d8 <fileclose+0x52>
    release(&ftable.lock);
801010c7:	c7 04 24 60 18 11 80 	movl   $0x80111860,(%esp)
801010ce:	e8 65 4a 00 00       	call   80105b38 <release>
801010d3:	e9 82 00 00 00       	jmp    8010115a <fileclose+0xd4>
    return;
  }
  ff = *f;
801010d8:	8b 45 08             	mov    0x8(%ebp),%eax
801010db:	8b 10                	mov    (%eax),%edx
801010dd:	89 55 e0             	mov    %edx,-0x20(%ebp)
801010e0:	8b 50 04             	mov    0x4(%eax),%edx
801010e3:	89 55 e4             	mov    %edx,-0x1c(%ebp)
801010e6:	8b 50 08             	mov    0x8(%eax),%edx
801010e9:	89 55 e8             	mov    %edx,-0x18(%ebp)
801010ec:	8b 50 0c             	mov    0xc(%eax),%edx
801010ef:	89 55 ec             	mov    %edx,-0x14(%ebp)
801010f2:	8b 50 10             	mov    0x10(%eax),%edx
801010f5:	89 55 f0             	mov    %edx,-0x10(%ebp)
801010f8:	8b 40 14             	mov    0x14(%eax),%eax
801010fb:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
801010fe:	8b 45 08             	mov    0x8(%ebp),%eax
80101101:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  f->type = FD_NONE;
80101108:	8b 45 08             	mov    0x8(%ebp),%eax
8010110b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  release(&ftable.lock);
80101111:	c7 04 24 60 18 11 80 	movl   $0x80111860,(%esp)
80101118:	e8 1b 4a 00 00       	call   80105b38 <release>
  
  if(ff.type == FD_PIPE)
8010111d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101120:	83 f8 01             	cmp    $0x1,%eax
80101123:	75 18                	jne    8010113d <fileclose+0xb7>
    pipeclose(ff.pipe, ff.writable);
80101125:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
80101129:	0f be d0             	movsbl %al,%edx
8010112c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010112f:	89 54 24 04          	mov    %edx,0x4(%esp)
80101133:	89 04 24             	mov    %eax,(%esp)
80101136:	e8 01 31 00 00       	call   8010423c <pipeclose>
8010113b:	eb 1d                	jmp    8010115a <fileclose+0xd4>
  else if(ff.type == FD_INODE){
8010113d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101140:	83 f8 02             	cmp    $0x2,%eax
80101143:	75 15                	jne    8010115a <fileclose+0xd4>
    begin_op();
80101145:	e8 99 24 00 00       	call   801035e3 <begin_op>
    iput(ff.ip);
8010114a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010114d:	89 04 24             	mov    %eax,(%esp)
80101150:	e8 71 09 00 00       	call   80101ac6 <iput>
    end_op();
80101155:	e8 0d 25 00 00       	call   80103667 <end_op>
  }
}
8010115a:	c9                   	leave  
8010115b:	c3                   	ret    

8010115c <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
8010115c:	55                   	push   %ebp
8010115d:	89 e5                	mov    %esp,%ebp
8010115f:	83 ec 18             	sub    $0x18,%esp
  if(f->type == FD_INODE){
80101162:	8b 45 08             	mov    0x8(%ebp),%eax
80101165:	8b 00                	mov    (%eax),%eax
80101167:	83 f8 02             	cmp    $0x2,%eax
8010116a:	75 38                	jne    801011a4 <filestat+0x48>
    ilock(f->ip);
8010116c:	8b 45 08             	mov    0x8(%ebp),%eax
8010116f:	8b 40 10             	mov    0x10(%eax),%eax
80101172:	89 04 24             	mov    %eax,(%esp)
80101175:	e8 99 07 00 00       	call   80101913 <ilock>
    stati(f->ip, st);
8010117a:	8b 45 08             	mov    0x8(%ebp),%eax
8010117d:	8b 40 10             	mov    0x10(%eax),%eax
80101180:	8b 55 0c             	mov    0xc(%ebp),%edx
80101183:	89 54 24 04          	mov    %edx,0x4(%esp)
80101187:	89 04 24             	mov    %eax,(%esp)
8010118a:	e8 4c 0c 00 00       	call   80101ddb <stati>
    iunlock(f->ip);
8010118f:	8b 45 08             	mov    0x8(%ebp),%eax
80101192:	8b 40 10             	mov    0x10(%eax),%eax
80101195:	89 04 24             	mov    %eax,(%esp)
80101198:	e8 c4 08 00 00       	call   80101a61 <iunlock>
    return 0;
8010119d:	b8 00 00 00 00       	mov    $0x0,%eax
801011a2:	eb 05                	jmp    801011a9 <filestat+0x4d>
  }
  return -1;
801011a4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801011a9:	c9                   	leave  
801011aa:	c3                   	ret    

801011ab <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
801011ab:	55                   	push   %ebp
801011ac:	89 e5                	mov    %esp,%ebp
801011ae:	83 ec 28             	sub    $0x28,%esp
  int r;

  if(f->readable == 0)
801011b1:	8b 45 08             	mov    0x8(%ebp),%eax
801011b4:	0f b6 40 08          	movzbl 0x8(%eax),%eax
801011b8:	84 c0                	test   %al,%al
801011ba:	75 0a                	jne    801011c6 <fileread+0x1b>
    return -1;
801011bc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801011c1:	e9 9f 00 00 00       	jmp    80101265 <fileread+0xba>
  if(f->type == FD_PIPE)
801011c6:	8b 45 08             	mov    0x8(%ebp),%eax
801011c9:	8b 00                	mov    (%eax),%eax
801011cb:	83 f8 01             	cmp    $0x1,%eax
801011ce:	75 1e                	jne    801011ee <fileread+0x43>
    return piperead(f->pipe, addr, n);
801011d0:	8b 45 08             	mov    0x8(%ebp),%eax
801011d3:	8b 40 0c             	mov    0xc(%eax),%eax
801011d6:	8b 55 10             	mov    0x10(%ebp),%edx
801011d9:	89 54 24 08          	mov    %edx,0x8(%esp)
801011dd:	8b 55 0c             	mov    0xc(%ebp),%edx
801011e0:	89 54 24 04          	mov    %edx,0x4(%esp)
801011e4:	89 04 24             	mov    %eax,(%esp)
801011e7:	e8 d1 31 00 00       	call   801043bd <piperead>
801011ec:	eb 77                	jmp    80101265 <fileread+0xba>
  if(f->type == FD_INODE){
801011ee:	8b 45 08             	mov    0x8(%ebp),%eax
801011f1:	8b 00                	mov    (%eax),%eax
801011f3:	83 f8 02             	cmp    $0x2,%eax
801011f6:	75 61                	jne    80101259 <fileread+0xae>
    ilock(f->ip);
801011f8:	8b 45 08             	mov    0x8(%ebp),%eax
801011fb:	8b 40 10             	mov    0x10(%eax),%eax
801011fe:	89 04 24             	mov    %eax,(%esp)
80101201:	e8 0d 07 00 00       	call   80101913 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
80101206:	8b 4d 10             	mov    0x10(%ebp),%ecx
80101209:	8b 45 08             	mov    0x8(%ebp),%eax
8010120c:	8b 50 14             	mov    0x14(%eax),%edx
8010120f:	8b 45 08             	mov    0x8(%ebp),%eax
80101212:	8b 40 10             	mov    0x10(%eax),%eax
80101215:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101219:	89 54 24 08          	mov    %edx,0x8(%esp)
8010121d:	8b 55 0c             	mov    0xc(%ebp),%edx
80101220:	89 54 24 04          	mov    %edx,0x4(%esp)
80101224:	89 04 24             	mov    %eax,(%esp)
80101227:	e8 f4 0b 00 00       	call   80101e20 <readi>
8010122c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010122f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101233:	7e 11                	jle    80101246 <fileread+0x9b>
      f->off += r;
80101235:	8b 45 08             	mov    0x8(%ebp),%eax
80101238:	8b 50 14             	mov    0x14(%eax),%edx
8010123b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010123e:	01 c2                	add    %eax,%edx
80101240:	8b 45 08             	mov    0x8(%ebp),%eax
80101243:	89 50 14             	mov    %edx,0x14(%eax)
    iunlock(f->ip);
80101246:	8b 45 08             	mov    0x8(%ebp),%eax
80101249:	8b 40 10             	mov    0x10(%eax),%eax
8010124c:	89 04 24             	mov    %eax,(%esp)
8010124f:	e8 0d 08 00 00       	call   80101a61 <iunlock>
    return r;
80101254:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101257:	eb 0c                	jmp    80101265 <fileread+0xba>
  }
  panic("fileread");
80101259:	c7 04 24 8c 92 10 80 	movl   $0x8010928c,(%esp)
80101260:	e8 d5 f2 ff ff       	call   8010053a <panic>
}
80101265:	c9                   	leave  
80101266:	c3                   	ret    

80101267 <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
80101267:	55                   	push   %ebp
80101268:	89 e5                	mov    %esp,%ebp
8010126a:	53                   	push   %ebx
8010126b:	83 ec 24             	sub    $0x24,%esp
  int r;

  if(f->writable == 0)
8010126e:	8b 45 08             	mov    0x8(%ebp),%eax
80101271:	0f b6 40 09          	movzbl 0x9(%eax),%eax
80101275:	84 c0                	test   %al,%al
80101277:	75 0a                	jne    80101283 <filewrite+0x1c>
    return -1;
80101279:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010127e:	e9 20 01 00 00       	jmp    801013a3 <filewrite+0x13c>
  if(f->type == FD_PIPE)
80101283:	8b 45 08             	mov    0x8(%ebp),%eax
80101286:	8b 00                	mov    (%eax),%eax
80101288:	83 f8 01             	cmp    $0x1,%eax
8010128b:	75 21                	jne    801012ae <filewrite+0x47>
    return pipewrite(f->pipe, addr, n);
8010128d:	8b 45 08             	mov    0x8(%ebp),%eax
80101290:	8b 40 0c             	mov    0xc(%eax),%eax
80101293:	8b 55 10             	mov    0x10(%ebp),%edx
80101296:	89 54 24 08          	mov    %edx,0x8(%esp)
8010129a:	8b 55 0c             	mov    0xc(%ebp),%edx
8010129d:	89 54 24 04          	mov    %edx,0x4(%esp)
801012a1:	89 04 24             	mov    %eax,(%esp)
801012a4:	e8 25 30 00 00       	call   801042ce <pipewrite>
801012a9:	e9 f5 00 00 00       	jmp    801013a3 <filewrite+0x13c>
  if(f->type == FD_INODE){
801012ae:	8b 45 08             	mov    0x8(%ebp),%eax
801012b1:	8b 00                	mov    (%eax),%eax
801012b3:	83 f8 02             	cmp    $0x2,%eax
801012b6:	0f 85 db 00 00 00    	jne    80101397 <filewrite+0x130>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
801012bc:	c7 45 ec 00 1a 00 00 	movl   $0x1a00,-0x14(%ebp)
    int i = 0;
801012c3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while(i < n){
801012ca:	e9 a8 00 00 00       	jmp    80101377 <filewrite+0x110>
      int n1 = n - i;
801012cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012d2:	8b 55 10             	mov    0x10(%ebp),%edx
801012d5:	29 c2                	sub    %eax,%edx
801012d7:	89 d0                	mov    %edx,%eax
801012d9:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(n1 > max)
801012dc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801012df:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801012e2:	7e 06                	jle    801012ea <filewrite+0x83>
        n1 = max;
801012e4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801012e7:	89 45 f0             	mov    %eax,-0x10(%ebp)

      begin_op();
801012ea:	e8 f4 22 00 00       	call   801035e3 <begin_op>
      ilock(f->ip);
801012ef:	8b 45 08             	mov    0x8(%ebp),%eax
801012f2:	8b 40 10             	mov    0x10(%eax),%eax
801012f5:	89 04 24             	mov    %eax,(%esp)
801012f8:	e8 16 06 00 00       	call   80101913 <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
801012fd:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80101300:	8b 45 08             	mov    0x8(%ebp),%eax
80101303:	8b 50 14             	mov    0x14(%eax),%edx
80101306:	8b 5d f4             	mov    -0xc(%ebp),%ebx
80101309:	8b 45 0c             	mov    0xc(%ebp),%eax
8010130c:	01 c3                	add    %eax,%ebx
8010130e:	8b 45 08             	mov    0x8(%ebp),%eax
80101311:	8b 40 10             	mov    0x10(%eax),%eax
80101314:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101318:	89 54 24 08          	mov    %edx,0x8(%esp)
8010131c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
80101320:	89 04 24             	mov    %eax,(%esp)
80101323:	e8 69 0c 00 00       	call   80101f91 <writei>
80101328:	89 45 e8             	mov    %eax,-0x18(%ebp)
8010132b:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010132f:	7e 11                	jle    80101342 <filewrite+0xdb>
        f->off += r;
80101331:	8b 45 08             	mov    0x8(%ebp),%eax
80101334:	8b 50 14             	mov    0x14(%eax),%edx
80101337:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010133a:	01 c2                	add    %eax,%edx
8010133c:	8b 45 08             	mov    0x8(%ebp),%eax
8010133f:	89 50 14             	mov    %edx,0x14(%eax)
      iunlock(f->ip);
80101342:	8b 45 08             	mov    0x8(%ebp),%eax
80101345:	8b 40 10             	mov    0x10(%eax),%eax
80101348:	89 04 24             	mov    %eax,(%esp)
8010134b:	e8 11 07 00 00       	call   80101a61 <iunlock>
      end_op();
80101350:	e8 12 23 00 00       	call   80103667 <end_op>

      if(r < 0)
80101355:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101359:	79 02                	jns    8010135d <filewrite+0xf6>
        break;
8010135b:	eb 26                	jmp    80101383 <filewrite+0x11c>
      if(r != n1)
8010135d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101360:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80101363:	74 0c                	je     80101371 <filewrite+0x10a>
        panic("short filewrite");
80101365:	c7 04 24 95 92 10 80 	movl   $0x80109295,(%esp)
8010136c:	e8 c9 f1 ff ff       	call   8010053a <panic>
      i += r;
80101371:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101374:	01 45 f4             	add    %eax,-0xc(%ebp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
80101377:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010137a:	3b 45 10             	cmp    0x10(%ebp),%eax
8010137d:	0f 8c 4c ff ff ff    	jl     801012cf <filewrite+0x68>
        break;
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
80101383:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101386:	3b 45 10             	cmp    0x10(%ebp),%eax
80101389:	75 05                	jne    80101390 <filewrite+0x129>
8010138b:	8b 45 10             	mov    0x10(%ebp),%eax
8010138e:	eb 05                	jmp    80101395 <filewrite+0x12e>
80101390:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101395:	eb 0c                	jmp    801013a3 <filewrite+0x13c>
  }
  panic("filewrite");
80101397:	c7 04 24 a5 92 10 80 	movl   $0x801092a5,(%esp)
8010139e:	e8 97 f1 ff ff       	call   8010053a <panic>
}
801013a3:	83 c4 24             	add    $0x24,%esp
801013a6:	5b                   	pop    %ebx
801013a7:	5d                   	pop    %ebp
801013a8:	c3                   	ret    

801013a9 <readsb>:
static void itrunc(struct inode*);

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
801013a9:	55                   	push   %ebp
801013aa:	89 e5                	mov    %esp,%ebp
801013ac:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
801013af:	8b 45 08             	mov    0x8(%ebp),%eax
801013b2:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801013b9:	00 
801013ba:	89 04 24             	mov    %eax,(%esp)
801013bd:	e8 e4 ed ff ff       	call   801001a6 <bread>
801013c2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
801013c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013c8:	83 c0 18             	add    $0x18,%eax
801013cb:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801013d2:	00 
801013d3:	89 44 24 04          	mov    %eax,0x4(%esp)
801013d7:	8b 45 0c             	mov    0xc(%ebp),%eax
801013da:	89 04 24             	mov    %eax,(%esp)
801013dd:	e8 17 4a 00 00       	call   80105df9 <memmove>
  brelse(bp);
801013e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013e5:	89 04 24             	mov    %eax,(%esp)
801013e8:	e8 2a ee ff ff       	call   80100217 <brelse>
}
801013ed:	c9                   	leave  
801013ee:	c3                   	ret    

801013ef <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
801013ef:	55                   	push   %ebp
801013f0:	89 e5                	mov    %esp,%ebp
801013f2:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
801013f5:	8b 55 0c             	mov    0xc(%ebp),%edx
801013f8:	8b 45 08             	mov    0x8(%ebp),%eax
801013fb:	89 54 24 04          	mov    %edx,0x4(%esp)
801013ff:	89 04 24             	mov    %eax,(%esp)
80101402:	e8 9f ed ff ff       	call   801001a6 <bread>
80101407:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
8010140a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010140d:	83 c0 18             	add    $0x18,%eax
80101410:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80101417:	00 
80101418:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010141f:	00 
80101420:	89 04 24             	mov    %eax,(%esp)
80101423:	e8 02 49 00 00       	call   80105d2a <memset>
  log_write(bp);
80101428:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010142b:	89 04 24             	mov    %eax,(%esp)
8010142e:	e8 bb 23 00 00       	call   801037ee <log_write>
  brelse(bp);
80101433:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101436:	89 04 24             	mov    %eax,(%esp)
80101439:	e8 d9 ed ff ff       	call   80100217 <brelse>
}
8010143e:	c9                   	leave  
8010143f:	c3                   	ret    

80101440 <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
80101440:	55                   	push   %ebp
80101441:	89 e5                	mov    %esp,%ebp
80101443:	83 ec 38             	sub    $0x38,%esp
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
80101446:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  readsb(dev, &sb);
8010144d:	8b 45 08             	mov    0x8(%ebp),%eax
80101450:	8d 55 d8             	lea    -0x28(%ebp),%edx
80101453:	89 54 24 04          	mov    %edx,0x4(%esp)
80101457:	89 04 24             	mov    %eax,(%esp)
8010145a:	e8 4a ff ff ff       	call   801013a9 <readsb>
  for(b = 0; b < sb.size; b += BPB){
8010145f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101466:	e9 07 01 00 00       	jmp    80101572 <balloc+0x132>
    bp = bread(dev, BBLOCK(b, sb.ninodes));
8010146b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010146e:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
80101474:	85 c0                	test   %eax,%eax
80101476:	0f 48 c2             	cmovs  %edx,%eax
80101479:	c1 f8 0c             	sar    $0xc,%eax
8010147c:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010147f:	c1 ea 03             	shr    $0x3,%edx
80101482:	01 d0                	add    %edx,%eax
80101484:	83 c0 03             	add    $0x3,%eax
80101487:	89 44 24 04          	mov    %eax,0x4(%esp)
8010148b:	8b 45 08             	mov    0x8(%ebp),%eax
8010148e:	89 04 24             	mov    %eax,(%esp)
80101491:	e8 10 ed ff ff       	call   801001a6 <bread>
80101496:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101499:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801014a0:	e9 9d 00 00 00       	jmp    80101542 <balloc+0x102>
      m = 1 << (bi % 8);
801014a5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014a8:	99                   	cltd   
801014a9:	c1 ea 1d             	shr    $0x1d,%edx
801014ac:	01 d0                	add    %edx,%eax
801014ae:	83 e0 07             	and    $0x7,%eax
801014b1:	29 d0                	sub    %edx,%eax
801014b3:	ba 01 00 00 00       	mov    $0x1,%edx
801014b8:	89 c1                	mov    %eax,%ecx
801014ba:	d3 e2                	shl    %cl,%edx
801014bc:	89 d0                	mov    %edx,%eax
801014be:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
801014c1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014c4:	8d 50 07             	lea    0x7(%eax),%edx
801014c7:	85 c0                	test   %eax,%eax
801014c9:	0f 48 c2             	cmovs  %edx,%eax
801014cc:	c1 f8 03             	sar    $0x3,%eax
801014cf:	8b 55 ec             	mov    -0x14(%ebp),%edx
801014d2:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
801014d7:	0f b6 c0             	movzbl %al,%eax
801014da:	23 45 e8             	and    -0x18(%ebp),%eax
801014dd:	85 c0                	test   %eax,%eax
801014df:	75 5d                	jne    8010153e <balloc+0xfe>
        bp->data[bi/8] |= m;  // Mark block in use.
801014e1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014e4:	8d 50 07             	lea    0x7(%eax),%edx
801014e7:	85 c0                	test   %eax,%eax
801014e9:	0f 48 c2             	cmovs  %edx,%eax
801014ec:	c1 f8 03             	sar    $0x3,%eax
801014ef:	8b 55 ec             	mov    -0x14(%ebp),%edx
801014f2:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
801014f7:	89 d1                	mov    %edx,%ecx
801014f9:	8b 55 e8             	mov    -0x18(%ebp),%edx
801014fc:	09 ca                	or     %ecx,%edx
801014fe:	89 d1                	mov    %edx,%ecx
80101500:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101503:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
80101507:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010150a:	89 04 24             	mov    %eax,(%esp)
8010150d:	e8 dc 22 00 00       	call   801037ee <log_write>
        brelse(bp);
80101512:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101515:	89 04 24             	mov    %eax,(%esp)
80101518:	e8 fa ec ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
8010151d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101520:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101523:	01 c2                	add    %eax,%edx
80101525:	8b 45 08             	mov    0x8(%ebp),%eax
80101528:	89 54 24 04          	mov    %edx,0x4(%esp)
8010152c:	89 04 24             	mov    %eax,(%esp)
8010152f:	e8 bb fe ff ff       	call   801013ef <bzero>
        return b + bi;
80101534:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101537:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010153a:	01 d0                	add    %edx,%eax
8010153c:	eb 4e                	jmp    8010158c <balloc+0x14c>

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
8010153e:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101542:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
80101549:	7f 15                	jg     80101560 <balloc+0x120>
8010154b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010154e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101551:	01 d0                	add    %edx,%eax
80101553:	89 c2                	mov    %eax,%edx
80101555:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101558:	39 c2                	cmp    %eax,%edx
8010155a:	0f 82 45 ff ff ff    	jb     801014a5 <balloc+0x65>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
80101560:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101563:	89 04 24             	mov    %eax,(%esp)
80101566:	e8 ac ec ff ff       	call   80100217 <brelse>
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
8010156b:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80101572:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101575:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101578:	39 c2                	cmp    %eax,%edx
8010157a:	0f 82 eb fe ff ff    	jb     8010146b <balloc+0x2b>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
80101580:	c7 04 24 af 92 10 80 	movl   $0x801092af,(%esp)
80101587:	e8 ae ef ff ff       	call   8010053a <panic>
}
8010158c:	c9                   	leave  
8010158d:	c3                   	ret    

8010158e <bfree>:

// Free a disk block.
static void
bfree(int dev, uint b)
{
8010158e:	55                   	push   %ebp
8010158f:	89 e5                	mov    %esp,%ebp
80101591:	83 ec 38             	sub    $0x38,%esp
  struct buf *bp;
  struct superblock sb;
  int bi, m;

  readsb(dev, &sb);
80101594:	8d 45 dc             	lea    -0x24(%ebp),%eax
80101597:	89 44 24 04          	mov    %eax,0x4(%esp)
8010159b:	8b 45 08             	mov    0x8(%ebp),%eax
8010159e:	89 04 24             	mov    %eax,(%esp)
801015a1:	e8 03 fe ff ff       	call   801013a9 <readsb>
  bp = bread(dev, BBLOCK(b, sb.ninodes));
801015a6:	8b 45 0c             	mov    0xc(%ebp),%eax
801015a9:	c1 e8 0c             	shr    $0xc,%eax
801015ac:	89 c2                	mov    %eax,%edx
801015ae:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801015b1:	c1 e8 03             	shr    $0x3,%eax
801015b4:	01 d0                	add    %edx,%eax
801015b6:	8d 50 03             	lea    0x3(%eax),%edx
801015b9:	8b 45 08             	mov    0x8(%ebp),%eax
801015bc:	89 54 24 04          	mov    %edx,0x4(%esp)
801015c0:	89 04 24             	mov    %eax,(%esp)
801015c3:	e8 de eb ff ff       	call   801001a6 <bread>
801015c8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
801015cb:	8b 45 0c             	mov    0xc(%ebp),%eax
801015ce:	25 ff 0f 00 00       	and    $0xfff,%eax
801015d3:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
801015d6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801015d9:	99                   	cltd   
801015da:	c1 ea 1d             	shr    $0x1d,%edx
801015dd:	01 d0                	add    %edx,%eax
801015df:	83 e0 07             	and    $0x7,%eax
801015e2:	29 d0                	sub    %edx,%eax
801015e4:	ba 01 00 00 00       	mov    $0x1,%edx
801015e9:	89 c1                	mov    %eax,%ecx
801015eb:	d3 e2                	shl    %cl,%edx
801015ed:	89 d0                	mov    %edx,%eax
801015ef:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
801015f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801015f5:	8d 50 07             	lea    0x7(%eax),%edx
801015f8:	85 c0                	test   %eax,%eax
801015fa:	0f 48 c2             	cmovs  %edx,%eax
801015fd:	c1 f8 03             	sar    $0x3,%eax
80101600:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101603:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101608:	0f b6 c0             	movzbl %al,%eax
8010160b:	23 45 ec             	and    -0x14(%ebp),%eax
8010160e:	85 c0                	test   %eax,%eax
80101610:	75 0c                	jne    8010161e <bfree+0x90>
    panic("freeing free block");
80101612:	c7 04 24 c5 92 10 80 	movl   $0x801092c5,(%esp)
80101619:	e8 1c ef ff ff       	call   8010053a <panic>
  bp->data[bi/8] &= ~m;
8010161e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101621:	8d 50 07             	lea    0x7(%eax),%edx
80101624:	85 c0                	test   %eax,%eax
80101626:	0f 48 c2             	cmovs  %edx,%eax
80101629:	c1 f8 03             	sar    $0x3,%eax
8010162c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010162f:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80101634:	8b 4d ec             	mov    -0x14(%ebp),%ecx
80101637:	f7 d1                	not    %ecx
80101639:	21 ca                	and    %ecx,%edx
8010163b:	89 d1                	mov    %edx,%ecx
8010163d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101640:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
80101644:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101647:	89 04 24             	mov    %eax,(%esp)
8010164a:	e8 9f 21 00 00       	call   801037ee <log_write>
  brelse(bp);
8010164f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101652:	89 04 24             	mov    %eax,(%esp)
80101655:	e8 bd eb ff ff       	call   80100217 <brelse>
}
8010165a:	c9                   	leave  
8010165b:	c3                   	ret    

8010165c <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(void)
{
8010165c:	55                   	push   %ebp
8010165d:	89 e5                	mov    %esp,%ebp
8010165f:	83 ec 18             	sub    $0x18,%esp
  initlock(&icache.lock, "icache");
80101662:	c7 44 24 04 d8 92 10 	movl   $0x801092d8,0x4(%esp)
80101669:	80 
8010166a:	c7 04 24 a0 22 11 80 	movl   $0x801122a0,(%esp)
80101671:	e8 3f 44 00 00       	call   80105ab5 <initlock>
}
80101676:	c9                   	leave  
80101677:	c3                   	ret    

80101678 <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
80101678:	55                   	push   %ebp
80101679:	89 e5                	mov    %esp,%ebp
8010167b:	83 ec 38             	sub    $0x38,%esp
8010167e:	8b 45 0c             	mov    0xc(%ebp),%eax
80101681:	66 89 45 d4          	mov    %ax,-0x2c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
80101685:	8b 45 08             	mov    0x8(%ebp),%eax
80101688:	8d 55 dc             	lea    -0x24(%ebp),%edx
8010168b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010168f:	89 04 24             	mov    %eax,(%esp)
80101692:	e8 12 fd ff ff       	call   801013a9 <readsb>

  for(inum = 1; inum < sb.ninodes; inum++){
80101697:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
8010169e:	e9 98 00 00 00       	jmp    8010173b <ialloc+0xc3>
    bp = bread(dev, IBLOCK(inum));
801016a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801016a6:	c1 e8 03             	shr    $0x3,%eax
801016a9:	83 c0 02             	add    $0x2,%eax
801016ac:	89 44 24 04          	mov    %eax,0x4(%esp)
801016b0:	8b 45 08             	mov    0x8(%ebp),%eax
801016b3:	89 04 24             	mov    %eax,(%esp)
801016b6:	e8 eb ea ff ff       	call   801001a6 <bread>
801016bb:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
801016be:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016c1:	8d 50 18             	lea    0x18(%eax),%edx
801016c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801016c7:	83 e0 07             	and    $0x7,%eax
801016ca:	c1 e0 06             	shl    $0x6,%eax
801016cd:	01 d0                	add    %edx,%eax
801016cf:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
801016d2:	8b 45 ec             	mov    -0x14(%ebp),%eax
801016d5:	0f b7 00             	movzwl (%eax),%eax
801016d8:	66 85 c0             	test   %ax,%ax
801016db:	75 4f                	jne    8010172c <ialloc+0xb4>
      memset(dip, 0, sizeof(*dip));
801016dd:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
801016e4:	00 
801016e5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801016ec:	00 
801016ed:	8b 45 ec             	mov    -0x14(%ebp),%eax
801016f0:	89 04 24             	mov    %eax,(%esp)
801016f3:	e8 32 46 00 00       	call   80105d2a <memset>
      dip->type = type;
801016f8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801016fb:	0f b7 55 d4          	movzwl -0x2c(%ebp),%edx
801016ff:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
80101702:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101705:	89 04 24             	mov    %eax,(%esp)
80101708:	e8 e1 20 00 00       	call   801037ee <log_write>
      brelse(bp);
8010170d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101710:	89 04 24             	mov    %eax,(%esp)
80101713:	e8 ff ea ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
80101718:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010171b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010171f:	8b 45 08             	mov    0x8(%ebp),%eax
80101722:	89 04 24             	mov    %eax,(%esp)
80101725:	e8 e5 00 00 00       	call   8010180f <iget>
8010172a:	eb 29                	jmp    80101755 <ialloc+0xdd>
    }
    brelse(bp);
8010172c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010172f:	89 04 24             	mov    %eax,(%esp)
80101732:	e8 e0 ea ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);

  for(inum = 1; inum < sb.ninodes; inum++){
80101737:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010173b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010173e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101741:	39 c2                	cmp    %eax,%edx
80101743:	0f 82 5a ff ff ff    	jb     801016a3 <ialloc+0x2b>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
80101749:	c7 04 24 df 92 10 80 	movl   $0x801092df,(%esp)
80101750:	e8 e5 ed ff ff       	call   8010053a <panic>
}
80101755:	c9                   	leave  
80101756:	c3                   	ret    

80101757 <iupdate>:

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
80101757:	55                   	push   %ebp
80101758:	89 e5                	mov    %esp,%ebp
8010175a:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
8010175d:	8b 45 08             	mov    0x8(%ebp),%eax
80101760:	8b 40 04             	mov    0x4(%eax),%eax
80101763:	c1 e8 03             	shr    $0x3,%eax
80101766:	8d 50 02             	lea    0x2(%eax),%edx
80101769:	8b 45 08             	mov    0x8(%ebp),%eax
8010176c:	8b 00                	mov    (%eax),%eax
8010176e:	89 54 24 04          	mov    %edx,0x4(%esp)
80101772:	89 04 24             	mov    %eax,(%esp)
80101775:	e8 2c ea ff ff       	call   801001a6 <bread>
8010177a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
8010177d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101780:	8d 50 18             	lea    0x18(%eax),%edx
80101783:	8b 45 08             	mov    0x8(%ebp),%eax
80101786:	8b 40 04             	mov    0x4(%eax),%eax
80101789:	83 e0 07             	and    $0x7,%eax
8010178c:	c1 e0 06             	shl    $0x6,%eax
8010178f:	01 d0                	add    %edx,%eax
80101791:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
80101794:	8b 45 08             	mov    0x8(%ebp),%eax
80101797:	0f b7 50 10          	movzwl 0x10(%eax),%edx
8010179b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010179e:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
801017a1:	8b 45 08             	mov    0x8(%ebp),%eax
801017a4:	0f b7 50 12          	movzwl 0x12(%eax),%edx
801017a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017ab:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
801017af:	8b 45 08             	mov    0x8(%ebp),%eax
801017b2:	0f b7 50 14          	movzwl 0x14(%eax),%edx
801017b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017b9:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
801017bd:	8b 45 08             	mov    0x8(%ebp),%eax
801017c0:	0f b7 50 16          	movzwl 0x16(%eax),%edx
801017c4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017c7:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
801017cb:	8b 45 08             	mov    0x8(%ebp),%eax
801017ce:	8b 50 18             	mov    0x18(%eax),%edx
801017d1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017d4:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
801017d7:	8b 45 08             	mov    0x8(%ebp),%eax
801017da:	8d 50 1c             	lea    0x1c(%eax),%edx
801017dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017e0:	83 c0 0c             	add    $0xc,%eax
801017e3:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
801017ea:	00 
801017eb:	89 54 24 04          	mov    %edx,0x4(%esp)
801017ef:	89 04 24             	mov    %eax,(%esp)
801017f2:	e8 02 46 00 00       	call   80105df9 <memmove>
  log_write(bp);
801017f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017fa:	89 04 24             	mov    %eax,(%esp)
801017fd:	e8 ec 1f 00 00       	call   801037ee <log_write>
  brelse(bp);
80101802:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101805:	89 04 24             	mov    %eax,(%esp)
80101808:	e8 0a ea ff ff       	call   80100217 <brelse>
}
8010180d:	c9                   	leave  
8010180e:	c3                   	ret    

8010180f <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
8010180f:	55                   	push   %ebp
80101810:	89 e5                	mov    %esp,%ebp
80101812:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
80101815:	c7 04 24 a0 22 11 80 	movl   $0x801122a0,(%esp)
8010181c:	e8 b5 42 00 00       	call   80105ad6 <acquire>

  // Is the inode already cached?
  empty = 0;
80101821:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101828:	c7 45 f4 d4 22 11 80 	movl   $0x801122d4,-0xc(%ebp)
8010182f:	eb 59                	jmp    8010188a <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
80101831:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101834:	8b 40 08             	mov    0x8(%eax),%eax
80101837:	85 c0                	test   %eax,%eax
80101839:	7e 35                	jle    80101870 <iget+0x61>
8010183b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010183e:	8b 00                	mov    (%eax),%eax
80101840:	3b 45 08             	cmp    0x8(%ebp),%eax
80101843:	75 2b                	jne    80101870 <iget+0x61>
80101845:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101848:	8b 40 04             	mov    0x4(%eax),%eax
8010184b:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010184e:	75 20                	jne    80101870 <iget+0x61>
      ip->ref++;
80101850:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101853:	8b 40 08             	mov    0x8(%eax),%eax
80101856:	8d 50 01             	lea    0x1(%eax),%edx
80101859:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010185c:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
8010185f:	c7 04 24 a0 22 11 80 	movl   $0x801122a0,(%esp)
80101866:	e8 cd 42 00 00       	call   80105b38 <release>
      return ip;
8010186b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010186e:	eb 6f                	jmp    801018df <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
80101870:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101874:	75 10                	jne    80101886 <iget+0x77>
80101876:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101879:	8b 40 08             	mov    0x8(%eax),%eax
8010187c:	85 c0                	test   %eax,%eax
8010187e:	75 06                	jne    80101886 <iget+0x77>
      empty = ip;
80101880:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101883:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101886:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
8010188a:	81 7d f4 74 32 11 80 	cmpl   $0x80113274,-0xc(%ebp)
80101891:	72 9e                	jb     80101831 <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
80101893:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101897:	75 0c                	jne    801018a5 <iget+0x96>
    panic("iget: no inodes");
80101899:	c7 04 24 f1 92 10 80 	movl   $0x801092f1,(%esp)
801018a0:	e8 95 ec ff ff       	call   8010053a <panic>

  ip = empty;
801018a5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018a8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
801018ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018ae:	8b 55 08             	mov    0x8(%ebp),%edx
801018b1:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
801018b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018b6:	8b 55 0c             	mov    0xc(%ebp),%edx
801018b9:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
801018bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018bf:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
801018c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018c9:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
801018d0:	c7 04 24 a0 22 11 80 	movl   $0x801122a0,(%esp)
801018d7:	e8 5c 42 00 00       	call   80105b38 <release>

  return ip;
801018dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801018df:	c9                   	leave  
801018e0:	c3                   	ret    

801018e1 <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
801018e1:	55                   	push   %ebp
801018e2:	89 e5                	mov    %esp,%ebp
801018e4:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
801018e7:	c7 04 24 a0 22 11 80 	movl   $0x801122a0,(%esp)
801018ee:	e8 e3 41 00 00       	call   80105ad6 <acquire>
  ip->ref++;
801018f3:	8b 45 08             	mov    0x8(%ebp),%eax
801018f6:	8b 40 08             	mov    0x8(%eax),%eax
801018f9:	8d 50 01             	lea    0x1(%eax),%edx
801018fc:	8b 45 08             	mov    0x8(%ebp),%eax
801018ff:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101902:	c7 04 24 a0 22 11 80 	movl   $0x801122a0,(%esp)
80101909:	e8 2a 42 00 00       	call   80105b38 <release>
  return ip;
8010190e:	8b 45 08             	mov    0x8(%ebp),%eax
}
80101911:	c9                   	leave  
80101912:	c3                   	ret    

80101913 <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
80101913:	55                   	push   %ebp
80101914:	89 e5                	mov    %esp,%ebp
80101916:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
80101919:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010191d:	74 0a                	je     80101929 <ilock+0x16>
8010191f:	8b 45 08             	mov    0x8(%ebp),%eax
80101922:	8b 40 08             	mov    0x8(%eax),%eax
80101925:	85 c0                	test   %eax,%eax
80101927:	7f 0c                	jg     80101935 <ilock+0x22>
    panic("ilock");
80101929:	c7 04 24 01 93 10 80 	movl   $0x80109301,(%esp)
80101930:	e8 05 ec ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
80101935:	c7 04 24 a0 22 11 80 	movl   $0x801122a0,(%esp)
8010193c:	e8 95 41 00 00       	call   80105ad6 <acquire>
  while(ip->flags & I_BUSY)
80101941:	eb 13                	jmp    80101956 <ilock+0x43>
    sleep(ip, &icache.lock);
80101943:	c7 44 24 04 a0 22 11 	movl   $0x801122a0,0x4(%esp)
8010194a:	80 
8010194b:	8b 45 08             	mov    0x8(%ebp),%eax
8010194e:	89 04 24             	mov    %eax,(%esp)
80101951:	e8 ae 33 00 00       	call   80104d04 <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
80101956:	8b 45 08             	mov    0x8(%ebp),%eax
80101959:	8b 40 0c             	mov    0xc(%eax),%eax
8010195c:	83 e0 01             	and    $0x1,%eax
8010195f:	85 c0                	test   %eax,%eax
80101961:	75 e0                	jne    80101943 <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
80101963:	8b 45 08             	mov    0x8(%ebp),%eax
80101966:	8b 40 0c             	mov    0xc(%eax),%eax
80101969:	83 c8 01             	or     $0x1,%eax
8010196c:	89 c2                	mov    %eax,%edx
8010196e:	8b 45 08             	mov    0x8(%ebp),%eax
80101971:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
80101974:	c7 04 24 a0 22 11 80 	movl   $0x801122a0,(%esp)
8010197b:	e8 b8 41 00 00       	call   80105b38 <release>

  if(!(ip->flags & I_VALID)){
80101980:	8b 45 08             	mov    0x8(%ebp),%eax
80101983:	8b 40 0c             	mov    0xc(%eax),%eax
80101986:	83 e0 02             	and    $0x2,%eax
80101989:	85 c0                	test   %eax,%eax
8010198b:	0f 85 ce 00 00 00    	jne    80101a5f <ilock+0x14c>
    bp = bread(ip->dev, IBLOCK(ip->inum));
80101991:	8b 45 08             	mov    0x8(%ebp),%eax
80101994:	8b 40 04             	mov    0x4(%eax),%eax
80101997:	c1 e8 03             	shr    $0x3,%eax
8010199a:	8d 50 02             	lea    0x2(%eax),%edx
8010199d:	8b 45 08             	mov    0x8(%ebp),%eax
801019a0:	8b 00                	mov    (%eax),%eax
801019a2:	89 54 24 04          	mov    %edx,0x4(%esp)
801019a6:	89 04 24             	mov    %eax,(%esp)
801019a9:	e8 f8 e7 ff ff       	call   801001a6 <bread>
801019ae:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
801019b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019b4:	8d 50 18             	lea    0x18(%eax),%edx
801019b7:	8b 45 08             	mov    0x8(%ebp),%eax
801019ba:	8b 40 04             	mov    0x4(%eax),%eax
801019bd:	83 e0 07             	and    $0x7,%eax
801019c0:	c1 e0 06             	shl    $0x6,%eax
801019c3:	01 d0                	add    %edx,%eax
801019c5:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
801019c8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019cb:	0f b7 10             	movzwl (%eax),%edx
801019ce:	8b 45 08             	mov    0x8(%ebp),%eax
801019d1:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
801019d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019d8:	0f b7 50 02          	movzwl 0x2(%eax),%edx
801019dc:	8b 45 08             	mov    0x8(%ebp),%eax
801019df:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
801019e3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019e6:	0f b7 50 04          	movzwl 0x4(%eax),%edx
801019ea:	8b 45 08             	mov    0x8(%ebp),%eax
801019ed:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
801019f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019f4:	0f b7 50 06          	movzwl 0x6(%eax),%edx
801019f8:	8b 45 08             	mov    0x8(%ebp),%eax
801019fb:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
801019ff:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a02:	8b 50 08             	mov    0x8(%eax),%edx
80101a05:	8b 45 08             	mov    0x8(%ebp),%eax
80101a08:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101a0b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a0e:	8d 50 0c             	lea    0xc(%eax),%edx
80101a11:	8b 45 08             	mov    0x8(%ebp),%eax
80101a14:	83 c0 1c             	add    $0x1c,%eax
80101a17:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101a1e:	00 
80101a1f:	89 54 24 04          	mov    %edx,0x4(%esp)
80101a23:	89 04 24             	mov    %eax,(%esp)
80101a26:	e8 ce 43 00 00       	call   80105df9 <memmove>
    brelse(bp);
80101a2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101a2e:	89 04 24             	mov    %eax,(%esp)
80101a31:	e8 e1 e7 ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
80101a36:	8b 45 08             	mov    0x8(%ebp),%eax
80101a39:	8b 40 0c             	mov    0xc(%eax),%eax
80101a3c:	83 c8 02             	or     $0x2,%eax
80101a3f:	89 c2                	mov    %eax,%edx
80101a41:	8b 45 08             	mov    0x8(%ebp),%eax
80101a44:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
80101a47:	8b 45 08             	mov    0x8(%ebp),%eax
80101a4a:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101a4e:	66 85 c0             	test   %ax,%ax
80101a51:	75 0c                	jne    80101a5f <ilock+0x14c>
      panic("ilock: no type");
80101a53:	c7 04 24 07 93 10 80 	movl   $0x80109307,(%esp)
80101a5a:	e8 db ea ff ff       	call   8010053a <panic>
  }
}
80101a5f:	c9                   	leave  
80101a60:	c3                   	ret    

80101a61 <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
80101a61:	55                   	push   %ebp
80101a62:	89 e5                	mov    %esp,%ebp
80101a64:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
80101a67:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101a6b:	74 17                	je     80101a84 <iunlock+0x23>
80101a6d:	8b 45 08             	mov    0x8(%ebp),%eax
80101a70:	8b 40 0c             	mov    0xc(%eax),%eax
80101a73:	83 e0 01             	and    $0x1,%eax
80101a76:	85 c0                	test   %eax,%eax
80101a78:	74 0a                	je     80101a84 <iunlock+0x23>
80101a7a:	8b 45 08             	mov    0x8(%ebp),%eax
80101a7d:	8b 40 08             	mov    0x8(%eax),%eax
80101a80:	85 c0                	test   %eax,%eax
80101a82:	7f 0c                	jg     80101a90 <iunlock+0x2f>
    panic("iunlock");
80101a84:	c7 04 24 16 93 10 80 	movl   $0x80109316,(%esp)
80101a8b:	e8 aa ea ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
80101a90:	c7 04 24 a0 22 11 80 	movl   $0x801122a0,(%esp)
80101a97:	e8 3a 40 00 00       	call   80105ad6 <acquire>
  ip->flags &= ~I_BUSY;
80101a9c:	8b 45 08             	mov    0x8(%ebp),%eax
80101a9f:	8b 40 0c             	mov    0xc(%eax),%eax
80101aa2:	83 e0 fe             	and    $0xfffffffe,%eax
80101aa5:	89 c2                	mov    %eax,%edx
80101aa7:	8b 45 08             	mov    0x8(%ebp),%eax
80101aaa:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
80101aad:	8b 45 08             	mov    0x8(%ebp),%eax
80101ab0:	89 04 24             	mov    %eax,(%esp)
80101ab3:	e8 28 33 00 00       	call   80104de0 <wakeup>
  release(&icache.lock);
80101ab8:	c7 04 24 a0 22 11 80 	movl   $0x801122a0,(%esp)
80101abf:	e8 74 40 00 00       	call   80105b38 <release>
}
80101ac4:	c9                   	leave  
80101ac5:	c3                   	ret    

80101ac6 <iput>:
// to it, free the inode (and its content) on disk.
// All calls to iput() must be inside a transaction in
// case it has to free the inode.
void
iput(struct inode *ip)
{
80101ac6:	55                   	push   %ebp
80101ac7:	89 e5                	mov    %esp,%ebp
80101ac9:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101acc:	c7 04 24 a0 22 11 80 	movl   $0x801122a0,(%esp)
80101ad3:	e8 fe 3f 00 00       	call   80105ad6 <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
80101ad8:	8b 45 08             	mov    0x8(%ebp),%eax
80101adb:	8b 40 08             	mov    0x8(%eax),%eax
80101ade:	83 f8 01             	cmp    $0x1,%eax
80101ae1:	0f 85 93 00 00 00    	jne    80101b7a <iput+0xb4>
80101ae7:	8b 45 08             	mov    0x8(%ebp),%eax
80101aea:	8b 40 0c             	mov    0xc(%eax),%eax
80101aed:	83 e0 02             	and    $0x2,%eax
80101af0:	85 c0                	test   %eax,%eax
80101af2:	0f 84 82 00 00 00    	je     80101b7a <iput+0xb4>
80101af8:	8b 45 08             	mov    0x8(%ebp),%eax
80101afb:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80101aff:	66 85 c0             	test   %ax,%ax
80101b02:	75 76                	jne    80101b7a <iput+0xb4>
    // inode has no links and no other references: truncate and free.
    if(ip->flags & I_BUSY)
80101b04:	8b 45 08             	mov    0x8(%ebp),%eax
80101b07:	8b 40 0c             	mov    0xc(%eax),%eax
80101b0a:	83 e0 01             	and    $0x1,%eax
80101b0d:	85 c0                	test   %eax,%eax
80101b0f:	74 0c                	je     80101b1d <iput+0x57>
      panic("iput busy");
80101b11:	c7 04 24 1e 93 10 80 	movl   $0x8010931e,(%esp)
80101b18:	e8 1d ea ff ff       	call   8010053a <panic>
    ip->flags |= I_BUSY;
80101b1d:	8b 45 08             	mov    0x8(%ebp),%eax
80101b20:	8b 40 0c             	mov    0xc(%eax),%eax
80101b23:	83 c8 01             	or     $0x1,%eax
80101b26:	89 c2                	mov    %eax,%edx
80101b28:	8b 45 08             	mov    0x8(%ebp),%eax
80101b2b:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80101b2e:	c7 04 24 a0 22 11 80 	movl   $0x801122a0,(%esp)
80101b35:	e8 fe 3f 00 00       	call   80105b38 <release>
    itrunc(ip);
80101b3a:	8b 45 08             	mov    0x8(%ebp),%eax
80101b3d:	89 04 24             	mov    %eax,(%esp)
80101b40:	e8 7d 01 00 00       	call   80101cc2 <itrunc>
    ip->type = 0;
80101b45:	8b 45 08             	mov    0x8(%ebp),%eax
80101b48:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
80101b4e:	8b 45 08             	mov    0x8(%ebp),%eax
80101b51:	89 04 24             	mov    %eax,(%esp)
80101b54:	e8 fe fb ff ff       	call   80101757 <iupdate>
    acquire(&icache.lock);
80101b59:	c7 04 24 a0 22 11 80 	movl   $0x801122a0,(%esp)
80101b60:	e8 71 3f 00 00       	call   80105ad6 <acquire>
    ip->flags = 0;
80101b65:	8b 45 08             	mov    0x8(%ebp),%eax
80101b68:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101b6f:	8b 45 08             	mov    0x8(%ebp),%eax
80101b72:	89 04 24             	mov    %eax,(%esp)
80101b75:	e8 66 32 00 00       	call   80104de0 <wakeup>
  }
  ip->ref--;
80101b7a:	8b 45 08             	mov    0x8(%ebp),%eax
80101b7d:	8b 40 08             	mov    0x8(%eax),%eax
80101b80:	8d 50 ff             	lea    -0x1(%eax),%edx
80101b83:	8b 45 08             	mov    0x8(%ebp),%eax
80101b86:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101b89:	c7 04 24 a0 22 11 80 	movl   $0x801122a0,(%esp)
80101b90:	e8 a3 3f 00 00       	call   80105b38 <release>
}
80101b95:	c9                   	leave  
80101b96:	c3                   	ret    

80101b97 <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80101b97:	55                   	push   %ebp
80101b98:	89 e5                	mov    %esp,%ebp
80101b9a:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80101b9d:	8b 45 08             	mov    0x8(%ebp),%eax
80101ba0:	89 04 24             	mov    %eax,(%esp)
80101ba3:	e8 b9 fe ff ff       	call   80101a61 <iunlock>
  iput(ip);
80101ba8:	8b 45 08             	mov    0x8(%ebp),%eax
80101bab:	89 04 24             	mov    %eax,(%esp)
80101bae:	e8 13 ff ff ff       	call   80101ac6 <iput>
}
80101bb3:	c9                   	leave  
80101bb4:	c3                   	ret    

80101bb5 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80101bb5:	55                   	push   %ebp
80101bb6:	89 e5                	mov    %esp,%ebp
80101bb8:	53                   	push   %ebx
80101bb9:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80101bbc:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
80101bc0:	77 3e                	ja     80101c00 <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
80101bc2:	8b 45 08             	mov    0x8(%ebp),%eax
80101bc5:	8b 55 0c             	mov    0xc(%ebp),%edx
80101bc8:	83 c2 04             	add    $0x4,%edx
80101bcb:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101bcf:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101bd2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101bd6:	75 20                	jne    80101bf8 <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
80101bd8:	8b 45 08             	mov    0x8(%ebp),%eax
80101bdb:	8b 00                	mov    (%eax),%eax
80101bdd:	89 04 24             	mov    %eax,(%esp)
80101be0:	e8 5b f8 ff ff       	call   80101440 <balloc>
80101be5:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101be8:	8b 45 08             	mov    0x8(%ebp),%eax
80101beb:	8b 55 0c             	mov    0xc(%ebp),%edx
80101bee:	8d 4a 04             	lea    0x4(%edx),%ecx
80101bf1:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101bf4:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
80101bf8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101bfb:	e9 bc 00 00 00       	jmp    80101cbc <bmap+0x107>
  }
  bn -= NDIRECT;
80101c00:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
80101c04:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
80101c08:	0f 87 a2 00 00 00    	ja     80101cb0 <bmap+0xfb>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
80101c0e:	8b 45 08             	mov    0x8(%ebp),%eax
80101c11:	8b 40 4c             	mov    0x4c(%eax),%eax
80101c14:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c17:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101c1b:	75 19                	jne    80101c36 <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
80101c1d:	8b 45 08             	mov    0x8(%ebp),%eax
80101c20:	8b 00                	mov    (%eax),%eax
80101c22:	89 04 24             	mov    %eax,(%esp)
80101c25:	e8 16 f8 ff ff       	call   80101440 <balloc>
80101c2a:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c2d:	8b 45 08             	mov    0x8(%ebp),%eax
80101c30:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c33:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
80101c36:	8b 45 08             	mov    0x8(%ebp),%eax
80101c39:	8b 00                	mov    (%eax),%eax
80101c3b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c3e:	89 54 24 04          	mov    %edx,0x4(%esp)
80101c42:	89 04 24             	mov    %eax,(%esp)
80101c45:	e8 5c e5 ff ff       	call   801001a6 <bread>
80101c4a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80101c4d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c50:	83 c0 18             	add    $0x18,%eax
80101c53:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
80101c56:	8b 45 0c             	mov    0xc(%ebp),%eax
80101c59:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101c60:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101c63:	01 d0                	add    %edx,%eax
80101c65:	8b 00                	mov    (%eax),%eax
80101c67:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c6a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101c6e:	75 30                	jne    80101ca0 <bmap+0xeb>
      a[bn] = addr = balloc(ip->dev);
80101c70:	8b 45 0c             	mov    0xc(%ebp),%eax
80101c73:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101c7a:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101c7d:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80101c80:	8b 45 08             	mov    0x8(%ebp),%eax
80101c83:	8b 00                	mov    (%eax),%eax
80101c85:	89 04 24             	mov    %eax,(%esp)
80101c88:	e8 b3 f7 ff ff       	call   80101440 <balloc>
80101c8d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c90:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c93:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80101c95:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c98:	89 04 24             	mov    %eax,(%esp)
80101c9b:	e8 4e 1b 00 00       	call   801037ee <log_write>
    }
    brelse(bp);
80101ca0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ca3:	89 04 24             	mov    %eax,(%esp)
80101ca6:	e8 6c e5 ff ff       	call   80100217 <brelse>
    return addr;
80101cab:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101cae:	eb 0c                	jmp    80101cbc <bmap+0x107>
  }

  panic("bmap: out of range");
80101cb0:	c7 04 24 28 93 10 80 	movl   $0x80109328,(%esp)
80101cb7:	e8 7e e8 ff ff       	call   8010053a <panic>
}
80101cbc:	83 c4 24             	add    $0x24,%esp
80101cbf:	5b                   	pop    %ebx
80101cc0:	5d                   	pop    %ebp
80101cc1:	c3                   	ret    

80101cc2 <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80101cc2:	55                   	push   %ebp
80101cc3:	89 e5                	mov    %esp,%ebp
80101cc5:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101cc8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101ccf:	eb 44                	jmp    80101d15 <itrunc+0x53>
    if(ip->addrs[i]){
80101cd1:	8b 45 08             	mov    0x8(%ebp),%eax
80101cd4:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101cd7:	83 c2 04             	add    $0x4,%edx
80101cda:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101cde:	85 c0                	test   %eax,%eax
80101ce0:	74 2f                	je     80101d11 <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
80101ce2:	8b 45 08             	mov    0x8(%ebp),%eax
80101ce5:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101ce8:	83 c2 04             	add    $0x4,%edx
80101ceb:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101cef:	8b 45 08             	mov    0x8(%ebp),%eax
80101cf2:	8b 00                	mov    (%eax),%eax
80101cf4:	89 54 24 04          	mov    %edx,0x4(%esp)
80101cf8:	89 04 24             	mov    %eax,(%esp)
80101cfb:	e8 8e f8 ff ff       	call   8010158e <bfree>
      ip->addrs[i] = 0;
80101d00:	8b 45 08             	mov    0x8(%ebp),%eax
80101d03:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101d06:	83 c2 04             	add    $0x4,%edx
80101d09:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80101d10:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101d11:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101d15:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101d19:	7e b6                	jle    80101cd1 <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
80101d1b:	8b 45 08             	mov    0x8(%ebp),%eax
80101d1e:	8b 40 4c             	mov    0x4c(%eax),%eax
80101d21:	85 c0                	test   %eax,%eax
80101d23:	0f 84 9b 00 00 00    	je     80101dc4 <itrunc+0x102>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80101d29:	8b 45 08             	mov    0x8(%ebp),%eax
80101d2c:	8b 50 4c             	mov    0x4c(%eax),%edx
80101d2f:	8b 45 08             	mov    0x8(%ebp),%eax
80101d32:	8b 00                	mov    (%eax),%eax
80101d34:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d38:	89 04 24             	mov    %eax,(%esp)
80101d3b:	e8 66 e4 ff ff       	call   801001a6 <bread>
80101d40:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80101d43:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d46:	83 c0 18             	add    $0x18,%eax
80101d49:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80101d4c:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101d53:	eb 3b                	jmp    80101d90 <itrunc+0xce>
      if(a[j])
80101d55:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d58:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101d5f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101d62:	01 d0                	add    %edx,%eax
80101d64:	8b 00                	mov    (%eax),%eax
80101d66:	85 c0                	test   %eax,%eax
80101d68:	74 22                	je     80101d8c <itrunc+0xca>
        bfree(ip->dev, a[j]);
80101d6a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d6d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101d74:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101d77:	01 d0                	add    %edx,%eax
80101d79:	8b 10                	mov    (%eax),%edx
80101d7b:	8b 45 08             	mov    0x8(%ebp),%eax
80101d7e:	8b 00                	mov    (%eax),%eax
80101d80:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d84:	89 04 24             	mov    %eax,(%esp)
80101d87:	e8 02 f8 ff ff       	call   8010158e <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80101d8c:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101d90:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d93:	83 f8 7f             	cmp    $0x7f,%eax
80101d96:	76 bd                	jbe    80101d55 <itrunc+0x93>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
80101d98:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d9b:	89 04 24             	mov    %eax,(%esp)
80101d9e:	e8 74 e4 ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101da3:	8b 45 08             	mov    0x8(%ebp),%eax
80101da6:	8b 50 4c             	mov    0x4c(%eax),%edx
80101da9:	8b 45 08             	mov    0x8(%ebp),%eax
80101dac:	8b 00                	mov    (%eax),%eax
80101dae:	89 54 24 04          	mov    %edx,0x4(%esp)
80101db2:	89 04 24             	mov    %eax,(%esp)
80101db5:	e8 d4 f7 ff ff       	call   8010158e <bfree>
    ip->addrs[NDIRECT] = 0;
80101dba:	8b 45 08             	mov    0x8(%ebp),%eax
80101dbd:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
80101dc4:	8b 45 08             	mov    0x8(%ebp),%eax
80101dc7:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80101dce:	8b 45 08             	mov    0x8(%ebp),%eax
80101dd1:	89 04 24             	mov    %eax,(%esp)
80101dd4:	e8 7e f9 ff ff       	call   80101757 <iupdate>
}
80101dd9:	c9                   	leave  
80101dda:	c3                   	ret    

80101ddb <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
80101ddb:	55                   	push   %ebp
80101ddc:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80101dde:	8b 45 08             	mov    0x8(%ebp),%eax
80101de1:	8b 00                	mov    (%eax),%eax
80101de3:	89 c2                	mov    %eax,%edx
80101de5:	8b 45 0c             	mov    0xc(%ebp),%eax
80101de8:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80101deb:	8b 45 08             	mov    0x8(%ebp),%eax
80101dee:	8b 50 04             	mov    0x4(%eax),%edx
80101df1:	8b 45 0c             	mov    0xc(%ebp),%eax
80101df4:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
80101df7:	8b 45 08             	mov    0x8(%ebp),%eax
80101dfa:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101dfe:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e01:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80101e04:	8b 45 08             	mov    0x8(%ebp),%eax
80101e07:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101e0b:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e0e:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80101e12:	8b 45 08             	mov    0x8(%ebp),%eax
80101e15:	8b 50 18             	mov    0x18(%eax),%edx
80101e18:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e1b:	89 50 10             	mov    %edx,0x10(%eax)
}
80101e1e:	5d                   	pop    %ebp
80101e1f:	c3                   	ret    

80101e20 <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80101e20:	55                   	push   %ebp
80101e21:	89 e5                	mov    %esp,%ebp
80101e23:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101e26:	8b 45 08             	mov    0x8(%ebp),%eax
80101e29:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101e2d:	66 83 f8 03          	cmp    $0x3,%ax
80101e31:	75 6d                	jne    80101ea0 <readi+0x80>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80101e33:	8b 45 08             	mov    0x8(%ebp),%eax
80101e36:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101e3a:	66 85 c0             	test   %ax,%ax
80101e3d:	78 23                	js     80101e62 <readi+0x42>
80101e3f:	8b 45 08             	mov    0x8(%ebp),%eax
80101e42:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101e46:	66 83 f8 09          	cmp    $0x9,%ax
80101e4a:	7f 16                	jg     80101e62 <readi+0x42>
80101e4c:	8b 45 08             	mov    0x8(%ebp),%eax
80101e4f:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101e53:	98                   	cwtl   
80101e54:	c1 e0 04             	shl    $0x4,%eax
80101e57:	05 08 22 11 80       	add    $0x80112208,%eax
80101e5c:	8b 00                	mov    (%eax),%eax
80101e5e:	85 c0                	test   %eax,%eax
80101e60:	75 0a                	jne    80101e6c <readi+0x4c>
      return -1;
80101e62:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101e67:	e9 23 01 00 00       	jmp    80101f8f <readi+0x16f>
    return devsw[ip->major].read(ip, dst, off, n);
80101e6c:	8b 45 08             	mov    0x8(%ebp),%eax
80101e6f:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101e73:	98                   	cwtl   
80101e74:	c1 e0 04             	shl    $0x4,%eax
80101e77:	05 08 22 11 80       	add    $0x80112208,%eax
80101e7c:	8b 00                	mov    (%eax),%eax
80101e7e:	8b 4d 14             	mov    0x14(%ebp),%ecx
80101e81:	8b 55 10             	mov    0x10(%ebp),%edx
80101e84:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101e88:	89 54 24 08          	mov    %edx,0x8(%esp)
80101e8c:	8b 55 0c             	mov    0xc(%ebp),%edx
80101e8f:	89 54 24 04          	mov    %edx,0x4(%esp)
80101e93:	8b 55 08             	mov    0x8(%ebp),%edx
80101e96:	89 14 24             	mov    %edx,(%esp)
80101e99:	ff d0                	call   *%eax
80101e9b:	e9 ef 00 00 00       	jmp    80101f8f <readi+0x16f>
  }

  if(off > ip->size || off + n < off)
80101ea0:	8b 45 08             	mov    0x8(%ebp),%eax
80101ea3:	8b 40 18             	mov    0x18(%eax),%eax
80101ea6:	3b 45 10             	cmp    0x10(%ebp),%eax
80101ea9:	72 0d                	jb     80101eb8 <readi+0x98>
80101eab:	8b 45 14             	mov    0x14(%ebp),%eax
80101eae:	8b 55 10             	mov    0x10(%ebp),%edx
80101eb1:	01 d0                	add    %edx,%eax
80101eb3:	3b 45 10             	cmp    0x10(%ebp),%eax
80101eb6:	73 0a                	jae    80101ec2 <readi+0xa2>
    return -1;
80101eb8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101ebd:	e9 cd 00 00 00       	jmp    80101f8f <readi+0x16f>
  if(off + n > ip->size)
80101ec2:	8b 45 14             	mov    0x14(%ebp),%eax
80101ec5:	8b 55 10             	mov    0x10(%ebp),%edx
80101ec8:	01 c2                	add    %eax,%edx
80101eca:	8b 45 08             	mov    0x8(%ebp),%eax
80101ecd:	8b 40 18             	mov    0x18(%eax),%eax
80101ed0:	39 c2                	cmp    %eax,%edx
80101ed2:	76 0c                	jbe    80101ee0 <readi+0xc0>
    n = ip->size - off;
80101ed4:	8b 45 08             	mov    0x8(%ebp),%eax
80101ed7:	8b 40 18             	mov    0x18(%eax),%eax
80101eda:	2b 45 10             	sub    0x10(%ebp),%eax
80101edd:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101ee0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101ee7:	e9 94 00 00 00       	jmp    80101f80 <readi+0x160>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101eec:	8b 45 10             	mov    0x10(%ebp),%eax
80101eef:	c1 e8 09             	shr    $0x9,%eax
80101ef2:	89 44 24 04          	mov    %eax,0x4(%esp)
80101ef6:	8b 45 08             	mov    0x8(%ebp),%eax
80101ef9:	89 04 24             	mov    %eax,(%esp)
80101efc:	e8 b4 fc ff ff       	call   80101bb5 <bmap>
80101f01:	8b 55 08             	mov    0x8(%ebp),%edx
80101f04:	8b 12                	mov    (%edx),%edx
80101f06:	89 44 24 04          	mov    %eax,0x4(%esp)
80101f0a:	89 14 24             	mov    %edx,(%esp)
80101f0d:	e8 94 e2 ff ff       	call   801001a6 <bread>
80101f12:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80101f15:	8b 45 10             	mov    0x10(%ebp),%eax
80101f18:	25 ff 01 00 00       	and    $0x1ff,%eax
80101f1d:	89 c2                	mov    %eax,%edx
80101f1f:	b8 00 02 00 00       	mov    $0x200,%eax
80101f24:	29 d0                	sub    %edx,%eax
80101f26:	89 c2                	mov    %eax,%edx
80101f28:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101f2b:	8b 4d 14             	mov    0x14(%ebp),%ecx
80101f2e:	29 c1                	sub    %eax,%ecx
80101f30:	89 c8                	mov    %ecx,%eax
80101f32:	39 c2                	cmp    %eax,%edx
80101f34:	0f 46 c2             	cmovbe %edx,%eax
80101f37:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
80101f3a:	8b 45 10             	mov    0x10(%ebp),%eax
80101f3d:	25 ff 01 00 00       	and    $0x1ff,%eax
80101f42:	8d 50 10             	lea    0x10(%eax),%edx
80101f45:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f48:	01 d0                	add    %edx,%eax
80101f4a:	8d 50 08             	lea    0x8(%eax),%edx
80101f4d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101f50:	89 44 24 08          	mov    %eax,0x8(%esp)
80101f54:	89 54 24 04          	mov    %edx,0x4(%esp)
80101f58:	8b 45 0c             	mov    0xc(%ebp),%eax
80101f5b:	89 04 24             	mov    %eax,(%esp)
80101f5e:	e8 96 3e 00 00       	call   80105df9 <memmove>
    brelse(bp);
80101f63:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f66:	89 04 24             	mov    %eax,(%esp)
80101f69:	e8 a9 e2 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101f6e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101f71:	01 45 f4             	add    %eax,-0xc(%ebp)
80101f74:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101f77:	01 45 10             	add    %eax,0x10(%ebp)
80101f7a:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101f7d:	01 45 0c             	add    %eax,0xc(%ebp)
80101f80:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101f83:	3b 45 14             	cmp    0x14(%ebp),%eax
80101f86:	0f 82 60 ff ff ff    	jb     80101eec <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
80101f8c:	8b 45 14             	mov    0x14(%ebp),%eax
}
80101f8f:	c9                   	leave  
80101f90:	c3                   	ret    

80101f91 <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80101f91:	55                   	push   %ebp
80101f92:	89 e5                	mov    %esp,%ebp
80101f94:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101f97:	8b 45 08             	mov    0x8(%ebp),%eax
80101f9a:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101f9e:	66 83 f8 03          	cmp    $0x3,%ax
80101fa2:	75 66                	jne    8010200a <writei+0x79>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80101fa4:	8b 45 08             	mov    0x8(%ebp),%eax
80101fa7:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101fab:	66 85 c0             	test   %ax,%ax
80101fae:	78 23                	js     80101fd3 <writei+0x42>
80101fb0:	8b 45 08             	mov    0x8(%ebp),%eax
80101fb3:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101fb7:	66 83 f8 09          	cmp    $0x9,%ax
80101fbb:	7f 16                	jg     80101fd3 <writei+0x42>
80101fbd:	8b 45 08             	mov    0x8(%ebp),%eax
80101fc0:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101fc4:	98                   	cwtl   
80101fc5:	c1 e0 04             	shl    $0x4,%eax
80101fc8:	05 0c 22 11 80       	add    $0x8011220c,%eax
80101fcd:	8b 00                	mov    (%eax),%eax
80101fcf:	85 c0                	test   %eax,%eax
80101fd1:	75 0a                	jne    80101fdd <writei+0x4c>
      return -1;
80101fd3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101fd8:	e9 47 01 00 00       	jmp    80102124 <writei+0x193>
    return devsw[ip->major].write(ip, src, n);
80101fdd:	8b 45 08             	mov    0x8(%ebp),%eax
80101fe0:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101fe4:	98                   	cwtl   
80101fe5:	c1 e0 04             	shl    $0x4,%eax
80101fe8:	05 0c 22 11 80       	add    $0x8011220c,%eax
80101fed:	8b 00                	mov    (%eax),%eax
80101fef:	8b 55 14             	mov    0x14(%ebp),%edx
80101ff2:	89 54 24 08          	mov    %edx,0x8(%esp)
80101ff6:	8b 55 0c             	mov    0xc(%ebp),%edx
80101ff9:	89 54 24 04          	mov    %edx,0x4(%esp)
80101ffd:	8b 55 08             	mov    0x8(%ebp),%edx
80102000:	89 14 24             	mov    %edx,(%esp)
80102003:	ff d0                	call   *%eax
80102005:	e9 1a 01 00 00       	jmp    80102124 <writei+0x193>
  }

  if(off > ip->size || off + n < off)
8010200a:	8b 45 08             	mov    0x8(%ebp),%eax
8010200d:	8b 40 18             	mov    0x18(%eax),%eax
80102010:	3b 45 10             	cmp    0x10(%ebp),%eax
80102013:	72 0d                	jb     80102022 <writei+0x91>
80102015:	8b 45 14             	mov    0x14(%ebp),%eax
80102018:	8b 55 10             	mov    0x10(%ebp),%edx
8010201b:	01 d0                	add    %edx,%eax
8010201d:	3b 45 10             	cmp    0x10(%ebp),%eax
80102020:	73 0a                	jae    8010202c <writei+0x9b>
    return -1;
80102022:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102027:	e9 f8 00 00 00       	jmp    80102124 <writei+0x193>
  if(off + n > MAXFILE*BSIZE)
8010202c:	8b 45 14             	mov    0x14(%ebp),%eax
8010202f:	8b 55 10             	mov    0x10(%ebp),%edx
80102032:	01 d0                	add    %edx,%eax
80102034:	3d 00 18 01 00       	cmp    $0x11800,%eax
80102039:	76 0a                	jbe    80102045 <writei+0xb4>
    return -1;
8010203b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102040:	e9 df 00 00 00       	jmp    80102124 <writei+0x193>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102045:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010204c:	e9 9f 00 00 00       	jmp    801020f0 <writei+0x15f>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80102051:	8b 45 10             	mov    0x10(%ebp),%eax
80102054:	c1 e8 09             	shr    $0x9,%eax
80102057:	89 44 24 04          	mov    %eax,0x4(%esp)
8010205b:	8b 45 08             	mov    0x8(%ebp),%eax
8010205e:	89 04 24             	mov    %eax,(%esp)
80102061:	e8 4f fb ff ff       	call   80101bb5 <bmap>
80102066:	8b 55 08             	mov    0x8(%ebp),%edx
80102069:	8b 12                	mov    (%edx),%edx
8010206b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010206f:	89 14 24             	mov    %edx,(%esp)
80102072:	e8 2f e1 ff ff       	call   801001a6 <bread>
80102077:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
8010207a:	8b 45 10             	mov    0x10(%ebp),%eax
8010207d:	25 ff 01 00 00       	and    $0x1ff,%eax
80102082:	89 c2                	mov    %eax,%edx
80102084:	b8 00 02 00 00       	mov    $0x200,%eax
80102089:	29 d0                	sub    %edx,%eax
8010208b:	89 c2                	mov    %eax,%edx
8010208d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102090:	8b 4d 14             	mov    0x14(%ebp),%ecx
80102093:	29 c1                	sub    %eax,%ecx
80102095:	89 c8                	mov    %ecx,%eax
80102097:	39 c2                	cmp    %eax,%edx
80102099:	0f 46 c2             	cmovbe %edx,%eax
8010209c:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
8010209f:	8b 45 10             	mov    0x10(%ebp),%eax
801020a2:	25 ff 01 00 00       	and    $0x1ff,%eax
801020a7:	8d 50 10             	lea    0x10(%eax),%edx
801020aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801020ad:	01 d0                	add    %edx,%eax
801020af:	8d 50 08             	lea    0x8(%eax),%edx
801020b2:	8b 45 ec             	mov    -0x14(%ebp),%eax
801020b5:	89 44 24 08          	mov    %eax,0x8(%esp)
801020b9:	8b 45 0c             	mov    0xc(%ebp),%eax
801020bc:	89 44 24 04          	mov    %eax,0x4(%esp)
801020c0:	89 14 24             	mov    %edx,(%esp)
801020c3:	e8 31 3d 00 00       	call   80105df9 <memmove>
    log_write(bp);
801020c8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801020cb:	89 04 24             	mov    %eax,(%esp)
801020ce:	e8 1b 17 00 00       	call   801037ee <log_write>
    brelse(bp);
801020d3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801020d6:	89 04 24             	mov    %eax,(%esp)
801020d9:	e8 39 e1 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
801020de:	8b 45 ec             	mov    -0x14(%ebp),%eax
801020e1:	01 45 f4             	add    %eax,-0xc(%ebp)
801020e4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801020e7:	01 45 10             	add    %eax,0x10(%ebp)
801020ea:	8b 45 ec             	mov    -0x14(%ebp),%eax
801020ed:	01 45 0c             	add    %eax,0xc(%ebp)
801020f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801020f3:	3b 45 14             	cmp    0x14(%ebp),%eax
801020f6:	0f 82 55 ff ff ff    	jb     80102051 <writei+0xc0>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
801020fc:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80102100:	74 1f                	je     80102121 <writei+0x190>
80102102:	8b 45 08             	mov    0x8(%ebp),%eax
80102105:	8b 40 18             	mov    0x18(%eax),%eax
80102108:	3b 45 10             	cmp    0x10(%ebp),%eax
8010210b:	73 14                	jae    80102121 <writei+0x190>
    ip->size = off;
8010210d:	8b 45 08             	mov    0x8(%ebp),%eax
80102110:	8b 55 10             	mov    0x10(%ebp),%edx
80102113:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
80102116:	8b 45 08             	mov    0x8(%ebp),%eax
80102119:	89 04 24             	mov    %eax,(%esp)
8010211c:	e8 36 f6 ff ff       	call   80101757 <iupdate>
  }
  return n;
80102121:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102124:	c9                   	leave  
80102125:	c3                   	ret    

80102126 <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
80102126:	55                   	push   %ebp
80102127:	89 e5                	mov    %esp,%ebp
80102129:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
8010212c:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102133:	00 
80102134:	8b 45 0c             	mov    0xc(%ebp),%eax
80102137:	89 44 24 04          	mov    %eax,0x4(%esp)
8010213b:	8b 45 08             	mov    0x8(%ebp),%eax
8010213e:	89 04 24             	mov    %eax,(%esp)
80102141:	e8 56 3d 00 00       	call   80105e9c <strncmp>
}
80102146:	c9                   	leave  
80102147:	c3                   	ret    

80102148 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
80102148:	55                   	push   %ebp
80102149:	89 e5                	mov    %esp,%ebp
8010214b:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;
  struct inode *ip;

  if(dp->type != T_DIR && !IS_DEV_DIR(dp))
8010214e:	8b 45 08             	mov    0x8(%ebp),%eax
80102151:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102155:	66 83 f8 01          	cmp    $0x1,%ax
80102159:	74 4d                	je     801021a8 <dirlookup+0x60>
8010215b:	8b 45 08             	mov    0x8(%ebp),%eax
8010215e:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102162:	66 83 f8 03          	cmp    $0x3,%ax
80102166:	75 34                	jne    8010219c <dirlookup+0x54>
80102168:	8b 45 08             	mov    0x8(%ebp),%eax
8010216b:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010216f:	98                   	cwtl   
80102170:	c1 e0 04             	shl    $0x4,%eax
80102173:	05 00 22 11 80       	add    $0x80112200,%eax
80102178:	8b 00                	mov    (%eax),%eax
8010217a:	85 c0                	test   %eax,%eax
8010217c:	74 1e                	je     8010219c <dirlookup+0x54>
8010217e:	8b 45 08             	mov    0x8(%ebp),%eax
80102181:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102185:	98                   	cwtl   
80102186:	c1 e0 04             	shl    $0x4,%eax
80102189:	05 00 22 11 80       	add    $0x80112200,%eax
8010218e:	8b 00                	mov    (%eax),%eax
80102190:	8b 55 08             	mov    0x8(%ebp),%edx
80102193:	89 14 24             	mov    %edx,(%esp)
80102196:	ff d0                	call   *%eax
80102198:	85 c0                	test   %eax,%eax
8010219a:	75 0c                	jne    801021a8 <dirlookup+0x60>
    panic("dirlookup not DIR");
8010219c:	c7 04 24 3b 93 10 80 	movl   $0x8010933b,(%esp)
801021a3:	e8 92 e3 ff ff       	call   8010053a <panic>

  for(off = 0; off < dp->size || dp->type == T_DEV; off += sizeof(de)){
801021a8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801021af:	e9 fd 00 00 00       	jmp    801022b1 <dirlookup+0x169>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de)) {
801021b4:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801021bb:	00 
801021bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021bf:	89 44 24 08          	mov    %eax,0x8(%esp)
801021c3:	8d 45 dc             	lea    -0x24(%ebp),%eax
801021c6:	89 44 24 04          	mov    %eax,0x4(%esp)
801021ca:	8b 45 08             	mov    0x8(%ebp),%eax
801021cd:	89 04 24             	mov    %eax,(%esp)
801021d0:	e8 4b fc ff ff       	call   80101e20 <readi>
801021d5:	83 f8 10             	cmp    $0x10,%eax
801021d8:	74 23                	je     801021fd <dirlookup+0xb5>
      if (dp->type == T_DEV)
801021da:	8b 45 08             	mov    0x8(%ebp),%eax
801021dd:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801021e1:	66 83 f8 03          	cmp    $0x3,%ax
801021e5:	75 0a                	jne    801021f1 <dirlookup+0xa9>
        return 0;
801021e7:	b8 00 00 00 00       	mov    $0x0,%eax
801021ec:	e9 e5 00 00 00       	jmp    801022d6 <dirlookup+0x18e>
      else
        panic("dirlink read");
801021f1:	c7 04 24 4d 93 10 80 	movl   $0x8010934d,(%esp)
801021f8:	e8 3d e3 ff ff       	call   8010053a <panic>
    }
    if(de.inum == 0)
801021fd:	0f b7 45 dc          	movzwl -0x24(%ebp),%eax
80102201:	66 85 c0             	test   %ax,%ax
80102204:	75 05                	jne    8010220b <dirlookup+0xc3>
      continue;
80102206:	e9 a2 00 00 00       	jmp    801022ad <dirlookup+0x165>
    if(namecmp(name, de.name) == 0){
8010220b:	8d 45 dc             	lea    -0x24(%ebp),%eax
8010220e:	83 c0 02             	add    $0x2,%eax
80102211:	89 44 24 04          	mov    %eax,0x4(%esp)
80102215:	8b 45 0c             	mov    0xc(%ebp),%eax
80102218:	89 04 24             	mov    %eax,(%esp)
8010221b:	e8 06 ff ff ff       	call   80102126 <namecmp>
80102220:	85 c0                	test   %eax,%eax
80102222:	0f 85 85 00 00 00    	jne    801022ad <dirlookup+0x165>
      // entry matches path element
      if(poff)
80102228:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010222c:	74 08                	je     80102236 <dirlookup+0xee>
        *poff = off;
8010222e:	8b 45 10             	mov    0x10(%ebp),%eax
80102231:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102234:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
80102236:	0f b7 45 dc          	movzwl -0x24(%ebp),%eax
8010223a:	0f b7 c0             	movzwl %ax,%eax
8010223d:	89 45 f0             	mov    %eax,-0x10(%ebp)
      ip = iget(dp->dev, inum);
80102240:	8b 45 08             	mov    0x8(%ebp),%eax
80102243:	8b 00                	mov    (%eax),%eax
80102245:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102248:	89 54 24 04          	mov    %edx,0x4(%esp)
8010224c:	89 04 24             	mov    %eax,(%esp)
8010224f:	e8 bb f5 ff ff       	call   8010180f <iget>
80102254:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if (!(ip->flags & I_VALID) && dp->type == T_DEV && devsw[dp->major].iread) {
80102257:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010225a:	8b 40 0c             	mov    0xc(%eax),%eax
8010225d:	83 e0 02             	and    $0x2,%eax
80102260:	85 c0                	test   %eax,%eax
80102262:	75 44                	jne    801022a8 <dirlookup+0x160>
80102264:	8b 45 08             	mov    0x8(%ebp),%eax
80102267:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010226b:	66 83 f8 03          	cmp    $0x3,%ax
8010226f:	75 37                	jne    801022a8 <dirlookup+0x160>
80102271:	8b 45 08             	mov    0x8(%ebp),%eax
80102274:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102278:	98                   	cwtl   
80102279:	c1 e0 04             	shl    $0x4,%eax
8010227c:	05 04 22 11 80       	add    $0x80112204,%eax
80102281:	8b 00                	mov    (%eax),%eax
80102283:	85 c0                	test   %eax,%eax
80102285:	74 21                	je     801022a8 <dirlookup+0x160>
        devsw[dp->major].iread(dp, ip);
80102287:	8b 45 08             	mov    0x8(%ebp),%eax
8010228a:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010228e:	98                   	cwtl   
8010228f:	c1 e0 04             	shl    $0x4,%eax
80102292:	05 04 22 11 80       	add    $0x80112204,%eax
80102297:	8b 00                	mov    (%eax),%eax
80102299:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010229c:	89 54 24 04          	mov    %edx,0x4(%esp)
801022a0:	8b 55 08             	mov    0x8(%ebp),%edx
801022a3:	89 14 24             	mov    %edx,(%esp)
801022a6:	ff d0                	call   *%eax
      }
      return ip;
801022a8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801022ab:	eb 29                	jmp    801022d6 <dirlookup+0x18e>
  struct inode *ip;

  if(dp->type != T_DIR && !IS_DEV_DIR(dp))
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size || dp->type == T_DEV; off += sizeof(de)){
801022ad:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801022b1:	8b 45 08             	mov    0x8(%ebp),%eax
801022b4:	8b 40 18             	mov    0x18(%eax),%eax
801022b7:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801022ba:	0f 87 f4 fe ff ff    	ja     801021b4 <dirlookup+0x6c>
801022c0:	8b 45 08             	mov    0x8(%ebp),%eax
801022c3:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801022c7:	66 83 f8 03          	cmp    $0x3,%ax
801022cb:	0f 84 e3 fe ff ff    	je     801021b4 <dirlookup+0x6c>
      }
      return ip;
    }
  }

  return 0;
801022d1:	b8 00 00 00 00       	mov    $0x0,%eax
}
801022d6:	c9                   	leave  
801022d7:	c3                   	ret    

801022d8 <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
801022d8:	55                   	push   %ebp
801022d9:	89 e5                	mov    %esp,%ebp
801022db:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
801022de:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801022e5:	00 
801022e6:	8b 45 0c             	mov    0xc(%ebp),%eax
801022e9:	89 44 24 04          	mov    %eax,0x4(%esp)
801022ed:	8b 45 08             	mov    0x8(%ebp),%eax
801022f0:	89 04 24             	mov    %eax,(%esp)
801022f3:	e8 50 fe ff ff       	call   80102148 <dirlookup>
801022f8:	89 45 f0             	mov    %eax,-0x10(%ebp)
801022fb:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801022ff:	74 15                	je     80102316 <dirlink+0x3e>
    iput(ip);
80102301:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102304:	89 04 24             	mov    %eax,(%esp)
80102307:	e8 ba f7 ff ff       	call   80101ac6 <iput>
    return -1;
8010230c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102311:	e9 b7 00 00 00       	jmp    801023cd <dirlink+0xf5>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80102316:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010231d:	eb 46                	jmp    80102365 <dirlink+0x8d>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010231f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102322:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102329:	00 
8010232a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010232e:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102331:	89 44 24 04          	mov    %eax,0x4(%esp)
80102335:	8b 45 08             	mov    0x8(%ebp),%eax
80102338:	89 04 24             	mov    %eax,(%esp)
8010233b:	e8 e0 fa ff ff       	call   80101e20 <readi>
80102340:	83 f8 10             	cmp    $0x10,%eax
80102343:	74 0c                	je     80102351 <dirlink+0x79>
      panic("dirlink read");
80102345:	c7 04 24 4d 93 10 80 	movl   $0x8010934d,(%esp)
8010234c:	e8 e9 e1 ff ff       	call   8010053a <panic>
    if(de.inum == 0)
80102351:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102355:	66 85 c0             	test   %ax,%ax
80102358:	75 02                	jne    8010235c <dirlink+0x84>
      break;
8010235a:	eb 16                	jmp    80102372 <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
8010235c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010235f:	83 c0 10             	add    $0x10,%eax
80102362:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102365:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102368:	8b 45 08             	mov    0x8(%ebp),%eax
8010236b:	8b 40 18             	mov    0x18(%eax),%eax
8010236e:	39 c2                	cmp    %eax,%edx
80102370:	72 ad                	jb     8010231f <dirlink+0x47>
      panic("dirlink read");
    if(de.inum == 0)
      break;
  }

  strncpy(de.name, name, DIRSIZ);
80102372:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102379:	00 
8010237a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010237d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102381:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102384:	83 c0 02             	add    $0x2,%eax
80102387:	89 04 24             	mov    %eax,(%esp)
8010238a:	e8 63 3b 00 00       	call   80105ef2 <strncpy>
  de.inum = inum;
8010238f:	8b 45 10             	mov    0x10(%ebp),%eax
80102392:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102396:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102399:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801023a0:	00 
801023a1:	89 44 24 08          	mov    %eax,0x8(%esp)
801023a5:	8d 45 e0             	lea    -0x20(%ebp),%eax
801023a8:	89 44 24 04          	mov    %eax,0x4(%esp)
801023ac:	8b 45 08             	mov    0x8(%ebp),%eax
801023af:	89 04 24             	mov    %eax,(%esp)
801023b2:	e8 da fb ff ff       	call   80101f91 <writei>
801023b7:	83 f8 10             	cmp    $0x10,%eax
801023ba:	74 0c                	je     801023c8 <dirlink+0xf0>
    panic("dirlink");
801023bc:	c7 04 24 5a 93 10 80 	movl   $0x8010935a,(%esp)
801023c3:	e8 72 e1 ff ff       	call   8010053a <panic>
  
  return 0;
801023c8:	b8 00 00 00 00       	mov    $0x0,%eax
}
801023cd:	c9                   	leave  
801023ce:	c3                   	ret    

801023cf <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
801023cf:	55                   	push   %ebp
801023d0:	89 e5                	mov    %esp,%ebp
801023d2:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
801023d5:	eb 04                	jmp    801023db <skipelem+0xc>
    path++;
801023d7:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
801023db:	8b 45 08             	mov    0x8(%ebp),%eax
801023de:	0f b6 00             	movzbl (%eax),%eax
801023e1:	3c 2f                	cmp    $0x2f,%al
801023e3:	74 f2                	je     801023d7 <skipelem+0x8>
    path++;
  if(*path == 0)
801023e5:	8b 45 08             	mov    0x8(%ebp),%eax
801023e8:	0f b6 00             	movzbl (%eax),%eax
801023eb:	84 c0                	test   %al,%al
801023ed:	75 0a                	jne    801023f9 <skipelem+0x2a>
    return 0;
801023ef:	b8 00 00 00 00       	mov    $0x0,%eax
801023f4:	e9 86 00 00 00       	jmp    8010247f <skipelem+0xb0>
  s = path;
801023f9:	8b 45 08             	mov    0x8(%ebp),%eax
801023fc:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
801023ff:	eb 04                	jmp    80102405 <skipelem+0x36>
    path++;
80102401:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
80102405:	8b 45 08             	mov    0x8(%ebp),%eax
80102408:	0f b6 00             	movzbl (%eax),%eax
8010240b:	3c 2f                	cmp    $0x2f,%al
8010240d:	74 0a                	je     80102419 <skipelem+0x4a>
8010240f:	8b 45 08             	mov    0x8(%ebp),%eax
80102412:	0f b6 00             	movzbl (%eax),%eax
80102415:	84 c0                	test   %al,%al
80102417:	75 e8                	jne    80102401 <skipelem+0x32>
    path++;
  len = path - s;
80102419:	8b 55 08             	mov    0x8(%ebp),%edx
8010241c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010241f:	29 c2                	sub    %eax,%edx
80102421:	89 d0                	mov    %edx,%eax
80102423:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
80102426:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
8010242a:	7e 1c                	jle    80102448 <skipelem+0x79>
    memmove(name, s, DIRSIZ);
8010242c:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102433:	00 
80102434:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102437:	89 44 24 04          	mov    %eax,0x4(%esp)
8010243b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010243e:	89 04 24             	mov    %eax,(%esp)
80102441:	e8 b3 39 00 00       	call   80105df9 <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102446:	eb 2a                	jmp    80102472 <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
80102448:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010244b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010244f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102452:	89 44 24 04          	mov    %eax,0x4(%esp)
80102456:	8b 45 0c             	mov    0xc(%ebp),%eax
80102459:	89 04 24             	mov    %eax,(%esp)
8010245c:	e8 98 39 00 00       	call   80105df9 <memmove>
    name[len] = 0;
80102461:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102464:	8b 45 0c             	mov    0xc(%ebp),%eax
80102467:	01 d0                	add    %edx,%eax
80102469:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
8010246c:	eb 04                	jmp    80102472 <skipelem+0xa3>
    path++;
8010246e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102472:	8b 45 08             	mov    0x8(%ebp),%eax
80102475:	0f b6 00             	movzbl (%eax),%eax
80102478:	3c 2f                	cmp    $0x2f,%al
8010247a:	74 f2                	je     8010246e <skipelem+0x9f>
    path++;
  return path;
8010247c:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010247f:	c9                   	leave  
80102480:	c3                   	ret    

80102481 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
80102481:	55                   	push   %ebp
80102482:	89 e5                	mov    %esp,%ebp
80102484:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
80102487:	8b 45 08             	mov    0x8(%ebp),%eax
8010248a:	0f b6 00             	movzbl (%eax),%eax
8010248d:	3c 2f                	cmp    $0x2f,%al
8010248f:	75 1c                	jne    801024ad <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
80102491:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102498:	00 
80102499:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801024a0:	e8 6a f3 ff ff       	call   8010180f <iget>
801024a5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
801024a8:	e9 f0 00 00 00       	jmp    8010259d <namex+0x11c>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
801024ad:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801024b3:	8b 40 68             	mov    0x68(%eax),%eax
801024b6:	89 04 24             	mov    %eax,(%esp)
801024b9:	e8 23 f4 ff ff       	call   801018e1 <idup>
801024be:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
801024c1:	e9 d7 00 00 00       	jmp    8010259d <namex+0x11c>
    ilock(ip);
801024c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024c9:	89 04 24             	mov    %eax,(%esp)
801024cc:	e8 42 f4 ff ff       	call   80101913 <ilock>
    if(ip->type != T_DIR && !IS_DEV_DIR(ip)){
801024d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024d4:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801024d8:	66 83 f8 01          	cmp    $0x1,%ax
801024dc:	74 56                	je     80102534 <namex+0xb3>
801024de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024e1:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801024e5:	66 83 f8 03          	cmp    $0x3,%ax
801024e9:	75 34                	jne    8010251f <namex+0x9e>
801024eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024ee:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801024f2:	98                   	cwtl   
801024f3:	c1 e0 04             	shl    $0x4,%eax
801024f6:	05 00 22 11 80       	add    $0x80112200,%eax
801024fb:	8b 00                	mov    (%eax),%eax
801024fd:	85 c0                	test   %eax,%eax
801024ff:	74 1e                	je     8010251f <namex+0x9e>
80102501:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102504:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102508:	98                   	cwtl   
80102509:	c1 e0 04             	shl    $0x4,%eax
8010250c:	05 00 22 11 80       	add    $0x80112200,%eax
80102511:	8b 00                	mov    (%eax),%eax
80102513:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102516:	89 14 24             	mov    %edx,(%esp)
80102519:	ff d0                	call   *%eax
8010251b:	85 c0                	test   %eax,%eax
8010251d:	75 15                	jne    80102534 <namex+0xb3>
      iunlockput(ip);
8010251f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102522:	89 04 24             	mov    %eax,(%esp)
80102525:	e8 6d f6 ff ff       	call   80101b97 <iunlockput>
      return 0;
8010252a:	b8 00 00 00 00       	mov    $0x0,%eax
8010252f:	e9 a3 00 00 00       	jmp    801025d7 <namex+0x156>
    }
    if(nameiparent && *path == '\0'){
80102534:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102538:	74 1d                	je     80102557 <namex+0xd6>
8010253a:	8b 45 08             	mov    0x8(%ebp),%eax
8010253d:	0f b6 00             	movzbl (%eax),%eax
80102540:	84 c0                	test   %al,%al
80102542:	75 13                	jne    80102557 <namex+0xd6>
      // Stop one level early.
      iunlock(ip);
80102544:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102547:	89 04 24             	mov    %eax,(%esp)
8010254a:	e8 12 f5 ff ff       	call   80101a61 <iunlock>
      return ip;
8010254f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102552:	e9 80 00 00 00       	jmp    801025d7 <namex+0x156>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
80102557:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010255e:	00 
8010255f:	8b 45 10             	mov    0x10(%ebp),%eax
80102562:	89 44 24 04          	mov    %eax,0x4(%esp)
80102566:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102569:	89 04 24             	mov    %eax,(%esp)
8010256c:	e8 d7 fb ff ff       	call   80102148 <dirlookup>
80102571:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102574:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102578:	75 12                	jne    8010258c <namex+0x10b>
      iunlockput(ip);
8010257a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010257d:	89 04 24             	mov    %eax,(%esp)
80102580:	e8 12 f6 ff ff       	call   80101b97 <iunlockput>
      return 0;
80102585:	b8 00 00 00 00       	mov    $0x0,%eax
8010258a:	eb 4b                	jmp    801025d7 <namex+0x156>
    }
    iunlockput(ip);
8010258c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010258f:	89 04 24             	mov    %eax,(%esp)
80102592:	e8 00 f6 ff ff       	call   80101b97 <iunlockput>
    ip = next;
80102597:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010259a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
8010259d:	8b 45 10             	mov    0x10(%ebp),%eax
801025a0:	89 44 24 04          	mov    %eax,0x4(%esp)
801025a4:	8b 45 08             	mov    0x8(%ebp),%eax
801025a7:	89 04 24             	mov    %eax,(%esp)
801025aa:	e8 20 fe ff ff       	call   801023cf <skipelem>
801025af:	89 45 08             	mov    %eax,0x8(%ebp)
801025b2:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801025b6:	0f 85 0a ff ff ff    	jne    801024c6 <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
801025bc:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801025c0:	74 12                	je     801025d4 <namex+0x153>
    iput(ip);
801025c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025c5:	89 04 24             	mov    %eax,(%esp)
801025c8:	e8 f9 f4 ff ff       	call   80101ac6 <iput>
    return 0;
801025cd:	b8 00 00 00 00       	mov    $0x0,%eax
801025d2:	eb 03                	jmp    801025d7 <namex+0x156>
  }
  return ip;
801025d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801025d7:	c9                   	leave  
801025d8:	c3                   	ret    

801025d9 <namei>:

struct inode*
namei(char *path)
{
801025d9:	55                   	push   %ebp
801025da:	89 e5                	mov    %esp,%ebp
801025dc:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
801025df:	8d 45 ea             	lea    -0x16(%ebp),%eax
801025e2:	89 44 24 08          	mov    %eax,0x8(%esp)
801025e6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801025ed:	00 
801025ee:	8b 45 08             	mov    0x8(%ebp),%eax
801025f1:	89 04 24             	mov    %eax,(%esp)
801025f4:	e8 88 fe ff ff       	call   80102481 <namex>
}
801025f9:	c9                   	leave  
801025fa:	c3                   	ret    

801025fb <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
801025fb:	55                   	push   %ebp
801025fc:	89 e5                	mov    %esp,%ebp
801025fe:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
80102601:	8b 45 0c             	mov    0xc(%ebp),%eax
80102604:	89 44 24 08          	mov    %eax,0x8(%esp)
80102608:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010260f:	00 
80102610:	8b 45 08             	mov    0x8(%ebp),%eax
80102613:	89 04 24             	mov    %eax,(%esp)
80102616:	e8 66 fe ff ff       	call   80102481 <namex>
}
8010261b:	c9                   	leave  
8010261c:	c3                   	ret    

8010261d <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
8010261d:	55                   	push   %ebp
8010261e:	89 e5                	mov    %esp,%ebp
80102620:	83 ec 14             	sub    $0x14,%esp
80102623:	8b 45 08             	mov    0x8(%ebp),%eax
80102626:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010262a:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
8010262e:	89 c2                	mov    %eax,%edx
80102630:	ec                   	in     (%dx),%al
80102631:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102634:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102638:	c9                   	leave  
80102639:	c3                   	ret    

8010263a <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
8010263a:	55                   	push   %ebp
8010263b:	89 e5                	mov    %esp,%ebp
8010263d:	57                   	push   %edi
8010263e:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
8010263f:	8b 55 08             	mov    0x8(%ebp),%edx
80102642:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102645:	8b 45 10             	mov    0x10(%ebp),%eax
80102648:	89 cb                	mov    %ecx,%ebx
8010264a:	89 df                	mov    %ebx,%edi
8010264c:	89 c1                	mov    %eax,%ecx
8010264e:	fc                   	cld    
8010264f:	f3 6d                	rep insl (%dx),%es:(%edi)
80102651:	89 c8                	mov    %ecx,%eax
80102653:	89 fb                	mov    %edi,%ebx
80102655:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102658:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
8010265b:	5b                   	pop    %ebx
8010265c:	5f                   	pop    %edi
8010265d:	5d                   	pop    %ebp
8010265e:	c3                   	ret    

8010265f <outb>:

static inline void
outb(ushort port, uchar data)
{
8010265f:	55                   	push   %ebp
80102660:	89 e5                	mov    %esp,%ebp
80102662:	83 ec 08             	sub    $0x8,%esp
80102665:	8b 55 08             	mov    0x8(%ebp),%edx
80102668:	8b 45 0c             	mov    0xc(%ebp),%eax
8010266b:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010266f:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102672:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102676:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010267a:	ee                   	out    %al,(%dx)
}
8010267b:	c9                   	leave  
8010267c:	c3                   	ret    

8010267d <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
8010267d:	55                   	push   %ebp
8010267e:	89 e5                	mov    %esp,%ebp
80102680:	56                   	push   %esi
80102681:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
80102682:	8b 55 08             	mov    0x8(%ebp),%edx
80102685:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102688:	8b 45 10             	mov    0x10(%ebp),%eax
8010268b:	89 cb                	mov    %ecx,%ebx
8010268d:	89 de                	mov    %ebx,%esi
8010268f:	89 c1                	mov    %eax,%ecx
80102691:	fc                   	cld    
80102692:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80102694:	89 c8                	mov    %ecx,%eax
80102696:	89 f3                	mov    %esi,%ebx
80102698:	89 5d 0c             	mov    %ebx,0xc(%ebp)
8010269b:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
8010269e:	5b                   	pop    %ebx
8010269f:	5e                   	pop    %esi
801026a0:	5d                   	pop    %ebp
801026a1:	c3                   	ret    

801026a2 <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
801026a2:	55                   	push   %ebp
801026a3:	89 e5                	mov    %esp,%ebp
801026a5:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
801026a8:	90                   	nop
801026a9:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801026b0:	e8 68 ff ff ff       	call   8010261d <inb>
801026b5:	0f b6 c0             	movzbl %al,%eax
801026b8:	89 45 fc             	mov    %eax,-0x4(%ebp)
801026bb:	8b 45 fc             	mov    -0x4(%ebp),%eax
801026be:	25 c0 00 00 00       	and    $0xc0,%eax
801026c3:	83 f8 40             	cmp    $0x40,%eax
801026c6:	75 e1                	jne    801026a9 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
801026c8:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801026cc:	74 11                	je     801026df <idewait+0x3d>
801026ce:	8b 45 fc             	mov    -0x4(%ebp),%eax
801026d1:	83 e0 21             	and    $0x21,%eax
801026d4:	85 c0                	test   %eax,%eax
801026d6:	74 07                	je     801026df <idewait+0x3d>
    return -1;
801026d8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801026dd:	eb 05                	jmp    801026e4 <idewait+0x42>
  return 0;
801026df:	b8 00 00 00 00       	mov    $0x0,%eax
}
801026e4:	c9                   	leave  
801026e5:	c3                   	ret    

801026e6 <ideinit>:

void
ideinit(void)
{
801026e6:	55                   	push   %ebp
801026e7:	89 e5                	mov    %esp,%ebp
801026e9:	83 ec 28             	sub    $0x28,%esp
  int i;

  initlock(&idelock, "ide");
801026ec:	c7 44 24 04 62 93 10 	movl   $0x80109362,0x4(%esp)
801026f3:	80 
801026f4:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
801026fb:	e8 b5 33 00 00       	call   80105ab5 <initlock>
  picenable(IRQ_IDE);
80102700:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102707:	e8 80 18 00 00       	call   80103f8c <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
8010270c:	a1 a0 39 11 80       	mov    0x801139a0,%eax
80102711:	83 e8 01             	sub    $0x1,%eax
80102714:	89 44 24 04          	mov    %eax,0x4(%esp)
80102718:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
8010271f:	e8 0c 04 00 00       	call   80102b30 <ioapicenable>
  idewait(0);
80102724:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010272b:	e8 72 ff ff ff       	call   801026a2 <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
80102730:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
80102737:	00 
80102738:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
8010273f:	e8 1b ff ff ff       	call   8010265f <outb>
  for(i=0; i<1000; i++){
80102744:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010274b:	eb 20                	jmp    8010276d <ideinit+0x87>
    if(inb(0x1f7) != 0){
8010274d:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102754:	e8 c4 fe ff ff       	call   8010261d <inb>
80102759:	84 c0                	test   %al,%al
8010275b:	74 0c                	je     80102769 <ideinit+0x83>
      havedisk1 = 1;
8010275d:	c7 05 58 c6 10 80 01 	movl   $0x1,0x8010c658
80102764:	00 00 00 
      break;
80102767:	eb 0d                	jmp    80102776 <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
80102769:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010276d:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
80102774:	7e d7                	jle    8010274d <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
80102776:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
8010277d:	00 
8010277e:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102785:	e8 d5 fe ff ff       	call   8010265f <outb>
}
8010278a:	c9                   	leave  
8010278b:	c3                   	ret    

8010278c <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
8010278c:	55                   	push   %ebp
8010278d:	89 e5                	mov    %esp,%ebp
8010278f:	83 ec 18             	sub    $0x18,%esp
  if(b == 0)
80102792:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102796:	75 0c                	jne    801027a4 <idestart+0x18>
    panic("idestart");
80102798:	c7 04 24 66 93 10 80 	movl   $0x80109366,(%esp)
8010279f:	e8 96 dd ff ff       	call   8010053a <panic>

  idewait(0);
801027a4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801027ab:	e8 f2 fe ff ff       	call   801026a2 <idewait>
  outb(0x3f6, 0);  // generate interrupt
801027b0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801027b7:	00 
801027b8:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
801027bf:	e8 9b fe ff ff       	call   8010265f <outb>
  outb(0x1f2, 1);  // number of sectors
801027c4:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801027cb:	00 
801027cc:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
801027d3:	e8 87 fe ff ff       	call   8010265f <outb>
  outb(0x1f3, b->sector & 0xff);
801027d8:	8b 45 08             	mov    0x8(%ebp),%eax
801027db:	8b 40 08             	mov    0x8(%eax),%eax
801027de:	0f b6 c0             	movzbl %al,%eax
801027e1:	89 44 24 04          	mov    %eax,0x4(%esp)
801027e5:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
801027ec:	e8 6e fe ff ff       	call   8010265f <outb>
  outb(0x1f4, (b->sector >> 8) & 0xff);
801027f1:	8b 45 08             	mov    0x8(%ebp),%eax
801027f4:	8b 40 08             	mov    0x8(%eax),%eax
801027f7:	c1 e8 08             	shr    $0x8,%eax
801027fa:	0f b6 c0             	movzbl %al,%eax
801027fd:	89 44 24 04          	mov    %eax,0x4(%esp)
80102801:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
80102808:	e8 52 fe ff ff       	call   8010265f <outb>
  outb(0x1f5, (b->sector >> 16) & 0xff);
8010280d:	8b 45 08             	mov    0x8(%ebp),%eax
80102810:	8b 40 08             	mov    0x8(%eax),%eax
80102813:	c1 e8 10             	shr    $0x10,%eax
80102816:	0f b6 c0             	movzbl %al,%eax
80102819:	89 44 24 04          	mov    %eax,0x4(%esp)
8010281d:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
80102824:	e8 36 fe ff ff       	call   8010265f <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((b->sector>>24)&0x0f));
80102829:	8b 45 08             	mov    0x8(%ebp),%eax
8010282c:	8b 40 04             	mov    0x4(%eax),%eax
8010282f:	83 e0 01             	and    $0x1,%eax
80102832:	c1 e0 04             	shl    $0x4,%eax
80102835:	89 c2                	mov    %eax,%edx
80102837:	8b 45 08             	mov    0x8(%ebp),%eax
8010283a:	8b 40 08             	mov    0x8(%eax),%eax
8010283d:	c1 e8 18             	shr    $0x18,%eax
80102840:	83 e0 0f             	and    $0xf,%eax
80102843:	09 d0                	or     %edx,%eax
80102845:	83 c8 e0             	or     $0xffffffe0,%eax
80102848:	0f b6 c0             	movzbl %al,%eax
8010284b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010284f:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102856:	e8 04 fe ff ff       	call   8010265f <outb>
  if(b->flags & B_DIRTY){
8010285b:	8b 45 08             	mov    0x8(%ebp),%eax
8010285e:	8b 00                	mov    (%eax),%eax
80102860:	83 e0 04             	and    $0x4,%eax
80102863:	85 c0                	test   %eax,%eax
80102865:	74 34                	je     8010289b <idestart+0x10f>
    outb(0x1f7, IDE_CMD_WRITE);
80102867:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
8010286e:	00 
8010286f:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102876:	e8 e4 fd ff ff       	call   8010265f <outb>
    outsl(0x1f0, b->data, 512/4);
8010287b:	8b 45 08             	mov    0x8(%ebp),%eax
8010287e:	83 c0 18             	add    $0x18,%eax
80102881:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102888:	00 
80102889:	89 44 24 04          	mov    %eax,0x4(%esp)
8010288d:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102894:	e8 e4 fd ff ff       	call   8010267d <outsl>
80102899:	eb 14                	jmp    801028af <idestart+0x123>
  } else {
    outb(0x1f7, IDE_CMD_READ);
8010289b:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
801028a2:	00 
801028a3:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801028aa:	e8 b0 fd ff ff       	call   8010265f <outb>
  }
}
801028af:	c9                   	leave  
801028b0:	c3                   	ret    

801028b1 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
801028b1:	55                   	push   %ebp
801028b2:	89 e5                	mov    %esp,%ebp
801028b4:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
801028b7:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
801028be:	e8 13 32 00 00       	call   80105ad6 <acquire>
  if((b = idequeue) == 0){
801028c3:	a1 54 c6 10 80       	mov    0x8010c654,%eax
801028c8:	89 45 f4             	mov    %eax,-0xc(%ebp)
801028cb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801028cf:	75 11                	jne    801028e2 <ideintr+0x31>
    release(&idelock);
801028d1:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
801028d8:	e8 5b 32 00 00       	call   80105b38 <release>
    // cprintf("spurious IDE interrupt\n");
    return;
801028dd:	e9 90 00 00 00       	jmp    80102972 <ideintr+0xc1>
  }
  idequeue = b->qnext;
801028e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028e5:	8b 40 14             	mov    0x14(%eax),%eax
801028e8:	a3 54 c6 10 80       	mov    %eax,0x8010c654

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
801028ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028f0:	8b 00                	mov    (%eax),%eax
801028f2:	83 e0 04             	and    $0x4,%eax
801028f5:	85 c0                	test   %eax,%eax
801028f7:	75 2e                	jne    80102927 <ideintr+0x76>
801028f9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102900:	e8 9d fd ff ff       	call   801026a2 <idewait>
80102905:	85 c0                	test   %eax,%eax
80102907:	78 1e                	js     80102927 <ideintr+0x76>
    insl(0x1f0, b->data, 512/4);
80102909:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010290c:	83 c0 18             	add    $0x18,%eax
8010290f:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102916:	00 
80102917:	89 44 24 04          	mov    %eax,0x4(%esp)
8010291b:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102922:	e8 13 fd ff ff       	call   8010263a <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80102927:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010292a:	8b 00                	mov    (%eax),%eax
8010292c:	83 c8 02             	or     $0x2,%eax
8010292f:	89 c2                	mov    %eax,%edx
80102931:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102934:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
80102936:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102939:	8b 00                	mov    (%eax),%eax
8010293b:	83 e0 fb             	and    $0xfffffffb,%eax
8010293e:	89 c2                	mov    %eax,%edx
80102940:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102943:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80102945:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102948:	89 04 24             	mov    %eax,(%esp)
8010294b:	e8 90 24 00 00       	call   80104de0 <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
80102950:	a1 54 c6 10 80       	mov    0x8010c654,%eax
80102955:	85 c0                	test   %eax,%eax
80102957:	74 0d                	je     80102966 <ideintr+0xb5>
    idestart(idequeue);
80102959:	a1 54 c6 10 80       	mov    0x8010c654,%eax
8010295e:	89 04 24             	mov    %eax,(%esp)
80102961:	e8 26 fe ff ff       	call   8010278c <idestart>

  release(&idelock);
80102966:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
8010296d:	e8 c6 31 00 00       	call   80105b38 <release>
}
80102972:	c9                   	leave  
80102973:	c3                   	ret    

80102974 <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80102974:	55                   	push   %ebp
80102975:	89 e5                	mov    %esp,%ebp
80102977:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
8010297a:	8b 45 08             	mov    0x8(%ebp),%eax
8010297d:	8b 00                	mov    (%eax),%eax
8010297f:	83 e0 01             	and    $0x1,%eax
80102982:	85 c0                	test   %eax,%eax
80102984:	75 0c                	jne    80102992 <iderw+0x1e>
    panic("iderw: buf not busy");
80102986:	c7 04 24 6f 93 10 80 	movl   $0x8010936f,(%esp)
8010298d:	e8 a8 db ff ff       	call   8010053a <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80102992:	8b 45 08             	mov    0x8(%ebp),%eax
80102995:	8b 00                	mov    (%eax),%eax
80102997:	83 e0 06             	and    $0x6,%eax
8010299a:	83 f8 02             	cmp    $0x2,%eax
8010299d:	75 0c                	jne    801029ab <iderw+0x37>
    panic("iderw: nothing to do");
8010299f:	c7 04 24 83 93 10 80 	movl   $0x80109383,(%esp)
801029a6:	e8 8f db ff ff       	call   8010053a <panic>
  if(b->dev != 0 && !havedisk1)
801029ab:	8b 45 08             	mov    0x8(%ebp),%eax
801029ae:	8b 40 04             	mov    0x4(%eax),%eax
801029b1:	85 c0                	test   %eax,%eax
801029b3:	74 15                	je     801029ca <iderw+0x56>
801029b5:	a1 58 c6 10 80       	mov    0x8010c658,%eax
801029ba:	85 c0                	test   %eax,%eax
801029bc:	75 0c                	jne    801029ca <iderw+0x56>
    panic("iderw: ide disk 1 not present");
801029be:	c7 04 24 98 93 10 80 	movl   $0x80109398,(%esp)
801029c5:	e8 70 db ff ff       	call   8010053a <panic>

  acquire(&idelock);  //DOC:acquire-lock
801029ca:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
801029d1:	e8 00 31 00 00       	call   80105ad6 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
801029d6:	8b 45 08             	mov    0x8(%ebp),%eax
801029d9:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
801029e0:	c7 45 f4 54 c6 10 80 	movl   $0x8010c654,-0xc(%ebp)
801029e7:	eb 0b                	jmp    801029f4 <iderw+0x80>
801029e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029ec:	8b 00                	mov    (%eax),%eax
801029ee:	83 c0 14             	add    $0x14,%eax
801029f1:	89 45 f4             	mov    %eax,-0xc(%ebp)
801029f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029f7:	8b 00                	mov    (%eax),%eax
801029f9:	85 c0                	test   %eax,%eax
801029fb:	75 ec                	jne    801029e9 <iderw+0x75>
    ;
  *pp = b;
801029fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a00:	8b 55 08             	mov    0x8(%ebp),%edx
80102a03:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
80102a05:	a1 54 c6 10 80       	mov    0x8010c654,%eax
80102a0a:	3b 45 08             	cmp    0x8(%ebp),%eax
80102a0d:	75 0d                	jne    80102a1c <iderw+0xa8>
    idestart(b);
80102a0f:	8b 45 08             	mov    0x8(%ebp),%eax
80102a12:	89 04 24             	mov    %eax,(%esp)
80102a15:	e8 72 fd ff ff       	call   8010278c <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102a1a:	eb 15                	jmp    80102a31 <iderw+0xbd>
80102a1c:	eb 13                	jmp    80102a31 <iderw+0xbd>
    sleep(b, &idelock);
80102a1e:	c7 44 24 04 20 c6 10 	movl   $0x8010c620,0x4(%esp)
80102a25:	80 
80102a26:	8b 45 08             	mov    0x8(%ebp),%eax
80102a29:	89 04 24             	mov    %eax,(%esp)
80102a2c:	e8 d3 22 00 00       	call   80104d04 <sleep>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102a31:	8b 45 08             	mov    0x8(%ebp),%eax
80102a34:	8b 00                	mov    (%eax),%eax
80102a36:	83 e0 06             	and    $0x6,%eax
80102a39:	83 f8 02             	cmp    $0x2,%eax
80102a3c:	75 e0                	jne    80102a1e <iderw+0xaa>
    sleep(b, &idelock);
  }

  release(&idelock);
80102a3e:	c7 04 24 20 c6 10 80 	movl   $0x8010c620,(%esp)
80102a45:	e8 ee 30 00 00       	call   80105b38 <release>
}
80102a4a:	c9                   	leave  
80102a4b:	c3                   	ret    

80102a4c <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80102a4c:	55                   	push   %ebp
80102a4d:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102a4f:	a1 74 32 11 80       	mov    0x80113274,%eax
80102a54:	8b 55 08             	mov    0x8(%ebp),%edx
80102a57:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
80102a59:	a1 74 32 11 80       	mov    0x80113274,%eax
80102a5e:	8b 40 10             	mov    0x10(%eax),%eax
}
80102a61:	5d                   	pop    %ebp
80102a62:	c3                   	ret    

80102a63 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80102a63:	55                   	push   %ebp
80102a64:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102a66:	a1 74 32 11 80       	mov    0x80113274,%eax
80102a6b:	8b 55 08             	mov    0x8(%ebp),%edx
80102a6e:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
80102a70:	a1 74 32 11 80       	mov    0x80113274,%eax
80102a75:	8b 55 0c             	mov    0xc(%ebp),%edx
80102a78:	89 50 10             	mov    %edx,0x10(%eax)
}
80102a7b:	5d                   	pop    %ebp
80102a7c:	c3                   	ret    

80102a7d <ioapicinit>:

void
ioapicinit(void)
{
80102a7d:	55                   	push   %ebp
80102a7e:	89 e5                	mov    %esp,%ebp
80102a80:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
80102a83:	a1 a4 33 11 80       	mov    0x801133a4,%eax
80102a88:	85 c0                	test   %eax,%eax
80102a8a:	75 05                	jne    80102a91 <ioapicinit+0x14>
    return;
80102a8c:	e9 9d 00 00 00       	jmp    80102b2e <ioapicinit+0xb1>

  ioapic = (volatile struct ioapic*)IOAPIC;
80102a91:	c7 05 74 32 11 80 00 	movl   $0xfec00000,0x80113274
80102a98:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80102a9b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102aa2:	e8 a5 ff ff ff       	call   80102a4c <ioapicread>
80102aa7:	c1 e8 10             	shr    $0x10,%eax
80102aaa:	25 ff 00 00 00       	and    $0xff,%eax
80102aaf:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80102ab2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102ab9:	e8 8e ff ff ff       	call   80102a4c <ioapicread>
80102abe:	c1 e8 18             	shr    $0x18,%eax
80102ac1:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
80102ac4:	0f b6 05 a0 33 11 80 	movzbl 0x801133a0,%eax
80102acb:	0f b6 c0             	movzbl %al,%eax
80102ace:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80102ad1:	74 0c                	je     80102adf <ioapicinit+0x62>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80102ad3:	c7 04 24 b8 93 10 80 	movl   $0x801093b8,(%esp)
80102ada:	e8 c1 d8 ff ff       	call   801003a0 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102adf:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102ae6:	eb 3e                	jmp    80102b26 <ioapicinit+0xa9>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80102ae8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102aeb:	83 c0 20             	add    $0x20,%eax
80102aee:	0d 00 00 01 00       	or     $0x10000,%eax
80102af3:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102af6:	83 c2 08             	add    $0x8,%edx
80102af9:	01 d2                	add    %edx,%edx
80102afb:	89 44 24 04          	mov    %eax,0x4(%esp)
80102aff:	89 14 24             	mov    %edx,(%esp)
80102b02:	e8 5c ff ff ff       	call   80102a63 <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80102b07:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b0a:	83 c0 08             	add    $0x8,%eax
80102b0d:	01 c0                	add    %eax,%eax
80102b0f:	83 c0 01             	add    $0x1,%eax
80102b12:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102b19:	00 
80102b1a:	89 04 24             	mov    %eax,(%esp)
80102b1d:	e8 41 ff ff ff       	call   80102a63 <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102b22:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102b26:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b29:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80102b2c:	7e ba                	jle    80102ae8 <ioapicinit+0x6b>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80102b2e:	c9                   	leave  
80102b2f:	c3                   	ret    

80102b30 <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80102b30:	55                   	push   %ebp
80102b31:	89 e5                	mov    %esp,%ebp
80102b33:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
80102b36:	a1 a4 33 11 80       	mov    0x801133a4,%eax
80102b3b:	85 c0                	test   %eax,%eax
80102b3d:	75 02                	jne    80102b41 <ioapicenable+0x11>
    return;
80102b3f:	eb 37                	jmp    80102b78 <ioapicenable+0x48>

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80102b41:	8b 45 08             	mov    0x8(%ebp),%eax
80102b44:	83 c0 20             	add    $0x20,%eax
80102b47:	8b 55 08             	mov    0x8(%ebp),%edx
80102b4a:	83 c2 08             	add    $0x8,%edx
80102b4d:	01 d2                	add    %edx,%edx
80102b4f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b53:	89 14 24             	mov    %edx,(%esp)
80102b56:	e8 08 ff ff ff       	call   80102a63 <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80102b5b:	8b 45 0c             	mov    0xc(%ebp),%eax
80102b5e:	c1 e0 18             	shl    $0x18,%eax
80102b61:	8b 55 08             	mov    0x8(%ebp),%edx
80102b64:	83 c2 08             	add    $0x8,%edx
80102b67:	01 d2                	add    %edx,%edx
80102b69:	83 c2 01             	add    $0x1,%edx
80102b6c:	89 44 24 04          	mov    %eax,0x4(%esp)
80102b70:	89 14 24             	mov    %edx,(%esp)
80102b73:	e8 eb fe ff ff       	call   80102a63 <ioapicwrite>
}
80102b78:	c9                   	leave  
80102b79:	c3                   	ret    

80102b7a <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80102b7a:	55                   	push   %ebp
80102b7b:	89 e5                	mov    %esp,%ebp
80102b7d:	8b 45 08             	mov    0x8(%ebp),%eax
80102b80:	05 00 00 00 80       	add    $0x80000000,%eax
80102b85:	5d                   	pop    %ebp
80102b86:	c3                   	ret    

80102b87 <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
80102b87:	55                   	push   %ebp
80102b88:	89 e5                	mov    %esp,%ebp
80102b8a:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
80102b8d:	c7 44 24 04 ea 93 10 	movl   $0x801093ea,0x4(%esp)
80102b94:	80 
80102b95:	c7 04 24 80 32 11 80 	movl   $0x80113280,(%esp)
80102b9c:	e8 14 2f 00 00       	call   80105ab5 <initlock>
  kmem.use_lock = 0;
80102ba1:	c7 05 b4 32 11 80 00 	movl   $0x0,0x801132b4
80102ba8:	00 00 00 
  freerange(vstart, vend);
80102bab:	8b 45 0c             	mov    0xc(%ebp),%eax
80102bae:	89 44 24 04          	mov    %eax,0x4(%esp)
80102bb2:	8b 45 08             	mov    0x8(%ebp),%eax
80102bb5:	89 04 24             	mov    %eax,(%esp)
80102bb8:	e8 26 00 00 00       	call   80102be3 <freerange>
}
80102bbd:	c9                   	leave  
80102bbe:	c3                   	ret    

80102bbf <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80102bbf:	55                   	push   %ebp
80102bc0:	89 e5                	mov    %esp,%ebp
80102bc2:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80102bc5:	8b 45 0c             	mov    0xc(%ebp),%eax
80102bc8:	89 44 24 04          	mov    %eax,0x4(%esp)
80102bcc:	8b 45 08             	mov    0x8(%ebp),%eax
80102bcf:	89 04 24             	mov    %eax,(%esp)
80102bd2:	e8 0c 00 00 00       	call   80102be3 <freerange>
  kmem.use_lock = 1;
80102bd7:	c7 05 b4 32 11 80 01 	movl   $0x1,0x801132b4
80102bde:	00 00 00 
}
80102be1:	c9                   	leave  
80102be2:	c3                   	ret    

80102be3 <freerange>:

void
freerange(void *vstart, void *vend)
{
80102be3:	55                   	push   %ebp
80102be4:	89 e5                	mov    %esp,%ebp
80102be6:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80102be9:	8b 45 08             	mov    0x8(%ebp),%eax
80102bec:	05 ff 0f 00 00       	add    $0xfff,%eax
80102bf1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102bf6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102bf9:	eb 12                	jmp    80102c0d <freerange+0x2a>
    kfree(p);
80102bfb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102bfe:	89 04 24             	mov    %eax,(%esp)
80102c01:	e8 16 00 00 00       	call   80102c1c <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102c06:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80102c0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c10:	05 00 10 00 00       	add    $0x1000,%eax
80102c15:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102c18:	76 e1                	jbe    80102bfb <freerange+0x18>
    kfree(p);
}
80102c1a:	c9                   	leave  
80102c1b:	c3                   	ret    

80102c1c <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80102c1c:	55                   	push   %ebp
80102c1d:	89 e5                	mov    %esp,%ebp
80102c1f:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
80102c22:	8b 45 08             	mov    0x8(%ebp),%eax
80102c25:	25 ff 0f 00 00       	and    $0xfff,%eax
80102c2a:	85 c0                	test   %eax,%eax
80102c2c:	75 1b                	jne    80102c49 <kfree+0x2d>
80102c2e:	81 7d 08 9c 7b 11 80 	cmpl   $0x80117b9c,0x8(%ebp)
80102c35:	72 12                	jb     80102c49 <kfree+0x2d>
80102c37:	8b 45 08             	mov    0x8(%ebp),%eax
80102c3a:	89 04 24             	mov    %eax,(%esp)
80102c3d:	e8 38 ff ff ff       	call   80102b7a <v2p>
80102c42:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102c47:	76 0c                	jbe    80102c55 <kfree+0x39>
    panic("kfree");
80102c49:	c7 04 24 ef 93 10 80 	movl   $0x801093ef,(%esp)
80102c50:	e8 e5 d8 ff ff       	call   8010053a <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102c55:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102c5c:	00 
80102c5d:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102c64:	00 
80102c65:	8b 45 08             	mov    0x8(%ebp),%eax
80102c68:	89 04 24             	mov    %eax,(%esp)
80102c6b:	e8 ba 30 00 00       	call   80105d2a <memset>

  if(kmem.use_lock)
80102c70:	a1 b4 32 11 80       	mov    0x801132b4,%eax
80102c75:	85 c0                	test   %eax,%eax
80102c77:	74 0c                	je     80102c85 <kfree+0x69>
    acquire(&kmem.lock);
80102c79:	c7 04 24 80 32 11 80 	movl   $0x80113280,(%esp)
80102c80:	e8 51 2e 00 00       	call   80105ad6 <acquire>
  r = (struct run*)v;
80102c85:	8b 45 08             	mov    0x8(%ebp),%eax
80102c88:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80102c8b:	8b 15 b8 32 11 80    	mov    0x801132b8,%edx
80102c91:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c94:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80102c96:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c99:	a3 b8 32 11 80       	mov    %eax,0x801132b8
  if(kmem.use_lock)
80102c9e:	a1 b4 32 11 80       	mov    0x801132b4,%eax
80102ca3:	85 c0                	test   %eax,%eax
80102ca5:	74 0c                	je     80102cb3 <kfree+0x97>
    release(&kmem.lock);
80102ca7:	c7 04 24 80 32 11 80 	movl   $0x80113280,(%esp)
80102cae:	e8 85 2e 00 00       	call   80105b38 <release>
}
80102cb3:	c9                   	leave  
80102cb4:	c3                   	ret    

80102cb5 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80102cb5:	55                   	push   %ebp
80102cb6:	89 e5                	mov    %esp,%ebp
80102cb8:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80102cbb:	a1 b4 32 11 80       	mov    0x801132b4,%eax
80102cc0:	85 c0                	test   %eax,%eax
80102cc2:	74 0c                	je     80102cd0 <kalloc+0x1b>
    acquire(&kmem.lock);
80102cc4:	c7 04 24 80 32 11 80 	movl   $0x80113280,(%esp)
80102ccb:	e8 06 2e 00 00       	call   80105ad6 <acquire>
  r = kmem.freelist;
80102cd0:	a1 b8 32 11 80       	mov    0x801132b8,%eax
80102cd5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80102cd8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102cdc:	74 0a                	je     80102ce8 <kalloc+0x33>
    kmem.freelist = r->next;
80102cde:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ce1:	8b 00                	mov    (%eax),%eax
80102ce3:	a3 b8 32 11 80       	mov    %eax,0x801132b8
  if(kmem.use_lock)
80102ce8:	a1 b4 32 11 80       	mov    0x801132b4,%eax
80102ced:	85 c0                	test   %eax,%eax
80102cef:	74 0c                	je     80102cfd <kalloc+0x48>
    release(&kmem.lock);
80102cf1:	c7 04 24 80 32 11 80 	movl   $0x80113280,(%esp)
80102cf8:	e8 3b 2e 00 00       	call   80105b38 <release>
  return (char*)r;
80102cfd:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102d00:	c9                   	leave  
80102d01:	c3                   	ret    

80102d02 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102d02:	55                   	push   %ebp
80102d03:	89 e5                	mov    %esp,%ebp
80102d05:	83 ec 14             	sub    $0x14,%esp
80102d08:	8b 45 08             	mov    0x8(%ebp),%eax
80102d0b:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102d0f:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102d13:	89 c2                	mov    %eax,%edx
80102d15:	ec                   	in     (%dx),%al
80102d16:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102d19:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102d1d:	c9                   	leave  
80102d1e:	c3                   	ret    

80102d1f <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102d1f:	55                   	push   %ebp
80102d20:	89 e5                	mov    %esp,%ebp
80102d22:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80102d25:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80102d2c:	e8 d1 ff ff ff       	call   80102d02 <inb>
80102d31:	0f b6 c0             	movzbl %al,%eax
80102d34:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80102d37:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d3a:	83 e0 01             	and    $0x1,%eax
80102d3d:	85 c0                	test   %eax,%eax
80102d3f:	75 0a                	jne    80102d4b <kbdgetc+0x2c>
    return -1;
80102d41:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102d46:	e9 25 01 00 00       	jmp    80102e70 <kbdgetc+0x151>
  data = inb(KBDATAP);
80102d4b:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80102d52:	e8 ab ff ff ff       	call   80102d02 <inb>
80102d57:	0f b6 c0             	movzbl %al,%eax
80102d5a:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80102d5d:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80102d64:	75 17                	jne    80102d7d <kbdgetc+0x5e>
    shift |= E0ESC;
80102d66:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80102d6b:	83 c8 40             	or     $0x40,%eax
80102d6e:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
    return 0;
80102d73:	b8 00 00 00 00       	mov    $0x0,%eax
80102d78:	e9 f3 00 00 00       	jmp    80102e70 <kbdgetc+0x151>
  } else if(data & 0x80){
80102d7d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d80:	25 80 00 00 00       	and    $0x80,%eax
80102d85:	85 c0                	test   %eax,%eax
80102d87:	74 45                	je     80102dce <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80102d89:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80102d8e:	83 e0 40             	and    $0x40,%eax
80102d91:	85 c0                	test   %eax,%eax
80102d93:	75 08                	jne    80102d9d <kbdgetc+0x7e>
80102d95:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d98:	83 e0 7f             	and    $0x7f,%eax
80102d9b:	eb 03                	jmp    80102da0 <kbdgetc+0x81>
80102d9d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102da0:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80102da3:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102da6:	05 20 a0 10 80       	add    $0x8010a020,%eax
80102dab:	0f b6 00             	movzbl (%eax),%eax
80102dae:	83 c8 40             	or     $0x40,%eax
80102db1:	0f b6 c0             	movzbl %al,%eax
80102db4:	f7 d0                	not    %eax
80102db6:	89 c2                	mov    %eax,%edx
80102db8:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80102dbd:	21 d0                	and    %edx,%eax
80102dbf:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
    return 0;
80102dc4:	b8 00 00 00 00       	mov    $0x0,%eax
80102dc9:	e9 a2 00 00 00       	jmp    80102e70 <kbdgetc+0x151>
  } else if(shift & E0ESC){
80102dce:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80102dd3:	83 e0 40             	and    $0x40,%eax
80102dd6:	85 c0                	test   %eax,%eax
80102dd8:	74 14                	je     80102dee <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102dda:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80102de1:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80102de6:	83 e0 bf             	and    $0xffffffbf,%eax
80102de9:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  }

  shift |= shiftcode[data];
80102dee:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102df1:	05 20 a0 10 80       	add    $0x8010a020,%eax
80102df6:	0f b6 00             	movzbl (%eax),%eax
80102df9:	0f b6 d0             	movzbl %al,%edx
80102dfc:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80102e01:	09 d0                	or     %edx,%eax
80102e03:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  shift ^= togglecode[data];
80102e08:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102e0b:	05 20 a1 10 80       	add    $0x8010a120,%eax
80102e10:	0f b6 00             	movzbl (%eax),%eax
80102e13:	0f b6 d0             	movzbl %al,%edx
80102e16:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80102e1b:	31 d0                	xor    %edx,%eax
80102e1d:	a3 5c c6 10 80       	mov    %eax,0x8010c65c
  c = charcode[shift & (CTL | SHIFT)][data];
80102e22:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80102e27:	83 e0 03             	and    $0x3,%eax
80102e2a:	8b 14 85 20 a5 10 80 	mov    -0x7fef5ae0(,%eax,4),%edx
80102e31:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102e34:	01 d0                	add    %edx,%eax
80102e36:	0f b6 00             	movzbl (%eax),%eax
80102e39:	0f b6 c0             	movzbl %al,%eax
80102e3c:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80102e3f:	a1 5c c6 10 80       	mov    0x8010c65c,%eax
80102e44:	83 e0 08             	and    $0x8,%eax
80102e47:	85 c0                	test   %eax,%eax
80102e49:	74 22                	je     80102e6d <kbdgetc+0x14e>
    if('a' <= c && c <= 'z')
80102e4b:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80102e4f:	76 0c                	jbe    80102e5d <kbdgetc+0x13e>
80102e51:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80102e55:	77 06                	ja     80102e5d <kbdgetc+0x13e>
      c += 'A' - 'a';
80102e57:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80102e5b:	eb 10                	jmp    80102e6d <kbdgetc+0x14e>
    else if('A' <= c && c <= 'Z')
80102e5d:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80102e61:	76 0a                	jbe    80102e6d <kbdgetc+0x14e>
80102e63:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80102e67:	77 04                	ja     80102e6d <kbdgetc+0x14e>
      c += 'a' - 'A';
80102e69:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80102e6d:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102e70:	c9                   	leave  
80102e71:	c3                   	ret    

80102e72 <kbdintr>:

void
kbdintr(void)
{
80102e72:	55                   	push   %ebp
80102e73:	89 e5                	mov    %esp,%ebp
80102e75:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80102e78:	c7 04 24 1f 2d 10 80 	movl   $0x80102d1f,(%esp)
80102e7f:	e8 29 d9 ff ff       	call   801007ad <consoleintr>
}
80102e84:	c9                   	leave  
80102e85:	c3                   	ret    

80102e86 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102e86:	55                   	push   %ebp
80102e87:	89 e5                	mov    %esp,%ebp
80102e89:	83 ec 14             	sub    $0x14,%esp
80102e8c:	8b 45 08             	mov    0x8(%ebp),%eax
80102e8f:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102e93:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102e97:	89 c2                	mov    %eax,%edx
80102e99:	ec                   	in     (%dx),%al
80102e9a:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102e9d:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102ea1:	c9                   	leave  
80102ea2:	c3                   	ret    

80102ea3 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80102ea3:	55                   	push   %ebp
80102ea4:	89 e5                	mov    %esp,%ebp
80102ea6:	83 ec 08             	sub    $0x8,%esp
80102ea9:	8b 55 08             	mov    0x8(%ebp),%edx
80102eac:	8b 45 0c             	mov    0xc(%ebp),%eax
80102eaf:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102eb3:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102eb6:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102eba:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102ebe:	ee                   	out    %al,(%dx)
}
80102ebf:	c9                   	leave  
80102ec0:	c3                   	ret    

80102ec1 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80102ec1:	55                   	push   %ebp
80102ec2:	89 e5                	mov    %esp,%ebp
80102ec4:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80102ec7:	9c                   	pushf  
80102ec8:	58                   	pop    %eax
80102ec9:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80102ecc:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80102ecf:	c9                   	leave  
80102ed0:	c3                   	ret    

80102ed1 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102ed1:	55                   	push   %ebp
80102ed2:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102ed4:	a1 bc 32 11 80       	mov    0x801132bc,%eax
80102ed9:	8b 55 08             	mov    0x8(%ebp),%edx
80102edc:	c1 e2 02             	shl    $0x2,%edx
80102edf:	01 c2                	add    %eax,%edx
80102ee1:	8b 45 0c             	mov    0xc(%ebp),%eax
80102ee4:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80102ee6:	a1 bc 32 11 80       	mov    0x801132bc,%eax
80102eeb:	83 c0 20             	add    $0x20,%eax
80102eee:	8b 00                	mov    (%eax),%eax
}
80102ef0:	5d                   	pop    %ebp
80102ef1:	c3                   	ret    

80102ef2 <lapicinit>:
//PAGEBREAK!

void
lapicinit(void)
{
80102ef2:	55                   	push   %ebp
80102ef3:	89 e5                	mov    %esp,%ebp
80102ef5:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80102ef8:	a1 bc 32 11 80       	mov    0x801132bc,%eax
80102efd:	85 c0                	test   %eax,%eax
80102eff:	75 05                	jne    80102f06 <lapicinit+0x14>
    return;
80102f01:	e9 43 01 00 00       	jmp    80103049 <lapicinit+0x157>

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102f06:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80102f0d:	00 
80102f0e:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
80102f15:	e8 b7 ff ff ff       	call   80102ed1 <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80102f1a:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80102f21:	00 
80102f22:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80102f29:	e8 a3 ff ff ff       	call   80102ed1 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102f2e:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80102f35:	00 
80102f36:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102f3d:	e8 8f ff ff ff       	call   80102ed1 <lapicw>
  lapicw(TICR, 10000000); 
80102f42:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80102f49:	00 
80102f4a:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80102f51:	e8 7b ff ff ff       	call   80102ed1 <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80102f56:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102f5d:	00 
80102f5e:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80102f65:	e8 67 ff ff ff       	call   80102ed1 <lapicw>
  lapicw(LINT1, MASKED);
80102f6a:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102f71:	00 
80102f72:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
80102f79:	e8 53 ff ff ff       	call   80102ed1 <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102f7e:	a1 bc 32 11 80       	mov    0x801132bc,%eax
80102f83:	83 c0 30             	add    $0x30,%eax
80102f86:	8b 00                	mov    (%eax),%eax
80102f88:	c1 e8 10             	shr    $0x10,%eax
80102f8b:	0f b6 c0             	movzbl %al,%eax
80102f8e:	83 f8 03             	cmp    $0x3,%eax
80102f91:	76 14                	jbe    80102fa7 <lapicinit+0xb5>
    lapicw(PCINT, MASKED);
80102f93:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102f9a:	00 
80102f9b:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80102fa2:	e8 2a ff ff ff       	call   80102ed1 <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80102fa7:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80102fae:	00 
80102faf:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80102fb6:	e8 16 ff ff ff       	call   80102ed1 <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80102fbb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102fc2:	00 
80102fc3:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102fca:	e8 02 ff ff ff       	call   80102ed1 <lapicw>
  lapicw(ESR, 0);
80102fcf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102fd6:	00 
80102fd7:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102fde:	e8 ee fe ff ff       	call   80102ed1 <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
80102fe3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102fea:	00 
80102feb:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80102ff2:	e8 da fe ff ff       	call   80102ed1 <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
80102ff7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102ffe:	00 
80102fff:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103006:	e8 c6 fe ff ff       	call   80102ed1 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
8010300b:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
80103012:	00 
80103013:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
8010301a:	e8 b2 fe ff ff       	call   80102ed1 <lapicw>
  while(lapic[ICRLO] & DELIVS)
8010301f:	90                   	nop
80103020:	a1 bc 32 11 80       	mov    0x801132bc,%eax
80103025:	05 00 03 00 00       	add    $0x300,%eax
8010302a:	8b 00                	mov    (%eax),%eax
8010302c:	25 00 10 00 00       	and    $0x1000,%eax
80103031:	85 c0                	test   %eax,%eax
80103033:	75 eb                	jne    80103020 <lapicinit+0x12e>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80103035:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010303c:	00 
8010303d:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103044:	e8 88 fe ff ff       	call   80102ed1 <lapicw>
}
80103049:	c9                   	leave  
8010304a:	c3                   	ret    

8010304b <cpunum>:

int
cpunum(void)
{
8010304b:	55                   	push   %ebp
8010304c:	89 e5                	mov    %esp,%ebp
8010304e:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
80103051:	e8 6b fe ff ff       	call   80102ec1 <readeflags>
80103056:	25 00 02 00 00       	and    $0x200,%eax
8010305b:	85 c0                	test   %eax,%eax
8010305d:	74 25                	je     80103084 <cpunum+0x39>
    static int n;
    if(n++ == 0)
8010305f:	a1 60 c6 10 80       	mov    0x8010c660,%eax
80103064:	8d 50 01             	lea    0x1(%eax),%edx
80103067:	89 15 60 c6 10 80    	mov    %edx,0x8010c660
8010306d:	85 c0                	test   %eax,%eax
8010306f:	75 13                	jne    80103084 <cpunum+0x39>
      cprintf("cpu called from %x with interrupts enabled\n",
80103071:	8b 45 04             	mov    0x4(%ebp),%eax
80103074:	89 44 24 04          	mov    %eax,0x4(%esp)
80103078:	c7 04 24 f8 93 10 80 	movl   $0x801093f8,(%esp)
8010307f:	e8 1c d3 ff ff       	call   801003a0 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80103084:	a1 bc 32 11 80       	mov    0x801132bc,%eax
80103089:	85 c0                	test   %eax,%eax
8010308b:	74 0f                	je     8010309c <cpunum+0x51>
    return lapic[ID]>>24;
8010308d:	a1 bc 32 11 80       	mov    0x801132bc,%eax
80103092:	83 c0 20             	add    $0x20,%eax
80103095:	8b 00                	mov    (%eax),%eax
80103097:	c1 e8 18             	shr    $0x18,%eax
8010309a:	eb 05                	jmp    801030a1 <cpunum+0x56>
  return 0;
8010309c:	b8 00 00 00 00       	mov    $0x0,%eax
}
801030a1:	c9                   	leave  
801030a2:	c3                   	ret    

801030a3 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
801030a3:	55                   	push   %ebp
801030a4:	89 e5                	mov    %esp,%ebp
801030a6:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
801030a9:	a1 bc 32 11 80       	mov    0x801132bc,%eax
801030ae:	85 c0                	test   %eax,%eax
801030b0:	74 14                	je     801030c6 <lapiceoi+0x23>
    lapicw(EOI, 0);
801030b2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801030b9:	00 
801030ba:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
801030c1:	e8 0b fe ff ff       	call   80102ed1 <lapicw>
}
801030c6:	c9                   	leave  
801030c7:	c3                   	ret    

801030c8 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
801030c8:	55                   	push   %ebp
801030c9:	89 e5                	mov    %esp,%ebp
}
801030cb:	5d                   	pop    %ebp
801030cc:	c3                   	ret    

801030cd <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
801030cd:	55                   	push   %ebp
801030ce:	89 e5                	mov    %esp,%ebp
801030d0:	83 ec 1c             	sub    $0x1c,%esp
801030d3:	8b 45 08             	mov    0x8(%ebp),%eax
801030d6:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(CMOS_PORT, 0xF);  // offset 0xF is shutdown code
801030d9:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
801030e0:	00 
801030e1:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
801030e8:	e8 b6 fd ff ff       	call   80102ea3 <outb>
  outb(CMOS_PORT+1, 0x0A);
801030ed:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
801030f4:	00 
801030f5:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
801030fc:	e8 a2 fd ff ff       	call   80102ea3 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
80103101:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
80103108:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010310b:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
80103110:	8b 45 f8             	mov    -0x8(%ebp),%eax
80103113:	8d 50 02             	lea    0x2(%eax),%edx
80103116:	8b 45 0c             	mov    0xc(%ebp),%eax
80103119:	c1 e8 04             	shr    $0x4,%eax
8010311c:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
8010311f:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103123:	c1 e0 18             	shl    $0x18,%eax
80103126:	89 44 24 04          	mov    %eax,0x4(%esp)
8010312a:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103131:	e8 9b fd ff ff       	call   80102ed1 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80103136:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
8010313d:	00 
8010313e:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103145:	e8 87 fd ff ff       	call   80102ed1 <lapicw>
  microdelay(200);
8010314a:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103151:	e8 72 ff ff ff       	call   801030c8 <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
80103156:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
8010315d:	00 
8010315e:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103165:	e8 67 fd ff ff       	call   80102ed1 <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
8010316a:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80103171:	e8 52 ff ff ff       	call   801030c8 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103176:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010317d:	eb 40                	jmp    801031bf <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
8010317f:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103183:	c1 e0 18             	shl    $0x18,%eax
80103186:	89 44 24 04          	mov    %eax,0x4(%esp)
8010318a:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80103191:	e8 3b fd ff ff       	call   80102ed1 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80103196:	8b 45 0c             	mov    0xc(%ebp),%eax
80103199:	c1 e8 0c             	shr    $0xc,%eax
8010319c:	80 cc 06             	or     $0x6,%ah
8010319f:	89 44 24 04          	mov    %eax,0x4(%esp)
801031a3:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801031aa:	e8 22 fd ff ff       	call   80102ed1 <lapicw>
    microdelay(200);
801031af:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801031b6:	e8 0d ff ff ff       	call   801030c8 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
801031bb:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801031bf:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
801031c3:	7e ba                	jle    8010317f <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
801031c5:	c9                   	leave  
801031c6:	c3                   	ret    

801031c7 <cmos_read>:
#define DAY     0x07
#define MONTH   0x08
#define YEAR    0x09

static uint cmos_read(uint reg)
{
801031c7:	55                   	push   %ebp
801031c8:	89 e5                	mov    %esp,%ebp
801031ca:	83 ec 08             	sub    $0x8,%esp
  outb(CMOS_PORT,  reg);
801031cd:	8b 45 08             	mov    0x8(%ebp),%eax
801031d0:	0f b6 c0             	movzbl %al,%eax
801031d3:	89 44 24 04          	mov    %eax,0x4(%esp)
801031d7:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
801031de:	e8 c0 fc ff ff       	call   80102ea3 <outb>
  microdelay(200);
801031e3:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801031ea:	e8 d9 fe ff ff       	call   801030c8 <microdelay>

  return inb(CMOS_RETURN);
801031ef:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
801031f6:	e8 8b fc ff ff       	call   80102e86 <inb>
801031fb:	0f b6 c0             	movzbl %al,%eax
}
801031fe:	c9                   	leave  
801031ff:	c3                   	ret    

80103200 <fill_rtcdate>:

static void fill_rtcdate(struct rtcdate *r)
{
80103200:	55                   	push   %ebp
80103201:	89 e5                	mov    %esp,%ebp
80103203:	83 ec 04             	sub    $0x4,%esp
  r->second = cmos_read(SECS);
80103206:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010320d:	e8 b5 ff ff ff       	call   801031c7 <cmos_read>
80103212:	8b 55 08             	mov    0x8(%ebp),%edx
80103215:	89 02                	mov    %eax,(%edx)
  r->minute = cmos_read(MINS);
80103217:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010321e:	e8 a4 ff ff ff       	call   801031c7 <cmos_read>
80103223:	8b 55 08             	mov    0x8(%ebp),%edx
80103226:	89 42 04             	mov    %eax,0x4(%edx)
  r->hour   = cmos_read(HOURS);
80103229:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80103230:	e8 92 ff ff ff       	call   801031c7 <cmos_read>
80103235:	8b 55 08             	mov    0x8(%ebp),%edx
80103238:	89 42 08             	mov    %eax,0x8(%edx)
  r->day    = cmos_read(DAY);
8010323b:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
80103242:	e8 80 ff ff ff       	call   801031c7 <cmos_read>
80103247:	8b 55 08             	mov    0x8(%ebp),%edx
8010324a:	89 42 0c             	mov    %eax,0xc(%edx)
  r->month  = cmos_read(MONTH);
8010324d:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80103254:	e8 6e ff ff ff       	call   801031c7 <cmos_read>
80103259:	8b 55 08             	mov    0x8(%ebp),%edx
8010325c:	89 42 10             	mov    %eax,0x10(%edx)
  r->year   = cmos_read(YEAR);
8010325f:	c7 04 24 09 00 00 00 	movl   $0x9,(%esp)
80103266:	e8 5c ff ff ff       	call   801031c7 <cmos_read>
8010326b:	8b 55 08             	mov    0x8(%ebp),%edx
8010326e:	89 42 14             	mov    %eax,0x14(%edx)
}
80103271:	c9                   	leave  
80103272:	c3                   	ret    

80103273 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void cmostime(struct rtcdate *r)
{
80103273:	55                   	push   %ebp
80103274:	89 e5                	mov    %esp,%ebp
80103276:	83 ec 58             	sub    $0x58,%esp
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
80103279:	c7 04 24 0b 00 00 00 	movl   $0xb,(%esp)
80103280:	e8 42 ff ff ff       	call   801031c7 <cmos_read>
80103285:	89 45 f4             	mov    %eax,-0xc(%ebp)

  bcd = (sb & (1 << 2)) == 0;
80103288:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010328b:	83 e0 04             	and    $0x4,%eax
8010328e:	85 c0                	test   %eax,%eax
80103290:	0f 94 c0             	sete   %al
80103293:	0f b6 c0             	movzbl %al,%eax
80103296:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // make sure CMOS doesn't modify time while we read it
  for (;;) {
    fill_rtcdate(&t1);
80103299:	8d 45 d8             	lea    -0x28(%ebp),%eax
8010329c:	89 04 24             	mov    %eax,(%esp)
8010329f:	e8 5c ff ff ff       	call   80103200 <fill_rtcdate>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
801032a4:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
801032ab:	e8 17 ff ff ff       	call   801031c7 <cmos_read>
801032b0:	25 80 00 00 00       	and    $0x80,%eax
801032b5:	85 c0                	test   %eax,%eax
801032b7:	74 02                	je     801032bb <cmostime+0x48>
        continue;
801032b9:	eb 36                	jmp    801032f1 <cmostime+0x7e>
    fill_rtcdate(&t2);
801032bb:	8d 45 c0             	lea    -0x40(%ebp),%eax
801032be:	89 04 24             	mov    %eax,(%esp)
801032c1:	e8 3a ff ff ff       	call   80103200 <fill_rtcdate>
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
801032c6:	c7 44 24 08 18 00 00 	movl   $0x18,0x8(%esp)
801032cd:	00 
801032ce:	8d 45 c0             	lea    -0x40(%ebp),%eax
801032d1:	89 44 24 04          	mov    %eax,0x4(%esp)
801032d5:	8d 45 d8             	lea    -0x28(%ebp),%eax
801032d8:	89 04 24             	mov    %eax,(%esp)
801032db:	e8 c1 2a 00 00       	call   80105da1 <memcmp>
801032e0:	85 c0                	test   %eax,%eax
801032e2:	75 0d                	jne    801032f1 <cmostime+0x7e>
      break;
801032e4:	90                   	nop
  }

  // convert
  if (bcd) {
801032e5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801032e9:	0f 84 ac 00 00 00    	je     8010339b <cmostime+0x128>
801032ef:	eb 02                	jmp    801032f3 <cmostime+0x80>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
        continue;
    fill_rtcdate(&t2);
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
      break;
  }
801032f1:	eb a6                	jmp    80103299 <cmostime+0x26>

  // convert
  if (bcd) {
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
801032f3:	8b 45 d8             	mov    -0x28(%ebp),%eax
801032f6:	c1 e8 04             	shr    $0x4,%eax
801032f9:	89 c2                	mov    %eax,%edx
801032fb:	89 d0                	mov    %edx,%eax
801032fd:	c1 e0 02             	shl    $0x2,%eax
80103300:	01 d0                	add    %edx,%eax
80103302:	01 c0                	add    %eax,%eax
80103304:	8b 55 d8             	mov    -0x28(%ebp),%edx
80103307:	83 e2 0f             	and    $0xf,%edx
8010330a:	01 d0                	add    %edx,%eax
8010330c:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(minute);
8010330f:	8b 45 dc             	mov    -0x24(%ebp),%eax
80103312:	c1 e8 04             	shr    $0x4,%eax
80103315:	89 c2                	mov    %eax,%edx
80103317:	89 d0                	mov    %edx,%eax
80103319:	c1 e0 02             	shl    $0x2,%eax
8010331c:	01 d0                	add    %edx,%eax
8010331e:	01 c0                	add    %eax,%eax
80103320:	8b 55 dc             	mov    -0x24(%ebp),%edx
80103323:	83 e2 0f             	and    $0xf,%edx
80103326:	01 d0                	add    %edx,%eax
80103328:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(hour  );
8010332b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010332e:	c1 e8 04             	shr    $0x4,%eax
80103331:	89 c2                	mov    %eax,%edx
80103333:	89 d0                	mov    %edx,%eax
80103335:	c1 e0 02             	shl    $0x2,%eax
80103338:	01 d0                	add    %edx,%eax
8010333a:	01 c0                	add    %eax,%eax
8010333c:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010333f:	83 e2 0f             	and    $0xf,%edx
80103342:	01 d0                	add    %edx,%eax
80103344:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(day   );
80103347:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010334a:	c1 e8 04             	shr    $0x4,%eax
8010334d:	89 c2                	mov    %eax,%edx
8010334f:	89 d0                	mov    %edx,%eax
80103351:	c1 e0 02             	shl    $0x2,%eax
80103354:	01 d0                	add    %edx,%eax
80103356:	01 c0                	add    %eax,%eax
80103358:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010335b:	83 e2 0f             	and    $0xf,%edx
8010335e:	01 d0                	add    %edx,%eax
80103360:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    CONV(month );
80103363:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103366:	c1 e8 04             	shr    $0x4,%eax
80103369:	89 c2                	mov    %eax,%edx
8010336b:	89 d0                	mov    %edx,%eax
8010336d:	c1 e0 02             	shl    $0x2,%eax
80103370:	01 d0                	add    %edx,%eax
80103372:	01 c0                	add    %eax,%eax
80103374:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103377:	83 e2 0f             	and    $0xf,%edx
8010337a:	01 d0                	add    %edx,%eax
8010337c:	89 45 e8             	mov    %eax,-0x18(%ebp)
    CONV(year  );
8010337f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103382:	c1 e8 04             	shr    $0x4,%eax
80103385:	89 c2                	mov    %eax,%edx
80103387:	89 d0                	mov    %edx,%eax
80103389:	c1 e0 02             	shl    $0x2,%eax
8010338c:	01 d0                	add    %edx,%eax
8010338e:	01 c0                	add    %eax,%eax
80103390:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103393:	83 e2 0f             	and    $0xf,%edx
80103396:	01 d0                	add    %edx,%eax
80103398:	89 45 ec             	mov    %eax,-0x14(%ebp)
#undef     CONV
  }

  *r = t1;
8010339b:	8b 45 08             	mov    0x8(%ebp),%eax
8010339e:	8b 55 d8             	mov    -0x28(%ebp),%edx
801033a1:	89 10                	mov    %edx,(%eax)
801033a3:	8b 55 dc             	mov    -0x24(%ebp),%edx
801033a6:	89 50 04             	mov    %edx,0x4(%eax)
801033a9:	8b 55 e0             	mov    -0x20(%ebp),%edx
801033ac:	89 50 08             	mov    %edx,0x8(%eax)
801033af:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801033b2:	89 50 0c             	mov    %edx,0xc(%eax)
801033b5:	8b 55 e8             	mov    -0x18(%ebp),%edx
801033b8:	89 50 10             	mov    %edx,0x10(%eax)
801033bb:	8b 55 ec             	mov    -0x14(%ebp),%edx
801033be:	89 50 14             	mov    %edx,0x14(%eax)
  r->year += 2000;
801033c1:	8b 45 08             	mov    0x8(%ebp),%eax
801033c4:	8b 40 14             	mov    0x14(%eax),%eax
801033c7:	8d 90 d0 07 00 00    	lea    0x7d0(%eax),%edx
801033cd:	8b 45 08             	mov    0x8(%ebp),%eax
801033d0:	89 50 14             	mov    %edx,0x14(%eax)
}
801033d3:	c9                   	leave  
801033d4:	c3                   	ret    

801033d5 <initlog>:
static void recover_from_log(void);
static void commit();

void
initlog(void)
{
801033d5:	55                   	push   %ebp
801033d6:	89 e5                	mov    %esp,%ebp
801033d8:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
801033db:	c7 44 24 04 24 94 10 	movl   $0x80109424,0x4(%esp)
801033e2:	80 
801033e3:	c7 04 24 c0 32 11 80 	movl   $0x801132c0,(%esp)
801033ea:	e8 c6 26 00 00       	call   80105ab5 <initlock>
  readsb(ROOTDEV, &sb);
801033ef:	8d 45 e8             	lea    -0x18(%ebp),%eax
801033f2:	89 44 24 04          	mov    %eax,0x4(%esp)
801033f6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801033fd:	e8 a7 df ff ff       	call   801013a9 <readsb>
  log.start = sb.size - sb.nlog;
80103402:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103405:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103408:	29 c2                	sub    %eax,%edx
8010340a:	89 d0                	mov    %edx,%eax
8010340c:	a3 f4 32 11 80       	mov    %eax,0x801132f4
  log.size = sb.nlog;
80103411:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103414:	a3 f8 32 11 80       	mov    %eax,0x801132f8
  log.dev = ROOTDEV;
80103419:	c7 05 04 33 11 80 01 	movl   $0x1,0x80113304
80103420:	00 00 00 
  recover_from_log();
80103423:	e8 9a 01 00 00       	call   801035c2 <recover_from_log>
}
80103428:	c9                   	leave  
80103429:	c3                   	ret    

8010342a <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
8010342a:	55                   	push   %ebp
8010342b:	89 e5                	mov    %esp,%ebp
8010342d:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103430:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103437:	e9 8c 00 00 00       	jmp    801034c8 <install_trans+0x9e>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
8010343c:	8b 15 f4 32 11 80    	mov    0x801132f4,%edx
80103442:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103445:	01 d0                	add    %edx,%eax
80103447:	83 c0 01             	add    $0x1,%eax
8010344a:	89 c2                	mov    %eax,%edx
8010344c:	a1 04 33 11 80       	mov    0x80113304,%eax
80103451:	89 54 24 04          	mov    %edx,0x4(%esp)
80103455:	89 04 24             	mov    %eax,(%esp)
80103458:	e8 49 cd ff ff       	call   801001a6 <bread>
8010345d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
80103460:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103463:	83 c0 10             	add    $0x10,%eax
80103466:	8b 04 85 cc 32 11 80 	mov    -0x7feecd34(,%eax,4),%eax
8010346d:	89 c2                	mov    %eax,%edx
8010346f:	a1 04 33 11 80       	mov    0x80113304,%eax
80103474:	89 54 24 04          	mov    %edx,0x4(%esp)
80103478:	89 04 24             	mov    %eax,(%esp)
8010347b:	e8 26 cd ff ff       	call   801001a6 <bread>
80103480:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80103483:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103486:	8d 50 18             	lea    0x18(%eax),%edx
80103489:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010348c:	83 c0 18             	add    $0x18,%eax
8010348f:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103496:	00 
80103497:	89 54 24 04          	mov    %edx,0x4(%esp)
8010349b:	89 04 24             	mov    %eax,(%esp)
8010349e:	e8 56 29 00 00       	call   80105df9 <memmove>
    bwrite(dbuf);  // write dst to disk
801034a3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801034a6:	89 04 24             	mov    %eax,(%esp)
801034a9:	e8 2f cd ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
801034ae:	8b 45 f0             	mov    -0x10(%ebp),%eax
801034b1:	89 04 24             	mov    %eax,(%esp)
801034b4:	e8 5e cd ff ff       	call   80100217 <brelse>
    brelse(dbuf);
801034b9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801034bc:	89 04 24             	mov    %eax,(%esp)
801034bf:	e8 53 cd ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801034c4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801034c8:	a1 08 33 11 80       	mov    0x80113308,%eax
801034cd:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801034d0:	0f 8f 66 ff ff ff    	jg     8010343c <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
801034d6:	c9                   	leave  
801034d7:	c3                   	ret    

801034d8 <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
801034d8:	55                   	push   %ebp
801034d9:	89 e5                	mov    %esp,%ebp
801034db:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
801034de:	a1 f4 32 11 80       	mov    0x801132f4,%eax
801034e3:	89 c2                	mov    %eax,%edx
801034e5:	a1 04 33 11 80       	mov    0x80113304,%eax
801034ea:	89 54 24 04          	mov    %edx,0x4(%esp)
801034ee:	89 04 24             	mov    %eax,(%esp)
801034f1:	e8 b0 cc ff ff       	call   801001a6 <bread>
801034f6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
801034f9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801034fc:	83 c0 18             	add    $0x18,%eax
801034ff:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
80103502:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103505:	8b 00                	mov    (%eax),%eax
80103507:	a3 08 33 11 80       	mov    %eax,0x80113308
  for (i = 0; i < log.lh.n; i++) {
8010350c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103513:	eb 1b                	jmp    80103530 <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
80103515:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103518:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010351b:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
8010351f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103522:	83 c2 10             	add    $0x10,%edx
80103525:	89 04 95 cc 32 11 80 	mov    %eax,-0x7feecd34(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
8010352c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103530:	a1 08 33 11 80       	mov    0x80113308,%eax
80103535:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103538:	7f db                	jg     80103515 <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
8010353a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010353d:	89 04 24             	mov    %eax,(%esp)
80103540:	e8 d2 cc ff ff       	call   80100217 <brelse>
}
80103545:	c9                   	leave  
80103546:	c3                   	ret    

80103547 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80103547:	55                   	push   %ebp
80103548:	89 e5                	mov    %esp,%ebp
8010354a:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
8010354d:	a1 f4 32 11 80       	mov    0x801132f4,%eax
80103552:	89 c2                	mov    %eax,%edx
80103554:	a1 04 33 11 80       	mov    0x80113304,%eax
80103559:	89 54 24 04          	mov    %edx,0x4(%esp)
8010355d:	89 04 24             	mov    %eax,(%esp)
80103560:	e8 41 cc ff ff       	call   801001a6 <bread>
80103565:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
80103568:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010356b:	83 c0 18             	add    $0x18,%eax
8010356e:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
80103571:	8b 15 08 33 11 80    	mov    0x80113308,%edx
80103577:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010357a:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
8010357c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103583:	eb 1b                	jmp    801035a0 <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
80103585:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103588:	83 c0 10             	add    $0x10,%eax
8010358b:	8b 0c 85 cc 32 11 80 	mov    -0x7feecd34(,%eax,4),%ecx
80103592:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103595:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103598:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
8010359c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801035a0:	a1 08 33 11 80       	mov    0x80113308,%eax
801035a5:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801035a8:	7f db                	jg     80103585 <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
801035aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035ad:	89 04 24             	mov    %eax,(%esp)
801035b0:	e8 28 cc ff ff       	call   801001dd <bwrite>
  brelse(buf);
801035b5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035b8:	89 04 24             	mov    %eax,(%esp)
801035bb:	e8 57 cc ff ff       	call   80100217 <brelse>
}
801035c0:	c9                   	leave  
801035c1:	c3                   	ret    

801035c2 <recover_from_log>:

static void
recover_from_log(void)
{
801035c2:	55                   	push   %ebp
801035c3:	89 e5                	mov    %esp,%ebp
801035c5:	83 ec 08             	sub    $0x8,%esp
  read_head();      
801035c8:	e8 0b ff ff ff       	call   801034d8 <read_head>
  install_trans(); // if committed, copy from log to disk
801035cd:	e8 58 fe ff ff       	call   8010342a <install_trans>
  log.lh.n = 0;
801035d2:	c7 05 08 33 11 80 00 	movl   $0x0,0x80113308
801035d9:	00 00 00 
  write_head(); // clear the log
801035dc:	e8 66 ff ff ff       	call   80103547 <write_head>
}
801035e1:	c9                   	leave  
801035e2:	c3                   	ret    

801035e3 <begin_op>:

// called at the start of each FS system call.
void
begin_op(void)
{
801035e3:	55                   	push   %ebp
801035e4:	89 e5                	mov    %esp,%ebp
801035e6:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
801035e9:	c7 04 24 c0 32 11 80 	movl   $0x801132c0,(%esp)
801035f0:	e8 e1 24 00 00       	call   80105ad6 <acquire>
  while(1){
    if(log.committing){
801035f5:	a1 00 33 11 80       	mov    0x80113300,%eax
801035fa:	85 c0                	test   %eax,%eax
801035fc:	74 16                	je     80103614 <begin_op+0x31>
      sleep(&log, &log.lock);
801035fe:	c7 44 24 04 c0 32 11 	movl   $0x801132c0,0x4(%esp)
80103605:	80 
80103606:	c7 04 24 c0 32 11 80 	movl   $0x801132c0,(%esp)
8010360d:	e8 f2 16 00 00       	call   80104d04 <sleep>
80103612:	eb 4f                	jmp    80103663 <begin_op+0x80>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80103614:	8b 0d 08 33 11 80    	mov    0x80113308,%ecx
8010361a:	a1 fc 32 11 80       	mov    0x801132fc,%eax
8010361f:	8d 50 01             	lea    0x1(%eax),%edx
80103622:	89 d0                	mov    %edx,%eax
80103624:	c1 e0 02             	shl    $0x2,%eax
80103627:	01 d0                	add    %edx,%eax
80103629:	01 c0                	add    %eax,%eax
8010362b:	01 c8                	add    %ecx,%eax
8010362d:	83 f8 1e             	cmp    $0x1e,%eax
80103630:	7e 16                	jle    80103648 <begin_op+0x65>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
80103632:	c7 44 24 04 c0 32 11 	movl   $0x801132c0,0x4(%esp)
80103639:	80 
8010363a:	c7 04 24 c0 32 11 80 	movl   $0x801132c0,(%esp)
80103641:	e8 be 16 00 00       	call   80104d04 <sleep>
80103646:	eb 1b                	jmp    80103663 <begin_op+0x80>
    } else {
      log.outstanding += 1;
80103648:	a1 fc 32 11 80       	mov    0x801132fc,%eax
8010364d:	83 c0 01             	add    $0x1,%eax
80103650:	a3 fc 32 11 80       	mov    %eax,0x801132fc
      release(&log.lock);
80103655:	c7 04 24 c0 32 11 80 	movl   $0x801132c0,(%esp)
8010365c:	e8 d7 24 00 00       	call   80105b38 <release>
      break;
80103661:	eb 02                	jmp    80103665 <begin_op+0x82>
    }
  }
80103663:	eb 90                	jmp    801035f5 <begin_op+0x12>
}
80103665:	c9                   	leave  
80103666:	c3                   	ret    

80103667 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
80103667:	55                   	push   %ebp
80103668:	89 e5                	mov    %esp,%ebp
8010366a:	83 ec 28             	sub    $0x28,%esp
  int do_commit = 0;
8010366d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&log.lock);
80103674:	c7 04 24 c0 32 11 80 	movl   $0x801132c0,(%esp)
8010367b:	e8 56 24 00 00       	call   80105ad6 <acquire>
  log.outstanding -= 1;
80103680:	a1 fc 32 11 80       	mov    0x801132fc,%eax
80103685:	83 e8 01             	sub    $0x1,%eax
80103688:	a3 fc 32 11 80       	mov    %eax,0x801132fc
  if(log.committing)
8010368d:	a1 00 33 11 80       	mov    0x80113300,%eax
80103692:	85 c0                	test   %eax,%eax
80103694:	74 0c                	je     801036a2 <end_op+0x3b>
    panic("log.committing");
80103696:	c7 04 24 28 94 10 80 	movl   $0x80109428,(%esp)
8010369d:	e8 98 ce ff ff       	call   8010053a <panic>
  if(log.outstanding == 0){
801036a2:	a1 fc 32 11 80       	mov    0x801132fc,%eax
801036a7:	85 c0                	test   %eax,%eax
801036a9:	75 13                	jne    801036be <end_op+0x57>
    do_commit = 1;
801036ab:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
    log.committing = 1;
801036b2:	c7 05 00 33 11 80 01 	movl   $0x1,0x80113300
801036b9:	00 00 00 
801036bc:	eb 0c                	jmp    801036ca <end_op+0x63>
  } else {
    // begin_op() may be waiting for log space.
    wakeup(&log);
801036be:	c7 04 24 c0 32 11 80 	movl   $0x801132c0,(%esp)
801036c5:	e8 16 17 00 00       	call   80104de0 <wakeup>
  }
  release(&log.lock);
801036ca:	c7 04 24 c0 32 11 80 	movl   $0x801132c0,(%esp)
801036d1:	e8 62 24 00 00       	call   80105b38 <release>

  if(do_commit){
801036d6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801036da:	74 33                	je     8010370f <end_op+0xa8>
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.
    commit();
801036dc:	e8 de 00 00 00       	call   801037bf <commit>
    acquire(&log.lock);
801036e1:	c7 04 24 c0 32 11 80 	movl   $0x801132c0,(%esp)
801036e8:	e8 e9 23 00 00       	call   80105ad6 <acquire>
    log.committing = 0;
801036ed:	c7 05 00 33 11 80 00 	movl   $0x0,0x80113300
801036f4:	00 00 00 
    wakeup(&log);
801036f7:	c7 04 24 c0 32 11 80 	movl   $0x801132c0,(%esp)
801036fe:	e8 dd 16 00 00       	call   80104de0 <wakeup>
    release(&log.lock);
80103703:	c7 04 24 c0 32 11 80 	movl   $0x801132c0,(%esp)
8010370a:	e8 29 24 00 00       	call   80105b38 <release>
  }
}
8010370f:	c9                   	leave  
80103710:	c3                   	ret    

80103711 <write_log>:

// Copy modified blocks from cache to log.
static void 
write_log(void)
{
80103711:	55                   	push   %ebp
80103712:	89 e5                	mov    %esp,%ebp
80103714:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103717:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010371e:	e9 8c 00 00 00       	jmp    801037af <write_log+0x9e>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
80103723:	8b 15 f4 32 11 80    	mov    0x801132f4,%edx
80103729:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010372c:	01 d0                	add    %edx,%eax
8010372e:	83 c0 01             	add    $0x1,%eax
80103731:	89 c2                	mov    %eax,%edx
80103733:	a1 04 33 11 80       	mov    0x80113304,%eax
80103738:	89 54 24 04          	mov    %edx,0x4(%esp)
8010373c:	89 04 24             	mov    %eax,(%esp)
8010373f:	e8 62 ca ff ff       	call   801001a6 <bread>
80103744:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *from = bread(log.dev, log.lh.sector[tail]); // cache block
80103747:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010374a:	83 c0 10             	add    $0x10,%eax
8010374d:	8b 04 85 cc 32 11 80 	mov    -0x7feecd34(,%eax,4),%eax
80103754:	89 c2                	mov    %eax,%edx
80103756:	a1 04 33 11 80       	mov    0x80113304,%eax
8010375b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010375f:	89 04 24             	mov    %eax,(%esp)
80103762:	e8 3f ca ff ff       	call   801001a6 <bread>
80103767:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(to->data, from->data, BSIZE);
8010376a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010376d:	8d 50 18             	lea    0x18(%eax),%edx
80103770:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103773:	83 c0 18             	add    $0x18,%eax
80103776:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
8010377d:	00 
8010377e:	89 54 24 04          	mov    %edx,0x4(%esp)
80103782:	89 04 24             	mov    %eax,(%esp)
80103785:	e8 6f 26 00 00       	call   80105df9 <memmove>
    bwrite(to);  // write the log
8010378a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010378d:	89 04 24             	mov    %eax,(%esp)
80103790:	e8 48 ca ff ff       	call   801001dd <bwrite>
    brelse(from); 
80103795:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103798:	89 04 24             	mov    %eax,(%esp)
8010379b:	e8 77 ca ff ff       	call   80100217 <brelse>
    brelse(to);
801037a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801037a3:	89 04 24             	mov    %eax,(%esp)
801037a6:	e8 6c ca ff ff       	call   80100217 <brelse>
static void 
write_log(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801037ab:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801037af:	a1 08 33 11 80       	mov    0x80113308,%eax
801037b4:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801037b7:	0f 8f 66 ff ff ff    	jg     80103723 <write_log+0x12>
    memmove(to->data, from->data, BSIZE);
    bwrite(to);  // write the log
    brelse(from); 
    brelse(to);
  }
}
801037bd:	c9                   	leave  
801037be:	c3                   	ret    

801037bf <commit>:

static void
commit()
{
801037bf:	55                   	push   %ebp
801037c0:	89 e5                	mov    %esp,%ebp
801037c2:	83 ec 08             	sub    $0x8,%esp
  if (log.lh.n > 0) {
801037c5:	a1 08 33 11 80       	mov    0x80113308,%eax
801037ca:	85 c0                	test   %eax,%eax
801037cc:	7e 1e                	jle    801037ec <commit+0x2d>
    write_log();     // Write modified blocks from cache to log
801037ce:	e8 3e ff ff ff       	call   80103711 <write_log>
    write_head();    // Write header to disk -- the real commit
801037d3:	e8 6f fd ff ff       	call   80103547 <write_head>
    install_trans(); // Now install writes to home locations
801037d8:	e8 4d fc ff ff       	call   8010342a <install_trans>
    log.lh.n = 0; 
801037dd:	c7 05 08 33 11 80 00 	movl   $0x0,0x80113308
801037e4:	00 00 00 
    write_head();    // Erase the transaction from the log
801037e7:	e8 5b fd ff ff       	call   80103547 <write_head>
  }
}
801037ec:	c9                   	leave  
801037ed:	c3                   	ret    

801037ee <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
801037ee:	55                   	push   %ebp
801037ef:	89 e5                	mov    %esp,%ebp
801037f1:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
801037f4:	a1 08 33 11 80       	mov    0x80113308,%eax
801037f9:	83 f8 1d             	cmp    $0x1d,%eax
801037fc:	7f 12                	jg     80103810 <log_write+0x22>
801037fe:	a1 08 33 11 80       	mov    0x80113308,%eax
80103803:	8b 15 f8 32 11 80    	mov    0x801132f8,%edx
80103809:	83 ea 01             	sub    $0x1,%edx
8010380c:	39 d0                	cmp    %edx,%eax
8010380e:	7c 0c                	jl     8010381c <log_write+0x2e>
    panic("too big a transaction");
80103810:	c7 04 24 37 94 10 80 	movl   $0x80109437,(%esp)
80103817:	e8 1e cd ff ff       	call   8010053a <panic>
  if (log.outstanding < 1)
8010381c:	a1 fc 32 11 80       	mov    0x801132fc,%eax
80103821:	85 c0                	test   %eax,%eax
80103823:	7f 0c                	jg     80103831 <log_write+0x43>
    panic("log_write outside of trans");
80103825:	c7 04 24 4d 94 10 80 	movl   $0x8010944d,(%esp)
8010382c:	e8 09 cd ff ff       	call   8010053a <panic>

  acquire(&log.lock);
80103831:	c7 04 24 c0 32 11 80 	movl   $0x801132c0,(%esp)
80103838:	e8 99 22 00 00       	call   80105ad6 <acquire>
  for (i = 0; i < log.lh.n; i++) {
8010383d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103844:	eb 1f                	jmp    80103865 <log_write+0x77>
    if (log.lh.sector[i] == b->sector)   // log absorbtion
80103846:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103849:	83 c0 10             	add    $0x10,%eax
8010384c:	8b 04 85 cc 32 11 80 	mov    -0x7feecd34(,%eax,4),%eax
80103853:	89 c2                	mov    %eax,%edx
80103855:	8b 45 08             	mov    0x8(%ebp),%eax
80103858:	8b 40 08             	mov    0x8(%eax),%eax
8010385b:	39 c2                	cmp    %eax,%edx
8010385d:	75 02                	jne    80103861 <log_write+0x73>
      break;
8010385f:	eb 0e                	jmp    8010386f <log_write+0x81>
    panic("too big a transaction");
  if (log.outstanding < 1)
    panic("log_write outside of trans");

  acquire(&log.lock);
  for (i = 0; i < log.lh.n; i++) {
80103861:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103865:	a1 08 33 11 80       	mov    0x80113308,%eax
8010386a:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010386d:	7f d7                	jg     80103846 <log_write+0x58>
    if (log.lh.sector[i] == b->sector)   // log absorbtion
      break;
  }
  log.lh.sector[i] = b->sector;
8010386f:	8b 45 08             	mov    0x8(%ebp),%eax
80103872:	8b 40 08             	mov    0x8(%eax),%eax
80103875:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103878:	83 c2 10             	add    $0x10,%edx
8010387b:	89 04 95 cc 32 11 80 	mov    %eax,-0x7feecd34(,%edx,4)
  if (i == log.lh.n)
80103882:	a1 08 33 11 80       	mov    0x80113308,%eax
80103887:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010388a:	75 0d                	jne    80103899 <log_write+0xab>
    log.lh.n++;
8010388c:	a1 08 33 11 80       	mov    0x80113308,%eax
80103891:	83 c0 01             	add    $0x1,%eax
80103894:	a3 08 33 11 80       	mov    %eax,0x80113308
  b->flags |= B_DIRTY; // prevent eviction
80103899:	8b 45 08             	mov    0x8(%ebp),%eax
8010389c:	8b 00                	mov    (%eax),%eax
8010389e:	83 c8 04             	or     $0x4,%eax
801038a1:	89 c2                	mov    %eax,%edx
801038a3:	8b 45 08             	mov    0x8(%ebp),%eax
801038a6:	89 10                	mov    %edx,(%eax)
  release(&log.lock);
801038a8:	c7 04 24 c0 32 11 80 	movl   $0x801132c0,(%esp)
801038af:	e8 84 22 00 00       	call   80105b38 <release>
}
801038b4:	c9                   	leave  
801038b5:	c3                   	ret    

801038b6 <v2p>:
801038b6:	55                   	push   %ebp
801038b7:	89 e5                	mov    %esp,%ebp
801038b9:	8b 45 08             	mov    0x8(%ebp),%eax
801038bc:	05 00 00 00 80       	add    $0x80000000,%eax
801038c1:	5d                   	pop    %ebp
801038c2:	c3                   	ret    

801038c3 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
801038c3:	55                   	push   %ebp
801038c4:	89 e5                	mov    %esp,%ebp
801038c6:	8b 45 08             	mov    0x8(%ebp),%eax
801038c9:	05 00 00 00 80       	add    $0x80000000,%eax
801038ce:	5d                   	pop    %ebp
801038cf:	c3                   	ret    

801038d0 <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
801038d0:	55                   	push   %ebp
801038d1:	89 e5                	mov    %esp,%ebp
801038d3:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
801038d6:	8b 55 08             	mov    0x8(%ebp),%edx
801038d9:	8b 45 0c             	mov    0xc(%ebp),%eax
801038dc:	8b 4d 08             	mov    0x8(%ebp),%ecx
801038df:	f0 87 02             	lock xchg %eax,(%edx)
801038e2:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
801038e5:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801038e8:	c9                   	leave  
801038e9:	c3                   	ret    

801038ea <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
801038ea:	55                   	push   %ebp
801038eb:	89 e5                	mov    %esp,%ebp
801038ed:	83 e4 f0             	and    $0xfffffff0,%esp
801038f0:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
801038f3:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
801038fa:	80 
801038fb:	c7 04 24 9c 7b 11 80 	movl   $0x80117b9c,(%esp)
80103902:	e8 80 f2 ff ff       	call   80102b87 <kinit1>
  kvmalloc();      // kernel page table
80103907:	e8 5a 51 00 00       	call   80108a66 <kvmalloc>
  mpinit();        // collect info about this machine
8010390c:	e8 4b 04 00 00       	call   80103d5c <mpinit>
  lapicinit();
80103911:	e8 dc f5 ff ff       	call   80102ef2 <lapicinit>
  seginit();       // set up segments
80103916:	e8 de 4a 00 00       	call   801083f9 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
8010391b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103921:	0f b6 00             	movzbl (%eax),%eax
80103924:	0f b6 c0             	movzbl %al,%eax
80103927:	89 44 24 04          	mov    %eax,0x4(%esp)
8010392b:	c7 04 24 68 94 10 80 	movl   $0x80109468,(%esp)
80103932:	e8 69 ca ff ff       	call   801003a0 <cprintf>
  picinit();       // interrupt controller
80103937:	e8 7e 06 00 00       	call   80103fba <picinit>
  ioapicinit();    // another interrupt controller
8010393c:	e8 3c f1 ff ff       	call   80102a7d <ioapicinit>
  procfsinit();
80103941:	e8 7c 18 00 00       	call   801051c2 <procfsinit>
  consoleinit();   // I/O devices & their interrupts
80103946:	e8 36 d1 ff ff       	call   80100a81 <consoleinit>
  uartinit();      // serial port
8010394b:	e8 f8 3d 00 00       	call   80107748 <uartinit>
  pinit();         // process table
80103950:	e8 6f 0b 00 00       	call   801044c4 <pinit>
  tvinit();        // trap vectors
80103955:	e8 a0 39 00 00       	call   801072fa <tvinit>
  binit();         // buffer cache
8010395a:	e8 d5 c6 ff ff       	call   80100034 <binit>
  fileinit();      // file table
8010395f:	e8 5e d6 ff ff       	call   80100fc2 <fileinit>
  iinit();         // inode cache
80103964:	e8 f3 dc ff ff       	call   8010165c <iinit>
  ideinit();       // disk
80103969:	e8 78 ed ff ff       	call   801026e6 <ideinit>
  if(!ismp)
8010396e:	a1 a4 33 11 80       	mov    0x801133a4,%eax
80103973:	85 c0                	test   %eax,%eax
80103975:	75 05                	jne    8010397c <main+0x92>
    timerinit();   // uniprocessor timer
80103977:	e8 c9 38 00 00       	call   80107245 <timerinit>
  startothers();   // start other processors
8010397c:	e8 7f 00 00 00       	call   80103a00 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80103981:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
80103988:	8e 
80103989:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80103990:	e8 2a f2 ff ff       	call   80102bbf <kinit2>
  userinit();      // first user process
80103995:	e8 48 0c 00 00       	call   801045e2 <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
8010399a:	e8 1a 00 00 00       	call   801039b9 <mpmain>

8010399f <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
8010399f:	55                   	push   %ebp
801039a0:	89 e5                	mov    %esp,%ebp
801039a2:	83 ec 08             	sub    $0x8,%esp
  switchkvm(); 
801039a5:	e8 d3 50 00 00       	call   80108a7d <switchkvm>
  seginit();
801039aa:	e8 4a 4a 00 00       	call   801083f9 <seginit>
  lapicinit();
801039af:	e8 3e f5 ff ff       	call   80102ef2 <lapicinit>
  mpmain();
801039b4:	e8 00 00 00 00       	call   801039b9 <mpmain>

801039b9 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
801039b9:	55                   	push   %ebp
801039ba:	89 e5                	mov    %esp,%ebp
801039bc:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
801039bf:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801039c5:	0f b6 00             	movzbl (%eax),%eax
801039c8:	0f b6 c0             	movzbl %al,%eax
801039cb:	89 44 24 04          	mov    %eax,0x4(%esp)
801039cf:	c7 04 24 7f 94 10 80 	movl   $0x8010947f,(%esp)
801039d6:	e8 c5 c9 ff ff       	call   801003a0 <cprintf>
  idtinit();       // load idt register
801039db:	e8 8e 3a 00 00       	call   8010746e <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
801039e0:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801039e6:	05 a8 00 00 00       	add    $0xa8,%eax
801039eb:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801039f2:	00 
801039f3:	89 04 24             	mov    %eax,(%esp)
801039f6:	e8 d5 fe ff ff       	call   801038d0 <xchg>
  scheduler();     // start running processes
801039fb:	e8 59 11 00 00       	call   80104b59 <scheduler>

80103a00 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103a00:	55                   	push   %ebp
80103a01:	89 e5                	mov    %esp,%ebp
80103a03:	53                   	push   %ebx
80103a04:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
80103a07:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
80103a0e:	e8 b0 fe ff ff       	call   801038c3 <p2v>
80103a13:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80103a16:	b8 8a 00 00 00       	mov    $0x8a,%eax
80103a1b:	89 44 24 08          	mov    %eax,0x8(%esp)
80103a1f:	c7 44 24 04 2c c5 10 	movl   $0x8010c52c,0x4(%esp)
80103a26:	80 
80103a27:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a2a:	89 04 24             	mov    %eax,(%esp)
80103a2d:	e8 c7 23 00 00       	call   80105df9 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80103a32:	c7 45 f4 c0 33 11 80 	movl   $0x801133c0,-0xc(%ebp)
80103a39:	e9 85 00 00 00       	jmp    80103ac3 <startothers+0xc3>
    if(c == cpus+cpunum())  // We've started already.
80103a3e:	e8 08 f6 ff ff       	call   8010304b <cpunum>
80103a43:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103a49:	05 c0 33 11 80       	add    $0x801133c0,%eax
80103a4e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103a51:	75 02                	jne    80103a55 <startothers+0x55>
      continue;
80103a53:	eb 67                	jmp    80103abc <startothers+0xbc>

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80103a55:	e8 5b f2 ff ff       	call   80102cb5 <kalloc>
80103a5a:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
80103a5d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a60:	83 e8 04             	sub    $0x4,%eax
80103a63:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103a66:	81 c2 00 10 00 00    	add    $0x1000,%edx
80103a6c:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
80103a6e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a71:	83 e8 08             	sub    $0x8,%eax
80103a74:	c7 00 9f 39 10 80    	movl   $0x8010399f,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
80103a7a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a7d:	8d 58 f4             	lea    -0xc(%eax),%ebx
80103a80:	c7 04 24 00 b0 10 80 	movl   $0x8010b000,(%esp)
80103a87:	e8 2a fe ff ff       	call   801038b6 <v2p>
80103a8c:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
80103a8e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a91:	89 04 24             	mov    %eax,(%esp)
80103a94:	e8 1d fe ff ff       	call   801038b6 <v2p>
80103a99:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103a9c:	0f b6 12             	movzbl (%edx),%edx
80103a9f:	0f b6 d2             	movzbl %dl,%edx
80103aa2:	89 44 24 04          	mov    %eax,0x4(%esp)
80103aa6:	89 14 24             	mov    %edx,(%esp)
80103aa9:	e8 1f f6 ff ff       	call   801030cd <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80103aae:	90                   	nop
80103aaf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ab2:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80103ab8:	85 c0                	test   %eax,%eax
80103aba:	74 f3                	je     80103aaf <startothers+0xaf>
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
80103abc:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80103ac3:	a1 a0 39 11 80       	mov    0x801139a0,%eax
80103ac8:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103ace:	05 c0 33 11 80       	add    $0x801133c0,%eax
80103ad3:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103ad6:	0f 87 62 ff ff ff    	ja     80103a3e <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80103adc:	83 c4 24             	add    $0x24,%esp
80103adf:	5b                   	pop    %ebx
80103ae0:	5d                   	pop    %ebp
80103ae1:	c3                   	ret    

80103ae2 <p2v>:
80103ae2:	55                   	push   %ebp
80103ae3:	89 e5                	mov    %esp,%ebp
80103ae5:	8b 45 08             	mov    0x8(%ebp),%eax
80103ae8:	05 00 00 00 80       	add    $0x80000000,%eax
80103aed:	5d                   	pop    %ebp
80103aee:	c3                   	ret    

80103aef <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103aef:	55                   	push   %ebp
80103af0:	89 e5                	mov    %esp,%ebp
80103af2:	83 ec 14             	sub    $0x14,%esp
80103af5:	8b 45 08             	mov    0x8(%ebp),%eax
80103af8:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103afc:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80103b00:	89 c2                	mov    %eax,%edx
80103b02:	ec                   	in     (%dx),%al
80103b03:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80103b06:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80103b0a:	c9                   	leave  
80103b0b:	c3                   	ret    

80103b0c <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103b0c:	55                   	push   %ebp
80103b0d:	89 e5                	mov    %esp,%ebp
80103b0f:	83 ec 08             	sub    $0x8,%esp
80103b12:	8b 55 08             	mov    0x8(%ebp),%edx
80103b15:	8b 45 0c             	mov    0xc(%ebp),%eax
80103b18:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103b1c:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103b1f:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103b23:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103b27:	ee                   	out    %al,(%dx)
}
80103b28:	c9                   	leave  
80103b29:	c3                   	ret    

80103b2a <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
80103b2a:	55                   	push   %ebp
80103b2b:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
80103b2d:	a1 64 c6 10 80       	mov    0x8010c664,%eax
80103b32:	89 c2                	mov    %eax,%edx
80103b34:	b8 c0 33 11 80       	mov    $0x801133c0,%eax
80103b39:	29 c2                	sub    %eax,%edx
80103b3b:	89 d0                	mov    %edx,%eax
80103b3d:	c1 f8 02             	sar    $0x2,%eax
80103b40:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
80103b46:	5d                   	pop    %ebp
80103b47:	c3                   	ret    

80103b48 <sum>:

static uchar
sum(uchar *addr, int len)
{
80103b48:	55                   	push   %ebp
80103b49:	89 e5                	mov    %esp,%ebp
80103b4b:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
80103b4e:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
80103b55:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103b5c:	eb 15                	jmp    80103b73 <sum+0x2b>
    sum += addr[i];
80103b5e:	8b 55 fc             	mov    -0x4(%ebp),%edx
80103b61:	8b 45 08             	mov    0x8(%ebp),%eax
80103b64:	01 d0                	add    %edx,%eax
80103b66:	0f b6 00             	movzbl (%eax),%eax
80103b69:	0f b6 c0             	movzbl %al,%eax
80103b6c:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
80103b6f:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103b73:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103b76:	3b 45 0c             	cmp    0xc(%ebp),%eax
80103b79:	7c e3                	jl     80103b5e <sum+0x16>
    sum += addr[i];
  return sum;
80103b7b:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103b7e:	c9                   	leave  
80103b7f:	c3                   	ret    

80103b80 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80103b80:	55                   	push   %ebp
80103b81:	89 e5                	mov    %esp,%ebp
80103b83:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
80103b86:	8b 45 08             	mov    0x8(%ebp),%eax
80103b89:	89 04 24             	mov    %eax,(%esp)
80103b8c:	e8 51 ff ff ff       	call   80103ae2 <p2v>
80103b91:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80103b94:	8b 55 0c             	mov    0xc(%ebp),%edx
80103b97:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b9a:	01 d0                	add    %edx,%eax
80103b9c:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
80103b9f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ba2:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103ba5:	eb 3f                	jmp    80103be6 <mpsearch1+0x66>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80103ba7:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103bae:	00 
80103baf:	c7 44 24 04 90 94 10 	movl   $0x80109490,0x4(%esp)
80103bb6:	80 
80103bb7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103bba:	89 04 24             	mov    %eax,(%esp)
80103bbd:	e8 df 21 00 00       	call   80105da1 <memcmp>
80103bc2:	85 c0                	test   %eax,%eax
80103bc4:	75 1c                	jne    80103be2 <mpsearch1+0x62>
80103bc6:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80103bcd:	00 
80103bce:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103bd1:	89 04 24             	mov    %eax,(%esp)
80103bd4:	e8 6f ff ff ff       	call   80103b48 <sum>
80103bd9:	84 c0                	test   %al,%al
80103bdb:	75 05                	jne    80103be2 <mpsearch1+0x62>
      return (struct mp*)p;
80103bdd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103be0:	eb 11                	jmp    80103bf3 <mpsearch1+0x73>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
80103be2:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80103be6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103be9:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103bec:	72 b9                	jb     80103ba7 <mpsearch1+0x27>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
80103bee:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103bf3:	c9                   	leave  
80103bf4:	c3                   	ret    

80103bf5 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80103bf5:	55                   	push   %ebp
80103bf6:	89 e5                	mov    %esp,%ebp
80103bf8:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
80103bfb:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80103c02:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c05:	83 c0 0f             	add    $0xf,%eax
80103c08:	0f b6 00             	movzbl (%eax),%eax
80103c0b:	0f b6 c0             	movzbl %al,%eax
80103c0e:	c1 e0 08             	shl    $0x8,%eax
80103c11:	89 c2                	mov    %eax,%edx
80103c13:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c16:	83 c0 0e             	add    $0xe,%eax
80103c19:	0f b6 00             	movzbl (%eax),%eax
80103c1c:	0f b6 c0             	movzbl %al,%eax
80103c1f:	09 d0                	or     %edx,%eax
80103c21:	c1 e0 04             	shl    $0x4,%eax
80103c24:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103c27:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103c2b:	74 21                	je     80103c4e <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
80103c2d:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103c34:	00 
80103c35:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c38:	89 04 24             	mov    %eax,(%esp)
80103c3b:	e8 40 ff ff ff       	call   80103b80 <mpsearch1>
80103c40:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103c43:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103c47:	74 50                	je     80103c99 <mpsearch+0xa4>
      return mp;
80103c49:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103c4c:	eb 5f                	jmp    80103cad <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80103c4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c51:	83 c0 14             	add    $0x14,%eax
80103c54:	0f b6 00             	movzbl (%eax),%eax
80103c57:	0f b6 c0             	movzbl %al,%eax
80103c5a:	c1 e0 08             	shl    $0x8,%eax
80103c5d:	89 c2                	mov    %eax,%edx
80103c5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c62:	83 c0 13             	add    $0x13,%eax
80103c65:	0f b6 00             	movzbl (%eax),%eax
80103c68:	0f b6 c0             	movzbl %al,%eax
80103c6b:	09 d0                	or     %edx,%eax
80103c6d:	c1 e0 0a             	shl    $0xa,%eax
80103c70:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80103c73:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c76:	2d 00 04 00 00       	sub    $0x400,%eax
80103c7b:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103c82:	00 
80103c83:	89 04 24             	mov    %eax,(%esp)
80103c86:	e8 f5 fe ff ff       	call   80103b80 <mpsearch1>
80103c8b:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103c8e:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103c92:	74 05                	je     80103c99 <mpsearch+0xa4>
      return mp;
80103c94:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103c97:	eb 14                	jmp    80103cad <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80103c99:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103ca0:	00 
80103ca1:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80103ca8:	e8 d3 fe ff ff       	call   80103b80 <mpsearch1>
}
80103cad:	c9                   	leave  
80103cae:	c3                   	ret    

80103caf <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80103caf:	55                   	push   %ebp
80103cb0:	89 e5                	mov    %esp,%ebp
80103cb2:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80103cb5:	e8 3b ff ff ff       	call   80103bf5 <mpsearch>
80103cba:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103cbd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103cc1:	74 0a                	je     80103ccd <mpconfig+0x1e>
80103cc3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103cc6:	8b 40 04             	mov    0x4(%eax),%eax
80103cc9:	85 c0                	test   %eax,%eax
80103ccb:	75 0a                	jne    80103cd7 <mpconfig+0x28>
    return 0;
80103ccd:	b8 00 00 00 00       	mov    $0x0,%eax
80103cd2:	e9 83 00 00 00       	jmp    80103d5a <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80103cd7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103cda:	8b 40 04             	mov    0x4(%eax),%eax
80103cdd:	89 04 24             	mov    %eax,(%esp)
80103ce0:	e8 fd fd ff ff       	call   80103ae2 <p2v>
80103ce5:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80103ce8:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103cef:	00 
80103cf0:	c7 44 24 04 95 94 10 	movl   $0x80109495,0x4(%esp)
80103cf7:	80 
80103cf8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103cfb:	89 04 24             	mov    %eax,(%esp)
80103cfe:	e8 9e 20 00 00       	call   80105da1 <memcmp>
80103d03:	85 c0                	test   %eax,%eax
80103d05:	74 07                	je     80103d0e <mpconfig+0x5f>
    return 0;
80103d07:	b8 00 00 00 00       	mov    $0x0,%eax
80103d0c:	eb 4c                	jmp    80103d5a <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
80103d0e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d11:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103d15:	3c 01                	cmp    $0x1,%al
80103d17:	74 12                	je     80103d2b <mpconfig+0x7c>
80103d19:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d1c:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103d20:	3c 04                	cmp    $0x4,%al
80103d22:	74 07                	je     80103d2b <mpconfig+0x7c>
    return 0;
80103d24:	b8 00 00 00 00       	mov    $0x0,%eax
80103d29:	eb 2f                	jmp    80103d5a <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
80103d2b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d2e:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103d32:	0f b7 c0             	movzwl %ax,%eax
80103d35:	89 44 24 04          	mov    %eax,0x4(%esp)
80103d39:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d3c:	89 04 24             	mov    %eax,(%esp)
80103d3f:	e8 04 fe ff ff       	call   80103b48 <sum>
80103d44:	84 c0                	test   %al,%al
80103d46:	74 07                	je     80103d4f <mpconfig+0xa0>
    return 0;
80103d48:	b8 00 00 00 00       	mov    $0x0,%eax
80103d4d:	eb 0b                	jmp    80103d5a <mpconfig+0xab>
  *pmp = mp;
80103d4f:	8b 45 08             	mov    0x8(%ebp),%eax
80103d52:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103d55:	89 10                	mov    %edx,(%eax)
  return conf;
80103d57:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80103d5a:	c9                   	leave  
80103d5b:	c3                   	ret    

80103d5c <mpinit>:

void
mpinit(void)
{
80103d5c:	55                   	push   %ebp
80103d5d:	89 e5                	mov    %esp,%ebp
80103d5f:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
80103d62:	c7 05 64 c6 10 80 c0 	movl   $0x801133c0,0x8010c664
80103d69:	33 11 80 
  if((conf = mpconfig(&mp)) == 0)
80103d6c:	8d 45 e0             	lea    -0x20(%ebp),%eax
80103d6f:	89 04 24             	mov    %eax,(%esp)
80103d72:	e8 38 ff ff ff       	call   80103caf <mpconfig>
80103d77:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103d7a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103d7e:	75 05                	jne    80103d85 <mpinit+0x29>
    return;
80103d80:	e9 9c 01 00 00       	jmp    80103f21 <mpinit+0x1c5>
  ismp = 1;
80103d85:	c7 05 a4 33 11 80 01 	movl   $0x1,0x801133a4
80103d8c:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
80103d8f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d92:	8b 40 24             	mov    0x24(%eax),%eax
80103d95:	a3 bc 32 11 80       	mov    %eax,0x801132bc
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103d9a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d9d:	83 c0 2c             	add    $0x2c,%eax
80103da0:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103da3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103da6:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103daa:	0f b7 d0             	movzwl %ax,%edx
80103dad:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103db0:	01 d0                	add    %edx,%eax
80103db2:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103db5:	e9 f4 00 00 00       	jmp    80103eae <mpinit+0x152>
    switch(*p){
80103dba:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103dbd:	0f b6 00             	movzbl (%eax),%eax
80103dc0:	0f b6 c0             	movzbl %al,%eax
80103dc3:	83 f8 04             	cmp    $0x4,%eax
80103dc6:	0f 87 bf 00 00 00    	ja     80103e8b <mpinit+0x12f>
80103dcc:	8b 04 85 d8 94 10 80 	mov    -0x7fef6b28(,%eax,4),%eax
80103dd3:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80103dd5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103dd8:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80103ddb:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103dde:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103de2:	0f b6 d0             	movzbl %al,%edx
80103de5:	a1 a0 39 11 80       	mov    0x801139a0,%eax
80103dea:	39 c2                	cmp    %eax,%edx
80103dec:	74 2d                	je     80103e1b <mpinit+0xbf>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
80103dee:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103df1:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103df5:	0f b6 d0             	movzbl %al,%edx
80103df8:	a1 a0 39 11 80       	mov    0x801139a0,%eax
80103dfd:	89 54 24 08          	mov    %edx,0x8(%esp)
80103e01:	89 44 24 04          	mov    %eax,0x4(%esp)
80103e05:	c7 04 24 9a 94 10 80 	movl   $0x8010949a,(%esp)
80103e0c:	e8 8f c5 ff ff       	call   801003a0 <cprintf>
        ismp = 0;
80103e11:	c7 05 a4 33 11 80 00 	movl   $0x0,0x801133a4
80103e18:	00 00 00 
      }
      if(proc->flags & MPBOOT)
80103e1b:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103e1e:	0f b6 40 03          	movzbl 0x3(%eax),%eax
80103e22:	0f b6 c0             	movzbl %al,%eax
80103e25:	83 e0 02             	and    $0x2,%eax
80103e28:	85 c0                	test   %eax,%eax
80103e2a:	74 15                	je     80103e41 <mpinit+0xe5>
        bcpu = &cpus[ncpu];
80103e2c:	a1 a0 39 11 80       	mov    0x801139a0,%eax
80103e31:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103e37:	05 c0 33 11 80       	add    $0x801133c0,%eax
80103e3c:	a3 64 c6 10 80       	mov    %eax,0x8010c664
      cpus[ncpu].id = ncpu;
80103e41:	8b 15 a0 39 11 80    	mov    0x801139a0,%edx
80103e47:	a1 a0 39 11 80       	mov    0x801139a0,%eax
80103e4c:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80103e52:	81 c2 c0 33 11 80    	add    $0x801133c0,%edx
80103e58:	88 02                	mov    %al,(%edx)
      ncpu++;
80103e5a:	a1 a0 39 11 80       	mov    0x801139a0,%eax
80103e5f:	83 c0 01             	add    $0x1,%eax
80103e62:	a3 a0 39 11 80       	mov    %eax,0x801139a0
      p += sizeof(struct mpproc);
80103e67:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80103e6b:	eb 41                	jmp    80103eae <mpinit+0x152>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80103e6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e70:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80103e73:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103e76:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103e7a:	a2 a0 33 11 80       	mov    %al,0x801133a0
      p += sizeof(struct mpioapic);
80103e7f:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103e83:	eb 29                	jmp    80103eae <mpinit+0x152>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80103e85:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103e89:	eb 23                	jmp    80103eae <mpinit+0x152>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80103e8b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e8e:	0f b6 00             	movzbl (%eax),%eax
80103e91:	0f b6 c0             	movzbl %al,%eax
80103e94:	89 44 24 04          	mov    %eax,0x4(%esp)
80103e98:	c7 04 24 b8 94 10 80 	movl   $0x801094b8,(%esp)
80103e9f:	e8 fc c4 ff ff       	call   801003a0 <cprintf>
      ismp = 0;
80103ea4:	c7 05 a4 33 11 80 00 	movl   $0x0,0x801133a4
80103eab:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103eae:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103eb1:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103eb4:	0f 82 00 ff ff ff    	jb     80103dba <mpinit+0x5e>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80103eba:	a1 a4 33 11 80       	mov    0x801133a4,%eax
80103ebf:	85 c0                	test   %eax,%eax
80103ec1:	75 1d                	jne    80103ee0 <mpinit+0x184>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80103ec3:	c7 05 a0 39 11 80 01 	movl   $0x1,0x801139a0
80103eca:	00 00 00 
    lapic = 0;
80103ecd:	c7 05 bc 32 11 80 00 	movl   $0x0,0x801132bc
80103ed4:	00 00 00 
    ioapicid = 0;
80103ed7:	c6 05 a0 33 11 80 00 	movb   $0x0,0x801133a0
    return;
80103ede:	eb 41                	jmp    80103f21 <mpinit+0x1c5>
  }

  if(mp->imcrp){
80103ee0:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103ee3:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80103ee7:	84 c0                	test   %al,%al
80103ee9:	74 36                	je     80103f21 <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80103eeb:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80103ef2:	00 
80103ef3:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80103efa:	e8 0d fc ff ff       	call   80103b0c <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80103eff:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103f06:	e8 e4 fb ff ff       	call   80103aef <inb>
80103f0b:	83 c8 01             	or     $0x1,%eax
80103f0e:	0f b6 c0             	movzbl %al,%eax
80103f11:	89 44 24 04          	mov    %eax,0x4(%esp)
80103f15:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103f1c:	e8 eb fb ff ff       	call   80103b0c <outb>
  }
}
80103f21:	c9                   	leave  
80103f22:	c3                   	ret    

80103f23 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103f23:	55                   	push   %ebp
80103f24:	89 e5                	mov    %esp,%ebp
80103f26:	83 ec 08             	sub    $0x8,%esp
80103f29:	8b 55 08             	mov    0x8(%ebp),%edx
80103f2c:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f2f:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103f33:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103f36:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103f3a:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103f3e:	ee                   	out    %al,(%dx)
}
80103f3f:	c9                   	leave  
80103f40:	c3                   	ret    

80103f41 <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80103f41:	55                   	push   %ebp
80103f42:	89 e5                	mov    %esp,%ebp
80103f44:	83 ec 0c             	sub    $0xc,%esp
80103f47:	8b 45 08             	mov    0x8(%ebp),%eax
80103f4a:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80103f4e:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103f52:	66 a3 00 c0 10 80    	mov    %ax,0x8010c000
  outb(IO_PIC1+1, mask);
80103f58:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103f5c:	0f b6 c0             	movzbl %al,%eax
80103f5f:	89 44 24 04          	mov    %eax,0x4(%esp)
80103f63:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103f6a:	e8 b4 ff ff ff       	call   80103f23 <outb>
  outb(IO_PIC2+1, mask >> 8);
80103f6f:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103f73:	66 c1 e8 08          	shr    $0x8,%ax
80103f77:	0f b6 c0             	movzbl %al,%eax
80103f7a:	89 44 24 04          	mov    %eax,0x4(%esp)
80103f7e:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103f85:	e8 99 ff ff ff       	call   80103f23 <outb>
}
80103f8a:	c9                   	leave  
80103f8b:	c3                   	ret    

80103f8c <picenable>:

void
picenable(int irq)
{
80103f8c:	55                   	push   %ebp
80103f8d:	89 e5                	mov    %esp,%ebp
80103f8f:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80103f92:	8b 45 08             	mov    0x8(%ebp),%eax
80103f95:	ba 01 00 00 00       	mov    $0x1,%edx
80103f9a:	89 c1                	mov    %eax,%ecx
80103f9c:	d3 e2                	shl    %cl,%edx
80103f9e:	89 d0                	mov    %edx,%eax
80103fa0:	f7 d0                	not    %eax
80103fa2:	89 c2                	mov    %eax,%edx
80103fa4:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
80103fab:	21 d0                	and    %edx,%eax
80103fad:	0f b7 c0             	movzwl %ax,%eax
80103fb0:	89 04 24             	mov    %eax,(%esp)
80103fb3:	e8 89 ff ff ff       	call   80103f41 <picsetmask>
}
80103fb8:	c9                   	leave  
80103fb9:	c3                   	ret    

80103fba <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80103fba:	55                   	push   %ebp
80103fbb:	89 e5                	mov    %esp,%ebp
80103fbd:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80103fc0:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103fc7:	00 
80103fc8:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103fcf:	e8 4f ff ff ff       	call   80103f23 <outb>
  outb(IO_PIC2+1, 0xFF);
80103fd4:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103fdb:	00 
80103fdc:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103fe3:	e8 3b ff ff ff       	call   80103f23 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80103fe8:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103fef:	00 
80103ff0:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103ff7:	e8 27 ff ff ff       	call   80103f23 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
80103ffc:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80104003:	00 
80104004:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
8010400b:	e8 13 ff ff ff       	call   80103f23 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
80104010:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
80104017:	00 
80104018:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
8010401f:	e8 ff fe ff ff       	call   80103f23 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
80104024:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
8010402b:	00 
8010402c:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104033:	e8 eb fe ff ff       	call   80103f23 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80104038:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
8010403f:	00 
80104040:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104047:	e8 d7 fe ff ff       	call   80103f23 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
8010404c:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80104053:	00 
80104054:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
8010405b:	e8 c3 fe ff ff       	call   80103f23 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80104060:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80104067:	00 
80104068:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
8010406f:	e8 af fe ff ff       	call   80103f23 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80104074:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
8010407b:	00 
8010407c:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104083:	e8 9b fe ff ff       	call   80103f23 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80104088:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
8010408f:	00 
80104090:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80104097:	e8 87 fe ff ff       	call   80103f23 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
8010409c:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
801040a3:	00 
801040a4:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801040ab:	e8 73 fe ff ff       	call   80103f23 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
801040b0:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
801040b7:	00 
801040b8:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801040bf:	e8 5f fe ff ff       	call   80103f23 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
801040c4:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
801040cb:	00 
801040cc:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801040d3:	e8 4b fe ff ff       	call   80103f23 <outb>

  if(irqmask != 0xFFFF)
801040d8:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
801040df:	66 83 f8 ff          	cmp    $0xffff,%ax
801040e3:	74 12                	je     801040f7 <picinit+0x13d>
    picsetmask(irqmask);
801040e5:	0f b7 05 00 c0 10 80 	movzwl 0x8010c000,%eax
801040ec:	0f b7 c0             	movzwl %ax,%eax
801040ef:	89 04 24             	mov    %eax,(%esp)
801040f2:	e8 4a fe ff ff       	call   80103f41 <picsetmask>
}
801040f7:	c9                   	leave  
801040f8:	c3                   	ret    

801040f9 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
801040f9:	55                   	push   %ebp
801040fa:	89 e5                	mov    %esp,%ebp
801040fc:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
801040ff:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80104106:	8b 45 0c             	mov    0xc(%ebp),%eax
80104109:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
8010410f:	8b 45 0c             	mov    0xc(%ebp),%eax
80104112:	8b 10                	mov    (%eax),%edx
80104114:	8b 45 08             	mov    0x8(%ebp),%eax
80104117:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80104119:	e8 c0 ce ff ff       	call   80100fde <filealloc>
8010411e:	8b 55 08             	mov    0x8(%ebp),%edx
80104121:	89 02                	mov    %eax,(%edx)
80104123:	8b 45 08             	mov    0x8(%ebp),%eax
80104126:	8b 00                	mov    (%eax),%eax
80104128:	85 c0                	test   %eax,%eax
8010412a:	0f 84 c8 00 00 00    	je     801041f8 <pipealloc+0xff>
80104130:	e8 a9 ce ff ff       	call   80100fde <filealloc>
80104135:	8b 55 0c             	mov    0xc(%ebp),%edx
80104138:	89 02                	mov    %eax,(%edx)
8010413a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010413d:	8b 00                	mov    (%eax),%eax
8010413f:	85 c0                	test   %eax,%eax
80104141:	0f 84 b1 00 00 00    	je     801041f8 <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80104147:	e8 69 eb ff ff       	call   80102cb5 <kalloc>
8010414c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010414f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104153:	75 05                	jne    8010415a <pipealloc+0x61>
    goto bad;
80104155:	e9 9e 00 00 00       	jmp    801041f8 <pipealloc+0xff>
  p->readopen = 1;
8010415a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010415d:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80104164:	00 00 00 
  p->writeopen = 1;
80104167:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010416a:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80104171:	00 00 00 
  p->nwrite = 0;
80104174:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104177:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
8010417e:	00 00 00 
  p->nread = 0;
80104181:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104184:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
8010418b:	00 00 00 
  initlock(&p->lock, "pipe");
8010418e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104191:	c7 44 24 04 ec 94 10 	movl   $0x801094ec,0x4(%esp)
80104198:	80 
80104199:	89 04 24             	mov    %eax,(%esp)
8010419c:	e8 14 19 00 00       	call   80105ab5 <initlock>
  (*f0)->type = FD_PIPE;
801041a1:	8b 45 08             	mov    0x8(%ebp),%eax
801041a4:	8b 00                	mov    (%eax),%eax
801041a6:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
801041ac:	8b 45 08             	mov    0x8(%ebp),%eax
801041af:	8b 00                	mov    (%eax),%eax
801041b1:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
801041b5:	8b 45 08             	mov    0x8(%ebp),%eax
801041b8:	8b 00                	mov    (%eax),%eax
801041ba:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
801041be:	8b 45 08             	mov    0x8(%ebp),%eax
801041c1:	8b 00                	mov    (%eax),%eax
801041c3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801041c6:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
801041c9:	8b 45 0c             	mov    0xc(%ebp),%eax
801041cc:	8b 00                	mov    (%eax),%eax
801041ce:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
801041d4:	8b 45 0c             	mov    0xc(%ebp),%eax
801041d7:	8b 00                	mov    (%eax),%eax
801041d9:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
801041dd:	8b 45 0c             	mov    0xc(%ebp),%eax
801041e0:	8b 00                	mov    (%eax),%eax
801041e2:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
801041e6:	8b 45 0c             	mov    0xc(%ebp),%eax
801041e9:	8b 00                	mov    (%eax),%eax
801041eb:	8b 55 f4             	mov    -0xc(%ebp),%edx
801041ee:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
801041f1:	b8 00 00 00 00       	mov    $0x0,%eax
801041f6:	eb 42                	jmp    8010423a <pipealloc+0x141>

//PAGEBREAK: 20
 bad:
  if(p)
801041f8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801041fc:	74 0b                	je     80104209 <pipealloc+0x110>
    kfree((char*)p);
801041fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104201:	89 04 24             	mov    %eax,(%esp)
80104204:	e8 13 ea ff ff       	call   80102c1c <kfree>
  if(*f0)
80104209:	8b 45 08             	mov    0x8(%ebp),%eax
8010420c:	8b 00                	mov    (%eax),%eax
8010420e:	85 c0                	test   %eax,%eax
80104210:	74 0d                	je     8010421f <pipealloc+0x126>
    fileclose(*f0);
80104212:	8b 45 08             	mov    0x8(%ebp),%eax
80104215:	8b 00                	mov    (%eax),%eax
80104217:	89 04 24             	mov    %eax,(%esp)
8010421a:	e8 67 ce ff ff       	call   80101086 <fileclose>
  if(*f1)
8010421f:	8b 45 0c             	mov    0xc(%ebp),%eax
80104222:	8b 00                	mov    (%eax),%eax
80104224:	85 c0                	test   %eax,%eax
80104226:	74 0d                	je     80104235 <pipealloc+0x13c>
    fileclose(*f1);
80104228:	8b 45 0c             	mov    0xc(%ebp),%eax
8010422b:	8b 00                	mov    (%eax),%eax
8010422d:	89 04 24             	mov    %eax,(%esp)
80104230:	e8 51 ce ff ff       	call   80101086 <fileclose>
  return -1;
80104235:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010423a:	c9                   	leave  
8010423b:	c3                   	ret    

8010423c <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
8010423c:	55                   	push   %ebp
8010423d:	89 e5                	mov    %esp,%ebp
8010423f:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
80104242:	8b 45 08             	mov    0x8(%ebp),%eax
80104245:	89 04 24             	mov    %eax,(%esp)
80104248:	e8 89 18 00 00       	call   80105ad6 <acquire>
  if(writable){
8010424d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104251:	74 1f                	je     80104272 <pipeclose+0x36>
    p->writeopen = 0;
80104253:	8b 45 08             	mov    0x8(%ebp),%eax
80104256:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
8010425d:	00 00 00 
    wakeup(&p->nread);
80104260:	8b 45 08             	mov    0x8(%ebp),%eax
80104263:	05 34 02 00 00       	add    $0x234,%eax
80104268:	89 04 24             	mov    %eax,(%esp)
8010426b:	e8 70 0b 00 00       	call   80104de0 <wakeup>
80104270:	eb 1d                	jmp    8010428f <pipeclose+0x53>
  } else {
    p->readopen = 0;
80104272:	8b 45 08             	mov    0x8(%ebp),%eax
80104275:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
8010427c:	00 00 00 
    wakeup(&p->nwrite);
8010427f:	8b 45 08             	mov    0x8(%ebp),%eax
80104282:	05 38 02 00 00       	add    $0x238,%eax
80104287:	89 04 24             	mov    %eax,(%esp)
8010428a:	e8 51 0b 00 00       	call   80104de0 <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
8010428f:	8b 45 08             	mov    0x8(%ebp),%eax
80104292:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80104298:	85 c0                	test   %eax,%eax
8010429a:	75 25                	jne    801042c1 <pipeclose+0x85>
8010429c:	8b 45 08             	mov    0x8(%ebp),%eax
8010429f:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
801042a5:	85 c0                	test   %eax,%eax
801042a7:	75 18                	jne    801042c1 <pipeclose+0x85>
    release(&p->lock);
801042a9:	8b 45 08             	mov    0x8(%ebp),%eax
801042ac:	89 04 24             	mov    %eax,(%esp)
801042af:	e8 84 18 00 00       	call   80105b38 <release>
    kfree((char*)p);
801042b4:	8b 45 08             	mov    0x8(%ebp),%eax
801042b7:	89 04 24             	mov    %eax,(%esp)
801042ba:	e8 5d e9 ff ff       	call   80102c1c <kfree>
801042bf:	eb 0b                	jmp    801042cc <pipeclose+0x90>
  } else
    release(&p->lock);
801042c1:	8b 45 08             	mov    0x8(%ebp),%eax
801042c4:	89 04 24             	mov    %eax,(%esp)
801042c7:	e8 6c 18 00 00       	call   80105b38 <release>
}
801042cc:	c9                   	leave  
801042cd:	c3                   	ret    

801042ce <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
801042ce:	55                   	push   %ebp
801042cf:	89 e5                	mov    %esp,%ebp
801042d1:	83 ec 28             	sub    $0x28,%esp
  int i;

  acquire(&p->lock);
801042d4:	8b 45 08             	mov    0x8(%ebp),%eax
801042d7:	89 04 24             	mov    %eax,(%esp)
801042da:	e8 f7 17 00 00       	call   80105ad6 <acquire>
  for(i = 0; i < n; i++){
801042df:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801042e6:	e9 a6 00 00 00       	jmp    80104391 <pipewrite+0xc3>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
801042eb:	eb 57                	jmp    80104344 <pipewrite+0x76>
      if(p->readopen == 0 || proc->killed){
801042ed:	8b 45 08             	mov    0x8(%ebp),%eax
801042f0:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
801042f6:	85 c0                	test   %eax,%eax
801042f8:	74 0d                	je     80104307 <pipewrite+0x39>
801042fa:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104300:	8b 40 24             	mov    0x24(%eax),%eax
80104303:	85 c0                	test   %eax,%eax
80104305:	74 15                	je     8010431c <pipewrite+0x4e>
        release(&p->lock);
80104307:	8b 45 08             	mov    0x8(%ebp),%eax
8010430a:	89 04 24             	mov    %eax,(%esp)
8010430d:	e8 26 18 00 00       	call   80105b38 <release>
        return -1;
80104312:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104317:	e9 9f 00 00 00       	jmp    801043bb <pipewrite+0xed>
      }
      wakeup(&p->nread);
8010431c:	8b 45 08             	mov    0x8(%ebp),%eax
8010431f:	05 34 02 00 00       	add    $0x234,%eax
80104324:	89 04 24             	mov    %eax,(%esp)
80104327:	e8 b4 0a 00 00       	call   80104de0 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
8010432c:	8b 45 08             	mov    0x8(%ebp),%eax
8010432f:	8b 55 08             	mov    0x8(%ebp),%edx
80104332:	81 c2 38 02 00 00    	add    $0x238,%edx
80104338:	89 44 24 04          	mov    %eax,0x4(%esp)
8010433c:	89 14 24             	mov    %edx,(%esp)
8010433f:	e8 c0 09 00 00       	call   80104d04 <sleep>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80104344:	8b 45 08             	mov    0x8(%ebp),%eax
80104347:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
8010434d:	8b 45 08             	mov    0x8(%ebp),%eax
80104350:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104356:	05 00 02 00 00       	add    $0x200,%eax
8010435b:	39 c2                	cmp    %eax,%edx
8010435d:	74 8e                	je     801042ed <pipewrite+0x1f>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
8010435f:	8b 45 08             	mov    0x8(%ebp),%eax
80104362:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104368:	8d 48 01             	lea    0x1(%eax),%ecx
8010436b:	8b 55 08             	mov    0x8(%ebp),%edx
8010436e:	89 8a 38 02 00 00    	mov    %ecx,0x238(%edx)
80104374:	25 ff 01 00 00       	and    $0x1ff,%eax
80104379:	89 c1                	mov    %eax,%ecx
8010437b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010437e:	8b 45 0c             	mov    0xc(%ebp),%eax
80104381:	01 d0                	add    %edx,%eax
80104383:	0f b6 10             	movzbl (%eax),%edx
80104386:	8b 45 08             	mov    0x8(%ebp),%eax
80104389:	88 54 08 34          	mov    %dl,0x34(%eax,%ecx,1)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
8010438d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104391:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104394:	3b 45 10             	cmp    0x10(%ebp),%eax
80104397:	0f 8c 4e ff ff ff    	jl     801042eb <pipewrite+0x1d>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
8010439d:	8b 45 08             	mov    0x8(%ebp),%eax
801043a0:	05 34 02 00 00       	add    $0x234,%eax
801043a5:	89 04 24             	mov    %eax,(%esp)
801043a8:	e8 33 0a 00 00       	call   80104de0 <wakeup>
  release(&p->lock);
801043ad:	8b 45 08             	mov    0x8(%ebp),%eax
801043b0:	89 04 24             	mov    %eax,(%esp)
801043b3:	e8 80 17 00 00       	call   80105b38 <release>
  return n;
801043b8:	8b 45 10             	mov    0x10(%ebp),%eax
}
801043bb:	c9                   	leave  
801043bc:	c3                   	ret    

801043bd <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
801043bd:	55                   	push   %ebp
801043be:	89 e5                	mov    %esp,%ebp
801043c0:	53                   	push   %ebx
801043c1:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
801043c4:	8b 45 08             	mov    0x8(%ebp),%eax
801043c7:	89 04 24             	mov    %eax,(%esp)
801043ca:	e8 07 17 00 00       	call   80105ad6 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801043cf:	eb 3a                	jmp    8010440b <piperead+0x4e>
    if(proc->killed){
801043d1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801043d7:	8b 40 24             	mov    0x24(%eax),%eax
801043da:	85 c0                	test   %eax,%eax
801043dc:	74 15                	je     801043f3 <piperead+0x36>
      release(&p->lock);
801043de:	8b 45 08             	mov    0x8(%ebp),%eax
801043e1:	89 04 24             	mov    %eax,(%esp)
801043e4:	e8 4f 17 00 00       	call   80105b38 <release>
      return -1;
801043e9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043ee:	e9 b5 00 00 00       	jmp    801044a8 <piperead+0xeb>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
801043f3:	8b 45 08             	mov    0x8(%ebp),%eax
801043f6:	8b 55 08             	mov    0x8(%ebp),%edx
801043f9:	81 c2 34 02 00 00    	add    $0x234,%edx
801043ff:	89 44 24 04          	mov    %eax,0x4(%esp)
80104403:	89 14 24             	mov    %edx,(%esp)
80104406:	e8 f9 08 00 00       	call   80104d04 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
8010440b:	8b 45 08             	mov    0x8(%ebp),%eax
8010440e:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104414:	8b 45 08             	mov    0x8(%ebp),%eax
80104417:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
8010441d:	39 c2                	cmp    %eax,%edx
8010441f:	75 0d                	jne    8010442e <piperead+0x71>
80104421:	8b 45 08             	mov    0x8(%ebp),%eax
80104424:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
8010442a:	85 c0                	test   %eax,%eax
8010442c:	75 a3                	jne    801043d1 <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
8010442e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104435:	eb 4b                	jmp    80104482 <piperead+0xc5>
    if(p->nread == p->nwrite)
80104437:	8b 45 08             	mov    0x8(%ebp),%eax
8010443a:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104440:	8b 45 08             	mov    0x8(%ebp),%eax
80104443:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104449:	39 c2                	cmp    %eax,%edx
8010444b:	75 02                	jne    8010444f <piperead+0x92>
      break;
8010444d:	eb 3b                	jmp    8010448a <piperead+0xcd>
    addr[i] = p->data[p->nread++ % PIPESIZE];
8010444f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104452:	8b 45 0c             	mov    0xc(%ebp),%eax
80104455:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80104458:	8b 45 08             	mov    0x8(%ebp),%eax
8010445b:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104461:	8d 48 01             	lea    0x1(%eax),%ecx
80104464:	8b 55 08             	mov    0x8(%ebp),%edx
80104467:	89 8a 34 02 00 00    	mov    %ecx,0x234(%edx)
8010446d:	25 ff 01 00 00       	and    $0x1ff,%eax
80104472:	89 c2                	mov    %eax,%edx
80104474:	8b 45 08             	mov    0x8(%ebp),%eax
80104477:	0f b6 44 10 34       	movzbl 0x34(%eax,%edx,1),%eax
8010447c:	88 03                	mov    %al,(%ebx)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
8010447e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104482:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104485:	3b 45 10             	cmp    0x10(%ebp),%eax
80104488:	7c ad                	jl     80104437 <piperead+0x7a>
    if(p->nread == p->nwrite)
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
8010448a:	8b 45 08             	mov    0x8(%ebp),%eax
8010448d:	05 38 02 00 00       	add    $0x238,%eax
80104492:	89 04 24             	mov    %eax,(%esp)
80104495:	e8 46 09 00 00       	call   80104de0 <wakeup>
  release(&p->lock);
8010449a:	8b 45 08             	mov    0x8(%ebp),%eax
8010449d:	89 04 24             	mov    %eax,(%esp)
801044a0:	e8 93 16 00 00       	call   80105b38 <release>
  return i;
801044a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801044a8:	83 c4 24             	add    $0x24,%esp
801044ab:	5b                   	pop    %ebx
801044ac:	5d                   	pop    %ebp
801044ad:	c3                   	ret    

801044ae <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
801044ae:	55                   	push   %ebp
801044af:	89 e5                	mov    %esp,%ebp
801044b1:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801044b4:	9c                   	pushf  
801044b5:	58                   	pop    %eax
801044b6:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
801044b9:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801044bc:	c9                   	leave  
801044bd:	c3                   	ret    

801044be <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
801044be:	55                   	push   %ebp
801044bf:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
801044c1:	fb                   	sti    
}
801044c2:	5d                   	pop    %ebp
801044c3:	c3                   	ret    

801044c4 <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
801044c4:	55                   	push   %ebp
801044c5:	89 e5                	mov    %esp,%ebp
801044c7:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
801044ca:	c7 44 24 04 f1 94 10 	movl   $0x801094f1,0x4(%esp)
801044d1:	80 
801044d2:	c7 04 24 c0 39 11 80 	movl   $0x801139c0,(%esp)
801044d9:	e8 d7 15 00 00       	call   80105ab5 <initlock>
}
801044de:	c9                   	leave  
801044df:	c3                   	ret    

801044e0 <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
801044e0:	55                   	push   %ebp
801044e1:	89 e5                	mov    %esp,%ebp
801044e3:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
801044e6:	c7 04 24 c0 39 11 80 	movl   $0x801139c0,(%esp)
801044ed:	e8 e4 15 00 00       	call   80105ad6 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801044f2:	c7 45 f4 f4 39 11 80 	movl   $0x801139f4,-0xc(%ebp)
801044f9:	eb 53                	jmp    8010454e <allocproc+0x6e>
    if(p->state == UNUSED)
801044fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044fe:	8b 40 0c             	mov    0xc(%eax),%eax
80104501:	85 c0                	test   %eax,%eax
80104503:	75 42                	jne    80104547 <allocproc+0x67>
      goto found;
80104505:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
80104506:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104509:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
80104510:	a1 04 c0 10 80       	mov    0x8010c004,%eax
80104515:	8d 50 01             	lea    0x1(%eax),%edx
80104518:	89 15 04 c0 10 80    	mov    %edx,0x8010c004
8010451e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104521:	89 42 10             	mov    %eax,0x10(%edx)
  release(&ptable.lock);
80104524:	c7 04 24 c0 39 11 80 	movl   $0x801139c0,(%esp)
8010452b:	e8 08 16 00 00       	call   80105b38 <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
80104530:	e8 80 e7 ff ff       	call   80102cb5 <kalloc>
80104535:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104538:	89 42 08             	mov    %eax,0x8(%edx)
8010453b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010453e:	8b 40 08             	mov    0x8(%eax),%eax
80104541:	85 c0                	test   %eax,%eax
80104543:	75 36                	jne    8010457b <allocproc+0x9b>
80104545:	eb 23                	jmp    8010456a <allocproc+0x8a>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104547:	81 45 f4 e4 00 00 00 	addl   $0xe4,-0xc(%ebp)
8010454e:	81 7d f4 f4 72 11 80 	cmpl   $0x801172f4,-0xc(%ebp)
80104555:	72 a4                	jb     801044fb <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
80104557:	c7 04 24 c0 39 11 80 	movl   $0x801139c0,(%esp)
8010455e:	e8 d5 15 00 00       	call   80105b38 <release>
  return 0;
80104563:	b8 00 00 00 00       	mov    $0x0,%eax
80104568:	eb 76                	jmp    801045e0 <allocproc+0x100>
  p->pid = nextpid++;
  release(&ptable.lock);

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
    p->state = UNUSED;
8010456a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010456d:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
80104574:	b8 00 00 00 00       	mov    $0x0,%eax
80104579:	eb 65                	jmp    801045e0 <allocproc+0x100>
  }
  sp = p->kstack + KSTACKSIZE;
8010457b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010457e:	8b 40 08             	mov    0x8(%eax),%eax
80104581:	05 00 10 00 00       	add    $0x1000,%eax
80104586:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
80104589:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
8010458d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104590:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104593:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
80104596:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
8010459a:	ba b5 72 10 80       	mov    $0x801072b5,%edx
8010459f:	8b 45 f0             	mov    -0x10(%ebp),%eax
801045a2:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
801045a4:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
801045a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045ab:	8b 55 f0             	mov    -0x10(%ebp),%edx
801045ae:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
801045b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045b4:	8b 40 1c             	mov    0x1c(%eax),%eax
801045b7:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
801045be:	00 
801045bf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801045c6:	00 
801045c7:	89 04 24             	mov    %eax,(%esp)
801045ca:	e8 5b 17 00 00       	call   80105d2a <memset>
  p->context->eip = (uint)forkret;
801045cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045d2:	8b 40 1c             	mov    0x1c(%eax),%eax
801045d5:	ba d8 4c 10 80       	mov    $0x80104cd8,%edx
801045da:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
801045dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801045e0:	c9                   	leave  
801045e1:	c3                   	ret    

801045e2 <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
801045e2:	55                   	push   %ebp
801045e3:	89 e5                	mov    %esp,%ebp
801045e5:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
801045e8:	e8 f3 fe ff ff       	call   801044e0 <allocproc>
801045ed:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
801045f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045f3:	a3 68 c6 10 80       	mov    %eax,0x8010c668
  if((p->pgdir = setupkvm()) == 0)
801045f8:	e8 ac 43 00 00       	call   801089a9 <setupkvm>
801045fd:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104600:	89 42 04             	mov    %eax,0x4(%edx)
80104603:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104606:	8b 40 04             	mov    0x4(%eax),%eax
80104609:	85 c0                	test   %eax,%eax
8010460b:	75 0c                	jne    80104619 <userinit+0x37>
    panic("userinit: out of memory?");
8010460d:	c7 04 24 f8 94 10 80 	movl   $0x801094f8,(%esp)
80104614:	e8 21 bf ff ff       	call   8010053a <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80104619:	ba 2c 00 00 00       	mov    $0x2c,%edx
8010461e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104621:	8b 40 04             	mov    0x4(%eax),%eax
80104624:	89 54 24 08          	mov    %edx,0x8(%esp)
80104628:	c7 44 24 04 00 c5 10 	movl   $0x8010c500,0x4(%esp)
8010462f:	80 
80104630:	89 04 24             	mov    %eax,(%esp)
80104633:	e8 c9 45 00 00       	call   80108c01 <inituvm>
  p->sz = PGSIZE;
80104638:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010463b:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
80104641:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104644:	8b 40 18             	mov    0x18(%eax),%eax
80104647:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
8010464e:	00 
8010464f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104656:	00 
80104657:	89 04 24             	mov    %eax,(%esp)
8010465a:	e8 cb 16 00 00       	call   80105d2a <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
8010465f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104662:	8b 40 18             	mov    0x18(%eax),%eax
80104665:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
8010466b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010466e:	8b 40 18             	mov    0x18(%eax),%eax
80104671:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
80104677:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010467a:	8b 40 18             	mov    0x18(%eax),%eax
8010467d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104680:	8b 52 18             	mov    0x18(%edx),%edx
80104683:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104687:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
8010468b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010468e:	8b 40 18             	mov    0x18(%eax),%eax
80104691:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104694:	8b 52 18             	mov    0x18(%edx),%edx
80104697:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
8010469b:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
8010469f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046a2:	8b 40 18             	mov    0x18(%eax),%eax
801046a5:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801046ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046af:	8b 40 18             	mov    0x18(%eax),%eax
801046b2:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
801046b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046bc:	8b 40 18             	mov    0x18(%eax),%eax
801046bf:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
801046c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046c9:	83 c0 6c             	add    $0x6c,%eax
801046cc:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801046d3:	00 
801046d4:	c7 44 24 04 11 95 10 	movl   $0x80109511,0x4(%esp)
801046db:	80 
801046dc:	89 04 24             	mov    %eax,(%esp)
801046df:	e8 66 18 00 00       	call   80105f4a <safestrcpy>
  p->cwd = namei("/");
801046e4:	c7 04 24 1a 95 10 80 	movl   $0x8010951a,(%esp)
801046eb:	e8 e9 de ff ff       	call   801025d9 <namei>
801046f0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801046f3:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
801046f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046f9:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
80104700:	c9                   	leave  
80104701:	c3                   	ret    

80104702 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80104702:	55                   	push   %ebp
80104703:	89 e5                	mov    %esp,%ebp
80104705:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
80104708:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010470e:	8b 00                	mov    (%eax),%eax
80104710:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80104713:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104717:	7e 34                	jle    8010474d <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
80104719:	8b 55 08             	mov    0x8(%ebp),%edx
8010471c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010471f:	01 c2                	add    %eax,%edx
80104721:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104727:	8b 40 04             	mov    0x4(%eax),%eax
8010472a:	89 54 24 08          	mov    %edx,0x8(%esp)
8010472e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104731:	89 54 24 04          	mov    %edx,0x4(%esp)
80104735:	89 04 24             	mov    %eax,(%esp)
80104738:	e8 3a 46 00 00       	call   80108d77 <allocuvm>
8010473d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104740:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104744:	75 41                	jne    80104787 <growproc+0x85>
      return -1;
80104746:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010474b:	eb 58                	jmp    801047a5 <growproc+0xa3>
  } else if(n < 0){
8010474d:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104751:	79 34                	jns    80104787 <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
80104753:	8b 55 08             	mov    0x8(%ebp),%edx
80104756:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104759:	01 c2                	add    %eax,%edx
8010475b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104761:	8b 40 04             	mov    0x4(%eax),%eax
80104764:	89 54 24 08          	mov    %edx,0x8(%esp)
80104768:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010476b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010476f:	89 04 24             	mov    %eax,(%esp)
80104772:	e8 da 46 00 00       	call   80108e51 <deallocuvm>
80104777:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010477a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010477e:	75 07                	jne    80104787 <growproc+0x85>
      return -1;
80104780:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104785:	eb 1e                	jmp    801047a5 <growproc+0xa3>
  }
  proc->sz = sz;
80104787:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010478d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104790:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80104792:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104798:	89 04 24             	mov    %eax,(%esp)
8010479b:	e8 fa 42 00 00       	call   80108a9a <switchuvm>
  return 0;
801047a0:	b8 00 00 00 00       	mov    $0x0,%eax
}
801047a5:	c9                   	leave  
801047a6:	c3                   	ret    

801047a7 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
801047a7:	55                   	push   %ebp
801047a8:	89 e5                	mov    %esp,%ebp
801047aa:	57                   	push   %edi
801047ab:	56                   	push   %esi
801047ac:	53                   	push   %ebx
801047ad:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
801047b0:	e8 2b fd ff ff       	call   801044e0 <allocproc>
801047b5:	89 45 e0             	mov    %eax,-0x20(%ebp)
801047b8:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
801047bc:	75 0a                	jne    801047c8 <fork+0x21>
    return -1;
801047be:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047c3:	e9 52 01 00 00       	jmp    8010491a <fork+0x173>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
801047c8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047ce:	8b 10                	mov    (%eax),%edx
801047d0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047d6:	8b 40 04             	mov    0x4(%eax),%eax
801047d9:	89 54 24 04          	mov    %edx,0x4(%esp)
801047dd:	89 04 24             	mov    %eax,(%esp)
801047e0:	e8 08 48 00 00       	call   80108fed <copyuvm>
801047e5:	8b 55 e0             	mov    -0x20(%ebp),%edx
801047e8:	89 42 04             	mov    %eax,0x4(%edx)
801047eb:	8b 45 e0             	mov    -0x20(%ebp),%eax
801047ee:	8b 40 04             	mov    0x4(%eax),%eax
801047f1:	85 c0                	test   %eax,%eax
801047f3:	75 2c                	jne    80104821 <fork+0x7a>
    kfree(np->kstack);
801047f5:	8b 45 e0             	mov    -0x20(%ebp),%eax
801047f8:	8b 40 08             	mov    0x8(%eax),%eax
801047fb:	89 04 24             	mov    %eax,(%esp)
801047fe:	e8 19 e4 ff ff       	call   80102c1c <kfree>
    np->kstack = 0;
80104803:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104806:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
8010480d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104810:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
80104817:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010481c:	e9 f9 00 00 00       	jmp    8010491a <fork+0x173>
  }
  np->sz = proc->sz;
80104821:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104827:	8b 10                	mov    (%eax),%edx
80104829:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010482c:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
8010482e:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104835:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104838:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
8010483b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010483e:	8b 50 18             	mov    0x18(%eax),%edx
80104841:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104847:	8b 40 18             	mov    0x18(%eax),%eax
8010484a:	89 c3                	mov    %eax,%ebx
8010484c:	b8 13 00 00 00       	mov    $0x13,%eax
80104851:	89 d7                	mov    %edx,%edi
80104853:	89 de                	mov    %ebx,%esi
80104855:	89 c1                	mov    %eax,%ecx
80104857:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
80104859:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010485c:	8b 40 18             	mov    0x18(%eax),%eax
8010485f:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
80104866:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
8010486d:	eb 3d                	jmp    801048ac <fork+0x105>
    if(proc->ofile[i])
8010486f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104875:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104878:	83 c2 08             	add    $0x8,%edx
8010487b:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010487f:	85 c0                	test   %eax,%eax
80104881:	74 25                	je     801048a8 <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
80104883:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104889:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010488c:	83 c2 08             	add    $0x8,%edx
8010488f:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104893:	89 04 24             	mov    %eax,(%esp)
80104896:	e8 a3 c7 ff ff       	call   8010103e <filedup>
8010489b:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010489e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801048a1:	83 c1 08             	add    $0x8,%ecx
801048a4:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
801048a8:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
801048ac:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
801048b0:	7e bd                	jle    8010486f <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
801048b2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048b8:	8b 40 68             	mov    0x68(%eax),%eax
801048bb:	89 04 24             	mov    %eax,(%esp)
801048be:	e8 1e d0 ff ff       	call   801018e1 <idup>
801048c3:	8b 55 e0             	mov    -0x20(%ebp),%edx
801048c6:	89 42 68             	mov    %eax,0x68(%edx)

  safestrcpy(np->name, proc->name, sizeof(proc->name));
801048c9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048cf:	8d 50 6c             	lea    0x6c(%eax),%edx
801048d2:	8b 45 e0             	mov    -0x20(%ebp),%eax
801048d5:	83 c0 6c             	add    $0x6c,%eax
801048d8:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801048df:	00 
801048e0:	89 54 24 04          	mov    %edx,0x4(%esp)
801048e4:	89 04 24             	mov    %eax,(%esp)
801048e7:	e8 5e 16 00 00       	call   80105f4a <safestrcpy>
 
  pid = np->pid;
801048ec:	8b 45 e0             	mov    -0x20(%ebp),%eax
801048ef:	8b 40 10             	mov    0x10(%eax),%eax
801048f2:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // lock to force the compiler to emit the np->state write last.
  acquire(&ptable.lock);
801048f5:	c7 04 24 c0 39 11 80 	movl   $0x801139c0,(%esp)
801048fc:	e8 d5 11 00 00       	call   80105ad6 <acquire>
  np->state = RUNNABLE;
80104901:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104904:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  release(&ptable.lock);
8010490b:	c7 04 24 c0 39 11 80 	movl   $0x801139c0,(%esp)
80104912:	e8 21 12 00 00       	call   80105b38 <release>
  
  return pid;
80104917:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
8010491a:	83 c4 2c             	add    $0x2c,%esp
8010491d:	5b                   	pop    %ebx
8010491e:	5e                   	pop    %esi
8010491f:	5f                   	pop    %edi
80104920:	5d                   	pop    %ebp
80104921:	c3                   	ret    

80104922 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
80104922:	55                   	push   %ebp
80104923:	89 e5                	mov    %esp,%ebp
80104925:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
80104928:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010492f:	a1 68 c6 10 80       	mov    0x8010c668,%eax
80104934:	39 c2                	cmp    %eax,%edx
80104936:	75 0c                	jne    80104944 <exit+0x22>
    panic("init exiting");
80104938:	c7 04 24 1c 95 10 80 	movl   $0x8010951c,(%esp)
8010493f:	e8 f6 bb ff ff       	call   8010053a <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104944:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
8010494b:	eb 44                	jmp    80104991 <exit+0x6f>
    if(proc->ofile[fd]){
8010494d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104953:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104956:	83 c2 08             	add    $0x8,%edx
80104959:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010495d:	85 c0                	test   %eax,%eax
8010495f:	74 2c                	je     8010498d <exit+0x6b>
      fileclose(proc->ofile[fd]);
80104961:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104967:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010496a:	83 c2 08             	add    $0x8,%edx
8010496d:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104971:	89 04 24             	mov    %eax,(%esp)
80104974:	e8 0d c7 ff ff       	call   80101086 <fileclose>
      proc->ofile[fd] = 0;
80104979:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010497f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104982:	83 c2 08             	add    $0x8,%edx
80104985:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
8010498c:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
8010498d:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104991:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80104995:	7e b6                	jle    8010494d <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  begin_op();
80104997:	e8 47 ec ff ff       	call   801035e3 <begin_op>
  iput(proc->cwd);
8010499c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049a2:	8b 40 68             	mov    0x68(%eax),%eax
801049a5:	89 04 24             	mov    %eax,(%esp)
801049a8:	e8 19 d1 ff ff       	call   80101ac6 <iput>
  end_op();
801049ad:	e8 b5 ec ff ff       	call   80103667 <end_op>
  proc->cwd = 0;
801049b2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049b8:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
801049bf:	c7 04 24 c0 39 11 80 	movl   $0x801139c0,(%esp)
801049c6:	e8 0b 11 00 00       	call   80105ad6 <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
801049cb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049d1:	8b 40 14             	mov    0x14(%eax),%eax
801049d4:	89 04 24             	mov    %eax,(%esp)
801049d7:	e8 c3 03 00 00       	call   80104d9f <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801049dc:	c7 45 f4 f4 39 11 80 	movl   $0x801139f4,-0xc(%ebp)
801049e3:	eb 3b                	jmp    80104a20 <exit+0xfe>
    if(p->parent == proc){
801049e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049e8:	8b 50 14             	mov    0x14(%eax),%edx
801049eb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049f1:	39 c2                	cmp    %eax,%edx
801049f3:	75 24                	jne    80104a19 <exit+0xf7>
      p->parent = initproc;
801049f5:	8b 15 68 c6 10 80    	mov    0x8010c668,%edx
801049fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049fe:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
80104a01:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a04:	8b 40 0c             	mov    0xc(%eax),%eax
80104a07:	83 f8 05             	cmp    $0x5,%eax
80104a0a:	75 0d                	jne    80104a19 <exit+0xf7>
        wakeup1(initproc);
80104a0c:	a1 68 c6 10 80       	mov    0x8010c668,%eax
80104a11:	89 04 24             	mov    %eax,(%esp)
80104a14:	e8 86 03 00 00       	call   80104d9f <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104a19:	81 45 f4 e4 00 00 00 	addl   $0xe4,-0xc(%ebp)
80104a20:	81 7d f4 f4 72 11 80 	cmpl   $0x801172f4,-0xc(%ebp)
80104a27:	72 bc                	jb     801049e5 <exit+0xc3>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
80104a29:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a2f:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
80104a36:	e8 b9 01 00 00       	call   80104bf4 <sched>
  panic("zombie exit");
80104a3b:	c7 04 24 29 95 10 80 	movl   $0x80109529,(%esp)
80104a42:	e8 f3 ba ff ff       	call   8010053a <panic>

80104a47 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
80104a47:	55                   	push   %ebp
80104a48:	89 e5                	mov    %esp,%ebp
80104a4a:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
80104a4d:	c7 04 24 c0 39 11 80 	movl   $0x801139c0,(%esp)
80104a54:	e8 7d 10 00 00       	call   80105ad6 <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
80104a59:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104a60:	c7 45 f4 f4 39 11 80 	movl   $0x801139f4,-0xc(%ebp)
80104a67:	e9 9d 00 00 00       	jmp    80104b09 <wait+0xc2>
      if(p->parent != proc)
80104a6c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a6f:	8b 50 14             	mov    0x14(%eax),%edx
80104a72:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a78:	39 c2                	cmp    %eax,%edx
80104a7a:	74 05                	je     80104a81 <wait+0x3a>
        continue;
80104a7c:	e9 81 00 00 00       	jmp    80104b02 <wait+0xbb>
      havekids = 1;
80104a81:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
80104a88:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a8b:	8b 40 0c             	mov    0xc(%eax),%eax
80104a8e:	83 f8 05             	cmp    $0x5,%eax
80104a91:	75 6f                	jne    80104b02 <wait+0xbb>
        // Found one.
        pid = p->pid;
80104a93:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a96:	8b 40 10             	mov    0x10(%eax),%eax
80104a99:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
80104a9c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a9f:	8b 40 08             	mov    0x8(%eax),%eax
80104aa2:	89 04 24             	mov    %eax,(%esp)
80104aa5:	e8 72 e1 ff ff       	call   80102c1c <kfree>
        p->kstack = 0;
80104aaa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104aad:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
80104ab4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ab7:	8b 40 04             	mov    0x4(%eax),%eax
80104aba:	89 04 24             	mov    %eax,(%esp)
80104abd:	e8 4b 44 00 00       	call   80108f0d <freevm>
        p->state = UNUSED;
80104ac2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ac5:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
80104acc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104acf:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
80104ad6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ad9:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
80104ae0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ae3:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
80104ae7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104aea:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
80104af1:	c7 04 24 c0 39 11 80 	movl   $0x801139c0,(%esp)
80104af8:	e8 3b 10 00 00       	call   80105b38 <release>
        return pid;
80104afd:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104b00:	eb 55                	jmp    80104b57 <wait+0x110>

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104b02:	81 45 f4 e4 00 00 00 	addl   $0xe4,-0xc(%ebp)
80104b09:	81 7d f4 f4 72 11 80 	cmpl   $0x801172f4,-0xc(%ebp)
80104b10:	0f 82 56 ff ff ff    	jb     80104a6c <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
80104b16:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104b1a:	74 0d                	je     80104b29 <wait+0xe2>
80104b1c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b22:	8b 40 24             	mov    0x24(%eax),%eax
80104b25:	85 c0                	test   %eax,%eax
80104b27:	74 13                	je     80104b3c <wait+0xf5>
      release(&ptable.lock);
80104b29:	c7 04 24 c0 39 11 80 	movl   $0x801139c0,(%esp)
80104b30:	e8 03 10 00 00       	call   80105b38 <release>
      return -1;
80104b35:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b3a:	eb 1b                	jmp    80104b57 <wait+0x110>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80104b3c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b42:	c7 44 24 04 c0 39 11 	movl   $0x801139c0,0x4(%esp)
80104b49:	80 
80104b4a:	89 04 24             	mov    %eax,(%esp)
80104b4d:	e8 b2 01 00 00       	call   80104d04 <sleep>
  }
80104b52:	e9 02 ff ff ff       	jmp    80104a59 <wait+0x12>
}
80104b57:	c9                   	leave  
80104b58:	c3                   	ret    

80104b59 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
80104b59:	55                   	push   %ebp
80104b5a:	89 e5                	mov    %esp,%ebp
80104b5c:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
80104b5f:	e8 5a f9 ff ff       	call   801044be <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
80104b64:	c7 04 24 c0 39 11 80 	movl   $0x801139c0,(%esp)
80104b6b:	e8 66 0f 00 00       	call   80105ad6 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104b70:	c7 45 f4 f4 39 11 80 	movl   $0x801139f4,-0xc(%ebp)
80104b77:	eb 61                	jmp    80104bda <scheduler+0x81>
      if(p->state != RUNNABLE)
80104b79:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b7c:	8b 40 0c             	mov    0xc(%eax),%eax
80104b7f:	83 f8 03             	cmp    $0x3,%eax
80104b82:	74 02                	je     80104b86 <scheduler+0x2d>
        continue;
80104b84:	eb 4d                	jmp    80104bd3 <scheduler+0x7a>

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
80104b86:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b89:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
80104b8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b92:	89 04 24             	mov    %eax,(%esp)
80104b95:	e8 00 3f 00 00       	call   80108a9a <switchuvm>
      p->state = RUNNING;
80104b9a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b9d:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
80104ba4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104baa:	8b 40 1c             	mov    0x1c(%eax),%eax
80104bad:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104bb4:	83 c2 04             	add    $0x4,%edx
80104bb7:	89 44 24 04          	mov    %eax,0x4(%esp)
80104bbb:	89 14 24             	mov    %edx,(%esp)
80104bbe:	e8 09 15 00 00       	call   801060cc <swtch>
      switchkvm();
80104bc3:	e8 b5 3e 00 00       	call   80108a7d <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
80104bc8:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80104bcf:	00 00 00 00 
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104bd3:	81 45 f4 e4 00 00 00 	addl   $0xe4,-0xc(%ebp)
80104bda:	81 7d f4 f4 72 11 80 	cmpl   $0x801172f4,-0xc(%ebp)
80104be1:	72 96                	jb     80104b79 <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
80104be3:	c7 04 24 c0 39 11 80 	movl   $0x801139c0,(%esp)
80104bea:	e8 49 0f 00 00       	call   80105b38 <release>

  }
80104bef:	e9 6b ff ff ff       	jmp    80104b5f <scheduler+0x6>

80104bf4 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80104bf4:	55                   	push   %ebp
80104bf5:	89 e5                	mov    %esp,%ebp
80104bf7:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80104bfa:	c7 04 24 c0 39 11 80 	movl   $0x801139c0,(%esp)
80104c01:	e8 fa 0f 00 00       	call   80105c00 <holding>
80104c06:	85 c0                	test   %eax,%eax
80104c08:	75 0c                	jne    80104c16 <sched+0x22>
    panic("sched ptable.lock");
80104c0a:	c7 04 24 35 95 10 80 	movl   $0x80109535,(%esp)
80104c11:	e8 24 b9 ff ff       	call   8010053a <panic>
  if(cpu->ncli != 1)
80104c16:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104c1c:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104c22:	83 f8 01             	cmp    $0x1,%eax
80104c25:	74 0c                	je     80104c33 <sched+0x3f>
    panic("sched locks");
80104c27:	c7 04 24 47 95 10 80 	movl   $0x80109547,(%esp)
80104c2e:	e8 07 b9 ff ff       	call   8010053a <panic>
  if(proc->state == RUNNING)
80104c33:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c39:	8b 40 0c             	mov    0xc(%eax),%eax
80104c3c:	83 f8 04             	cmp    $0x4,%eax
80104c3f:	75 0c                	jne    80104c4d <sched+0x59>
    panic("sched running");
80104c41:	c7 04 24 53 95 10 80 	movl   $0x80109553,(%esp)
80104c48:	e8 ed b8 ff ff       	call   8010053a <panic>
  if(readeflags()&FL_IF)
80104c4d:	e8 5c f8 ff ff       	call   801044ae <readeflags>
80104c52:	25 00 02 00 00       	and    $0x200,%eax
80104c57:	85 c0                	test   %eax,%eax
80104c59:	74 0c                	je     80104c67 <sched+0x73>
    panic("sched interruptible");
80104c5b:	c7 04 24 61 95 10 80 	movl   $0x80109561,(%esp)
80104c62:	e8 d3 b8 ff ff       	call   8010053a <panic>
  intena = cpu->intena;
80104c67:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104c6d:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80104c73:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
80104c76:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104c7c:	8b 40 04             	mov    0x4(%eax),%eax
80104c7f:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104c86:	83 c2 1c             	add    $0x1c,%edx
80104c89:	89 44 24 04          	mov    %eax,0x4(%esp)
80104c8d:	89 14 24             	mov    %edx,(%esp)
80104c90:	e8 37 14 00 00       	call   801060cc <swtch>
  cpu->intena = intena;
80104c95:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104c9b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c9e:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80104ca4:	c9                   	leave  
80104ca5:	c3                   	ret    

80104ca6 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80104ca6:	55                   	push   %ebp
80104ca7:	89 e5                	mov    %esp,%ebp
80104ca9:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80104cac:	c7 04 24 c0 39 11 80 	movl   $0x801139c0,(%esp)
80104cb3:	e8 1e 0e 00 00       	call   80105ad6 <acquire>
  proc->state = RUNNABLE;
80104cb8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104cbe:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80104cc5:	e8 2a ff ff ff       	call   80104bf4 <sched>
  release(&ptable.lock);
80104cca:	c7 04 24 c0 39 11 80 	movl   $0x801139c0,(%esp)
80104cd1:	e8 62 0e 00 00       	call   80105b38 <release>
}
80104cd6:	c9                   	leave  
80104cd7:	c3                   	ret    

80104cd8 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80104cd8:	55                   	push   %ebp
80104cd9:	89 e5                	mov    %esp,%ebp
80104cdb:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80104cde:	c7 04 24 c0 39 11 80 	movl   $0x801139c0,(%esp)
80104ce5:	e8 4e 0e 00 00       	call   80105b38 <release>

  if (first) {
80104cea:	a1 08 c0 10 80       	mov    0x8010c008,%eax
80104cef:	85 c0                	test   %eax,%eax
80104cf1:	74 0f                	je     80104d02 <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80104cf3:	c7 05 08 c0 10 80 00 	movl   $0x0,0x8010c008
80104cfa:	00 00 00 
    initlog();
80104cfd:	e8 d3 e6 ff ff       	call   801033d5 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80104d02:	c9                   	leave  
80104d03:	c3                   	ret    

80104d04 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80104d04:	55                   	push   %ebp
80104d05:	89 e5                	mov    %esp,%ebp
80104d07:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80104d0a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d10:	85 c0                	test   %eax,%eax
80104d12:	75 0c                	jne    80104d20 <sleep+0x1c>
    panic("sleep");
80104d14:	c7 04 24 75 95 10 80 	movl   $0x80109575,(%esp)
80104d1b:	e8 1a b8 ff ff       	call   8010053a <panic>

  if(lk == 0)
80104d20:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104d24:	75 0c                	jne    80104d32 <sleep+0x2e>
    panic("sleep without lk");
80104d26:	c7 04 24 7b 95 10 80 	movl   $0x8010957b,(%esp)
80104d2d:	e8 08 b8 ff ff       	call   8010053a <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80104d32:	81 7d 0c c0 39 11 80 	cmpl   $0x801139c0,0xc(%ebp)
80104d39:	74 17                	je     80104d52 <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
80104d3b:	c7 04 24 c0 39 11 80 	movl   $0x801139c0,(%esp)
80104d42:	e8 8f 0d 00 00       	call   80105ad6 <acquire>
    release(lk);
80104d47:	8b 45 0c             	mov    0xc(%ebp),%eax
80104d4a:	89 04 24             	mov    %eax,(%esp)
80104d4d:	e8 e6 0d 00 00       	call   80105b38 <release>
  }

  // Go to sleep.
  proc->chan = chan;
80104d52:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d58:	8b 55 08             	mov    0x8(%ebp),%edx
80104d5b:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
80104d5e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d64:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
80104d6b:	e8 84 fe ff ff       	call   80104bf4 <sched>

  // Tidy up.
  proc->chan = 0;
80104d70:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d76:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
80104d7d:	81 7d 0c c0 39 11 80 	cmpl   $0x801139c0,0xc(%ebp)
80104d84:	74 17                	je     80104d9d <sleep+0x99>
    release(&ptable.lock);
80104d86:	c7 04 24 c0 39 11 80 	movl   $0x801139c0,(%esp)
80104d8d:	e8 a6 0d 00 00       	call   80105b38 <release>
    acquire(lk);
80104d92:	8b 45 0c             	mov    0xc(%ebp),%eax
80104d95:	89 04 24             	mov    %eax,(%esp)
80104d98:	e8 39 0d 00 00       	call   80105ad6 <acquire>
  }
}
80104d9d:	c9                   	leave  
80104d9e:	c3                   	ret    

80104d9f <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80104d9f:	55                   	push   %ebp
80104da0:	89 e5                	mov    %esp,%ebp
80104da2:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104da5:	c7 45 fc f4 39 11 80 	movl   $0x801139f4,-0x4(%ebp)
80104dac:	eb 27                	jmp    80104dd5 <wakeup1+0x36>
    if(p->state == SLEEPING && p->chan == chan)
80104dae:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104db1:	8b 40 0c             	mov    0xc(%eax),%eax
80104db4:	83 f8 02             	cmp    $0x2,%eax
80104db7:	75 15                	jne    80104dce <wakeup1+0x2f>
80104db9:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104dbc:	8b 40 20             	mov    0x20(%eax),%eax
80104dbf:	3b 45 08             	cmp    0x8(%ebp),%eax
80104dc2:	75 0a                	jne    80104dce <wakeup1+0x2f>
      p->state = RUNNABLE;
80104dc4:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104dc7:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104dce:	81 45 fc e4 00 00 00 	addl   $0xe4,-0x4(%ebp)
80104dd5:	81 7d fc f4 72 11 80 	cmpl   $0x801172f4,-0x4(%ebp)
80104ddc:	72 d0                	jb     80104dae <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
80104dde:	c9                   	leave  
80104ddf:	c3                   	ret    

80104de0 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80104de0:	55                   	push   %ebp
80104de1:	89 e5                	mov    %esp,%ebp
80104de3:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80104de6:	c7 04 24 c0 39 11 80 	movl   $0x801139c0,(%esp)
80104ded:	e8 e4 0c 00 00       	call   80105ad6 <acquire>
  wakeup1(chan);
80104df2:	8b 45 08             	mov    0x8(%ebp),%eax
80104df5:	89 04 24             	mov    %eax,(%esp)
80104df8:	e8 a2 ff ff ff       	call   80104d9f <wakeup1>
  release(&ptable.lock);
80104dfd:	c7 04 24 c0 39 11 80 	movl   $0x801139c0,(%esp)
80104e04:	e8 2f 0d 00 00       	call   80105b38 <release>
}
80104e09:	c9                   	leave  
80104e0a:	c3                   	ret    

80104e0b <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80104e0b:	55                   	push   %ebp
80104e0c:	89 e5                	mov    %esp,%ebp
80104e0e:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80104e11:	c7 04 24 c0 39 11 80 	movl   $0x801139c0,(%esp)
80104e18:	e8 b9 0c 00 00       	call   80105ad6 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104e1d:	c7 45 f4 f4 39 11 80 	movl   $0x801139f4,-0xc(%ebp)
80104e24:	eb 44                	jmp    80104e6a <kill+0x5f>
    if(p->pid == pid){
80104e26:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e29:	8b 40 10             	mov    0x10(%eax),%eax
80104e2c:	3b 45 08             	cmp    0x8(%ebp),%eax
80104e2f:	75 32                	jne    80104e63 <kill+0x58>
      p->killed = 1;
80104e31:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e34:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80104e3b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e3e:	8b 40 0c             	mov    0xc(%eax),%eax
80104e41:	83 f8 02             	cmp    $0x2,%eax
80104e44:	75 0a                	jne    80104e50 <kill+0x45>
        p->state = RUNNABLE;
80104e46:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e49:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80104e50:	c7 04 24 c0 39 11 80 	movl   $0x801139c0,(%esp)
80104e57:	e8 dc 0c 00 00       	call   80105b38 <release>
      return 0;
80104e5c:	b8 00 00 00 00       	mov    $0x0,%eax
80104e61:	eb 21                	jmp    80104e84 <kill+0x79>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104e63:	81 45 f4 e4 00 00 00 	addl   $0xe4,-0xc(%ebp)
80104e6a:	81 7d f4 f4 72 11 80 	cmpl   $0x801172f4,-0xc(%ebp)
80104e71:	72 b3                	jb     80104e26 <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80104e73:	c7 04 24 c0 39 11 80 	movl   $0x801139c0,(%esp)
80104e7a:	e8 b9 0c 00 00       	call   80105b38 <release>
  return -1;
80104e7f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104e84:	c9                   	leave  
80104e85:	c3                   	ret    

80104e86 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80104e86:	55                   	push   %ebp
80104e87:	89 e5                	mov    %esp,%ebp
80104e89:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104e8c:	c7 45 f0 f4 39 11 80 	movl   $0x801139f4,-0x10(%ebp)
80104e93:	e9 d9 00 00 00       	jmp    80104f71 <procdump+0xeb>
    if(p->state == UNUSED)
80104e98:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104e9b:	8b 40 0c             	mov    0xc(%eax),%eax
80104e9e:	85 c0                	test   %eax,%eax
80104ea0:	75 05                	jne    80104ea7 <procdump+0x21>
      continue;
80104ea2:	e9 c3 00 00 00       	jmp    80104f6a <procdump+0xe4>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80104ea7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104eaa:	8b 40 0c             	mov    0xc(%eax),%eax
80104ead:	83 f8 05             	cmp    $0x5,%eax
80104eb0:	77 23                	ja     80104ed5 <procdump+0x4f>
80104eb2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104eb5:	8b 40 0c             	mov    0xc(%eax),%eax
80104eb8:	8b 04 85 0c c0 10 80 	mov    -0x7fef3ff4(,%eax,4),%eax
80104ebf:	85 c0                	test   %eax,%eax
80104ec1:	74 12                	je     80104ed5 <procdump+0x4f>
      state = states[p->state];
80104ec3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ec6:	8b 40 0c             	mov    0xc(%eax),%eax
80104ec9:	8b 04 85 0c c0 10 80 	mov    -0x7fef3ff4(,%eax,4),%eax
80104ed0:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104ed3:	eb 07                	jmp    80104edc <procdump+0x56>
    else
      state = "???";
80104ed5:	c7 45 ec 8c 95 10 80 	movl   $0x8010958c,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80104edc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104edf:	8d 50 6c             	lea    0x6c(%eax),%edx
80104ee2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ee5:	8b 40 10             	mov    0x10(%eax),%eax
80104ee8:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104eec:	8b 55 ec             	mov    -0x14(%ebp),%edx
80104eef:	89 54 24 08          	mov    %edx,0x8(%esp)
80104ef3:	89 44 24 04          	mov    %eax,0x4(%esp)
80104ef7:	c7 04 24 90 95 10 80 	movl   $0x80109590,(%esp)
80104efe:	e8 9d b4 ff ff       	call   801003a0 <cprintf>
    if(p->state == SLEEPING){
80104f03:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104f06:	8b 40 0c             	mov    0xc(%eax),%eax
80104f09:	83 f8 02             	cmp    $0x2,%eax
80104f0c:	75 50                	jne    80104f5e <procdump+0xd8>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80104f0e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104f11:	8b 40 1c             	mov    0x1c(%eax),%eax
80104f14:	8b 40 0c             	mov    0xc(%eax),%eax
80104f17:	83 c0 08             	add    $0x8,%eax
80104f1a:	8d 55 c4             	lea    -0x3c(%ebp),%edx
80104f1d:	89 54 24 04          	mov    %edx,0x4(%esp)
80104f21:	89 04 24             	mov    %eax,(%esp)
80104f24:	e8 5e 0c 00 00       	call   80105b87 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80104f29:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104f30:	eb 1b                	jmp    80104f4d <procdump+0xc7>
        cprintf(" %p", pc[i]);
80104f32:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f35:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104f39:	89 44 24 04          	mov    %eax,0x4(%esp)
80104f3d:	c7 04 24 99 95 10 80 	movl   $0x80109599,(%esp)
80104f44:	e8 57 b4 ff ff       	call   801003a0 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
80104f49:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104f4d:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80104f51:	7f 0b                	jg     80104f5e <procdump+0xd8>
80104f53:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f56:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104f5a:	85 c0                	test   %eax,%eax
80104f5c:	75 d4                	jne    80104f32 <procdump+0xac>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80104f5e:	c7 04 24 9d 95 10 80 	movl   $0x8010959d,(%esp)
80104f65:	e8 36 b4 ff ff       	call   801003a0 <cprintf>
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104f6a:	81 45 f0 e4 00 00 00 	addl   $0xe4,-0x10(%ebp)
80104f71:	81 7d f0 f4 72 11 80 	cmpl   $0x801172f4,-0x10(%ebp)
80104f78:	0f 82 1a ff ff ff    	jb     80104e98 <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
80104f7e:	c9                   	leave  
80104f7f:	c3                   	ret    

80104f80 <procfsisdir>:

char * fd_enums[3] = {"FD_NONE", "FD_PIPE", "FD_INODE"};
char * proc_run_state[6] = { "UNUSED", "EMBRYO", "SLEEPING", "RUNNABLE", "RUNNING", "ZOMBIE" };
  
int 
procfsisdir(struct inode *ip) {
80104f80:	55                   	push   %ebp
80104f81:	89 e5                	mov    %esp,%ebp
  return ip->type == T_DEV && ip->major == PROCFS;
80104f83:	8b 45 08             	mov    0x8(%ebp),%eax
80104f86:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80104f8a:	66 83 f8 03          	cmp    $0x3,%ax
80104f8e:	75 14                	jne    80104fa4 <procfsisdir+0x24>
80104f90:	8b 45 08             	mov    0x8(%ebp),%eax
80104f93:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80104f97:	66 83 f8 02          	cmp    $0x2,%ax
80104f9b:	75 07                	jne    80104fa4 <procfsisdir+0x24>
80104f9d:	b8 01 00 00 00       	mov    $0x1,%eax
80104fa2:	eb 05                	jmp    80104fa9 <procfsisdir+0x29>
80104fa4:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104fa9:	5d                   	pop    %ebp
80104faa:	c3                   	ret    

80104fab <procfsiread>:

void 
procfsiread(struct inode* dp, struct inode *ip) {
80104fab:	55                   	push   %ebp
80104fac:	89 e5                	mov    %esp,%ebp
  ip->flags |= I_VALID;
80104fae:	8b 45 0c             	mov    0xc(%ebp),%eax
80104fb1:	8b 40 0c             	mov    0xc(%eax),%eax
80104fb4:	83 c8 02             	or     $0x2,%eax
80104fb7:	89 c2                	mov    %eax,%edx
80104fb9:	8b 45 0c             	mov    0xc(%ebp),%eax
80104fbc:	89 50 0c             	mov    %edx,0xc(%eax)
  ip->type = T_DEV;
80104fbf:	8b 45 0c             	mov    0xc(%ebp),%eax
80104fc2:	66 c7 40 10 03 00    	movw   $0x3,0x10(%eax)
  ip->ref++;
80104fc8:	8b 45 0c             	mov    0xc(%ebp),%eax
80104fcb:	8b 40 08             	mov    0x8(%eax),%eax
80104fce:	8d 50 01             	lea    0x1(%eax),%edx
80104fd1:	8b 45 0c             	mov    0xc(%ebp),%eax
80104fd4:	89 50 08             	mov    %edx,0x8(%eax)
  ip->size = 0;
80104fd7:	8b 45 0c             	mov    0xc(%ebp),%eax
80104fda:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  ip->major = PROCFS;
80104fe1:	8b 45 0c             	mov    0xc(%ebp),%eax
80104fe4:	66 c7 40 12 02 00    	movw   $0x2,0x12(%eax)
  if (ip->inum > dp->inum) {
80104fea:	8b 45 0c             	mov    0xc(%ebp),%eax
80104fed:	8b 50 04             	mov    0x4(%eax),%edx
80104ff0:	8b 45 08             	mov    0x8(%ebp),%eax
80104ff3:	8b 40 04             	mov    0x4(%eax),%eax
80104ff6:	39 c2                	cmp    %eax,%edx
80104ff8:	76 15                	jbe    8010500f <procfsiread+0x64>
    ip->minor = dp->minor + 1;
80104ffa:	8b 45 08             	mov    0x8(%ebp),%eax
80104ffd:	0f b7 40 14          	movzwl 0x14(%eax),%eax
80105001:	83 c0 01             	add    $0x1,%eax
80105004:	89 c2                	mov    %eax,%edx
80105006:	8b 45 0c             	mov    0xc(%ebp),%eax
80105009:	66 89 50 14          	mov    %dx,0x14(%eax)
8010500d:	eb 33                	jmp    80105042 <procfsiread+0x97>
  }
  else if (ip->inum < dp->inum) {
8010500f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105012:	8b 50 04             	mov    0x4(%eax),%edx
80105015:	8b 45 08             	mov    0x8(%ebp),%eax
80105018:	8b 40 04             	mov    0x4(%eax),%eax
8010501b:	39 c2                	cmp    %eax,%edx
8010501d:	73 15                	jae    80105034 <procfsiread+0x89>
    ip->minor = dp->minor - 1;
8010501f:	8b 45 08             	mov    0x8(%ebp),%eax
80105022:	0f b7 40 14          	movzwl 0x14(%eax),%eax
80105026:	83 e8 01             	sub    $0x1,%eax
80105029:	89 c2                	mov    %eax,%edx
8010502b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010502e:	66 89 50 14          	mov    %dx,0x14(%eax)
80105032:	eb 0e                	jmp    80105042 <procfsiread+0x97>
  }
  else {
    ip->minor = dp->minor;
80105034:	8b 45 08             	mov    0x8(%ebp),%eax
80105037:	0f b7 50 14          	movzwl 0x14(%eax),%edx
8010503b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010503e:	66 89 50 14          	mov    %dx,0x14(%eax)
  }
  
}
80105042:	5d                   	pop    %ebp
80105043:	c3                   	ret    

80105044 <procfsread>:

int
procfsread(struct inode *ip, char *dst, int off, int n) {
80105044:	55                   	push   %ebp
80105045:	89 e5                	mov    %esp,%ebp
80105047:	81 ec 28 02 00 00    	sub    $0x228,%esp
  char buf[BSIZE];
  int size = 0;
8010504d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  
  if (ip->minor == 0) { // minor == 0 determines that we want to read from fld /PROC
80105054:	8b 45 08             	mov    0x8(%ebp),%eax
80105057:	0f b7 40 14          	movzwl 0x14(%eax),%eax
8010505b:	66 85 c0             	test   %ax,%ax
8010505e:	75 1d                	jne    8010507d <procfsread+0x39>
    size = mockPROCfld(ip, buf);
80105060:	8d 85 ec fd ff ff    	lea    -0x214(%ebp),%eax
80105066:	89 44 24 04          	mov    %eax,0x4(%esp)
8010506a:	8b 45 08             	mov    0x8(%ebp),%eax
8010506d:	89 04 24             	mov    %eax,(%esp)
80105070:	e8 7a 01 00 00       	call   801051ef <mockPROCfld>
80105075:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105078:	e9 e4 00 00 00       	jmp    80105161 <procfsread+0x11d>
  }
  else if (ip->minor == 1) { // minor == 1 determines that we want to read from fld /PROC/<PID>
8010507d:	8b 45 08             	mov    0x8(%ebp),%eax
80105080:	0f b7 40 14          	movzwl 0x14(%eax),%eax
80105084:	66 83 f8 01          	cmp    $0x1,%ax
80105088:	75 1d                	jne    801050a7 <procfsread+0x63>
    size = mockPIDfld(ip, buf);
8010508a:	8d 85 ec fd ff ff    	lea    -0x214(%ebp),%eax
80105090:	89 44 24 04          	mov    %eax,0x4(%esp)
80105094:	8b 45 08             	mov    0x8(%ebp),%eax
80105097:	89 04 24             	mov    %eax,(%esp)
8010509a:	e8 1d 02 00 00       	call   801052bc <mockPIDfld>
8010509f:	89 45 f4             	mov    %eax,-0xc(%ebp)
801050a2:	e9 ba 00 00 00       	jmp    80105161 <procfsread+0x11d>
  }
  else if (ip->minor == 2) { // minor == 2 determines that we want to read from file /PROC/<PID>/<file>
801050a7:	8b 45 08             	mov    0x8(%ebp),%eax
801050aa:	0f b7 40 14          	movzwl 0x14(%eax),%eax
801050ae:	66 83 f8 02          	cmp    $0x2,%ax
801050b2:	0f 85 84 00 00 00    	jne    8010513c <procfsread+0xf8>
    int file = (ip->inum/1000)*1000;
801050b8:	8b 45 08             	mov    0x8(%ebp),%eax
801050bb:	8b 40 04             	mov    0x4(%eax),%eax
801050be:	ba d3 4d 62 10       	mov    $0x10624dd3,%edx
801050c3:	f7 e2                	mul    %edx
801050c5:	89 d0                	mov    %edx,%eax
801050c7:	c1 e8 06             	shr    $0x6,%eax
801050ca:	69 c0 e8 03 00 00    	imul   $0x3e8,%eax,%eax
801050d0:	89 45 f0             	mov    %eax,-0x10(%ebp)
    switch (file) {
801050d3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801050d6:	3d a0 0f 00 00       	cmp    $0xfa0,%eax
801050db:	74 2a                	je     80105107 <procfsread+0xc3>
801050dd:	3d 70 17 00 00       	cmp    $0x1770,%eax
801050e2:	74 3d                	je     80105121 <procfsread+0xdd>
801050e4:	3d d0 07 00 00       	cmp    $0x7d0,%eax
801050e9:	74 02                	je     801050ed <procfsread+0xa9>
801050eb:	eb 74                	jmp    80105161 <procfsread+0x11d>
      case CMD_LINE:
	size = mockCmdLine(ip, buf);
801050ed:	8d 85 ec fd ff ff    	lea    -0x214(%ebp),%eax
801050f3:	89 44 24 04          	mov    %eax,0x4(%esp)
801050f7:	8b 45 08             	mov    0x8(%ebp),%eax
801050fa:	89 04 24             	mov    %eax,(%esp)
801050fd:	e8 0b 03 00 00       	call   8010540d <mockCmdLine>
80105102:	89 45 f4             	mov    %eax,-0xc(%ebp)
	break;
80105105:	eb 33                	jmp    8010513a <procfsread+0xf6>
      case FD_INFO:
	size = mockFdInfo(ip, buf);
80105107:	8d 85 ec fd ff ff    	lea    -0x214(%ebp),%eax
8010510d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105111:	8b 45 08             	mov    0x8(%ebp),%eax
80105114:	89 04 24             	mov    %eax,(%esp)
80105117:	e8 c3 04 00 00       	call   801055df <mockFdInfo>
8010511c:	89 45 f4             	mov    %eax,-0xc(%ebp)
	break;
8010511f:	eb 19                	jmp    8010513a <procfsread+0xf6>
      case STATUS:
	size = mockStatusInfo(ip, buf);
80105121:	8d 85 ec fd ff ff    	lea    -0x214(%ebp),%eax
80105127:	89 44 24 04          	mov    %eax,0x4(%esp)
8010512b:	8b 45 08             	mov    0x8(%ebp),%eax
8010512e:	89 04 24             	mov    %eax,(%esp)
80105131:	e8 2e 03 00 00       	call   80105464 <mockStatusInfo>
80105136:	89 45 f4             	mov    %eax,-0xc(%ebp)
	break;
80105139:	90                   	nop
8010513a:	eb 25                	jmp    80105161 <procfsread+0x11d>
    }
  }
  else if (ip->minor >= 3) {  
8010513c:	8b 45 08             	mov    0x8(%ebp),%eax
8010513f:	0f b7 40 14          	movzwl 0x14(%eax),%eax
80105143:	66 83 f8 02          	cmp    $0x2,%ax
80105147:	7e 18                	jle    80105161 <procfsread+0x11d>
    //cprintf("HEELO!\n");
    size = mockFdStatus(ip, buf);
80105149:	8d 85 ec fd ff ff    	lea    -0x214(%ebp),%eax
8010514f:	89 44 24 04          	mov    %eax,0x4(%esp)
80105153:	8b 45 08             	mov    0x8(%ebp),%eax
80105156:	89 04 24             	mov    %eax,(%esp)
80105159:	e8 85 05 00 00       	call   801056e3 <mockFdStatus>
8010515e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  }
  
  if (off < size) {
80105161:	8b 45 10             	mov    0x10(%ebp),%eax
80105164:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80105167:	7d 40                	jge    801051a9 <procfsread+0x165>
      int remain = size - off;
80105169:	8b 45 10             	mov    0x10(%ebp),%eax
8010516c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010516f:	29 c2                	sub    %eax,%edx
80105171:	89 d0                	mov    %edx,%eax
80105173:	89 45 ec             	mov    %eax,-0x14(%ebp)
      remain = remain < n ? remain : n;
80105176:	8b 45 ec             	mov    -0x14(%ebp),%eax
80105179:	39 45 14             	cmp    %eax,0x14(%ebp)
8010517c:	0f 4e 45 14          	cmovle 0x14(%ebp),%eax
80105180:	89 45 ec             	mov    %eax,-0x14(%ebp)
      memmove(dst, buf + off, remain);
80105183:	8b 45 ec             	mov    -0x14(%ebp),%eax
80105186:	8b 55 10             	mov    0x10(%ebp),%edx
80105189:	8d 8d ec fd ff ff    	lea    -0x214(%ebp),%ecx
8010518f:	01 ca                	add    %ecx,%edx
80105191:	89 44 24 08          	mov    %eax,0x8(%esp)
80105195:	89 54 24 04          	mov    %edx,0x4(%esp)
80105199:	8b 45 0c             	mov    0xc(%ebp),%eax
8010519c:	89 04 24             	mov    %eax,(%esp)
8010519f:	e8 55 0c 00 00       	call   80105df9 <memmove>
      //cprintf("dst is: %s\n", dst);
      return remain;
801051a4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801051a7:	eb 05                	jmp    801051ae <procfsread+0x16a>
  }
  //cprintf("buf is: %s BAD\n", buf);
  return 0;
801051a9:	b8 00 00 00 00       	mov    $0x0,%eax
}
801051ae:	c9                   	leave  
801051af:	c3                   	ret    

801051b0 <procfswrite>:

int
procfswrite(struct inode *ip, char *buf, int n)
{
801051b0:	55                   	push   %ebp
801051b1:	89 e5                	mov    %esp,%ebp
801051b3:	83 ec 18             	sub    $0x18,%esp
  panic("You shall not write");
801051b6:	c7 04 24 11 96 10 80 	movl   $0x80109611,(%esp)
801051bd:	e8 78 b3 ff ff       	call   8010053a <panic>

801051c2 <procfsinit>:
  return 0;
}

void
procfsinit(void)
{
801051c2:	55                   	push   %ebp
801051c3:	89 e5                	mov    %esp,%ebp
  devsw[PROCFS].isdir = procfsisdir;
801051c5:	c7 05 20 22 11 80 80 	movl   $0x80104f80,0x80112220
801051cc:	4f 10 80 
  devsw[PROCFS].iread = procfsiread;
801051cf:	c7 05 24 22 11 80 ab 	movl   $0x80104fab,0x80112224
801051d6:	4f 10 80 
  devsw[PROCFS].write = procfswrite;
801051d9:	c7 05 2c 22 11 80 b0 	movl   $0x801051b0,0x8011222c
801051e0:	51 10 80 
  devsw[PROCFS].read = procfsread;
801051e3:	c7 05 28 22 11 80 44 	movl   $0x80105044,0x80112228
801051ea:	50 10 80 
}
801051ed:	5d                   	pop    %ebp
801051ee:	c3                   	ret    

801051ef <mockPROCfld>:
/**
 * mocks the /PROC folder - Creates the file entries and push them to the buffer.
 * returns the size of the buffer
 */
int
mockPROCfld(struct inode *ip, char *buf) {
801051ef:	55                   	push   %ebp
801051f0:	89 e5                	mov    %esp,%ebp
801051f2:	81 ec 28 02 00 00    	sub    $0x228,%esp
    int count = 0;
801051f8:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
    pushDirentToBuf(".", ip->inum, buf, &count);
801051ff:	8b 45 08             	mov    0x8(%ebp),%eax
80105202:	8b 40 04             	mov    0x4(%eax),%eax
80105205:	8d 55 ec             	lea    -0x14(%ebp),%edx
80105208:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010520c:	8b 55 0c             	mov    0xc(%ebp),%edx
8010520f:	89 54 24 08          	mov    %edx,0x8(%esp)
80105213:	89 44 24 04          	mov    %eax,0x4(%esp)
80105217:	c7 04 24 25 96 10 80 	movl   $0x80109625,(%esp)
8010521e:	e8 f3 07 00 00       	call   80105a16 <pushDirentToBuf>
    pushDirentToBuf("..", ROOTINO, buf, &count);
80105223:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105226:	89 44 24 0c          	mov    %eax,0xc(%esp)
8010522a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010522d:	89 44 24 08          	mov    %eax,0x8(%esp)
80105231:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105238:	00 
80105239:	c7 04 24 27 96 10 80 	movl   $0x80109627,(%esp)
80105240:	e8 d1 07 00 00       	call   80105a16 <pushDirentToBuf>
    
    struct proc* p;
    int i = 0;  
80105245:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    char sPid[BSIZE];
    
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010524c:	c7 45 f4 f4 39 11 80 	movl   $0x801139f4,-0xc(%ebp)
80105253:	eb 56                	jmp    801052ab <mockPROCfld+0xbc>
      if(p->state != UNUSED)
80105255:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105258:	8b 40 0c             	mov    0xc(%eax),%eax
8010525b:	85 c0                	test   %eax,%eax
8010525d:	74 41                	je     801052a0 <mockPROCfld+0xb1>
      {	
	itoa(p->pid,sPid);
8010525f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105262:	8b 40 10             	mov    0x10(%eax),%eax
80105265:	8d 95 ec fd ff ff    	lea    -0x214(%ebp),%edx
8010526b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010526f:	89 04 24             	mov    %eax,(%esp)
80105272:	e8 a7 0d 00 00       	call   8010601e <itoa>
	pushDirentToBuf(sPid, NINODES + i, buf, &count);
80105277:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010527a:	8d 90 c8 00 00 00    	lea    0xc8(%eax),%edx
80105280:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105283:	89 44 24 0c          	mov    %eax,0xc(%esp)
80105287:	8b 45 0c             	mov    0xc(%ebp),%eax
8010528a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010528e:	89 54 24 04          	mov    %edx,0x4(%esp)
80105292:	8d 85 ec fd ff ff    	lea    -0x214(%ebp),%eax
80105298:	89 04 24             	mov    %eax,(%esp)
8010529b:	e8 76 07 00 00       	call   80105a16 <pushDirentToBuf>
      }
      i++;
801052a0:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
    
    struct proc* p;
    int i = 0;  
    char sPid[BSIZE];
    
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801052a4:	81 45 f4 e4 00 00 00 	addl   $0xe4,-0xc(%ebp)
801052ab:	81 7d f4 f4 72 11 80 	cmpl   $0x801172f4,-0xc(%ebp)
801052b2:	72 a1                	jb     80105255 <mockPROCfld+0x66>
	itoa(p->pid,sPid);
	pushDirentToBuf(sPid, NINODES + i, buf, &count);
      }
      i++;
    }
    return count * sizeof(struct dirent);
801052b4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801052b7:	c1 e0 04             	shl    $0x4,%eax
}
801052ba:	c9                   	leave  
801052bb:	c3                   	ret    

801052bc <mockPIDfld>:

int
mockPIDfld(struct inode *ip, char * buf) {
801052bc:	55                   	push   %ebp
801052bd:	89 e5                	mov    %esp,%ebp
801052bf:	83 ec 28             	sub    $0x28,%esp
    struct proc * p = &ptable.proc[ip->inum - NINODES];
801052c2:	8b 45 08             	mov    0x8(%ebp),%eax
801052c5:	8b 40 04             	mov    0x4(%eax),%eax
801052c8:	2d c8 00 00 00       	sub    $0xc8,%eax
801052cd:	69 c0 e4 00 00 00    	imul   $0xe4,%eax,%eax
801052d3:	83 c0 30             	add    $0x30,%eax
801052d6:	05 c0 39 11 80       	add    $0x801139c0,%eax
801052db:	83 c0 04             	add    $0x4,%eax
801052de:	89 45 f4             	mov    %eax,-0xc(%ebp)
    int count = 0;
801052e1:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    pushDirentToBuf(".", ip->inum, buf, &count);
801052e8:	8b 45 08             	mov    0x8(%ebp),%eax
801052eb:	8b 40 04             	mov    0x4(%eax),%eax
801052ee:	8d 55 f0             	lea    -0x10(%ebp),%edx
801052f1:	89 54 24 0c          	mov    %edx,0xc(%esp)
801052f5:	8b 55 0c             	mov    0xc(%ebp),%edx
801052f8:	89 54 24 08          	mov    %edx,0x8(%esp)
801052fc:	89 44 24 04          	mov    %eax,0x4(%esp)
80105300:	c7 04 24 25 96 10 80 	movl   $0x80109625,(%esp)
80105307:	e8 0a 07 00 00       	call   80105a16 <pushDirentToBuf>
    pushDirentToBuf("..", ROOTINO, buf, &count);
8010530c:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010530f:	89 44 24 0c          	mov    %eax,0xc(%esp)
80105313:	8b 45 0c             	mov    0xc(%ebp),%eax
80105316:	89 44 24 08          	mov    %eax,0x8(%esp)
8010531a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105321:	00 
80105322:	c7 04 24 27 96 10 80 	movl   $0x80109627,(%esp)
80105329:	e8 e8 06 00 00       	call   80105a16 <pushDirentToBuf>
    
    if (p->state != UNUSED) {    
8010532e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105331:	8b 40 0c             	mov    0xc(%eax),%eax
80105334:	85 c0                	test   %eax,%eax
80105336:	0f 84 c9 00 00 00    	je     80105405 <mockPIDfld+0x149>
      pushDirentToBuf("cmdline", ip->inum + CMD_LINE, buf, &count);
8010533c:	8b 45 08             	mov    0x8(%ebp),%eax
8010533f:	8b 40 04             	mov    0x4(%eax),%eax
80105342:	05 d0 07 00 00       	add    $0x7d0,%eax
80105347:	8d 55 f0             	lea    -0x10(%ebp),%edx
8010534a:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010534e:	8b 55 0c             	mov    0xc(%ebp),%edx
80105351:	89 54 24 08          	mov    %edx,0x8(%esp)
80105355:	89 44 24 04          	mov    %eax,0x4(%esp)
80105359:	c7 04 24 2a 96 10 80 	movl   $0x8010962a,(%esp)
80105360:	e8 b1 06 00 00       	call   80105a16 <pushDirentToBuf>
      pushDirentToBuf("cwd", p->cwd->inum, buf, &count);
80105365:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105368:	8b 40 68             	mov    0x68(%eax),%eax
8010536b:	8b 40 04             	mov    0x4(%eax),%eax
8010536e:	8d 55 f0             	lea    -0x10(%ebp),%edx
80105371:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105375:	8b 55 0c             	mov    0xc(%ebp),%edx
80105378:	89 54 24 08          	mov    %edx,0x8(%esp)
8010537c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105380:	c7 04 24 32 96 10 80 	movl   $0x80109632,(%esp)
80105387:	e8 8a 06 00 00       	call   80105a16 <pushDirentToBuf>
      pushDirentToBuf("exe", p->exe->inum, buf, &count);
8010538c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010538f:	8b 40 7c             	mov    0x7c(%eax),%eax
80105392:	8b 40 04             	mov    0x4(%eax),%eax
80105395:	8d 55 f0             	lea    -0x10(%ebp),%edx
80105398:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010539c:	8b 55 0c             	mov    0xc(%ebp),%edx
8010539f:	89 54 24 08          	mov    %edx,0x8(%esp)
801053a3:	89 44 24 04          	mov    %eax,0x4(%esp)
801053a7:	c7 04 24 36 96 10 80 	movl   $0x80109636,(%esp)
801053ae:	e8 63 06 00 00       	call   80105a16 <pushDirentToBuf>
      pushDirentToBuf("fdinfo", ip->inum + FD_INFO, buf, &count);   
801053b3:	8b 45 08             	mov    0x8(%ebp),%eax
801053b6:	8b 40 04             	mov    0x4(%eax),%eax
801053b9:	05 a0 0f 00 00       	add    $0xfa0,%eax
801053be:	8d 55 f0             	lea    -0x10(%ebp),%edx
801053c1:	89 54 24 0c          	mov    %edx,0xc(%esp)
801053c5:	8b 55 0c             	mov    0xc(%ebp),%edx
801053c8:	89 54 24 08          	mov    %edx,0x8(%esp)
801053cc:	89 44 24 04          	mov    %eax,0x4(%esp)
801053d0:	c7 04 24 3a 96 10 80 	movl   $0x8010963a,(%esp)
801053d7:	e8 3a 06 00 00       	call   80105a16 <pushDirentToBuf>
      pushDirentToBuf("status", ip->inum + STATUS, buf, &count);    
801053dc:	8b 45 08             	mov    0x8(%ebp),%eax
801053df:	8b 40 04             	mov    0x4(%eax),%eax
801053e2:	05 70 17 00 00       	add    $0x1770,%eax
801053e7:	8d 55 f0             	lea    -0x10(%ebp),%edx
801053ea:	89 54 24 0c          	mov    %edx,0xc(%esp)
801053ee:	8b 55 0c             	mov    0xc(%ebp),%edx
801053f1:	89 54 24 08          	mov    %edx,0x8(%esp)
801053f5:	89 44 24 04          	mov    %eax,0x4(%esp)
801053f9:	c7 04 24 41 96 10 80 	movl   $0x80109641,(%esp)
80105400:	e8 11 06 00 00       	call   80105a16 <pushDirentToBuf>
    }
    
    return count*(sizeof(struct dirent)); 
80105405:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105408:	c1 e0 04             	shl    $0x4,%eax
}
8010540b:	c9                   	leave  
8010540c:	c3                   	ret    

8010540d <mockCmdLine>:

int
mockCmdLine(struct inode *ip, char * buf) {
8010540d:	55                   	push   %ebp
8010540e:	89 e5                	mov    %esp,%ebp
80105410:	83 ec 28             	sub    $0x28,%esp
    struct proc *p = &ptable.proc[(ip->inum - CMD_LINE) - NINODES];
80105413:	8b 45 08             	mov    0x8(%ebp),%eax
80105416:	8b 40 04             	mov    0x4(%eax),%eax
80105419:	2d 98 08 00 00       	sub    $0x898,%eax
8010541e:	69 c0 e4 00 00 00    	imul   $0xe4,%eax,%eax
80105424:	83 c0 30             	add    $0x30,%eax
80105427:	05 c0 39 11 80       	add    $0x801139c0,%eax
8010542c:	83 c0 04             	add    $0x4,%eax
8010542f:	89 45 f4             	mov    %eax,-0xc(%ebp)
    int sz = strlen(p->cmdline);
80105432:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105435:	83 e8 80             	sub    $0xffffff80,%eax
80105438:	89 04 24             	mov    %eax,(%esp)
8010543b:	e8 54 0b 00 00       	call   80105f94 <strlen>
80105440:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(buf, p->cmdline, sz);
80105443:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105446:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105449:	83 ea 80             	sub    $0xffffff80,%edx
8010544c:	89 44 24 08          	mov    %eax,0x8(%esp)
80105450:	89 54 24 04          	mov    %edx,0x4(%esp)
80105454:	8b 45 0c             	mov    0xc(%ebp),%eax
80105457:	89 04 24             	mov    %eax,(%esp)
8010545a:	e8 9a 09 00 00       	call   80105df9 <memmove>
    return sz;
8010545f:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80105462:	c9                   	leave  
80105463:	c3                   	ret    

80105464 <mockStatusInfo>:

int 
mockStatusInfo(struct inode *ip, char * buf) {
80105464:	55                   	push   %ebp
80105465:	89 e5                	mov    %esp,%ebp
80105467:	83 ec 38             	sub    $0x38,%esp
    struct proc *p = &ptable.proc[(ip->inum - STATUS) - NINODES];
8010546a:	8b 45 08             	mov    0x8(%ebp),%eax
8010546d:	8b 40 04             	mov    0x4(%eax),%eax
80105470:	2d 38 18 00 00       	sub    $0x1838,%eax
80105475:	69 c0 e4 00 00 00    	imul   $0xe4,%eax,%eax
8010547b:	83 c0 30             	add    $0x30,%eax
8010547e:	05 c0 39 11 80       	add    $0x801139c0,%eax
80105483:	83 c0 04             	add    $0x4,%eax
80105486:	89 45 f4             	mov    %eax,-0xc(%ebp)
    
    int sz = 0;
80105489:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    memmove(buf, "run state: ", strlen("run state: ") + 1);
80105490:	c7 04 24 48 96 10 80 	movl   $0x80109648,(%esp)
80105497:	e8 f8 0a 00 00       	call   80105f94 <strlen>
8010549c:	83 c0 01             	add    $0x1,%eax
8010549f:	89 44 24 08          	mov    %eax,0x8(%esp)
801054a3:	c7 44 24 04 48 96 10 	movl   $0x80109648,0x4(%esp)
801054aa:	80 
801054ab:	8b 45 0c             	mov    0xc(%ebp),%eax
801054ae:	89 04 24             	mov    %eax,(%esp)
801054b1:	e8 43 09 00 00       	call   80105df9 <memmove>
    sz += strlen("run state: ") + 1;
801054b6:	c7 04 24 48 96 10 80 	movl   $0x80109648,(%esp)
801054bd:	e8 d2 0a 00 00       	call   80105f94 <strlen>
801054c2:	83 c0 01             	add    $0x1,%eax
801054c5:	01 45 f0             	add    %eax,-0x10(%ebp)
    
    char * str = proc_run_state[p->state];  
801054c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054cb:	8b 40 0c             	mov    0xc(%eax),%eax
801054ce:	8b 04 85 30 c0 10 80 	mov    -0x7fef3fd0(,%eax,4),%eax
801054d5:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(buf + sz, str, strlen(str) + 1);
801054d8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801054db:	89 04 24             	mov    %eax,(%esp)
801054de:	e8 b1 0a 00 00       	call   80105f94 <strlen>
801054e3:	83 c0 01             	add    $0x1,%eax
801054e6:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801054e9:	8b 55 0c             	mov    0xc(%ebp),%edx
801054ec:	01 ca                	add    %ecx,%edx
801054ee:	89 44 24 08          	mov    %eax,0x8(%esp)
801054f2:	8b 45 ec             	mov    -0x14(%ebp),%eax
801054f5:	89 44 24 04          	mov    %eax,0x4(%esp)
801054f9:	89 14 24             	mov    %edx,(%esp)
801054fc:	e8 f8 08 00 00       	call   80105df9 <memmove>
    sz += strlen(str) + 1;
80105501:	8b 45 ec             	mov    -0x14(%ebp),%eax
80105504:	89 04 24             	mov    %eax,(%esp)
80105507:	e8 88 0a 00 00       	call   80105f94 <strlen>
8010550c:	83 c0 01             	add    $0x1,%eax
8010550f:	01 45 f0             	add    %eax,-0x10(%ebp)
    
    memmove(buf + sz, " memory usage: ", strlen(" memory usage: ") + 1);
80105512:	c7 04 24 54 96 10 80 	movl   $0x80109654,(%esp)
80105519:	e8 76 0a 00 00       	call   80105f94 <strlen>
8010551e:	83 c0 01             	add    $0x1,%eax
80105521:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105524:	8b 55 0c             	mov    0xc(%ebp),%edx
80105527:	01 ca                	add    %ecx,%edx
80105529:	89 44 24 08          	mov    %eax,0x8(%esp)
8010552d:	c7 44 24 04 54 96 10 	movl   $0x80109654,0x4(%esp)
80105534:	80 
80105535:	89 14 24             	mov    %edx,(%esp)
80105538:	e8 bc 08 00 00       	call   80105df9 <memmove>
    sz += strlen(" memory usage: ") + 1;
8010553d:	c7 04 24 54 96 10 80 	movl   $0x80109654,(%esp)
80105544:	e8 4b 0a 00 00       	call   80105f94 <strlen>
80105549:	83 c0 01             	add    $0x1,%eax
8010554c:	01 45 f0             	add    %eax,-0x10(%ebp)
    
    char proc_sz[6];
    itoa((int)p->sz, proc_sz);
8010554f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105552:	8b 00                	mov    (%eax),%eax
80105554:	8d 55 e6             	lea    -0x1a(%ebp),%edx
80105557:	89 54 24 04          	mov    %edx,0x4(%esp)
8010555b:	89 04 24             	mov    %eax,(%esp)
8010555e:	e8 bb 0a 00 00       	call   8010601e <itoa>
    memmove(buf + sz, proc_sz, strlen(proc_sz) + 1);
80105563:	8d 45 e6             	lea    -0x1a(%ebp),%eax
80105566:	89 04 24             	mov    %eax,(%esp)
80105569:	e8 26 0a 00 00       	call   80105f94 <strlen>
8010556e:	83 c0 01             	add    $0x1,%eax
80105571:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105574:	8b 55 0c             	mov    0xc(%ebp),%edx
80105577:	01 ca                	add    %ecx,%edx
80105579:	89 44 24 08          	mov    %eax,0x8(%esp)
8010557d:	8d 45 e6             	lea    -0x1a(%ebp),%eax
80105580:	89 44 24 04          	mov    %eax,0x4(%esp)
80105584:	89 14 24             	mov    %edx,(%esp)
80105587:	e8 6d 08 00 00       	call   80105df9 <memmove>
    sz += strlen(proc_sz) + 1;
8010558c:	8d 45 e6             	lea    -0x1a(%ebp),%eax
8010558f:	89 04 24             	mov    %eax,(%esp)
80105592:	e8 fd 09 00 00       	call   80105f94 <strlen>
80105597:	83 c0 01             	add    $0x1,%eax
8010559a:	01 45 f0             	add    %eax,-0x10(%ebp)
    
    memmove(buf + sz, "\n", strlen("\n") + 1);
8010559d:	c7 04 24 64 96 10 80 	movl   $0x80109664,(%esp)
801055a4:	e8 eb 09 00 00       	call   80105f94 <strlen>
801055a9:	83 c0 01             	add    $0x1,%eax
801055ac:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801055af:	8b 55 0c             	mov    0xc(%ebp),%edx
801055b2:	01 ca                	add    %ecx,%edx
801055b4:	89 44 24 08          	mov    %eax,0x8(%esp)
801055b8:	c7 44 24 04 64 96 10 	movl   $0x80109664,0x4(%esp)
801055bf:	80 
801055c0:	89 14 24             	mov    %edx,(%esp)
801055c3:	e8 31 08 00 00       	call   80105df9 <memmove>
    sz += strlen("\n") + 1;
801055c8:	c7 04 24 64 96 10 80 	movl   $0x80109664,(%esp)
801055cf:	e8 c0 09 00 00       	call   80105f94 <strlen>
801055d4:	83 c0 01             	add    $0x1,%eax
801055d7:	01 45 f0             	add    %eax,-0x10(%ebp)
    
    return sz;
801055da:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801055dd:	c9                   	leave  
801055de:	c3                   	ret    

801055df <mockFdInfo>:

int
mockFdInfo(struct inode *ip, char *buf) {
801055df:	55                   	push   %ebp
801055e0:	89 e5                	mov    %esp,%ebp
801055e2:	83 ec 38             	sub    $0x38,%esp
    int count = 0;
801055e5:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
    pushDirentToBuf(".", ip->inum, buf, &count);
801055ec:	8b 45 08             	mov    0x8(%ebp),%eax
801055ef:	8b 40 04             	mov    0x4(%eax),%eax
801055f2:	8d 55 e4             	lea    -0x1c(%ebp),%edx
801055f5:	89 54 24 0c          	mov    %edx,0xc(%esp)
801055f9:	8b 55 0c             	mov    0xc(%ebp),%edx
801055fc:	89 54 24 08          	mov    %edx,0x8(%esp)
80105600:	89 44 24 04          	mov    %eax,0x4(%esp)
80105604:	c7 04 24 25 96 10 80 	movl   $0x80109625,(%esp)
8010560b:	e8 06 04 00 00       	call   80105a16 <pushDirentToBuf>
    pushDirentToBuf("..", ROOTINO, buf, &count);
80105610:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105613:	89 44 24 0c          	mov    %eax,0xc(%esp)
80105617:	8b 45 0c             	mov    0xc(%ebp),%eax
8010561a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010561e:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105625:	00 
80105626:	c7 04 24 27 96 10 80 	movl   $0x80109627,(%esp)
8010562d:	e8 e4 03 00 00       	call   80105a16 <pushDirentToBuf>
    
    int procIndex = ip->inum - FD_INFO - NINODES;
80105632:	8b 45 08             	mov    0x8(%ebp),%eax
80105635:	8b 40 04             	mov    0x4(%eax),%eax
80105638:	2d 68 10 00 00       	sub    $0x1068,%eax
8010563d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    //cprintf("proc index is: %d\n", procIndex);
    struct proc *p = &ptable.proc[procIndex];
80105640:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105643:	69 c0 e4 00 00 00    	imul   $0xe4,%eax,%eax
80105649:	83 c0 30             	add    $0x30,%eax
8010564c:	05 c0 39 11 80       	add    $0x801139c0,%eax
80105651:	83 c0 04             	add    $0x4,%eax
80105654:	89 45 ec             	mov    %eax,-0x14(%ebp)
    int i = 0;  
80105657:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    char sFD[2];
    
    for (i = 0; i < NOFILE; i++){
8010565e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80105665:	eb 6e                	jmp    801056d5 <mockFdInfo+0xf6>
      //cprintf("fd is %d, file %d, for proc %d\n", i, p->ofile[i], p->pid);
      if(p->ofile[i] && p->ofile[i]->type != FD_NONE)
80105667:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010566a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010566d:	83 c2 08             	add    $0x8,%edx
80105670:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105674:	85 c0                	test   %eax,%eax
80105676:	74 59                	je     801056d1 <mockFdInfo+0xf2>
80105678:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010567b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010567e:	83 c2 08             	add    $0x8,%edx
80105681:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105685:	8b 00                	mov    (%eax),%eax
80105687:	85 c0                	test   %eax,%eax
80105689:	74 46                	je     801056d1 <mockFdInfo+0xf2>
      {		
	itoa(i, sFD);	
8010568b:	8d 45 e2             	lea    -0x1e(%ebp),%eax
8010568e:	89 44 24 04          	mov    %eax,0x4(%esp)
80105692:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105695:	89 04 24             	mov    %eax,(%esp)
80105698:	e8 81 09 00 00       	call   8010601e <itoa>
	int inum = FD_INFO + NINODES + NPROC + NOFILE * procIndex + i; // 4000 + 200 + 64 + 16*procIndex + i
8010569d:	8b 45 f0             	mov    -0x10(%ebp),%eax
801056a0:	c1 e0 04             	shl    $0x4,%eax
801056a3:	8d 90 a8 10 00 00    	lea    0x10a8(%eax),%edx
801056a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056ac:	01 d0                	add    %edx,%eax
801056ae:	89 45 e8             	mov    %eax,-0x18(%ebp)
	pushDirentToBuf(sFD, inum, buf, &count);
801056b1:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801056b4:	89 44 24 0c          	mov    %eax,0xc(%esp)
801056b8:	8b 45 0c             	mov    0xc(%ebp),%eax
801056bb:	89 44 24 08          	mov    %eax,0x8(%esp)
801056bf:	8b 45 e8             	mov    -0x18(%ebp),%eax
801056c2:	89 44 24 04          	mov    %eax,0x4(%esp)
801056c6:	8d 45 e2             	lea    -0x1e(%ebp),%eax
801056c9:	89 04 24             	mov    %eax,(%esp)
801056cc:	e8 45 03 00 00       	call   80105a16 <pushDirentToBuf>
    //cprintf("proc index is: %d\n", procIndex);
    struct proc *p = &ptable.proc[procIndex];
    int i = 0;  
    char sFD[2];
    
    for (i = 0; i < NOFILE; i++){
801056d1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801056d5:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
801056d9:	7e 8c                	jle    80105667 <mockFdInfo+0x88>
	itoa(i, sFD);	
	int inum = FD_INFO + NINODES + NPROC + NOFILE * procIndex + i; // 4000 + 200 + 64 + 16*procIndex + i
	pushDirentToBuf(sFD, inum, buf, &count);
      }
    }
    return count * sizeof(struct dirent);
801056db:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801056de:	c1 e0 04             	shl    $0x4,%eax
}
801056e1:	c9                   	leave  
801056e2:	c3                   	ret    

801056e3 <mockFdStatus>:


int
mockFdStatus(struct inode *ip, char * buf) {
801056e3:	55                   	push   %ebp
801056e4:	89 e5                	mov    %esp,%ebp
801056e6:	53                   	push   %ebx
801056e7:	81 ec 94 00 00 00    	sub    $0x94,%esp
  
    // NOFILE * procIndex + fdNum = inum - FD_INFO - NINODES - NPROC
    int procIndex = (ip->inum - FD_INFO - NINODES - NPROC) / NOFILE;
801056ed:	8b 45 08             	mov    0x8(%ebp),%eax
801056f0:	8b 40 04             	mov    0x4(%eax),%eax
801056f3:	2d a8 10 00 00       	sub    $0x10a8,%eax
801056f8:	c1 e8 04             	shr    $0x4,%eax
801056fb:	89 45 f4             	mov    %eax,-0xc(%ebp)
    int fdNum = (ip->inum - FD_INFO - NINODES - NPROC) % NOFILE;
801056fe:	8b 45 08             	mov    0x8(%ebp),%eax
80105701:	8b 40 04             	mov    0x4(%eax),%eax
80105704:	2d a8 10 00 00       	sub    $0x10a8,%eax
80105709:	83 e0 0f             	and    $0xf,%eax
8010570c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    
    struct proc *p = &ptable.proc[procIndex];
8010570f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105712:	69 c0 e4 00 00 00    	imul   $0xe4,%eax,%eax
80105718:	83 c0 30             	add    $0x30,%eax
8010571b:	05 c0 39 11 80       	add    $0x801139c0,%eax
80105720:	83 c0 04             	add    $0x4,%eax
80105723:	89 45 ec             	mov    %eax,-0x14(%ebp)
    struct file *fd = p->ofile[fdNum];
80105726:	8b 45 ec             	mov    -0x14(%ebp),%eax
80105729:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010572c:	83 c2 08             	add    $0x8,%edx
8010572f:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105733:	89 45 e8             	mov    %eax,-0x18(%ebp)
    
    int sz = 0;
80105736:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
    memmove(buf, "type: ", strlen("type: ") + 1);
8010573d:	c7 04 24 66 96 10 80 	movl   $0x80109666,(%esp)
80105744:	e8 4b 08 00 00       	call   80105f94 <strlen>
80105749:	83 c0 01             	add    $0x1,%eax
8010574c:	89 44 24 08          	mov    %eax,0x8(%esp)
80105750:	c7 44 24 04 66 96 10 	movl   $0x80109666,0x4(%esp)
80105757:	80 
80105758:	8b 45 0c             	mov    0xc(%ebp),%eax
8010575b:	89 04 24             	mov    %eax,(%esp)
8010575e:	e8 96 06 00 00       	call   80105df9 <memmove>
    sz += strlen("type: ") + 1;
80105763:	c7 04 24 66 96 10 80 	movl   $0x80109666,(%esp)
8010576a:	e8 25 08 00 00       	call   80105f94 <strlen>
8010576f:	83 c0 01             	add    $0x1,%eax
80105772:	01 45 e4             	add    %eax,-0x1c(%ebp)
    
    memmove(buf + sz,fd_enums[fd->type], strlen(fd_enums[fd->type]) + 1);
80105775:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105778:	8b 00                	mov    (%eax),%eax
8010577a:	8b 04 85 24 c0 10 80 	mov    -0x7fef3fdc(,%eax,4),%eax
80105781:	89 04 24             	mov    %eax,(%esp)
80105784:	e8 0b 08 00 00       	call   80105f94 <strlen>
80105789:	83 c0 01             	add    $0x1,%eax
8010578c:	89 c2                	mov    %eax,%edx
8010578e:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105791:	8b 00                	mov    (%eax),%eax
80105793:	8b 04 85 24 c0 10 80 	mov    -0x7fef3fdc(,%eax,4),%eax
8010579a:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
8010579d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801057a0:	01 d9                	add    %ebx,%ecx
801057a2:	89 54 24 08          	mov    %edx,0x8(%esp)
801057a6:	89 44 24 04          	mov    %eax,0x4(%esp)
801057aa:	89 0c 24             	mov    %ecx,(%esp)
801057ad:	e8 47 06 00 00       	call   80105df9 <memmove>
    sz += strlen(fd_enums[fd->type]) + 1;
801057b2:	8b 45 e8             	mov    -0x18(%ebp),%eax
801057b5:	8b 00                	mov    (%eax),%eax
801057b7:	8b 04 85 24 c0 10 80 	mov    -0x7fef3fdc(,%eax,4),%eax
801057be:	89 04 24             	mov    %eax,(%esp)
801057c1:	e8 ce 07 00 00       	call   80105f94 <strlen>
801057c6:	83 c0 01             	add    $0x1,%eax
801057c9:	01 45 e4             	add    %eax,-0x1c(%ebp)
    
    memmove(buf + sz, "\noffset: ", strlen("\noffset: ") + 1);
801057cc:	c7 04 24 6d 96 10 80 	movl   $0x8010966d,(%esp)
801057d3:	e8 bc 07 00 00       	call   80105f94 <strlen>
801057d8:	83 c0 01             	add    $0x1,%eax
801057db:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801057de:	8b 55 0c             	mov    0xc(%ebp),%edx
801057e1:	01 ca                	add    %ecx,%edx
801057e3:	89 44 24 08          	mov    %eax,0x8(%esp)
801057e7:	c7 44 24 04 6d 96 10 	movl   $0x8010966d,0x4(%esp)
801057ee:	80 
801057ef:	89 14 24             	mov    %edx,(%esp)
801057f2:	e8 02 06 00 00       	call   80105df9 <memmove>
    sz += strlen("\noffset: ") + 1;
801057f7:	c7 04 24 6d 96 10 80 	movl   $0x8010966d,(%esp)
801057fe:	e8 91 07 00 00       	call   80105f94 <strlen>
80105803:	83 c0 01             	add    $0x1,%eax
80105806:	01 45 e4             	add    %eax,-0x1c(%ebp)
    
    char off[100];
    itoa((int)fd->off, off);
80105809:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010580c:	8b 40 14             	mov    0x14(%eax),%eax
8010580f:	8d 55 80             	lea    -0x80(%ebp),%edx
80105812:	89 54 24 04          	mov    %edx,0x4(%esp)
80105816:	89 04 24             	mov    %eax,(%esp)
80105819:	e8 00 08 00 00       	call   8010601e <itoa>
    memmove(buf + sz, off, strlen(off) + 1);
8010581e:	8d 45 80             	lea    -0x80(%ebp),%eax
80105821:	89 04 24             	mov    %eax,(%esp)
80105824:	e8 6b 07 00 00       	call   80105f94 <strlen>
80105829:	83 c0 01             	add    $0x1,%eax
8010582c:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
8010582f:	8b 55 0c             	mov    0xc(%ebp),%edx
80105832:	01 ca                	add    %ecx,%edx
80105834:	89 44 24 08          	mov    %eax,0x8(%esp)
80105838:	8d 45 80             	lea    -0x80(%ebp),%eax
8010583b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010583f:	89 14 24             	mov    %edx,(%esp)
80105842:	e8 b2 05 00 00       	call   80105df9 <memmove>
    sz += strlen(off) + 1;
80105847:	8d 45 80             	lea    -0x80(%ebp),%eax
8010584a:	89 04 24             	mov    %eax,(%esp)
8010584d:	e8 42 07 00 00       	call   80105f94 <strlen>
80105852:	83 c0 01             	add    $0x1,%eax
80105855:	01 45 e4             	add    %eax,-0x1c(%ebp)
    
    memmove(buf + sz, "\nflags: ", strlen("\nflags: ") + 1);
80105858:	c7 04 24 77 96 10 80 	movl   $0x80109677,(%esp)
8010585f:	e8 30 07 00 00       	call   80105f94 <strlen>
80105864:	83 c0 01             	add    $0x1,%eax
80105867:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
8010586a:	8b 55 0c             	mov    0xc(%ebp),%edx
8010586d:	01 ca                	add    %ecx,%edx
8010586f:	89 44 24 08          	mov    %eax,0x8(%esp)
80105873:	c7 44 24 04 77 96 10 	movl   $0x80109677,0x4(%esp)
8010587a:	80 
8010587b:	89 14 24             	mov    %edx,(%esp)
8010587e:	e8 76 05 00 00       	call   80105df9 <memmove>
    sz += strlen("\nflags: ") + 1;
80105883:	c7 04 24 77 96 10 80 	movl   $0x80109677,(%esp)
8010588a:	e8 05 07 00 00       	call   80105f94 <strlen>
8010588f:	83 c0 01             	add    $0x1,%eax
80105892:	01 45 e4             	add    %eax,-0x1c(%ebp)
        
    memmove(buf + sz, "readable: ", strlen(" readable: ") + 1);
80105895:	c7 04 24 80 96 10 80 	movl   $0x80109680,(%esp)
8010589c:	e8 f3 06 00 00       	call   80105f94 <strlen>
801058a1:	83 c0 01             	add    $0x1,%eax
801058a4:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801058a7:	8b 55 0c             	mov    0xc(%ebp),%edx
801058aa:	01 ca                	add    %ecx,%edx
801058ac:	89 44 24 08          	mov    %eax,0x8(%esp)
801058b0:	c7 44 24 04 8c 96 10 	movl   $0x8010968c,0x4(%esp)
801058b7:	80 
801058b8:	89 14 24             	mov    %edx,(%esp)
801058bb:	e8 39 05 00 00       	call   80105df9 <memmove>
    sz += strlen(" readable: ") + 1;
801058c0:	c7 04 24 80 96 10 80 	movl   $0x80109680,(%esp)
801058c7:	e8 c8 06 00 00       	call   80105f94 <strlen>
801058cc:	83 c0 01             	add    $0x1,%eax
801058cf:	01 45 e4             	add    %eax,-0x1c(%ebp)
    
    char read[1];
    itoa(fd->readable, read);
801058d2:	8b 45 e8             	mov    -0x18(%ebp),%eax
801058d5:	0f b6 40 08          	movzbl 0x8(%eax),%eax
801058d9:	0f be c0             	movsbl %al,%eax
801058dc:	8d 95 7f ff ff ff    	lea    -0x81(%ebp),%edx
801058e2:	89 54 24 04          	mov    %edx,0x4(%esp)
801058e6:	89 04 24             	mov    %eax,(%esp)
801058e9:	e8 30 07 00 00       	call   8010601e <itoa>
    memmove(buf + sz, read, strlen(read) + 1);
801058ee:	8d 85 7f ff ff ff    	lea    -0x81(%ebp),%eax
801058f4:	89 04 24             	mov    %eax,(%esp)
801058f7:	e8 98 06 00 00       	call   80105f94 <strlen>
801058fc:	83 c0 01             	add    $0x1,%eax
801058ff:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80105902:	8b 55 0c             	mov    0xc(%ebp),%edx
80105905:	01 ca                	add    %ecx,%edx
80105907:	89 44 24 08          	mov    %eax,0x8(%esp)
8010590b:	8d 85 7f ff ff ff    	lea    -0x81(%ebp),%eax
80105911:	89 44 24 04          	mov    %eax,0x4(%esp)
80105915:	89 14 24             	mov    %edx,(%esp)
80105918:	e8 dc 04 00 00       	call   80105df9 <memmove>
    sz += strlen(read) + 1;
8010591d:	8d 85 7f ff ff ff    	lea    -0x81(%ebp),%eax
80105923:	89 04 24             	mov    %eax,(%esp)
80105926:	e8 69 06 00 00       	call   80105f94 <strlen>
8010592b:	83 c0 01             	add    $0x1,%eax
8010592e:	01 45 e4             	add    %eax,-0x1c(%ebp)
    
    memmove(buf + sz, " writable: ", strlen(" writable: ") + 1);
80105931:	c7 04 24 97 96 10 80 	movl   $0x80109697,(%esp)
80105938:	e8 57 06 00 00       	call   80105f94 <strlen>
8010593d:	83 c0 01             	add    $0x1,%eax
80105940:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80105943:	8b 55 0c             	mov    0xc(%ebp),%edx
80105946:	01 ca                	add    %ecx,%edx
80105948:	89 44 24 08          	mov    %eax,0x8(%esp)
8010594c:	c7 44 24 04 97 96 10 	movl   $0x80109697,0x4(%esp)
80105953:	80 
80105954:	89 14 24             	mov    %edx,(%esp)
80105957:	e8 9d 04 00 00       	call   80105df9 <memmove>
    sz += strlen(" writable: ") + 1;
8010595c:	c7 04 24 97 96 10 80 	movl   $0x80109697,(%esp)
80105963:	e8 2c 06 00 00       	call   80105f94 <strlen>
80105968:	83 c0 01             	add    $0x1,%eax
8010596b:	01 45 e4             	add    %eax,-0x1c(%ebp)
    
    char write[1];
    itoa(fd->writable, write);
8010596e:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105971:	0f b6 40 09          	movzbl 0x9(%eax),%eax
80105975:	0f be c0             	movsbl %al,%eax
80105978:	8d 95 7e ff ff ff    	lea    -0x82(%ebp),%edx
8010597e:	89 54 24 04          	mov    %edx,0x4(%esp)
80105982:	89 04 24             	mov    %eax,(%esp)
80105985:	e8 94 06 00 00       	call   8010601e <itoa>
    memmove(buf + sz, write, strlen(write) + 1);
8010598a:	8d 85 7e ff ff ff    	lea    -0x82(%ebp),%eax
80105990:	89 04 24             	mov    %eax,(%esp)
80105993:	e8 fc 05 00 00       	call   80105f94 <strlen>
80105998:	83 c0 01             	add    $0x1,%eax
8010599b:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
8010599e:	8b 55 0c             	mov    0xc(%ebp),%edx
801059a1:	01 ca                	add    %ecx,%edx
801059a3:	89 44 24 08          	mov    %eax,0x8(%esp)
801059a7:	8d 85 7e ff ff ff    	lea    -0x82(%ebp),%eax
801059ad:	89 44 24 04          	mov    %eax,0x4(%esp)
801059b1:	89 14 24             	mov    %edx,(%esp)
801059b4:	e8 40 04 00 00       	call   80105df9 <memmove>
    sz += strlen(write) + 1;
801059b9:	8d 85 7e ff ff ff    	lea    -0x82(%ebp),%eax
801059bf:	89 04 24             	mov    %eax,(%esp)
801059c2:	e8 cd 05 00 00       	call   80105f94 <strlen>
801059c7:	83 c0 01             	add    $0x1,%eax
801059ca:	01 45 e4             	add    %eax,-0x1c(%ebp)
    
    memmove(buf + sz, "\n", strlen("\n") + 1);
801059cd:	c7 04 24 64 96 10 80 	movl   $0x80109664,(%esp)
801059d4:	e8 bb 05 00 00       	call   80105f94 <strlen>
801059d9:	83 c0 01             	add    $0x1,%eax
801059dc:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801059df:	8b 55 0c             	mov    0xc(%ebp),%edx
801059e2:	01 ca                	add    %ecx,%edx
801059e4:	89 44 24 08          	mov    %eax,0x8(%esp)
801059e8:	c7 44 24 04 64 96 10 	movl   $0x80109664,0x4(%esp)
801059ef:	80 
801059f0:	89 14 24             	mov    %edx,(%esp)
801059f3:	e8 01 04 00 00       	call   80105df9 <memmove>
    sz += strlen("\n") + 1;
801059f8:	c7 04 24 64 96 10 80 	movl   $0x80109664,(%esp)
801059ff:	e8 90 05 00 00       	call   80105f94 <strlen>
80105a04:	83 c0 01             	add    $0x1,%eax
80105a07:	01 45 e4             	add    %eax,-0x1c(%ebp)
    
    return sz;
80105a0a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
}
80105a0d:	81 c4 94 00 00 00    	add    $0x94,%esp
80105a13:	5b                   	pop    %ebx
80105a14:	5d                   	pop    %ebp
80105a15:	c3                   	ret    

80105a16 <pushDirentToBuf>:

/**
 * gets directory name and inum, buffer, and a pointer to number of directories already in the buffer
 * push directory entry to buffer (as struct dirent), increase numDirsInBuf by 1 
 */
void pushDirentToBuf(char* dirName, int inum, char* buf, int* numDirsInBuf) {
80105a16:	55                   	push   %ebp
80105a17:	89 e5                	mov    %esp,%ebp
80105a19:	83 ec 28             	sub    $0x28,%esp
  struct dirent dir;
  dir.inum = inum;
80105a1c:	8b 45 0c             	mov    0xc(%ebp),%eax
80105a1f:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  memmove(dir.name, dirName, strlen(dirName)+1);
80105a23:	8b 45 08             	mov    0x8(%ebp),%eax
80105a26:	89 04 24             	mov    %eax,(%esp)
80105a29:	e8 66 05 00 00       	call   80105f94 <strlen>
80105a2e:	83 c0 01             	add    $0x1,%eax
80105a31:	89 44 24 08          	mov    %eax,0x8(%esp)
80105a35:	8b 45 08             	mov    0x8(%ebp),%eax
80105a38:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a3c:	8d 45 e8             	lea    -0x18(%ebp),%eax
80105a3f:	83 c0 02             	add    $0x2,%eax
80105a42:	89 04 24             	mov    %eax,(%esp)
80105a45:	e8 af 03 00 00       	call   80105df9 <memmove>
  memmove(buf + (*numDirsInBuf)*sizeof(dir), (char*)&dir, sizeof(dir));
80105a4a:	8b 45 14             	mov    0x14(%ebp),%eax
80105a4d:	8b 00                	mov    (%eax),%eax
80105a4f:	c1 e0 04             	shl    $0x4,%eax
80105a52:	89 c2                	mov    %eax,%edx
80105a54:	8b 45 10             	mov    0x10(%ebp),%eax
80105a57:	01 c2                	add    %eax,%edx
80105a59:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105a60:	00 
80105a61:	8d 45 e8             	lea    -0x18(%ebp),%eax
80105a64:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a68:	89 14 24             	mov    %edx,(%esp)
80105a6b:	e8 89 03 00 00       	call   80105df9 <memmove>
  (*numDirsInBuf)++;
80105a70:	8b 45 14             	mov    0x14(%ebp),%eax
80105a73:	8b 00                	mov    (%eax),%eax
80105a75:	8d 50 01             	lea    0x1(%eax),%edx
80105a78:	8b 45 14             	mov    0x14(%ebp),%eax
80105a7b:	89 10                	mov    %edx,(%eax)
80105a7d:	c9                   	leave  
80105a7e:	c3                   	ret    

80105a7f <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80105a7f:	55                   	push   %ebp
80105a80:	89 e5                	mov    %esp,%ebp
80105a82:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80105a85:	9c                   	pushf  
80105a86:	58                   	pop    %eax
80105a87:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80105a8a:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105a8d:	c9                   	leave  
80105a8e:	c3                   	ret    

80105a8f <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80105a8f:	55                   	push   %ebp
80105a90:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80105a92:	fa                   	cli    
}
80105a93:	5d                   	pop    %ebp
80105a94:	c3                   	ret    

80105a95 <sti>:

static inline void
sti(void)
{
80105a95:	55                   	push   %ebp
80105a96:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80105a98:	fb                   	sti    
}
80105a99:	5d                   	pop    %ebp
80105a9a:	c3                   	ret    

80105a9b <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80105a9b:	55                   	push   %ebp
80105a9c:	89 e5                	mov    %esp,%ebp
80105a9e:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80105aa1:	8b 55 08             	mov    0x8(%ebp),%edx
80105aa4:	8b 45 0c             	mov    0xc(%ebp),%eax
80105aa7:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105aaa:	f0 87 02             	lock xchg %eax,(%edx)
80105aad:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80105ab0:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105ab3:	c9                   	leave  
80105ab4:	c3                   	ret    

80105ab5 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80105ab5:	55                   	push   %ebp
80105ab6:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80105ab8:	8b 45 08             	mov    0x8(%ebp),%eax
80105abb:	8b 55 0c             	mov    0xc(%ebp),%edx
80105abe:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80105ac1:	8b 45 08             	mov    0x8(%ebp),%eax
80105ac4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80105aca:	8b 45 08             	mov    0x8(%ebp),%eax
80105acd:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80105ad4:	5d                   	pop    %ebp
80105ad5:	c3                   	ret    

80105ad6 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80105ad6:	55                   	push   %ebp
80105ad7:	89 e5                	mov    %esp,%ebp
80105ad9:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80105adc:	e8 49 01 00 00       	call   80105c2a <pushcli>
  if(holding(lk))
80105ae1:	8b 45 08             	mov    0x8(%ebp),%eax
80105ae4:	89 04 24             	mov    %eax,(%esp)
80105ae7:	e8 14 01 00 00       	call   80105c00 <holding>
80105aec:	85 c0                	test   %eax,%eax
80105aee:	74 0c                	je     80105afc <acquire+0x26>
    panic("acquire");
80105af0:	c7 04 24 a3 96 10 80 	movl   $0x801096a3,(%esp)
80105af7:	e8 3e aa ff ff       	call   8010053a <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80105afc:	90                   	nop
80105afd:	8b 45 08             	mov    0x8(%ebp),%eax
80105b00:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105b07:	00 
80105b08:	89 04 24             	mov    %eax,(%esp)
80105b0b:	e8 8b ff ff ff       	call   80105a9b <xchg>
80105b10:	85 c0                	test   %eax,%eax
80105b12:	75 e9                	jne    80105afd <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80105b14:	8b 45 08             	mov    0x8(%ebp),%eax
80105b17:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105b1e:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80105b21:	8b 45 08             	mov    0x8(%ebp),%eax
80105b24:	83 c0 0c             	add    $0xc,%eax
80105b27:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b2b:	8d 45 08             	lea    0x8(%ebp),%eax
80105b2e:	89 04 24             	mov    %eax,(%esp)
80105b31:	e8 51 00 00 00       	call   80105b87 <getcallerpcs>
}
80105b36:	c9                   	leave  
80105b37:	c3                   	ret    

80105b38 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80105b38:	55                   	push   %ebp
80105b39:	89 e5                	mov    %esp,%ebp
80105b3b:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80105b3e:	8b 45 08             	mov    0x8(%ebp),%eax
80105b41:	89 04 24             	mov    %eax,(%esp)
80105b44:	e8 b7 00 00 00       	call   80105c00 <holding>
80105b49:	85 c0                	test   %eax,%eax
80105b4b:	75 0c                	jne    80105b59 <release+0x21>
    panic("release");
80105b4d:	c7 04 24 ab 96 10 80 	movl   $0x801096ab,(%esp)
80105b54:	e8 e1 a9 ff ff       	call   8010053a <panic>

  lk->pcs[0] = 0;
80105b59:	8b 45 08             	mov    0x8(%ebp),%eax
80105b5c:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80105b63:	8b 45 08             	mov    0x8(%ebp),%eax
80105b66:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80105b6d:	8b 45 08             	mov    0x8(%ebp),%eax
80105b70:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105b77:	00 
80105b78:	89 04 24             	mov    %eax,(%esp)
80105b7b:	e8 1b ff ff ff       	call   80105a9b <xchg>

  popcli();
80105b80:	e8 e9 00 00 00       	call   80105c6e <popcli>
}
80105b85:	c9                   	leave  
80105b86:	c3                   	ret    

80105b87 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80105b87:	55                   	push   %ebp
80105b88:	89 e5                	mov    %esp,%ebp
80105b8a:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80105b8d:	8b 45 08             	mov    0x8(%ebp),%eax
80105b90:	83 e8 08             	sub    $0x8,%eax
80105b93:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80105b96:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80105b9d:	eb 38                	jmp    80105bd7 <getcallerpcs+0x50>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80105b9f:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80105ba3:	74 38                	je     80105bdd <getcallerpcs+0x56>
80105ba5:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80105bac:	76 2f                	jbe    80105bdd <getcallerpcs+0x56>
80105bae:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80105bb2:	74 29                	je     80105bdd <getcallerpcs+0x56>
      break;
    pcs[i] = ebp[1];     // saved %eip
80105bb4:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105bb7:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80105bbe:	8b 45 0c             	mov    0xc(%ebp),%eax
80105bc1:	01 c2                	add    %eax,%edx
80105bc3:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105bc6:	8b 40 04             	mov    0x4(%eax),%eax
80105bc9:	89 02                	mov    %eax,(%edx)
    ebp = (uint*)ebp[0]; // saved %ebp
80105bcb:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105bce:	8b 00                	mov    (%eax),%eax
80105bd0:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80105bd3:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105bd7:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105bdb:	7e c2                	jle    80105b9f <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105bdd:	eb 19                	jmp    80105bf8 <getcallerpcs+0x71>
    pcs[i] = 0;
80105bdf:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105be2:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80105be9:	8b 45 0c             	mov    0xc(%ebp),%eax
80105bec:	01 d0                	add    %edx,%eax
80105bee:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105bf4:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105bf8:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105bfc:	7e e1                	jle    80105bdf <getcallerpcs+0x58>
    pcs[i] = 0;
}
80105bfe:	c9                   	leave  
80105bff:	c3                   	ret    

80105c00 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80105c00:	55                   	push   %ebp
80105c01:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80105c03:	8b 45 08             	mov    0x8(%ebp),%eax
80105c06:	8b 00                	mov    (%eax),%eax
80105c08:	85 c0                	test   %eax,%eax
80105c0a:	74 17                	je     80105c23 <holding+0x23>
80105c0c:	8b 45 08             	mov    0x8(%ebp),%eax
80105c0f:	8b 50 08             	mov    0x8(%eax),%edx
80105c12:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105c18:	39 c2                	cmp    %eax,%edx
80105c1a:	75 07                	jne    80105c23 <holding+0x23>
80105c1c:	b8 01 00 00 00       	mov    $0x1,%eax
80105c21:	eb 05                	jmp    80105c28 <holding+0x28>
80105c23:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105c28:	5d                   	pop    %ebp
80105c29:	c3                   	ret    

80105c2a <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80105c2a:	55                   	push   %ebp
80105c2b:	89 e5                	mov    %esp,%ebp
80105c2d:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80105c30:	e8 4a fe ff ff       	call   80105a7f <readeflags>
80105c35:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80105c38:	e8 52 fe ff ff       	call   80105a8f <cli>
  if(cpu->ncli++ == 0)
80105c3d:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105c44:	8b 82 ac 00 00 00    	mov    0xac(%edx),%eax
80105c4a:	8d 48 01             	lea    0x1(%eax),%ecx
80105c4d:	89 8a ac 00 00 00    	mov    %ecx,0xac(%edx)
80105c53:	85 c0                	test   %eax,%eax
80105c55:	75 15                	jne    80105c6c <pushcli+0x42>
    cpu->intena = eflags & FL_IF;
80105c57:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105c5d:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105c60:	81 e2 00 02 00 00    	and    $0x200,%edx
80105c66:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80105c6c:	c9                   	leave  
80105c6d:	c3                   	ret    

80105c6e <popcli>:

void
popcli(void)
{
80105c6e:	55                   	push   %ebp
80105c6f:	89 e5                	mov    %esp,%ebp
80105c71:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80105c74:	e8 06 fe ff ff       	call   80105a7f <readeflags>
80105c79:	25 00 02 00 00       	and    $0x200,%eax
80105c7e:	85 c0                	test   %eax,%eax
80105c80:	74 0c                	je     80105c8e <popcli+0x20>
    panic("popcli - interruptible");
80105c82:	c7 04 24 b3 96 10 80 	movl   $0x801096b3,(%esp)
80105c89:	e8 ac a8 ff ff       	call   8010053a <panic>
  if(--cpu->ncli < 0)
80105c8e:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105c94:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105c9a:	83 ea 01             	sub    $0x1,%edx
80105c9d:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105ca3:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105ca9:	85 c0                	test   %eax,%eax
80105cab:	79 0c                	jns    80105cb9 <popcli+0x4b>
    panic("popcli");
80105cad:	c7 04 24 ca 96 10 80 	movl   $0x801096ca,(%esp)
80105cb4:	e8 81 a8 ff ff       	call   8010053a <panic>
  if(cpu->ncli == 0 && cpu->intena)
80105cb9:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105cbf:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105cc5:	85 c0                	test   %eax,%eax
80105cc7:	75 15                	jne    80105cde <popcli+0x70>
80105cc9:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105ccf:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105cd5:	85 c0                	test   %eax,%eax
80105cd7:	74 05                	je     80105cde <popcli+0x70>
    sti();
80105cd9:	e8 b7 fd ff ff       	call   80105a95 <sti>
}
80105cde:	c9                   	leave  
80105cdf:	c3                   	ret    

80105ce0 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80105ce0:	55                   	push   %ebp
80105ce1:	89 e5                	mov    %esp,%ebp
80105ce3:	57                   	push   %edi
80105ce4:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80105ce5:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105ce8:	8b 55 10             	mov    0x10(%ebp),%edx
80105ceb:	8b 45 0c             	mov    0xc(%ebp),%eax
80105cee:	89 cb                	mov    %ecx,%ebx
80105cf0:	89 df                	mov    %ebx,%edi
80105cf2:	89 d1                	mov    %edx,%ecx
80105cf4:	fc                   	cld    
80105cf5:	f3 aa                	rep stos %al,%es:(%edi)
80105cf7:	89 ca                	mov    %ecx,%edx
80105cf9:	89 fb                	mov    %edi,%ebx
80105cfb:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105cfe:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105d01:	5b                   	pop    %ebx
80105d02:	5f                   	pop    %edi
80105d03:	5d                   	pop    %ebp
80105d04:	c3                   	ret    

80105d05 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80105d05:	55                   	push   %ebp
80105d06:	89 e5                	mov    %esp,%ebp
80105d08:	57                   	push   %edi
80105d09:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
80105d0a:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105d0d:	8b 55 10             	mov    0x10(%ebp),%edx
80105d10:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d13:	89 cb                	mov    %ecx,%ebx
80105d15:	89 df                	mov    %ebx,%edi
80105d17:	89 d1                	mov    %edx,%ecx
80105d19:	fc                   	cld    
80105d1a:	f3 ab                	rep stos %eax,%es:(%edi)
80105d1c:	89 ca                	mov    %ecx,%edx
80105d1e:	89 fb                	mov    %edi,%ebx
80105d20:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105d23:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105d26:	5b                   	pop    %ebx
80105d27:	5f                   	pop    %edi
80105d28:	5d                   	pop    %ebp
80105d29:	c3                   	ret    

80105d2a <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80105d2a:	55                   	push   %ebp
80105d2b:	89 e5                	mov    %esp,%ebp
80105d2d:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80105d30:	8b 45 08             	mov    0x8(%ebp),%eax
80105d33:	83 e0 03             	and    $0x3,%eax
80105d36:	85 c0                	test   %eax,%eax
80105d38:	75 49                	jne    80105d83 <memset+0x59>
80105d3a:	8b 45 10             	mov    0x10(%ebp),%eax
80105d3d:	83 e0 03             	and    $0x3,%eax
80105d40:	85 c0                	test   %eax,%eax
80105d42:	75 3f                	jne    80105d83 <memset+0x59>
    c &= 0xFF;
80105d44:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80105d4b:	8b 45 10             	mov    0x10(%ebp),%eax
80105d4e:	c1 e8 02             	shr    $0x2,%eax
80105d51:	89 c2                	mov    %eax,%edx
80105d53:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d56:	c1 e0 18             	shl    $0x18,%eax
80105d59:	89 c1                	mov    %eax,%ecx
80105d5b:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d5e:	c1 e0 10             	shl    $0x10,%eax
80105d61:	09 c1                	or     %eax,%ecx
80105d63:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d66:	c1 e0 08             	shl    $0x8,%eax
80105d69:	09 c8                	or     %ecx,%eax
80105d6b:	0b 45 0c             	or     0xc(%ebp),%eax
80105d6e:	89 54 24 08          	mov    %edx,0x8(%esp)
80105d72:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d76:	8b 45 08             	mov    0x8(%ebp),%eax
80105d79:	89 04 24             	mov    %eax,(%esp)
80105d7c:	e8 84 ff ff ff       	call   80105d05 <stosl>
80105d81:	eb 19                	jmp    80105d9c <memset+0x72>
  } else
    stosb(dst, c, n);
80105d83:	8b 45 10             	mov    0x10(%ebp),%eax
80105d86:	89 44 24 08          	mov    %eax,0x8(%esp)
80105d8a:	8b 45 0c             	mov    0xc(%ebp),%eax
80105d8d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d91:	8b 45 08             	mov    0x8(%ebp),%eax
80105d94:	89 04 24             	mov    %eax,(%esp)
80105d97:	e8 44 ff ff ff       	call   80105ce0 <stosb>
  return dst;
80105d9c:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105d9f:	c9                   	leave  
80105da0:	c3                   	ret    

80105da1 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80105da1:	55                   	push   %ebp
80105da2:	89 e5                	mov    %esp,%ebp
80105da4:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80105da7:	8b 45 08             	mov    0x8(%ebp),%eax
80105daa:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80105dad:	8b 45 0c             	mov    0xc(%ebp),%eax
80105db0:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80105db3:	eb 30                	jmp    80105de5 <memcmp+0x44>
    if(*s1 != *s2)
80105db5:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105db8:	0f b6 10             	movzbl (%eax),%edx
80105dbb:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105dbe:	0f b6 00             	movzbl (%eax),%eax
80105dc1:	38 c2                	cmp    %al,%dl
80105dc3:	74 18                	je     80105ddd <memcmp+0x3c>
      return *s1 - *s2;
80105dc5:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105dc8:	0f b6 00             	movzbl (%eax),%eax
80105dcb:	0f b6 d0             	movzbl %al,%edx
80105dce:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105dd1:	0f b6 00             	movzbl (%eax),%eax
80105dd4:	0f b6 c0             	movzbl %al,%eax
80105dd7:	29 c2                	sub    %eax,%edx
80105dd9:	89 d0                	mov    %edx,%eax
80105ddb:	eb 1a                	jmp    80105df7 <memcmp+0x56>
    s1++, s2++;
80105ddd:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105de1:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80105de5:	8b 45 10             	mov    0x10(%ebp),%eax
80105de8:	8d 50 ff             	lea    -0x1(%eax),%edx
80105deb:	89 55 10             	mov    %edx,0x10(%ebp)
80105dee:	85 c0                	test   %eax,%eax
80105df0:	75 c3                	jne    80105db5 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80105df2:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105df7:	c9                   	leave  
80105df8:	c3                   	ret    

80105df9 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80105df9:	55                   	push   %ebp
80105dfa:	89 e5                	mov    %esp,%ebp
80105dfc:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105dff:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e02:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80105e05:	8b 45 08             	mov    0x8(%ebp),%eax
80105e08:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80105e0b:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105e0e:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105e11:	73 3d                	jae    80105e50 <memmove+0x57>
80105e13:	8b 45 10             	mov    0x10(%ebp),%eax
80105e16:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105e19:	01 d0                	add    %edx,%eax
80105e1b:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105e1e:	76 30                	jbe    80105e50 <memmove+0x57>
    s += n;
80105e20:	8b 45 10             	mov    0x10(%ebp),%eax
80105e23:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
80105e26:	8b 45 10             	mov    0x10(%ebp),%eax
80105e29:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105e2c:	eb 13                	jmp    80105e41 <memmove+0x48>
      *--d = *--s;
80105e2e:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80105e32:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
80105e36:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105e39:	0f b6 10             	movzbl (%eax),%edx
80105e3c:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105e3f:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105e41:	8b 45 10             	mov    0x10(%ebp),%eax
80105e44:	8d 50 ff             	lea    -0x1(%eax),%edx
80105e47:	89 55 10             	mov    %edx,0x10(%ebp)
80105e4a:	85 c0                	test   %eax,%eax
80105e4c:	75 e0                	jne    80105e2e <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80105e4e:	eb 26                	jmp    80105e76 <memmove+0x7d>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105e50:	eb 17                	jmp    80105e69 <memmove+0x70>
      *d++ = *s++;
80105e52:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105e55:	8d 50 01             	lea    0x1(%eax),%edx
80105e58:	89 55 f8             	mov    %edx,-0x8(%ebp)
80105e5b:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105e5e:	8d 4a 01             	lea    0x1(%edx),%ecx
80105e61:	89 4d fc             	mov    %ecx,-0x4(%ebp)
80105e64:	0f b6 12             	movzbl (%edx),%edx
80105e67:	88 10                	mov    %dl,(%eax)
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105e69:	8b 45 10             	mov    0x10(%ebp),%eax
80105e6c:	8d 50 ff             	lea    -0x1(%eax),%edx
80105e6f:	89 55 10             	mov    %edx,0x10(%ebp)
80105e72:	85 c0                	test   %eax,%eax
80105e74:	75 dc                	jne    80105e52 <memmove+0x59>
      *d++ = *s++;

  return dst;
80105e76:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105e79:	c9                   	leave  
80105e7a:	c3                   	ret    

80105e7b <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80105e7b:	55                   	push   %ebp
80105e7c:	89 e5                	mov    %esp,%ebp
80105e7e:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80105e81:	8b 45 10             	mov    0x10(%ebp),%eax
80105e84:	89 44 24 08          	mov    %eax,0x8(%esp)
80105e88:	8b 45 0c             	mov    0xc(%ebp),%eax
80105e8b:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e8f:	8b 45 08             	mov    0x8(%ebp),%eax
80105e92:	89 04 24             	mov    %eax,(%esp)
80105e95:	e8 5f ff ff ff       	call   80105df9 <memmove>
}
80105e9a:	c9                   	leave  
80105e9b:	c3                   	ret    

80105e9c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80105e9c:	55                   	push   %ebp
80105e9d:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80105e9f:	eb 0c                	jmp    80105ead <strncmp+0x11>
    n--, p++, q++;
80105ea1:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105ea5:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105ea9:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80105ead:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105eb1:	74 1a                	je     80105ecd <strncmp+0x31>
80105eb3:	8b 45 08             	mov    0x8(%ebp),%eax
80105eb6:	0f b6 00             	movzbl (%eax),%eax
80105eb9:	84 c0                	test   %al,%al
80105ebb:	74 10                	je     80105ecd <strncmp+0x31>
80105ebd:	8b 45 08             	mov    0x8(%ebp),%eax
80105ec0:	0f b6 10             	movzbl (%eax),%edx
80105ec3:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ec6:	0f b6 00             	movzbl (%eax),%eax
80105ec9:	38 c2                	cmp    %al,%dl
80105ecb:	74 d4                	je     80105ea1 <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105ecd:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105ed1:	75 07                	jne    80105eda <strncmp+0x3e>
    return 0;
80105ed3:	b8 00 00 00 00       	mov    $0x0,%eax
80105ed8:	eb 16                	jmp    80105ef0 <strncmp+0x54>
  return (uchar)*p - (uchar)*q;
80105eda:	8b 45 08             	mov    0x8(%ebp),%eax
80105edd:	0f b6 00             	movzbl (%eax),%eax
80105ee0:	0f b6 d0             	movzbl %al,%edx
80105ee3:	8b 45 0c             	mov    0xc(%ebp),%eax
80105ee6:	0f b6 00             	movzbl (%eax),%eax
80105ee9:	0f b6 c0             	movzbl %al,%eax
80105eec:	29 c2                	sub    %eax,%edx
80105eee:	89 d0                	mov    %edx,%eax
}
80105ef0:	5d                   	pop    %ebp
80105ef1:	c3                   	ret    

80105ef2 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80105ef2:	55                   	push   %ebp
80105ef3:	89 e5                	mov    %esp,%ebp
80105ef5:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105ef8:	8b 45 08             	mov    0x8(%ebp),%eax
80105efb:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105efe:	90                   	nop
80105eff:	8b 45 10             	mov    0x10(%ebp),%eax
80105f02:	8d 50 ff             	lea    -0x1(%eax),%edx
80105f05:	89 55 10             	mov    %edx,0x10(%ebp)
80105f08:	85 c0                	test   %eax,%eax
80105f0a:	7e 1e                	jle    80105f2a <strncpy+0x38>
80105f0c:	8b 45 08             	mov    0x8(%ebp),%eax
80105f0f:	8d 50 01             	lea    0x1(%eax),%edx
80105f12:	89 55 08             	mov    %edx,0x8(%ebp)
80105f15:	8b 55 0c             	mov    0xc(%ebp),%edx
80105f18:	8d 4a 01             	lea    0x1(%edx),%ecx
80105f1b:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105f1e:	0f b6 12             	movzbl (%edx),%edx
80105f21:	88 10                	mov    %dl,(%eax)
80105f23:	0f b6 00             	movzbl (%eax),%eax
80105f26:	84 c0                	test   %al,%al
80105f28:	75 d5                	jne    80105eff <strncpy+0xd>
    ;
  while(n-- > 0)
80105f2a:	eb 0c                	jmp    80105f38 <strncpy+0x46>
    *s++ = 0;
80105f2c:	8b 45 08             	mov    0x8(%ebp),%eax
80105f2f:	8d 50 01             	lea    0x1(%eax),%edx
80105f32:	89 55 08             	mov    %edx,0x8(%ebp)
80105f35:	c6 00 00             	movb   $0x0,(%eax)
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80105f38:	8b 45 10             	mov    0x10(%ebp),%eax
80105f3b:	8d 50 ff             	lea    -0x1(%eax),%edx
80105f3e:	89 55 10             	mov    %edx,0x10(%ebp)
80105f41:	85 c0                	test   %eax,%eax
80105f43:	7f e7                	jg     80105f2c <strncpy+0x3a>
    *s++ = 0;
  return os;
80105f45:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105f48:	c9                   	leave  
80105f49:	c3                   	ret    

80105f4a <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80105f4a:	55                   	push   %ebp
80105f4b:	89 e5                	mov    %esp,%ebp
80105f4d:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105f50:	8b 45 08             	mov    0x8(%ebp),%eax
80105f53:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
80105f56:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105f5a:	7f 05                	jg     80105f61 <safestrcpy+0x17>
    return os;
80105f5c:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105f5f:	eb 31                	jmp    80105f92 <safestrcpy+0x48>
  while(--n > 0 && (*s++ = *t++) != 0)
80105f61:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105f65:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105f69:	7e 1e                	jle    80105f89 <safestrcpy+0x3f>
80105f6b:	8b 45 08             	mov    0x8(%ebp),%eax
80105f6e:	8d 50 01             	lea    0x1(%eax),%edx
80105f71:	89 55 08             	mov    %edx,0x8(%ebp)
80105f74:	8b 55 0c             	mov    0xc(%ebp),%edx
80105f77:	8d 4a 01             	lea    0x1(%edx),%ecx
80105f7a:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105f7d:	0f b6 12             	movzbl (%edx),%edx
80105f80:	88 10                	mov    %dl,(%eax)
80105f82:	0f b6 00             	movzbl (%eax),%eax
80105f85:	84 c0                	test   %al,%al
80105f87:	75 d8                	jne    80105f61 <safestrcpy+0x17>
    ;
  *s = 0;
80105f89:	8b 45 08             	mov    0x8(%ebp),%eax
80105f8c:	c6 00 00             	movb   $0x0,(%eax)
  return os;
80105f8f:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105f92:	c9                   	leave  
80105f93:	c3                   	ret    

80105f94 <strlen>:

int
strlen(const char *s)
{
80105f94:	55                   	push   %ebp
80105f95:	89 e5                	mov    %esp,%ebp
80105f97:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
80105f9a:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105fa1:	eb 04                	jmp    80105fa7 <strlen+0x13>
80105fa3:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105fa7:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105faa:	8b 45 08             	mov    0x8(%ebp),%eax
80105fad:	01 d0                	add    %edx,%eax
80105faf:	0f b6 00             	movzbl (%eax),%eax
80105fb2:	84 c0                	test   %al,%al
80105fb4:	75 ed                	jne    80105fa3 <strlen+0xf>
    ;
  return n;
80105fb6:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105fb9:	c9                   	leave  
80105fba:	c3                   	ret    

80105fbb <reverse>:

 /* reverse:  reverse string s in place */
void reverse(char s[])
{
80105fbb:	55                   	push   %ebp
80105fbc:	89 e5                	mov    %esp,%ebp
80105fbe:	83 ec 14             	sub    $0x14,%esp
     int i, j;
     char c;
 
     for (i = 0, j = strlen(s)-1; i<j; i++, j--) {
80105fc1:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105fc8:	8b 45 08             	mov    0x8(%ebp),%eax
80105fcb:	89 04 24             	mov    %eax,(%esp)
80105fce:	e8 c1 ff ff ff       	call   80105f94 <strlen>
80105fd3:	83 e8 01             	sub    $0x1,%eax
80105fd6:	89 45 f8             	mov    %eax,-0x8(%ebp)
80105fd9:	eb 39                	jmp    80106014 <reverse+0x59>
         c = s[i];
80105fdb:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105fde:	8b 45 08             	mov    0x8(%ebp),%eax
80105fe1:	01 d0                	add    %edx,%eax
80105fe3:	0f b6 00             	movzbl (%eax),%eax
80105fe6:	88 45 f7             	mov    %al,-0x9(%ebp)
         s[i] = s[j];
80105fe9:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105fec:	8b 45 08             	mov    0x8(%ebp),%eax
80105fef:	01 c2                	add    %eax,%edx
80105ff1:	8b 4d f8             	mov    -0x8(%ebp),%ecx
80105ff4:	8b 45 08             	mov    0x8(%ebp),%eax
80105ff7:	01 c8                	add    %ecx,%eax
80105ff9:	0f b6 00             	movzbl (%eax),%eax
80105ffc:	88 02                	mov    %al,(%edx)
         s[j] = c;
80105ffe:	8b 55 f8             	mov    -0x8(%ebp),%edx
80106001:	8b 45 08             	mov    0x8(%ebp),%eax
80106004:	01 c2                	add    %eax,%edx
80106006:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
8010600a:	88 02                	mov    %al,(%edx)
void reverse(char s[])
{
     int i, j;
     char c;
 
     for (i = 0, j = strlen(s)-1; i<j; i++, j--) {
8010600c:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80106010:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80106014:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106017:	3b 45 f8             	cmp    -0x8(%ebp),%eax
8010601a:	7c bf                	jl     80105fdb <reverse+0x20>
         c = s[i];
         s[i] = s[j];
         s[j] = c;
     }
}
8010601c:	c9                   	leave  
8010601d:	c3                   	ret    

8010601e <itoa>:

 /* itoa:  convert n to characters in s */
void itoa(int n, char s[])
{
8010601e:	55                   	push   %ebp
8010601f:	89 e5                	mov    %esp,%ebp
80106021:	53                   	push   %ebx
80106022:	83 ec 14             	sub    $0x14,%esp
     int i, sign;
 
     if ((sign = n) < 0)  /* record sign */
80106025:	8b 45 08             	mov    0x8(%ebp),%eax
80106028:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010602b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010602f:	79 03                	jns    80106034 <itoa+0x16>
         n = -n;          /* make n positive */
80106031:	f7 5d 08             	negl   0x8(%ebp)
     i = 0;
80106034:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
     do {       /* generate digits in reverse order */
         s[i++] = n % 10 + '0';   /* get next digit */
8010603b:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010603e:	8d 50 01             	lea    0x1(%eax),%edx
80106041:	89 55 f8             	mov    %edx,-0x8(%ebp)
80106044:	89 c2                	mov    %eax,%edx
80106046:	8b 45 0c             	mov    0xc(%ebp),%eax
80106049:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
8010604c:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010604f:	ba 67 66 66 66       	mov    $0x66666667,%edx
80106054:	89 c8                	mov    %ecx,%eax
80106056:	f7 ea                	imul   %edx
80106058:	c1 fa 02             	sar    $0x2,%edx
8010605b:	89 c8                	mov    %ecx,%eax
8010605d:	c1 f8 1f             	sar    $0x1f,%eax
80106060:	29 c2                	sub    %eax,%edx
80106062:	89 d0                	mov    %edx,%eax
80106064:	c1 e0 02             	shl    $0x2,%eax
80106067:	01 d0                	add    %edx,%eax
80106069:	01 c0                	add    %eax,%eax
8010606b:	29 c1                	sub    %eax,%ecx
8010606d:	89 ca                	mov    %ecx,%edx
8010606f:	89 d0                	mov    %edx,%eax
80106071:	83 c0 30             	add    $0x30,%eax
80106074:	88 03                	mov    %al,(%ebx)
     } while ((n /= 10) > 0);     /* delete it */
80106076:	8b 4d 08             	mov    0x8(%ebp),%ecx
80106079:	ba 67 66 66 66       	mov    $0x66666667,%edx
8010607e:	89 c8                	mov    %ecx,%eax
80106080:	f7 ea                	imul   %edx
80106082:	c1 fa 02             	sar    $0x2,%edx
80106085:	89 c8                	mov    %ecx,%eax
80106087:	c1 f8 1f             	sar    $0x1f,%eax
8010608a:	29 c2                	sub    %eax,%edx
8010608c:	89 d0                	mov    %edx,%eax
8010608e:	89 45 08             	mov    %eax,0x8(%ebp)
80106091:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80106095:	7f a4                	jg     8010603b <itoa+0x1d>
     if (sign < 0)
80106097:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010609b:	79 13                	jns    801060b0 <itoa+0x92>
         s[i++] = '-';
8010609d:	8b 45 f8             	mov    -0x8(%ebp),%eax
801060a0:	8d 50 01             	lea    0x1(%eax),%edx
801060a3:	89 55 f8             	mov    %edx,-0x8(%ebp)
801060a6:	89 c2                	mov    %eax,%edx
801060a8:	8b 45 0c             	mov    0xc(%ebp),%eax
801060ab:	01 d0                	add    %edx,%eax
801060ad:	c6 00 2d             	movb   $0x2d,(%eax)
     s[i] = '\0';
801060b0:	8b 55 f8             	mov    -0x8(%ebp),%edx
801060b3:	8b 45 0c             	mov    0xc(%ebp),%eax
801060b6:	01 d0                	add    %edx,%eax
801060b8:	c6 00 00             	movb   $0x0,(%eax)
     reverse(s);
801060bb:	8b 45 0c             	mov    0xc(%ebp),%eax
801060be:	89 04 24             	mov    %eax,(%esp)
801060c1:	e8 f5 fe ff ff       	call   80105fbb <reverse>
801060c6:	83 c4 14             	add    $0x14,%esp
801060c9:	5b                   	pop    %ebx
801060ca:	5d                   	pop    %ebp
801060cb:	c3                   	ret    

801060cc <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
801060cc:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
801060d0:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
801060d4:	55                   	push   %ebp
  pushl %ebx
801060d5:	53                   	push   %ebx
  pushl %esi
801060d6:	56                   	push   %esi
  pushl %edi
801060d7:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
801060d8:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
801060da:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
801060dc:	5f                   	pop    %edi
  popl %esi
801060dd:	5e                   	pop    %esi
  popl %ebx
801060de:	5b                   	pop    %ebx
  popl %ebp
801060df:	5d                   	pop    %ebp
  ret
801060e0:	c3                   	ret    

801060e1 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
801060e1:	55                   	push   %ebp
801060e2:	89 e5                	mov    %esp,%ebp
  if(addr >= proc->sz || addr+4 > proc->sz)
801060e4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801060ea:	8b 00                	mov    (%eax),%eax
801060ec:	3b 45 08             	cmp    0x8(%ebp),%eax
801060ef:	76 12                	jbe    80106103 <fetchint+0x22>
801060f1:	8b 45 08             	mov    0x8(%ebp),%eax
801060f4:	8d 50 04             	lea    0x4(%eax),%edx
801060f7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801060fd:	8b 00                	mov    (%eax),%eax
801060ff:	39 c2                	cmp    %eax,%edx
80106101:	76 07                	jbe    8010610a <fetchint+0x29>
    return -1;
80106103:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106108:	eb 0f                	jmp    80106119 <fetchint+0x38>
  *ip = *(int*)(addr);
8010610a:	8b 45 08             	mov    0x8(%ebp),%eax
8010610d:	8b 10                	mov    (%eax),%edx
8010610f:	8b 45 0c             	mov    0xc(%ebp),%eax
80106112:	89 10                	mov    %edx,(%eax)
  return 0;
80106114:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106119:	5d                   	pop    %ebp
8010611a:	c3                   	ret    

8010611b <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
8010611b:	55                   	push   %ebp
8010611c:	89 e5                	mov    %esp,%ebp
8010611e:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= proc->sz)
80106121:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106127:	8b 00                	mov    (%eax),%eax
80106129:	3b 45 08             	cmp    0x8(%ebp),%eax
8010612c:	77 07                	ja     80106135 <fetchstr+0x1a>
    return -1;
8010612e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106133:	eb 46                	jmp    8010617b <fetchstr+0x60>
  *pp = (char*)addr;
80106135:	8b 55 08             	mov    0x8(%ebp),%edx
80106138:	8b 45 0c             	mov    0xc(%ebp),%eax
8010613b:	89 10                	mov    %edx,(%eax)
  ep = (char*)proc->sz;
8010613d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106143:	8b 00                	mov    (%eax),%eax
80106145:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
80106148:	8b 45 0c             	mov    0xc(%ebp),%eax
8010614b:	8b 00                	mov    (%eax),%eax
8010614d:	89 45 fc             	mov    %eax,-0x4(%ebp)
80106150:	eb 1c                	jmp    8010616e <fetchstr+0x53>
    if(*s == 0)
80106152:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106155:	0f b6 00             	movzbl (%eax),%eax
80106158:	84 c0                	test   %al,%al
8010615a:	75 0e                	jne    8010616a <fetchstr+0x4f>
      return s - *pp;
8010615c:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010615f:	8b 45 0c             	mov    0xc(%ebp),%eax
80106162:	8b 00                	mov    (%eax),%eax
80106164:	29 c2                	sub    %eax,%edx
80106166:	89 d0                	mov    %edx,%eax
80106168:	eb 11                	jmp    8010617b <fetchstr+0x60>

  if(addr >= proc->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)proc->sz;
  for(s = *pp; s < ep; s++)
8010616a:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010616e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106171:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80106174:	72 dc                	jb     80106152 <fetchstr+0x37>
    if(*s == 0)
      return s - *pp;
  return -1;
80106176:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010617b:	c9                   	leave  
8010617c:	c3                   	ret    

8010617d <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
8010617d:	55                   	push   %ebp
8010617e:	89 e5                	mov    %esp,%ebp
80106180:	83 ec 08             	sub    $0x8,%esp
  return fetchint(proc->tf->esp + 4 + 4*n, ip);
80106183:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106189:	8b 40 18             	mov    0x18(%eax),%eax
8010618c:	8b 50 44             	mov    0x44(%eax),%edx
8010618f:	8b 45 08             	mov    0x8(%ebp),%eax
80106192:	c1 e0 02             	shl    $0x2,%eax
80106195:	01 d0                	add    %edx,%eax
80106197:	8d 50 04             	lea    0x4(%eax),%edx
8010619a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010619d:	89 44 24 04          	mov    %eax,0x4(%esp)
801061a1:	89 14 24             	mov    %edx,(%esp)
801061a4:	e8 38 ff ff ff       	call   801060e1 <fetchint>
}
801061a9:	c9                   	leave  
801061aa:	c3                   	ret    

801061ab <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
801061ab:	55                   	push   %ebp
801061ac:	89 e5                	mov    %esp,%ebp
801061ae:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
801061b1:	8d 45 fc             	lea    -0x4(%ebp),%eax
801061b4:	89 44 24 04          	mov    %eax,0x4(%esp)
801061b8:	8b 45 08             	mov    0x8(%ebp),%eax
801061bb:	89 04 24             	mov    %eax,(%esp)
801061be:	e8 ba ff ff ff       	call   8010617d <argint>
801061c3:	85 c0                	test   %eax,%eax
801061c5:	79 07                	jns    801061ce <argptr+0x23>
    return -1;
801061c7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061cc:	eb 3d                	jmp    8010620b <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
801061ce:	8b 45 fc             	mov    -0x4(%ebp),%eax
801061d1:	89 c2                	mov    %eax,%edx
801061d3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801061d9:	8b 00                	mov    (%eax),%eax
801061db:	39 c2                	cmp    %eax,%edx
801061dd:	73 16                	jae    801061f5 <argptr+0x4a>
801061df:	8b 45 fc             	mov    -0x4(%ebp),%eax
801061e2:	89 c2                	mov    %eax,%edx
801061e4:	8b 45 10             	mov    0x10(%ebp),%eax
801061e7:	01 c2                	add    %eax,%edx
801061e9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801061ef:	8b 00                	mov    (%eax),%eax
801061f1:	39 c2                	cmp    %eax,%edx
801061f3:	76 07                	jbe    801061fc <argptr+0x51>
    return -1;
801061f5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061fa:	eb 0f                	jmp    8010620b <argptr+0x60>
  *pp = (char*)i;
801061fc:	8b 45 fc             	mov    -0x4(%ebp),%eax
801061ff:	89 c2                	mov    %eax,%edx
80106201:	8b 45 0c             	mov    0xc(%ebp),%eax
80106204:	89 10                	mov    %edx,(%eax)
  return 0;
80106206:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010620b:	c9                   	leave  
8010620c:	c3                   	ret    

8010620d <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
8010620d:	55                   	push   %ebp
8010620e:	89 e5                	mov    %esp,%ebp
80106210:	83 ec 18             	sub    $0x18,%esp
  int addr;
  if(argint(n, &addr) < 0)
80106213:	8d 45 fc             	lea    -0x4(%ebp),%eax
80106216:	89 44 24 04          	mov    %eax,0x4(%esp)
8010621a:	8b 45 08             	mov    0x8(%ebp),%eax
8010621d:	89 04 24             	mov    %eax,(%esp)
80106220:	e8 58 ff ff ff       	call   8010617d <argint>
80106225:	85 c0                	test   %eax,%eax
80106227:	79 07                	jns    80106230 <argstr+0x23>
    return -1;
80106229:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010622e:	eb 12                	jmp    80106242 <argstr+0x35>
  return fetchstr(addr, pp);
80106230:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106233:	8b 55 0c             	mov    0xc(%ebp),%edx
80106236:	89 54 24 04          	mov    %edx,0x4(%esp)
8010623a:	89 04 24             	mov    %eax,(%esp)
8010623d:	e8 d9 fe ff ff       	call   8010611b <fetchstr>
}
80106242:	c9                   	leave  
80106243:	c3                   	ret    

80106244 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
80106244:	55                   	push   %ebp
80106245:	89 e5                	mov    %esp,%ebp
80106247:	53                   	push   %ebx
80106248:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
8010624b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106251:	8b 40 18             	mov    0x18(%eax),%eax
80106254:	8b 40 1c             	mov    0x1c(%eax),%eax
80106257:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
8010625a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010625e:	7e 30                	jle    80106290 <syscall+0x4c>
80106260:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106263:	83 f8 15             	cmp    $0x15,%eax
80106266:	77 28                	ja     80106290 <syscall+0x4c>
80106268:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010626b:	8b 04 85 60 c0 10 80 	mov    -0x7fef3fa0(,%eax,4),%eax
80106272:	85 c0                	test   %eax,%eax
80106274:	74 1a                	je     80106290 <syscall+0x4c>
    proc->tf->eax = syscalls[num]();
80106276:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010627c:	8b 58 18             	mov    0x18(%eax),%ebx
8010627f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106282:	8b 04 85 60 c0 10 80 	mov    -0x7fef3fa0(,%eax,4),%eax
80106289:	ff d0                	call   *%eax
8010628b:	89 43 1c             	mov    %eax,0x1c(%ebx)
8010628e:	eb 3d                	jmp    801062cd <syscall+0x89>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
80106290:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106296:	8d 48 6c             	lea    0x6c(%eax),%ecx
80106299:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax

  num = proc->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
8010629f:	8b 40 10             	mov    0x10(%eax),%eax
801062a2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801062a5:	89 54 24 0c          	mov    %edx,0xc(%esp)
801062a9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801062ad:	89 44 24 04          	mov    %eax,0x4(%esp)
801062b1:	c7 04 24 d1 96 10 80 	movl   $0x801096d1,(%esp)
801062b8:	e8 e3 a0 ff ff       	call   801003a0 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
801062bd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801062c3:	8b 40 18             	mov    0x18(%eax),%eax
801062c6:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
801062cd:	83 c4 24             	add    $0x24,%esp
801062d0:	5b                   	pop    %ebx
801062d1:	5d                   	pop    %ebp
801062d2:	c3                   	ret    

801062d3 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
801062d3:	55                   	push   %ebp
801062d4:	89 e5                	mov    %esp,%ebp
801062d6:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
801062d9:	8d 45 f0             	lea    -0x10(%ebp),%eax
801062dc:	89 44 24 04          	mov    %eax,0x4(%esp)
801062e0:	8b 45 08             	mov    0x8(%ebp),%eax
801062e3:	89 04 24             	mov    %eax,(%esp)
801062e6:	e8 92 fe ff ff       	call   8010617d <argint>
801062eb:	85 c0                	test   %eax,%eax
801062ed:	79 07                	jns    801062f6 <argfd+0x23>
    return -1;
801062ef:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062f4:	eb 50                	jmp    80106346 <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
801062f6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062f9:	85 c0                	test   %eax,%eax
801062fb:	78 21                	js     8010631e <argfd+0x4b>
801062fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106300:	83 f8 0f             	cmp    $0xf,%eax
80106303:	7f 19                	jg     8010631e <argfd+0x4b>
80106305:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010630b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010630e:	83 c2 08             	add    $0x8,%edx
80106311:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80106315:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106318:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010631c:	75 07                	jne    80106325 <argfd+0x52>
    return -1;
8010631e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106323:	eb 21                	jmp    80106346 <argfd+0x73>
  if(pfd)
80106325:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80106329:	74 08                	je     80106333 <argfd+0x60>
    *pfd = fd;
8010632b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010632e:	8b 45 0c             	mov    0xc(%ebp),%eax
80106331:	89 10                	mov    %edx,(%eax)
  if(pf)
80106333:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80106337:	74 08                	je     80106341 <argfd+0x6e>
    *pf = f;
80106339:	8b 45 10             	mov    0x10(%ebp),%eax
8010633c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010633f:	89 10                	mov    %edx,(%eax)
  return 0;
80106341:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106346:	c9                   	leave  
80106347:	c3                   	ret    

80106348 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80106348:	55                   	push   %ebp
80106349:	89 e5                	mov    %esp,%ebp
8010634b:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
8010634e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80106355:	eb 30                	jmp    80106387 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
80106357:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010635d:	8b 55 fc             	mov    -0x4(%ebp),%edx
80106360:	83 c2 08             	add    $0x8,%edx
80106363:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80106367:	85 c0                	test   %eax,%eax
80106369:	75 18                	jne    80106383 <fdalloc+0x3b>
      proc->ofile[fd] = f;
8010636b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106371:	8b 55 fc             	mov    -0x4(%ebp),%edx
80106374:	8d 4a 08             	lea    0x8(%edx),%ecx
80106377:	8b 55 08             	mov    0x8(%ebp),%edx
8010637a:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
8010637e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80106381:	eb 0f                	jmp    80106392 <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80106383:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80106387:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
8010638b:	7e ca                	jle    80106357 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
8010638d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106392:	c9                   	leave  
80106393:	c3                   	ret    

80106394 <sys_dup>:

int
sys_dup(void)
{
80106394:	55                   	push   %ebp
80106395:	89 e5                	mov    %esp,%ebp
80106397:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
8010639a:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010639d:	89 44 24 08          	mov    %eax,0x8(%esp)
801063a1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801063a8:	00 
801063a9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801063b0:	e8 1e ff ff ff       	call   801062d3 <argfd>
801063b5:	85 c0                	test   %eax,%eax
801063b7:	79 07                	jns    801063c0 <sys_dup+0x2c>
    return -1;
801063b9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063be:	eb 29                	jmp    801063e9 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
801063c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063c3:	89 04 24             	mov    %eax,(%esp)
801063c6:	e8 7d ff ff ff       	call   80106348 <fdalloc>
801063cb:	89 45 f4             	mov    %eax,-0xc(%ebp)
801063ce:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801063d2:	79 07                	jns    801063db <sys_dup+0x47>
    return -1;
801063d4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063d9:	eb 0e                	jmp    801063e9 <sys_dup+0x55>
  filedup(f);
801063db:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063de:	89 04 24             	mov    %eax,(%esp)
801063e1:	e8 58 ac ff ff       	call   8010103e <filedup>
  return fd;
801063e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801063e9:	c9                   	leave  
801063ea:	c3                   	ret    

801063eb <sys_read>:

int
sys_read(void)
{
801063eb:	55                   	push   %ebp
801063ec:	89 e5                	mov    %esp,%ebp
801063ee:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801063f1:	8d 45 f4             	lea    -0xc(%ebp),%eax
801063f4:	89 44 24 08          	mov    %eax,0x8(%esp)
801063f8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801063ff:	00 
80106400:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106407:	e8 c7 fe ff ff       	call   801062d3 <argfd>
8010640c:	85 c0                	test   %eax,%eax
8010640e:	78 35                	js     80106445 <sys_read+0x5a>
80106410:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106413:	89 44 24 04          	mov    %eax,0x4(%esp)
80106417:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010641e:	e8 5a fd ff ff       	call   8010617d <argint>
80106423:	85 c0                	test   %eax,%eax
80106425:	78 1e                	js     80106445 <sys_read+0x5a>
80106427:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010642a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010642e:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106431:	89 44 24 04          	mov    %eax,0x4(%esp)
80106435:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010643c:	e8 6a fd ff ff       	call   801061ab <argptr>
80106441:	85 c0                	test   %eax,%eax
80106443:	79 07                	jns    8010644c <sys_read+0x61>
    return -1;
80106445:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010644a:	eb 19                	jmp    80106465 <sys_read+0x7a>
  return fileread(f, p, n);
8010644c:	8b 4d f0             	mov    -0x10(%ebp),%ecx
8010644f:	8b 55 ec             	mov    -0x14(%ebp),%edx
80106452:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106455:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106459:	89 54 24 04          	mov    %edx,0x4(%esp)
8010645d:	89 04 24             	mov    %eax,(%esp)
80106460:	e8 46 ad ff ff       	call   801011ab <fileread>
}
80106465:	c9                   	leave  
80106466:	c3                   	ret    

80106467 <sys_write>:

int
sys_write(void)
{
80106467:	55                   	push   %ebp
80106468:	89 e5                	mov    %esp,%ebp
8010646a:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010646d:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106470:	89 44 24 08          	mov    %eax,0x8(%esp)
80106474:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010647b:	00 
8010647c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106483:	e8 4b fe ff ff       	call   801062d3 <argfd>
80106488:	85 c0                	test   %eax,%eax
8010648a:	78 35                	js     801064c1 <sys_write+0x5a>
8010648c:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010648f:	89 44 24 04          	mov    %eax,0x4(%esp)
80106493:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
8010649a:	e8 de fc ff ff       	call   8010617d <argint>
8010649f:	85 c0                	test   %eax,%eax
801064a1:	78 1e                	js     801064c1 <sys_write+0x5a>
801064a3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801064a6:	89 44 24 08          	mov    %eax,0x8(%esp)
801064aa:	8d 45 ec             	lea    -0x14(%ebp),%eax
801064ad:	89 44 24 04          	mov    %eax,0x4(%esp)
801064b1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801064b8:	e8 ee fc ff ff       	call   801061ab <argptr>
801064bd:	85 c0                	test   %eax,%eax
801064bf:	79 07                	jns    801064c8 <sys_write+0x61>
    return -1;
801064c1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064c6:	eb 19                	jmp    801064e1 <sys_write+0x7a>
  return filewrite(f, p, n);
801064c8:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801064cb:	8b 55 ec             	mov    -0x14(%ebp),%edx
801064ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064d1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801064d5:	89 54 24 04          	mov    %edx,0x4(%esp)
801064d9:	89 04 24             	mov    %eax,(%esp)
801064dc:	e8 86 ad ff ff       	call   80101267 <filewrite>
}
801064e1:	c9                   	leave  
801064e2:	c3                   	ret    

801064e3 <sys_close>:

int
sys_close(void)
{
801064e3:	55                   	push   %ebp
801064e4:	89 e5                	mov    %esp,%ebp
801064e6:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
801064e9:	8d 45 f0             	lea    -0x10(%ebp),%eax
801064ec:	89 44 24 08          	mov    %eax,0x8(%esp)
801064f0:	8d 45 f4             	lea    -0xc(%ebp),%eax
801064f3:	89 44 24 04          	mov    %eax,0x4(%esp)
801064f7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801064fe:	e8 d0 fd ff ff       	call   801062d3 <argfd>
80106503:	85 c0                	test   %eax,%eax
80106505:	79 07                	jns    8010650e <sys_close+0x2b>
    return -1;
80106507:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010650c:	eb 24                	jmp    80106532 <sys_close+0x4f>
  proc->ofile[fd] = 0;
8010650e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106514:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106517:	83 c2 08             	add    $0x8,%edx
8010651a:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80106521:	00 
  fileclose(f);
80106522:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106525:	89 04 24             	mov    %eax,(%esp)
80106528:	e8 59 ab ff ff       	call   80101086 <fileclose>
  return 0;
8010652d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106532:	c9                   	leave  
80106533:	c3                   	ret    

80106534 <sys_fstat>:

int
sys_fstat(void)
{
80106534:	55                   	push   %ebp
80106535:	89 e5                	mov    %esp,%ebp
80106537:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
8010653a:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010653d:	89 44 24 08          	mov    %eax,0x8(%esp)
80106541:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106548:	00 
80106549:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106550:	e8 7e fd ff ff       	call   801062d3 <argfd>
80106555:	85 c0                	test   %eax,%eax
80106557:	78 1f                	js     80106578 <sys_fstat+0x44>
80106559:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80106560:	00 
80106561:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106564:	89 44 24 04          	mov    %eax,0x4(%esp)
80106568:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010656f:	e8 37 fc ff ff       	call   801061ab <argptr>
80106574:	85 c0                	test   %eax,%eax
80106576:	79 07                	jns    8010657f <sys_fstat+0x4b>
    return -1;
80106578:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010657d:	eb 12                	jmp    80106591 <sys_fstat+0x5d>
  return filestat(f, st);
8010657f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80106582:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106585:	89 54 24 04          	mov    %edx,0x4(%esp)
80106589:	89 04 24             	mov    %eax,(%esp)
8010658c:	e8 cb ab ff ff       	call   8010115c <filestat>
}
80106591:	c9                   	leave  
80106592:	c3                   	ret    

80106593 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
80106593:	55                   	push   %ebp
80106594:	89 e5                	mov    %esp,%ebp
80106596:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80106599:	8d 45 d8             	lea    -0x28(%ebp),%eax
8010659c:	89 44 24 04          	mov    %eax,0x4(%esp)
801065a0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801065a7:	e8 61 fc ff ff       	call   8010620d <argstr>
801065ac:	85 c0                	test   %eax,%eax
801065ae:	78 17                	js     801065c7 <sys_link+0x34>
801065b0:	8d 45 dc             	lea    -0x24(%ebp),%eax
801065b3:	89 44 24 04          	mov    %eax,0x4(%esp)
801065b7:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801065be:	e8 4a fc ff ff       	call   8010620d <argstr>
801065c3:	85 c0                	test   %eax,%eax
801065c5:	79 0a                	jns    801065d1 <sys_link+0x3e>
    return -1;
801065c7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801065cc:	e9 42 01 00 00       	jmp    80106713 <sys_link+0x180>

  begin_op();
801065d1:	e8 0d d0 ff ff       	call   801035e3 <begin_op>
  if((ip = namei(old)) == 0){
801065d6:	8b 45 d8             	mov    -0x28(%ebp),%eax
801065d9:	89 04 24             	mov    %eax,(%esp)
801065dc:	e8 f8 bf ff ff       	call   801025d9 <namei>
801065e1:	89 45 f4             	mov    %eax,-0xc(%ebp)
801065e4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801065e8:	75 0f                	jne    801065f9 <sys_link+0x66>
    end_op();
801065ea:	e8 78 d0 ff ff       	call   80103667 <end_op>
    return -1;
801065ef:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801065f4:	e9 1a 01 00 00       	jmp    80106713 <sys_link+0x180>
  }

  ilock(ip);
801065f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065fc:	89 04 24             	mov    %eax,(%esp)
801065ff:	e8 0f b3 ff ff       	call   80101913 <ilock>
  if(ip->type == T_DIR){
80106604:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106607:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010660b:	66 83 f8 01          	cmp    $0x1,%ax
8010660f:	75 1a                	jne    8010662b <sys_link+0x98>
    iunlockput(ip);
80106611:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106614:	89 04 24             	mov    %eax,(%esp)
80106617:	e8 7b b5 ff ff       	call   80101b97 <iunlockput>
    end_op();
8010661c:	e8 46 d0 ff ff       	call   80103667 <end_op>
    return -1;
80106621:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106626:	e9 e8 00 00 00       	jmp    80106713 <sys_link+0x180>
  }

  ip->nlink++;
8010662b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010662e:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106632:	8d 50 01             	lea    0x1(%eax),%edx
80106635:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106638:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
8010663c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010663f:	89 04 24             	mov    %eax,(%esp)
80106642:	e8 10 b1 ff ff       	call   80101757 <iupdate>
  iunlock(ip);
80106647:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010664a:	89 04 24             	mov    %eax,(%esp)
8010664d:	e8 0f b4 ff ff       	call   80101a61 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
80106652:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106655:	8d 55 e2             	lea    -0x1e(%ebp),%edx
80106658:	89 54 24 04          	mov    %edx,0x4(%esp)
8010665c:	89 04 24             	mov    %eax,(%esp)
8010665f:	e8 97 bf ff ff       	call   801025fb <nameiparent>
80106664:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106667:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010666b:	75 02                	jne    8010666f <sys_link+0xdc>
    goto bad;
8010666d:	eb 68                	jmp    801066d7 <sys_link+0x144>
  ilock(dp);
8010666f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106672:	89 04 24             	mov    %eax,(%esp)
80106675:	e8 99 b2 ff ff       	call   80101913 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
8010667a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010667d:	8b 10                	mov    (%eax),%edx
8010667f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106682:	8b 00                	mov    (%eax),%eax
80106684:	39 c2                	cmp    %eax,%edx
80106686:	75 20                	jne    801066a8 <sys_link+0x115>
80106688:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010668b:	8b 40 04             	mov    0x4(%eax),%eax
8010668e:	89 44 24 08          	mov    %eax,0x8(%esp)
80106692:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80106695:	89 44 24 04          	mov    %eax,0x4(%esp)
80106699:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010669c:	89 04 24             	mov    %eax,(%esp)
8010669f:	e8 34 bc ff ff       	call   801022d8 <dirlink>
801066a4:	85 c0                	test   %eax,%eax
801066a6:	79 0d                	jns    801066b5 <sys_link+0x122>
    iunlockput(dp);
801066a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066ab:	89 04 24             	mov    %eax,(%esp)
801066ae:	e8 e4 b4 ff ff       	call   80101b97 <iunlockput>
    goto bad;
801066b3:	eb 22                	jmp    801066d7 <sys_link+0x144>
  }
  iunlockput(dp);
801066b5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066b8:	89 04 24             	mov    %eax,(%esp)
801066bb:	e8 d7 b4 ff ff       	call   80101b97 <iunlockput>
  iput(ip);
801066c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066c3:	89 04 24             	mov    %eax,(%esp)
801066c6:	e8 fb b3 ff ff       	call   80101ac6 <iput>

  end_op();
801066cb:	e8 97 cf ff ff       	call   80103667 <end_op>

  return 0;
801066d0:	b8 00 00 00 00       	mov    $0x0,%eax
801066d5:	eb 3c                	jmp    80106713 <sys_link+0x180>

bad:
  ilock(ip);
801066d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066da:	89 04 24             	mov    %eax,(%esp)
801066dd:	e8 31 b2 ff ff       	call   80101913 <ilock>
  ip->nlink--;
801066e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066e5:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801066e9:	8d 50 ff             	lea    -0x1(%eax),%edx
801066ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066ef:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801066f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801066f6:	89 04 24             	mov    %eax,(%esp)
801066f9:	e8 59 b0 ff ff       	call   80101757 <iupdate>
  iunlockput(ip);
801066fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106701:	89 04 24             	mov    %eax,(%esp)
80106704:	e8 8e b4 ff ff       	call   80101b97 <iunlockput>
  end_op();
80106709:	e8 59 cf ff ff       	call   80103667 <end_op>
  return -1;
8010670e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106713:	c9                   	leave  
80106714:	c3                   	ret    

80106715 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80106715:	55                   	push   %ebp
80106716:	89 e5                	mov    %esp,%ebp
80106718:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
8010671b:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
80106722:	eb 4b                	jmp    8010676f <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80106724:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106727:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010672e:	00 
8010672f:	89 44 24 08          	mov    %eax,0x8(%esp)
80106733:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106736:	89 44 24 04          	mov    %eax,0x4(%esp)
8010673a:	8b 45 08             	mov    0x8(%ebp),%eax
8010673d:	89 04 24             	mov    %eax,(%esp)
80106740:	e8 db b6 ff ff       	call   80101e20 <readi>
80106745:	83 f8 10             	cmp    $0x10,%eax
80106748:	74 0c                	je     80106756 <isdirempty+0x41>
      panic("isdirempty: readi");
8010674a:	c7 04 24 ed 96 10 80 	movl   $0x801096ed,(%esp)
80106751:	e8 e4 9d ff ff       	call   8010053a <panic>
    if(de.inum != 0)
80106756:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
8010675a:	66 85 c0             	test   %ax,%ax
8010675d:	74 07                	je     80106766 <isdirempty+0x51>
      return 0;
8010675f:	b8 00 00 00 00       	mov    $0x0,%eax
80106764:	eb 1b                	jmp    80106781 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80106766:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106769:	83 c0 10             	add    $0x10,%eax
8010676c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010676f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106772:	8b 45 08             	mov    0x8(%ebp),%eax
80106775:	8b 40 18             	mov    0x18(%eax),%eax
80106778:	39 c2                	cmp    %eax,%edx
8010677a:	72 a8                	jb     80106724 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
8010677c:	b8 01 00 00 00       	mov    $0x1,%eax
}
80106781:	c9                   	leave  
80106782:	c3                   	ret    

80106783 <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
80106783:	55                   	push   %ebp
80106784:	89 e5                	mov    %esp,%ebp
80106786:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80106789:	8d 45 cc             	lea    -0x34(%ebp),%eax
8010678c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106790:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106797:	e8 71 fa ff ff       	call   8010620d <argstr>
8010679c:	85 c0                	test   %eax,%eax
8010679e:	79 0a                	jns    801067aa <sys_unlink+0x27>
    return -1;
801067a0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067a5:	e9 af 01 00 00       	jmp    80106959 <sys_unlink+0x1d6>

  begin_op();
801067aa:	e8 34 ce ff ff       	call   801035e3 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
801067af:	8b 45 cc             	mov    -0x34(%ebp),%eax
801067b2:	8d 55 d2             	lea    -0x2e(%ebp),%edx
801067b5:	89 54 24 04          	mov    %edx,0x4(%esp)
801067b9:	89 04 24             	mov    %eax,(%esp)
801067bc:	e8 3a be ff ff       	call   801025fb <nameiparent>
801067c1:	89 45 f4             	mov    %eax,-0xc(%ebp)
801067c4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801067c8:	75 0f                	jne    801067d9 <sys_unlink+0x56>
    end_op();
801067ca:	e8 98 ce ff ff       	call   80103667 <end_op>
    return -1;
801067cf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067d4:	e9 80 01 00 00       	jmp    80106959 <sys_unlink+0x1d6>
  }

  ilock(dp);
801067d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067dc:	89 04 24             	mov    %eax,(%esp)
801067df:	e8 2f b1 ff ff       	call   80101913 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
801067e4:	c7 44 24 04 ff 96 10 	movl   $0x801096ff,0x4(%esp)
801067eb:	80 
801067ec:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801067ef:	89 04 24             	mov    %eax,(%esp)
801067f2:	e8 2f b9 ff ff       	call   80102126 <namecmp>
801067f7:	85 c0                	test   %eax,%eax
801067f9:	0f 84 45 01 00 00    	je     80106944 <sys_unlink+0x1c1>
801067ff:	c7 44 24 04 01 97 10 	movl   $0x80109701,0x4(%esp)
80106806:	80 
80106807:	8d 45 d2             	lea    -0x2e(%ebp),%eax
8010680a:	89 04 24             	mov    %eax,(%esp)
8010680d:	e8 14 b9 ff ff       	call   80102126 <namecmp>
80106812:	85 c0                	test   %eax,%eax
80106814:	0f 84 2a 01 00 00    	je     80106944 <sys_unlink+0x1c1>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
8010681a:	8d 45 c8             	lea    -0x38(%ebp),%eax
8010681d:	89 44 24 08          	mov    %eax,0x8(%esp)
80106821:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80106824:	89 44 24 04          	mov    %eax,0x4(%esp)
80106828:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010682b:	89 04 24             	mov    %eax,(%esp)
8010682e:	e8 15 b9 ff ff       	call   80102148 <dirlookup>
80106833:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106836:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010683a:	75 05                	jne    80106841 <sys_unlink+0xbe>
    goto bad;
8010683c:	e9 03 01 00 00       	jmp    80106944 <sys_unlink+0x1c1>
  ilock(ip);
80106841:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106844:	89 04 24             	mov    %eax,(%esp)
80106847:	e8 c7 b0 ff ff       	call   80101913 <ilock>

  if(ip->nlink < 1)
8010684c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010684f:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106853:	66 85 c0             	test   %ax,%ax
80106856:	7f 0c                	jg     80106864 <sys_unlink+0xe1>
    panic("unlink: nlink < 1");
80106858:	c7 04 24 04 97 10 80 	movl   $0x80109704,(%esp)
8010685f:	e8 d6 9c ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80106864:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106867:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010686b:	66 83 f8 01          	cmp    $0x1,%ax
8010686f:	75 1f                	jne    80106890 <sys_unlink+0x10d>
80106871:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106874:	89 04 24             	mov    %eax,(%esp)
80106877:	e8 99 fe ff ff       	call   80106715 <isdirempty>
8010687c:	85 c0                	test   %eax,%eax
8010687e:	75 10                	jne    80106890 <sys_unlink+0x10d>
    iunlockput(ip);
80106880:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106883:	89 04 24             	mov    %eax,(%esp)
80106886:	e8 0c b3 ff ff       	call   80101b97 <iunlockput>
    goto bad;
8010688b:	e9 b4 00 00 00       	jmp    80106944 <sys_unlink+0x1c1>
  }

  memset(&de, 0, sizeof(de));
80106890:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80106897:	00 
80106898:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010689f:	00 
801068a0:	8d 45 e0             	lea    -0x20(%ebp),%eax
801068a3:	89 04 24             	mov    %eax,(%esp)
801068a6:	e8 7f f4 ff ff       	call   80105d2a <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801068ab:	8b 45 c8             	mov    -0x38(%ebp),%eax
801068ae:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801068b5:	00 
801068b6:	89 44 24 08          	mov    %eax,0x8(%esp)
801068ba:	8d 45 e0             	lea    -0x20(%ebp),%eax
801068bd:	89 44 24 04          	mov    %eax,0x4(%esp)
801068c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068c4:	89 04 24             	mov    %eax,(%esp)
801068c7:	e8 c5 b6 ff ff       	call   80101f91 <writei>
801068cc:	83 f8 10             	cmp    $0x10,%eax
801068cf:	74 0c                	je     801068dd <sys_unlink+0x15a>
    panic("unlink: writei");
801068d1:	c7 04 24 16 97 10 80 	movl   $0x80109716,(%esp)
801068d8:	e8 5d 9c ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR){
801068dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068e0:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801068e4:	66 83 f8 01          	cmp    $0x1,%ax
801068e8:	75 1c                	jne    80106906 <sys_unlink+0x183>
    dp->nlink--;
801068ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068ed:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801068f1:	8d 50 ff             	lea    -0x1(%eax),%edx
801068f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068f7:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
801068fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068fe:	89 04 24             	mov    %eax,(%esp)
80106901:	e8 51 ae ff ff       	call   80101757 <iupdate>
  }
  iunlockput(dp);
80106906:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106909:	89 04 24             	mov    %eax,(%esp)
8010690c:	e8 86 b2 ff ff       	call   80101b97 <iunlockput>

  ip->nlink--;
80106911:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106914:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106918:	8d 50 ff             	lea    -0x1(%eax),%edx
8010691b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010691e:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80106922:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106925:	89 04 24             	mov    %eax,(%esp)
80106928:	e8 2a ae ff ff       	call   80101757 <iupdate>
  iunlockput(ip);
8010692d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106930:	89 04 24             	mov    %eax,(%esp)
80106933:	e8 5f b2 ff ff       	call   80101b97 <iunlockput>

  end_op();
80106938:	e8 2a cd ff ff       	call   80103667 <end_op>

  return 0;
8010693d:	b8 00 00 00 00       	mov    $0x0,%eax
80106942:	eb 15                	jmp    80106959 <sys_unlink+0x1d6>

bad:
  iunlockput(dp);
80106944:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106947:	89 04 24             	mov    %eax,(%esp)
8010694a:	e8 48 b2 ff ff       	call   80101b97 <iunlockput>
  end_op();
8010694f:	e8 13 cd ff ff       	call   80103667 <end_op>
  return -1;
80106954:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80106959:	c9                   	leave  
8010695a:	c3                   	ret    

8010695b <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
8010695b:	55                   	push   %ebp
8010695c:	89 e5                	mov    %esp,%ebp
8010695e:	83 ec 48             	sub    $0x48,%esp
80106961:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80106964:	8b 55 10             	mov    0x10(%ebp),%edx
80106967:	8b 45 14             	mov    0x14(%ebp),%eax
8010696a:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
8010696e:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80106972:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80106976:	8d 45 de             	lea    -0x22(%ebp),%eax
80106979:	89 44 24 04          	mov    %eax,0x4(%esp)
8010697d:	8b 45 08             	mov    0x8(%ebp),%eax
80106980:	89 04 24             	mov    %eax,(%esp)
80106983:	e8 73 bc ff ff       	call   801025fb <nameiparent>
80106988:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010698b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010698f:	75 0a                	jne    8010699b <create+0x40>
    return 0;
80106991:	b8 00 00 00 00       	mov    $0x0,%eax
80106996:	e9 a0 01 00 00       	jmp    80106b3b <create+0x1e0>
  ilock(dp);
8010699b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010699e:	89 04 24             	mov    %eax,(%esp)
801069a1:	e8 6d af ff ff       	call   80101913 <ilock>

  if (dp->type == T_DEV) {
801069a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069a9:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801069ad:	66 83 f8 03          	cmp    $0x3,%ax
801069b1:	75 15                	jne    801069c8 <create+0x6d>
    iunlockput(dp);
801069b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069b6:	89 04 24             	mov    %eax,(%esp)
801069b9:	e8 d9 b1 ff ff       	call   80101b97 <iunlockput>
    return 0;
801069be:	b8 00 00 00 00       	mov    $0x0,%eax
801069c3:	e9 73 01 00 00       	jmp    80106b3b <create+0x1e0>
  }

  if((ip = dirlookup(dp, name, &off)) != 0){
801069c8:	8d 45 ec             	lea    -0x14(%ebp),%eax
801069cb:	89 44 24 08          	mov    %eax,0x8(%esp)
801069cf:	8d 45 de             	lea    -0x22(%ebp),%eax
801069d2:	89 44 24 04          	mov    %eax,0x4(%esp)
801069d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069d9:	89 04 24             	mov    %eax,(%esp)
801069dc:	e8 67 b7 ff ff       	call   80102148 <dirlookup>
801069e1:	89 45 f0             	mov    %eax,-0x10(%ebp)
801069e4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801069e8:	74 47                	je     80106a31 <create+0xd6>
    iunlockput(dp);
801069ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069ed:	89 04 24             	mov    %eax,(%esp)
801069f0:	e8 a2 b1 ff ff       	call   80101b97 <iunlockput>
    ilock(ip);
801069f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801069f8:	89 04 24             	mov    %eax,(%esp)
801069fb:	e8 13 af ff ff       	call   80101913 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80106a00:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80106a05:	75 15                	jne    80106a1c <create+0xc1>
80106a07:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a0a:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106a0e:	66 83 f8 02          	cmp    $0x2,%ax
80106a12:	75 08                	jne    80106a1c <create+0xc1>
      return ip;
80106a14:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a17:	e9 1f 01 00 00       	jmp    80106b3b <create+0x1e0>
    iunlockput(ip);
80106a1c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a1f:	89 04 24             	mov    %eax,(%esp)
80106a22:	e8 70 b1 ff ff       	call   80101b97 <iunlockput>
    return 0;
80106a27:	b8 00 00 00 00       	mov    $0x0,%eax
80106a2c:	e9 0a 01 00 00       	jmp    80106b3b <create+0x1e0>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
80106a31:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80106a35:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a38:	8b 00                	mov    (%eax),%eax
80106a3a:	89 54 24 04          	mov    %edx,0x4(%esp)
80106a3e:	89 04 24             	mov    %eax,(%esp)
80106a41:	e8 32 ac ff ff       	call   80101678 <ialloc>
80106a46:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106a49:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106a4d:	75 0c                	jne    80106a5b <create+0x100>
    panic("create: ialloc");
80106a4f:	c7 04 24 25 97 10 80 	movl   $0x80109725,(%esp)
80106a56:	e8 df 9a ff ff       	call   8010053a <panic>

  ilock(ip);
80106a5b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a5e:	89 04 24             	mov    %eax,(%esp)
80106a61:	e8 ad ae ff ff       	call   80101913 <ilock>
  ip->major = major;
80106a66:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a69:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80106a6d:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80106a71:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a74:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80106a78:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80106a7c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a7f:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80106a85:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106a88:	89 04 24             	mov    %eax,(%esp)
80106a8b:	e8 c7 ac ff ff       	call   80101757 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80106a90:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80106a95:	75 6a                	jne    80106b01 <create+0x1a6>
    dp->nlink++;  // for ".."
80106a97:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a9a:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80106a9e:	8d 50 01             	lea    0x1(%eax),%edx
80106aa1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106aa4:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106aa8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106aab:	89 04 24             	mov    %eax,(%esp)
80106aae:	e8 a4 ac ff ff       	call   80101757 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80106ab3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ab6:	8b 40 04             	mov    0x4(%eax),%eax
80106ab9:	89 44 24 08          	mov    %eax,0x8(%esp)
80106abd:	c7 44 24 04 ff 96 10 	movl   $0x801096ff,0x4(%esp)
80106ac4:	80 
80106ac5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ac8:	89 04 24             	mov    %eax,(%esp)
80106acb:	e8 08 b8 ff ff       	call   801022d8 <dirlink>
80106ad0:	85 c0                	test   %eax,%eax
80106ad2:	78 21                	js     80106af5 <create+0x19a>
80106ad4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106ad7:	8b 40 04             	mov    0x4(%eax),%eax
80106ada:	89 44 24 08          	mov    %eax,0x8(%esp)
80106ade:	c7 44 24 04 01 97 10 	movl   $0x80109701,0x4(%esp)
80106ae5:	80 
80106ae6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ae9:	89 04 24             	mov    %eax,(%esp)
80106aec:	e8 e7 b7 ff ff       	call   801022d8 <dirlink>
80106af1:	85 c0                	test   %eax,%eax
80106af3:	79 0c                	jns    80106b01 <create+0x1a6>
      panic("create dots");
80106af5:	c7 04 24 34 97 10 80 	movl   $0x80109734,(%esp)
80106afc:	e8 39 9a ff ff       	call   8010053a <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80106b01:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106b04:	8b 40 04             	mov    0x4(%eax),%eax
80106b07:	89 44 24 08          	mov    %eax,0x8(%esp)
80106b0b:	8d 45 de             	lea    -0x22(%ebp),%eax
80106b0e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b12:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b15:	89 04 24             	mov    %eax,(%esp)
80106b18:	e8 bb b7 ff ff       	call   801022d8 <dirlink>
80106b1d:	85 c0                	test   %eax,%eax
80106b1f:	79 0c                	jns    80106b2d <create+0x1d2>
    panic("create: dirlink");
80106b21:	c7 04 24 40 97 10 80 	movl   $0x80109740,(%esp)
80106b28:	e8 0d 9a ff ff       	call   8010053a <panic>

  iunlockput(dp);
80106b2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106b30:	89 04 24             	mov    %eax,(%esp)
80106b33:	e8 5f b0 ff ff       	call   80101b97 <iunlockput>

  return ip;
80106b38:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80106b3b:	c9                   	leave  
80106b3c:	c3                   	ret    

80106b3d <sys_open>:

int
sys_open(void)
{
80106b3d:	55                   	push   %ebp
80106b3e:	89 e5                	mov    %esp,%ebp
80106b40:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80106b43:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106b46:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b4a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106b51:	e8 b7 f6 ff ff       	call   8010620d <argstr>
80106b56:	85 c0                	test   %eax,%eax
80106b58:	78 17                	js     80106b71 <sys_open+0x34>
80106b5a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106b5d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106b61:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106b68:	e8 10 f6 ff ff       	call   8010617d <argint>
80106b6d:	85 c0                	test   %eax,%eax
80106b6f:	79 0a                	jns    80106b7b <sys_open+0x3e>
    return -1;
80106b71:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106b76:	e9 5c 01 00 00       	jmp    80106cd7 <sys_open+0x19a>

  begin_op();
80106b7b:	e8 63 ca ff ff       	call   801035e3 <begin_op>

  if(omode & O_CREATE){
80106b80:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106b83:	25 00 02 00 00       	and    $0x200,%eax
80106b88:	85 c0                	test   %eax,%eax
80106b8a:	74 3b                	je     80106bc7 <sys_open+0x8a>
    ip = create(path, T_FILE, 0, 0);
80106b8c:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106b8f:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106b96:	00 
80106b97:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106b9e:	00 
80106b9f:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106ba6:	00 
80106ba7:	89 04 24             	mov    %eax,(%esp)
80106baa:	e8 ac fd ff ff       	call   8010695b <create>
80106baf:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(ip == 0){
80106bb2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106bb6:	75 6b                	jne    80106c23 <sys_open+0xe6>
      end_op();
80106bb8:	e8 aa ca ff ff       	call   80103667 <end_op>
      return -1;
80106bbd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106bc2:	e9 10 01 00 00       	jmp    80106cd7 <sys_open+0x19a>
    }
  } else {
    if((ip = namei(path)) == 0){
80106bc7:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106bca:	89 04 24             	mov    %eax,(%esp)
80106bcd:	e8 07 ba ff ff       	call   801025d9 <namei>
80106bd2:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106bd5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106bd9:	75 0f                	jne    80106bea <sys_open+0xad>
      end_op();
80106bdb:	e8 87 ca ff ff       	call   80103667 <end_op>
      return -1;
80106be0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106be5:	e9 ed 00 00 00       	jmp    80106cd7 <sys_open+0x19a>
    }
    ilock(ip);
80106bea:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bed:	89 04 24             	mov    %eax,(%esp)
80106bf0:	e8 1e ad ff ff       	call   80101913 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80106bf5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106bf8:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106bfc:	66 83 f8 01          	cmp    $0x1,%ax
80106c00:	75 21                	jne    80106c23 <sys_open+0xe6>
80106c02:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106c05:	85 c0                	test   %eax,%eax
80106c07:	74 1a                	je     80106c23 <sys_open+0xe6>
      iunlockput(ip);
80106c09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c0c:	89 04 24             	mov    %eax,(%esp)
80106c0f:	e8 83 af ff ff       	call   80101b97 <iunlockput>
      end_op();
80106c14:	e8 4e ca ff ff       	call   80103667 <end_op>
      return -1;
80106c19:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c1e:	e9 b4 00 00 00       	jmp    80106cd7 <sys_open+0x19a>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80106c23:	e8 b6 a3 ff ff       	call   80100fde <filealloc>
80106c28:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106c2b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106c2f:	74 14                	je     80106c45 <sys_open+0x108>
80106c31:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c34:	89 04 24             	mov    %eax,(%esp)
80106c37:	e8 0c f7 ff ff       	call   80106348 <fdalloc>
80106c3c:	89 45 ec             	mov    %eax,-0x14(%ebp)
80106c3f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80106c43:	79 28                	jns    80106c6d <sys_open+0x130>
    if(f)
80106c45:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106c49:	74 0b                	je     80106c56 <sys_open+0x119>
      fileclose(f);
80106c4b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c4e:	89 04 24             	mov    %eax,(%esp)
80106c51:	e8 30 a4 ff ff       	call   80101086 <fileclose>
    iunlockput(ip);
80106c56:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c59:	89 04 24             	mov    %eax,(%esp)
80106c5c:	e8 36 af ff ff       	call   80101b97 <iunlockput>
    end_op();
80106c61:	e8 01 ca ff ff       	call   80103667 <end_op>
    return -1;
80106c66:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106c6b:	eb 6a                	jmp    80106cd7 <sys_open+0x19a>
  }
  iunlock(ip);
80106c6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c70:	89 04 24             	mov    %eax,(%esp)
80106c73:	e8 e9 ad ff ff       	call   80101a61 <iunlock>
  end_op();
80106c78:	e8 ea c9 ff ff       	call   80103667 <end_op>

  f->type = FD_INODE;
80106c7d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c80:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106c86:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c89:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106c8c:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80106c8f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106c92:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106c99:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106c9c:	83 e0 01             	and    $0x1,%eax
80106c9f:	85 c0                	test   %eax,%eax
80106ca1:	0f 94 c0             	sete   %al
80106ca4:	89 c2                	mov    %eax,%edx
80106ca6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106ca9:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106cac:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106caf:	83 e0 01             	and    $0x1,%eax
80106cb2:	85 c0                	test   %eax,%eax
80106cb4:	75 0a                	jne    80106cc0 <sys_open+0x183>
80106cb6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106cb9:	83 e0 02             	and    $0x2,%eax
80106cbc:	85 c0                	test   %eax,%eax
80106cbe:	74 07                	je     80106cc7 <sys_open+0x18a>
80106cc0:	b8 01 00 00 00       	mov    $0x1,%eax
80106cc5:	eb 05                	jmp    80106ccc <sys_open+0x18f>
80106cc7:	b8 00 00 00 00       	mov    $0x0,%eax
80106ccc:	89 c2                	mov    %eax,%edx
80106cce:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106cd1:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80106cd4:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80106cd7:	c9                   	leave  
80106cd8:	c3                   	ret    

80106cd9 <sys_mkdir>:

int
sys_mkdir(void)
{
80106cd9:	55                   	push   %ebp
80106cda:	89 e5                	mov    %esp,%ebp
80106cdc:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
80106cdf:	e8 ff c8 ff ff       	call   801035e3 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80106ce4:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106ce7:	89 44 24 04          	mov    %eax,0x4(%esp)
80106ceb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106cf2:	e8 16 f5 ff ff       	call   8010620d <argstr>
80106cf7:	85 c0                	test   %eax,%eax
80106cf9:	78 2c                	js     80106d27 <sys_mkdir+0x4e>
80106cfb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106cfe:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80106d05:	00 
80106d06:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106d0d:	00 
80106d0e:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106d15:	00 
80106d16:	89 04 24             	mov    %eax,(%esp)
80106d19:	e8 3d fc ff ff       	call   8010695b <create>
80106d1e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106d21:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106d25:	75 0c                	jne    80106d33 <sys_mkdir+0x5a>
    end_op();
80106d27:	e8 3b c9 ff ff       	call   80103667 <end_op>
    return -1;
80106d2c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106d31:	eb 15                	jmp    80106d48 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
80106d33:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106d36:	89 04 24             	mov    %eax,(%esp)
80106d39:	e8 59 ae ff ff       	call   80101b97 <iunlockput>
  end_op();
80106d3e:	e8 24 c9 ff ff       	call   80103667 <end_op>
  return 0;
80106d43:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106d48:	c9                   	leave  
80106d49:	c3                   	ret    

80106d4a <sys_mknod>:

int
sys_mknod(void)
{
80106d4a:	55                   	push   %ebp
80106d4b:	89 e5                	mov    %esp,%ebp
80106d4d:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_op();
80106d50:	e8 8e c8 ff ff       	call   801035e3 <begin_op>
  if((len=argstr(0, &path)) < 0 ||
80106d55:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106d58:	89 44 24 04          	mov    %eax,0x4(%esp)
80106d5c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106d63:	e8 a5 f4 ff ff       	call   8010620d <argstr>
80106d68:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106d6b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106d6f:	78 5e                	js     80106dcf <sys_mknod+0x85>
     argint(1, &major) < 0 ||
80106d71:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106d74:	89 44 24 04          	mov    %eax,0x4(%esp)
80106d78:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106d7f:	e8 f9 f3 ff ff       	call   8010617d <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
80106d84:	85 c0                	test   %eax,%eax
80106d86:	78 47                	js     80106dcf <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106d88:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106d8b:	89 44 24 04          	mov    %eax,0x4(%esp)
80106d8f:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106d96:	e8 e2 f3 ff ff       	call   8010617d <argint>
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80106d9b:	85 c0                	test   %eax,%eax
80106d9d:	78 30                	js     80106dcf <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
80106d9f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106da2:	0f bf c8             	movswl %ax,%ecx
80106da5:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106da8:	0f bf d0             	movswl %ax,%edx
80106dab:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106dae:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106db2:	89 54 24 08          	mov    %edx,0x8(%esp)
80106db6:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106dbd:	00 
80106dbe:	89 04 24             	mov    %eax,(%esp)
80106dc1:	e8 95 fb ff ff       	call   8010695b <create>
80106dc6:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106dc9:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106dcd:	75 0c                	jne    80106ddb <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    end_op();
80106dcf:	e8 93 c8 ff ff       	call   80103667 <end_op>
    return -1;
80106dd4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106dd9:	eb 15                	jmp    80106df0 <sys_mknod+0xa6>
  }
  iunlockput(ip);
80106ddb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106dde:	89 04 24             	mov    %eax,(%esp)
80106de1:	e8 b1 ad ff ff       	call   80101b97 <iunlockput>
  end_op();
80106de6:	e8 7c c8 ff ff       	call   80103667 <end_op>
  return 0;
80106deb:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106df0:	c9                   	leave  
80106df1:	c3                   	ret    

80106df2 <sys_chdir>:

int
sys_chdir(void)
{
80106df2:	55                   	push   %ebp
80106df3:	89 e5                	mov    %esp,%ebp
80106df5:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
80106df8:	e8 e6 c7 ff ff       	call   801035e3 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80106dfd:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106e00:	89 44 24 04          	mov    %eax,0x4(%esp)
80106e04:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106e0b:	e8 fd f3 ff ff       	call   8010620d <argstr>
80106e10:	85 c0                	test   %eax,%eax
80106e12:	78 14                	js     80106e28 <sys_chdir+0x36>
80106e14:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106e17:	89 04 24             	mov    %eax,(%esp)
80106e1a:	e8 ba b7 ff ff       	call   801025d9 <namei>
80106e1f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106e22:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106e26:	75 0f                	jne    80106e37 <sys_chdir+0x45>
    end_op();
80106e28:	e8 3a c8 ff ff       	call   80103667 <end_op>
    return -1;
80106e2d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106e32:	e9 a2 00 00 00       	jmp    80106ed9 <sys_chdir+0xe7>
  }
  ilock(ip);
80106e37:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e3a:	89 04 24             	mov    %eax,(%esp)
80106e3d:	e8 d1 aa ff ff       	call   80101913 <ilock>
  if(ip->type != T_DIR && !IS_DEV_DIR(ip)) {
80106e42:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e45:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106e49:	66 83 f8 01          	cmp    $0x1,%ax
80106e4d:	74 58                	je     80106ea7 <sys_chdir+0xb5>
80106e4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e52:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106e56:	66 83 f8 03          	cmp    $0x3,%ax
80106e5a:	75 34                	jne    80106e90 <sys_chdir+0x9e>
80106e5c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e5f:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80106e63:	98                   	cwtl   
80106e64:	c1 e0 04             	shl    $0x4,%eax
80106e67:	05 00 22 11 80       	add    $0x80112200,%eax
80106e6c:	8b 00                	mov    (%eax),%eax
80106e6e:	85 c0                	test   %eax,%eax
80106e70:	74 1e                	je     80106e90 <sys_chdir+0x9e>
80106e72:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e75:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80106e79:	98                   	cwtl   
80106e7a:	c1 e0 04             	shl    $0x4,%eax
80106e7d:	05 00 22 11 80       	add    $0x80112200,%eax
80106e82:	8b 00                	mov    (%eax),%eax
80106e84:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106e87:	89 14 24             	mov    %edx,(%esp)
80106e8a:	ff d0                	call   *%eax
80106e8c:	85 c0                	test   %eax,%eax
80106e8e:	75 17                	jne    80106ea7 <sys_chdir+0xb5>
    iunlockput(ip);
80106e90:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106e93:	89 04 24             	mov    %eax,(%esp)
80106e96:	e8 fc ac ff ff       	call   80101b97 <iunlockput>
    end_op();
80106e9b:	e8 c7 c7 ff ff       	call   80103667 <end_op>
    return -1;
80106ea0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ea5:	eb 32                	jmp    80106ed9 <sys_chdir+0xe7>
  }
  iunlock(ip);
80106ea7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106eaa:	89 04 24             	mov    %eax,(%esp)
80106ead:	e8 af ab ff ff       	call   80101a61 <iunlock>
  iput(proc->cwd);
80106eb2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106eb8:	8b 40 68             	mov    0x68(%eax),%eax
80106ebb:	89 04 24             	mov    %eax,(%esp)
80106ebe:	e8 03 ac ff ff       	call   80101ac6 <iput>
  end_op();
80106ec3:	e8 9f c7 ff ff       	call   80103667 <end_op>
  proc->cwd = ip;
80106ec8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106ece:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106ed1:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80106ed4:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106ed9:	c9                   	leave  
80106eda:	c3                   	ret    

80106edb <sys_exec>:

int
sys_exec(void)
{
80106edb:	55                   	push   %ebp
80106edc:	89 e5                	mov    %esp,%ebp
80106ede:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80106ee4:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106ee7:	89 44 24 04          	mov    %eax,0x4(%esp)
80106eeb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106ef2:	e8 16 f3 ff ff       	call   8010620d <argstr>
80106ef7:	85 c0                	test   %eax,%eax
80106ef9:	78 1a                	js     80106f15 <sys_exec+0x3a>
80106efb:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80106f01:	89 44 24 04          	mov    %eax,0x4(%esp)
80106f05:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80106f0c:	e8 6c f2 ff ff       	call   8010617d <argint>
80106f11:	85 c0                	test   %eax,%eax
80106f13:	79 0a                	jns    80106f1f <sys_exec+0x44>
    return -1;
80106f15:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f1a:	e9 c8 00 00 00       	jmp    80106fe7 <sys_exec+0x10c>
  }
  memset(argv, 0, sizeof(argv));
80106f1f:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80106f26:	00 
80106f27:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106f2e:	00 
80106f2f:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106f35:	89 04 24             	mov    %eax,(%esp)
80106f38:	e8 ed ed ff ff       	call   80105d2a <memset>
  for(i=0;; i++){
80106f3d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80106f44:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f47:	83 f8 1f             	cmp    $0x1f,%eax
80106f4a:	76 0a                	jbe    80106f56 <sys_exec+0x7b>
      return -1;
80106f4c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f51:	e9 91 00 00 00       	jmp    80106fe7 <sys_exec+0x10c>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80106f56:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f59:	c1 e0 02             	shl    $0x2,%eax
80106f5c:	89 c2                	mov    %eax,%edx
80106f5e:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80106f64:	01 c2                	add    %eax,%edx
80106f66:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
80106f6c:	89 44 24 04          	mov    %eax,0x4(%esp)
80106f70:	89 14 24             	mov    %edx,(%esp)
80106f73:	e8 69 f1 ff ff       	call   801060e1 <fetchint>
80106f78:	85 c0                	test   %eax,%eax
80106f7a:	79 07                	jns    80106f83 <sys_exec+0xa8>
      return -1;
80106f7c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106f81:	eb 64                	jmp    80106fe7 <sys_exec+0x10c>
    if(uarg == 0){
80106f83:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106f89:	85 c0                	test   %eax,%eax
80106f8b:	75 26                	jne    80106fb3 <sys_exec+0xd8>
      argv[i] = 0;
80106f8d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f90:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80106f97:	00 00 00 00 
      break;
80106f9b:	90                   	nop
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80106f9c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106f9f:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80106fa5:	89 54 24 04          	mov    %edx,0x4(%esp)
80106fa9:	89 04 24             	mov    %eax,(%esp)
80106fac:	e8 3e 9b ff ff       	call   80100aef <exec>
80106fb1:	eb 34                	jmp    80106fe7 <sys_exec+0x10c>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80106fb3:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106fb9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106fbc:	c1 e2 02             	shl    $0x2,%edx
80106fbf:	01 c2                	add    %eax,%edx
80106fc1:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106fc7:	89 54 24 04          	mov    %edx,0x4(%esp)
80106fcb:	89 04 24             	mov    %eax,(%esp)
80106fce:	e8 48 f1 ff ff       	call   8010611b <fetchstr>
80106fd3:	85 c0                	test   %eax,%eax
80106fd5:	79 07                	jns    80106fde <sys_exec+0x103>
      return -1;
80106fd7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106fdc:	eb 09                	jmp    80106fe7 <sys_exec+0x10c>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
80106fde:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
80106fe2:	e9 5d ff ff ff       	jmp    80106f44 <sys_exec+0x69>
  return exec(path, argv);
}
80106fe7:	c9                   	leave  
80106fe8:	c3                   	ret    

80106fe9 <sys_pipe>:

int
sys_pipe(void)
{
80106fe9:	55                   	push   %ebp
80106fea:	89 e5                	mov    %esp,%ebp
80106fec:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80106fef:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80106ff6:	00 
80106ff7:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106ffa:	89 44 24 04          	mov    %eax,0x4(%esp)
80106ffe:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107005:	e8 a1 f1 ff ff       	call   801061ab <argptr>
8010700a:	85 c0                	test   %eax,%eax
8010700c:	79 0a                	jns    80107018 <sys_pipe+0x2f>
    return -1;
8010700e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107013:	e9 9b 00 00 00       	jmp    801070b3 <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80107018:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010701b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010701f:	8d 45 e8             	lea    -0x18(%ebp),%eax
80107022:	89 04 24             	mov    %eax,(%esp)
80107025:	e8 cf d0 ff ff       	call   801040f9 <pipealloc>
8010702a:	85 c0                	test   %eax,%eax
8010702c:	79 07                	jns    80107035 <sys_pipe+0x4c>
    return -1;
8010702e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107033:	eb 7e                	jmp    801070b3 <sys_pipe+0xca>
  fd0 = -1;
80107035:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
8010703c:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010703f:	89 04 24             	mov    %eax,(%esp)
80107042:	e8 01 f3 ff ff       	call   80106348 <fdalloc>
80107047:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010704a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010704e:	78 14                	js     80107064 <sys_pipe+0x7b>
80107050:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80107053:	89 04 24             	mov    %eax,(%esp)
80107056:	e8 ed f2 ff ff       	call   80106348 <fdalloc>
8010705b:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010705e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107062:	79 37                	jns    8010709b <sys_pipe+0xb2>
    if(fd0 >= 0)
80107064:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107068:	78 14                	js     8010707e <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
8010706a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107070:	8b 55 f4             	mov    -0xc(%ebp),%edx
80107073:	83 c2 08             	add    $0x8,%edx
80107076:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
8010707d:	00 
    fileclose(rf);
8010707e:	8b 45 e8             	mov    -0x18(%ebp),%eax
80107081:	89 04 24             	mov    %eax,(%esp)
80107084:	e8 fd 9f ff ff       	call   80101086 <fileclose>
    fileclose(wf);
80107089:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010708c:	89 04 24             	mov    %eax,(%esp)
8010708f:	e8 f2 9f ff ff       	call   80101086 <fileclose>
    return -1;
80107094:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107099:	eb 18                	jmp    801070b3 <sys_pipe+0xca>
  }
  fd[0] = fd0;
8010709b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010709e:	8b 55 f4             	mov    -0xc(%ebp),%edx
801070a1:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
801070a3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801070a6:	8d 50 04             	lea    0x4(%eax),%edx
801070a9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801070ac:	89 02                	mov    %eax,(%edx)
  return 0;
801070ae:	b8 00 00 00 00       	mov    $0x0,%eax
}
801070b3:	c9                   	leave  
801070b4:	c3                   	ret    

801070b5 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
801070b5:	55                   	push   %ebp
801070b6:	89 e5                	mov    %esp,%ebp
801070b8:	83 ec 08             	sub    $0x8,%esp
  return fork();
801070bb:	e8 e7 d6 ff ff       	call   801047a7 <fork>
}
801070c0:	c9                   	leave  
801070c1:	c3                   	ret    

801070c2 <sys_exit>:

int
sys_exit(void)
{
801070c2:	55                   	push   %ebp
801070c3:	89 e5                	mov    %esp,%ebp
801070c5:	83 ec 08             	sub    $0x8,%esp
  exit();
801070c8:	e8 55 d8 ff ff       	call   80104922 <exit>
  return 0;  // not reached
801070cd:	b8 00 00 00 00       	mov    $0x0,%eax
}
801070d2:	c9                   	leave  
801070d3:	c3                   	ret    

801070d4 <sys_wait>:

int
sys_wait(void)
{
801070d4:	55                   	push   %ebp
801070d5:	89 e5                	mov    %esp,%ebp
801070d7:	83 ec 08             	sub    $0x8,%esp
  return wait();
801070da:	e8 68 d9 ff ff       	call   80104a47 <wait>
}
801070df:	c9                   	leave  
801070e0:	c3                   	ret    

801070e1 <sys_kill>:

int
sys_kill(void)
{
801070e1:	55                   	push   %ebp
801070e2:	89 e5                	mov    %esp,%ebp
801070e4:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
801070e7:	8d 45 f4             	lea    -0xc(%ebp),%eax
801070ea:	89 44 24 04          	mov    %eax,0x4(%esp)
801070ee:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801070f5:	e8 83 f0 ff ff       	call   8010617d <argint>
801070fa:	85 c0                	test   %eax,%eax
801070fc:	79 07                	jns    80107105 <sys_kill+0x24>
    return -1;
801070fe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107103:	eb 0b                	jmp    80107110 <sys_kill+0x2f>
  return kill(pid);
80107105:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107108:	89 04 24             	mov    %eax,(%esp)
8010710b:	e8 fb dc ff ff       	call   80104e0b <kill>
}
80107110:	c9                   	leave  
80107111:	c3                   	ret    

80107112 <sys_getpid>:

int
sys_getpid(void)
{
80107112:	55                   	push   %ebp
80107113:	89 e5                	mov    %esp,%ebp
  return proc->pid;
80107115:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010711b:	8b 40 10             	mov    0x10(%eax),%eax
}
8010711e:	5d                   	pop    %ebp
8010711f:	c3                   	ret    

80107120 <sys_sbrk>:

int
sys_sbrk(void)
{
80107120:	55                   	push   %ebp
80107121:	89 e5                	mov    %esp,%ebp
80107123:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80107126:	8d 45 f0             	lea    -0x10(%ebp),%eax
80107129:	89 44 24 04          	mov    %eax,0x4(%esp)
8010712d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80107134:	e8 44 f0 ff ff       	call   8010617d <argint>
80107139:	85 c0                	test   %eax,%eax
8010713b:	79 07                	jns    80107144 <sys_sbrk+0x24>
    return -1;
8010713d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107142:	eb 24                	jmp    80107168 <sys_sbrk+0x48>
  addr = proc->sz;
80107144:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010714a:	8b 00                	mov    (%eax),%eax
8010714c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
8010714f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107152:	89 04 24             	mov    %eax,(%esp)
80107155:	e8 a8 d5 ff ff       	call   80104702 <growproc>
8010715a:	85 c0                	test   %eax,%eax
8010715c:	79 07                	jns    80107165 <sys_sbrk+0x45>
    return -1;
8010715e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107163:	eb 03                	jmp    80107168 <sys_sbrk+0x48>
  return addr;
80107165:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80107168:	c9                   	leave  
80107169:	c3                   	ret    

8010716a <sys_sleep>:

int
sys_sleep(void)
{
8010716a:	55                   	push   %ebp
8010716b:	89 e5                	mov    %esp,%ebp
8010716d:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
80107170:	8d 45 f0             	lea    -0x10(%ebp),%eax
80107173:	89 44 24 04          	mov    %eax,0x4(%esp)
80107177:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010717e:	e8 fa ef ff ff       	call   8010617d <argint>
80107183:	85 c0                	test   %eax,%eax
80107185:	79 07                	jns    8010718e <sys_sleep+0x24>
    return -1;
80107187:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010718c:	eb 6c                	jmp    801071fa <sys_sleep+0x90>
  acquire(&tickslock);
8010718e:	c7 04 24 00 73 11 80 	movl   $0x80117300,(%esp)
80107195:	e8 3c e9 ff ff       	call   80105ad6 <acquire>
  ticks0 = ticks;
8010719a:	a1 40 7b 11 80       	mov    0x80117b40,%eax
8010719f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
801071a2:	eb 34                	jmp    801071d8 <sys_sleep+0x6e>
    if(proc->killed){
801071a4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801071aa:	8b 40 24             	mov    0x24(%eax),%eax
801071ad:	85 c0                	test   %eax,%eax
801071af:	74 13                	je     801071c4 <sys_sleep+0x5a>
      release(&tickslock);
801071b1:	c7 04 24 00 73 11 80 	movl   $0x80117300,(%esp)
801071b8:	e8 7b e9 ff ff       	call   80105b38 <release>
      return -1;
801071bd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801071c2:	eb 36                	jmp    801071fa <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
801071c4:	c7 44 24 04 00 73 11 	movl   $0x80117300,0x4(%esp)
801071cb:	80 
801071cc:	c7 04 24 40 7b 11 80 	movl   $0x80117b40,(%esp)
801071d3:	e8 2c db ff ff       	call   80104d04 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
801071d8:	a1 40 7b 11 80       	mov    0x80117b40,%eax
801071dd:	2b 45 f4             	sub    -0xc(%ebp),%eax
801071e0:	89 c2                	mov    %eax,%edx
801071e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801071e5:	39 c2                	cmp    %eax,%edx
801071e7:	72 bb                	jb     801071a4 <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
801071e9:	c7 04 24 00 73 11 80 	movl   $0x80117300,(%esp)
801071f0:	e8 43 e9 ff ff       	call   80105b38 <release>
  return 0;
801071f5:	b8 00 00 00 00       	mov    $0x0,%eax
}
801071fa:	c9                   	leave  
801071fb:	c3                   	ret    

801071fc <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
801071fc:	55                   	push   %ebp
801071fd:	89 e5                	mov    %esp,%ebp
801071ff:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
80107202:	c7 04 24 00 73 11 80 	movl   $0x80117300,(%esp)
80107209:	e8 c8 e8 ff ff       	call   80105ad6 <acquire>
  xticks = ticks;
8010720e:	a1 40 7b 11 80       	mov    0x80117b40,%eax
80107213:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80107216:	c7 04 24 00 73 11 80 	movl   $0x80117300,(%esp)
8010721d:	e8 16 e9 ff ff       	call   80105b38 <release>
  return xticks;
80107222:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80107225:	c9                   	leave  
80107226:	c3                   	ret    

80107227 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80107227:	55                   	push   %ebp
80107228:	89 e5                	mov    %esp,%ebp
8010722a:	83 ec 08             	sub    $0x8,%esp
8010722d:	8b 55 08             	mov    0x8(%ebp),%edx
80107230:	8b 45 0c             	mov    0xc(%ebp),%eax
80107233:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80107237:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010723a:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010723e:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80107242:	ee                   	out    %al,(%dx)
}
80107243:	c9                   	leave  
80107244:	c3                   	ret    

80107245 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
80107245:	55                   	push   %ebp
80107246:	89 e5                	mov    %esp,%ebp
80107248:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
8010724b:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
80107252:	00 
80107253:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
8010725a:	e8 c8 ff ff ff       	call   80107227 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
8010725f:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
80107266:	00 
80107267:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
8010726e:	e8 b4 ff ff ff       	call   80107227 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
80107273:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
8010727a:	00 
8010727b:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80107282:	e8 a0 ff ff ff       	call   80107227 <outb>
  picenable(IRQ_TIMER);
80107287:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010728e:	e8 f9 cc ff ff       	call   80103f8c <picenable>
}
80107293:	c9                   	leave  
80107294:	c3                   	ret    

80107295 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80107295:	1e                   	push   %ds
  pushl %es
80107296:	06                   	push   %es
  pushl %fs
80107297:	0f a0                	push   %fs
  pushl %gs
80107299:	0f a8                	push   %gs
  pushal
8010729b:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
8010729c:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
801072a0:	8e d8                	mov    %eax,%ds
  movw %ax, %es
801072a2:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
801072a4:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
801072a8:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
801072aa:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
801072ac:	54                   	push   %esp
  call trap
801072ad:	e8 d8 01 00 00       	call   8010748a <trap>
  addl $4, %esp
801072b2:	83 c4 04             	add    $0x4,%esp

801072b5 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
801072b5:	61                   	popa   
  popl %gs
801072b6:	0f a9                	pop    %gs
  popl %fs
801072b8:	0f a1                	pop    %fs
  popl %es
801072ba:	07                   	pop    %es
  popl %ds
801072bb:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
801072bc:	83 c4 08             	add    $0x8,%esp
  iret
801072bf:	cf                   	iret   

801072c0 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
801072c0:	55                   	push   %ebp
801072c1:	89 e5                	mov    %esp,%ebp
801072c3:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
801072c6:	8b 45 0c             	mov    0xc(%ebp),%eax
801072c9:	83 e8 01             	sub    $0x1,%eax
801072cc:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
801072d0:	8b 45 08             	mov    0x8(%ebp),%eax
801072d3:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801072d7:	8b 45 08             	mov    0x8(%ebp),%eax
801072da:	c1 e8 10             	shr    $0x10,%eax
801072dd:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
801072e1:	8d 45 fa             	lea    -0x6(%ebp),%eax
801072e4:	0f 01 18             	lidtl  (%eax)
}
801072e7:	c9                   	leave  
801072e8:	c3                   	ret    

801072e9 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
801072e9:	55                   	push   %ebp
801072ea:	89 e5                	mov    %esp,%ebp
801072ec:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
801072ef:	0f 20 d0             	mov    %cr2,%eax
801072f2:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return val;
801072f5:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801072f8:	c9                   	leave  
801072f9:	c3                   	ret    

801072fa <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
801072fa:	55                   	push   %ebp
801072fb:	89 e5                	mov    %esp,%ebp
801072fd:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
80107300:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107307:	e9 c3 00 00 00       	jmp    801073cf <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
8010730c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010730f:	8b 04 85 b8 c0 10 80 	mov    -0x7fef3f48(,%eax,4),%eax
80107316:	89 c2                	mov    %eax,%edx
80107318:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010731b:	66 89 14 c5 40 73 11 	mov    %dx,-0x7fee8cc0(,%eax,8)
80107322:	80 
80107323:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107326:	66 c7 04 c5 42 73 11 	movw   $0x8,-0x7fee8cbe(,%eax,8)
8010732d:	80 08 00 
80107330:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107333:	0f b6 14 c5 44 73 11 	movzbl -0x7fee8cbc(,%eax,8),%edx
8010733a:	80 
8010733b:	83 e2 e0             	and    $0xffffffe0,%edx
8010733e:	88 14 c5 44 73 11 80 	mov    %dl,-0x7fee8cbc(,%eax,8)
80107345:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107348:	0f b6 14 c5 44 73 11 	movzbl -0x7fee8cbc(,%eax,8),%edx
8010734f:	80 
80107350:	83 e2 1f             	and    $0x1f,%edx
80107353:	88 14 c5 44 73 11 80 	mov    %dl,-0x7fee8cbc(,%eax,8)
8010735a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010735d:	0f b6 14 c5 45 73 11 	movzbl -0x7fee8cbb(,%eax,8),%edx
80107364:	80 
80107365:	83 e2 f0             	and    $0xfffffff0,%edx
80107368:	83 ca 0e             	or     $0xe,%edx
8010736b:	88 14 c5 45 73 11 80 	mov    %dl,-0x7fee8cbb(,%eax,8)
80107372:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107375:	0f b6 14 c5 45 73 11 	movzbl -0x7fee8cbb(,%eax,8),%edx
8010737c:	80 
8010737d:	83 e2 ef             	and    $0xffffffef,%edx
80107380:	88 14 c5 45 73 11 80 	mov    %dl,-0x7fee8cbb(,%eax,8)
80107387:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010738a:	0f b6 14 c5 45 73 11 	movzbl -0x7fee8cbb(,%eax,8),%edx
80107391:	80 
80107392:	83 e2 9f             	and    $0xffffff9f,%edx
80107395:	88 14 c5 45 73 11 80 	mov    %dl,-0x7fee8cbb(,%eax,8)
8010739c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010739f:	0f b6 14 c5 45 73 11 	movzbl -0x7fee8cbb(,%eax,8),%edx
801073a6:	80 
801073a7:	83 ca 80             	or     $0xffffff80,%edx
801073aa:	88 14 c5 45 73 11 80 	mov    %dl,-0x7fee8cbb(,%eax,8)
801073b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801073b4:	8b 04 85 b8 c0 10 80 	mov    -0x7fef3f48(,%eax,4),%eax
801073bb:	c1 e8 10             	shr    $0x10,%eax
801073be:	89 c2                	mov    %eax,%edx
801073c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801073c3:	66 89 14 c5 46 73 11 	mov    %dx,-0x7fee8cba(,%eax,8)
801073ca:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
801073cb:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801073cf:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
801073d6:	0f 8e 30 ff ff ff    	jle    8010730c <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
801073dc:	a1 b8 c1 10 80       	mov    0x8010c1b8,%eax
801073e1:	66 a3 40 75 11 80    	mov    %ax,0x80117540
801073e7:	66 c7 05 42 75 11 80 	movw   $0x8,0x80117542
801073ee:	08 00 
801073f0:	0f b6 05 44 75 11 80 	movzbl 0x80117544,%eax
801073f7:	83 e0 e0             	and    $0xffffffe0,%eax
801073fa:	a2 44 75 11 80       	mov    %al,0x80117544
801073ff:	0f b6 05 44 75 11 80 	movzbl 0x80117544,%eax
80107406:	83 e0 1f             	and    $0x1f,%eax
80107409:	a2 44 75 11 80       	mov    %al,0x80117544
8010740e:	0f b6 05 45 75 11 80 	movzbl 0x80117545,%eax
80107415:	83 c8 0f             	or     $0xf,%eax
80107418:	a2 45 75 11 80       	mov    %al,0x80117545
8010741d:	0f b6 05 45 75 11 80 	movzbl 0x80117545,%eax
80107424:	83 e0 ef             	and    $0xffffffef,%eax
80107427:	a2 45 75 11 80       	mov    %al,0x80117545
8010742c:	0f b6 05 45 75 11 80 	movzbl 0x80117545,%eax
80107433:	83 c8 60             	or     $0x60,%eax
80107436:	a2 45 75 11 80       	mov    %al,0x80117545
8010743b:	0f b6 05 45 75 11 80 	movzbl 0x80117545,%eax
80107442:	83 c8 80             	or     $0xffffff80,%eax
80107445:	a2 45 75 11 80       	mov    %al,0x80117545
8010744a:	a1 b8 c1 10 80       	mov    0x8010c1b8,%eax
8010744f:	c1 e8 10             	shr    $0x10,%eax
80107452:	66 a3 46 75 11 80    	mov    %ax,0x80117546
  
  initlock(&tickslock, "time");
80107458:	c7 44 24 04 50 97 10 	movl   $0x80109750,0x4(%esp)
8010745f:	80 
80107460:	c7 04 24 00 73 11 80 	movl   $0x80117300,(%esp)
80107467:	e8 49 e6 ff ff       	call   80105ab5 <initlock>
}
8010746c:	c9                   	leave  
8010746d:	c3                   	ret    

8010746e <idtinit>:

void
idtinit(void)
{
8010746e:	55                   	push   %ebp
8010746f:	89 e5                	mov    %esp,%ebp
80107471:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80107474:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
8010747b:	00 
8010747c:	c7 04 24 40 73 11 80 	movl   $0x80117340,(%esp)
80107483:	e8 38 fe ff ff       	call   801072c0 <lidt>
}
80107488:	c9                   	leave  
80107489:	c3                   	ret    

8010748a <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
8010748a:	55                   	push   %ebp
8010748b:	89 e5                	mov    %esp,%ebp
8010748d:	57                   	push   %edi
8010748e:	56                   	push   %esi
8010748f:	53                   	push   %ebx
80107490:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80107493:	8b 45 08             	mov    0x8(%ebp),%eax
80107496:	8b 40 30             	mov    0x30(%eax),%eax
80107499:	83 f8 40             	cmp    $0x40,%eax
8010749c:	75 3f                	jne    801074dd <trap+0x53>
    if(proc->killed)
8010749e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801074a4:	8b 40 24             	mov    0x24(%eax),%eax
801074a7:	85 c0                	test   %eax,%eax
801074a9:	74 05                	je     801074b0 <trap+0x26>
      exit();
801074ab:	e8 72 d4 ff ff       	call   80104922 <exit>
    proc->tf = tf;
801074b0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801074b6:	8b 55 08             	mov    0x8(%ebp),%edx
801074b9:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
801074bc:	e8 83 ed ff ff       	call   80106244 <syscall>
    if(proc->killed)
801074c1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801074c7:	8b 40 24             	mov    0x24(%eax),%eax
801074ca:	85 c0                	test   %eax,%eax
801074cc:	74 0a                	je     801074d8 <trap+0x4e>
      exit();
801074ce:	e8 4f d4 ff ff       	call   80104922 <exit>
    return;
801074d3:	e9 2d 02 00 00       	jmp    80107705 <trap+0x27b>
801074d8:	e9 28 02 00 00       	jmp    80107705 <trap+0x27b>
  }

  switch(tf->trapno){
801074dd:	8b 45 08             	mov    0x8(%ebp),%eax
801074e0:	8b 40 30             	mov    0x30(%eax),%eax
801074e3:	83 e8 20             	sub    $0x20,%eax
801074e6:	83 f8 1f             	cmp    $0x1f,%eax
801074e9:	0f 87 bc 00 00 00    	ja     801075ab <trap+0x121>
801074ef:	8b 04 85 f8 97 10 80 	mov    -0x7fef6808(,%eax,4),%eax
801074f6:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
801074f8:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801074fe:	0f b6 00             	movzbl (%eax),%eax
80107501:	84 c0                	test   %al,%al
80107503:	75 31                	jne    80107536 <trap+0xac>
      acquire(&tickslock);
80107505:	c7 04 24 00 73 11 80 	movl   $0x80117300,(%esp)
8010750c:	e8 c5 e5 ff ff       	call   80105ad6 <acquire>
      ticks++;
80107511:	a1 40 7b 11 80       	mov    0x80117b40,%eax
80107516:	83 c0 01             	add    $0x1,%eax
80107519:	a3 40 7b 11 80       	mov    %eax,0x80117b40
      wakeup(&ticks);
8010751e:	c7 04 24 40 7b 11 80 	movl   $0x80117b40,(%esp)
80107525:	e8 b6 d8 ff ff       	call   80104de0 <wakeup>
      release(&tickslock);
8010752a:	c7 04 24 00 73 11 80 	movl   $0x80117300,(%esp)
80107531:	e8 02 e6 ff ff       	call   80105b38 <release>
    }
    lapiceoi();
80107536:	e8 68 bb ff ff       	call   801030a3 <lapiceoi>
    break;
8010753b:	e9 41 01 00 00       	jmp    80107681 <trap+0x1f7>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
80107540:	e8 6c b3 ff ff       	call   801028b1 <ideintr>
    lapiceoi();
80107545:	e8 59 bb ff ff       	call   801030a3 <lapiceoi>
    break;
8010754a:	e9 32 01 00 00       	jmp    80107681 <trap+0x1f7>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
8010754f:	e8 1e b9 ff ff       	call   80102e72 <kbdintr>
    lapiceoi();
80107554:	e8 4a bb ff ff       	call   801030a3 <lapiceoi>
    break;
80107559:	e9 23 01 00 00       	jmp    80107681 <trap+0x1f7>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
8010755e:	e8 97 03 00 00       	call   801078fa <uartintr>
    lapiceoi();
80107563:	e8 3b bb ff ff       	call   801030a3 <lapiceoi>
    break;
80107568:	e9 14 01 00 00       	jmp    80107681 <trap+0x1f7>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010756d:	8b 45 08             	mov    0x8(%ebp),%eax
80107570:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
80107573:	8b 45 08             	mov    0x8(%ebp),%eax
80107576:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010757a:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
8010757d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107583:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80107586:	0f b6 c0             	movzbl %al,%eax
80107589:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010758d:	89 54 24 08          	mov    %edx,0x8(%esp)
80107591:	89 44 24 04          	mov    %eax,0x4(%esp)
80107595:	c7 04 24 58 97 10 80 	movl   $0x80109758,(%esp)
8010759c:	e8 ff 8d ff ff       	call   801003a0 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
801075a1:	e8 fd ba ff ff       	call   801030a3 <lapiceoi>
    break;
801075a6:	e9 d6 00 00 00       	jmp    80107681 <trap+0x1f7>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
801075ab:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801075b1:	85 c0                	test   %eax,%eax
801075b3:	74 11                	je     801075c6 <trap+0x13c>
801075b5:	8b 45 08             	mov    0x8(%ebp),%eax
801075b8:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801075bc:	0f b7 c0             	movzwl %ax,%eax
801075bf:	83 e0 03             	and    $0x3,%eax
801075c2:	85 c0                	test   %eax,%eax
801075c4:	75 46                	jne    8010760c <trap+0x182>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801075c6:	e8 1e fd ff ff       	call   801072e9 <rcr2>
801075cb:	8b 55 08             	mov    0x8(%ebp),%edx
801075ce:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
801075d1:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801075d8:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801075db:	0f b6 ca             	movzbl %dl,%ecx
801075de:	8b 55 08             	mov    0x8(%ebp),%edx
801075e1:	8b 52 30             	mov    0x30(%edx),%edx
801075e4:	89 44 24 10          	mov    %eax,0x10(%esp)
801075e8:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
801075ec:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801075f0:	89 54 24 04          	mov    %edx,0x4(%esp)
801075f4:	c7 04 24 7c 97 10 80 	movl   $0x8010977c,(%esp)
801075fb:	e8 a0 8d ff ff       	call   801003a0 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
80107600:	c7 04 24 ae 97 10 80 	movl   $0x801097ae,(%esp)
80107607:	e8 2e 8f ff ff       	call   8010053a <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010760c:	e8 d8 fc ff ff       	call   801072e9 <rcr2>
80107611:	89 c2                	mov    %eax,%edx
80107613:	8b 45 08             	mov    0x8(%ebp),%eax
80107616:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107619:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010761f:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107622:	0f b6 f0             	movzbl %al,%esi
80107625:	8b 45 08             	mov    0x8(%ebp),%eax
80107628:	8b 58 34             	mov    0x34(%eax),%ebx
8010762b:	8b 45 08             	mov    0x8(%ebp),%eax
8010762e:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80107631:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107637:	83 c0 6c             	add    $0x6c,%eax
8010763a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010763d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80107643:	8b 40 10             	mov    0x10(%eax),%eax
80107646:	89 54 24 1c          	mov    %edx,0x1c(%esp)
8010764a:	89 7c 24 18          	mov    %edi,0x18(%esp)
8010764e:	89 74 24 14          	mov    %esi,0x14(%esp)
80107652:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80107656:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010765a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
8010765d:	89 74 24 08          	mov    %esi,0x8(%esp)
80107661:	89 44 24 04          	mov    %eax,0x4(%esp)
80107665:	c7 04 24 b4 97 10 80 	movl   $0x801097b4,(%esp)
8010766c:	e8 2f 8d ff ff       	call   801003a0 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
80107671:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107677:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
8010767e:	eb 01                	jmp    80107681 <trap+0x1f7>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
80107680:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80107681:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107687:	85 c0                	test   %eax,%eax
80107689:	74 24                	je     801076af <trap+0x225>
8010768b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80107691:	8b 40 24             	mov    0x24(%eax),%eax
80107694:	85 c0                	test   %eax,%eax
80107696:	74 17                	je     801076af <trap+0x225>
80107698:	8b 45 08             	mov    0x8(%ebp),%eax
8010769b:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
8010769f:	0f b7 c0             	movzwl %ax,%eax
801076a2:	83 e0 03             	and    $0x3,%eax
801076a5:	83 f8 03             	cmp    $0x3,%eax
801076a8:	75 05                	jne    801076af <trap+0x225>
    exit();
801076aa:	e8 73 d2 ff ff       	call   80104922 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
801076af:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801076b5:	85 c0                	test   %eax,%eax
801076b7:	74 1e                	je     801076d7 <trap+0x24d>
801076b9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801076bf:	8b 40 0c             	mov    0xc(%eax),%eax
801076c2:	83 f8 04             	cmp    $0x4,%eax
801076c5:	75 10                	jne    801076d7 <trap+0x24d>
801076c7:	8b 45 08             	mov    0x8(%ebp),%eax
801076ca:	8b 40 30             	mov    0x30(%eax),%eax
801076cd:	83 f8 20             	cmp    $0x20,%eax
801076d0:	75 05                	jne    801076d7 <trap+0x24d>
    yield();
801076d2:	e8 cf d5 ff ff       	call   80104ca6 <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
801076d7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801076dd:	85 c0                	test   %eax,%eax
801076df:	74 24                	je     80107705 <trap+0x27b>
801076e1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801076e7:	8b 40 24             	mov    0x24(%eax),%eax
801076ea:	85 c0                	test   %eax,%eax
801076ec:	74 17                	je     80107705 <trap+0x27b>
801076ee:	8b 45 08             	mov    0x8(%ebp),%eax
801076f1:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801076f5:	0f b7 c0             	movzwl %ax,%eax
801076f8:	83 e0 03             	and    $0x3,%eax
801076fb:	83 f8 03             	cmp    $0x3,%eax
801076fe:	75 05                	jne    80107705 <trap+0x27b>
    exit();
80107700:	e8 1d d2 ff ff       	call   80104922 <exit>
}
80107705:	83 c4 3c             	add    $0x3c,%esp
80107708:	5b                   	pop    %ebx
80107709:	5e                   	pop    %esi
8010770a:	5f                   	pop    %edi
8010770b:	5d                   	pop    %ebp
8010770c:	c3                   	ret    

8010770d <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
8010770d:	55                   	push   %ebp
8010770e:	89 e5                	mov    %esp,%ebp
80107710:	83 ec 14             	sub    $0x14,%esp
80107713:	8b 45 08             	mov    0x8(%ebp),%eax
80107716:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010771a:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
8010771e:	89 c2                	mov    %eax,%edx
80107720:	ec                   	in     (%dx),%al
80107721:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80107724:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80107728:	c9                   	leave  
80107729:	c3                   	ret    

8010772a <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
8010772a:	55                   	push   %ebp
8010772b:	89 e5                	mov    %esp,%ebp
8010772d:	83 ec 08             	sub    $0x8,%esp
80107730:	8b 55 08             	mov    0x8(%ebp),%edx
80107733:	8b 45 0c             	mov    0xc(%ebp),%eax
80107736:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010773a:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010773d:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80107741:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80107745:	ee                   	out    %al,(%dx)
}
80107746:	c9                   	leave  
80107747:	c3                   	ret    

80107748 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80107748:	55                   	push   %ebp
80107749:	89 e5                	mov    %esp,%ebp
8010774b:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
8010774e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107755:	00 
80107756:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
8010775d:	e8 c8 ff ff ff       	call   8010772a <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80107762:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80107769:	00 
8010776a:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80107771:	e8 b4 ff ff ff       	call   8010772a <outb>
  outb(COM1+0, 115200/9600);
80107776:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
8010777d:	00 
8010777e:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107785:	e8 a0 ff ff ff       	call   8010772a <outb>
  outb(COM1+1, 0);
8010778a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107791:	00 
80107792:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80107799:	e8 8c ff ff ff       	call   8010772a <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
8010779e:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801077a5:	00 
801077a6:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
801077ad:	e8 78 ff ff ff       	call   8010772a <outb>
  outb(COM1+4, 0);
801077b2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801077b9:	00 
801077ba:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
801077c1:	e8 64 ff ff ff       	call   8010772a <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
801077c6:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801077cd:	00 
801077ce:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
801077d5:	e8 50 ff ff ff       	call   8010772a <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
801077da:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801077e1:	e8 27 ff ff ff       	call   8010770d <inb>
801077e6:	3c ff                	cmp    $0xff,%al
801077e8:	75 02                	jne    801077ec <uartinit+0xa4>
    return;
801077ea:	eb 6a                	jmp    80107856 <uartinit+0x10e>
  uart = 1;
801077ec:	c7 05 6c c6 10 80 01 	movl   $0x1,0x8010c66c
801077f3:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
801077f6:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
801077fd:	e8 0b ff ff ff       	call   8010770d <inb>
  inb(COM1+0);
80107802:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80107809:	e8 ff fe ff ff       	call   8010770d <inb>
  picenable(IRQ_COM1);
8010780e:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107815:	e8 72 c7 ff ff       	call   80103f8c <picenable>
  ioapicenable(IRQ_COM1, 0);
8010781a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107821:	00 
80107822:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80107829:	e8 02 b3 ff ff       	call   80102b30 <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
8010782e:	c7 45 f4 78 98 10 80 	movl   $0x80109878,-0xc(%ebp)
80107835:	eb 15                	jmp    8010784c <uartinit+0x104>
    uartputc(*p);
80107837:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010783a:	0f b6 00             	movzbl (%eax),%eax
8010783d:	0f be c0             	movsbl %al,%eax
80107840:	89 04 24             	mov    %eax,(%esp)
80107843:	e8 10 00 00 00       	call   80107858 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80107848:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010784c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010784f:	0f b6 00             	movzbl (%eax),%eax
80107852:	84 c0                	test   %al,%al
80107854:	75 e1                	jne    80107837 <uartinit+0xef>
    uartputc(*p);
}
80107856:	c9                   	leave  
80107857:	c3                   	ret    

80107858 <uartputc>:

void
uartputc(int c)
{
80107858:	55                   	push   %ebp
80107859:	89 e5                	mov    %esp,%ebp
8010785b:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
8010785e:	a1 6c c6 10 80       	mov    0x8010c66c,%eax
80107863:	85 c0                	test   %eax,%eax
80107865:	75 02                	jne    80107869 <uartputc+0x11>
    return;
80107867:	eb 4b                	jmp    801078b4 <uartputc+0x5c>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80107869:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107870:	eb 10                	jmp    80107882 <uartputc+0x2a>
    microdelay(10);
80107872:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80107879:	e8 4a b8 ff ff       	call   801030c8 <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
8010787e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107882:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80107886:	7f 16                	jg     8010789e <uartputc+0x46>
80107888:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
8010788f:	e8 79 fe ff ff       	call   8010770d <inb>
80107894:	0f b6 c0             	movzbl %al,%eax
80107897:	83 e0 20             	and    $0x20,%eax
8010789a:	85 c0                	test   %eax,%eax
8010789c:	74 d4                	je     80107872 <uartputc+0x1a>
    microdelay(10);
  outb(COM1+0, c);
8010789e:	8b 45 08             	mov    0x8(%ebp),%eax
801078a1:	0f b6 c0             	movzbl %al,%eax
801078a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801078a8:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801078af:	e8 76 fe ff ff       	call   8010772a <outb>
}
801078b4:	c9                   	leave  
801078b5:	c3                   	ret    

801078b6 <uartgetc>:

static int
uartgetc(void)
{
801078b6:	55                   	push   %ebp
801078b7:	89 e5                	mov    %esp,%ebp
801078b9:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
801078bc:	a1 6c c6 10 80       	mov    0x8010c66c,%eax
801078c1:	85 c0                	test   %eax,%eax
801078c3:	75 07                	jne    801078cc <uartgetc+0x16>
    return -1;
801078c5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801078ca:	eb 2c                	jmp    801078f8 <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
801078cc:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801078d3:	e8 35 fe ff ff       	call   8010770d <inb>
801078d8:	0f b6 c0             	movzbl %al,%eax
801078db:	83 e0 01             	and    $0x1,%eax
801078de:	85 c0                	test   %eax,%eax
801078e0:	75 07                	jne    801078e9 <uartgetc+0x33>
    return -1;
801078e2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801078e7:	eb 0f                	jmp    801078f8 <uartgetc+0x42>
  return inb(COM1+0);
801078e9:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801078f0:	e8 18 fe ff ff       	call   8010770d <inb>
801078f5:	0f b6 c0             	movzbl %al,%eax
}
801078f8:	c9                   	leave  
801078f9:	c3                   	ret    

801078fa <uartintr>:

void
uartintr(void)
{
801078fa:	55                   	push   %ebp
801078fb:	89 e5                	mov    %esp,%ebp
801078fd:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80107900:	c7 04 24 b6 78 10 80 	movl   $0x801078b6,(%esp)
80107907:	e8 a1 8e ff ff       	call   801007ad <consoleintr>
}
8010790c:	c9                   	leave  
8010790d:	c3                   	ret    

8010790e <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
8010790e:	6a 00                	push   $0x0
  pushl $0
80107910:	6a 00                	push   $0x0
  jmp alltraps
80107912:	e9 7e f9 ff ff       	jmp    80107295 <alltraps>

80107917 <vector1>:
.globl vector1
vector1:
  pushl $0
80107917:	6a 00                	push   $0x0
  pushl $1
80107919:	6a 01                	push   $0x1
  jmp alltraps
8010791b:	e9 75 f9 ff ff       	jmp    80107295 <alltraps>

80107920 <vector2>:
.globl vector2
vector2:
  pushl $0
80107920:	6a 00                	push   $0x0
  pushl $2
80107922:	6a 02                	push   $0x2
  jmp alltraps
80107924:	e9 6c f9 ff ff       	jmp    80107295 <alltraps>

80107929 <vector3>:
.globl vector3
vector3:
  pushl $0
80107929:	6a 00                	push   $0x0
  pushl $3
8010792b:	6a 03                	push   $0x3
  jmp alltraps
8010792d:	e9 63 f9 ff ff       	jmp    80107295 <alltraps>

80107932 <vector4>:
.globl vector4
vector4:
  pushl $0
80107932:	6a 00                	push   $0x0
  pushl $4
80107934:	6a 04                	push   $0x4
  jmp alltraps
80107936:	e9 5a f9 ff ff       	jmp    80107295 <alltraps>

8010793b <vector5>:
.globl vector5
vector5:
  pushl $0
8010793b:	6a 00                	push   $0x0
  pushl $5
8010793d:	6a 05                	push   $0x5
  jmp alltraps
8010793f:	e9 51 f9 ff ff       	jmp    80107295 <alltraps>

80107944 <vector6>:
.globl vector6
vector6:
  pushl $0
80107944:	6a 00                	push   $0x0
  pushl $6
80107946:	6a 06                	push   $0x6
  jmp alltraps
80107948:	e9 48 f9 ff ff       	jmp    80107295 <alltraps>

8010794d <vector7>:
.globl vector7
vector7:
  pushl $0
8010794d:	6a 00                	push   $0x0
  pushl $7
8010794f:	6a 07                	push   $0x7
  jmp alltraps
80107951:	e9 3f f9 ff ff       	jmp    80107295 <alltraps>

80107956 <vector8>:
.globl vector8
vector8:
  pushl $8
80107956:	6a 08                	push   $0x8
  jmp alltraps
80107958:	e9 38 f9 ff ff       	jmp    80107295 <alltraps>

8010795d <vector9>:
.globl vector9
vector9:
  pushl $0
8010795d:	6a 00                	push   $0x0
  pushl $9
8010795f:	6a 09                	push   $0x9
  jmp alltraps
80107961:	e9 2f f9 ff ff       	jmp    80107295 <alltraps>

80107966 <vector10>:
.globl vector10
vector10:
  pushl $10
80107966:	6a 0a                	push   $0xa
  jmp alltraps
80107968:	e9 28 f9 ff ff       	jmp    80107295 <alltraps>

8010796d <vector11>:
.globl vector11
vector11:
  pushl $11
8010796d:	6a 0b                	push   $0xb
  jmp alltraps
8010796f:	e9 21 f9 ff ff       	jmp    80107295 <alltraps>

80107974 <vector12>:
.globl vector12
vector12:
  pushl $12
80107974:	6a 0c                	push   $0xc
  jmp alltraps
80107976:	e9 1a f9 ff ff       	jmp    80107295 <alltraps>

8010797b <vector13>:
.globl vector13
vector13:
  pushl $13
8010797b:	6a 0d                	push   $0xd
  jmp alltraps
8010797d:	e9 13 f9 ff ff       	jmp    80107295 <alltraps>

80107982 <vector14>:
.globl vector14
vector14:
  pushl $14
80107982:	6a 0e                	push   $0xe
  jmp alltraps
80107984:	e9 0c f9 ff ff       	jmp    80107295 <alltraps>

80107989 <vector15>:
.globl vector15
vector15:
  pushl $0
80107989:	6a 00                	push   $0x0
  pushl $15
8010798b:	6a 0f                	push   $0xf
  jmp alltraps
8010798d:	e9 03 f9 ff ff       	jmp    80107295 <alltraps>

80107992 <vector16>:
.globl vector16
vector16:
  pushl $0
80107992:	6a 00                	push   $0x0
  pushl $16
80107994:	6a 10                	push   $0x10
  jmp alltraps
80107996:	e9 fa f8 ff ff       	jmp    80107295 <alltraps>

8010799b <vector17>:
.globl vector17
vector17:
  pushl $17
8010799b:	6a 11                	push   $0x11
  jmp alltraps
8010799d:	e9 f3 f8 ff ff       	jmp    80107295 <alltraps>

801079a2 <vector18>:
.globl vector18
vector18:
  pushl $0
801079a2:	6a 00                	push   $0x0
  pushl $18
801079a4:	6a 12                	push   $0x12
  jmp alltraps
801079a6:	e9 ea f8 ff ff       	jmp    80107295 <alltraps>

801079ab <vector19>:
.globl vector19
vector19:
  pushl $0
801079ab:	6a 00                	push   $0x0
  pushl $19
801079ad:	6a 13                	push   $0x13
  jmp alltraps
801079af:	e9 e1 f8 ff ff       	jmp    80107295 <alltraps>

801079b4 <vector20>:
.globl vector20
vector20:
  pushl $0
801079b4:	6a 00                	push   $0x0
  pushl $20
801079b6:	6a 14                	push   $0x14
  jmp alltraps
801079b8:	e9 d8 f8 ff ff       	jmp    80107295 <alltraps>

801079bd <vector21>:
.globl vector21
vector21:
  pushl $0
801079bd:	6a 00                	push   $0x0
  pushl $21
801079bf:	6a 15                	push   $0x15
  jmp alltraps
801079c1:	e9 cf f8 ff ff       	jmp    80107295 <alltraps>

801079c6 <vector22>:
.globl vector22
vector22:
  pushl $0
801079c6:	6a 00                	push   $0x0
  pushl $22
801079c8:	6a 16                	push   $0x16
  jmp alltraps
801079ca:	e9 c6 f8 ff ff       	jmp    80107295 <alltraps>

801079cf <vector23>:
.globl vector23
vector23:
  pushl $0
801079cf:	6a 00                	push   $0x0
  pushl $23
801079d1:	6a 17                	push   $0x17
  jmp alltraps
801079d3:	e9 bd f8 ff ff       	jmp    80107295 <alltraps>

801079d8 <vector24>:
.globl vector24
vector24:
  pushl $0
801079d8:	6a 00                	push   $0x0
  pushl $24
801079da:	6a 18                	push   $0x18
  jmp alltraps
801079dc:	e9 b4 f8 ff ff       	jmp    80107295 <alltraps>

801079e1 <vector25>:
.globl vector25
vector25:
  pushl $0
801079e1:	6a 00                	push   $0x0
  pushl $25
801079e3:	6a 19                	push   $0x19
  jmp alltraps
801079e5:	e9 ab f8 ff ff       	jmp    80107295 <alltraps>

801079ea <vector26>:
.globl vector26
vector26:
  pushl $0
801079ea:	6a 00                	push   $0x0
  pushl $26
801079ec:	6a 1a                	push   $0x1a
  jmp alltraps
801079ee:	e9 a2 f8 ff ff       	jmp    80107295 <alltraps>

801079f3 <vector27>:
.globl vector27
vector27:
  pushl $0
801079f3:	6a 00                	push   $0x0
  pushl $27
801079f5:	6a 1b                	push   $0x1b
  jmp alltraps
801079f7:	e9 99 f8 ff ff       	jmp    80107295 <alltraps>

801079fc <vector28>:
.globl vector28
vector28:
  pushl $0
801079fc:	6a 00                	push   $0x0
  pushl $28
801079fe:	6a 1c                	push   $0x1c
  jmp alltraps
80107a00:	e9 90 f8 ff ff       	jmp    80107295 <alltraps>

80107a05 <vector29>:
.globl vector29
vector29:
  pushl $0
80107a05:	6a 00                	push   $0x0
  pushl $29
80107a07:	6a 1d                	push   $0x1d
  jmp alltraps
80107a09:	e9 87 f8 ff ff       	jmp    80107295 <alltraps>

80107a0e <vector30>:
.globl vector30
vector30:
  pushl $0
80107a0e:	6a 00                	push   $0x0
  pushl $30
80107a10:	6a 1e                	push   $0x1e
  jmp alltraps
80107a12:	e9 7e f8 ff ff       	jmp    80107295 <alltraps>

80107a17 <vector31>:
.globl vector31
vector31:
  pushl $0
80107a17:	6a 00                	push   $0x0
  pushl $31
80107a19:	6a 1f                	push   $0x1f
  jmp alltraps
80107a1b:	e9 75 f8 ff ff       	jmp    80107295 <alltraps>

80107a20 <vector32>:
.globl vector32
vector32:
  pushl $0
80107a20:	6a 00                	push   $0x0
  pushl $32
80107a22:	6a 20                	push   $0x20
  jmp alltraps
80107a24:	e9 6c f8 ff ff       	jmp    80107295 <alltraps>

80107a29 <vector33>:
.globl vector33
vector33:
  pushl $0
80107a29:	6a 00                	push   $0x0
  pushl $33
80107a2b:	6a 21                	push   $0x21
  jmp alltraps
80107a2d:	e9 63 f8 ff ff       	jmp    80107295 <alltraps>

80107a32 <vector34>:
.globl vector34
vector34:
  pushl $0
80107a32:	6a 00                	push   $0x0
  pushl $34
80107a34:	6a 22                	push   $0x22
  jmp alltraps
80107a36:	e9 5a f8 ff ff       	jmp    80107295 <alltraps>

80107a3b <vector35>:
.globl vector35
vector35:
  pushl $0
80107a3b:	6a 00                	push   $0x0
  pushl $35
80107a3d:	6a 23                	push   $0x23
  jmp alltraps
80107a3f:	e9 51 f8 ff ff       	jmp    80107295 <alltraps>

80107a44 <vector36>:
.globl vector36
vector36:
  pushl $0
80107a44:	6a 00                	push   $0x0
  pushl $36
80107a46:	6a 24                	push   $0x24
  jmp alltraps
80107a48:	e9 48 f8 ff ff       	jmp    80107295 <alltraps>

80107a4d <vector37>:
.globl vector37
vector37:
  pushl $0
80107a4d:	6a 00                	push   $0x0
  pushl $37
80107a4f:	6a 25                	push   $0x25
  jmp alltraps
80107a51:	e9 3f f8 ff ff       	jmp    80107295 <alltraps>

80107a56 <vector38>:
.globl vector38
vector38:
  pushl $0
80107a56:	6a 00                	push   $0x0
  pushl $38
80107a58:	6a 26                	push   $0x26
  jmp alltraps
80107a5a:	e9 36 f8 ff ff       	jmp    80107295 <alltraps>

80107a5f <vector39>:
.globl vector39
vector39:
  pushl $0
80107a5f:	6a 00                	push   $0x0
  pushl $39
80107a61:	6a 27                	push   $0x27
  jmp alltraps
80107a63:	e9 2d f8 ff ff       	jmp    80107295 <alltraps>

80107a68 <vector40>:
.globl vector40
vector40:
  pushl $0
80107a68:	6a 00                	push   $0x0
  pushl $40
80107a6a:	6a 28                	push   $0x28
  jmp alltraps
80107a6c:	e9 24 f8 ff ff       	jmp    80107295 <alltraps>

80107a71 <vector41>:
.globl vector41
vector41:
  pushl $0
80107a71:	6a 00                	push   $0x0
  pushl $41
80107a73:	6a 29                	push   $0x29
  jmp alltraps
80107a75:	e9 1b f8 ff ff       	jmp    80107295 <alltraps>

80107a7a <vector42>:
.globl vector42
vector42:
  pushl $0
80107a7a:	6a 00                	push   $0x0
  pushl $42
80107a7c:	6a 2a                	push   $0x2a
  jmp alltraps
80107a7e:	e9 12 f8 ff ff       	jmp    80107295 <alltraps>

80107a83 <vector43>:
.globl vector43
vector43:
  pushl $0
80107a83:	6a 00                	push   $0x0
  pushl $43
80107a85:	6a 2b                	push   $0x2b
  jmp alltraps
80107a87:	e9 09 f8 ff ff       	jmp    80107295 <alltraps>

80107a8c <vector44>:
.globl vector44
vector44:
  pushl $0
80107a8c:	6a 00                	push   $0x0
  pushl $44
80107a8e:	6a 2c                	push   $0x2c
  jmp alltraps
80107a90:	e9 00 f8 ff ff       	jmp    80107295 <alltraps>

80107a95 <vector45>:
.globl vector45
vector45:
  pushl $0
80107a95:	6a 00                	push   $0x0
  pushl $45
80107a97:	6a 2d                	push   $0x2d
  jmp alltraps
80107a99:	e9 f7 f7 ff ff       	jmp    80107295 <alltraps>

80107a9e <vector46>:
.globl vector46
vector46:
  pushl $0
80107a9e:	6a 00                	push   $0x0
  pushl $46
80107aa0:	6a 2e                	push   $0x2e
  jmp alltraps
80107aa2:	e9 ee f7 ff ff       	jmp    80107295 <alltraps>

80107aa7 <vector47>:
.globl vector47
vector47:
  pushl $0
80107aa7:	6a 00                	push   $0x0
  pushl $47
80107aa9:	6a 2f                	push   $0x2f
  jmp alltraps
80107aab:	e9 e5 f7 ff ff       	jmp    80107295 <alltraps>

80107ab0 <vector48>:
.globl vector48
vector48:
  pushl $0
80107ab0:	6a 00                	push   $0x0
  pushl $48
80107ab2:	6a 30                	push   $0x30
  jmp alltraps
80107ab4:	e9 dc f7 ff ff       	jmp    80107295 <alltraps>

80107ab9 <vector49>:
.globl vector49
vector49:
  pushl $0
80107ab9:	6a 00                	push   $0x0
  pushl $49
80107abb:	6a 31                	push   $0x31
  jmp alltraps
80107abd:	e9 d3 f7 ff ff       	jmp    80107295 <alltraps>

80107ac2 <vector50>:
.globl vector50
vector50:
  pushl $0
80107ac2:	6a 00                	push   $0x0
  pushl $50
80107ac4:	6a 32                	push   $0x32
  jmp alltraps
80107ac6:	e9 ca f7 ff ff       	jmp    80107295 <alltraps>

80107acb <vector51>:
.globl vector51
vector51:
  pushl $0
80107acb:	6a 00                	push   $0x0
  pushl $51
80107acd:	6a 33                	push   $0x33
  jmp alltraps
80107acf:	e9 c1 f7 ff ff       	jmp    80107295 <alltraps>

80107ad4 <vector52>:
.globl vector52
vector52:
  pushl $0
80107ad4:	6a 00                	push   $0x0
  pushl $52
80107ad6:	6a 34                	push   $0x34
  jmp alltraps
80107ad8:	e9 b8 f7 ff ff       	jmp    80107295 <alltraps>

80107add <vector53>:
.globl vector53
vector53:
  pushl $0
80107add:	6a 00                	push   $0x0
  pushl $53
80107adf:	6a 35                	push   $0x35
  jmp alltraps
80107ae1:	e9 af f7 ff ff       	jmp    80107295 <alltraps>

80107ae6 <vector54>:
.globl vector54
vector54:
  pushl $0
80107ae6:	6a 00                	push   $0x0
  pushl $54
80107ae8:	6a 36                	push   $0x36
  jmp alltraps
80107aea:	e9 a6 f7 ff ff       	jmp    80107295 <alltraps>

80107aef <vector55>:
.globl vector55
vector55:
  pushl $0
80107aef:	6a 00                	push   $0x0
  pushl $55
80107af1:	6a 37                	push   $0x37
  jmp alltraps
80107af3:	e9 9d f7 ff ff       	jmp    80107295 <alltraps>

80107af8 <vector56>:
.globl vector56
vector56:
  pushl $0
80107af8:	6a 00                	push   $0x0
  pushl $56
80107afa:	6a 38                	push   $0x38
  jmp alltraps
80107afc:	e9 94 f7 ff ff       	jmp    80107295 <alltraps>

80107b01 <vector57>:
.globl vector57
vector57:
  pushl $0
80107b01:	6a 00                	push   $0x0
  pushl $57
80107b03:	6a 39                	push   $0x39
  jmp alltraps
80107b05:	e9 8b f7 ff ff       	jmp    80107295 <alltraps>

80107b0a <vector58>:
.globl vector58
vector58:
  pushl $0
80107b0a:	6a 00                	push   $0x0
  pushl $58
80107b0c:	6a 3a                	push   $0x3a
  jmp alltraps
80107b0e:	e9 82 f7 ff ff       	jmp    80107295 <alltraps>

80107b13 <vector59>:
.globl vector59
vector59:
  pushl $0
80107b13:	6a 00                	push   $0x0
  pushl $59
80107b15:	6a 3b                	push   $0x3b
  jmp alltraps
80107b17:	e9 79 f7 ff ff       	jmp    80107295 <alltraps>

80107b1c <vector60>:
.globl vector60
vector60:
  pushl $0
80107b1c:	6a 00                	push   $0x0
  pushl $60
80107b1e:	6a 3c                	push   $0x3c
  jmp alltraps
80107b20:	e9 70 f7 ff ff       	jmp    80107295 <alltraps>

80107b25 <vector61>:
.globl vector61
vector61:
  pushl $0
80107b25:	6a 00                	push   $0x0
  pushl $61
80107b27:	6a 3d                	push   $0x3d
  jmp alltraps
80107b29:	e9 67 f7 ff ff       	jmp    80107295 <alltraps>

80107b2e <vector62>:
.globl vector62
vector62:
  pushl $0
80107b2e:	6a 00                	push   $0x0
  pushl $62
80107b30:	6a 3e                	push   $0x3e
  jmp alltraps
80107b32:	e9 5e f7 ff ff       	jmp    80107295 <alltraps>

80107b37 <vector63>:
.globl vector63
vector63:
  pushl $0
80107b37:	6a 00                	push   $0x0
  pushl $63
80107b39:	6a 3f                	push   $0x3f
  jmp alltraps
80107b3b:	e9 55 f7 ff ff       	jmp    80107295 <alltraps>

80107b40 <vector64>:
.globl vector64
vector64:
  pushl $0
80107b40:	6a 00                	push   $0x0
  pushl $64
80107b42:	6a 40                	push   $0x40
  jmp alltraps
80107b44:	e9 4c f7 ff ff       	jmp    80107295 <alltraps>

80107b49 <vector65>:
.globl vector65
vector65:
  pushl $0
80107b49:	6a 00                	push   $0x0
  pushl $65
80107b4b:	6a 41                	push   $0x41
  jmp alltraps
80107b4d:	e9 43 f7 ff ff       	jmp    80107295 <alltraps>

80107b52 <vector66>:
.globl vector66
vector66:
  pushl $0
80107b52:	6a 00                	push   $0x0
  pushl $66
80107b54:	6a 42                	push   $0x42
  jmp alltraps
80107b56:	e9 3a f7 ff ff       	jmp    80107295 <alltraps>

80107b5b <vector67>:
.globl vector67
vector67:
  pushl $0
80107b5b:	6a 00                	push   $0x0
  pushl $67
80107b5d:	6a 43                	push   $0x43
  jmp alltraps
80107b5f:	e9 31 f7 ff ff       	jmp    80107295 <alltraps>

80107b64 <vector68>:
.globl vector68
vector68:
  pushl $0
80107b64:	6a 00                	push   $0x0
  pushl $68
80107b66:	6a 44                	push   $0x44
  jmp alltraps
80107b68:	e9 28 f7 ff ff       	jmp    80107295 <alltraps>

80107b6d <vector69>:
.globl vector69
vector69:
  pushl $0
80107b6d:	6a 00                	push   $0x0
  pushl $69
80107b6f:	6a 45                	push   $0x45
  jmp alltraps
80107b71:	e9 1f f7 ff ff       	jmp    80107295 <alltraps>

80107b76 <vector70>:
.globl vector70
vector70:
  pushl $0
80107b76:	6a 00                	push   $0x0
  pushl $70
80107b78:	6a 46                	push   $0x46
  jmp alltraps
80107b7a:	e9 16 f7 ff ff       	jmp    80107295 <alltraps>

80107b7f <vector71>:
.globl vector71
vector71:
  pushl $0
80107b7f:	6a 00                	push   $0x0
  pushl $71
80107b81:	6a 47                	push   $0x47
  jmp alltraps
80107b83:	e9 0d f7 ff ff       	jmp    80107295 <alltraps>

80107b88 <vector72>:
.globl vector72
vector72:
  pushl $0
80107b88:	6a 00                	push   $0x0
  pushl $72
80107b8a:	6a 48                	push   $0x48
  jmp alltraps
80107b8c:	e9 04 f7 ff ff       	jmp    80107295 <alltraps>

80107b91 <vector73>:
.globl vector73
vector73:
  pushl $0
80107b91:	6a 00                	push   $0x0
  pushl $73
80107b93:	6a 49                	push   $0x49
  jmp alltraps
80107b95:	e9 fb f6 ff ff       	jmp    80107295 <alltraps>

80107b9a <vector74>:
.globl vector74
vector74:
  pushl $0
80107b9a:	6a 00                	push   $0x0
  pushl $74
80107b9c:	6a 4a                	push   $0x4a
  jmp alltraps
80107b9e:	e9 f2 f6 ff ff       	jmp    80107295 <alltraps>

80107ba3 <vector75>:
.globl vector75
vector75:
  pushl $0
80107ba3:	6a 00                	push   $0x0
  pushl $75
80107ba5:	6a 4b                	push   $0x4b
  jmp alltraps
80107ba7:	e9 e9 f6 ff ff       	jmp    80107295 <alltraps>

80107bac <vector76>:
.globl vector76
vector76:
  pushl $0
80107bac:	6a 00                	push   $0x0
  pushl $76
80107bae:	6a 4c                	push   $0x4c
  jmp alltraps
80107bb0:	e9 e0 f6 ff ff       	jmp    80107295 <alltraps>

80107bb5 <vector77>:
.globl vector77
vector77:
  pushl $0
80107bb5:	6a 00                	push   $0x0
  pushl $77
80107bb7:	6a 4d                	push   $0x4d
  jmp alltraps
80107bb9:	e9 d7 f6 ff ff       	jmp    80107295 <alltraps>

80107bbe <vector78>:
.globl vector78
vector78:
  pushl $0
80107bbe:	6a 00                	push   $0x0
  pushl $78
80107bc0:	6a 4e                	push   $0x4e
  jmp alltraps
80107bc2:	e9 ce f6 ff ff       	jmp    80107295 <alltraps>

80107bc7 <vector79>:
.globl vector79
vector79:
  pushl $0
80107bc7:	6a 00                	push   $0x0
  pushl $79
80107bc9:	6a 4f                	push   $0x4f
  jmp alltraps
80107bcb:	e9 c5 f6 ff ff       	jmp    80107295 <alltraps>

80107bd0 <vector80>:
.globl vector80
vector80:
  pushl $0
80107bd0:	6a 00                	push   $0x0
  pushl $80
80107bd2:	6a 50                	push   $0x50
  jmp alltraps
80107bd4:	e9 bc f6 ff ff       	jmp    80107295 <alltraps>

80107bd9 <vector81>:
.globl vector81
vector81:
  pushl $0
80107bd9:	6a 00                	push   $0x0
  pushl $81
80107bdb:	6a 51                	push   $0x51
  jmp alltraps
80107bdd:	e9 b3 f6 ff ff       	jmp    80107295 <alltraps>

80107be2 <vector82>:
.globl vector82
vector82:
  pushl $0
80107be2:	6a 00                	push   $0x0
  pushl $82
80107be4:	6a 52                	push   $0x52
  jmp alltraps
80107be6:	e9 aa f6 ff ff       	jmp    80107295 <alltraps>

80107beb <vector83>:
.globl vector83
vector83:
  pushl $0
80107beb:	6a 00                	push   $0x0
  pushl $83
80107bed:	6a 53                	push   $0x53
  jmp alltraps
80107bef:	e9 a1 f6 ff ff       	jmp    80107295 <alltraps>

80107bf4 <vector84>:
.globl vector84
vector84:
  pushl $0
80107bf4:	6a 00                	push   $0x0
  pushl $84
80107bf6:	6a 54                	push   $0x54
  jmp alltraps
80107bf8:	e9 98 f6 ff ff       	jmp    80107295 <alltraps>

80107bfd <vector85>:
.globl vector85
vector85:
  pushl $0
80107bfd:	6a 00                	push   $0x0
  pushl $85
80107bff:	6a 55                	push   $0x55
  jmp alltraps
80107c01:	e9 8f f6 ff ff       	jmp    80107295 <alltraps>

80107c06 <vector86>:
.globl vector86
vector86:
  pushl $0
80107c06:	6a 00                	push   $0x0
  pushl $86
80107c08:	6a 56                	push   $0x56
  jmp alltraps
80107c0a:	e9 86 f6 ff ff       	jmp    80107295 <alltraps>

80107c0f <vector87>:
.globl vector87
vector87:
  pushl $0
80107c0f:	6a 00                	push   $0x0
  pushl $87
80107c11:	6a 57                	push   $0x57
  jmp alltraps
80107c13:	e9 7d f6 ff ff       	jmp    80107295 <alltraps>

80107c18 <vector88>:
.globl vector88
vector88:
  pushl $0
80107c18:	6a 00                	push   $0x0
  pushl $88
80107c1a:	6a 58                	push   $0x58
  jmp alltraps
80107c1c:	e9 74 f6 ff ff       	jmp    80107295 <alltraps>

80107c21 <vector89>:
.globl vector89
vector89:
  pushl $0
80107c21:	6a 00                	push   $0x0
  pushl $89
80107c23:	6a 59                	push   $0x59
  jmp alltraps
80107c25:	e9 6b f6 ff ff       	jmp    80107295 <alltraps>

80107c2a <vector90>:
.globl vector90
vector90:
  pushl $0
80107c2a:	6a 00                	push   $0x0
  pushl $90
80107c2c:	6a 5a                	push   $0x5a
  jmp alltraps
80107c2e:	e9 62 f6 ff ff       	jmp    80107295 <alltraps>

80107c33 <vector91>:
.globl vector91
vector91:
  pushl $0
80107c33:	6a 00                	push   $0x0
  pushl $91
80107c35:	6a 5b                	push   $0x5b
  jmp alltraps
80107c37:	e9 59 f6 ff ff       	jmp    80107295 <alltraps>

80107c3c <vector92>:
.globl vector92
vector92:
  pushl $0
80107c3c:	6a 00                	push   $0x0
  pushl $92
80107c3e:	6a 5c                	push   $0x5c
  jmp alltraps
80107c40:	e9 50 f6 ff ff       	jmp    80107295 <alltraps>

80107c45 <vector93>:
.globl vector93
vector93:
  pushl $0
80107c45:	6a 00                	push   $0x0
  pushl $93
80107c47:	6a 5d                	push   $0x5d
  jmp alltraps
80107c49:	e9 47 f6 ff ff       	jmp    80107295 <alltraps>

80107c4e <vector94>:
.globl vector94
vector94:
  pushl $0
80107c4e:	6a 00                	push   $0x0
  pushl $94
80107c50:	6a 5e                	push   $0x5e
  jmp alltraps
80107c52:	e9 3e f6 ff ff       	jmp    80107295 <alltraps>

80107c57 <vector95>:
.globl vector95
vector95:
  pushl $0
80107c57:	6a 00                	push   $0x0
  pushl $95
80107c59:	6a 5f                	push   $0x5f
  jmp alltraps
80107c5b:	e9 35 f6 ff ff       	jmp    80107295 <alltraps>

80107c60 <vector96>:
.globl vector96
vector96:
  pushl $0
80107c60:	6a 00                	push   $0x0
  pushl $96
80107c62:	6a 60                	push   $0x60
  jmp alltraps
80107c64:	e9 2c f6 ff ff       	jmp    80107295 <alltraps>

80107c69 <vector97>:
.globl vector97
vector97:
  pushl $0
80107c69:	6a 00                	push   $0x0
  pushl $97
80107c6b:	6a 61                	push   $0x61
  jmp alltraps
80107c6d:	e9 23 f6 ff ff       	jmp    80107295 <alltraps>

80107c72 <vector98>:
.globl vector98
vector98:
  pushl $0
80107c72:	6a 00                	push   $0x0
  pushl $98
80107c74:	6a 62                	push   $0x62
  jmp alltraps
80107c76:	e9 1a f6 ff ff       	jmp    80107295 <alltraps>

80107c7b <vector99>:
.globl vector99
vector99:
  pushl $0
80107c7b:	6a 00                	push   $0x0
  pushl $99
80107c7d:	6a 63                	push   $0x63
  jmp alltraps
80107c7f:	e9 11 f6 ff ff       	jmp    80107295 <alltraps>

80107c84 <vector100>:
.globl vector100
vector100:
  pushl $0
80107c84:	6a 00                	push   $0x0
  pushl $100
80107c86:	6a 64                	push   $0x64
  jmp alltraps
80107c88:	e9 08 f6 ff ff       	jmp    80107295 <alltraps>

80107c8d <vector101>:
.globl vector101
vector101:
  pushl $0
80107c8d:	6a 00                	push   $0x0
  pushl $101
80107c8f:	6a 65                	push   $0x65
  jmp alltraps
80107c91:	e9 ff f5 ff ff       	jmp    80107295 <alltraps>

80107c96 <vector102>:
.globl vector102
vector102:
  pushl $0
80107c96:	6a 00                	push   $0x0
  pushl $102
80107c98:	6a 66                	push   $0x66
  jmp alltraps
80107c9a:	e9 f6 f5 ff ff       	jmp    80107295 <alltraps>

80107c9f <vector103>:
.globl vector103
vector103:
  pushl $0
80107c9f:	6a 00                	push   $0x0
  pushl $103
80107ca1:	6a 67                	push   $0x67
  jmp alltraps
80107ca3:	e9 ed f5 ff ff       	jmp    80107295 <alltraps>

80107ca8 <vector104>:
.globl vector104
vector104:
  pushl $0
80107ca8:	6a 00                	push   $0x0
  pushl $104
80107caa:	6a 68                	push   $0x68
  jmp alltraps
80107cac:	e9 e4 f5 ff ff       	jmp    80107295 <alltraps>

80107cb1 <vector105>:
.globl vector105
vector105:
  pushl $0
80107cb1:	6a 00                	push   $0x0
  pushl $105
80107cb3:	6a 69                	push   $0x69
  jmp alltraps
80107cb5:	e9 db f5 ff ff       	jmp    80107295 <alltraps>

80107cba <vector106>:
.globl vector106
vector106:
  pushl $0
80107cba:	6a 00                	push   $0x0
  pushl $106
80107cbc:	6a 6a                	push   $0x6a
  jmp alltraps
80107cbe:	e9 d2 f5 ff ff       	jmp    80107295 <alltraps>

80107cc3 <vector107>:
.globl vector107
vector107:
  pushl $0
80107cc3:	6a 00                	push   $0x0
  pushl $107
80107cc5:	6a 6b                	push   $0x6b
  jmp alltraps
80107cc7:	e9 c9 f5 ff ff       	jmp    80107295 <alltraps>

80107ccc <vector108>:
.globl vector108
vector108:
  pushl $0
80107ccc:	6a 00                	push   $0x0
  pushl $108
80107cce:	6a 6c                	push   $0x6c
  jmp alltraps
80107cd0:	e9 c0 f5 ff ff       	jmp    80107295 <alltraps>

80107cd5 <vector109>:
.globl vector109
vector109:
  pushl $0
80107cd5:	6a 00                	push   $0x0
  pushl $109
80107cd7:	6a 6d                	push   $0x6d
  jmp alltraps
80107cd9:	e9 b7 f5 ff ff       	jmp    80107295 <alltraps>

80107cde <vector110>:
.globl vector110
vector110:
  pushl $0
80107cde:	6a 00                	push   $0x0
  pushl $110
80107ce0:	6a 6e                	push   $0x6e
  jmp alltraps
80107ce2:	e9 ae f5 ff ff       	jmp    80107295 <alltraps>

80107ce7 <vector111>:
.globl vector111
vector111:
  pushl $0
80107ce7:	6a 00                	push   $0x0
  pushl $111
80107ce9:	6a 6f                	push   $0x6f
  jmp alltraps
80107ceb:	e9 a5 f5 ff ff       	jmp    80107295 <alltraps>

80107cf0 <vector112>:
.globl vector112
vector112:
  pushl $0
80107cf0:	6a 00                	push   $0x0
  pushl $112
80107cf2:	6a 70                	push   $0x70
  jmp alltraps
80107cf4:	e9 9c f5 ff ff       	jmp    80107295 <alltraps>

80107cf9 <vector113>:
.globl vector113
vector113:
  pushl $0
80107cf9:	6a 00                	push   $0x0
  pushl $113
80107cfb:	6a 71                	push   $0x71
  jmp alltraps
80107cfd:	e9 93 f5 ff ff       	jmp    80107295 <alltraps>

80107d02 <vector114>:
.globl vector114
vector114:
  pushl $0
80107d02:	6a 00                	push   $0x0
  pushl $114
80107d04:	6a 72                	push   $0x72
  jmp alltraps
80107d06:	e9 8a f5 ff ff       	jmp    80107295 <alltraps>

80107d0b <vector115>:
.globl vector115
vector115:
  pushl $0
80107d0b:	6a 00                	push   $0x0
  pushl $115
80107d0d:	6a 73                	push   $0x73
  jmp alltraps
80107d0f:	e9 81 f5 ff ff       	jmp    80107295 <alltraps>

80107d14 <vector116>:
.globl vector116
vector116:
  pushl $0
80107d14:	6a 00                	push   $0x0
  pushl $116
80107d16:	6a 74                	push   $0x74
  jmp alltraps
80107d18:	e9 78 f5 ff ff       	jmp    80107295 <alltraps>

80107d1d <vector117>:
.globl vector117
vector117:
  pushl $0
80107d1d:	6a 00                	push   $0x0
  pushl $117
80107d1f:	6a 75                	push   $0x75
  jmp alltraps
80107d21:	e9 6f f5 ff ff       	jmp    80107295 <alltraps>

80107d26 <vector118>:
.globl vector118
vector118:
  pushl $0
80107d26:	6a 00                	push   $0x0
  pushl $118
80107d28:	6a 76                	push   $0x76
  jmp alltraps
80107d2a:	e9 66 f5 ff ff       	jmp    80107295 <alltraps>

80107d2f <vector119>:
.globl vector119
vector119:
  pushl $0
80107d2f:	6a 00                	push   $0x0
  pushl $119
80107d31:	6a 77                	push   $0x77
  jmp alltraps
80107d33:	e9 5d f5 ff ff       	jmp    80107295 <alltraps>

80107d38 <vector120>:
.globl vector120
vector120:
  pushl $0
80107d38:	6a 00                	push   $0x0
  pushl $120
80107d3a:	6a 78                	push   $0x78
  jmp alltraps
80107d3c:	e9 54 f5 ff ff       	jmp    80107295 <alltraps>

80107d41 <vector121>:
.globl vector121
vector121:
  pushl $0
80107d41:	6a 00                	push   $0x0
  pushl $121
80107d43:	6a 79                	push   $0x79
  jmp alltraps
80107d45:	e9 4b f5 ff ff       	jmp    80107295 <alltraps>

80107d4a <vector122>:
.globl vector122
vector122:
  pushl $0
80107d4a:	6a 00                	push   $0x0
  pushl $122
80107d4c:	6a 7a                	push   $0x7a
  jmp alltraps
80107d4e:	e9 42 f5 ff ff       	jmp    80107295 <alltraps>

80107d53 <vector123>:
.globl vector123
vector123:
  pushl $0
80107d53:	6a 00                	push   $0x0
  pushl $123
80107d55:	6a 7b                	push   $0x7b
  jmp alltraps
80107d57:	e9 39 f5 ff ff       	jmp    80107295 <alltraps>

80107d5c <vector124>:
.globl vector124
vector124:
  pushl $0
80107d5c:	6a 00                	push   $0x0
  pushl $124
80107d5e:	6a 7c                	push   $0x7c
  jmp alltraps
80107d60:	e9 30 f5 ff ff       	jmp    80107295 <alltraps>

80107d65 <vector125>:
.globl vector125
vector125:
  pushl $0
80107d65:	6a 00                	push   $0x0
  pushl $125
80107d67:	6a 7d                	push   $0x7d
  jmp alltraps
80107d69:	e9 27 f5 ff ff       	jmp    80107295 <alltraps>

80107d6e <vector126>:
.globl vector126
vector126:
  pushl $0
80107d6e:	6a 00                	push   $0x0
  pushl $126
80107d70:	6a 7e                	push   $0x7e
  jmp alltraps
80107d72:	e9 1e f5 ff ff       	jmp    80107295 <alltraps>

80107d77 <vector127>:
.globl vector127
vector127:
  pushl $0
80107d77:	6a 00                	push   $0x0
  pushl $127
80107d79:	6a 7f                	push   $0x7f
  jmp alltraps
80107d7b:	e9 15 f5 ff ff       	jmp    80107295 <alltraps>

80107d80 <vector128>:
.globl vector128
vector128:
  pushl $0
80107d80:	6a 00                	push   $0x0
  pushl $128
80107d82:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80107d87:	e9 09 f5 ff ff       	jmp    80107295 <alltraps>

80107d8c <vector129>:
.globl vector129
vector129:
  pushl $0
80107d8c:	6a 00                	push   $0x0
  pushl $129
80107d8e:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80107d93:	e9 fd f4 ff ff       	jmp    80107295 <alltraps>

80107d98 <vector130>:
.globl vector130
vector130:
  pushl $0
80107d98:	6a 00                	push   $0x0
  pushl $130
80107d9a:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80107d9f:	e9 f1 f4 ff ff       	jmp    80107295 <alltraps>

80107da4 <vector131>:
.globl vector131
vector131:
  pushl $0
80107da4:	6a 00                	push   $0x0
  pushl $131
80107da6:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80107dab:	e9 e5 f4 ff ff       	jmp    80107295 <alltraps>

80107db0 <vector132>:
.globl vector132
vector132:
  pushl $0
80107db0:	6a 00                	push   $0x0
  pushl $132
80107db2:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80107db7:	e9 d9 f4 ff ff       	jmp    80107295 <alltraps>

80107dbc <vector133>:
.globl vector133
vector133:
  pushl $0
80107dbc:	6a 00                	push   $0x0
  pushl $133
80107dbe:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80107dc3:	e9 cd f4 ff ff       	jmp    80107295 <alltraps>

80107dc8 <vector134>:
.globl vector134
vector134:
  pushl $0
80107dc8:	6a 00                	push   $0x0
  pushl $134
80107dca:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80107dcf:	e9 c1 f4 ff ff       	jmp    80107295 <alltraps>

80107dd4 <vector135>:
.globl vector135
vector135:
  pushl $0
80107dd4:	6a 00                	push   $0x0
  pushl $135
80107dd6:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80107ddb:	e9 b5 f4 ff ff       	jmp    80107295 <alltraps>

80107de0 <vector136>:
.globl vector136
vector136:
  pushl $0
80107de0:	6a 00                	push   $0x0
  pushl $136
80107de2:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80107de7:	e9 a9 f4 ff ff       	jmp    80107295 <alltraps>

80107dec <vector137>:
.globl vector137
vector137:
  pushl $0
80107dec:	6a 00                	push   $0x0
  pushl $137
80107dee:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80107df3:	e9 9d f4 ff ff       	jmp    80107295 <alltraps>

80107df8 <vector138>:
.globl vector138
vector138:
  pushl $0
80107df8:	6a 00                	push   $0x0
  pushl $138
80107dfa:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80107dff:	e9 91 f4 ff ff       	jmp    80107295 <alltraps>

80107e04 <vector139>:
.globl vector139
vector139:
  pushl $0
80107e04:	6a 00                	push   $0x0
  pushl $139
80107e06:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80107e0b:	e9 85 f4 ff ff       	jmp    80107295 <alltraps>

80107e10 <vector140>:
.globl vector140
vector140:
  pushl $0
80107e10:	6a 00                	push   $0x0
  pushl $140
80107e12:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80107e17:	e9 79 f4 ff ff       	jmp    80107295 <alltraps>

80107e1c <vector141>:
.globl vector141
vector141:
  pushl $0
80107e1c:	6a 00                	push   $0x0
  pushl $141
80107e1e:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80107e23:	e9 6d f4 ff ff       	jmp    80107295 <alltraps>

80107e28 <vector142>:
.globl vector142
vector142:
  pushl $0
80107e28:	6a 00                	push   $0x0
  pushl $142
80107e2a:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80107e2f:	e9 61 f4 ff ff       	jmp    80107295 <alltraps>

80107e34 <vector143>:
.globl vector143
vector143:
  pushl $0
80107e34:	6a 00                	push   $0x0
  pushl $143
80107e36:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80107e3b:	e9 55 f4 ff ff       	jmp    80107295 <alltraps>

80107e40 <vector144>:
.globl vector144
vector144:
  pushl $0
80107e40:	6a 00                	push   $0x0
  pushl $144
80107e42:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80107e47:	e9 49 f4 ff ff       	jmp    80107295 <alltraps>

80107e4c <vector145>:
.globl vector145
vector145:
  pushl $0
80107e4c:	6a 00                	push   $0x0
  pushl $145
80107e4e:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80107e53:	e9 3d f4 ff ff       	jmp    80107295 <alltraps>

80107e58 <vector146>:
.globl vector146
vector146:
  pushl $0
80107e58:	6a 00                	push   $0x0
  pushl $146
80107e5a:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80107e5f:	e9 31 f4 ff ff       	jmp    80107295 <alltraps>

80107e64 <vector147>:
.globl vector147
vector147:
  pushl $0
80107e64:	6a 00                	push   $0x0
  pushl $147
80107e66:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80107e6b:	e9 25 f4 ff ff       	jmp    80107295 <alltraps>

80107e70 <vector148>:
.globl vector148
vector148:
  pushl $0
80107e70:	6a 00                	push   $0x0
  pushl $148
80107e72:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80107e77:	e9 19 f4 ff ff       	jmp    80107295 <alltraps>

80107e7c <vector149>:
.globl vector149
vector149:
  pushl $0
80107e7c:	6a 00                	push   $0x0
  pushl $149
80107e7e:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80107e83:	e9 0d f4 ff ff       	jmp    80107295 <alltraps>

80107e88 <vector150>:
.globl vector150
vector150:
  pushl $0
80107e88:	6a 00                	push   $0x0
  pushl $150
80107e8a:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80107e8f:	e9 01 f4 ff ff       	jmp    80107295 <alltraps>

80107e94 <vector151>:
.globl vector151
vector151:
  pushl $0
80107e94:	6a 00                	push   $0x0
  pushl $151
80107e96:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80107e9b:	e9 f5 f3 ff ff       	jmp    80107295 <alltraps>

80107ea0 <vector152>:
.globl vector152
vector152:
  pushl $0
80107ea0:	6a 00                	push   $0x0
  pushl $152
80107ea2:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80107ea7:	e9 e9 f3 ff ff       	jmp    80107295 <alltraps>

80107eac <vector153>:
.globl vector153
vector153:
  pushl $0
80107eac:	6a 00                	push   $0x0
  pushl $153
80107eae:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80107eb3:	e9 dd f3 ff ff       	jmp    80107295 <alltraps>

80107eb8 <vector154>:
.globl vector154
vector154:
  pushl $0
80107eb8:	6a 00                	push   $0x0
  pushl $154
80107eba:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80107ebf:	e9 d1 f3 ff ff       	jmp    80107295 <alltraps>

80107ec4 <vector155>:
.globl vector155
vector155:
  pushl $0
80107ec4:	6a 00                	push   $0x0
  pushl $155
80107ec6:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80107ecb:	e9 c5 f3 ff ff       	jmp    80107295 <alltraps>

80107ed0 <vector156>:
.globl vector156
vector156:
  pushl $0
80107ed0:	6a 00                	push   $0x0
  pushl $156
80107ed2:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80107ed7:	e9 b9 f3 ff ff       	jmp    80107295 <alltraps>

80107edc <vector157>:
.globl vector157
vector157:
  pushl $0
80107edc:	6a 00                	push   $0x0
  pushl $157
80107ede:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80107ee3:	e9 ad f3 ff ff       	jmp    80107295 <alltraps>

80107ee8 <vector158>:
.globl vector158
vector158:
  pushl $0
80107ee8:	6a 00                	push   $0x0
  pushl $158
80107eea:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80107eef:	e9 a1 f3 ff ff       	jmp    80107295 <alltraps>

80107ef4 <vector159>:
.globl vector159
vector159:
  pushl $0
80107ef4:	6a 00                	push   $0x0
  pushl $159
80107ef6:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80107efb:	e9 95 f3 ff ff       	jmp    80107295 <alltraps>

80107f00 <vector160>:
.globl vector160
vector160:
  pushl $0
80107f00:	6a 00                	push   $0x0
  pushl $160
80107f02:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80107f07:	e9 89 f3 ff ff       	jmp    80107295 <alltraps>

80107f0c <vector161>:
.globl vector161
vector161:
  pushl $0
80107f0c:	6a 00                	push   $0x0
  pushl $161
80107f0e:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80107f13:	e9 7d f3 ff ff       	jmp    80107295 <alltraps>

80107f18 <vector162>:
.globl vector162
vector162:
  pushl $0
80107f18:	6a 00                	push   $0x0
  pushl $162
80107f1a:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80107f1f:	e9 71 f3 ff ff       	jmp    80107295 <alltraps>

80107f24 <vector163>:
.globl vector163
vector163:
  pushl $0
80107f24:	6a 00                	push   $0x0
  pushl $163
80107f26:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80107f2b:	e9 65 f3 ff ff       	jmp    80107295 <alltraps>

80107f30 <vector164>:
.globl vector164
vector164:
  pushl $0
80107f30:	6a 00                	push   $0x0
  pushl $164
80107f32:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80107f37:	e9 59 f3 ff ff       	jmp    80107295 <alltraps>

80107f3c <vector165>:
.globl vector165
vector165:
  pushl $0
80107f3c:	6a 00                	push   $0x0
  pushl $165
80107f3e:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80107f43:	e9 4d f3 ff ff       	jmp    80107295 <alltraps>

80107f48 <vector166>:
.globl vector166
vector166:
  pushl $0
80107f48:	6a 00                	push   $0x0
  pushl $166
80107f4a:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80107f4f:	e9 41 f3 ff ff       	jmp    80107295 <alltraps>

80107f54 <vector167>:
.globl vector167
vector167:
  pushl $0
80107f54:	6a 00                	push   $0x0
  pushl $167
80107f56:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80107f5b:	e9 35 f3 ff ff       	jmp    80107295 <alltraps>

80107f60 <vector168>:
.globl vector168
vector168:
  pushl $0
80107f60:	6a 00                	push   $0x0
  pushl $168
80107f62:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80107f67:	e9 29 f3 ff ff       	jmp    80107295 <alltraps>

80107f6c <vector169>:
.globl vector169
vector169:
  pushl $0
80107f6c:	6a 00                	push   $0x0
  pushl $169
80107f6e:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80107f73:	e9 1d f3 ff ff       	jmp    80107295 <alltraps>

80107f78 <vector170>:
.globl vector170
vector170:
  pushl $0
80107f78:	6a 00                	push   $0x0
  pushl $170
80107f7a:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80107f7f:	e9 11 f3 ff ff       	jmp    80107295 <alltraps>

80107f84 <vector171>:
.globl vector171
vector171:
  pushl $0
80107f84:	6a 00                	push   $0x0
  pushl $171
80107f86:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80107f8b:	e9 05 f3 ff ff       	jmp    80107295 <alltraps>

80107f90 <vector172>:
.globl vector172
vector172:
  pushl $0
80107f90:	6a 00                	push   $0x0
  pushl $172
80107f92:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80107f97:	e9 f9 f2 ff ff       	jmp    80107295 <alltraps>

80107f9c <vector173>:
.globl vector173
vector173:
  pushl $0
80107f9c:	6a 00                	push   $0x0
  pushl $173
80107f9e:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80107fa3:	e9 ed f2 ff ff       	jmp    80107295 <alltraps>

80107fa8 <vector174>:
.globl vector174
vector174:
  pushl $0
80107fa8:	6a 00                	push   $0x0
  pushl $174
80107faa:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80107faf:	e9 e1 f2 ff ff       	jmp    80107295 <alltraps>

80107fb4 <vector175>:
.globl vector175
vector175:
  pushl $0
80107fb4:	6a 00                	push   $0x0
  pushl $175
80107fb6:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80107fbb:	e9 d5 f2 ff ff       	jmp    80107295 <alltraps>

80107fc0 <vector176>:
.globl vector176
vector176:
  pushl $0
80107fc0:	6a 00                	push   $0x0
  pushl $176
80107fc2:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80107fc7:	e9 c9 f2 ff ff       	jmp    80107295 <alltraps>

80107fcc <vector177>:
.globl vector177
vector177:
  pushl $0
80107fcc:	6a 00                	push   $0x0
  pushl $177
80107fce:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80107fd3:	e9 bd f2 ff ff       	jmp    80107295 <alltraps>

80107fd8 <vector178>:
.globl vector178
vector178:
  pushl $0
80107fd8:	6a 00                	push   $0x0
  pushl $178
80107fda:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80107fdf:	e9 b1 f2 ff ff       	jmp    80107295 <alltraps>

80107fe4 <vector179>:
.globl vector179
vector179:
  pushl $0
80107fe4:	6a 00                	push   $0x0
  pushl $179
80107fe6:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80107feb:	e9 a5 f2 ff ff       	jmp    80107295 <alltraps>

80107ff0 <vector180>:
.globl vector180
vector180:
  pushl $0
80107ff0:	6a 00                	push   $0x0
  pushl $180
80107ff2:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80107ff7:	e9 99 f2 ff ff       	jmp    80107295 <alltraps>

80107ffc <vector181>:
.globl vector181
vector181:
  pushl $0
80107ffc:	6a 00                	push   $0x0
  pushl $181
80107ffe:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80108003:	e9 8d f2 ff ff       	jmp    80107295 <alltraps>

80108008 <vector182>:
.globl vector182
vector182:
  pushl $0
80108008:	6a 00                	push   $0x0
  pushl $182
8010800a:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
8010800f:	e9 81 f2 ff ff       	jmp    80107295 <alltraps>

80108014 <vector183>:
.globl vector183
vector183:
  pushl $0
80108014:	6a 00                	push   $0x0
  pushl $183
80108016:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
8010801b:	e9 75 f2 ff ff       	jmp    80107295 <alltraps>

80108020 <vector184>:
.globl vector184
vector184:
  pushl $0
80108020:	6a 00                	push   $0x0
  pushl $184
80108022:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80108027:	e9 69 f2 ff ff       	jmp    80107295 <alltraps>

8010802c <vector185>:
.globl vector185
vector185:
  pushl $0
8010802c:	6a 00                	push   $0x0
  pushl $185
8010802e:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80108033:	e9 5d f2 ff ff       	jmp    80107295 <alltraps>

80108038 <vector186>:
.globl vector186
vector186:
  pushl $0
80108038:	6a 00                	push   $0x0
  pushl $186
8010803a:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
8010803f:	e9 51 f2 ff ff       	jmp    80107295 <alltraps>

80108044 <vector187>:
.globl vector187
vector187:
  pushl $0
80108044:	6a 00                	push   $0x0
  pushl $187
80108046:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
8010804b:	e9 45 f2 ff ff       	jmp    80107295 <alltraps>

80108050 <vector188>:
.globl vector188
vector188:
  pushl $0
80108050:	6a 00                	push   $0x0
  pushl $188
80108052:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80108057:	e9 39 f2 ff ff       	jmp    80107295 <alltraps>

8010805c <vector189>:
.globl vector189
vector189:
  pushl $0
8010805c:	6a 00                	push   $0x0
  pushl $189
8010805e:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80108063:	e9 2d f2 ff ff       	jmp    80107295 <alltraps>

80108068 <vector190>:
.globl vector190
vector190:
  pushl $0
80108068:	6a 00                	push   $0x0
  pushl $190
8010806a:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
8010806f:	e9 21 f2 ff ff       	jmp    80107295 <alltraps>

80108074 <vector191>:
.globl vector191
vector191:
  pushl $0
80108074:	6a 00                	push   $0x0
  pushl $191
80108076:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
8010807b:	e9 15 f2 ff ff       	jmp    80107295 <alltraps>

80108080 <vector192>:
.globl vector192
vector192:
  pushl $0
80108080:	6a 00                	push   $0x0
  pushl $192
80108082:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80108087:	e9 09 f2 ff ff       	jmp    80107295 <alltraps>

8010808c <vector193>:
.globl vector193
vector193:
  pushl $0
8010808c:	6a 00                	push   $0x0
  pushl $193
8010808e:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80108093:	e9 fd f1 ff ff       	jmp    80107295 <alltraps>

80108098 <vector194>:
.globl vector194
vector194:
  pushl $0
80108098:	6a 00                	push   $0x0
  pushl $194
8010809a:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
8010809f:	e9 f1 f1 ff ff       	jmp    80107295 <alltraps>

801080a4 <vector195>:
.globl vector195
vector195:
  pushl $0
801080a4:	6a 00                	push   $0x0
  pushl $195
801080a6:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
801080ab:	e9 e5 f1 ff ff       	jmp    80107295 <alltraps>

801080b0 <vector196>:
.globl vector196
vector196:
  pushl $0
801080b0:	6a 00                	push   $0x0
  pushl $196
801080b2:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
801080b7:	e9 d9 f1 ff ff       	jmp    80107295 <alltraps>

801080bc <vector197>:
.globl vector197
vector197:
  pushl $0
801080bc:	6a 00                	push   $0x0
  pushl $197
801080be:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
801080c3:	e9 cd f1 ff ff       	jmp    80107295 <alltraps>

801080c8 <vector198>:
.globl vector198
vector198:
  pushl $0
801080c8:	6a 00                	push   $0x0
  pushl $198
801080ca:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
801080cf:	e9 c1 f1 ff ff       	jmp    80107295 <alltraps>

801080d4 <vector199>:
.globl vector199
vector199:
  pushl $0
801080d4:	6a 00                	push   $0x0
  pushl $199
801080d6:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
801080db:	e9 b5 f1 ff ff       	jmp    80107295 <alltraps>

801080e0 <vector200>:
.globl vector200
vector200:
  pushl $0
801080e0:	6a 00                	push   $0x0
  pushl $200
801080e2:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
801080e7:	e9 a9 f1 ff ff       	jmp    80107295 <alltraps>

801080ec <vector201>:
.globl vector201
vector201:
  pushl $0
801080ec:	6a 00                	push   $0x0
  pushl $201
801080ee:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
801080f3:	e9 9d f1 ff ff       	jmp    80107295 <alltraps>

801080f8 <vector202>:
.globl vector202
vector202:
  pushl $0
801080f8:	6a 00                	push   $0x0
  pushl $202
801080fa:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
801080ff:	e9 91 f1 ff ff       	jmp    80107295 <alltraps>

80108104 <vector203>:
.globl vector203
vector203:
  pushl $0
80108104:	6a 00                	push   $0x0
  pushl $203
80108106:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
8010810b:	e9 85 f1 ff ff       	jmp    80107295 <alltraps>

80108110 <vector204>:
.globl vector204
vector204:
  pushl $0
80108110:	6a 00                	push   $0x0
  pushl $204
80108112:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80108117:	e9 79 f1 ff ff       	jmp    80107295 <alltraps>

8010811c <vector205>:
.globl vector205
vector205:
  pushl $0
8010811c:	6a 00                	push   $0x0
  pushl $205
8010811e:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80108123:	e9 6d f1 ff ff       	jmp    80107295 <alltraps>

80108128 <vector206>:
.globl vector206
vector206:
  pushl $0
80108128:	6a 00                	push   $0x0
  pushl $206
8010812a:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
8010812f:	e9 61 f1 ff ff       	jmp    80107295 <alltraps>

80108134 <vector207>:
.globl vector207
vector207:
  pushl $0
80108134:	6a 00                	push   $0x0
  pushl $207
80108136:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
8010813b:	e9 55 f1 ff ff       	jmp    80107295 <alltraps>

80108140 <vector208>:
.globl vector208
vector208:
  pushl $0
80108140:	6a 00                	push   $0x0
  pushl $208
80108142:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80108147:	e9 49 f1 ff ff       	jmp    80107295 <alltraps>

8010814c <vector209>:
.globl vector209
vector209:
  pushl $0
8010814c:	6a 00                	push   $0x0
  pushl $209
8010814e:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80108153:	e9 3d f1 ff ff       	jmp    80107295 <alltraps>

80108158 <vector210>:
.globl vector210
vector210:
  pushl $0
80108158:	6a 00                	push   $0x0
  pushl $210
8010815a:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
8010815f:	e9 31 f1 ff ff       	jmp    80107295 <alltraps>

80108164 <vector211>:
.globl vector211
vector211:
  pushl $0
80108164:	6a 00                	push   $0x0
  pushl $211
80108166:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
8010816b:	e9 25 f1 ff ff       	jmp    80107295 <alltraps>

80108170 <vector212>:
.globl vector212
vector212:
  pushl $0
80108170:	6a 00                	push   $0x0
  pushl $212
80108172:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80108177:	e9 19 f1 ff ff       	jmp    80107295 <alltraps>

8010817c <vector213>:
.globl vector213
vector213:
  pushl $0
8010817c:	6a 00                	push   $0x0
  pushl $213
8010817e:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80108183:	e9 0d f1 ff ff       	jmp    80107295 <alltraps>

80108188 <vector214>:
.globl vector214
vector214:
  pushl $0
80108188:	6a 00                	push   $0x0
  pushl $214
8010818a:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
8010818f:	e9 01 f1 ff ff       	jmp    80107295 <alltraps>

80108194 <vector215>:
.globl vector215
vector215:
  pushl $0
80108194:	6a 00                	push   $0x0
  pushl $215
80108196:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
8010819b:	e9 f5 f0 ff ff       	jmp    80107295 <alltraps>

801081a0 <vector216>:
.globl vector216
vector216:
  pushl $0
801081a0:	6a 00                	push   $0x0
  pushl $216
801081a2:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
801081a7:	e9 e9 f0 ff ff       	jmp    80107295 <alltraps>

801081ac <vector217>:
.globl vector217
vector217:
  pushl $0
801081ac:	6a 00                	push   $0x0
  pushl $217
801081ae:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
801081b3:	e9 dd f0 ff ff       	jmp    80107295 <alltraps>

801081b8 <vector218>:
.globl vector218
vector218:
  pushl $0
801081b8:	6a 00                	push   $0x0
  pushl $218
801081ba:	68 da 00 00 00       	push   $0xda
  jmp alltraps
801081bf:	e9 d1 f0 ff ff       	jmp    80107295 <alltraps>

801081c4 <vector219>:
.globl vector219
vector219:
  pushl $0
801081c4:	6a 00                	push   $0x0
  pushl $219
801081c6:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
801081cb:	e9 c5 f0 ff ff       	jmp    80107295 <alltraps>

801081d0 <vector220>:
.globl vector220
vector220:
  pushl $0
801081d0:	6a 00                	push   $0x0
  pushl $220
801081d2:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
801081d7:	e9 b9 f0 ff ff       	jmp    80107295 <alltraps>

801081dc <vector221>:
.globl vector221
vector221:
  pushl $0
801081dc:	6a 00                	push   $0x0
  pushl $221
801081de:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
801081e3:	e9 ad f0 ff ff       	jmp    80107295 <alltraps>

801081e8 <vector222>:
.globl vector222
vector222:
  pushl $0
801081e8:	6a 00                	push   $0x0
  pushl $222
801081ea:	68 de 00 00 00       	push   $0xde
  jmp alltraps
801081ef:	e9 a1 f0 ff ff       	jmp    80107295 <alltraps>

801081f4 <vector223>:
.globl vector223
vector223:
  pushl $0
801081f4:	6a 00                	push   $0x0
  pushl $223
801081f6:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
801081fb:	e9 95 f0 ff ff       	jmp    80107295 <alltraps>

80108200 <vector224>:
.globl vector224
vector224:
  pushl $0
80108200:	6a 00                	push   $0x0
  pushl $224
80108202:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80108207:	e9 89 f0 ff ff       	jmp    80107295 <alltraps>

8010820c <vector225>:
.globl vector225
vector225:
  pushl $0
8010820c:	6a 00                	push   $0x0
  pushl $225
8010820e:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80108213:	e9 7d f0 ff ff       	jmp    80107295 <alltraps>

80108218 <vector226>:
.globl vector226
vector226:
  pushl $0
80108218:	6a 00                	push   $0x0
  pushl $226
8010821a:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
8010821f:	e9 71 f0 ff ff       	jmp    80107295 <alltraps>

80108224 <vector227>:
.globl vector227
vector227:
  pushl $0
80108224:	6a 00                	push   $0x0
  pushl $227
80108226:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
8010822b:	e9 65 f0 ff ff       	jmp    80107295 <alltraps>

80108230 <vector228>:
.globl vector228
vector228:
  pushl $0
80108230:	6a 00                	push   $0x0
  pushl $228
80108232:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80108237:	e9 59 f0 ff ff       	jmp    80107295 <alltraps>

8010823c <vector229>:
.globl vector229
vector229:
  pushl $0
8010823c:	6a 00                	push   $0x0
  pushl $229
8010823e:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80108243:	e9 4d f0 ff ff       	jmp    80107295 <alltraps>

80108248 <vector230>:
.globl vector230
vector230:
  pushl $0
80108248:	6a 00                	push   $0x0
  pushl $230
8010824a:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
8010824f:	e9 41 f0 ff ff       	jmp    80107295 <alltraps>

80108254 <vector231>:
.globl vector231
vector231:
  pushl $0
80108254:	6a 00                	push   $0x0
  pushl $231
80108256:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
8010825b:	e9 35 f0 ff ff       	jmp    80107295 <alltraps>

80108260 <vector232>:
.globl vector232
vector232:
  pushl $0
80108260:	6a 00                	push   $0x0
  pushl $232
80108262:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80108267:	e9 29 f0 ff ff       	jmp    80107295 <alltraps>

8010826c <vector233>:
.globl vector233
vector233:
  pushl $0
8010826c:	6a 00                	push   $0x0
  pushl $233
8010826e:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80108273:	e9 1d f0 ff ff       	jmp    80107295 <alltraps>

80108278 <vector234>:
.globl vector234
vector234:
  pushl $0
80108278:	6a 00                	push   $0x0
  pushl $234
8010827a:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
8010827f:	e9 11 f0 ff ff       	jmp    80107295 <alltraps>

80108284 <vector235>:
.globl vector235
vector235:
  pushl $0
80108284:	6a 00                	push   $0x0
  pushl $235
80108286:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
8010828b:	e9 05 f0 ff ff       	jmp    80107295 <alltraps>

80108290 <vector236>:
.globl vector236
vector236:
  pushl $0
80108290:	6a 00                	push   $0x0
  pushl $236
80108292:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80108297:	e9 f9 ef ff ff       	jmp    80107295 <alltraps>

8010829c <vector237>:
.globl vector237
vector237:
  pushl $0
8010829c:	6a 00                	push   $0x0
  pushl $237
8010829e:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
801082a3:	e9 ed ef ff ff       	jmp    80107295 <alltraps>

801082a8 <vector238>:
.globl vector238
vector238:
  pushl $0
801082a8:	6a 00                	push   $0x0
  pushl $238
801082aa:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
801082af:	e9 e1 ef ff ff       	jmp    80107295 <alltraps>

801082b4 <vector239>:
.globl vector239
vector239:
  pushl $0
801082b4:	6a 00                	push   $0x0
  pushl $239
801082b6:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
801082bb:	e9 d5 ef ff ff       	jmp    80107295 <alltraps>

801082c0 <vector240>:
.globl vector240
vector240:
  pushl $0
801082c0:	6a 00                	push   $0x0
  pushl $240
801082c2:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
801082c7:	e9 c9 ef ff ff       	jmp    80107295 <alltraps>

801082cc <vector241>:
.globl vector241
vector241:
  pushl $0
801082cc:	6a 00                	push   $0x0
  pushl $241
801082ce:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
801082d3:	e9 bd ef ff ff       	jmp    80107295 <alltraps>

801082d8 <vector242>:
.globl vector242
vector242:
  pushl $0
801082d8:	6a 00                	push   $0x0
  pushl $242
801082da:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
801082df:	e9 b1 ef ff ff       	jmp    80107295 <alltraps>

801082e4 <vector243>:
.globl vector243
vector243:
  pushl $0
801082e4:	6a 00                	push   $0x0
  pushl $243
801082e6:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
801082eb:	e9 a5 ef ff ff       	jmp    80107295 <alltraps>

801082f0 <vector244>:
.globl vector244
vector244:
  pushl $0
801082f0:	6a 00                	push   $0x0
  pushl $244
801082f2:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
801082f7:	e9 99 ef ff ff       	jmp    80107295 <alltraps>

801082fc <vector245>:
.globl vector245
vector245:
  pushl $0
801082fc:	6a 00                	push   $0x0
  pushl $245
801082fe:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80108303:	e9 8d ef ff ff       	jmp    80107295 <alltraps>

80108308 <vector246>:
.globl vector246
vector246:
  pushl $0
80108308:	6a 00                	push   $0x0
  pushl $246
8010830a:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
8010830f:	e9 81 ef ff ff       	jmp    80107295 <alltraps>

80108314 <vector247>:
.globl vector247
vector247:
  pushl $0
80108314:	6a 00                	push   $0x0
  pushl $247
80108316:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
8010831b:	e9 75 ef ff ff       	jmp    80107295 <alltraps>

80108320 <vector248>:
.globl vector248
vector248:
  pushl $0
80108320:	6a 00                	push   $0x0
  pushl $248
80108322:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80108327:	e9 69 ef ff ff       	jmp    80107295 <alltraps>

8010832c <vector249>:
.globl vector249
vector249:
  pushl $0
8010832c:	6a 00                	push   $0x0
  pushl $249
8010832e:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80108333:	e9 5d ef ff ff       	jmp    80107295 <alltraps>

80108338 <vector250>:
.globl vector250
vector250:
  pushl $0
80108338:	6a 00                	push   $0x0
  pushl $250
8010833a:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
8010833f:	e9 51 ef ff ff       	jmp    80107295 <alltraps>

80108344 <vector251>:
.globl vector251
vector251:
  pushl $0
80108344:	6a 00                	push   $0x0
  pushl $251
80108346:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
8010834b:	e9 45 ef ff ff       	jmp    80107295 <alltraps>

80108350 <vector252>:
.globl vector252
vector252:
  pushl $0
80108350:	6a 00                	push   $0x0
  pushl $252
80108352:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80108357:	e9 39 ef ff ff       	jmp    80107295 <alltraps>

8010835c <vector253>:
.globl vector253
vector253:
  pushl $0
8010835c:	6a 00                	push   $0x0
  pushl $253
8010835e:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80108363:	e9 2d ef ff ff       	jmp    80107295 <alltraps>

80108368 <vector254>:
.globl vector254
vector254:
  pushl $0
80108368:	6a 00                	push   $0x0
  pushl $254
8010836a:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
8010836f:	e9 21 ef ff ff       	jmp    80107295 <alltraps>

80108374 <vector255>:
.globl vector255
vector255:
  pushl $0
80108374:	6a 00                	push   $0x0
  pushl $255
80108376:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
8010837b:	e9 15 ef ff ff       	jmp    80107295 <alltraps>

80108380 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
80108380:	55                   	push   %ebp
80108381:	89 e5                	mov    %esp,%ebp
80108383:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80108386:	8b 45 0c             	mov    0xc(%ebp),%eax
80108389:	83 e8 01             	sub    $0x1,%eax
8010838c:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80108390:	8b 45 08             	mov    0x8(%ebp),%eax
80108393:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80108397:	8b 45 08             	mov    0x8(%ebp),%eax
8010839a:	c1 e8 10             	shr    $0x10,%eax
8010839d:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
801083a1:	8d 45 fa             	lea    -0x6(%ebp),%eax
801083a4:	0f 01 10             	lgdtl  (%eax)
}
801083a7:	c9                   	leave  
801083a8:	c3                   	ret    

801083a9 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
801083a9:	55                   	push   %ebp
801083aa:	89 e5                	mov    %esp,%ebp
801083ac:	83 ec 04             	sub    $0x4,%esp
801083af:	8b 45 08             	mov    0x8(%ebp),%eax
801083b2:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
801083b6:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801083ba:	0f 00 d8             	ltr    %ax
}
801083bd:	c9                   	leave  
801083be:	c3                   	ret    

801083bf <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
801083bf:	55                   	push   %ebp
801083c0:	89 e5                	mov    %esp,%ebp
801083c2:	83 ec 04             	sub    $0x4,%esp
801083c5:	8b 45 08             	mov    0x8(%ebp),%eax
801083c8:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
801083cc:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801083d0:	8e e8                	mov    %eax,%gs
}
801083d2:	c9                   	leave  
801083d3:	c3                   	ret    

801083d4 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
801083d4:	55                   	push   %ebp
801083d5:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
801083d7:	8b 45 08             	mov    0x8(%ebp),%eax
801083da:	0f 22 d8             	mov    %eax,%cr3
}
801083dd:	5d                   	pop    %ebp
801083de:	c3                   	ret    

801083df <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
801083df:	55                   	push   %ebp
801083e0:	89 e5                	mov    %esp,%ebp
801083e2:	8b 45 08             	mov    0x8(%ebp),%eax
801083e5:	05 00 00 00 80       	add    $0x80000000,%eax
801083ea:	5d                   	pop    %ebp
801083eb:	c3                   	ret    

801083ec <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
801083ec:	55                   	push   %ebp
801083ed:	89 e5                	mov    %esp,%ebp
801083ef:	8b 45 08             	mov    0x8(%ebp),%eax
801083f2:	05 00 00 00 80       	add    $0x80000000,%eax
801083f7:	5d                   	pop    %ebp
801083f8:	c3                   	ret    

801083f9 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
801083f9:	55                   	push   %ebp
801083fa:	89 e5                	mov    %esp,%ebp
801083fc:	53                   	push   %ebx
801083fd:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
80108400:	e8 46 ac ff ff       	call   8010304b <cpunum>
80108405:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
8010840b:	05 c0 33 11 80       	add    $0x801133c0,%eax
80108410:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80108413:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108416:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
8010841c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010841f:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
80108425:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108428:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
8010842c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010842f:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108433:	83 e2 f0             	and    $0xfffffff0,%edx
80108436:	83 ca 0a             	or     $0xa,%edx
80108439:	88 50 7d             	mov    %dl,0x7d(%eax)
8010843c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010843f:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108443:	83 ca 10             	or     $0x10,%edx
80108446:	88 50 7d             	mov    %dl,0x7d(%eax)
80108449:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010844c:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80108450:	83 e2 9f             	and    $0xffffff9f,%edx
80108453:	88 50 7d             	mov    %dl,0x7d(%eax)
80108456:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108459:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010845d:	83 ca 80             	or     $0xffffff80,%edx
80108460:	88 50 7d             	mov    %dl,0x7d(%eax)
80108463:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108466:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010846a:	83 ca 0f             	or     $0xf,%edx
8010846d:	88 50 7e             	mov    %dl,0x7e(%eax)
80108470:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108473:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108477:	83 e2 ef             	and    $0xffffffef,%edx
8010847a:	88 50 7e             	mov    %dl,0x7e(%eax)
8010847d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108480:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108484:	83 e2 df             	and    $0xffffffdf,%edx
80108487:	88 50 7e             	mov    %dl,0x7e(%eax)
8010848a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010848d:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80108491:	83 ca 40             	or     $0x40,%edx
80108494:	88 50 7e             	mov    %dl,0x7e(%eax)
80108497:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010849a:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010849e:	83 ca 80             	or     $0xffffff80,%edx
801084a1:	88 50 7e             	mov    %dl,0x7e(%eax)
801084a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084a7:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
801084ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084ae:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
801084b5:	ff ff 
801084b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084ba:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
801084c1:	00 00 
801084c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084c6:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
801084cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084d0:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801084d7:	83 e2 f0             	and    $0xfffffff0,%edx
801084da:	83 ca 02             	or     $0x2,%edx
801084dd:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801084e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084e6:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801084ed:	83 ca 10             	or     $0x10,%edx
801084f0:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801084f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084f9:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108500:	83 e2 9f             	and    $0xffffff9f,%edx
80108503:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80108509:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010850c:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80108513:	83 ca 80             	or     $0xffffff80,%edx
80108516:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010851c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010851f:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108526:	83 ca 0f             	or     $0xf,%edx
80108529:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010852f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108532:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108539:	83 e2 ef             	and    $0xffffffef,%edx
8010853c:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108542:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108545:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010854c:	83 e2 df             	and    $0xffffffdf,%edx
8010854f:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108555:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108558:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010855f:	83 ca 40             	or     $0x40,%edx
80108562:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80108568:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010856b:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80108572:	83 ca 80             	or     $0xffffff80,%edx
80108575:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010857b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010857e:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80108585:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108588:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
8010858f:	ff ff 
80108591:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108594:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
8010859b:	00 00 
8010859d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085a0:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
801085a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085aa:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801085b1:	83 e2 f0             	and    $0xfffffff0,%edx
801085b4:	83 ca 0a             	or     $0xa,%edx
801085b7:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801085bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085c0:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801085c7:	83 ca 10             	or     $0x10,%edx
801085ca:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801085d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085d3:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801085da:	83 ca 60             	or     $0x60,%edx
801085dd:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801085e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085e6:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801085ed:	83 ca 80             	or     $0xffffff80,%edx
801085f0:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801085f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085f9:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108600:	83 ca 0f             	or     $0xf,%edx
80108603:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108609:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010860c:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108613:	83 e2 ef             	and    $0xffffffef,%edx
80108616:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010861c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010861f:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108626:	83 e2 df             	and    $0xffffffdf,%edx
80108629:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
8010862f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108632:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80108639:	83 ca 40             	or     $0x40,%edx
8010863c:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108642:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108645:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010864c:	83 ca 80             	or     $0xffffff80,%edx
8010864f:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80108655:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108658:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
8010865f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108662:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80108669:	ff ff 
8010866b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010866e:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80108675:	00 00 
80108677:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010867a:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
80108681:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108684:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010868b:	83 e2 f0             	and    $0xfffffff0,%edx
8010868e:	83 ca 02             	or     $0x2,%edx
80108691:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80108697:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010869a:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801086a1:	83 ca 10             	or     $0x10,%edx
801086a4:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801086aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086ad:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801086b4:	83 ca 60             	or     $0x60,%edx
801086b7:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801086bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086c0:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801086c7:	83 ca 80             	or     $0xffffff80,%edx
801086ca:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801086d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086d3:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801086da:	83 ca 0f             	or     $0xf,%edx
801086dd:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801086e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086e6:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801086ed:	83 e2 ef             	and    $0xffffffef,%edx
801086f0:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801086f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086f9:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108700:	83 e2 df             	and    $0xffffffdf,%edx
80108703:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80108709:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010870c:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108713:	83 ca 40             	or     $0x40,%edx
80108716:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010871c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010871f:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80108726:	83 ca 80             	or     $0xffffff80,%edx
80108729:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010872f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108732:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80108739:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010873c:	05 b4 00 00 00       	add    $0xb4,%eax
80108741:	89 c3                	mov    %eax,%ebx
80108743:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108746:	05 b4 00 00 00       	add    $0xb4,%eax
8010874b:	c1 e8 10             	shr    $0x10,%eax
8010874e:	89 c1                	mov    %eax,%ecx
80108750:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108753:	05 b4 00 00 00       	add    $0xb4,%eax
80108758:	c1 e8 18             	shr    $0x18,%eax
8010875b:	89 c2                	mov    %eax,%edx
8010875d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108760:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80108767:	00 00 
80108769:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010876c:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80108773:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108776:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
8010877c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010877f:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80108786:	83 e1 f0             	and    $0xfffffff0,%ecx
80108789:	83 c9 02             	or     $0x2,%ecx
8010878c:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80108792:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108795:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
8010879c:	83 c9 10             	or     $0x10,%ecx
8010879f:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801087a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087a8:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801087af:	83 e1 9f             	and    $0xffffff9f,%ecx
801087b2:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801087b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087bb:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801087c2:	83 c9 80             	or     $0xffffff80,%ecx
801087c5:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801087cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087ce:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801087d5:	83 e1 f0             	and    $0xfffffff0,%ecx
801087d8:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801087de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087e1:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801087e8:	83 e1 ef             	and    $0xffffffef,%ecx
801087eb:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801087f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087f4:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801087fb:	83 e1 df             	and    $0xffffffdf,%ecx
801087fe:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108804:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108807:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
8010880e:	83 c9 40             	or     $0x40,%ecx
80108811:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80108817:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010881a:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80108821:	83 c9 80             	or     $0xffffff80,%ecx
80108824:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
8010882a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010882d:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
80108833:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108836:	83 c0 70             	add    $0x70,%eax
80108839:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80108840:	00 
80108841:	89 04 24             	mov    %eax,(%esp)
80108844:	e8 37 fb ff ff       	call   80108380 <lgdt>
  loadgs(SEG_KCPU << 3);
80108849:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80108850:	e8 6a fb ff ff       	call   801083bf <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80108855:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108858:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
8010885e:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80108865:	00 00 00 00 
}
80108869:	83 c4 24             	add    $0x24,%esp
8010886c:	5b                   	pop    %ebx
8010886d:	5d                   	pop    %ebp
8010886e:	c3                   	ret    

8010886f <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
8010886f:	55                   	push   %ebp
80108870:	89 e5                	mov    %esp,%ebp
80108872:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80108875:	8b 45 0c             	mov    0xc(%ebp),%eax
80108878:	c1 e8 16             	shr    $0x16,%eax
8010887b:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108882:	8b 45 08             	mov    0x8(%ebp),%eax
80108885:	01 d0                	add    %edx,%eax
80108887:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
8010888a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010888d:	8b 00                	mov    (%eax),%eax
8010888f:	83 e0 01             	and    $0x1,%eax
80108892:	85 c0                	test   %eax,%eax
80108894:	74 17                	je     801088ad <walkpgdir+0x3e>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80108896:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108899:	8b 00                	mov    (%eax),%eax
8010889b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801088a0:	89 04 24             	mov    %eax,(%esp)
801088a3:	e8 44 fb ff ff       	call   801083ec <p2v>
801088a8:	89 45 f4             	mov    %eax,-0xc(%ebp)
801088ab:	eb 4b                	jmp    801088f8 <walkpgdir+0x89>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
801088ad:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801088b1:	74 0e                	je     801088c1 <walkpgdir+0x52>
801088b3:	e8 fd a3 ff ff       	call   80102cb5 <kalloc>
801088b8:	89 45 f4             	mov    %eax,-0xc(%ebp)
801088bb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801088bf:	75 07                	jne    801088c8 <walkpgdir+0x59>
      return 0;
801088c1:	b8 00 00 00 00       	mov    $0x0,%eax
801088c6:	eb 47                	jmp    8010890f <walkpgdir+0xa0>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
801088c8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801088cf:	00 
801088d0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801088d7:	00 
801088d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088db:	89 04 24             	mov    %eax,(%esp)
801088de:	e8 47 d4 ff ff       	call   80105d2a <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
801088e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801088e6:	89 04 24             	mov    %eax,(%esp)
801088e9:	e8 f1 fa ff ff       	call   801083df <v2p>
801088ee:	83 c8 07             	or     $0x7,%eax
801088f1:	89 c2                	mov    %eax,%edx
801088f3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801088f6:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
801088f8:	8b 45 0c             	mov    0xc(%ebp),%eax
801088fb:	c1 e8 0c             	shr    $0xc,%eax
801088fe:	25 ff 03 00 00       	and    $0x3ff,%eax
80108903:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010890a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010890d:	01 d0                	add    %edx,%eax
}
8010890f:	c9                   	leave  
80108910:	c3                   	ret    

80108911 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80108911:	55                   	push   %ebp
80108912:	89 e5                	mov    %esp,%ebp
80108914:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80108917:	8b 45 0c             	mov    0xc(%ebp),%eax
8010891a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010891f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80108922:	8b 55 0c             	mov    0xc(%ebp),%edx
80108925:	8b 45 10             	mov    0x10(%ebp),%eax
80108928:	01 d0                	add    %edx,%eax
8010892a:	83 e8 01             	sub    $0x1,%eax
8010892d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108932:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80108935:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
8010893c:	00 
8010893d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108940:	89 44 24 04          	mov    %eax,0x4(%esp)
80108944:	8b 45 08             	mov    0x8(%ebp),%eax
80108947:	89 04 24             	mov    %eax,(%esp)
8010894a:	e8 20 ff ff ff       	call   8010886f <walkpgdir>
8010894f:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108952:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108956:	75 07                	jne    8010895f <mappages+0x4e>
      return -1;
80108958:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010895d:	eb 48                	jmp    801089a7 <mappages+0x96>
    if(*pte & PTE_P)
8010895f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108962:	8b 00                	mov    (%eax),%eax
80108964:	83 e0 01             	and    $0x1,%eax
80108967:	85 c0                	test   %eax,%eax
80108969:	74 0c                	je     80108977 <mappages+0x66>
      panic("remap");
8010896b:	c7 04 24 80 98 10 80 	movl   $0x80109880,(%esp)
80108972:	e8 c3 7b ff ff       	call   8010053a <panic>
    *pte = pa | perm | PTE_P;
80108977:	8b 45 18             	mov    0x18(%ebp),%eax
8010897a:	0b 45 14             	or     0x14(%ebp),%eax
8010897d:	83 c8 01             	or     $0x1,%eax
80108980:	89 c2                	mov    %eax,%edx
80108982:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108985:	89 10                	mov    %edx,(%eax)
    if(a == last)
80108987:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010898a:	3b 45 f0             	cmp    -0x10(%ebp),%eax
8010898d:	75 08                	jne    80108997 <mappages+0x86>
      break;
8010898f:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80108990:	b8 00 00 00 00       	mov    $0x0,%eax
80108995:	eb 10                	jmp    801089a7 <mappages+0x96>
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
    a += PGSIZE;
80108997:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
8010899e:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
801089a5:	eb 8e                	jmp    80108935 <mappages+0x24>
  return 0;
}
801089a7:	c9                   	leave  
801089a8:	c3                   	ret    

801089a9 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
{
801089a9:	55                   	push   %ebp
801089aa:	89 e5                	mov    %esp,%ebp
801089ac:	53                   	push   %ebx
801089ad:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
801089b0:	e8 00 a3 ff ff       	call   80102cb5 <kalloc>
801089b5:	89 45 f0             	mov    %eax,-0x10(%ebp)
801089b8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801089bc:	75 0a                	jne    801089c8 <setupkvm+0x1f>
    return 0;
801089be:	b8 00 00 00 00       	mov    $0x0,%eax
801089c3:	e9 98 00 00 00       	jmp    80108a60 <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
801089c8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801089cf:	00 
801089d0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801089d7:	00 
801089d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801089db:	89 04 24             	mov    %eax,(%esp)
801089de:	e8 47 d3 ff ff       	call   80105d2a <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
801089e3:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
801089ea:	e8 fd f9 ff ff       	call   801083ec <p2v>
801089ef:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
801089f4:	76 0c                	jbe    80108a02 <setupkvm+0x59>
    panic("PHYSTOP too high");
801089f6:	c7 04 24 86 98 10 80 	movl   $0x80109886,(%esp)
801089fd:	e8 38 7b ff ff       	call   8010053a <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108a02:	c7 45 f4 c0 c4 10 80 	movl   $0x8010c4c0,-0xc(%ebp)
80108a09:	eb 49                	jmp    80108a54 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80108a0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a0e:	8b 48 0c             	mov    0xc(%eax),%ecx
80108a11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a14:	8b 50 04             	mov    0x4(%eax),%edx
80108a17:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a1a:	8b 58 08             	mov    0x8(%eax),%ebx
80108a1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a20:	8b 40 04             	mov    0x4(%eax),%eax
80108a23:	29 c3                	sub    %eax,%ebx
80108a25:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108a28:	8b 00                	mov    (%eax),%eax
80108a2a:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80108a2e:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108a32:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108a36:	89 44 24 04          	mov    %eax,0x4(%esp)
80108a3a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108a3d:	89 04 24             	mov    %eax,(%esp)
80108a40:	e8 cc fe ff ff       	call   80108911 <mappages>
80108a45:	85 c0                	test   %eax,%eax
80108a47:	79 07                	jns    80108a50 <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80108a49:	b8 00 00 00 00       	mov    $0x0,%eax
80108a4e:	eb 10                	jmp    80108a60 <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80108a50:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80108a54:	81 7d f4 00 c5 10 80 	cmpl   $0x8010c500,-0xc(%ebp)
80108a5b:	72 ae                	jb     80108a0b <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80108a5d:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80108a60:	83 c4 34             	add    $0x34,%esp
80108a63:	5b                   	pop    %ebx
80108a64:	5d                   	pop    %ebp
80108a65:	c3                   	ret    

80108a66 <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80108a66:	55                   	push   %ebp
80108a67:	89 e5                	mov    %esp,%ebp
80108a69:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80108a6c:	e8 38 ff ff ff       	call   801089a9 <setupkvm>
80108a71:	a3 98 7b 11 80       	mov    %eax,0x80117b98
  switchkvm();
80108a76:	e8 02 00 00 00       	call   80108a7d <switchkvm>
}
80108a7b:	c9                   	leave  
80108a7c:	c3                   	ret    

80108a7d <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80108a7d:	55                   	push   %ebp
80108a7e:	89 e5                	mov    %esp,%ebp
80108a80:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80108a83:	a1 98 7b 11 80       	mov    0x80117b98,%eax
80108a88:	89 04 24             	mov    %eax,(%esp)
80108a8b:	e8 4f f9 ff ff       	call   801083df <v2p>
80108a90:	89 04 24             	mov    %eax,(%esp)
80108a93:	e8 3c f9 ff ff       	call   801083d4 <lcr3>
}
80108a98:	c9                   	leave  
80108a99:	c3                   	ret    

80108a9a <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80108a9a:	55                   	push   %ebp
80108a9b:	89 e5                	mov    %esp,%ebp
80108a9d:	53                   	push   %ebx
80108a9e:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80108aa1:	e8 84 d1 ff ff       	call   80105c2a <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
80108aa6:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108aac:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108ab3:	83 c2 08             	add    $0x8,%edx
80108ab6:	89 d3                	mov    %edx,%ebx
80108ab8:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108abf:	83 c2 08             	add    $0x8,%edx
80108ac2:	c1 ea 10             	shr    $0x10,%edx
80108ac5:	89 d1                	mov    %edx,%ecx
80108ac7:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80108ace:	83 c2 08             	add    $0x8,%edx
80108ad1:	c1 ea 18             	shr    $0x18,%edx
80108ad4:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80108adb:	67 00 
80108add:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80108ae4:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80108aea:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108af1:	83 e1 f0             	and    $0xfffffff0,%ecx
80108af4:	83 c9 09             	or     $0x9,%ecx
80108af7:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108afd:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108b04:	83 c9 10             	or     $0x10,%ecx
80108b07:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108b0d:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108b14:	83 e1 9f             	and    $0xffffff9f,%ecx
80108b17:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108b1d:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80108b24:	83 c9 80             	or     $0xffffff80,%ecx
80108b27:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80108b2d:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108b34:	83 e1 f0             	and    $0xfffffff0,%ecx
80108b37:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108b3d:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108b44:	83 e1 ef             	and    $0xffffffef,%ecx
80108b47:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108b4d:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108b54:	83 e1 df             	and    $0xffffffdf,%ecx
80108b57:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108b5d:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108b64:	83 c9 40             	or     $0x40,%ecx
80108b67:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108b6d:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108b74:	83 e1 7f             	and    $0x7f,%ecx
80108b77:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108b7d:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
80108b83:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108b89:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80108b90:	83 e2 ef             	and    $0xffffffef,%edx
80108b93:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80108b99:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108b9f:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80108ba5:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108bab:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80108bb2:	8b 52 08             	mov    0x8(%edx),%edx
80108bb5:	81 c2 00 10 00 00    	add    $0x1000,%edx
80108bbb:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
80108bbe:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80108bc5:	e8 df f7 ff ff       	call   801083a9 <ltr>
  if(p->pgdir == 0)
80108bca:	8b 45 08             	mov    0x8(%ebp),%eax
80108bcd:	8b 40 04             	mov    0x4(%eax),%eax
80108bd0:	85 c0                	test   %eax,%eax
80108bd2:	75 0c                	jne    80108be0 <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80108bd4:	c7 04 24 97 98 10 80 	movl   $0x80109897,(%esp)
80108bdb:	e8 5a 79 ff ff       	call   8010053a <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80108be0:	8b 45 08             	mov    0x8(%ebp),%eax
80108be3:	8b 40 04             	mov    0x4(%eax),%eax
80108be6:	89 04 24             	mov    %eax,(%esp)
80108be9:	e8 f1 f7 ff ff       	call   801083df <v2p>
80108bee:	89 04 24             	mov    %eax,(%esp)
80108bf1:	e8 de f7 ff ff       	call   801083d4 <lcr3>
  popcli();
80108bf6:	e8 73 d0 ff ff       	call   80105c6e <popcli>
}
80108bfb:	83 c4 14             	add    $0x14,%esp
80108bfe:	5b                   	pop    %ebx
80108bff:	5d                   	pop    %ebp
80108c00:	c3                   	ret    

80108c01 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80108c01:	55                   	push   %ebp
80108c02:	89 e5                	mov    %esp,%ebp
80108c04:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80108c07:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80108c0e:	76 0c                	jbe    80108c1c <inituvm+0x1b>
    panic("inituvm: more than a page");
80108c10:	c7 04 24 ab 98 10 80 	movl   $0x801098ab,(%esp)
80108c17:	e8 1e 79 ff ff       	call   8010053a <panic>
  mem = kalloc();
80108c1c:	e8 94 a0 ff ff       	call   80102cb5 <kalloc>
80108c21:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80108c24:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108c2b:	00 
80108c2c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108c33:	00 
80108c34:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c37:	89 04 24             	mov    %eax,(%esp)
80108c3a:	e8 eb d0 ff ff       	call   80105d2a <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108c3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c42:	89 04 24             	mov    %eax,(%esp)
80108c45:	e8 95 f7 ff ff       	call   801083df <v2p>
80108c4a:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108c51:	00 
80108c52:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108c56:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108c5d:	00 
80108c5e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108c65:	00 
80108c66:	8b 45 08             	mov    0x8(%ebp),%eax
80108c69:	89 04 24             	mov    %eax,(%esp)
80108c6c:	e8 a0 fc ff ff       	call   80108911 <mappages>
  memmove(mem, init, sz);
80108c71:	8b 45 10             	mov    0x10(%ebp),%eax
80108c74:	89 44 24 08          	mov    %eax,0x8(%esp)
80108c78:	8b 45 0c             	mov    0xc(%ebp),%eax
80108c7b:	89 44 24 04          	mov    %eax,0x4(%esp)
80108c7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108c82:	89 04 24             	mov    %eax,(%esp)
80108c85:	e8 6f d1 ff ff       	call   80105df9 <memmove>
}
80108c8a:	c9                   	leave  
80108c8b:	c3                   	ret    

80108c8c <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80108c8c:	55                   	push   %ebp
80108c8d:	89 e5                	mov    %esp,%ebp
80108c8f:	53                   	push   %ebx
80108c90:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80108c93:	8b 45 0c             	mov    0xc(%ebp),%eax
80108c96:	25 ff 0f 00 00       	and    $0xfff,%eax
80108c9b:	85 c0                	test   %eax,%eax
80108c9d:	74 0c                	je     80108cab <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
80108c9f:	c7 04 24 c8 98 10 80 	movl   $0x801098c8,(%esp)
80108ca6:	e8 8f 78 ff ff       	call   8010053a <panic>
  for(i = 0; i < sz; i += PGSIZE){
80108cab:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108cb2:	e9 a9 00 00 00       	jmp    80108d60 <loaduvm+0xd4>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80108cb7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cba:	8b 55 0c             	mov    0xc(%ebp),%edx
80108cbd:	01 d0                	add    %edx,%eax
80108cbf:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108cc6:	00 
80108cc7:	89 44 24 04          	mov    %eax,0x4(%esp)
80108ccb:	8b 45 08             	mov    0x8(%ebp),%eax
80108cce:	89 04 24             	mov    %eax,(%esp)
80108cd1:	e8 99 fb ff ff       	call   8010886f <walkpgdir>
80108cd6:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108cd9:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108cdd:	75 0c                	jne    80108ceb <loaduvm+0x5f>
      panic("loaduvm: address should exist");
80108cdf:	c7 04 24 eb 98 10 80 	movl   $0x801098eb,(%esp)
80108ce6:	e8 4f 78 ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
80108ceb:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108cee:	8b 00                	mov    (%eax),%eax
80108cf0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108cf5:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80108cf8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108cfb:	8b 55 18             	mov    0x18(%ebp),%edx
80108cfe:	29 c2                	sub    %eax,%edx
80108d00:	89 d0                	mov    %edx,%eax
80108d02:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80108d07:	77 0f                	ja     80108d18 <loaduvm+0x8c>
      n = sz - i;
80108d09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d0c:	8b 55 18             	mov    0x18(%ebp),%edx
80108d0f:	29 c2                	sub    %eax,%edx
80108d11:	89 d0                	mov    %edx,%eax
80108d13:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108d16:	eb 07                	jmp    80108d1f <loaduvm+0x93>
    else
      n = PGSIZE;
80108d18:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
80108d1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d22:	8b 55 14             	mov    0x14(%ebp),%edx
80108d25:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80108d28:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108d2b:	89 04 24             	mov    %eax,(%esp)
80108d2e:	e8 b9 f6 ff ff       	call   801083ec <p2v>
80108d33:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108d36:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108d3a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108d3e:	89 44 24 04          	mov    %eax,0x4(%esp)
80108d42:	8b 45 10             	mov    0x10(%ebp),%eax
80108d45:	89 04 24             	mov    %eax,(%esp)
80108d48:	e8 d3 90 ff ff       	call   80101e20 <readi>
80108d4d:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108d50:	74 07                	je     80108d59 <loaduvm+0xcd>
      return -1;
80108d52:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108d57:	eb 18                	jmp    80108d71 <loaduvm+0xe5>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80108d59:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108d60:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108d63:	3b 45 18             	cmp    0x18(%ebp),%eax
80108d66:	0f 82 4b ff ff ff    	jb     80108cb7 <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80108d6c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108d71:	83 c4 24             	add    $0x24,%esp
80108d74:	5b                   	pop    %ebx
80108d75:	5d                   	pop    %ebp
80108d76:	c3                   	ret    

80108d77 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80108d77:	55                   	push   %ebp
80108d78:	89 e5                	mov    %esp,%ebp
80108d7a:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80108d7d:	8b 45 10             	mov    0x10(%ebp),%eax
80108d80:	85 c0                	test   %eax,%eax
80108d82:	79 0a                	jns    80108d8e <allocuvm+0x17>
    return 0;
80108d84:	b8 00 00 00 00       	mov    $0x0,%eax
80108d89:	e9 c1 00 00 00       	jmp    80108e4f <allocuvm+0xd8>
  if(newsz < oldsz)
80108d8e:	8b 45 10             	mov    0x10(%ebp),%eax
80108d91:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108d94:	73 08                	jae    80108d9e <allocuvm+0x27>
    return oldsz;
80108d96:	8b 45 0c             	mov    0xc(%ebp),%eax
80108d99:	e9 b1 00 00 00       	jmp    80108e4f <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
80108d9e:	8b 45 0c             	mov    0xc(%ebp),%eax
80108da1:	05 ff 0f 00 00       	add    $0xfff,%eax
80108da6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108dab:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
80108dae:	e9 8d 00 00 00       	jmp    80108e40 <allocuvm+0xc9>
    mem = kalloc();
80108db3:	e8 fd 9e ff ff       	call   80102cb5 <kalloc>
80108db8:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
80108dbb:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108dbf:	75 2c                	jne    80108ded <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
80108dc1:	c7 04 24 09 99 10 80 	movl   $0x80109909,(%esp)
80108dc8:	e8 d3 75 ff ff       	call   801003a0 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80108dcd:	8b 45 0c             	mov    0xc(%ebp),%eax
80108dd0:	89 44 24 08          	mov    %eax,0x8(%esp)
80108dd4:	8b 45 10             	mov    0x10(%ebp),%eax
80108dd7:	89 44 24 04          	mov    %eax,0x4(%esp)
80108ddb:	8b 45 08             	mov    0x8(%ebp),%eax
80108dde:	89 04 24             	mov    %eax,(%esp)
80108de1:	e8 6b 00 00 00       	call   80108e51 <deallocuvm>
      return 0;
80108de6:	b8 00 00 00 00       	mov    $0x0,%eax
80108deb:	eb 62                	jmp    80108e4f <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
80108ded:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108df4:	00 
80108df5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108dfc:	00 
80108dfd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108e00:	89 04 24             	mov    %eax,(%esp)
80108e03:	e8 22 cf ff ff       	call   80105d2a <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108e08:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108e0b:	89 04 24             	mov    %eax,(%esp)
80108e0e:	e8 cc f5 ff ff       	call   801083df <v2p>
80108e13:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108e16:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108e1d:	00 
80108e1e:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108e22:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108e29:	00 
80108e2a:	89 54 24 04          	mov    %edx,0x4(%esp)
80108e2e:	8b 45 08             	mov    0x8(%ebp),%eax
80108e31:	89 04 24             	mov    %eax,(%esp)
80108e34:	e8 d8 fa ff ff       	call   80108911 <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80108e39:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108e40:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e43:	3b 45 10             	cmp    0x10(%ebp),%eax
80108e46:	0f 82 67 ff ff ff    	jb     80108db3 <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
80108e4c:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108e4f:	c9                   	leave  
80108e50:	c3                   	ret    

80108e51 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80108e51:	55                   	push   %ebp
80108e52:	89 e5                	mov    %esp,%ebp
80108e54:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80108e57:	8b 45 10             	mov    0x10(%ebp),%eax
80108e5a:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108e5d:	72 08                	jb     80108e67 <deallocuvm+0x16>
    return oldsz;
80108e5f:	8b 45 0c             	mov    0xc(%ebp),%eax
80108e62:	e9 a4 00 00 00       	jmp    80108f0b <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
80108e67:	8b 45 10             	mov    0x10(%ebp),%eax
80108e6a:	05 ff 0f 00 00       	add    $0xfff,%eax
80108e6f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108e74:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80108e77:	e9 80 00 00 00       	jmp    80108efc <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
80108e7c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108e7f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108e86:	00 
80108e87:	89 44 24 04          	mov    %eax,0x4(%esp)
80108e8b:	8b 45 08             	mov    0x8(%ebp),%eax
80108e8e:	89 04 24             	mov    %eax,(%esp)
80108e91:	e8 d9 f9 ff ff       	call   8010886f <walkpgdir>
80108e96:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
80108e99:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108e9d:	75 09                	jne    80108ea8 <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
80108e9f:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
80108ea6:	eb 4d                	jmp    80108ef5 <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
80108ea8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108eab:	8b 00                	mov    (%eax),%eax
80108ead:	83 e0 01             	and    $0x1,%eax
80108eb0:	85 c0                	test   %eax,%eax
80108eb2:	74 41                	je     80108ef5 <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
80108eb4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108eb7:	8b 00                	mov    (%eax),%eax
80108eb9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108ebe:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80108ec1:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108ec5:	75 0c                	jne    80108ed3 <deallocuvm+0x82>
        panic("kfree");
80108ec7:	c7 04 24 21 99 10 80 	movl   $0x80109921,(%esp)
80108ece:	e8 67 76 ff ff       	call   8010053a <panic>
      char *v = p2v(pa);
80108ed3:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108ed6:	89 04 24             	mov    %eax,(%esp)
80108ed9:	e8 0e f5 ff ff       	call   801083ec <p2v>
80108ede:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
80108ee1:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108ee4:	89 04 24             	mov    %eax,(%esp)
80108ee7:	e8 30 9d ff ff       	call   80102c1c <kfree>
      *pte = 0;
80108eec:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108eef:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80108ef5:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108efc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108eff:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108f02:	0f 82 74 ff ff ff    	jb     80108e7c <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
80108f08:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108f0b:	c9                   	leave  
80108f0c:	c3                   	ret    

80108f0d <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80108f0d:	55                   	push   %ebp
80108f0e:	89 e5                	mov    %esp,%ebp
80108f10:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
80108f13:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80108f17:	75 0c                	jne    80108f25 <freevm+0x18>
    panic("freevm: no pgdir");
80108f19:	c7 04 24 27 99 10 80 	movl   $0x80109927,(%esp)
80108f20:	e8 15 76 ff ff       	call   8010053a <panic>
  deallocuvm(pgdir, KERNBASE, 0);
80108f25:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108f2c:	00 
80108f2d:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80108f34:	80 
80108f35:	8b 45 08             	mov    0x8(%ebp),%eax
80108f38:	89 04 24             	mov    %eax,(%esp)
80108f3b:	e8 11 ff ff ff       	call   80108e51 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80108f40:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108f47:	eb 48                	jmp    80108f91 <freevm+0x84>
    if(pgdir[i] & PTE_P){
80108f49:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108f4c:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108f53:	8b 45 08             	mov    0x8(%ebp),%eax
80108f56:	01 d0                	add    %edx,%eax
80108f58:	8b 00                	mov    (%eax),%eax
80108f5a:	83 e0 01             	and    $0x1,%eax
80108f5d:	85 c0                	test   %eax,%eax
80108f5f:	74 2c                	je     80108f8d <freevm+0x80>
      char * v = p2v(PTE_ADDR(pgdir[i]));
80108f61:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108f64:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108f6b:	8b 45 08             	mov    0x8(%ebp),%eax
80108f6e:	01 d0                	add    %edx,%eax
80108f70:	8b 00                	mov    (%eax),%eax
80108f72:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108f77:	89 04 24             	mov    %eax,(%esp)
80108f7a:	e8 6d f4 ff ff       	call   801083ec <p2v>
80108f7f:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
80108f82:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108f85:	89 04 24             	mov    %eax,(%esp)
80108f88:	e8 8f 9c ff ff       	call   80102c1c <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
80108f8d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80108f91:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80108f98:	76 af                	jbe    80108f49 <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80108f9a:	8b 45 08             	mov    0x8(%ebp),%eax
80108f9d:	89 04 24             	mov    %eax,(%esp)
80108fa0:	e8 77 9c ff ff       	call   80102c1c <kfree>
}
80108fa5:	c9                   	leave  
80108fa6:	c3                   	ret    

80108fa7 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80108fa7:	55                   	push   %ebp
80108fa8:	89 e5                	mov    %esp,%ebp
80108faa:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108fad:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108fb4:	00 
80108fb5:	8b 45 0c             	mov    0xc(%ebp),%eax
80108fb8:	89 44 24 04          	mov    %eax,0x4(%esp)
80108fbc:	8b 45 08             	mov    0x8(%ebp),%eax
80108fbf:	89 04 24             	mov    %eax,(%esp)
80108fc2:	e8 a8 f8 ff ff       	call   8010886f <walkpgdir>
80108fc7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80108fca:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108fce:	75 0c                	jne    80108fdc <clearpteu+0x35>
    panic("clearpteu");
80108fd0:	c7 04 24 38 99 10 80 	movl   $0x80109938,(%esp)
80108fd7:	e8 5e 75 ff ff       	call   8010053a <panic>
  *pte &= ~PTE_U;
80108fdc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108fdf:	8b 00                	mov    (%eax),%eax
80108fe1:	83 e0 fb             	and    $0xfffffffb,%eax
80108fe4:	89 c2                	mov    %eax,%edx
80108fe6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108fe9:	89 10                	mov    %edx,(%eax)
}
80108feb:	c9                   	leave  
80108fec:	c3                   	ret    

80108fed <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80108fed:	55                   	push   %ebp
80108fee:	89 e5                	mov    %esp,%ebp
80108ff0:	53                   	push   %ebx
80108ff1:	83 ec 44             	sub    $0x44,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
80108ff4:	e8 b0 f9 ff ff       	call   801089a9 <setupkvm>
80108ff9:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108ffc:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80109000:	75 0a                	jne    8010900c <copyuvm+0x1f>
    return 0;
80109002:	b8 00 00 00 00       	mov    $0x0,%eax
80109007:	e9 fd 00 00 00       	jmp    80109109 <copyuvm+0x11c>
  for(i = 0; i < sz; i += PGSIZE){
8010900c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80109013:	e9 d0 00 00 00       	jmp    801090e8 <copyuvm+0xfb>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80109018:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010901b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80109022:	00 
80109023:	89 44 24 04          	mov    %eax,0x4(%esp)
80109027:	8b 45 08             	mov    0x8(%ebp),%eax
8010902a:	89 04 24             	mov    %eax,(%esp)
8010902d:	e8 3d f8 ff ff       	call   8010886f <walkpgdir>
80109032:	89 45 ec             	mov    %eax,-0x14(%ebp)
80109035:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80109039:	75 0c                	jne    80109047 <copyuvm+0x5a>
      panic("copyuvm: pte should exist");
8010903b:	c7 04 24 42 99 10 80 	movl   $0x80109942,(%esp)
80109042:	e8 f3 74 ff ff       	call   8010053a <panic>
    if(!(*pte & PTE_P))
80109047:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010904a:	8b 00                	mov    (%eax),%eax
8010904c:	83 e0 01             	and    $0x1,%eax
8010904f:	85 c0                	test   %eax,%eax
80109051:	75 0c                	jne    8010905f <copyuvm+0x72>
      panic("copyuvm: page not present");
80109053:	c7 04 24 5c 99 10 80 	movl   $0x8010995c,(%esp)
8010905a:	e8 db 74 ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
8010905f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80109062:	8b 00                	mov    (%eax),%eax
80109064:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109069:	89 45 e8             	mov    %eax,-0x18(%ebp)
    flags = PTE_FLAGS(*pte);
8010906c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010906f:	8b 00                	mov    (%eax),%eax
80109071:	25 ff 0f 00 00       	and    $0xfff,%eax
80109076:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if((mem = kalloc()) == 0)
80109079:	e8 37 9c ff ff       	call   80102cb5 <kalloc>
8010907e:	89 45 e0             	mov    %eax,-0x20(%ebp)
80109081:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80109085:	75 02                	jne    80109089 <copyuvm+0x9c>
      goto bad;
80109087:	eb 70                	jmp    801090f9 <copyuvm+0x10c>
    memmove(mem, (char*)p2v(pa), PGSIZE);
80109089:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010908c:	89 04 24             	mov    %eax,(%esp)
8010908f:	e8 58 f3 ff ff       	call   801083ec <p2v>
80109094:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010909b:	00 
8010909c:	89 44 24 04          	mov    %eax,0x4(%esp)
801090a0:	8b 45 e0             	mov    -0x20(%ebp),%eax
801090a3:	89 04 24             	mov    %eax,(%esp)
801090a6:	e8 4e cd ff ff       	call   80105df9 <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
801090ab:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
801090ae:	8b 45 e0             	mov    -0x20(%ebp),%eax
801090b1:	89 04 24             	mov    %eax,(%esp)
801090b4:	e8 26 f3 ff ff       	call   801083df <v2p>
801090b9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801090bc:	89 5c 24 10          	mov    %ebx,0x10(%esp)
801090c0:	89 44 24 0c          	mov    %eax,0xc(%esp)
801090c4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801090cb:	00 
801090cc:	89 54 24 04          	mov    %edx,0x4(%esp)
801090d0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801090d3:	89 04 24             	mov    %eax,(%esp)
801090d6:	e8 36 f8 ff ff       	call   80108911 <mappages>
801090db:	85 c0                	test   %eax,%eax
801090dd:	79 02                	jns    801090e1 <copyuvm+0xf4>
      goto bad;
801090df:	eb 18                	jmp    801090f9 <copyuvm+0x10c>
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
801090e1:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801090e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801090eb:	3b 45 0c             	cmp    0xc(%ebp),%eax
801090ee:	0f 82 24 ff ff ff    	jb     80109018 <copyuvm+0x2b>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
      goto bad;
  }
  return d;
801090f4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801090f7:	eb 10                	jmp    80109109 <copyuvm+0x11c>

bad:
  freevm(d);
801090f9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801090fc:	89 04 24             	mov    %eax,(%esp)
801090ff:	e8 09 fe ff ff       	call   80108f0d <freevm>
  return 0;
80109104:	b8 00 00 00 00       	mov    $0x0,%eax
}
80109109:	83 c4 44             	add    $0x44,%esp
8010910c:	5b                   	pop    %ebx
8010910d:	5d                   	pop    %ebp
8010910e:	c3                   	ret    

8010910f <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
8010910f:	55                   	push   %ebp
80109110:	89 e5                	mov    %esp,%ebp
80109112:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80109115:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010911c:	00 
8010911d:	8b 45 0c             	mov    0xc(%ebp),%eax
80109120:	89 44 24 04          	mov    %eax,0x4(%esp)
80109124:	8b 45 08             	mov    0x8(%ebp),%eax
80109127:	89 04 24             	mov    %eax,(%esp)
8010912a:	e8 40 f7 ff ff       	call   8010886f <walkpgdir>
8010912f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
80109132:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109135:	8b 00                	mov    (%eax),%eax
80109137:	83 e0 01             	and    $0x1,%eax
8010913a:	85 c0                	test   %eax,%eax
8010913c:	75 07                	jne    80109145 <uva2ka+0x36>
    return 0;
8010913e:	b8 00 00 00 00       	mov    $0x0,%eax
80109143:	eb 25                	jmp    8010916a <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
80109145:	8b 45 f4             	mov    -0xc(%ebp),%eax
80109148:	8b 00                	mov    (%eax),%eax
8010914a:	83 e0 04             	and    $0x4,%eax
8010914d:	85 c0                	test   %eax,%eax
8010914f:	75 07                	jne    80109158 <uva2ka+0x49>
    return 0;
80109151:	b8 00 00 00 00       	mov    $0x0,%eax
80109156:	eb 12                	jmp    8010916a <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
80109158:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010915b:	8b 00                	mov    (%eax),%eax
8010915d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109162:	89 04 24             	mov    %eax,(%esp)
80109165:	e8 82 f2 ff ff       	call   801083ec <p2v>
}
8010916a:	c9                   	leave  
8010916b:	c3                   	ret    

8010916c <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
8010916c:	55                   	push   %ebp
8010916d:	89 e5                	mov    %esp,%ebp
8010916f:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
80109172:	8b 45 10             	mov    0x10(%ebp),%eax
80109175:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
80109178:	e9 87 00 00 00       	jmp    80109204 <copyout+0x98>
    va0 = (uint)PGROUNDDOWN(va);
8010917d:	8b 45 0c             	mov    0xc(%ebp),%eax
80109180:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80109185:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
80109188:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010918b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010918f:	8b 45 08             	mov    0x8(%ebp),%eax
80109192:	89 04 24             	mov    %eax,(%esp)
80109195:	e8 75 ff ff ff       	call   8010910f <uva2ka>
8010919a:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
8010919d:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801091a1:	75 07                	jne    801091aa <copyout+0x3e>
      return -1;
801091a3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801091a8:	eb 69                	jmp    80109213 <copyout+0xa7>
    n = PGSIZE - (va - va0);
801091aa:	8b 45 0c             	mov    0xc(%ebp),%eax
801091ad:	8b 55 ec             	mov    -0x14(%ebp),%edx
801091b0:	29 c2                	sub    %eax,%edx
801091b2:	89 d0                	mov    %edx,%eax
801091b4:	05 00 10 00 00       	add    $0x1000,%eax
801091b9:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
801091bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801091bf:	3b 45 14             	cmp    0x14(%ebp),%eax
801091c2:	76 06                	jbe    801091ca <copyout+0x5e>
      n = len;
801091c4:	8b 45 14             	mov    0x14(%ebp),%eax
801091c7:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
801091ca:	8b 45 ec             	mov    -0x14(%ebp),%eax
801091cd:	8b 55 0c             	mov    0xc(%ebp),%edx
801091d0:	29 c2                	sub    %eax,%edx
801091d2:	8b 45 e8             	mov    -0x18(%ebp),%eax
801091d5:	01 c2                	add    %eax,%edx
801091d7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801091da:	89 44 24 08          	mov    %eax,0x8(%esp)
801091de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801091e1:	89 44 24 04          	mov    %eax,0x4(%esp)
801091e5:	89 14 24             	mov    %edx,(%esp)
801091e8:	e8 0c cc ff ff       	call   80105df9 <memmove>
    len -= n;
801091ed:	8b 45 f0             	mov    -0x10(%ebp),%eax
801091f0:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
801091f3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801091f6:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
801091f9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801091fc:	05 00 10 00 00       	add    $0x1000,%eax
80109201:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
80109204:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80109208:	0f 85 6f ff ff ff    	jne    8010917d <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
8010920e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80109213:	c9                   	leave  
80109214:	c3                   	ret    
