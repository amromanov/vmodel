@echo off

rem Compile and link options used for building MEX-files using Cygwin,
rem for the 64-bit version of MATLAB.
rem
rem It makes the assumption that you installed Cygwin in C:\CYGWIN,
rem and that you installed either the "mingw64-x86_64-g++" package.
rem
rem This file should be renamed to "mexopts.bat" and copied to:
rem C:\Documents and Settings\<Username>\Application Data\MathWorks\MATLAB\<MATLAB version>\
rem
rem Initial version by Michel Juillard, revised by Sebastien Villemot.
rem Оriginal version was part of Dynare software
rem
rem vmodel toolbox, 2014.

rem ********************************************************************
rem General parameters
rem ********************************************************************

set MATLAB=%MATLAB%
set PATH=%PATH%;c:\cygwin\bin
set MW_TARGET_ARCH=win64

rem ********************************************************************
rem Compiler parameters
rem ********************************************************************
set COMPILER=x86_64-w64-mingw32-g++
set COMPFLAGS=-c -fexceptions -w
set OPTIMFLAGS=-O3
set DEBUGFLAGS=-g -Wall
set NAME_OBJECT=-o

rem ********************************************************************
rem Linker parameters
rem ********************************************************************
set PRELINK_CMDS1=echo EXPORTS > mex.def & echo mexFunction >> mex.def
set LIBLOC=%MATLAB%\bin\win64\
set LINKER=x86_64-w64-mingw32-g++
set LINKFLAGS= -static-libstdc++ -static-libgcc -shared mex.def "-L%LIBLOC%"
set LINKFLAGSPOST= -lmex -lmx -lmwlapack -lmwblas
set LINKOPTIMFLAGS=-O3
set LINKDEBUGFLAGS= -g -Wall
set LINK_FILE=
set LINK_LIB=
set NAME_OUTPUT=-o "%OUTDIR%%MEX_NAME%%MEX_EXT%"
set RSP_FILE_INDICATOR=@
set POSTLINK_CMDS1=del mex.def
