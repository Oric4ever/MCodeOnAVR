struct diskparams {
    long lba;
    void *dma;
    int offset, count;
};

extern void Reset(void);
extern char ConsoleStatus(void);
extern char ConsoleInput (void);
extern void ConsoleOutput(char);
extern void NewSectorRead (void *);
extern void NewSectorWrite(void *);
