module cmsdk_apb4_eg_slave # (
	paramter ADDRWIDTH = 12 )
(
	input wire					PCLK,
	input wire 					PRESETn,
	
	input wire					PSEL,
	input wire[ADDRWIDTH-1:0]	PADDR,
	input wire					PENABLE,
	input wire					PWRITE,
	input wire[31:0]			PWDATA,
	input wire[3:0]				PSTRB,
	
	input wire[3:0]				ECOREVNUM
	
	output wire[31:0]			PRDATA,
	output wire					PREADY,
	output wire					PSLVERR);
	
	wire[ADDRWIDTH-1:0] 	reg_addr;
	wire					reg_read_en;
	wire 					reg_write_en;
	wire[3:0]				reg_byte_strobe;
	wire[31:0]				reg_wdata;
	wire[31:0]				reg_rdata;
	
	cmsdk_apb4_eg_slave_interface 
		#(.ADDRWIDTH (ADDRWIDTH))
		u_apb_eg_slave_interface (
		
		// APB4 interface
		.pclk			(PCLK),
		.presetn		(PRESETn),
		.psel			(PSEL),
		.paddr			(PADDR),
		.penable		(PENABLE),
		.pwrite			(PWRITE),
		.pstrb			(PSTRB),
		
		.prdata			(PRDATA),
		.pready			(PREADY),
		.pslverr		(PSLVERR),
		
		// Register interface
		.addr			(reg_addr),
		.read_en		(reg_read_en),
		.write_en		(reg_write_en),
		.byte_strobe	(reg_byte_strobe),
		.wdata			(reg_wdata),
		.rdata			(reg_data)
	);
	
	cmsdk_apb4_eg_slave_reg
		#(.ADDRWIDTH(ADDRWIDTH))
		u_apb_eg_slave_reg (
		.pclk			(PCLK),
		.presetn		(PRESETn),
		
		.addr			(reg_addr),
		.read_en		(reg_read_en),
		.write_en		(reg_write_en),
		.byte_strobe	(reg_byte_strobe),
		.wdata			(reg_wdata),
		.ecorevnum		(ECOREVNUM),
		.rdata			(reg_rdata)
	);
	
endmodule