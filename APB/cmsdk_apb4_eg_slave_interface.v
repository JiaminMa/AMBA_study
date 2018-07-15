module cmsdk_apb4_eg_slave_interface #(
		parameter ADDRWIDTH = 12)
(
	input wire						pclk,
	input wire						presetn,
	
	//apb interface inputs
	input wire 						psel,
	input wire[ADDRWIDTH-1:0]		paddr,
	input wire						penable,
	input wire						pwrite,
	input wire[31:0]				pwdata,
	input wire[3:0]					pstrb,
	
	//apb interface outputs
	output wire[31:0]				prdata,
	output wire						pready,
	output wire						pslverr,
	
	//register interface
	output wire[ADDRWIDTH-1:0]		addr,
	output wire 					read_en,
	output wire						write_en,
	output wire[3:0]				byte_strobe,
	output wire[31:0]				wdata,
	input wire[31:0]				rdata
);

//APB interface
assign pready = 1'b1; 		//Always readay. Can be customized to support waitstate if required.
assign pslverr = 1'b0;		//Always OKAY. Can be customized to support error response if required.

// register read and write signal
assign addr = paddr;
assign read_en = psel & (~pwrite);	//assert for whole apb read transfer;
assign write_en = psel & (~penable) & pwrite;	//assert for the 1st cycle of write transfer.
assign byte_strobe = pstrb;
assign wdata = pwdata;
assign prdata = rdata;
	
endmodule