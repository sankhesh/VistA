ZZRGUT1 ;RGI/VSL - Unit Tests - Problem List ;3/28/13
 ;;1.0;UNIT TEST;;Apr 25, 2012;Build 1;
 Q:$T(^GMPLAPI1)=""
 TSTART
 I $T(EN^XTMUNIT)'="" D EN^XTMUNIT("ZZRGUT1")
 TROLLBACK
 Q
 ;
STARTUP ;
 S U="^"
 S DT=$P($$HTFM^XLFDT($H),".")
 S LSTNAME="UserList"_DT
 S CATNAME="Diabetes "_DT
 S LOC=$P(^SC(0),U,3)
 S USER="1"
 S LSTMAX=$P(^GMPL(125,0),U,3)
 S LSTCNT=$P(^GMPL(125,0),U,4)
 S LSTCMAX=$P(^GMPL(125.1,0),U,3)
 S LSTCCNT=$P(^GMPL(125.1,0),U,4)
 S CATMAX=$P(^GMPL(125.11,0),U,3)
 S CATCNT=$P(^GMPL(125.11,0),U,4)
 S CATCMAX=$P(^GMPL(125.12,0),U,3)
 S CATCCNT=$P(^GMPL(125.12,0),U,4)
 Q
 ;
SETUP ;
 ; Check if List name already exists.
 I $D(^GMPL(125,"B",LSTNAME))=0 Q
 S LSTNAME=LSTNAME_"1" D SETUP
 Q
 ;
SHUTDOWN ;
 Q
 ;
NEWLST ; Test New list
 ;
 K:$D(RETURN) RETURN
 S NEWLST=$$NEWLST^GMPLAPI1(.RETURN,LSTNAME,"W")
 D CHKEQ^XTMUNIT(0,+NEWLST,"List already exists")
 D CHKEQ^XTMUNIT("INVPARAM",$P(RETURN(0),U,1),"INVPARAM GMPLLOC expected")
 ;
 K:$D(RETURN) RETURN
 S NEWLST=$$NEWLST^GMPLAPI1(.RETURN,"")
 D CHKEQ^XTMUNIT(0,+NEWLST,"List already exists")
 D CHKEQ^XTMUNIT("INVPARAM",$P(RETURN(0),U,1),"INVPARAM GMPLLST expected")
 ;
 K:$D(RETURN) RETURN
 S NEWLST=$$NEWLST^GMPLAPI1(.RETURN,LSTNAME,LOC+1)
 D CHKEQ^XTMUNIT(0,+NEWLST,"List already exists")
 D CHKEQ^XTMUNIT("LOCNFND",$P(RETURN(0),U,1),"LOCNFND expected")
 ;
 K:$D(RETURN) RETURN
 S NEWLST=$$NEWLST^GMPLAPI1(.RETURN,"PL")
 D CHKEQ^XTMUNIT(0,+NEWLST,"List already exists")
 D CHKEQ^XTMUNIT("INVPARAM",$P(RETURN(0),U,1),"INVPARAM GMPLLST expected (too short name)")
 ;
 K:$D(RETURN) RETURN
 N LNGNAME S LNGNAME="L"
 F I=1:1:30 S LNGNAME=LNGNAME_"L"
 S NEWLST=$$NEWLST^GMPLAPI1(.RETURN,LNGNAME)
 D CHKEQ^XTMUNIT(0,+NEWLST,"List already exists")
 D CHKEQ^XTMUNIT("INVPARAM",$P(RETURN(0),U,1),"INVPARAM GMPLLST expected (too long name)")
 ;
 K:$D(RETURN) RETURN
 S %=$$NEWLST^GMPLAPI1(.RETURN,LSTNAME,LOC)
 S NEWLST=RETURN
 D CHKEQ^XTMUNIT(LSTMAX+1,+RETURN,"INCORRECT LIST IEN")
 D CHKTF^XTMUNIT($D(RETURN(0))=0,"No error expected")
 D CHKEQ^XTMUNIT(LSTMAX+1,$P(^GMPL(125,0),U,3),"INCORRECT MOST RECENTLY IEN")
 D CHKEQ^XTMUNIT(LSTCNT+1,$P(^GMPL(125,0),U,4),"INCORRECT ENTRIES COUNT")
 D CHKEQ^XTMUNIT("",^GMPL(125,"B",LSTNAME,+RETURN),"INCORRECT CROSS-REFERENCE")
 D CHKEQ^XTMUNIT(LSTNAME_U_U_LOC,^GMPL(125,+RETURN,0),"INCORRECT LIST DATA")
 ;
 K:$D(RETURN) RETURN
 S %=$$NEWLST^GMPLAPI1(.RETURN,LSTNAME,LOC)
 D CHKEQ^XTMUNIT(0,+RETURN,"INCORRECT EXISTING LIST IEN")
 D CHKEQ^XTMUNIT("LISTXST",$P(RETURN(0),U,1),"LISTXST expected")
 Q
 ;
ASSUSR ; Test Assign list to users (ASSGNUSR)
 K:$D(RETURN) RETURN
 S %=$$ASSUSR^GMPLAPI6(.RETURN,"A","")
 D CHKEQ^XTMUNIT("INVPARAM",$P(RETURN(0),U,1),"INVPARAM GMPLLST expected")
 ;
 K:$D(RETURN) RETURN
 S %=$$ASSUSR^GMPLAPI6(.RETURN,+NEWLST+1,"")
 D CHKEQ^XTMUNIT("LISTNFND",$P(RETURN(0),U,1),"LISTNFND expected")
 ;
 K:$D(RETURN) RETURN
 S %=$$ASSUSR^GMPLAPI6(.RETURN,+NEWLST,"^USER^")
 D CHKEQ^XTMUNIT("INVPARAM",$P(RETURN(0),U,1),"INVPARAM USER expected")
 ;
 K:$D(RETURN) RETURN
 S %=$$ASSUSR^GMPLAPI6(.RETURN,+NEWLST,$P(^VA(200,0),U,3)+1)
 D CHKEQ^XTMUNIT("PROVNFND",$P(RETURN(0),U,1),"PROVNFND expected")
 ;
 K:$D(RETURN) RETURN
 S %=$$ASSUSR^GMPLAPI6(.RETURN,+NEWLST,USER)
 D CHKEQ^XTMUNIT(^VA(200,USER,125),U_+NEWLST,"INCORRECT USER ASSIGNED LIST DATA")
 D CHKTF^XTMUNIT($D(RETURN(0))=0,"No error expected")
 ;
 Q
 ;
REMUSR ; Test Remove list from users
 K:$D(RETURN) RETURN
 S %=$$REMUSR^GMPLAPI6(.RETURN,"A",USER)
 D CHKEQ^XTMUNIT("INVPARAM",$P(RETURN(0),U,1),"INVPARAM GMPLLST expected")
 ;
 K:$D(RETURN) RETURN
 S %=$$REMUSR^GMPLAPI6(.RETURN,+NEWLST+1,USER)
 D CHKEQ^XTMUNIT("LISTNFND",$P(RETURN(0),U,1),"LISTNFND expected")
 ;
 K:$D(RETURN) RETURN
 S %=$$REMUSR^GMPLAPI6(.RETURN,+NEWLST,"^USER^")
 D CHKEQ^XTMUNIT("INVPARAM",$P(RETURN(0),U,1),"INVPARAM GMPLUSER expected")
 ;
 K:$D(RETURN) RETURN
 S %=$$REMUSR^GMPLAPI6(.RETURN,+NEWLST,$P(^VA(200,0),U,3)+1)
 D CHKEQ^XTMUNIT("PROVNFND",$P(RETURN(0),U,1),"PROVNFND expected")
 ;
 K:$D(RETURN) RETURN
 S %=$$REMUSR^GMPLAPI6(.RETURN,+NEWLST,USER)
 D CHKEQ^XTMUNIT(^VA(200,USER,125),U,"INCORRECT USER ASSIGNED LIST DATA")
 ;
 Q
 ;
DEULST ;
 ;
 K:$D(RETURN) RETURN
 S %=$$DELLST^GMPLAPI1(.RETURN,"A")
 D CHKEQ^XTMUNIT("INVPARAM",$P(RETURN(0),U,1),"INVPARAM GMPLLST expected")
 ;
 K:$D(RETURN) RETURN
 S %=$$DELLST^GMPLAPI1(.RETURN,+NEWLST+1)
 D CHKEQ^XTMUNIT("LISTNFND",$P(RETURN(0),U,1),"LISTNFND expected")
 ;
 K:$D(RETURN) RETURN
 S %=$$DELLST^GMPLAPI1(.RETURN,+NEWLST)
 D CHKEQ^XTMUNIT("LISTUSED",$P(RETURN(0),U,1),"LISTUSED expected")
 Q
 ;
DELLST ;
 ;
 K:$D(RETURN) RETURN
 S:LSTCNT="" LSTCNT=0
 S %=$$DELLST^GMPLAPI1(.RETURN,+NEWLST)
 D CHKTF^XTMUNIT($D(RETURN(0))=0,"List deleted. No error expected.")
 D CHKEQ^XTMUNIT(LSTMAX,$P(^GMPL(125,0),U,3),"INCORRECT MOST RECENTLY IEN")
 D CHKEQ^XTMUNIT(LSTCNT,$P(^GMPL(125,0),U,4),"INCORRECT ENTRIES COUNT")
 D CHKTF^XTMUNIT($D(^GMPL(125,"B",LSTNAME))=0,"INCORRECT CROSS-REFERENCE")
 D CHKTF^XTMUNIT($D(^GMPL(125,+NEWLST))=0,"INCORRECT LIST IEN")
 Q
 ;
NEWCAT ;
 ;
 K:$D(RETURN) RETURN
 S NEWCAT=$$NEWCAT^GMPLAPI1(.RETURN,"")
 D CHKEQ^XTMUNIT(0,+NEWCAT,"Category already exists")
 D CHKEQ^XTMUNIT("INVPARAM",$P(RETURN(0),U,1),"INVPARAM GMPLGRP expected")
 ;
 K:$D(RETURN) RETURN
 S NEWCAT=$$NEWCAT^GMPLAPI1(.RETURN,"CA")
 D CHKEQ^XTMUNIT(0,+NEWCAT,"Category already exists")
 D CHKEQ^XTMUNIT("INVPARAM",$P(RETURN(0),U,1),"INVPARAM GMPLGRP expected (too short name)")
 ;
 K:$D(RETURN) RETURN
 N LNGNAME S LNGNAME="L"
 F I=1:1:30 S LNGNAME=LNGNAME_"L"
 S NEWCAT=$$NEWCAT^GMPLAPI1(.RETURN,LNGNAME)
 D CHKEQ^XTMUNIT(0,+NEWCAT,"Category already exists")
 D CHKEQ^XTMUNIT("INVPARAM",$P(RETURN(0),U,1),"INVPARAM GMPLGRP expected (too long name)")
 ;
 K:$D(RETURN) RETURN
 S NEWCAT=$$NEWCAT^GMPLAPI1(.RETURN,CATNAME)
 S NEWCAT=RETURN
 D CHKEQ^XTMUNIT(CATMAX+1,+NEWCAT,"INCORRECT CATEGORY IEN")
 D CHKTF^XTMUNIT($D(RETURN(0))=0,"No error expected")
 D CHKEQ^XTMUNIT(CATMAX+1,$P(^GMPL(125.11,0),U,3),"INCORRECT MOST RECENTLY IEN")
 D CHKEQ^XTMUNIT(CATCNT+1,$P(^GMPL(125.11,0),U,4),"INCORRECT ENTRIES COUNT")
 D CHKEQ^XTMUNIT("",^GMPL(125.11,"B",CATNAME,+NEWCAT),"INCORRECT CROSS-REFERENCE")
 D CHKEQ^XTMUNIT(CATNAME,^GMPL(125.11,+NEWCAT,0),"INCORRECT LIST DATA")
 ;
 K:$D(RETURN) RETURN
 S EXCAT=$$NEWCAT^GMPLAPI1(.RETURN,CATNAME)
 D CHKEQ^XTMUNIT(0,+EXCAT,"INCORRECT EXISTING LIST IEN")
 D CHKEQ^XTMUNIT("CTGEXIST",$P(RETURN(0),U,1),"CTGEXIST expected")
 Q
 ;
DEUCAT ;
 ;
 K:$D(RETURN) RETURN
 S CNT=$$DELCAT^GMPLAPI1(.RETURN,"")
 D CHKEQ^XTMUNIT("INVPARAM",$P(RETURN(0),U,1),"INVPARAM GMPLLST expected")
 ;
 K:$D(RETURN) RETURN
 S CNT=$$DELCAT^GMPLAPI1(.RETURN,+NEWCAT+1)
 D CHKEQ^XTMUNIT("CTGNFND",$P(RETURN(0),U,1),"CTGNFND expected")
 ;
 K:$D(RETURN) RETURN
 S CNT=$$DELCAT^GMPLAPI1(.RETURN,+NEWCAT)
 D CHKEQ^XTMUNIT("CATUSED",$P(RETURN(0),U,1),"CATUSED expected")
 Q
 ;
DELCAT ;
 ;
 K:$D(RETURN) RETURN
 S:CATCNT="" CATCNT=0
 S CNT=$$DELCAT^GMPLAPI1(.RETURN,+NEWCAT)
 D CHKTF^XTMUNIT($D(RETURN(0))=0,"Category deleted. No error expected.")
 D CHKEQ^XTMUNIT(CATMAX,$P(^GMPL(125.11,0),U,3),"INCORRECT MOST RECENTLY IEN")
 D CHKEQ^XTMUNIT(CATCNT,$P(^GMPL(125.11,0),U,4),"INCORRECT ENTRIES COUNT")
 D CHKTF^XTMUNIT($D(^GMPL(125.11,"B",CATNAME))=0,"INCORRECT CROSS-REFERENCE")
 D CHKTF^XTMUNIT($D(^GMPL(125.11,+NEWCAT))=0,"INCORRECT LIST IEN")
 Q
 ;
ADDCAT ;
 N TARGET K ^TMP("GMPLLST",$J)
 S ^TMP("GMPLLST",$J,0)=1
 S ^TMP("GMPLLST",$J,"0001N")="1"_U_+NEWCAT_U_CATNAME_U_"1"
 M TARGET=^TMP("GMPLLST",$J)
 K:$D(RETURN) RETURN
 S %=$$SAVLST^GMPLAPI1(.RETURN,"A",.TARGET)
 D CHKEQ^XTMUNIT("INVPARAM",$P(RETURN(0),U,1),"INVPARAM GMPLLST expected")
 ;
 K:$D(RETURN) RETURN
 S %=$$SAVLST^GMPLAPI1(.RETURN,+NEWLST+1,.TARGET)
 D CHKEQ^XTMUNIT("LISTNFND",$P(RETURN(0),U,1),"LISTNFND expected")
 ;
 K:$D(RETURN) RETURN
 S %=$$SAVLST^GMPLAPI1(.RETURN,+NEWLST,.TARGET)
 D CHKTF^XTMUNIT($D(RETURN(0))=0,"No error expected")
 D CHKEQ^XTMUNIT(LSTCMAX+1,$P(^GMPL(125.1,0),U,3),"INCORRECT MOST RECENTLY IEN")
 D CHKEQ^XTMUNIT(LSTCCNT+1,$P(^GMPL(125.1,0),U,4),"INCORRECT ENTRIES COUNT")
 D CHKEQ^XTMUNIT("",^GMPL(125.1,"B",+NEWLST,LSTCMAX+1),"INCORRECT CROSS-REFERENCE")
 S LSTC=+NEWLST_U_"1"_U_+NEWCAT_U_CATNAME_U_"1" ;list^seq^cat^cat name^show prob
 D CHKEQ^XTMUNIT(LSTC,^GMPL(125.1,LSTCMAX+1,0),"INCORRECT LIST DATA")
 ;
 K:$D(RETURN) RETURN
 S ^TMP("GMPLLST",$J,"45")="1"_U_+NEWCAT_U_CATNAME_U_"1"
 M TARGET=^TMP("GMPLLST",$J)
 S %=$$SAVLST^GMPLAPI1(.RETURN,+NEWLST,.TARGET)
 Q
 ;
REMCAT ;
 N TARGET K ^TMP("GMPLLST",$J)
 S ^TMP("GMPLLST",$J,0)=1
 S IND=$O(^GMPL(125.1,"B",+NEWLST,0))
 S ^TMP("GMPLLST",$J,IND)="@"
 M TARGET=^TMP("GMPLLST",$J)
 K:$D(RETURN) RETURN
 S %=$$SAVLST^GMPLAPI1(.RETURN,"A",.TARGET)
 D CHKEQ^XTMUNIT("INVPARAM",$P(RETURN(0),U,1),"INVPARAM GMPLLST expected")
 ;
 K:$D(RETURN) RETURN
 S %=$$SAVLST^GMPLAPI1(.RETURN,+NEWLST+1,.TARGET)
 D CHKEQ^XTMUNIT("LISTNFND",$P(RETURN(0),U,1),"LISTNFND expected")
 ;
 K:$D(RETURN) RETURN
 S %=$$SAVLST^GMPLAPI1(.RETURN,+NEWLST,.TARGET)
 D CHKTF^XTMUNIT($D(RETURN(0))=0,"No error expected")
 D CHKEQ^XTMUNIT(LSTCMAX,$P(^GMPL(125.1,0),U,3),"INCORRECT MOST RECENTLY IEN")
 D CHKEQ^XTMUNIT($S(LSTCCNT'="":LSTCCNT,1:0),$P(^GMPL(125.1,0),U,4),"INCORRECT ENTRIES COUNT")
 D CHKTF^XTMUNIT($D(^GMPL(125.1,"B",+NEWLST,+CATMAX+1))=0,"INCORRECT CROSS-REFERENCE")
 D CHKTF^XTMUNIT($D(^GMPL(125.1,+NEWCAT))=0,"INCORRECT LIST IEN")
 Q
 ;
ADDPRB ;
 N TARGET K ^TMP("GMPLLST",$J)
 S ^TMP("GMPLLST",$J,0)=1
 S ^TMP("GMPLLST",$J,"0001N")="1^33572^Diabetes Insipidus^253.5"
 M TARGET=^TMP("GMPLLST",$J)
 K:$D(RETURN) RETURN
 S %=$$SAVGRP^GMPLAPI1(.RETURN,"A",.TARGET)
 D CHKEQ^XTMUNIT("INVPARAM",$P(RETURN(0),U,1),"INVPARAM GMPLLST expected")
 ;
 K:$D(RETURN) RETURN
 S %=$$SAVGRP^GMPLAPI1(.RETURN,+NEWCAT+1,.TARGET)
 D CHKEQ^XTMUNIT("CTGNFND",$P(RETURN(0),U,1),"LISTNFND expected")
 ;
 K:$D(RETURN) RETURN
 S %=$$SAVGRP^GMPLAPI1(.RETURN,+NEWCAT,.TARGET)
 D CHKTF^XTMUNIT($D(RETURN(0))=0,"No error expected")
 D CHKEQ^XTMUNIT(CATCMAX+1,$P(^GMPL(125.12,0),U,3),"INCORRECT MOST RECENTLY IEN")
 D CHKEQ^XTMUNIT(CATCCNT+1,$P(^GMPL(125.12,0),U,4),"INCORRECT ENTRIES COUNT")
 D CHKEQ^XTMUNIT(1,$D(^GMPL(125.12,"B",+NEWCAT,CATCMAX+1)),"INCORRECT CROSS-REFERENCE")
 S CATC=+NEWCAT_U_"1"_U_"33572^Diabetes Insipidus^253.5" ;cat^seq^problem^text^code
 D CHKEQ^XTMUNIT(CATC,^GMPL(125.12,CATCMAX+1,0),"INCORRECT LIST DATA")
 Q
 ;
REMPRB ;
 N TARGET K ^TMP("GMPLLST",$J)
 S ^TMP("GMPLLST",$J,0)=1
 S IND=$O(^GMPL(125.12,"B",+NEWCAT,0))
 S ^TMP("GMPLLST",$J,IND)="@"
 M TARGET=^TMP("GMPLLST",$J)
 K:$D(RETURN) RETURN
 S %=$$SAVGRP^GMPLAPI1(.RETURN,"A",.TARGET)
 D CHKEQ^XTMUNIT("INVPARAM",$P(RETURN(0),U,1),"INVPARAM GMPLLST expected")
 ;
 K:$D(RETURN) RETURN
 S %=$$SAVGRP^GMPLAPI1(.RETURN,+NEWCAT+1,.TARGET)
 D CHKEQ^XTMUNIT("CTGNFND",$P(RETURN(0),U,1),"LISTNFND expected")
 ;
 K:$D(RETURN) RETURN
 S %=$$SAVGRP^GMPLAPI1(.RETURN,+NEWCAT,.TARGET)
 D CHKTF^XTMUNIT($D(RETURN(0))=0,"No error expected")
 D CHKEQ^XTMUNIT(CATCMAX,$P(^GMPL(125.12,0),U,3),"INCORRECT MOST RECENTLY IEN")
 D CHKEQ^XTMUNIT(+CATCCNT,$P(^GMPL(125.12,0),U,4),"INCORRECT ENTRIES COUNT")
 D CHKTF^XTMUNIT($D(^GMPL(125.12,"B",+NEWCAT))=0,"INCORRECT CROSS-REFERENCE")
 D CHKTF^XTMUNIT($D(^GMPL(125.12,+CATCMAX+1))=0,"INCORRECT LIST IEN")
 Q
 ;
GETCAT ;
 Q
 ;
GETLST ;
 Q
 ;
XTENT ;
 ;;NEWLST;Tests list creation
 ;;ASSUSR;Tests user assigned list
 ;;NEWCAT;Tests category creation
 ;;ADDCAT;Add category to list
 ;;ADDPRB;Add problems to category
 ;;GETCAT;Get category
 ;;GETLST;Get list
 ;;REMPRB;Remove problems from category
 ;;DEUCAT;Used category cannot be deleted, depends on ADDCAT
 ;;REMCAT;Remove category from list
 ;;DELCAT;Tests physical removal of category, depends on REMCAT
 ;;DEULST;Used list cannot be deleted, depends on ASSUSR
 ;;REMUSR;Remove assigned list from user
 ;;DELLST;Tests physical removal of list, depends on REMUSR
 Q
