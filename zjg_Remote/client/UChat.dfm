object FChat: TFChat
  Left = 0
  Top = 0
  Caption = 'FChat'
  ClientHeight = 336
  ClientWidth = 252
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object YourText_Edit: TEdit
    Left = 0
    Top = 315
    Width = 252
    Height = 21
    Align = alBottom
    TabOrder = 0
    ExplicitTop = 210
    ExplicitWidth = 214
  end
  object Chat_RichEdit: TRichEdit
    Left = 0
    Top = 0
    Width = 252
    Height = 315
    Align = alClient
    Font.Charset = GB2312_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 1
    Zoom = 100
    ExplicitTop = -49
    ExplicitWidth = 214
    ExplicitHeight = 280
  end
end
