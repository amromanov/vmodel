%%**********vmodel MATLAB Verilog simulator usage example***************
%%Moscow, Control Problems Department MIREA, 2009-2010
%%Authors: Karyakin D, Romanov A
%%
%%Distributed under the GNU LGPL
%%**********************************************************************

%% Constructing and reseting 
mult=constructor;
mult.rst=1;
sim_step(mult,1,1); %Simulating 1 clock period without output
mult.rst=0; 
sim_step(mult,1,1); %Simulating 1 clock period without output
%% Testing
N=1000; %Number of tests
BitWidth=16; %Multiplier bit width
a=zeros(N,1); 
b=zeros(N,1);
s=zeros(N,1);
r=zeros(N,1);

%Running tests
for i=1:1:N
mult.start=1; %Setting start strob 
mult.a=floor(rand*(2^(BitWidth)-1)); 
mult.b=floor(rand*(2^(BitWidth)-1));
sim_step(mult,1,1); %Simulating 1 clock period without output
mult.start=0; %reseting start strob
res=sim_tcond(mult,32,0); %simulating until breaking condition (top->rdy == 1)
                            %or until 5000 clock periods
if mult.a>=(2^(BitWidth-1)) %Converting to signed
    a(i)=mult.a-2^BitWidth;
else
    a(i)=mult.a;    
end

if mult.b>=(2^(BitWidth-1)) %Converting to signed
    b(i)=mult.b-2^BitWidth;
else
    b(i)=mult.b;    
end

if res.c>=(2^(BitWidth-1)) %Converting to signed
    r(i)=double(res.c)-2^BitWidth;
else
    r(i)=double(res.c);    
end

end

%Create coverage file
sim_step(mult,0,1);
[prcnt, covered, total] = vcoverage(200,0,{},'coverage.dat');  %Run line coverage check with minimum level for one line of 200 test 
fprintf('Test coverage (%i/%i): %3.2f%%\n',covered,total,prcnt);
fprintf('Annotated coverage results: coverage_source\\\n');
fprintf('Lines started with %% haven''t passed the test\n');

%Plotting multiplier error and histograms
figure(1)
subplot(5,1,1)
plot(r-fix(a.*b/(2^(BitWidth-1))))
subplot(5,1,2)
hist(a,100)
subplot(5,1,3)
hist(b,100)
subplot(5,1,4)
hist(s,100)
subplot(5,1,5)
hist(r,100)

