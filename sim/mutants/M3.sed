s|; // do nothing on reset|for (i = 0; i < (1<<ADDR_WIDTH); i = i + 1) ram[i] <= {DATA_WIDTH{1'b0}};|
