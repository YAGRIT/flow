#=======================================#
#																			  #
#                Flow: 									#
#   circt-verilog => | .mlir | 					#
#     =>  circt-opt => | .mlir |				#
#       =>  arcilator => |  .ll  |			#
#         =>        llc => |  .s   |		#
#           =>        gcc => |  .o   | 	#
#																			  #
#=======================================#

CIRCT_VRG ?= 	$(shell which circt-verilog)
CIRCT_OPT ?= 	$(shell which circt-opt)
ARCILATOR ?= 	$(shell which arcilator)
LLC   		?=	$(shell which llc-14)
LLC_FLAGS =		-opaque-pointers 
CC 				?=	$(shell which gcc)
RISC_V_DIR=		risc-v
OBJS			=		$(wildcard $(RISC_V_DIR)/core/*.sv)
BUILD_DIR	=		$(RISC_V_DIR)/build

#===-------------------------------------
# Default flow  
#===-------------------------------------

asm-to-bin: $(BUILD_DIR)/%.s 
	$(CC) -o $(basename $<).o $< 

ll-to-asm: $(BUILD_DIR)/%.ll 
	$(LLC) $(LLC_FLAGS) -o $(basename $<).s $< 

mlirs-to-ll: $(BUILD_DIR)/%_op.mlir
	$(ARCILATOR) -o $(basename $<).ll $< 

mlirs-opt: $(BUILD_DIR)/%.mlir 
	$(CIRCT_OPT) -o $(basename $<)_opt.mlir $< 

sv-to-mlirs: $(OBJS)
	$(CIRCT_VRG) $(OBJS)

#===-------------------------------------
# Test flow on single file
#===-------------------------------------

test-asm-to-bin: $(TEST_MOD).s 
	$(CC) -o adder.o $^ 

test-ll-to-asm: $(TEST_MOD).ll 
	$(LLC) $(LLC_FLAGS) $< > $(BUILD_DIR)/adder.s 

test-mlirs-to-ll: $(TEST_MOD)_opt.mlir 
	$(ARCILATOR) $< > $(BUILD_DIR)/adder.ll 

test-mlirs-opt: $(TEST_MOD).mlir 
	$(CIRCT_OPT) $< > $(BUILD_DIR)/adder_opt.mlir 

test-sv-to-mlirs: $(TEST_MOD).sv 
	$(CIRCT_VRG) $< > $(BUILD_DIR)/adder.mlir 

#===-------------------------------------
# Convenience 
#===-------------------------------------

all: sv-to-mlirs mlirs-opt mlirs-to-ll ll-to-asm asm-to-bin

single: test-sv-to-mlirs test-mlirs-opt test-mlirs-to-ll test-ll-to-asm test-asm-to-bin

.PHONY: all 
