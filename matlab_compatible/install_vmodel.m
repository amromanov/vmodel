%%install_vmodel
%%Script to install vmodel and verilator automatically
%%Linux:
%%You will need internet access and rights to read&write for /opt/ folder
%%Verilator will be installed in /opt/verilator
%%Also you will need gcc, g++, flex, bison and perl packages. To install
%%verilator in other folder, do it manually and then install vmodel with
%%install() function.
%%-
%%Windows:
%%You will need internet access and matlab started with administrator rights
%%CYGWIN and verilator will be installed into c:\cygwin\
%%To install CYGWIN and verilator in other folder, do it manually and then 
%install vmodel with install() function.
%%-
%%*********************vmodel MATLAB Verilog simulator******************
%%Moscow, Control Problems Department MIREA, 2009-2015
%%Authors: Karyakin D, Romanov A, Slashcov B
%%-
%%Distributed under the GNU LGPL
%%**********************************************************************

if (ispc)    %Windows installation
    if (strcmp(computer('arch'),'win64'))
        if (~exist('c:\cygwin\bin\bash.exe','file'))
            %Downloading cygwin
            fprintf('Downloading CYGWIN installer...\n')   
            [flstr,status]=urlwrite('http://cygwin.com/setup-x86_64.exe','setup-x86_64.exe');
            if(~status)
                fprintf('CYGWIN installer download failed.\n')
                return
            end    
            %Installing cygwin
            fprintf('Installing cygwin...\n')   
            system('install.bat')
            if ~(exist('c:\cygwin\bin\bash.exe','file'))
                fprintf('CYGWIN install failed. Try to install it manually.\n')
                return
            end
        end
        %Installing Verilator
            if ~(exist('c:\cygwin\opt\verilator\verilator_bin.exe','file'))
            fprintf('Installing verilator...\n')   
            system('c:\cygwin\bin\bash --login -i /opt/install_vmodel_preq');      
            %copying cygwin dlls
            copyfile('c:\cygwin\bin\cygwin1.dll', 'c:\cygwin\opt\verilator\');
            copyfile('c:\cygwin\bin\cyggcc_s-seh-1.dll', 'c:\cygwin\opt\verilator\');
            copyfile('c:\cygwin\bin\cygstdc++-6.dll', 'c:\cygwin\opt\verilator\');

            if ~(exist('c:\cygwin\opt\verilator\verilator_bin.exe','file'))
                fprintf('Verilator install failed. Try to install it manually.\n')
                return
            end
        end
        %Installing vmodel
        fprintf('Installing vmodel...\n')   
        install('c:\cygwin\opt\verilator\',1)
    else
       fprintf('Only 64-bit systems are supported by vmodel windows installer. \nFor 32-bit systems install cygwin and verilator manually. \n');
    end
else
    %Installing Verilator
    if ~(exist('/opt/verilator/verilator_bin','file'))
        fprintf('Installing verilator...\n')   
        system('bash install_vmodel_preq');        
        if ~(exist('/opt/verilator/verilator_bin','file'))
            fprintf('Verilator install failed. Try to install it manually.\n')
            return
        end
    end
    %Installing vmodel
    fprintf('Installing vmodel...\n')   
    install('/opt/verilator/',0)
end