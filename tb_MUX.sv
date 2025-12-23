
///////////////////////////////////////////////////////////////////////////
//working testbench with driver,monitor,transaction,interface,and generator

interface intf();
  logic     Y;
  logic[3:0]A;
  logic[1:0]S;
  
  modport driver(output A,S);
  modport monitor(input A,S,Y);
  
endinterface

class trans;
  

       logic     Y;
  rand logic[3:0]A;
  rand logic[1:0]S;
 
  constraint valid_data{
    A>3;
    A<12;
    S>0;
  }
  
  task display(string name);
    $display("time:%0t\t |[%s] A:%d | S:%d",$time,A,S);
  endtask
  
  
endclass


class generator;
  mailbox gen2drive;
  trans tr;
 
  

//   rand[3:0]data;
//   rand logic[3:0]data;
  
  function new(mailbox gen2drive);
    this.gen2drive = gen2drive;
//     initial begin $display("data type bit always initilize's to zero hence,addr:%b\t",tr.addr); end
  endfunction
  
//    constraint limit_data{
//       data>3;
//       data<12;
// //      data % 2 == 0;
     
//     }
  
  task main();

    
    repeat(5)begin
        tr=new();
//       randamize(data);
//       void'(randomize(data));
//       data.randomize();
      tr.randomize();  
      gen2drive.put(tr);
      tr.display("GEN");
//       $display("Time:%0t\t | A:%d\t S:%b\t|  created by genrator",$time,tr.A,tr.S);
      
    end

    
  endtask
        
endclass

class driver;
  mailbox gen2drive;
  virtual intf intf1;
  trans tr_rec;
  
  logic [3:0]data_out;
  
  function new(mailbox gen2drive,virtual intf vif);
    this.gen2drive = gen2drive;
    intf1 = vif;
  endfunction
  
  
  
  task main();
    repeat(5)begin
      gen2drive.get(tr_rec);  
//       tr_rec.display();
      intf1.driver.A <= tr_rec.A;
      intf1.driver.S <= tr_rec.S;
      tr_rec.display("DRV");
      #10;
//       display();
    end
  endtask

  
  task display();
//     $display("$time:%0t\t | addr:%b\t",$time,tr_rec.addr);

    $display("Time:%0t\t | driver driving the A:%d S:%d\t",$time,tr_rec.A,tr_rec.S);
    
  endtask
endclass


class monitor;
  virtual intf intf2;
  trans t2;
  mailbox mon2soc;
  
  function new(mailbox mon2soc,virtual intf vif);
    intf2 = vif;
    this.mon2soc = mon2soc;
  endfunction
  
  task main;
    repeat(5) begin
        t2=new();
      #10;

      t2.A=intf2.monitor.A ;
      t2.S=intf2.monitor.S;
      t2.Y=intf2.monitor.Y;
      mon2soc.put(t2);

    $display("time:%0t\t [MON] saw | A:%d\t | S:%b\t | Y:%b\t on wire ",$time,intf2.monitor.A,intf2.monitor.S,intf2.monitor.Y);
    end
    
  endtask
  
endclass

class scoreboard;
monitor mon;
trans t3;
mailbox mon2soc;
bit Y;

function new(mailbox mon2soc);
    this.mon2soc = mon2soc;

endfunction


task main;
repeat(5)begin
// t3=new();
    mon2soc.get(t3);

Y=(t3.S == 2'b00)?t3.A[0]:
    (t3.S == 2'b01) ?t3.A[1]:
    (t3.S == 2'b10) ?t3.A[2]:
    (t3.S == 2'b11) ?t3.A[3]:2'b0;

if(t3.Y === Y) begin
    $display("Result:Passed");
end else begin
    $display("Result:Fail");

end

end


endtask


endclass

module top();

  generator gen;
  driver drv;
  mailbox mbox;
  mailbox mbox1;
  monitor mon;
  scoreboard soc;
  intf i_intf();
  
  MUX DUT(
    .A(i_intf.A),
    .S(i_intf.S),
    .Y(i_intf.Y)
  );
  
  initial begin
	mbox=new();
    mbox1=new();
//     gen = mbox;
//     drv=mbox;
    gen=new(mbox);
    drv=new(mbox,i_intf);
    mon=new(mbox1,i_intf);
    soc=new(mbox1);

    fork
      gen.main();
      drv.main();
      mon.main();
      soc.main();


    join_any
    wait(mbox.num() == 0);
    #20;
  end
  
endmodule
///////////////////////////////////////////////////
DUT
// Code your design here

// Code your design here

module MUX(
  output logic    Y,
  input logic[3:0]A,
  input logic[1:0]S
);
  
  always_comb begin;
    case(S)
      2'b00:Y = A[0];
      2'b01:Y = A[1];
      2'b10:Y = A[2];
      2'b11:Y = A[3];
    endcase
  end
  
  
  
endmodule