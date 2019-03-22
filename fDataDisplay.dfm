object DataDisplay: TDataDisplay
  Left = 0
  Top = 0
  Caption = 'Kugler Log - Data Display'
  ClientHeight = 299
  ClientWidth = 525
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  DesignSize = (
    525
    299)
  PixelsPerInch = 96
  TextHeight = 13
  object mData: TMemo
    Left = 8
    Top = 8
    Width = 509
    Height = 283
    Anchors = [akLeft, akTop, akRight, akBottom]
    Lines.Strings = (
      '')
    ScrollBars = ssBoth
    TabOrder = 0
    ExplicitWidth = 550
    ExplicitHeight = 502
  end
end
