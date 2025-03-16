C     PROGRAM SOMNEC(INPUT,OUTPUT,TAPE21)
C
C     PROGRAM TO GENERATE NEC INTERPOLATION GRIDS FOR FIELDS DUE TO
C     GROUND.  FIELD COMPONENTS ARE COMPUTED BY NUMERICAL EVALUATION
C     OF MODIFIED SOMMERFELD INTEGRALS.
C
      PROGRAM SOMNEC
C
      COMPLEX CK1,CK1SQ,ERV,EZV,ERH,EPH,AR1,AR2,AR3,EPSCF,CKSM,CT1,CT2,C
     1T3,CL1,CL2,CON
      COMMON /EVLCOM/ CKSM,CT1,CT2,CT3,CK1,CK1SQ,CK2,CK2SQ,TKMAG,TSMAG,C
     1K1R,ZPH,RHO,JH
      COMMON /GGRID/ AR1(11,10,4),AR2(17,5,4),AR3(9,8,4),EPSCF,DXA(3),DY
     1A(3),XSA(3),YSA(3),NXA(3),NYA(3)
      DIMENSION LCOMP(4)
      CHARACTER*32 OTFILE
      DATA NXA/11,17,9/,NYA/10,5,8/,XSA/0.,.2,.2/,YSA/0.,0.,.3490658504/
      DATA DXA/.02,.05,.1/,DYA/.1745329252,.0872654626,.1745329252/
      DATA LCOMP/3HERV,3HEZV,3HERH,3HEPH/
C
C     READ GROUND PARAMETERS - EPR = RELATIVE DIELECTRIC CONSTANT
C                              SIG = CONDUCTIVITY (MHOS/M)
C                              FMHZ = FREQUENCY (MHZ)
C                              IPT = 1 TO PRINT GRIDS.  =0 OTHERWISE.
C     IF SIG .LT. 0. THEN COMPLEX DIELECTRIC CONSTANT = EPR + J*SIG
C     AND FMHZ IS NOT USED
C
C     READ 15, EPR,SIG,FMHZ,IPT
      PRINT100
100   FORMAT(' Program to Calculate Ground Interpolation Grid')
      PRINT101
101   FORMAT(' For NEC2 Using Sommerfeld-Norton Method')
      PRINT102
102   FORMAT(' ')
      PRINT103
103   FORMAT(' Enter Relative Dielectric Constant:')
      ACCEPT *, EPR
      PRINT104
104   FORMAT(' Enter Conductivity (Mhos/Meter):')
      ACCEPT *, SIG
      PRINT105
105   FORMAT(' Enter Frequency (MHz):')
      ACCEPT *, FMHZ
      PRINT106
106   FORMAT(' Enter 1 to Print Grids, 0 to Suppress Printing:')
      ACCEPT *, IPT
      PRINT107
107   FORMAT(' Enter Data Output Filename:')
      ACCEPT 24, OTFILE
      PRINT *, ' Relative Dielectric Constant = ', EPR
      PRINT *, ' Conductivity (Mhos/Meter) = ', SIG
      PRINT *, ' Frequency, MHz = ', FMHZ
      PRINT *, ' Printing Flag = ', IPT
      PRINT *, ' Data Output File Name = ', OTFILE
      IF (SIG.LT.0) GO TO 1
      WLAM=299.8/FMHZ
      EPSCF=CMPLX(EPR,-SIG*WLAM*59.96)
      GO TO 2
1     EPSCF=CMPLX(EPR,SIG)
2     TST=SECNDS (0.0)
      CK2=6.283185308
      CK2SQ=CK2*CK2
C
C     SOMMERFELD INTEGRAL EVALUATION USES EXP(-JWT), NEC USES EXP(+JWT),
C     HENCE NEED CONJG(EPSCF).  CONJUGATE OF FIELDS OCCURS IN SUBROUTINE
C     EVALUA.
C
      CK1SQ=CK2SQ*CONJG(EPSCF)
      CK1=CSQRT(CK1SQ)
      CK1R=REAL(CK1)
      TKMAG=100.*CABS(CK1)
      TSMAG=100.*CK1*CONJG(CK1)
      CKSM=CK2SQ/(CK1SQ+CK2SQ)
      CT1=.5*(CK1SQ-CK2SQ)
      ERV=CK1SQ*CK1SQ
      EZV=CK2SQ*CK2SQ
      CT2=.125*(ERV-EZV)
      ERV=ERV*CK1SQ
      EZV=EZV*CK2SQ
      CT3=.0625*(ERV-EZV)
C
C     LOOP OVER 3 GRID REGIONS
C
      DO 6 K=1,3
      NR=NXA(K)
      NTH=NYA(K)
      DR=DXA(K)
      DTH=DYA(K)
      R=XSA(K)-DR
      IRS=1
      IF (K.EQ.1) R=XSA(K)
      IF (K.EQ.1) IRS=2
C
C     LOOP OVER R.  (R=SQRT(RHO**2 + (Z+H)**2))
C
      DO 6 IR=IRS,NR
      R=R+DR
      THET=YSA(K)-DTH
C
C     LOOP OVER THETA.  (THETA=ATAN((Z+H)/RHO))
C
      DO 6 ITH=1,NTH
      THET=THET+DTH
      RHO=R*COS(THET)
      ZPH=R*SIN(THET)
      IF (RHO.LT.1.E-7) RHO=1.E-8
      IF (ZPH.LT.1.E-7) ZPH=0.
      CALL EVLUA (ERV,EZV,ERH,EPH)
      RK=CK2*R
      CON=-(0.,4.77147)*R/CMPLX(COS(RK),-SIN(RK))
      GO TO (3,4,5), K
3     AR1(IR,ITH,1)=ERV*CON
      AR1(IR,ITH,2)=EZV*CON
      AR1(IR,ITH,3)=ERH*CON
      AR1(IR,ITH,4)=EPH*CON
      GO TO 6
4     AR2(IR,ITH,1)=ERV*CON
      AR2(IR,ITH,2)=EZV*CON
      AR2(IR,ITH,3)=ERH*CON
      AR2(IR,ITH,4)=EPH*CON
      GO TO 6
5     AR3(IR,ITH,1)=ERV*CON
      AR3(IR,ITH,2)=EZV*CON
      AR3(IR,ITH,3)=ERH*CON
      AR3(IR,ITH,4)=EPH*CON
6     CONTINUE
C
C     FILL GRID 1 FOR R EQUAL TO ZERO.
C
      CL2=-(0.,188.370)*(EPSCF-1.)/(EPSCF+1.)
      CL1=CL2/(EPSCF+1.)
      EZV=EPSCF*CL1
      THET=-DTH
      NTH=NYA(1)
      DO 9 ITH=1,NTH
      THET=THET+DTH
      IF (ITH.EQ.NTH) GO TO 7
      TFAC2=COS(THET)
      TFAC1=(1.-SIN(THET))/TFAC2
      TFAC2=TFAC1/TFAC2
      ERV=EPSCF*CL1*TFAC1
      ERH=CL1*(TFAC2-1.)+CL2
      EPH=CL1*TFAC2-CL2
      GO TO 8
7     ERV=0.
      ERH=CL2-.5*CL1
      EPH=-ERH
8     AR1(1,ITH,1)=ERV
      AR1(1,ITH,2)=EZV
      AR1(1,ITH,3)=ERH
9     AR1(1,ITH,4)=EPH
      TIM=SECNDS (TST)
C
C     WRITE GRID ON TAPE21
C
      OPEN (UNIT=21,FILE=OTFILE,FORM='UNFORMATTED',STATUS='NEW',ERR=21)
      WRITE (21) AR1,AR2,AR3,EPSCF,DXA,DYA,XSA,YSA,NXA,NYA
      CLOSE (UNIT=21)
      IF (IPT.EQ.0) GO TO 14
C
C     PRINT GRID
C
      PRINT 17, EPSCF
      DO 13 K=1,3
      NR=NXA(K)
      NTH=NYA(K)
      PRINT 18, K,XSA(K),DXA(K),NR,YSA(K),DYA(K),NTH
      DO 13 L=1,4
      PRINT 19, LCOMP(L)
      DO 13 IR=1,NR
      GO TO (10,11,12), K
10    PRINT 20, IR,(AR1(IR,ITH,L),ITH=1,NTH)
      GO TO 13
11    PRINT 20, IR,(AR2(IR,ITH,L),ITH=1,NTH)
      GO TO 13
12    PRINT 20, IR,(AR3(IR,ITH,L),ITH=1,NTH)
13    CONTINUE
14    CONTINUE
      PRINT 16, TIM
      GO TO 23
21    PRINT 22, OTFILE
23    STOP
C
15    FORMAT (3E10.3,I5)
16    FORMAT (6H TIME=,E12.3,8H SECONDS)
17    FORMAT (30H NEC GROUND INTERPOLATION GRID,/,21H DIELECTRIC CONSTAN
     1T=,2E12.5)
18    FORMAT (///,5H GRID,I2,/,4X,5HR(1)=,F7.4,4X,3HDR=,F7.4,4X,3HNR=,I3
     1,/,9H THET(1)=,F7.4,3X,4HDTH=,F7.4,3X,4HNTH=,I3,//)
19    FORMAT (///1X,A3)
20    FORMAT (4H IR=,I3,/1X,(10(1PE12.5)))
22    FORMAT ('ERROR CREATING OUTPUT FILE = ',A)
24    FORMAT (A)
      END
C ***
C
C
      SUBROUTINE BESSEL (Z,J0,J0P)
C
C     BESSEL EVALUATES THE ZERO-ORDER BESSEL FUNCTION AND ITS DERIVATIVE
C     FOR COMPLEX ARGUMENT Z.
C
      COMPLEX J0,J0P,P0Z,P1Z,Q0Z,Q1Z,Z,ZI,ZI2,ZK,FJ,CZ,SZ,J0X,J0PX
      DIMENSION M(101), A1(25), A2(25), FJX(2)
      EQUIVALENCE (FJ,FJX)
      DATA C3,P10,P20,Q10,Q20/.7978845608,.0703125,.1121520996,
     1.125,.0732421875/
      DATA P11,P21,Q11,Q21/.1171875,.1441955566,.375,.1025390625/
      DATA POF,INIT/.7853981635,0/,FJX/0.,1./
      IF (INIT.EQ.0) GO TO 5
1     ZMS=Z*CONJG(Z)
      IF (ZMS.GT.1.E-12) GO TO 2
      J0=(1.,0.)
      J0P=-.5*Z
      RETURN
2     IB=0
      IF (ZMS.GT.37.21) GO TO 4
      IF (ZMS.GT.36.) IB=1
C     SERIES EXPANSION
      IZ=1.+ZMS
      MIZ=M(IZ)
      J0=(1.,0.)
      J0P=J0
      ZK=J0
      ZI=Z*Z
      DO 3 K=1,MIZ
      ZK=ZK*A1(K)*ZI
      J0=J0+ZK
3     J0P=J0P+A2(K)*ZK
      J0P=-.5*Z*J0P
      IF (IB.EQ.0) RETURN
      J0X=J0
      J0PX=J0P
C     ASYMPTOTIC EXPANSION
4     ZI=1./Z
      ZI2=ZI*ZI
      P0Z=1.+(P20*ZI2-P10)*ZI2
      P1Z=1.+(P11-P21*ZI2)*ZI2
      Q0Z=(Q20*ZI2-Q10)*ZI
      Q1Z=(Q11-Q21*ZI2)*ZI
      ZK=CEXP(FJ*(Z-POF))
      ZI2=1./ZK
      CZ=.5*(ZK+ZI2)
      SZ=FJ*.5*(ZI2-ZK)
      ZK=C3*CSQRT(ZI)
      J0=ZK*(P0Z*CZ-Q0Z*SZ)
      J0P=-ZK*(P1Z*SZ+Q1Z*CZ)
      IF (IB.EQ.0) RETURN
      ZMS=COS((SQRT(ZMS)-6.)*31.41592654)
      J0=.5*(J0X*(1.+ZMS)+J0*(1.-ZMS))
      J0P=.5*(J0PX*(1.+ZMS)+J0P*(1.-ZMS))
      RETURN
C     INITIALIZATION OF CONSTANTS
5     DO 6 K=1,25
      A1(K)=-.25/(K*K)
6     A2(K)=1./(K+1.)
      DO 8 I=1,101
      TEST=1.
      DO 7 K=1,24
      INIT=K
      TEST=-TEST*I*A1(K)
      IF (TEST.LT.1.E-6) GO TO 8
7     CONTINUE
8     M(I)=INIT
      GO TO 1
      END
C ***
C
C
      SUBROUTINE EVLUA (ERV,EZV,ERH,EPH)
C
C     EVLUA CONTROLS THE INTEGRATION CONTOUR IN THE COMPLEX LAMBDA
C     PLANE FOR EVALUATION OF THE SOMMERFELD INTEGRALS.
C
      COMPLEX ERV,EZV,ERH,EPH,A,B,CK1,CK1SQ,BK,SUM,DELTA,ANS,DELTA2,CP1,
     1CP2,CP3,CKSM,CT1,CT2,CT3
      COMMON /CNTOUR/ A,B
      COMMON /EVLCOM/ CKSM,CT1,CT2,CT3,CK1,CK1SQ,CK2,CK2SQ,TKMAG,TSMAG,C
     1K1R,ZPH,RHO,JH
      DIMENSION SUM(6), ANS(6)
      DATA PTP/.6283185308/
      DEL=ZPH
      IF (RHO.GT.DEL) DEL=RHO
      IF (ZPH.LT.2.*RHO) GO TO 4
C
C     BESSEL FUNCTION FORM OF SOMMERFELD INTEGRALS
C
      JH=0
      A=(0.,0.)
      DEL=1./DEL
      IF (DEL.LE.TKMAG) GO TO 2
      B=CMPLX(.1*TKMAG,-.1*TKMAG)
      CALL ROM1 (6,SUM,2)
      A=B
      B=CMPLX(DEL,-DEL)
      CALL ROM1 (6,ANS,2)
      DO 1 I=1,6
1     SUM(I)=SUM(I)+ANS(I)
      GO TO 3
2     B=CMPLX(DEL,-DEL)
      CALL ROM1 (6,SUM,2)
3     DELTA=PTP*DEL
      CALL GSHANK (B,DELTA,ANS,6,SUM,0,B,B)
      GO TO 10
C
C     HANKEL FUNCTION FORM OF SOMMERFELD INTEGRALS
C
4     JH=1
      CP1=CMPLX(0.,.4*CK2)
      CP2=CMPLX(.6*CK2,-.2*CK2)
      CP3=CMPLX(1.02*CK2,-.2*CK2)
      A=CP1
      B=CP2
      CALL ROM1 (6,SUM,2)
      A=CP2
      B=CP3
      CALL ROM1 (6,ANS,2)
      DO 5 I=1,6
5     SUM(I)=-(SUM(I)+ANS(I))
C     PATH FROM IMAGINARY AXIS TO -INFINITY
      SLOPE=1000.
      IF (ZPH.GT..001*RHO) SLOPE=RHO/ZPH
      DEL=PTP/DEL
      DELTA=CMPLX(-1.,SLOPE)*DEL/SQRT(1.+SLOPE*SLOPE)
      DELTA2=-CONJG(DELTA)
      CALL GSHANK (CP1,DELTA,ANS,6,SUM,0,BK,BK)
      RMIS=RHO*(REAL(CK1)-CK2)
      IF (RMIS.LT.2.*CK2) GO TO 8
      IF (RHO.LT.1.E-10) GO TO 8
      IF (ZPH.LT.1.E-10) GO TO 6
      BK=CMPLX(-ZPH,RHO)*(CK1-CP3)
      RMIS=-REAL(BK)/ABS(AIMAG(BK))
      IF(RMIS.GT.4.*RHO/ZPH)GO TO 8
C     INTEGRATE UP BETWEEN BRANCH CUTS, THEN TO + INFINITY
6     CP1=CK1-(.1,.2)
      CP2=CP1+.2
      BK=CMPLX(0.,DEL)
      CALL GSHANK (CP1,BK,SUM,6,ANS,0,BK,BK)
      A=CP1
      B=CP2
      CALL ROM1 (6,ANS,1)
      DO 7 I=1,6
7     ANS(I)=ANS(I)-SUM(I)
      CALL GSHANK (CP3,BK,SUM,6,ANS,0,BK,BK)
      CALL GSHANK (CP2,DELTA2,ANS,6,SUM,0,BK,BK)
      GO TO 10
C     INTEGRATE BELOW BRANCH POINTS, THEN TO + INFINITY
8     DO 9 I=1,6
9     SUM(I)=-ANS(I)
      RMIS=REAL(CK1)*1.01
      IF (CK2+1..GT.RMIS) RMIS=CK2+1.
      BK=CMPLX(RMIS,.99*AIMAG(CK1))
      DELTA=BK-CP3
      DELTA=DELTA*DEL/CABS(DELTA)
      CALL GSHANK (CP3,DELTA,ANS,6,SUM,1,BK,DELTA2)
10    ANS(6)=ANS(6)*CK1
C     CONJUGATE SINCE NEC USES EXP(+JWT)
      ERV=CONJG(CK1SQ*ANS(3))
      EZV=CONJG(CK1SQ*(ANS(2)+CK2SQ*ANS(5)))
      ERH=CONJG(CK2SQ*(ANS(1)+ANS(6)))
      EPH=-CONJG(CK2SQ*(ANS(4)+ANS(6)))
      RETURN
      END
C ***
C
C
      SUBROUTINE GSHANK (START,DELA,SUM,NANS,SEED,IBK,BK,DELB)
C
C     GSHANK INTEGRATES THE 6 SOMMERFELD INTEGRALS FROM START TO
C     INFINITY (UNTIL CONVERGENCE) IN LAMBDA.  AT THE BREAK POINT, BK,
C     THE STEP INCREMENT MAY BE CHANGED FROM DELA TO DELB.  SHANK'S
C     ALGORITHM TO ACCELERATE CONVERGENCE OF A SLOWLY CONVERGING SERIES 
C     IS USED
C
      COMPLEX START,DELA,SUM,SEED,BK,DELB,A,B,Q1,Q2,ANS1,ANS2,A1,A2,AS1,
     1AS2,DEL,AA
      COMMON /CNTOUR/ A,B
      DIMENSION Q1(6,20), Q2(6,20), ANS1(6), ANS2(6), SUM(6), SEED(6)
      DATA CRIT/1.E-4/,MAXH/20/
      RBK=REAL(BK)
      DEL=DELA
      IBX=0
      IF (IBK.EQ.0) IBX=1
      DO 1 I=1,NANS
1     ANS2(I)=SEED(I)
      B=START
2     DO 20 INT=1,MAXH
      INX=INT
      A=B
      B=B+DEL
      IF (IBX.EQ.0.AND.REAL(B).GE.RBK) GO TO 5
      CALL ROM1 (NANS,SUM,2)
      DO 3 I=1,NANS
3     ANS1(I)=ANS2(I)+SUM(I)
      A=B
      B=B+DEL
      IF (IBX.EQ.0.AND.REAL(B).GE.RBK) GO TO 6
      CALL ROM1 (NANS,SUM,2)
      DO 4 I=1,NANS
4     ANS2(I)=ANS1(I)+SUM(I)
      GO TO 11
C     HIT BREAK POINT.  RESET SEED AND START OVER.
5     IBX=1
      GO TO 7
6     IBX=2
7     B=BK
      DEL=DELB
      CALL ROM1 (NANS,SUM,2)
      IF (IBX.EQ.2) GO TO 9
      DO 8 I=1,NANS
8     ANS2(I)=ANS2(I)+SUM(I)
      GO TO 2
9     DO 10 I=1,NANS
10    ANS2(I)=ANS1(I)+SUM(I)
      GO TO 2
11    DEN=0.
      DO 18 I=1,NANS
      AS1=ANS1(I)
      AS2=ANS2(I)
      IF (INT.LT.2) GO TO 17
      DO 16 J=2,INT
      JM=J-1
      AA=Q2(I,JM)
      A1=Q1(I,JM)+AS1-2.*AA
      IF (REAL(A1).EQ.0..AND.AIMAG(A1).EQ.0.) GO TO 12
      A2=AA-Q1(I,JM)
      A1=Q1(I,JM)-A2*A2/A1
      GO TO 13
12    A1=Q1(I,JM)
13    A2=AA+AS2-2.*AS1
      IF (REAL(A2).EQ.0..AND.AIMAG(A2).EQ.0.) GO TO 14
      A2=AA-(AS1-AA)*(AS1-AA)/A2
      GO TO 15
14    A2=AA
15    Q1(I,JM)=AS1
      Q2(I,JM)=AS2
      AS1=A1
16    AS2=A2
17    Q1(I,INT)=AS1
      Q2(I,INT)=AS2
      AMG=ABS(REAL(AS2))+ABS(AIMAG(AS2))
      IF (AMG.GT.DEN) DEN=AMG
18    CONTINUE
      DENM=1.E-3*DEN*CRIT
      JM=INT-3
      IF (JM.LT.1) JM=1
      DO 19 J=JM,INT
      DO 19 I=1,NANS
      A1=Q2(I,J)
      DEN=(ABS(REAL(A1))+ABS(AIMAG(A1)))*CRIT
      IF (DEN.LT.DENM) DEN=DENM
      A1=Q1(I,J)-A1
      AMG=ABS(REAL(A1))+ABS(AIMAG(A1))
      IF (AMG.GT.DEN) GO TO 20
19    CONTINUE
      GO TO 22
20    CONTINUE
      PRINT 24
      DO 21 I=1,NANS
21    PRINT 25, Q1(I,INX),Q2(I,INX)
22    DO 23 I=1,NANS
23    SUM(I)=.5*(Q1(I,INX)+Q2(I,INX))
      RETURN
C
24    FORMAT (46H **** NO CONVERGENCE IN SUBROUTINE GSHANK ****)
25    FORMAT (10E12.5)
      END
C ***
C
C
      SUBROUTINE HANKEL (Z,H0,H0P)
C
C     HANKEL EVALUATES HANKEL FUNCTION OF THE FIRST KIND, ORDER ZERO,
C     AND ITS DERIVATIVE FOR COMPLEX ARGUMENT Z.
C
      COMPLEX CLOGZ,H0,H0P,J0,J0P,P0Z,P1Z,Q0Z,Q1Z,Y0,Y0P,Z,ZI,ZI2,ZK,FJ
      DIMENSION M(101), A1(25), A2(25), A3(25), A4(25), FJX(2)
      EQUIVALENCE (FJ,FJX)
      DATA PI,GAMMA,C1,C2,C3,P10,P20/3.141592654,.5772156649,-.024578509
     15,.3674669052,.7978845608,.0703125,.1121520996/
      DATA Q10,Q20,P11,P21,Q11,Q21/.125,.0732421875,.1171875,.1441955566
     1,.375,.1025390625/
      DATA P0F,INIT/.7853981635,0/,FJX/0.,1./
      IF (INIT.EQ.0) GO TO 5
1     ZMS=Z*CONJG(Z)
      IF (ZMS.NE.0.) GO TO 2
      PRINT 9
      STOP
2     IB=0
      IF (ZMS.GT.16.81) GO TO 4
      IF (ZMS.GT.16.) IB=1
C     SERIES EXPANSION
      IZ=1.+ZMS
      MIZ=M(IZ)
      J0=(1.,0.)
      J0P=J0
      Y0=(0.,0.)
      Y0P=Y0
      ZK=J0
      ZI=Z*Z
      DO 3 K=1,MIZ
      ZK=ZK*A1(K)*ZI
      J0=J0+ZK
      J0P=J0P+A2(K)*ZK
      Y0=Y0+A3(K)*ZK
3     Y0P=Y0P+A4(K)*ZK
      J0P=-.5*Z*J0P
      CLOGZ=CLOG(.5*Z)
      Y0=(2.*J0*CLOGZ-Y0)/PI+C2
      Y0P=(2./Z+2.*J0P*CLOGZ+.5*Y0P*Z)/PI+C1*Z
      H0=J0+FJ*Y0
      H0P=J0P+FJ*Y0P
      IF (IB.EQ.0) RETURN
      Y0=H0
      Y0P=H0P
C     ASYMPTOTIC EXPANSION
4     ZI=1./Z
      ZI2=ZI*ZI
      P0Z=1.+(P20*ZI2-P10)*ZI2
      P1Z=1.+(P11-P21*ZI2)*ZI2
      Q0Z=(Q20*ZI2-Q10)*ZI
      Q1Z=(Q11-Q21*ZI2)*ZI
      ZK=CEXP(FJ*(Z-P0F))*CSQRT(ZI)*C3
      H0=ZK*(P0Z+FJ*Q0Z)
      H0P=FJ*ZK*(P1Z+FJ*Q1Z)
      IF (IB.EQ.0) RETURN
      ZMS=COS((SQRT(ZMS)-4.)*31.41592654)
      H0=.5*(Y0*(1.+ZMS)+H0*(1.-ZMS))
      H0P=.5*(Y0P*(1.+ZMS)+H0P*(1.-ZMS))
      RETURN
C     INITIALIZATION OF CONSTANTS
5     PSI=-GAMMA
      DO 6 K=1,25
      A1(K)=-.25/(K*K)
      A2(K)=1./(K+1.)
      PSI=PSI+1./K
      A3(K)=PSI+PSI
6     A4(K)=(PSI+PSI+1./(K+1.))/(K+1.)
      DO 8 I=1,101
      TEST=1.
      DO 7 K=1,24
      INIT=K
      TEST=-TEST*I*A1(K)
      IF (TEST*A3(K).LT.1.E-6) GO TO 8
7     CONTINUE
8     M(I)=INIT
      GO TO 1
C
9     FORMAT (34H ERROR - HANKEL NOT VALID FOR Z=0.)
      END
C ***
C
C
      SUBROUTINE LAMBDA (T,XLAM,DXLAM)
C
C     COMPUTE INTEGRATION PARAMETER XLAM=LAMBDA FROM PARAMETER T.
C
      COMPLEX A,B,XLAM,DXLAM
      COMMON /CNTOUR/ A,B
      DXLAM=B-A
      XLAM=A+DXLAM*T
      RETURN
      END
C ***
C
C
      SUBROUTINE ROM1 (N,SUM,NX)
C
C     ROM1 INTEGRATES THE 6 SOMMERFELD INTEGRALS FROM A TO B IN LAMBDA.
C     THE METHOD OF VARIABLE INTERVAL WIDTH ROMBERG INTEGRATION IS USED.
C
      COMPLEX A,B,SUM,G1,G2,G3,G4,G5,T00,T01,T10,T02,T11,T20
      COMMON /CNTOUR/ A,B
      DIMENSION SUM(6), G1(6), G2(6), G3(6), G4(6), G5(6), T01(6), T10(6
     1), T20(6)
      DATA NM,NTS,RX/131072,4,1.E-4/
      LSTEP=0
      Z=0.
      ZE=1.
      S=1.
      EP=S/(1.E4*NM)
      ZEND=ZE-EP
      DO 1 I=1,N
1     SUM(I)=(0.,0.)
      NS=NX
      NT=0
      CALL SAOA (Z,G1)
2     DZ=S/NS
      IF (Z+DZ.LE.ZE) GO TO 3
      DZ=ZE-Z
      IF (DZ.LE.EP) GO TO 17
3     DZOT=DZ*.5
      CALL SAOA (Z+DZOT,G3)
      CALL SAOA (Z+DZ,G5)
4     NOGO=0
      DO 5 I=1,N
      T00=(G1(I)+G5(I))*DZOT
      T01(I)=(T00+DZ*G3(I))*.5
      T10(I)=(4.*T01(I)-T00)/3.
C     TEST CONVERGENCE OF 3 POINT ROMBERG RESULT
      CALL TEST (REAL(T01(I)),REAL(T10(I)),TR,AIMAG(T01(I)),AIMAG(T10(I)
     1),TI,0.)
      IF (TR.GT.RX.OR.TI.GT.RX) NOGO=1
5     CONTINUE
      IF (NOGO.NE.0) GO TO 7
      DO 6 I=1,N
6     SUM(I)=SUM(I)+T10(I)
      NT=NT+2
      GO TO 11
7     CALL SAOA (Z+DZ*.25,G2)
      CALL SAOA (Z+DZ*.75,G4)
      NOGO=0
      DO 8 I=1,N
      T02=(T01(I)+DZOT*(G2(I)+G4(I)))*.5
      T11=(4.*T02-T01(I))/3.
      T20(I)=(16.*T11-T10(I))/15.
C     TEST CONVERGENCE OF 5 POINT ROMBERG RESULT
      CALL TEST (REAL(T11),REAL(T20(I)),TR,AIMAG(T11),AIMAG(T20(I)),TI,0
     1.)
      IF (TR.GT.RX.OR.TI.GT.RX) NOGO=1
8     CONTINUE
      IF (NOGO.NE.0) GO TO 13
9     DO 10 I=1,N
10    SUM(I)=SUM(I)+T20(I)
      NT=NT+1
11    Z=Z+DZ
      IF (Z.GT.ZEND) GO TO 17
      DO 12 I=1,N
12    G1(I)=G5(I)
      IF (NT.LT.NTS.OR.NS.LE.NX) GO TO 2
      NS=NS/2
      NT=1
      GO TO 2
13    NT=0
      IF (NS.LT.NM) GO TO 15
      IF (LSTEP.EQ.1) GO TO 9
      LSTEP=1
      CALL LAMBDA (Z,T00,T11)
      PRINT 18, T00
      PRINT 19, Z,DZ,A,B
      DO 14 I=1,N
14    PRINT 19, G1(I),G2(I),G3(I),G4(I),G5(I)
      GO TO 9
15    NS=NS*2
      DZ=S/NS
      DZOT=DZ*.5
      DO 16 I=1,N
      G5(I)=G3(I)
16    G3(I)=G2(I)
      GO TO 4
17    CONTINUE
      RETURN
C
18    FORMAT (38H ROM1 -- STEP SIZE LIMITED AT LAMBDA =,2E12.5)
19    FORMAT (10E12.5)
      END
C ***
C
C
      SUBROUTINE SAOA (T,ANS)
C
C     SAOA COMPUTES THE INTEGRAND FOR EACH OF THE 6
C     SOMMERFELD INTEGRALS FOR SOURCE AND OBSERVER ABOVE GROUND
C
      COMPLEX ANS,XL,DXL,CGAM1,CGAM2,B0,B0P,COM,CK1,CK1SQ,CKSM,CT1,CT2,C
     1T3,DGAM,DEN1,DEN2
      COMMON /EVLCOM/ CKSM,CT1,CT2,CT3,CK1,CK1SQ,CK2,CK2SQ,TKMAG,TSMAG,C
     1K1R,ZPH,RHO,JH
      DIMENSION ANS(6)
      CALL LAMBDA (T,XL,DXL)
      IF (JH.GT.0) GO TO 1
C     BESSEL FUNCTION FORM
      CALL BESSEL (XL*RHO,B0,B0P)
      B0=2.*B0
      B0P=2.*B0P
      CGAM1=CSQRT(XL*XL-CK1SQ)
      CGAM2=CSQRT(XL*XL-CK2SQ)
      IF (REAL(CGAM1).EQ.0.) CGAM1=CMPLX(0.,-ABS(AIMAG(CGAM1)))
      IF (REAL(CGAM2).EQ.0.) CGAM2=CMPLX(0.,-ABS(AIMAG(CGAM2)))
      GO TO 2
C     HANKEL FUNCTION FORM
1     CALL HANKEL (XL*RHO,B0,B0P)
      COM=XL-CK1
      CGAM1=CSQRT(XL+CK1)*CSQRT(COM)
      IF (REAL(COM).LT.0..AND.AIMAG(COM).GE.0.) CGAM1=-CGAM1
      COM=XL-CK2
      CGAM2=CSQRT(XL+CK2)*CSQRT(COM)
      IF (REAL(COM).LT.0..AND.AIMAG(COM).GE.0.) CGAM2=-CGAM2
2     XLR=XL*CONJG(XL)
      IF (XLR.LT.TSMAG) GO TO 3
      IF (AIMAG(XL).LT.0.) GO TO 4
      XLR=REAL(XL)
      IF (XLR.LT.CK2) GO TO 5
      IF (XLR.GT.CK1R) GO TO 4
3     DGAM=CGAM2-CGAM1
      GO TO 7
4     SIGN=1.
      GO TO 6
5     SIGN=-1.
6     DGAM=1./(XL*XL)
      DGAM=SIGN*((CT3*DGAM+CT2)*DGAM+CT1)/XL
7     DEN2=CKSM*DGAM/(CGAM2*(CK1SQ*CGAM2+CK2SQ*CGAM1))
      DEN1=1./(CGAM1+CGAM2)-CKSM/CGAM2
      COM=DXL*XL*CEXP(-CGAM2*ZPH)
      ANS(6)=COM*B0*DEN1/CK1
      COM=COM*DEN2
      IF (RHO.EQ.0.) GO TO 8
      B0P=B0P/RHO
      ANS(1)=-COM*XL*(B0P+B0*XL)
      ANS(4)=COM*XL*B0P
      GO TO 9
8     ANS(1)=-COM*XL*XL*.5
      ANS(4)=ANS(1)
9     ANS(2)=COM*CGAM2*CGAM2*B0
      ANS(3)=-ANS(4)*CGAM2*RHO
      ANS(5)=COM*B0
      RETURN
      END
C ***
C
C
      SUBROUTINE TEST (F1R,F2R,TR,F1I,F2I,TI,DMIN)
C
C     TEST FOR CONVERGENCE IN NUMERICAL INTEGRATION
C
      DEN=ABS(F2R)
      TR=ABS(F2I)
      IF (DEN.LT.TR) DEN=TR
      IF (DEN.LT.DMIN) DEN=DMIN
      IF (DEN.LT.1.E-37) GO TO 1
      TR=ABS((F1R-F2R)/DEN)
      TI=ABS((F1I-F2I)/DEN)
      RETURN
1     TR=0.
      TI=0.
      RETURN
      END
