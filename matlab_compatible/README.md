# vmodel
Vmodel toolbox repository

Vmodel toolbox was developed to generate cycle-accurate HDL models for MATLAB and Simulink from Verilog code.
Vmodel toolbox is based on Verilator simulator and support most of its features, including code coverage.
Also vmodel provides additional functions for waveform visualization in MATLAB.


To install vmodel:

1. Run MATLAB

2. Change folder to vmodel distributive

3. run help install_vmodel

4. Read installation procedure requirments

5. run install_vmodel script

6. run_vmodel_tests script (approx 10-20 min) to check if everything works correct

In windows you should run MATLAB with administrator rights to run installation scripts or self-test.

In Linux you shoul have read&write right for /opt/verilator folder. Also you should have
gcc, g++, flex, bison and perl packages installed before running install_vmodel script.

Vmodel was tested with Windows 7, Windows 8, Ubuntu linux 12.04 LTS, 14.04 LTS,
and MATLAB 2011b, 2013a.
