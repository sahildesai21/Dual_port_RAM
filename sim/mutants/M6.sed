s|q <= ram\[read_addr\];|q <= (we \&\& !rst \&\& (write_addr == read_addr)) ? data : ram[read_addr];|
