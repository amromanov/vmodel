@ECHO OFF
REM -- Automates cygwin installation
 
SETLOCAL
 
REM -- Change to the directory of the executing batch file
CD %~dp0
 
REM -- Configure our paths
SET SITE=http://cygwin.mirrors.pair.com/
SET LOCALDIR=%CD%
SET ROOTDIR=C:\cygwin
 
REM -- These are the packages we will install 
SET PACKAGES=autoconf,autoconf2.1,autoconf2.5,automake,automake1.10,automake1.11,automake1.12
SET PACKAGES=%PACKAGES%,automake1.13,automake1.14,automake1.4,automake1.5,automake1.6,automake1.7
SET PACKAGES=%PACKAGES%,automake1.8,automake1.9,base-cygwin,base-files,bash,binutils,bison,bzip2
SET PACKAGES=%PACKAGES%,ca-certificates,checkbashisms,chewmail,code2html,colorgcc,convmv,copyright-update
SET PACKAGES=%PACKAGES%,coreutils,cpio,crypt,csih,cvs,cvsps,cygrunsrv,cygutils,cygwin,dash,ddir,delta,diffutils
SET PACKAGES=%PACKAGES%,dos2unix,editrights,file,findutils,flex,gamin,gawk,gcc-core,gcc-g++,gcc-tools-epoch1-autoconf
SET PACKAGES=%PACKAGES%,gcc-tools-epoch1-automake,gcc-tools-epoch2-autoconf,gcc-tools-epoch2-automake,gdb,getent,git
SET PACKAGES=%PACKAGES%,grep,grepmail,groff,gsettings-desktop-schemas,gzip,ipc-utils,ipcalc,less,libapr1,libaprutil1
SET PACKAGES=%PACKAGES%,libargp,libasn1_8,libatomic1,libattr1,libautotrace3,libblkid1,libbz2_1,libcairo2,libcloog-isl4,libcom_err2
SET PACKAGES=%PACKAGES%,libcroco0.6_3,libcurl4,libdatrie1,libdb4.5,libdb4.8,libedit0,libEMF1,libexpat1,libfam0,libffi6,libfftw3_3
SET PACKAGES=%PACKAGES%,libfontconfig1,libfpx1,libfreetype6,libgcc1,libgcrypt11,libgd2,libgdbm4,libgdk_pixbuf2.0_0,libgif4,libglib1.2_0
SET PACKAGES=%PACKAGES%,libglib2.0_0,libgmp10,libgmp3,libgnutls26,libgomp1,libgpg-error0,libgraphite2_3,libgs9,libgssapi3,libharfbuzz0
SET PACKAGES=%PACKAGES%,libheimbase1,libheimntlm0,libhx509_5,libICE6,libiconv2,libicu48,libidn11,libintl8,libiodbc2,libisl10,libjasper1
SET PACKAGES=%PACKAGES%,libjbig2,libjpeg8,libkafs0,libkrb5_26,liblcms2_2,libltdl7,liblzma5,liblzo2_2,libMagickCore5,libming1,libmpc3
SET PACKAGES=%PACKAGES%,libmpfr4,libmysqlclient18,libncurses10,libncursesw10,libneon27,libopenldap2_4_2,libopenssl098,libopenssl100
SET PACKAGES=%PACKAGES%,libp11-kit0,libpango1.0_0,libpaper-common,libpaper1,libpcre0,libpcre1,libpixman1_0,libplotter2,libpng14
SET PACKAGES=%PACKAGES%,libpng15,libpopt0,libpq5,libproxy1,libpstoedit0,libreadline7,libroken18,librsvg2_2,libsasl2_3,libserf1_0
SET PACKAGES=%PACKAGES%,libsigsegv2,libSM6,libsqlite3_0,libssh2_1,libssp0,libstdc++6,libtasn1_3,libtasn1_6,libthai0,libtiff5,libuuid1
SET PACKAGES=%PACKAGES%,libwind0,libwrap0,libX11_6,libXau6,libXaw7,libxcb-render0,libxcb-shm0,libxcb1,libxdelta2,libXdmcp6,libXext6
SET PACKAGES=%PACKAGES%,libXft2,libxml2,libXmu6,libXpm4,libXrender1,libXt6,licensecheck,linklint,login,m4,make,makepasswd,man,mboxcheck
SET PACKAGES=%PACKAGES%,mingw-binutils,mingw-gcc-core,mingw-gcc-g++,mingw-pthreads,mingw-runtime,mingw-w32api,mingw64-x86_64-binutils
SET PACKAGES=%PACKAGES%,mingw64-x86_64-gcc,mingw64-x86_64-gcc-core,mingw64-x86_64-gcc-g++,mingw64-x86_64-headers,mingw64-x86_64-runtime
SET PACKAGES=%PACKAGES%,mingw64-x86_64-winpthreads,mintty,net-snmp-agent-libs,net-snmp-libs,net-snmp-perl,openssh,openssl,p11-kit
SET PACKAGES=%PACKAGES%,p11-kit-trust,patcher,perl,perl-Clone,perl-DBD-mysql,perl-DBD-SQLite,perl-DBI,perl-Error,perl-ExtUtils-Depends
SET PACKAGES=%PACKAGES%,perl-ExtUtils-PkgConfig,perl-Image-Magick,perl-IO-Tty,perl-libwin32,perl-Locale-gettext,perl-ming,perl-Net-Libproxy
SET PACKAGES=%PACKAGES%,perl-SGMLSpm,perl-Text-CSV,perl-Text-CSV_XS,perl-Tk,perl-Win32-GUI,perl-XML-Simple,perl_debuginfo,perl_manpages
SET PACKAGES=%PACKAGES%,perl_vendor,pkg-config,popt,pristine-tar,pwget,rebase,rsnapshot,rsync,run,sed,sendxmpp,signify,subversion,tar
SET PACKAGES=%PACKAGES%,terminfo,texinfo,tzcode,util-linux,vim-minimal,w32api-headers,w32api-runtime,wget,which,xdelta,xz,zlib-devel,zlib0

REM Create install directory and copy there install script
mkdir %ROOTDIR%
mkdir %ROOTDIR%\opt\
copy install_vmodel_preq %ROOTDIR%\opt\
REM Install Cygwin
setup-x86_64 -q -d -D -L -X -s %SITE% -l "%LOCALDIR%" -R "%ROOTDIR%" -P %PACKAGES%
 
ECHO Package list:
ECHO - %PACKAGES%
ECHO.
 
ENDLOCAL

EXIT /B 0