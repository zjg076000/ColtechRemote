unit URemoteScreen;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.Imaging.pngimage;

type
  TFRemoteScreen = class(TForm)
    ScrollBox1: TScrollBox;
    Screen_Image: TImage;
    Menu_Panel: TPanel;
    MouseIcon_Image: TImage;
    KeyboardIcon_Image: TImage;
    ResizeIcon_Image: TImage;
    MouseIcon_checked_Image: TImage;
    KeyboardIcon_checked_Image: TImage;
    ResizeIcon_checked_Image: TImage;
    ResizeIcon_unchecked_Image: TImage;
    KeyboardIcon_unchecked_Image: TImage;
    MouseIcon_unchecked_Image: TImage;
    Chat_Image: TImage;
    FileShared_Image: TImage;
    ScreenStart_Image: TImage;
    MouseRemote_CheckBox: TCheckBox;
    KeyboardRemote_CheckBox: TCheckBox;
    Resize_CheckBox: TCheckBox;
    CaptureKeys_Timer: TTimer;
    procedure MouseRemote_CheckBoxClick(Sender: TObject);
    procedure KeyboardRemote_CheckBoxClick(Sender: TObject);
    procedure Resize_CheckBoxClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure FormShow(Sender: TObject);
    procedure CaptureKeys_TimerTimer(Sender: TObject);
    procedure ScreenStart_ImageMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ScreenStart_ImageMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure ScreenStart_ImageMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);

     procedure SendSocketKeys(Keys: string);
    procedure Chat_ImageClick(Sender: TObject);
    procedure FileShared_ImageClick(Sender: TObject);
  private
    { Private declarations }
  public
     CtrlPressed, ShiftPressed, AltPressed: Boolean;
  end;

var
  FRemoteScreen: TFRemoteScreen;

implementation

{$R *.dfm}

uses Umain, UChat, UShareFiles;

procedure TFRemoteScreen.CaptureKeys_TimerTimer(Sender: TObject);

  var
  i: Byte;
begin
  // The keys programmed here, may not match the keys on your keyboard. I recommend to undertake adaptation.
  try
    { Combo }
    if (Active) then
    begin
      // Alt
      if not(AltPressed) then
      begin
        if (GetKeyState(VK_MENU) < 0) then
        begin
          AltPressed := true;
          SendSocketKeys('<|ALTDOWN|>');
        end;
      end
      else
      begin
        if (GetKeyState(VK_MENU) > -1) then
        begin
          AltPressed := false;
          SendSocketKeys('<|ALTUP|>');
        end;
      end;

      // Ctrl
      if not(CtrlPressed) then
      begin
        if (GetKeyState(VK_CONTROL) < 0) then
        begin
          CtrlPressed := true;
          SendSocketKeys('<|CTRLDOWN|>');
        end;
      end
      else
      begin
        if (GetKeyState(VK_CONTROL) > -1) then
        begin
          CtrlPressed := false;
          SendSocketKeys('<|CTRLUP|>');
        end;
      end;

      // Shift
      if not(ShiftPressed) then
      begin
        if (GetKeyState(VK_SHIFT) < 0) then
        begin
          ShiftPressed := true;
          SendSocketKeys('<|SHIFTDOWN|>');
        end;
      end
      else
      begin
        if (GetKeyState(VK_SHIFT) > -1) then
        begin
          ShiftPressed := false;
          SendSocketKeys('<|SHIFTUP|>');
        end;
      end;
    end;

    for i := 8 to 228 do
    begin
      if (GetAsyncKeyState(i) = -32767) then
      begin
        case i of
          8:
            SendSocketKeys('{BS}');
          9:
            SendSocketKeys('{TAB}');
          13:
            SendSocketKeys('{ENTER}');
          27:
            SendSocketKeys('{ESCAPE}');
          32:
            SendSocketKeys(' ');
          33:
            SendSocketKeys('{PGUP}');
          34:
            SendSocketKeys('{PGDN}');
          35:
            SendSocketKeys('{END}');
          36:
            SendSocketKeys('{HOME}');
          37:
            SendSocketKeys('{LEFT}');
          38:
            SendSocketKeys('{UP}');
          39:
            SendSocketKeys('{RIGHT}');
          40:
            SendSocketKeys('{DOWN}');
          44:
            SendSocketKeys('{PRTSC}');
          46:
            SendSocketKeys('{DEL}');
          145:
            SendSocketKeys('{SCROLLLOCK}');

          // Numbers: 1 2 3 4 5 6 7 8 9 and ! @ # $ % ? * ( )
          48:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys(')')
            else
              SendSocketKeys('0');
          49:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('!')
            else
              SendSocketKeys('1');
          50:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('@')
            else
              SendSocketKeys('2');
          51:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('#')
            else
              SendSocketKeys('3');
          52:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('$')
            else
              SendSocketKeys('4');
          53:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('%')
            else
              SendSocketKeys('5');
          54:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('^')
            else
              SendSocketKeys('6');
          55:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('&')
            else
              SendSocketKeys('7');
          56:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('*')
            else
              SendSocketKeys('8');
          57:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('(')
            else
              SendSocketKeys('9');

          65 .. 90: // A..Z / a..z
            begin
              if (GetKeyState(VK_CAPITAL) = 1) then
                if (GetKeyState(VK_SHIFT) < 0) then
                  SendSocketKeys(LowerCase(Chr(i)))
                else
                  SendSocketKeys(UpperCase(Chr(i)))
              else if (GetKeyState(VK_SHIFT) < 0) then
                SendSocketKeys(UpperCase(Chr(i)))
              else
                SendSocketKeys(LowerCase(Chr(i)))

            end;

          96 .. 105: // Numpad 1..9
            SendSocketKeys(IntToStr(i - 96));

          106:
            SendSocketKeys('*');
          107:
            SendSocketKeys('+');
          109:
            SendSocketKeys('-');
          110:
            SendSocketKeys(',');
          111:
            SendSocketKeys('/');
          194:
            SendSocketKeys('.');

          // F1..F12
          112 .. 123:
            SendSocketKeys('{F' + IntToStr(i - 111) + '}');

          186:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('?')
            else
              SendSocketKeys('?');
          187:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('+')
            else
              SendSocketKeys('=');
          188:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('<')
            else
              SendSocketKeys(',');
          189:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('_')
            else
              SendSocketKeys('-');
          190:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('>')
            else
              SendSocketKeys('.');
          191:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys(':')
            else
              SendSocketKeys(';');
          192:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('"')
            else
              SendSocketKeys('''');
          193:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('?')
            else
              SendSocketKeys('/');
          219:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('`')
            else
              SendSocketKeys('?');
          220:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('}')
            else
              SendSocketKeys(']');
          221:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('{')
            else
              SendSocketKeys('[');
          222:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('^')
            else
              SendSocketKeys('~');
          226:
            if (GetKeyState(VK_SHIFT) < 0) then
              SendSocketKeys('|')
            else
              SendSocketKeys('\');
        end;
      end;
    end;
  except
  end;
end;

procedure TFRemoteScreen.Chat_ImageClick(Sender: TObject);
begin
 FChat.Show;
end;

procedure TFRemoteScreen.FileShared_ImageClick(Sender: TObject);
begin
   FShareFiles.Show;
end;

procedure TFRemoteScreen.FormCreate(Sender: TObject);
begin
    SetWindowLong(Handle, GWL_EXSTYLE, WS_EX_APPWINDOW);
end;

procedure TFRemoteScreen.FormMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
   if (MouseRemote_CheckBox.Checked) then
    FMain.Main_Socket.Socket.SendText('<|REDIRECT|><|WHEELMOUSE|>' + IntToStr(WheelDelta) + '<|END|>');
end;

procedure TFRemoteScreen.FormShow(Sender: TObject);
begin
   CtrlPressed := false;
  ShiftPressed := false;
  AltPressed := false;
end;

procedure TFRemoteScreen.KeyboardRemote_CheckBoxClick(Sender: TObject);
begin
  if KeyboardRemote_CheckBox.Checked then
  begin
    KeyboardIcon_Image.Picture.Assign(KeyboardIcon_checked_Image.Picture);
    CaptureKeys_Timer.Enabled := true;
  end
  else
  begin
    KeyboardIcon_Image.Picture.Assign(KeyboardIcon_unchecked_Image.Picture);
    CaptureKeys_Timer.Enabled := false;
  end;
end;

procedure TFRemoteScreen.MouseRemote_CheckBoxClick(Sender: TObject);
begin
     if MouseRemote_CheckBox.Checked then
  begin
    MouseIcon_Image.Picture.Assign(MouseIcon_checked_Image.Picture);
  end
  else
  begin
    MouseIcon_Image.Picture.Assign(MouseIcon_unchecked_Image.Picture);
  end;
end;

procedure TFRemoteScreen.Resize_CheckBoxClick(Sender: TObject);
begin
    if Resize_CheckBox.Checked then
  begin
    Screen_Image.AutoSize := false;
    Screen_Image.Stretch := true;
    Screen_Image.Align := alClient;
    ResizeIcon_Image.Picture.Assign(ResizeIcon_checked_Image.Picture);
  end
  else
  begin
    Screen_Image.AutoSize := true;
    Screen_Image.Stretch := false;
    Screen_Image.Align := alNone;
    ResizeIcon_Image.Picture.Assign(ResizeIcon_unchecked_Image.Picture);
  end;
end;

procedure TFRemoteScreen.ScreenStart_ImageMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
    if (Active) and (MouseRemote_CheckBox.Checked) then
  begin
    X := (X * FMain.ResolutionTargetWidth) div (Screen_Image.Width);
    Y := (Y * FMain.ResolutionTargetHeight) div (Screen_Image.Height);

    if (Button = mbLeft) then
      FMain.Main_Socket.Socket.SendText('<|REDIRECT|><|SETMOUSELEFTCLICKDOWN|>' + IntToStr(X) + '<|>' + IntToStr(Y) + '<|END|>')
    else if (Button = mbRight) then
      FMain.Main_Socket.Socket.SendText('<|REDIRECT|><|SETMOUSERIGHTCLICKDOWN|>' + IntToStr(X) + '<|>' + IntToStr(Y) + '<|END|>')
    else
      FMain.Main_Socket.Socket.SendText('<|REDIRECT|><|SETMOUSEMIDDLEDOWN|>' + IntToStr(X) + '<|>' + IntToStr(Y) + '<|END|>')
  end;
end;

procedure TFRemoteScreen.ScreenStart_ImageMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
    if (Active) and (MouseRemote_CheckBox.Checked) then
  begin
    X := (X * FMain.ResolutionTargetWidth) div (Screen_Image.Width);
    Y := (Y * FMain.ResolutionTargetHeight) div (Screen_Image.Height);
    FMain.Main_Socket.Socket.SendText('<|REDIRECT|><|SETMOUSEPOS|>' + IntToStr(X) + '<|>' + IntToStr(Y) + '<|END|>');
  end;
end;

procedure TFRemoteScreen.ScreenStart_ImageMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
     if (Active) and (MouseRemote_CheckBox.Checked) then
  begin
    X := (X * FMain.ResolutionTargetWidth) div (Screen_Image.Width);
    Y := (Y * FMain.ResolutionTargetHeight) div (Screen_Image.Height);
    if (Button = mbLeft) then
      FMain.Main_Socket.Socket.SendText('<|REDIRECT|><|SETMOUSELEFTCLICKUP|>' + IntToStr(X) + '<|>' + IntToStr(Y) + '<|END|>')
    else if (Button = mbRight) then
      FMain.Main_Socket.Socket.SendText('<|REDIRECT|><|SETMOUSERIGHTCLICKUP|>' + IntToStr(X) + '<|>' + IntToStr(Y) + '<|END|>')
    else
      FMain.Main_Socket.Socket.SendText('<|REDIRECT|><|SETMOUSEMIDDLEUP|>' + IntToStr(X) + '<|>' + IntToStr(Y) + '<|END|>')
  end;
end;

procedure TFRemoteScreen.SendSocketKeys(Keys: string);
begin
     if (Active) then
    FMain.Keyboard_Socket.Socket.SendText(Keys);
end;

end.
