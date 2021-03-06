VERSION 5.00
Begin VB.Form Main 
   Caption         =   "Main"
   ClientHeight    =   4290
   ClientLeft      =   60
   ClientTop       =   450
   ClientWidth     =   6780
   LinkTopic       =   "Form1"
   ScaleHeight     =   4290
   ScaleWidth      =   6780
   StartUpPosition =   3  'Windows Default
   Begin VB.CommandButton btnTransfer 
      Caption         =   "&Start Transfer"
      Height          =   1215
      Left            =   1560
      TabIndex        =   0
      Top             =   1920
      Width           =   2895
   End
   Begin VB.Image Image1 
      Height          =   825
      Left            =   120
      Picture         =   "Main.frx":0000
      Top             =   120
      Width           =   1530
   End
   Begin VB.Label Label1 
      Caption         =   "Click ""Start Transfer"" to Begin"
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   13.5
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   735
      Left            =   1560
      TabIndex        =   3
      Top             =   960
      Width           =   4215
   End
   Begin VB.Label Label 
      Caption         =   "PoUpdate: Busche Indiana"
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   13.5
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   495
      Left            =   1800
      TabIndex        =   2
      Top             =   120
      Width           =   3855
   End
   Begin VB.Label lblStatus 
      Caption         =   "Not Started"
      ForeColor       =   &H000080FF&
      Height          =   495
      Left            =   720
      TabIndex        =   1
      Top             =   3480
      Width           =   4935
   End
End
Attribute VB_Name = "Main"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Private Sub btnTransfer_Click()
  Main
End Sub
'**********************************************************************
'  Visual Basic ActiveX Script
'************************************************************************

Function Main()
On Error GoTo ErrorHandler
' These values were copied from the ADOVBS.INC file.
'---- CursorTypeEnum Values ----
Const adOpenForwardOnly = 0
Const adOpenKeyset = 1
Const adOpenDynamic = 2
Const adOpenStatic = 3

'---- CommandTypeEnum Values ----
Const adCmdUnknown = &H8
Const adCmdText = &H1
Const adCmdTable = &H2
Const adCmdStoredProc = &H4


 Dim SourceConn
 Dim SourceRecordset
 Dim ItemSourceRecordset
 Dim DestinationConn
 Dim DestinationRecordset
 Dim ItemDestinationRecordset
 Dim CompanySourceRecordset
 Dim GetNextPORecordSet
 Dim GetVendorNumber
 Dim GetVendorTerms
 Dim CurrentPO
 Dim NextPO
 Dim NextItemNumber
 Dim ReadyForImport
 Dim Terms
 Dim M2MVendor
 Dim PONumber As String
 
 Set SourceConn = CreateObject("ADODB.Connection")
 Set DestinationConn = CreateObject("ADODB.Connection")
 Set GetNextPORecordSet = CreateObject("ADODB.Recordset")
 Set SourceRecordset = CreateObject("ADODB.Recordset")
 Set DestinationRecordset = CreateObject("ADODB.Recordset")
 Set CompanySourceRecordset = CreateObject("ADODB.Recordset")
 Set ItemSourceRecordset = CreateObject("ADODB.Recordset")
 Set ItemDestinationRecordset = CreateObject("ADODB.Recordset")
 Set GetVendorNumber = CreateObject("ADODB.Recordset")
 Set GetVendorTerms = CreateObject("ADODB.Recordset")
    
 DestinationRecordset.CursorType = adOpenKeyset
 DestinationRecordset.CursorLocation = 3
 DestinationRecordset.LockType = 2
 
 CompanySourceRecordset.CursorType = adOpenDynamic
 CompanySourceRecordset.CursorLocation = 3
 CompanySourceRecordset.LockType = 3
 
 
 SourceRecordset.LockType = 2
 SourceRecordset.CursorLocation = 3
 SourceRecordset.CursorType = adOpenDynamic
 
 
 ItemDestinationRecordset.CursorType = adOpenDynamic
 ItemDestinationRecordset.CursorLocation = 3
 ItemDestinationRecordset.LockType = 2
 
 GetNextPORecordSet.LockType = 2
 GetNextPORecordSet.CursorLocation = 3
 GetNextPORecordSet.CursorType = adOpenDynamic
 
 ItemSourceRecordset.LockType = 2
 ItemSourceRecordset.CursorLocation = 3
 ItemSourceRecordset.CursorType = adOpenDynamic
 
 GetVendorNumber.LockType = 3
 GetVendorNumber.CursorLocation = 3
 GetVendorNumber.CursorType = adOpenDynamic
 
 GetVendorTerms.LockType = 3
 GetVendorTerms.CursorLocation = 3
 GetVendorTerms.CursorType = adOpenDynamic

 lblStatus.Caption = "PO Update has started"

 '*****************Select databases for Alabama or Indiana**********************

    SourceConn.Open = "Provider=SQLOLEDB.1;Data Source=Busche-SQL; Initial Catalog=Cribmaster;user id = 'sa';password='buschecnc1'"
    DestinationConn.Open = "Provider=SQLOLEDB.1;Data Source=Busche-SQL-1; Initial Catalog=m2mdata01;user id = 'sa';password='buschecnc1'"
    
    '**********PO Status Number 3 = Requested
    SourceRecordset.Open "SELECT * FROM [PO]  WHERE [PO].POSTATUSNO = 3 and [PO].SITEID <> '90'", SourceConn, adOpenKeyset
    

 While Not SourceRecordset.EOF

'*******************CHECK IF ALL PO CATEGORIES HAVE BEEN SELECTED FOR EACH PO ITEM & THE RECORDS ARE NOT LOCKED****************
  ItemSourceRecordset.Open "SELECT * FROM PODETAIL WHERE PONUMBER = " + CStr(SourceRecordset.Fields("PONUMBER")), SourceConn, adOpenKeyset
  While Not ItemSourceRecordset.EOF
      If IsNull(ItemSourceRecordset.Fields("UDF_POCATEGORY")) Then
        Err.Description = "Error: No Indiana PO Category for Po# " + CStr(SourceRecordset.Fields("PONUMBER")) + " Item# " + CStr(ItemSourceRecordset.Fields("Item"))
        GoTo ErrorHandler
    End If
    ItemSourceRecordset.Movenext
  Wend
  ItemSourceRecordset.Movefirst
'*******************CHECK IF PO HAS A VALID VENDOR IN CRIBMASTER****************
  PONumber = SourceRecordset.Fields("PONumber")
  GetVendorNumber.Open "SELECT * FROM [VENDOR]  WHERE VENDORNUMBER= '" + SourceRecordset.Fields("Vendor") + "'", SourceConn, adOpenKeyset
  If (GetVendorNumber.RecordCount < 1) Then
   Err.Description = "Error: No CribMaster Vendor# " + CStr(SourceRecordset.Fields("Vendor")) + " found for PO# " + PONumber
   GoTo ErrorHandler
  End If
  
  '* M2m Vendor Number link field
    M2MVendor = GetVendorNumber.Fields("UDFM2MVENDORNUMBER")
  If (IsNull(M2MVendor)) Then
    Err.Description = "Error: No Indiana M2M Vendor found for Cribmaster Vendor# " + CStr(SourceRecordset.Fields("Vendor")) + " found for PO# " + PONumber
    GoTo ErrorHandler
  End If
  
'*******************CHECK IF CRIBMASTER VENDOR HAS GOOD LINK TO M2M VENDOR***************
'*apvend links to syaddr with the vendor number but syaddr also has SLCDPM vendors
  CompanySourceRecordset.Open "SELECT * FROM [APVEND],[SYADDR] WHERE [APVEND].FVENDNO = [SYADDR].FCALIASKEY AND fvendno = '" + M2MVendor + "' AND [SYADDR].FCALIAS = 'APVEND'", DestinationConn
'  CompanySourceRecordset.Open "SELECT * FROM [APVEND],[SYADDR] WHERE [APVEND].FVENDNO = [SYADDR].FCALIASKEY AND fvendno = '" + GetVendorNumber.Fields("UDFM2MVENDORNUMBER") + "' AND [SYADDR].FCALIAS = 'APVEND'", DestinationConn
  If CompanySourceRecordset.RecordCount < 1 Then
     Err.Description = "Error: Indiana Vendor #" + CStr(GetVendorNumber.Fields("UDFM2MVENDORNUMBER")) + " not in M2M for PO# " + CStr(SourceRecordset.Fields("PONumber"))
     GoTo ErrorHandler
  End If
'*******************GET STANDARD TERMS FROM M2M VENDOOR PAGE***************
  
  GetVendorTerms.Open "SELECT FCTERMS FROM [APVEND]  WHERE FVENDNO= '" + GetVendorNumber.Fields("UDFM2MVENDORNUMBER") + "'", DestinationConn, adOpenKeyset
  If GetVendorTerms.RecordCount < 1 Then
    Err.Description = "Error: No standard terms for M2M vendor# " + GetVendorNumber.Fields("UDFM2MVENDORNUMBER") + " for PO# " + SourceRecordset.Fields("PONumber")
    GoTo ErrorHandler
  End If
  
  Dim SkipPO As Boolean
  SkipPO = False
  '********************Update PoStatusNo field to Ordered if blanket po and do not create a master PO record
  If SourceRecordset.Fields("BLANKETPO") <> "" Then
     SourceRecordset.Fields("POStatusNo") = 0
     SourceRecordset.Update
     SkipPO = True
  End If
    
  If Not SkipPO Then
    '*****************************CREATE MASTER PO RECORD *****************************
   Terms = GetVendorTerms.Fields("FCTERMS")
   ' Determine the next M2M Po Number
   GetNextPORecordSet.Open "SELECT * FROM SYSEQU WHERE fcclass = 'POMAST.STD'", DestinationConn, adOpenKeyset
   CurrentPO = CStr(CLng(GetNextPORecordSet.Fields("fcnumber")))
   NextPO = CStr(CLng(GetNextPORecordSet.Fields("fcnumber")) + 1)
   While Len(NextPO) < 6
    NextPO = "0" + NextPO
   Wend
   GetNextPORecordSet.Fields("fcnumber") = NextPO
   GetNextPORecordSet.Update
   GetNextPORecordSet.Close
   While Len(CurrentPO) < 6
    CurrentPO = "0" + CurrentPO
   Wend
   DestinationRecordset.Open "[POMast]", DestinationConn, adOpenKeyset, adCmdTable
   DestinationRecordset.AddNew
   DestinationRecordset.Fields("fpono") = CurrentPO
   DestinationRecordset.Fields("fcompany") = CompanySourceRecordset.Fields("fccompany")
   DestinationRecordset.Fields("fcshipto") = "SELF"
   DestinationRecordset.Fields("forddate") = FormatDateTime(SourceRecordset.Fields("POdate"), 2)
   DestinationRecordset.Fields("fstatus") = "OPEN"
   'Hartselle / Indiana diff
   DestinationRecordset.Fields("fvendno") = GetVendorNumber.Fields("UDFM2MVENDORNUMBER")
   DestinationRecordset.Fields("fbuyer") = "CM"
   DestinationRecordset.Fields("fchangeby") = "CM"
   DestinationRecordset.Fields("fshipvia") = "UPS-OURS"
   DestinationRecordset.Fields("fcngdate") = FormatDateTime(SourceRecordset.Fields("POdate"), 2)
   DestinationRecordset.Fields("fcreate") = FormatDateTime(SourceRecordset.Fields("POdate"), 2)
   DestinationRecordset.Fields("ffob") = "OUR PLANT"
   DestinationRecordset.Fields("fmethod") = "1"
   DestinationRecordset.Fields("foldstatus") = "STARTED"
   DestinationRecordset.Fields("fordrevdt") = #1/1/1900#
   DestinationRecordset.Fields("fordtot") = 0
   DestinationRecordset.Fields("fpayterm") = Terms
   DestinationRecordset.Fields("fpaytype") = "3"
   DestinationRecordset.Fields("fporev") = "00"
   DestinationRecordset.Fields("fprint") = "N"
   DestinationRecordset.Fields("freqdate") = #1/1/1900#
   DestinationRecordset.Fields("freqsdt") = FormatDateTime(SourceRecordset.Fields("POdate"), 2)
   DestinationRecordset.Fields("freqsno") = ""
   DestinationRecordset.Fields("frevtot") = 0
   DestinationRecordset.Fields("fsalestax") = 0
   DestinationRecordset.Fields("ftax") = "N"
   DestinationRecordset.Fields("fcsnaddrke") = "0001"
   DestinationRecordset.Fields("fnnextitem") = 1
   DestinationRecordset.Fields("fautoclose") = "Y"
   DestinationRecordset.Fields("fnusrqty1") = 0
   DestinationRecordset.Fields("fnusrcur1") = 0
   DestinationRecordset.Fields("fdusrdate1") = #1/1/1900#
   DestinationRecordset.Fields("fcfactor") = 0
   DestinationRecordset.Fields("fdcurdate") = #1/1/1900#
   DestinationRecordset.Fields("fdeurodate") = #1/1/1900#
   DestinationRecordset.Fields("feurofctr") = 0
   DestinationRecordset.Fields("fctype") = "O"
   DestinationRecordset.Fields("fmsnstreet") = CompanySourceRecordset.Fields("fmstreet")
   DestinationRecordset.Fields("fpoclosing") = "Please reference our purchase order number on all correspondence.  " _
   & "Notification of changes regarding quantities to be shipped and changes in the delivery schedule are required." + _
   Chr(13) + Chr(13) + _
   "PO APPROVALS:" + Chr(13) + Chr(13) + _
   "Requr. _______________________________________" + Chr(13) + _
   "Dept. Head ___________________________________" + Chr(13) + Chr(13) + _
   "G.M. Only: All Items Over $500.00" + Chr(13) + _
   "G.M ________________________________________" + Chr(13) + _
   "VP/Group Controller. Only: All Assests/CER and ER Over $10,000.00" + Chr(13) + _
   "VP/Group Controller _____________________________________" + Chr(13) + _
   "Pres. Only: All Assets/CER/ER and/or PO�s Over $10,000.00" + Chr(13) + _
   "President _____________________________________"
   DestinationRecordset.Fields("fndbrmod") = 0

    DestinationRecordset.Fields("fcsncity") = CompanySourceRecordset.Fields("fccity")
    DestinationRecordset.Fields("fcsnstate") = CompanySourceRecordset.Fields("fcstate")
    DestinationRecordset.Fields("fcsnzip") = CompanySourceRecordset.Fields("fczip")
    DestinationRecordset.Fields("fcsncountr") = CompanySourceRecordset.Fields("fccountry")
    DestinationRecordset.Fields("fcsnphone") = CompanySourceRecordset.Fields("fcphone")
    DestinationRecordset.Fields("fcsnfax") = CompanySourceRecordset.Fields("fcfax")
   
   
    DestinationRecordset.Fields("fcshcompan") = "BUSCHE INDIANA"
    DestinationRecordset.Fields("fcshcity") = "ALBION"
    DestinationRecordset.Fields("fcshstate") = "IN"
    DestinationRecordset.Fields("fcshzip") = "46701"
    DestinationRecordset.Fields("fcshcountr") = "USA"
    DestinationRecordset.Fields("fcshphone") = "2606367030"
    DestinationRecordset.Fields("fcshfax") = "2603637031"
    DestinationRecordset.Fields("fmshstreet") = "1563 E. State Road 8"

   DestinationRecordset.Update
   SourceRecordset.Fields("VendorPO") = CurrentPO
   SourceRecordset.Fields("POStatusNo") = 0
   SourceRecordset.Update
    
    NextItem = 0
   ItemDestinationRecordset.Open "[POItem]", DestinationConn, adOpenKeyset, adCmdTable
   While Not ItemSourceRecordset.EOF
    NextItem = NextItem + 1
    ItemDestinationRecordset.AddNew
    ItemDestinationRecordset.Fields("fpono") = CurrentPO
    ItemDestinationRecordset.Fields("fpartno") = Left(ItemSourceRecordset.Fields("ItemDescription"), 25)
    ItemDestinationRecordset.Fields("frev") = "NS"
    ItemDestinationRecordset.Fields("fmeasure") = "EA"
    ItemDestinationRecordset.Fields("frev") = "NS"
    If NextItem > 99 Then
     ItemDestinationRecordset.Fields("fitemno") = Trim(CStr(NextItem))
    ElseIf NextItem > 9 Then
     ItemDestinationRecordset.Fields("fitemno") = " " + Trim(CStr(NextItem))
    Else
     ItemDestinationRecordset.Fields("fitemno") = "  " + Trim(CStr(NextItem))
    End If
    ItemDestinationRecordset.Fields("frelsno") = "  0"
   'Hartselle / Indiana diff
    ItemDestinationRecordset.Fields("fcategory") = ItemSourceRecordset.Fields("UDF_POCATEGORY")
    ItemDestinationRecordset.Fields("fjoopno") = 0
    ItemDestinationRecordset.Fields("flstcost") = ItemSourceRecordset.Fields("Cost")
    ItemDestinationRecordset.Fields("fstdcost") = ItemSourceRecordset.Fields("Cost")
    ItemDestinationRecordset.Fields("fleadtime") = 0
    If IsNull(ItemSourceRecordset.Fields("RequiredDate")) Then
     ItemDestinationRecordset.Fields("forgpdate") = FormatDateTime(Now(), 2)
     ItemDestinationRecordset.Fields("flstpdate") = FormatDateTime(Now(), 2)
    Else
     ItemDestinationRecordset.Fields("forgpdate") = FormatDateTime(ItemSourceRecordset.Fields("RequiredDate"), 2)
     ItemDestinationRecordset.Fields("flstpdate") = FormatDateTime(ItemSourceRecordset.Fields("RequiredDate"), 2)
    End If
    ItemDestinationRecordset.Fields("fmultirls") = "N"
    ItemDestinationRecordset.Fields("fnextrels") = 0
    ItemDestinationRecordset.Fields("fnqtydm") = 0
    ItemDestinationRecordset.Fields("freqdate") = #1/1/1900#
    ItemDestinationRecordset.Fields("fretqty") = 0
    ItemDestinationRecordset.Fields("fordqty") = ItemSourceRecordset.Fields("Quantity")
    ItemDestinationRecordset.Fields("fqtyutol") = 0
    ItemDestinationRecordset.Fields("fqtyltol") = 0
    ItemDestinationRecordset.Fields("fbkordqty") = 0
    ItemDestinationRecordset.Fields("flstsdate") = #1/1/1900#
    ItemDestinationRecordset.Fields("frcpdate") = #1/1/1900#
    ItemDestinationRecordset.Fields("frcpqty") = 0
    ItemDestinationRecordset.Fields("fshpqty") = 0
    ItemDestinationRecordset.Fields("finvqty") = 0
    ItemDestinationRecordset.Fields("fdiscount") = 0
    ItemDestinationRecordset.Fields("fstandard") = 0
    ItemDestinationRecordset.Fields("ftax") = "N"
    ItemDestinationRecordset.Fields("fsalestax") = 0
    ItemDestinationRecordset.Fields("flcost") = ItemSourceRecordset.Fields("Cost")
    ItemDestinationRecordset.Fields("fucost") = ItemSourceRecordset.Fields("Cost")
    ItemDestinationRecordset.Fields("fprintmemo") = "Y"
    ItemDestinationRecordset.Fields("fvlstcost") = ItemSourceRecordset.Fields("Cost")
    ItemDestinationRecordset.Fields("fvleadtime") = 0
    ItemDestinationRecordset.Fields("fvmeasure") = "EA"
    If IsNull(ItemSourceRecordset.Fields("ITEM")) Then
     ItemDestinationRecordset.Fields("fvptdes") = " "
    Else
     ItemDestinationRecordset.Fields("fvptdes") = ItemSourceRecordset.Fields("ITEM")
    End If
    ItemDestinationRecordset.Fields("fvordqty") = ItemSourceRecordset.Fields("Quantity")
    ItemDestinationRecordset.Fields("fvconvfact") = 1
    ItemDestinationRecordset.Fields("fvucost") = ItemSourceRecordset.Fields("Cost")
    ItemDestinationRecordset.Fields("fqtyshipr") = 0
    ItemDestinationRecordset.Fields("fdateship") = #1/1/1900#
    ItemDestinationRecordset.Fields("fnorgucost") = 0
    ItemDestinationRecordset.Fields("fnorgeurcost") = 0
    ItemDestinationRecordset.Fields("fnorgtxncost") = 0
    ItemDestinationRecordset.Fields("futxncost") = 0
    ItemDestinationRecordset.Fields("fvueurocost") = 0
    ItemDestinationRecordset.Fields("fvutxncost") = 0
    ItemDestinationRecordset.Fields("fljrdif") = 0
    ItemDestinationRecordset.Fields("fucostonly") = ItemSourceRecordset.Fields("Cost")
    ItemDestinationRecordset.Fields("futxncston") = 0
    ItemDestinationRecordset.Fields("fueurcston") = 0
    If IsNull(ItemSourceRecordset.Fields("Comments")) Then
     ItemDestinationRecordset.Fields("fcomments") = " "
    Else
     ItemDestinationRecordset.Fields("fcomments") = ItemSourceRecordset.Fields("Comments")
    End If
    If IsNull(ItemSourceRecordset.Fields("Description2")) Then
     ItemDestinationRecordset.Fields("fdescript") = " "
    Else
     ItemDestinationRecordset.Fields("fdescript") = ItemSourceRecordset.Fields("Description2")
    End If
    ItemDestinationRecordset.Fields("fac") = "Default"
    ItemDestinationRecordset.Fields("fndbrmod") = 0
    ItemDestinationRecordset.Update
    ItemSourceRecordset.Fields("VendorPONumber") = CurrentPO
    ItemSourceRecordset.Update
    ItemSourceRecordset.Movenext
   Wend
   DestinationRecordset.Fields("fnnextitem") = NextItem
   DestinationRecordset.Update
   DestinationRecordset.Close
   ItemDestinationRecordset.Close
   If GetNextPORecordSet.State = 1 Then
    GetNextPORecordSet.Close
   End If
  End If  ' Skip PO Check
  GetVendorNumber.Close
  GetVendorTerms.Close
  CompanySourceRecordset.Close
  ItemSourceRecordset.Close
  SourceRecordset.Movenext
 Wend  ' Next CribMaster PO record
 If ItemDestinationRecordset.State = 1 Then
  ItemDestinationRecordset.Close
 End If
 If DestinationRecordset.State = 1 Then
  DestinationRecordset.Close
 End If
 If GetNextPORecordSet.State = 1 Then
  GetNextPORecordSet.Close
 End If
 If CompanySourceRecordset.State = 1 Then
  CompanySourceRecordset.Close
 End If
 If GetVendorNumber.State = 1 Then
  GetVendorNumber.Close
 End If
 If ItemSourceRecordset.State = 1 Then
  ItemSourceRecordset.Close
 End If
 If CompanySourceRecordset.State = 1 Then
  CompanySourceRecordset.Close
 End If
 If SourceRecordset.State = 1 Then
  SourceRecordset.Close
 End If
 SourceConn.Close
 DestinationConn.Close
 
 Main = DTSTaskExecResult_Success
 lblStatus.Caption = "PO Update has finished successfully"
 Exit Function


ErrorHandler:
 lblStatus.Caption = "PO Update failed"
 MsgBox (Err.Description)
 If ItemDestinationRecordset.State = 1 Then
  ItemDestinationRecordset.Close
 End If
 If DestinationRecordset.State = 1 Then
  DestinationRecordset.Close
 End If
 If GetNextPORecordSet.State = 1 Then
  GetNextPORecordSet.Close
 End If
 If CompanySourceRecordset.State = 1 Then
  CompanySourceRecordset.Close
 End If
 If GetVendorNumber.State = 1 Then
  GetVendorNumber.Close
 End If
 If ItemSourceRecordset.State = 1 Then
  ItemSourceRecordset.Close
 End If
 If CompanySourceRecordset.State = 1 Then
  CompanySourceRecordset.Close
 End If
 If SourceRecordset.State = 1 Then
  SourceRecordset.Close
 End If
 SourceConn.Close
 DestinationConn.Close
 
End Function






