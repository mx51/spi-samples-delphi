VERSION 5.00
Begin VB.Form frmActions 
   BorderStyle     =   3  'Fixed Dialog
   Caption         =   "Actions"
   ClientHeight    =   6945
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
   ScaleHeight     =   6945
   ScaleWidth      =   6705
   ShowInTaskbar   =   0   'False
   Begin VB.Frame frameActions 
      Height          =   1815
      Left            =   120
      TabIndex        =   1
      Top             =   5040
      Width           =   6495
      Begin VB.TextBox txtPreauthId 
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
         Left            =   2280
         TabIndex        =   11
         Top             =   360
         Visible         =   0   'False
         Width           =   1815
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
         Left            =   2280
         TabIndex        =   6
         Top             =   840
         Visible         =   0   'False
         Width           =   1815
      End
      Begin VB.Label lblPreauthId 
         Caption         =   "PreAuth Id:"
         Height          =   405
         Left            =   120
         TabIndex        =   12
         Top             =   360
         Visible         =   0   'False
         Width           =   2175
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
ByVal hWnd As Long, _
ByVal bRevert As Long) As Long

Private Declare Function GetMenuItemCount Lib "user32.dll" ( _
ByVal hMenu As Long) As Long

Private Const MF_BYPOSITION = &H400&

Private Declare Function SendMessage Lib "user32" Alias "SendMessageA" ( _
    ByVal hWnd As Long, ByVal wMsg As Long, ByVal wParam As Long, lParam As Any) As Long
    
Private Const LB_SETHORIZONTALEXTENT = &H194

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
    ElseIf btnAction1.Caption = "OK-Unpaired" Then
        spi.AckFlowEndedAndBackToIdle
        listFlow.Clear
        frmMain.Enabled = True
        frmMain.btnPair.Enabled = True
        frmMain.txtPosId.Enabled = True
        frmMain.txtEftposAddress.Enabled = True
        frmMain.btnPair.Caption = "Pair"
        frmMain.framePreauthActions.Visible = False
        frmMain.frameOtherActions.Visible = False
        frmMain.txtPosId.Enabled = True
        frmMain.txtEftposAddress.Enabled = True
        frmMain.lblStatus.BackColor = RGB(255, 0, 0)
        Hide
    ElseIf btnAction1.Caption = "Accept Signature" Then
        spi.AcceptSignature (True)
    ElseIf btnAction1.Caption = "Retry" Then
        spi.AckFlowEndedAndBackToIdle
        listFlow.Clear
        lblFlowStatus.Caption = "Retry by selecting from the options"
        PrintStatusAndActions
    ElseIf btnAction1.Caption = "Open" Then
        DoOpen
    ElseIf btnAction1.Caption = "Top Up" Then
        DoTopUp
    ElseIf btnAction1.Caption = "Top Down" Then
        DoTopDown
    ElseIf btnAction1.Caption = "Extend" Then
        DoExtend
    ElseIf btnAction1.Caption = "Complete" Then
        DoComplete
    ElseIf btnAction1.Caption = "PreAuth Cancel" Then
        DoCancel
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

Private Sub Form_Activate()
    frmMain.Enabled = False
End Sub

Private Sub Form_Load()
    'REMOVE THE SYSTEM MENU ITEM - CLOSE
    RemoveMenu GetSystemMenu(Me.hWnd, 0), GetMenuItemCount(GetSystemMenu(Me.hWnd, 0)) - 1, MF_BYPOSITION
    'REMOVE THE MENU SEPARATOR
    RemoveMenu GetSystemMenu(Me.hWnd, 0), GetMenuItemCount(GetSystemMenu(Me.hWnd, 0)) - 1, MF_BYPOSITION
    
    'Adding horizontal bar for listbox
    Dim lLength As Long
    lLength = 2 * (listFlow.Width / Screen.TwipsPerPixelX)
    Call SendMessage(listFlow.hWnd, LB_SETHORIZONTALEXTENT, lLength, 0&)
End Sub

Private Sub DoOpen()
    Dim initRes As SPIClient.InitiateTxResult
    Set initRes = New SPIClient.InitiateTxResult
    
    On Error GoTo ErrHandler
    Set initRes = spiPreauth.InitiateOpenTx("propen-" + Format(Now, "dd-mm-yyyy-hh-nn-ss"), CInt(txtAmount.Text))
ErrHandler:
    If (Err.Number = 6) Then
        MsgBox "Exceeds Limit", vbOKOnly, "Warning"
        Exit Sub
    End If
    
    If initRes.Initiated Then
        listFlow.AddItem "# Preauth request Initiated. Will be updated with Progress."
    Else
        listFlow.AddItem "# Could not initiate preauth request: " + initRes.Message + ". Please Retry."
    End If
End Sub

Private Sub DoTopUp()
    Dim initRes As SPIClient.InitiateTxResult
    Set initRes = New SPIClient.InitiateTxResult
    
    On Error GoTo ErrHandler
    Set initRes = spiPreauth.InitiateTopupTx("prtopup-" + frmActions.txtPreauthId.Text + Format(Now, "dd-mm-yyyy-hh-nn-ss"), frmActions.txtPreauthId.Text, CInt(txtAmount.Text))
ErrHandler:
    If (Err.Number = 6) Then
        MsgBox "Exceeds Limit", vbOKOnly, "Warning"
        Exit Sub
    End If
    
    If initRes.Initiated Then
        listFlow.AddItem "# Preauth request Initiated. Will be updated with Progress."
    Else
        listFlow.AddItem "# Could not initiate preauth request: " + initRes.Message + ". Please Retry."
    End If
End Sub

Private Sub DoTopDown()
    Dim initRes As SPIClient.InitiateTxResult
    Set initRes = New SPIClient.InitiateTxResult
    
    On Error GoTo ErrHandler
    Set initRes = spiPreauth.InitiatePartialCancellationTx("prtopd-" + frmActions.txtPreauthId.Text + Format(Now, "dd-mm-yyyy-hh-nn-ss"), frmActions.txtPreauthId.Text, CInt(txtAmount.Text))
ErrHandler:
    If (Err.Number = 6) Then
        MsgBox "Exceeds Limit", vbOKOnly, "Warning"
        Exit Sub
    End If
    
    If initRes.Initiated Then
        listFlow.AddItem "# Preauth request Initiated. Will be updated with Progress."
    Else
        listFlow.AddItem "# Could not initiate preauth request: " + initRes.Message + ". Please Retry."
    End If
End Sub

Private Sub DoExtend()
    Dim initRes As SPIClient.InitiateTxResult
    
    Set initRes = New SPIClient.InitiateTxResult
    Set initRes = spiPreauth.InitiateExtendTx("prtopd-" + frmActions.txtPreauthId.Text + Format(Now, "dd-mm-yyyy-hh-nn-ss"), frmActions.txtPreauthId.Text)
    
    If initRes.Initiated Then
        listFlow.AddItem "# Preauth request Initiated. Will be updated with Progress."
    Else
        listFlow.AddItem "# Could not initiate preauth request: " + initRes.Message + ". Please Retry."
    End If
End Sub

Private Sub DoComplete()
    Dim initRes As SPIClient.InitiateTxResult
    Set initRes = New SPIClient.InitiateTxResult
    
    On Error GoTo ErrHandler
    Set initRes = spiPreauth.InitiateCompletionTx("prcomp-" + frmActions.txtPreauthId.Text + Format(Now, "dd-mm-yyyy-hh-nn-ss"), frmActions.txtPreauthId.Text, CInt(txtAmount.Text))
ErrHandler:
    If (Err.Number = 6) Then
        MsgBox "Exceeds Limit", vbOKOnly, "Warning"
        Exit Sub
    End If
    
    If initRes.Initiated Then
        listFlow.AddItem "# Preauth request Initiated. Will be updated with Progress."
    Else
        listFlow.AddItem "# Could not initiate preauth request: " + initRes.Message + ". Please Retry."
    End If
End Sub

Private Sub DoCancel()
    Dim initRes As SPIClient.InitiateTxResult
    Set initRes = New SPIClient.InitiateTxResult

    Set initRes = spiPreauth.InitiateCancelTx("prtopd-" + frmActions.txtPreauthId.Text + Format(Now, "dd-mm-yyyy-hh-nn-ss"), frmActions.txtPreauthId.Text)
    
    If initRes.Initiated Then
        listFlow.AddItem "# Preauth request Initiated. Will be updated with Progress."
    Else
        listFlow.AddItem "# Could not initiate preauth request: " + initRes.Message + ". Please Retry."
    End If
End Sub
