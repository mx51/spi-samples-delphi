object frmMain: TfrmMain
  Left = 366
  Top = 103
  AutoSize = True
  BorderIcons = [biSystemMenu]
  Caption = 'Table Delphi Pos'
  ClientHeight = 498
  ClientWidth = 626
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Verdana'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesigned
  Visible = True
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object pnlSettings: TPanel
    Left = 0
    Top = 0
    Width = 313
    Height = 147
    BorderStyle = bsSingle
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -27
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    object lblSettings: TLabel
      Left = 1
      Top = 1
      Width = 307
      Height = 33
      Align = alTop
      Alignment = taCenter
      Caption = 'Settings'
      Color = clSilver
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
      ExplicitWidth = 95
    end
    object lblPosID: TLabel
      Left = 1
      Top = 40
      Width = 53
      Height = 19
      Caption = 'Pos ID:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object lblEftposAddress: TLabel
      Left = 1
      Top = 72
      Width = 134
      Height = 19
      AutoSize = False
      Caption = 'EFTPOS Address:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
    object lblReceiptFrom: TLabel
      Left = 1
      Top = 100
      Width = 150
      Height = 19
      AutoSize = False
      Caption = 'Receipt From EFTPOS:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
    object lblSignFrom: TLabel
      Left = 1
      Top = 123
      Width = 150
      Height = 19
      AutoSize = False
      Caption = 'Sign From EFTPOS:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
    object edtPosID: TEdit
      Left = 143
      Top = 40
      Width = 158
      Height = 24
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object radioSign: TRadioGroup
      Left = 141
      Top = 97
      Width = 160
      Height = 42
      Columns = 2
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ItemIndex = 0
      Items.Strings = (
        'Yes'
        'No')
      ParentFont = False
      TabOrder = 3
    end
    object radioReceipt: TRadioGroup
      Left = 141
      Top = 75
      Width = 160
      Height = 42
      Columns = 2
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ItemIndex = 0
      Items.Strings = (
        'Yes'
        'No')
      ParentFont = False
      TabOrder = 2
    end
    object edtEftposAddress: TEdit
      Left = 143
      Top = 70
      Width = 158
      Height = 24
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
    end
  end
  object pnlStatus: TPanel
    Left = 0
    Top = 147
    Width = 313
    Height = 110
    BorderStyle = bsSingle
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -27
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    object lblStatusHead: TLabel
      Left = 1
      Top = 1
      Width = 307
      Height = 33
      Align = alTop
      Alignment = taCenter
      Caption = 'Status'
      Color = clSilver
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
      ExplicitWidth = 74
    end
    object lblStatus: TLabel
      Left = 60
      Top = 40
      Width = 185
      Height = 19
      Alignment = taCenter
      AutoSize = False
      Caption = 'Idle'
      Color = clBtnFace
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
      Layout = tlCenter
    end
    object btnPair: TButton
      Left = 74
      Top = 65
      Width = 158
      Height = 34
      Caption = 'Pair'
      TabOrder = 0
      OnClick = btnPairClick
    end
  end
  object pnlReceipt: TPanel
    Left = 313
    Top = 0
    Width = 313
    Height = 498
    BorderStyle = bsSingle
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -27
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    object lblReceipt: TLabel
      Left = 1
      Top = 1
      Width = 307
      Height = 33
      Align = alTop
      Alignment = taCenter
      Caption = 'Receipt'
      Color = clSilver
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
      ExplicitWidth = 87
    end
    object richEdtReceipt: TRichEdit
      Left = 0
      Top = 35
      Width = 307
      Height = 455
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 0
      Zoom = 100
    end
  end
  object pnlTableActions: TPanel
    Left = 0
    Top = 257
    Width = 313
    Height = 128
    BorderStyle = bsSingle
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -27
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 3
    Visible = False
    object lblTableActions: TLabel
      Left = 1
      Top = 1
      Width = 307
      Height = 33
      Align = alTop
      Alignment = taCenter
      Caption = 'Table Actions'
      Color = clSilver
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
      ExplicitWidth = 158
    end
    object btnClose: TButton
      Left = 60
      Top = 80
      Width = 80
      Height = 34
      Caption = 'Close'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = btnCloseClick
    end
    object btnPrintBill: TButton
      Left = 155
      Top = 80
      Width = 80
      Height = 34
      Caption = 'Print Bill'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
    end
    object btnOpen: TButton
      Left = 60
      Top = 40
      Width = 80
      Height = 34
      Caption = 'Open'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = btnOpenClick
    end
    object btnAdd: TButton
      Left = 155
      Top = 40
      Width = 80
      Height = 34
      Caption = 'Add'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      OnClick = btnAddClick
    end
  end
  object pnlOtherActions: TPanel
    Left = 0
    Top = 386
    Width = 313
    Height = 112
    BorderStyle = bsSingle
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -27
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
    Visible = False
    object lblOtherActions: TLabel
      Left = 1
      Top = 1
      Width = 307
      Height = 33
      Align = alTop
      Alignment = taCenter
      Caption = 'Other Actions'
      Color = clSilver
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
      ExplicitWidth = 160
    end
    object btnPurchase: TButton
      Left = 12
      Top = 54
      Width = 80
      Height = 34
      Caption = 'Purchase'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = btnPurchaseClick
    end
    object btnSettlement: TButton
      Left = 211
      Top = 54
      Width = 80
      Height = 34
      Caption = 'Settlement'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = btnSettleClick
    end
    object btnRefund: TButton
      Left = 116
      Top = 54
      Width = 80
      Height = 34
      Caption = 'Refund'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = btnRefundClick
    end
  end
end
