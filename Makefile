# Variables
ASM = as
LD = ld
CLEANUP = rm -f
TARGET = main
OBJS = $(TARGET).o
ASMFLAGS = -g 
LDFLAGS =        

# Reglas
.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $^

%.o: %.s
	$(ASM) $(ASMFLAGS) -o $@ $<

clean:
	$(CLEANUP) $(TARGET) $(OBJS)
