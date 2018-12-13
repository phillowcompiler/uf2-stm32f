#
# Common rules for makefiles for the PX4 bootloaders
#

BUILD_DIR	 = build/$(TARGET_FILE_NAME)

OBJS		:= $(addprefix $(BUILD_DIR)/, $(patsubst %.c,%.o,$(SRCS)))
DEPS		:= $(OBJS:.o=.d)

ELF		 = $(BUILD_DIR)/$(TARGET_FILE_NAME).elf
BINARY		 = $(BUILD_DIR)/$(TARGET_FILE_NAME).bin
UF2		 = $(BUILD_DIR)/$(TARGET_FILE_NAME).uf2

FL_OBJS = $(addprefix $(BUILD_DIR)/, flasher.o main_f4-flasher.o util.o dmesg.o)

all:		$(BUILD_DIR) $(ELF) $(BINARY) $(UF2)

# Compile and generate dependency files
$(BUILD_DIR)/%.o:	%.c
	@echo Generating object $@
	$(CC) -c -MMD $(FLAGS) -o $@ $*.c

# Compile and generate dependency files
$(BUILD_DIR)/%-flasher.o:	%.c
	@echo Generating object $@
	$(CC) -c -MMD $(FLAGS) -DBL_FLASHER=1 -o $@ $<

# Make the build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(ELF):		$(OBJS) $(MAKEFILE_LIST)
	$(CC) -o $@ $(OBJS) $(FLAGS)  -Wl,-Map=$(ELF).map

$(BINARY):	$(ELF)
	$(OBJCOPY) -O binary $(ELF) $(BINARY)

$(UF2): $(FL_OBJS) $(BINARY)
	$(CC) -o $(BUILD_DIR)/flasher.elf $(FL_OBJS) $(FLAGS:.ld=-flasher.ld)
	$(OBJCOPY) -O binary $(BUILD_DIR)/flasher.elf $(BUILD_DIR)/flasher.bin
	python uf2/utils/uf2conv.py $(BUILD_DIR)/flasher.bin -b 0x08010000 -o $(BUILD_DIR)/flasher.uf2 -c -f 0x57755a57

# Dependencies for .o files
-include $(DEPS)
