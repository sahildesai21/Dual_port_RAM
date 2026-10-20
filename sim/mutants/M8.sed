s|ram\[write_addr\] <= data;|ram[write_addr] <= {1'b0, data[DATA_WIDTH-2:0]};|
