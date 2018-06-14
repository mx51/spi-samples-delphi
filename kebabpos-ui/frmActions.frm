VERSION 5.00
Begin VB.Form frmActions 
   BorderStyle     =   3  'Fixed Dialog
   Caption         =   "Actions"
   ClientHeight    =   7500
   ClientLeft      =   5970
   ClientTop       =   855
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
   ScaleHeight     =   7500
   ScaleWidth      =   6705
   ShowInTaskbar   =   0   'False
   Begin VB.Frame frameActions 
      Height          =   2415
      Left            =   120
      TabIndex        =   1
      Top             =   5040
      Width           =   6495
      Begin VB.OptionButton optionPromptNo 
         Caption         =   "No"
         Height          =   255
         Left            =   3360
         TabIndex        =   16
         Top             =   1920
         Width           =   735
      End
      Begin VB.OptionButton optionPromptYes 
         Caption         =   "Yes"
         Height          =   285
         Left            =   2640
         TabIndex        =   15
         Top             =   1890
         Value           =   -1  'True
         Width           =   735
      End
      Begin VB.TextBox txtCashoutAmount 
         Alignment       =   1  'Right Justify
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
         Left            =   2520
         TabIndex        =   13
         Top             =   1320
         Visible         =   0   'False
         Width           =   1575
      End
      Begin VB.TextBox txtTipAmount 
         Alignment       =   1  'Right Justify
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
         Left            =   2520
         TabIndex        =   11
         Top             =   840
         Visible         =   0   'False
         Width           =   1575
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
      Begin VB.TextBox txtAmount 
         Alignment       =   1  'Right Justify
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
         Left            =   2520
         TabIndex        =   6
         Top             =   360
         Visible         =   0   'False
         Width           =   1575
      End
      Begin VB.Label lblPrompt 
         Caption         =   "Prompt For Cashout"
         Height          =   255
         Left            =   120
         TabIndex        =   17
         Top             =   1920
         Visible         =   0   'False
         Width           =   2295
      End
      Begin VB.Label lblCashoutAmount 
         Caption         =   "Cashout Amount (cents):"
         Height          =   405
         Left            =   120
         TabIndex        =   14
         Top             =   1320
         Visible         =   0   'False
         Width           =   2535
      End
      Begin VB.Label lblTipAmount 
         Caption         =   "Tip Amount (cents):"
         Height          =   405
         Left            =   120
         TabIndex        =   12
         Top             =   840
         Visible         =   0   'False
         Width           =   2175
      End
      Begin VB.Label lblAmount 
         Caption         =   "Amount (cents):"
         Height          =   405
         Left            =   120
         TabIndex        =   7
         Top             =   360
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
        ElseIf spi.CurrentTxFlowState.Type = TransactionType_CashoutOnly Then
            DoCashOut
        ElseIf spi.CurrentTxFlowState.Type = TransactionType_MOTO Then
            DoMoto
        Else
            lblFlowStatus.Caption = "Retry by selecting from the options"
            PrintStatusAndActions
        End If
    ElseIf btnAction1.Caption = "Purchase" Then
        DoPurchase
    ElseIf btnAction1.Caption = "Refund" Then
        DoRefund
    ElseIf btnAction1.Caption = "Cash Out" Then
        DoCashOut
    ElseIf btnAction1.Caption = "MOTO" Then
        DoMoto
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
    Set purchase = spi.InitiatePurchaseTxV2("kebab-" + Format(Now, "dd-mm-yyyy-hh-nn-ss"), _
        CInt(txtAmount.Text), CInt(txtTipAmount.Text), CInt(txtCashoutAmount.Text), optionPromptYes.Value)
    
    If purchase.Initiated Then
        listFlow.AddItem "# Purchase Initiated. Will be updated with Progress."
    Else
        listFlow.AddItem "# Could not initiate purchase: " + purchase.Message + ". Please Retry."
    End If
End Sub

Private Sub DoRefund()
    Dim refund As SPIClient.InitiateTxResult
    
    Set refund = New SPIClient.InitiateTxResult
    Set refund = spi.InitiateRefundTx("rfnd-" + Format(Now, "dd-mm-yyyy-hh-nn-ss"), CInt(txtAmount.Text))
    
    If refund.Initiated Then
        listFlow.AddItem "# Refund Initiated. Will be updated with Progress."
    Else
        listFlow.AddItem "# Could not initiate refund: " + refund.Message + ". Please Retry."
    End If
End Sub

Private Sub DoCashOut()
    Dim coRes As SPIClient.InitiateTxResult
    
    Set coRes = New SPIClient.InitiateTxResult
    Set coRes = spi.InitiateCashoutOnlyTx("cshout-" + Format(Now, "dd-mm-yyyy-hh-nn-ss"), CInt(txtAmount.Text))
    
    If coRes.Initiated Then
        listFlow.AddItem "# Cashout Initiated. Will be updated with Progress."
    Else
        listFlow.AddItem "# Could not initiate cashout: " + coRes.Message + ". Please Retry."
    End If
End Sub

Private Sub DoMoto()
    Dim motoRes As SPIClient.InitiateTxResult
    
    Set motoRes = New SPIClient.InitiateTxResult
    Set motoRes = spi.InitiateMotoPurchaseTx("moto-" + Format(Now, "dd-mm-yyyy-hh-nn-ss"), CInt(txtAmount.Text))
    
    If motoRes.Initiated Then
        listFlow.AddItem "# Moto Initiated. Will be updated with Progress."
    Else
        listFlow.AddItem "# Could not initiate moto: " + motoRes.Message + ". Please Retry."
    End If
End Sub
