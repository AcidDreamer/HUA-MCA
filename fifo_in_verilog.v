
/********************************
*	FIFO IMPLEMENTATION			*
*********************************/
`define READ 1  
`define WRITE 2
//Δύο define για να είναι πιο κατανοητό αν κάνουμε read ή write
`define SLOTS 4    
//2^4 τα bit που χρειαζόμαστε για 16 θέσεις
`define MAX_SLOTS 16
//16 θέσεις για δημιουργεία πίνακα ή συγκρίσεις
`define SLOT_SIZE 32
//32-1 το μέγεθος θέσης
module fifo( clk, reset, Data_IN, FIFO_Data_Out, FIFO_Read_Write, FIFO_Empty, FIFO_Full, FIFO_Last );


input           clk,reset ; 
//παλμοί για το clock και το reset
input[1:0]	   	FIFO_Read_Write;
//2-bit για το READ_WRITE (00 = μην κάνεις τίποτα,01 = READ , 10 = WRITE,11 περισεύει)
input [`SLOT_SIZE-1:0]           Data_IN;                   
output[`SLOT_SIZE-1:0]           FIFO_Data_Out;                  
//32-bit για την είσοδο και έξοδο των δεδομένων
output                FIFO_Empty, FIFO_Full,FIFO_Last;      
//FIFO empty,last και full που ζητήθηκε 
reg[`SLOTS :0] fifo_counter;             
//Μετρητής θέσεων στην ουρά
reg[`SLOT_SIZE-1:0]             FIFO_Data_Out;
reg                   FIFO_Empty, FIFO_Full,FIFO_Last;
reg[`SLOTS -1:0]  read_pointer, write_pointer;            
//pointers σε διεύθυνση για read ή write
reg[`SLOT_SIZE-1:0]              indexed_table[`MAX_SLOTS -1 : 0]; 
/***************************************************
* Ένας buffer 16 θέσεων με μέγεθος θέσης 32-bit	   *
* εδώ βρίσκεται η καρδία της FIFO , παίζοντας με   *
* το array και τους read/write pointers μπορούμε   *
* να επιστρέψουμε και διαβάσουμε τα δεδομένα       *
***************************************************/


always @(fifo_counter)
//σε κάθε παλμό του fifo_counter
begin
	//Ελέγχουμε σε τι κατάσταση βρίσκεται η ουρά
	FIFO_Empty = (fifo_counter==0);
   	FIFO_Full = (fifo_counter == `MAX_SLOTS);
   	FIFO_Last = (fifo_counter == `MAX_SLOTS-1);
   	//Σημαντικοί έλεγχοι για πιο κάτω
end


always @(posedge clk or posedge reset)
//Σε κάθε θετικό παλμό του ρολογιού ή του reset
begin
   	if( reset )
    	fifo_counter <= 0;
    //στο reset αδειάζουμε την ουρά με non-blocking
    //assignment στο 0
	else if( !FIFO_Full && FIFO_Read_Write== `WRITE )
    	fifo_counter <= fifo_counter + 1;
    //άμα η ουρά δεν είναι γεμάτη και θέλουμε να γράψουμε
    //αυξάνουμε το counter κατά 1
   	else if( !FIFO_Empty && FIFO_Read_Write== `READ )
		fifo_counter <= fifo_counter - 1;
	//εάν η ουρά δεν είναι γεμάτη και θέλουμε να διαβάσουμε
	//μειώνουμε το counter κατά 1
end

//Σε κάθε θετικό παλμό του ρολογιού ή του reset
always @( posedge clk or posedge reset)
begin
  	if( reset )
    	FIFO_Data_Out <= 0;
    	//Αδειάζουμε τα δεδόμενα που εξόδου
   else
   begin
    	if( FIFO_Read_Write==`READ && !FIFO_Empty )
        	FIFO_Data_Out <= indexed_table[read_pointer];
        //Διαφορετικά αν διαβάζουμε και η ουρά δεν είναι άδεια
        //παίρνουμε από την μνήμη του buffer το σημείο
        //που δείχνει ο read_pointer και το επιστρέφουμε
   end
end


//Σε κάθε θετικό παλμό του ρολογιού
always @(posedge clk)
begin
   	if( FIFO_Read_Write==`WRITE && !FIFO_Full )
    	indexed_table[ write_pointer ] <= Data_IN;
	//εάν η ουρά δεν είναι γεμάτη και θέλουμε να διαβάσουμε
	//βάζουμε τα δεδομένα εισόδου στο σημείο του buffer που
	//δείχνει η μνήμη
end

//Σε κάθε θετικό παλμό του ρολογιού ή του reset
always@(posedge clk or posedge reset)
begin
   	if( reset )
   	begin
    	write_pointer <= 0;
      	read_pointer <= 0;
    //εάν έχουμε reset μηδενίζουμε τους pointer
   	end
   	else
   	begin
    	if( !FIFO_Full && FIFO_Read_Write==`WRITE )    
    		write_pointer <= write_pointer + 1;
	    
	    if( !FIFO_Empty && FIFO_Read_Write==`READ ) 
			read_pointer <= read_pointer + 1;

	/********************************************************
	* Τι γίνετε με τους pointer;			 				*
	*	Εφόσον oi pointers έχουν την						*
	* ίδια χωριτηκότητα με το fifo_counter					*
	* όταν η τιμή τους ξεπεράσει το μέγιστο 				*
	* γίνετε overflow και η τιμή τους αρχίζει ξανά			*
	* από το 0 , έτσι όταν για παραδειγμάτος χάρην 			*
	* κάνουμε read το ψηφίο που μπήκε 17ο εφόσον έχουμε		*
	* γράψει 16 φορές (εάν η ουρά δεν είναι γεμάτη) 		*
	* το επόμενο μέρος που θα γράψουμε είναι η μηδενική 	*
	* θέση.													*
	*********************************************************/

   end
end
endmodule

/********************************
*	     TOP MODULE				*
*********************************/
module TOP();

reg clk, reset ;
reg[1:0] FIFO_Read_Write;
reg[`SLOT_SIZE-1:0] Data_IN;
reg[`SLOT_SIZE-1:0] tempdata;
//το παραπάνω χρησιμοποιήται για 
//να μπορούμε να διαβάσουμε τις τιμές
//που παίρνουμε όταν κάνουμε pop 
wire [`SLOT_SIZE-1:0] FIFO_Data_Out;

fifo first_in_first_out( .clk(clk), .reset(reset), .Data_IN(Data_IN), .FIFO_Data_Out(FIFO_Data_Out), 
         .FIFO_Read_Write(FIFO_Read_Write), .FIFO_Empty(FIFO_Empty), 
         .FIFO_Full(FIFO_Full),. FIFO_Last(FIFO_Last) );

initial
begin
	$dumpfile("fifo.vcd");
	$dumpvars(0);

	clk = 0;
	FIFO_Read_Write = 0;
        tempdata = 0;
        Data_IN = 0;

	reset = 1;
        #15 reset = 0;
	//Επειδή το reset αρχικοποιεί την fifo ,
	//κάνουμε reset πριν αρχίσουμε να κάνουμε
	//pop ή push

        push(1);	//1
	push(4294967295);//2
	//2^32-1	
        push(3);	//3
        push(4);	//4	
        push(5);	//5
        push(6);	//6
        push(7);	//7
        push(8);	//8	
        push(9);	//9
        push(10);	//10	


        pop(tempdata);	//1
        pop(tempdata);	//2
        pop(tempdata);	//3
        pop(tempdata);	//4
        pop(tempdata);	//5
        pop(tempdata);	//6
        pop(tempdata);	//7	
        pop(tempdata);	//8
        pop(tempdata);	//9
        pop(tempdata);	//10

	#10 $finish;
end

always
   #5 clk = ~clk;
   //After 5 time units , reverse the clock
task push;
input[`SLOT_SIZE-1:0] data_to_write;

   if( FIFO_Full )
            $display("Buffer Full");
        else if ( FIFO_Last )
	begin
	   $display("Pushed ",data_to_write,". Warning last slot!" );
           Data_IN = data_to_write;
           FIFO_Read_Write = `WRITE;
                @(posedge clk);
		#1 FIFO_Read_Write = 0;
	   //γράψε ,περίμενε ένα κύκλο και κλείσε το READ_WRITE
           //ανάλογη λογική σε όλα τα παρακάτω
	end
	else
        begin
           $display("Pushed ",data_to_write );
           Data_IN = data_to_write;
           FIFO_Read_Write = `WRITE;
                @(posedge clk);
		#1 FIFO_Read_Write = 0;
        end

endtask

task pop;
output [`SLOT_SIZE-1:0] data_to_read;
   if( FIFO_Empty )
            $display("Buffer Empty");
   else
        begin
     	FIFO_Read_Write = `READ;
          @(posedge clk);
	  #1 FIFO_Read_Write = 0;
          data_to_read = FIFO_Data_Out;
           $display("Poped ", data_to_read);
        end
endtask

endmodule

