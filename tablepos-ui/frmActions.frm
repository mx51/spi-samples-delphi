VERSION 5.00
Begin VB.Form frmActions 
   BorderStyle     =   3  'Fixed Dialog
   Caption         =   "Actions"
   ClientHeight    =   6960
   ClientLeft      =   5850
   ClientTop       =   1965
   ClientWidth     =   6705
   BeginProperty Font 
      Name            =   "Calibri"
      Size            =   12
      Charset         =   0
      Weight          =   400
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   6960
   ScaleWidth      =   6705
   ShowInTaskbar   =   0   'False
   Begin VB.Frame frameActions 
      Height          =   1815
      Left            =   120
      TabIndex        =   1
      Top             =   5040
      Width           =   6495
      Begin VB.TextBox txtAmount 
         BeginProperty DataFormat 
            Type            =   1
            Format          =   "0"
            HaveTrueFalseNull=   0
            FirstDayOfWeek  =   0
            FirstWeekOfYear =   0
            LCID            =   3081
            SubFormatType   =   1
         EndProperty
         Height          =   405
         Left            =   2040
         TabIndex        =   11
         Top             =   840
         Visible         =   0   'False
         Width           =   2055
      End
      Begin VB.CommandButton btnAction3 
         Caption         =   "Command3"
         Height          =   405
         Left            =   4200
         TabIndex        =   10
         Top             =   1320
         Visible         =   0   'False
         Width           =   2175
      End
      Begin VB.CommandButton btnAction2 
         Caption         =   "Command2"
         Height          =   405
         Left            =   4200
         TabIndex        =   9
         Top             =   840
         Visible         =   0   'False
         Width           =   2175
      End
      Begin VB.CommandButton btnAction1 
         Caption         =   "Command1"
         Height          =   405
         Left            =   4200
         TabIndex        =   8
         Top             =   360
         Visible         =   0   'False
         Width           =   2175
      End
      Begin VB.TextBox txtTableId 
         BeginProperty DataFormat 
            Type            =   1
            Format          =   "0"
            HaveTrueFalseNull=   0
            FirstDayOfWeek  =   0
            FirstWeekOfYear =   0
            LCID            =   3081
            SubFormatType   =   1
         EndProperty
         Height          =   405
         Left            =   2040
         TabIndex        =   6
         Top             =   360
         Visible         =   0   'False
         Width           =   2055
      End
      Begin VB.Label lblTableId 
         Caption         =   "Table Id:"
         Height          =   405
         Left            =   120
         TabIndex        =   12
         Top             =   360
         Visible         =   0   'False
         Width           =   1695
      End
      Begin VB.Label lblAmount 
         Caption         =   "Amount (cents):"
         Height          =   405
         Left            =   120
         TabIndex        =   7
         Top             =   840
         Visible         =   0   'False
         Width           =   1575
      End
   End
   Begin VB.Frame frameFlow 
      Height          =   5055
      Left            =   120
      TabIndex        =   0
      Top             =   0
      Width           =   6495
      Begin VB.ListBox listFlow 
         BeginProperty Font 
            Name            =   "Calibri"
            Size            =   9.75
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   3210
         ItemData        =   "frmActions.frx":0000
         Left            =   120
         List            =   "frmActions.frx":0002
         TabIndex        =   5
         Top             =   1560
         Width           =   6255
      End
      Begin VB.Label lblFlowMessage 
         BeginProperty Font 
            Name            =   "Calibri"
            Size            =   14.25
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   735
         Left            =   240
         TabIndex        =   4
         Top             =   720
         Width           =   6135
         WordWrap        =   -1  'True
      End
      Begin VB.Label lblFlowStatus 
         Caption         =   "Idle"
         BeginProperty Font 
            Name            =   "Calibri"
            Size            =   15.75
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         ForeColor       =   &H000000FF&
         Height          =   375
         Left            =   3360
         TabIndex        =   3
         Top             =   240
         Width           =   2175
      End
      Begin VB.Label lblFlow 
         Alignment       =   1  'Right Justify
         Caption         =   "Flow:"
         BeginProperty Font 
            Name            =   "Calibri"
            Size            =   15.75
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   375
         Left            =   1920
         TabIndex        =   2
         Top             =   240
         Width           =   1335
      End
   End
End
Attribute VB_Name = "frmActions"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Declare Function RemoveMenu Lib "user32" ( _
ByVal hMenu As Long, _
ByVal nPosition As Long, _
ByVal wFlags As Long) As Long

Private Declare Function GetSystemMenu Lib "user32" ( _
ByVal hwnd As Long, _
ByVal bRevert As Long) As Long

Private Declare Function GetMenuItemCount Lib "user32.dll" ( _
ByVal hMenu As Long) As Long

Private Const MF_BYPOSITION = &H400&

Private Sub btnAction1_Click()
    If btnAction1.Caption = "Confirm Code" Then
        spi.PairingConfirmCode
    ElseIf btnAction1.Caption = "Cancel Pairing" Then
        spi.PairingCancel
        frmMain.lblStatus.BackColor = RGB(255, 0, 0)
    ElseIf btnAction1.Caption = "Cancel" Then
        spi.CancelTransaction
    ElseIf btnAction1.Caption = "OK" Then
        spi.AckFlowEndedAndBackToIdle
        listFlow.Clear
        lblFlowMessage.Caption = "Select from the options below"
        PrintStatusAndActions
        frmMain.Enabled = True
        frmMain.btnPair.Enabled = True
        frmMain.txtPosId.Enabled = True
        frmMain.txtEftposAddress.Enabled = True
        Hide
    ElseIf btnAction1.Caption = "Accept Signature" Then
        spi.AcceptSignature (True)
    ElseIf btnAction1.Caption = "Retry" Then
        spi.AckFlowEndedAndBackToIdle
        listFlow.Clear
        If spi.CurrentTxFlowState.Type = TransactionType_Purchase Then
            DoPurchase
        ElseIf spi.CurrentTxFlowState.Type = TransactionType_Refund Then
            DoRefund
        Else
            lblFlowStatus.Caption = "Retry by selecting from the options below"
            PrintStatusAndActions
        End If
    ElseIf btnAction1.Caption = "Purchase" Then
        DoPurchase
    ElseIf btnAction1.Caption = "Refund" Then
        DoRefund
    ElseIf btnAction1.Caption = "Open" Then
        DoOpenTable
    ElseIf btnAction1.Caption = "Close" Then
        DoCloseTable
    ElseIf btnAction1.Caption = "Add" Then
        DoAddToTable
    ElseIf btnAction1.Caption = "Print Bill" Then
        DoPrintBill
    End If
End Sub

Private Sub btnAction2_Click()
    If btnAction2.Caption = "Cancel Pairing" Then
        spi.PairingCancel
        frmMain.lblStatus.BackColor = RGB(255, 0, 0)
    ElseIf btnAction2.Caption = "Decline Signature" Then
        spi.AcceptSignature (False)
    ElseIf btnAction2.Caption = "Cancel" Then
        spi.AckFlowEndedAndBackToIdle
        listFlow.Clear
        PrintStatusAndActions
        frmMain.Enabled = True
        Hide
    End If
End Sub

Private Sub btnAction3_Click()
    If btnAction3.Caption = "Cancel" Then
        spi.CancelTransaction
    End If
End Sub

Private Sub Form_Load()
    'REMOVE THE SYSTEM MENU ITEM - CLOSE
    RemoveMenu GetSystemMenu(Me.hwnd, 0), GetMenuItemCount(GetSystemMenu(Me.hwnd, 0)) - 1, MF_BYPOSITION
    'REMOVE THE MENU SEPARATOR
    RemoveMenu GetSystemMenu(Me.hwnd, 0), GetMenuItemCount(GetSystemMenu(Me.hwnd, 0)) - 1, MF_BYPOSITION
End Sub

Private Sub DoPurchase()
    Dim purchase As SPIClient.InitiateTxResult
    
    Set purchase = New SPIClient.InitiateTxResult
    Set purchase = spi.InitiatePurchaseTxV2("purchase-" + Format(Now, "o"), CInt(txtAmount.Text), 0, 0, False)
    
    If purchase.Initiated Then
        listFlow.AddItem "# Purchase Initiated. Will be updated with Progress."
    Else
        listFlow.AddItem "# Could not initiate purchase: " + purchase.Message + ". Please Retry."
    End If
End Sub

Private Sub DoRefund()
    Dim refund As SPIClient.InitiateTxResult
    
    Set refund = New SPIClient.InitiateTxResult
    Set refund = spi.InitiateRefundTx("rfnd-" + Format(Now, "o"), CInt(txtAmount.Text))
    
    If refund.Initiated Then
        listFlow.AddItem "# Refund Initiated. Will be updated with Progress."
    Else
        listFlow.AddItem "# Could not initiate refund: " + refund.Message + ". Please Retry."
    End If
End Sub

Private Sub DoOpenTable()
    Dim newBill As New bill
    Dim bill As New bill
    Dim billId, TableId As String
    
    TableId = txtTableId.Text
    
    If (tableToBillMappingDict.Exists(TableId)) Then
        billId = tableToBillMappingDict.Item(TableId)
        Set bill = billsStoreDict.Item(billId)
        listFlow.AddItem "Table Already Open: " + BillToString(bill)
    Else
        newBill.billId = comWrapper.NewBillId
        newBill.TableId = txtTableId.Text
        With billsStoreDict
            .Add newBill.billId, newBill
        End With
        With tableToBillMappingDict
            .Add newBill.TableId, newBill.billId
        End With
        listFlow.AddItem "Opened: " + BillToString(newBill)
    End If
    
    frmActions.Show
    btnAction1.Visible = True
    btnAction1.Caption = "OK"
    btnAction2.Visible = False
    btnAction3.Visible = False
    lblAmount.Visible = False
    txtAmount.Visible = False
    lblTableId.Visible = False
    txtTableId.Visible = False
    frmMain.Enabled = False
End Sub

Private Sub DoAddToTable()
    Dim amountCents As Integer
    Dim billId, TableId As String
    Dim bill As New bill
    
    TableId = txtTableId.Text
    amountCents = CInt(txtAmount.Text)
    
    If (Not tableToBillMappingDict.Exists(TableId)) Then
        listFlow.AddItem "Table Not Open: "
    Else
        billId = tableToBillMappingDict.Item(TableId)
        Set bill = billsStoreDict.Item(billId)
        bill.TotalAmount = bill.TotalAmount + amountCents
        bill.OutstandingAmount = bill.OutstandingAmount + amountCents
        Set billsStoreDict.Item(billId) = bill
        listFlow.AddItem "Updated: " + BillToString(bill)
    End If
    
    frmActions.Show
    btnAction1.Visible = True
    btnAction1.Caption = "OK"
    btnAction2.Visible = False
    btnAction3.Visible = False
    lblAmount.Visible = False
    txtAmount.Visible = False
    lblTableId.Visible = False
    txtTableId.Visible = False
    frmMain.Enabled = False
End Sub

Private Sub DoCloseTable()
    Dim billId, TableId As String
    Dim bill As New bill
    
    TableId = txtTableId.Text
    
    If (Not tableToBillMappingDict.Exists(TableId)) Then
        listFlow.AddItem "Table Not Open: "
    Else
        billId = tableToBillMappingDict.Item(TableId)
        Set bill = billsStoreDict.Item(billId)
        
        If (bill.OutstandingAmount > 0) Then
            listFlow.AddItem "Bill not Paid Yet: " + BillToString(bill)
        Else
            tableToBillMappingDict.Remove (TableId)
            assemblyBillDataStoreDict.Remove (TableId)
            listFlow.AddItem "Updated: " + BillToString(bill)
        End If
    End If
    
    frmActions.Show
    btnAction1.Visible = True
    btnAction1.Caption = "OK"
    btnAction2.Visible = False
    btnAction3.Visible = False
    lblAmount.Visible = False
    txtAmount.Visible = False
    lblTableId.Visible = False
    txtTableId.Visible = False
    frmMain.Enabled = False
End Sub

Private Sub DoPrintBill()
    Dim billId As String
    Dim bill As bill
    
    billId = txtTableId.Text
    Set bill = billsStoreDict.Item(billId)
    
    If (Not billsStoreDict.Exists(billId)) Then
        listFlow.AddItem "Bill Not Open: "
    Else
        listFlow.AddItem "Updated: " + BillToString(bill)
    End If
    
    frmActions.Show
    btnAction1.Visible = True
    btnAction1.Caption = "OK"
    btnAction2.Visible = False
    btnAction3.Visible = False
    lblAmount.Visible = False
    txtAmount.Visible = False
    lblTableId.Visible = False
    txtTableId.Visible = False
    frmMain.Enabled = False
End Sub

Private Function BillToString(ByVal newBill As bill) As String
  BillToString = newBill.billId + " - Table:" + newBill.TableId + "Total:$" + CStr(newBill.TotalAmount / 100) _
    + " Outstanding:$" + CStr(newBill.OutstandingAmount / 100) + " Tips:$" + CStr(newBill.TippedAmount / 100)
End Function
