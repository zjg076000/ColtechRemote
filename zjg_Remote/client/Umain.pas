﻿unit Umain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Mask, Vcl.StdCtrls,Winapi.MMSystem,
  Vcl.Buttons, Vcl.Imaging.pngimage,System.Win.ScktComp,Vcl.ComCtrls,Registry,Clipbrd, sndkey32, StreamManager, zLibEx;

type
  TThread_Connection_Main = class(TThread)
    Socket: TCustomWinSocket;
    constructor Create(aSocket: TCustomWinSocket); overload;
    procedure Execute; override;
  end;

type
  TThread_Connection_Desktop = class(TThread)
    Socket: TCustomWinSocket;
    constructor Create(aSocket: TCustomWinSocket); overload;
    procedure Execute; override;
  end;

type
  TThread_Connection_Keyboard = class(TThread)
    Socket: TCustomWinSocket;
    constructor Create(aSocket: TCustomWinSocket); overload;
    procedure Execute; override;
  end;

type
  TThread_Connection_Files = class(TThread)
    Socket: TCustomWinSocket;
    constructor Create(aSocket: TCustomWinSocket); overload;
    procedure Execute; override;
  end;


type
  TFmain = class(TForm)
    TopBackground_Image: TImage;
    Logo_Image: TImage;
    Title1_Label: TLabel;
    Title2_Label: TLabel;
    background_label_Image3: TImage;
    TargetID_Label: TLabel;
    Status_Image: TImage;
    Status_Label: TLabel;
    Bevel1: TBevel;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    GroupBox1: TGroupBox;
    background_label_Image: TImage;
    YourID_Label: TLabel;
    background_label_Image2: TImage;
    YourPassword_Label: TLabel;
    YourID_Edit: TEdit;
    YourPassword_Edit: TEdit;
    Connect_BitBtn: TBitBtn;
    About_BitBtn: TBitBtn;
    TargetID_MaskEdit: TMaskEdit;
    Reconnect_Timer: TTimer;
    Timeout_Timer: TTimer;
    Clipboard_Timer: TTimer;
    procedure FormCreate(Sender: TObject);

    procedure Main_SocketConnecting(Sender: TObject; Socket: TCustomWinSocket);
    procedure Main_SocketDisconnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure Main_SocketError(Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent; var ErrorCode: Integer);
    procedure Main_SocketConnect(Sender: TObject; Socket: TCustomWinSocket);

    procedure Desktop_SocketError(Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent; var ErrorCode: Integer);
    procedure Desktop_SocketConnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure Keyboard_SocketError(Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent; var ErrorCode: Integer);
    procedure Keyboard_SocketConnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure Files_SocketError(Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent; var ErrorCode: Integer);
    procedure Files_SocketConnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure TargetID_MaskEditKeyPress(Sender: TObject; var Key: Char);
    procedure Clipboard_TimerTimer(Sender: TObject);
    procedure YourID_EditKeyPress(Sender: TObject; var Key: Char);
    procedure Timeout_TimerTimer(Sender: TObject);
    procedure Reconnect_TimerTimer(Sender: TObject);
    procedure Connect_BitBtnClick(Sender: TObject);

  private
    { Private declarations }
  public
     Main_Socket: TClientSocket;
    Desktop_Socket: TClientSocket;
    Keyboard_Socket: TClientSocket;
    Files_Socket: TClientSocket;

    MyID: string;
    MyPassword: string;
    MyPing: Integer;
    Viewer: Boolean;
    ResolutionTargetWidth: Integer;
    ResolutionTargetHeight: Integer;

    Thread_Connection_Main: TThread_Connection_Main;
    Thread_Connection_Desktop: TThread_Connection_Desktop;
    Thread_Connection_Keyboard: TThread_Connection_Keyboard;
    Thread_Connection_Files: TThread_Connection_Files;

    procedure ClearConnection;
    procedure SetOffline;
    procedure SetOnline;
    procedure Reconnect;
    procedure ReconnectSecundarySockets;
    procedure CloseSockets;
  end;

var
  Fmain: TFmain;

  ResolutionWidth: Integer;
  ResolutionHeight: Integer;
  Timeout: Integer;
  OldWallpaper: string;
  OldClipboardText: string;
  Accessed: Boolean;

 const
  Host = '122.128.106.8'; // Host of Sockets  (Insert the IP Address or DNS of your Server)
  Port = 3898; // Port of Sockets
  ConnectionTimeout = 60; // Timeout of connection (in secound)
  ProcessingSlack = 2; // Processing slack for Sleep Commands

implementation

{$R *.dfm}

uses UPassWord, URemoteScreen, UShareFiles, UChat;

{ TThread_Connection_Main }
// Compress Stream with zLib
function CompressStreamWithZLib(SrcStream: TMemoryStream): Boolean;
var
  InputStream: TMemoryStream;
  inbuffer: Pointer;
  outbuffer: Pointer;
  count, outcount: longint;
begin
  Result := False;
  InputStream := TMemoryStream.Create;

  try
    InputStream.LoadFromStream(SrcStream);
    count := InputStream.Size;
    getmem(inbuffer, count);
    InputStream.ReadBuffer(inbuffer^, count);
    zcompress(inbuffer, count, outbuffer, outcount, zcDefault);
    SrcStream.Clear;
    SrcStream.Write(outbuffer^, outcount);
    Result := true;
  finally
    FreeAndNil(InputStream);
    FreeMem(inbuffer, count);
    FreeMem(outbuffer, outcount);
  end;
end;

// Decompress Stream with zLib
function DeCompressStreamWithZLib(SrcStream: TMemoryStream): Boolean;
var
  InputStream: TMemoryStream;
  inbuffer: Pointer;
  outbuffer: Pointer;
  count: longint;
  outcount: longint;
begin
  Result := False;
  InputStream := TMemoryStream.Create;

  try
    InputStream.LoadFromStream(SrcStream);
    count := InputStream.Size;
    getmem(inbuffer, count);
    InputStream.ReadBuffer(inbuffer^, count);
    zdecompress(inbuffer, count, outbuffer, outcount);
    SrcStream.Clear;
    SrcStream.Write(outbuffer^, outcount);
    Result := true;
  finally
    FreeAndNil(InputStream);
    FreeMem(inbuffer, count);
    FreeMem(outbuffer, outcount);
  end;
end;

function MemoryStreamToString(M: TMemoryStream): AnsiString;
begin
  SetString(Result, PAnsiChar(M.Memory), M.Size);
end;

// Return size (B, KB, MB or GB)
function GetSize(bytes: Int64): string;
begin
  if bytes < 1024 then
    Result := IntToStr(bytes) + ' B'
  else if bytes < 1048576 then
    Result := FloatToStrF(bytes / 1024, ffFixed, 10, 1) + ' KB'
  else if bytes < 1073741824 then
    Result := FloatToStrF(bytes / 1048576, ffFixed, 10, 1) + ' MB'
  else if bytes > 1073741824 then
    Result := FloatToStrF(bytes / 1073741824, ffFixed, 10, 1) + ' GB';
end;

// Function to List Folders
function ListFolders(Directory: string): string;
var
  FileName: string;
  Filelist: string;
  Dirlist: string;
  Searchrec: TWin32FindData;
  FindHandle: THandle;
  ReturnStr: string;
begin
  ReturnStr := '';
  try
    FindHandle := FindFirstFile(PChar(Directory + '*.*'), Searchrec);
    if FindHandle <> INVALID_HANDLE_VALUE then
      repeat
        FileName := Searchrec.cFileName;
        if (FileName = '.') then
          Continue;
        if ((Searchrec.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) <> 0) then
        begin
          Dirlist := Dirlist + (FileName + #13);
        end
        else
        begin
          Filelist := Filelist + (FileName + #13);
        end;
      until FindNextFile(FindHandle, Searchrec) = False;
  finally
    Winapi.Windows.FindClose(FindHandle);
  end;
  ReturnStr := (Dirlist);
  Result := ReturnStr;
end;

// Function to List Files
function ListFiles(FileName, Ext: string): string;
var
  SearchFile: TSearchRec;
  FindResult: Integer;
  Arc: TStrings;
begin
  Arc := TStringList.Create;
  FindResult := FindFirst(FileName + Ext, faArchive, SearchFile);
  try
    while FindResult = 0 do
    begin
      Application.ProcessMessages;
      Arc.Add(SearchFile.Name);
      FindResult := FindNext(SearchFile);
    end;
  finally
    FindClose(SearchFile)
  end;
  Result := Arc.Text;
end;

 // Get current Version
function GetAppVersionStr: string;
var
  Exe: string;
  Size, Handle: DWORD;
  Buffer: TBytes;
  FixedPtr: PVSFixedFileInfo;
begin
  Exe := ParamStr(0);
  Size := GetFileVersionInfoSize(PChar(Exe), Handle);
  if Size = 0 then
    RaiseLastOSError;
  SetLength(Buffer, Size);
  if not GetFileVersionInfo(PChar(Exe), Handle, Size, Buffer) then
    RaiseLastOSError;
  if not VerQueryValue(Buffer, '\', Pointer(FixedPtr), Size) then
    RaiseLastOSError;
  Result := Format('%d.%d.%d.%d', [LongRec(FixedPtr.dwFileVersionMS).Hi, // major
    LongRec(FixedPtr.dwFileVersionMS).Lo, // minor
    LongRec(FixedPtr.dwFileVersionLS).Hi, // release
    LongRec(FixedPtr.dwFileVersionLS).Lo]) // build
end;

function GetWallpaperDirectory: string;
var
  Reg: TRegistry;
begin
  Reg := nil;
  try
    Reg := TRegistry.Create;
    Reg.RootKey := HKEY_CURRENT_USER;
    Reg.OpenKey('Control Panel\Desktop', False);
    Result := Reg.ReadString('Wallpaper');
  finally
    FreeAndNil(Reg);
  end;
end;

procedure ChangeWallpaper(Directory: string);
var
  Reg: TRegistry;
begin
  Reg := nil;
  try
    Reg := TRegistry.Create;
    Reg.RootKey := HKEY_CURRENT_USER;
    Reg.OpenKey('Control Panel\Desktop', False);
    Reg.WriteString('Wallpaper', Directory);
    SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, nil, SPIF_SENDWININICHANGE);
  finally
    FreeAndNil(Reg);
  end;
end;

constructor TThread_Connection_Main.Create(aSocket: TCustomWinSocket);
begin
  inherited Create(False);
  Socket := aSocket;
  FreeOnTerminate := true;
end;

procedure TThread_Connection_Main.Execute;
var
  Buffer: string;
  BufferTemp: string;
  Extension: string;
  i: Integer;
  Position: Integer;
  MousePosX: Integer;
  MousePosY: Integer;
  FoldersAndFiles: TStringList;
  L: TListItem;
  FileToUpload: TFileStream;
  hDesktop: HDESK;
begin
  inherited;

  FoldersAndFiles := nil;
  FileToUpload := nil;

  while Socket.Connected do
  begin
    Sleep(ProcessingSlack); // Avoids using 100% CPU

    if (Socket = nil) or not(Socket.Connected) then
      Break;

    if Socket.ReceiveLength < 1 then
      Continue;

    Buffer := Socket.ReceiveText;

    // Received data, then resets the timeout
    Timeout := 0;

    // EUREKA: This is the responsable to interact with UAC. But we need run
    // the software on SYSTEM account to work.
    hDesktop := OpenInputDesktop(0, true, MAXIMUM_ALLOWED);
    if hDesktop <> 0 then
    begin
      SetThreadDesktop(hDesktop);
      CloseHandle(hDesktop);
    end;

    // If receive ID, are Online
    Position := Pos('<|ID|>', Buffer);
    if Position > 0 then
    begin
      BufferTemp := Buffer;
      Delete(BufferTemp, 1, Position + 5);
      Position := Pos('<|>', BufferTemp);
      FMain.MyID := Copy(BufferTemp, 1, Position - 1);
      Delete(BufferTemp, 1, Position + 2);
      FMain.MyPassword := Copy(BufferTemp, 1, Pos('<|END|>', BufferTemp) - 1);
      Synchronize(FMain.SetOnline);

      // If this Socket are connected, then connect the Desktop Socket, Keyboard Socket, File Download Socket and File Upload Socket
      Synchronize(
        procedure
        begin
          with FMain do
          begin
            Desktop_Socket.Active := true;
            Keyboard_Socket.Active := true;
            Files_Socket.Active := true;

            TargetID_MaskEdit.SetFocus;
          end;
        end);
    end;

    // Ping
    if Buffer.Contains('<|PING|>') then
      Socket.SendText('<|PONG|>');

    Position := Pos('<|SETPING|>', Buffer);
    if Position > 0 then
    begin
      BufferTemp := Buffer;
      Delete(BufferTemp, 1, Position + 10);
      BufferTemp := Copy(BufferTemp, 1, Pos('<|END|>', BufferTemp) - 1);
      FMain.MyPing := StrToInt(BufferTemp);
    end;

    // Warns access and remove Wallpaper
    if Buffer.Contains('<|ACCESSING|>') then
    begin
      OldWallpaper := GetWallpaperDirectory;
      // ChangeWallpaper('');

      Synchronize(
        procedure
        begin
          FMain.TargetID_MaskEdit.Enabled := False;
          FMain.Connect_BitBtn.Enabled := False;
          FMain.Status_Image.Picture.Assign(FMain.Image3.Picture);
          FMain.Status_Label.Caption := 'Connected support!';
        end);
      Accessed := true;
    end;

    if Buffer.Contains('<|IDEXISTS!REQUESTPASSWORD|>') then
    begin
      Synchronize(
        procedure
        begin
          FMain.Status_Label.Caption := 'Waiting for authentication...';
          FPassword.ShowModal;
        end);
    end;

    if Buffer.Contains('<|IDNOTEXISTS|>') then
    begin
      Synchronize(
        procedure
        begin
          FMain.Status_Image.Picture.Assign(FMain.Image2.Picture);
          FMain.Status_Label.Caption := 'ID does nor exists.';
          FMain.TargetID_MaskEdit.Enabled := true;
          FMain.Connect_BitBtn.Enabled := true;
          FMain.TargetID_MaskEdit.SetFocus;
        end);
    end;

    if Buffer.Contains('<|ACCESSDENIED|>') then
    begin
      Synchronize(
        procedure
        begin
          FMain.Status_Image.Picture.Assign(FMain.Image2.Picture);
          FMain.Status_Label.Caption := 'Wrong password!';
          FMain.TargetID_MaskEdit.Enabled := true;
          FMain.Connect_BitBtn.Enabled := true;
          FMain.TargetID_MaskEdit.SetFocus;
        end);
    end;

    if Buffer.Contains('<|ACCESSBUSY|>') then
    begin
      Synchronize(
        procedure
        begin
          FMain.Status_Image.Picture.Assign(FMain.Image2.Picture);
          FMain.Status_Label.Caption := 'PC is Busy!';
          FMain.TargetID_MaskEdit.Enabled := true;
          FMain.Connect_BitBtn.Enabled := true;
          FMain.TargetID_MaskEdit.SetFocus;
        end);
    end;

    if Buffer.Contains('<|ACCESSGRANTED|>') then
    begin
      Synchronize(
        procedure
        begin
          FMain.Status_Image.Picture.Assign(FMain.Image3.Picture);
          FMain.Status_Label.Caption := 'Access granted!';
          FMain.Viewer := true;
          FMain.Clipboard_Timer.Enabled := true;
          FMain.ClearConnection;
          FRemoteScreen.Show;
          FMain.Hide;
          Socket.SendText('<|RELATION|>' + FMain.MyID + '<|>' + FMain.TargetID_MaskEdit.Text + '<|END|>');
        end);
    end;

    if Buffer.Contains('<|DISCONNECTED|>') then
    begin
      Synchronize(
        procedure
        begin
          FRemoteScreen.Hide;
          FShareFiles.Hide;
          FChat.Hide;

          // if Accessed then
          // ChangeWallpaper(OldWallpaper);

          FMain.ReconnectSecundarySockets;
          FMain.Show;
          FMain.SetOnline;
          FMain.Status_Image.Picture.Assign(FMain.Image2.Picture);
          FMain.Status_Label.Caption := 'Lost connection to PC!';
          FlashWindow(FMain.Handle, true);
        end);
    end;

    { Redirected commands }

    // Desktop Remote
    Position := Pos('<|RESOLUTION|>', Buffer);
    if Position > 0 then
    begin
      BufferTemp := Buffer;
      Delete(BufferTemp, 1, Position + 13);
      Position := Pos('<|>', BufferTemp);
      FMain.ResolutionTargetWidth := StrToInt(Copy(BufferTemp, 1, Position - 1));
      Delete(BufferTemp, 1, Position + 2);
      FMain.ResolutionTargetHeight := StrToInt(Copy(BufferTemp, 1, Pos('<|END|>', BufferTemp) - 1));
    end;

    Position := Pos('<|SETMOUSEPOS|>', Buffer);
    if Position > 0 then
    begin
      BufferTemp := Buffer;
      Delete(BufferTemp, 1, Position + 14);
      Position := Pos('<|>', BufferTemp);
      MousePosX := StrToInt(Copy(BufferTemp, 1, Position - 1));
      Delete(BufferTemp, 1, Position + 2);
      MousePosY := StrToInt(Copy(BufferTemp, 1, Pos('<|END|>', BufferTemp) - 1));
      SetCursorPos(MousePosX, MousePosY);
    end;

    Position := Pos('<|SETMOUSELEFTCLICKDOWN|>', Buffer);
    if Position > 0 then
    begin
      BufferTemp := Buffer;
      Delete(BufferTemp, 1, Position + 24);
      Position := Pos('<|>', BufferTemp);
      MousePosX := StrToInt(Copy(BufferTemp, 1, Position - 1));
      Delete(BufferTemp, 1, Position + 2);
      MousePosY := StrToInt(Copy(BufferTemp, 1, Pos('<|END|>', BufferTemp) - 1));
      SetCursorPos(MousePosX, MousePosY);
      Mouse_Event(MOUSEEVENTF_ABSOLUTE or MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
    end;

    Position := Pos('<|SETMOUSELEFTCLICKUP|>', Buffer);
    if Position > 0 then
    begin
      BufferTemp := Buffer;
      Delete(BufferTemp, 1, Position + 22);
      Position := Pos('<|>', BufferTemp);
      MousePosX := StrToInt(Copy(BufferTemp, 1, Position - 1));
      Delete(BufferTemp, 1, Position + 2);
      MousePosY := StrToInt(Copy(BufferTemp, 1, Pos('<|END|>', BufferTemp) - 1));
      SetCursorPos(MousePosX, MousePosY);
      Mouse_Event(MOUSEEVENTF_ABSOLUTE or MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
    end;

    Position := Pos('<|SETMOUSERIGHTCLICKDOWN|>', Buffer);
    if Position > 0 then
    begin
      BufferTemp := Buffer;
      Delete(BufferTemp, 1, Position + 25);
      Position := Pos('<|>', BufferTemp);
      MousePosX := StrToInt(Copy(BufferTemp, 1, Position - 1));
      Delete(BufferTemp, 1, Position + 2);
      MousePosY := StrToInt(Copy(BufferTemp, 1, Pos('<|END|>', BufferTemp) - 1));
      SetCursorPos(MousePosX, MousePosY);
      Mouse_Event(MOUSEEVENTF_ABSOLUTE or MOUSEEVENTF_RIGHTDOWN, 0, 0, 0, 0);
    end;

    Position := Pos('<|SETMOUSERIGHTCLICKUP|>', Buffer);
    if Position > 0 then
    begin
      BufferTemp := Buffer;
      Delete(BufferTemp, 1, Position + 23);
      Position := Pos('<|>', BufferTemp);
      MousePosX := StrToInt(Copy(BufferTemp, 1, Position - 1));
      Delete(BufferTemp, 1, Position + 2);
      MousePosY := StrToInt(Copy(BufferTemp, 1, Pos('<|END|>', BufferTemp) - 1));
      SetCursorPos(MousePosX, MousePosY);
      Mouse_Event(MOUSEEVENTF_ABSOLUTE or MOUSEEVENTF_RIGHTUP, 0, 0, 0, 0);
    end;

    Position := Pos('<|SETMOUSEMIDDLEDOWN|>', Buffer);
    if Position > 0 then
    begin
      BufferTemp := Buffer;
      Delete(BufferTemp, 1, Position + 21);
      Position := Pos('<|>', BufferTemp);
      MousePosX := StrToInt(Copy(BufferTemp, 1, Position - 1));
      Delete(BufferTemp, 1, Position + 2);
      MousePosY := StrToInt(Copy(BufferTemp, 1, Pos('<|END|>', BufferTemp) - 1));
      SetCursorPos(MousePosX, MousePosY);
      Mouse_Event(MOUSEEVENTF_ABSOLUTE or MOUSEEVENTF_MIDDLEDOWN, 0, 0, 0, 0);
    end;

    Position := Pos('<|SETMOUSEMIDDLEUP|>', Buffer);
    if Position > 0 then
    begin
      BufferTemp := Buffer;
      Delete(BufferTemp, 1, Position + 19);
      Position := Pos('<|>', BufferTemp);
      MousePosX := StrToInt(Copy(BufferTemp, 1, Position - 1));
      Delete(BufferTemp, 1, Position + 2);
      MousePosY := StrToInt(Copy(BufferTemp, 1, Pos('<|END|>', BufferTemp) - 1));
      SetCursorPos(MousePosX, MousePosY);
      Mouse_Event(MOUSEEVENTF_ABSOLUTE or MOUSEEVENTF_MIDDLEUP, 0, 0, 0, 0);
    end;

    Position := Pos('<|WHEELMOUSE|>', Buffer);
    if Position > 0 then
    begin
      BufferTemp := Buffer;
      Delete(BufferTemp, 1, Position + 13);
      BufferTemp := Copy(BufferTemp, 1, Pos('<|END|>', BufferTemp) - 1);
      Mouse_Event(MOUSEEVENTF_WHEEL, 0, 0, DWORD(StrToInt(BufferTemp)), 0);
    end;

    // Clipboard Remote
    Position := Pos('<|CLIPBOARD|>', Buffer);
    if Position > 0 then
    begin
      BufferTemp := Buffer;
      Delete(BufferTemp, 1, Position + 12);
      BufferTemp := Copy(BufferTemp, 1, Pos('<|END|>', BufferTemp) - 1);
      try
        Clipboard.Open;
        Clipboard.AsText := BufferTemp;
      finally
        Clipboard.Close;
      end;
    end;

    // Chat
    Position := Pos('<|CHAT|>', Buffer);
    if Position > 0 then
    begin
      BufferTemp := Buffer;
      Delete(BufferTemp, 1, Position + 7);
      BufferTemp := Copy(BufferTemp, 1, Pos('<|END|>', BufferTemp) - 1);

      Synchronize(
        procedure
        begin
          with FChat do
          begin
            if (FirstMessage) then
            begin
              LastMessageAreYou := False;
              Chat_RichEdit.SelStart := Chat_RichEdit.GetTextLen;
              Chat_RichEdit.SelAttributes.Style := [fsBold];
              Chat_RichEdit.SelAttributes.Color := clGreen;
              Chat_RichEdit.SelText := #13 + #13 + 'He say:';
              FirstMessage := False;
            end;

            if (LastMessageAreYou) then
            begin
              LastMessageAreYou := False;
              Chat_RichEdit.SelStart := Chat_RichEdit.GetTextLen;
              Chat_RichEdit.SelAttributes.Style := [fsBold];
              Chat_RichEdit.SelAttributes.Color := clGreen;
              Chat_RichEdit.SelText := #13 + #13 + 'He say:' + #13;

              Chat_RichEdit.SelStart := Chat_RichEdit.GetTextLen;
              Chat_RichEdit.SelAttributes.Color := clWhite;
              Chat_RichEdit.SelText := '   •   ' + BufferTemp;
            end
            else
            begin
              Chat_RichEdit.SelStart := Chat_RichEdit.GetTextLen;
              Chat_RichEdit.SelAttributes.Style := [];
              Chat_RichEdit.SelAttributes.Color := clWhite;
              Chat_RichEdit.SelText := #13 + '   •   ' + BufferTemp;
            end;

            SendMessage(Chat_RichEdit.Handle, WM_VSCROLL, SB_BOTTOM, 0);

            if not(Visible) then
            begin
              PlaySound('BEEP', 0, SND_RESOURCE or SND_ASYNC);
              Show;
            end;

            if not(Active) then
            begin
              PlaySound('BEEP', 0, SND_RESOURCE or SND_ASYNC);
              FlashWindow(FMain.Handle, true);
              FlashWindow(FChat.Handle, true);
            end;
          end;
        end);
    end;

    // Share Files
    // Request Folder List
    Position := Pos('<|GETFOLDERS|>', Buffer);
    if Position > 0 then
    begin
      BufferTemp := Buffer;
      Delete(BufferTemp, 1, Position + 13);
      BufferTemp := Copy(BufferTemp, 1, Pos('<|END|>', BufferTemp) - 1);
      Socket.SendText('<|REDIRECT|><|FOLDERLIST|>' + ListFolders(BufferTemp) + '<|ENDFOLDERLIST|>');
    end;

    // Request Files List
    Position := Pos('<|GETFILES|>', Buffer);
    if Position > 0 then
    begin
      BufferTemp := Buffer;
      Delete(BufferTemp, 1, Position + 11);
      BufferTemp := Copy(BufferTemp, 1, Pos('<|END|>', BufferTemp) - 1);
      Socket.SendText('<|REDIRECT|><|FILESLIST|>' + ListFiles(BufferTemp, '*.*') + '<|ENDFILESLIST|>');
    end;

    // Receive Folder List
    Position := Pos('<|FOLDERLIST|>', Buffer);
    if Position > 0 then
    begin
      while Socket.Connected do
      begin
        if Buffer.Contains('<|ENDFOLDERLIST|>') then
          Break;

        if Socket.ReceiveLength > 0 then
          Buffer := Buffer + Socket.ReceiveText;

        Sleep(ProcessingSlack);
      end;

      BufferTemp := Buffer;
      Delete(BufferTemp, 1, Position + 13);
      FoldersAndFiles := TStringList.Create;
      FoldersAndFiles.Text := Copy(BufferTemp, 1, Pos('<|ENDFOLDERLIST|>', BufferTemp) - 1);
      FoldersAndFiles.Sort;

      Synchronize(
        procedure
        var
          i: Integer;
        begin
          FShareFiles.ShareFiles_ListView.Clear;

          for i := 0 to FoldersAndFiles.count - 1 do
          begin
            L := FShareFiles.ShareFiles_ListView.Items.Add;
            if (FoldersAndFiles.Strings[i] = '..') then
            begin
              L.Caption := 'Return';
              L.ImageIndex := 0;
            end
            else
            begin
              L.Caption := FoldersAndFiles.Strings[i];
              L.ImageIndex := 1;
            end;
            FShareFiles.Caption := 'Share Files - ' + IntToStr(FShareFiles.ShareFiles_ListView.Items.count) + ' Items found';
          end;
        end);

      FreeAndNil(FoldersAndFiles);
      Socket.SendText('<|REDIRECT|><|GETFILES|>' + FShareFiles.Directory_Edit.Text + '<|END|>');
    end;

    // Receive Files List
    Position := Pos('<|FILESLIST|>', Buffer);
    if Position > 0 then
    begin
      while Socket.Connected do
      begin
        if Buffer.Contains('<|ENDFILESLIST|>') then
          Break;

        if Socket.ReceiveLength > 0 then
          Buffer := Buffer + Socket.ReceiveText;

        Sleep(ProcessingSlack);
      end;

      BufferTemp := Buffer;
      Delete(BufferTemp, 1, Position + 12);
      FoldersAndFiles := TStringList.Create;
      FoldersAndFiles.Text := Copy(BufferTemp, 1, Pos('<|ENDFILESLIST|>', BufferTemp) - 1);
      FoldersAndFiles.Sort;

      Synchronize(
        procedure
        var
          i: Integer;
        begin
          for i := 0 to FoldersAndFiles.count - 1 do
          begin
            L := FShareFiles.ShareFiles_ListView.Items.Add;
            L.Caption := FoldersAndFiles.Strings[i];
            Extension := LowerCase(ExtractFileExt(L.Caption));

            if (Extension = '.exe') then
              L.ImageIndex := 3
            else if (Extension = '.txt') then
              L.ImageIndex := 4
            else if (Extension = '.rar') then
              L.ImageIndex := 5
            else if (Extension = '.mp3') then
              L.ImageIndex := 6
            else if (Extension = '.zip') then
              L.ImageIndex := 7
            else if (Extension = '.jpg') then
              L.ImageIndex := 8
            else if (Extension = '.bat') then
              L.ImageIndex := 9
            else if (Extension = '.xml') then
              L.ImageIndex := 10
            else if (Extension = '.sql') then
              L.ImageIndex := 11
            else if (Extension = '.html') then
              L.ImageIndex := 12
            else if (Extension = '.xls') then
              L.ImageIndex := 13
            else if (Extension = '.png') then
              L.ImageIndex := 14
            else if (Extension = '.doc') then
              L.ImageIndex := 15
            else if (Extension = '.docx') then
              L.ImageIndex := 15
            else if (Extension = '.pdf') then
              L.ImageIndex := 16
            else if (Extension = '.dll') then
              L.ImageIndex := 17
            else
              L.ImageIndex := 2;

            FShareFiles.Caption := 'Share Files - ' + IntToStr(FShareFiles.ShareFiles_ListView.Items.count) + ' Items found';
          end;

          FShareFiles.Directory_Edit.Enabled := true;
          FShareFiles.Caption := 'Share Files - ' + IntToStr(FShareFiles.ShareFiles_ListView.Items.count) + ' Items found';
        end);

      FreeAndNil(FoldersAndFiles);
    end;

    Position := Pos('<|UPLOADPROGRESS|>', Buffer);
    if Position > 0 then
    begin
      BufferTemp := Buffer;
      Delete(BufferTemp, 1, Position + 17);
      BufferTemp := Copy(BufferTemp, 1, Pos('<|END|>', BufferTemp) - 1);

      Synchronize(
        procedure
        begin
          FShareFiles.Upload_ProgressBar.Position := StrToInt(BufferTemp);
          FShareFiles.SizeUpload_Label.Caption := 'Size: ' + GetSize(FShareFiles.Upload_ProgressBar.Position) + ' / ' + GetSize(FShareFiles.Upload_ProgressBar.Max);
        end);
    end;

    if Buffer.Contains('<|UPLOADCOMPLETE|>') then
    begin
      Synchronize(
        procedure
        begin
          FShareFiles.Upload_ProgressBar.Position := 0;
          FShareFiles.Upload_BitBtn.Enabled := true;
          FShareFiles.Directory_Edit.Enabled := False;
          FShareFiles.SizeUpload_Label.Caption := 'Size: 0 B / 0 B';
        end);

      FMain.Main_Socket.Socket.SendText('<|REDIRECT|><|GETFOLDERS|>' + FShareFiles.Directory_Edit.Text + '<|END|>');

      Synchronize(
        procedure
        begin
          MessageBox(0, 'The file was successfully sent.', 'AllaKore Remote - Share Files', MB_ICONASTERISK + MB_TOPMOST);
        end);
    end;

    Position := Pos('<|DOWNLOADFILE|>', Buffer);
    if Position > 0 then
    begin
      BufferTemp := Buffer;
      Delete(BufferTemp, 1, Position + 15);
      BufferTemp := Copy(BufferTemp, 1, Pos('<|END|>', BufferTemp) - 1);
      FileToUpload := TFileStream.Create(BufferTemp, fmOpenRead);
      FMain.Files_Socket.Socket.SendText('<|SIZE|>' + IntToStr(FileToUpload.Size) + '<|END|>');
      FMain.Files_Socket.Socket.SendStream(FileToUpload);
    end;
  end;

end;

{ TFmain }

procedure TFmain.ClearConnection;
begin
  FMain.ResolutionTargetWidth := 986;
  FMain.ResolutionTargetHeight := 600;

  with FRemoteScreen do
  begin
    MouseIcon_Image.Picture.Assign(MouseIcon_unchecked_Image.Picture);
    KeyboardIcon_Image.Picture.Assign(KeyboardIcon_unchecked_Image.Picture);
    ResizeIcon_Image.Picture.Assign(ResizeIcon_checked_Image.Picture);

    MouseRemote_CheckBox.Checked := False;
    KeyboardRemote_CheckBox.Checked := False;
    Resize_CheckBox.Checked := true;
    CaptureKeys_Timer.Enabled := False;

    Screen_Image.Picture.Assign(ScreenStart_Image.Picture);

    Width := 986;
    Height := 646;
  end;

  with FShareFiles do
  begin
    Download_BitBtn.Enabled := true;
    Upload_BitBtn.Enabled := true;
    Download_ProgressBar.Position := 0;
    Upload_ProgressBar.Position := 0;
    SizeDownload_Label.Caption := 'Size: 0 B / 0 B';
    SizeUpload_Label.Caption := 'Size: 0 B / 0 B';

    Directory_Edit.Text := 'C:\';
    ShareFiles_ListView.Items.Clear;

    if (Visible) then
      Close;
  end;

  with FChat do
  begin
    Width := 230;
    Height := 340;

    Left := Screen.WorkAreaWidth - Width;
    Top := Screen.WorkAreaHeight - Height;

    Chat_RichEdit.Clear;
    YourText_Edit.Clear;
    Chat_RichEdit.SelStart := Chat_RichEdit.GetTextLen;
    Chat_RichEdit.SelAttributes.Style := [fsBold];
    Chat_RichEdit.SelAttributes.Color := clWhite;
    Chat_RichEdit.SelText := 'AllaKore Remote - Chat' + #13 + #13;

    FirstMessage := true;
    LastMessageAreYou := False;

    if (Visible) then
      Close;
  end;
end;

procedure TFmain.Clipboard_TimerTimer(Sender: TObject);
begin
  try
    try
      Clipboard.Open;

      if (Clipboard.HasFormat(CF_TEXT)) then
      begin
        if not(OldClipboardText = Clipboard.AsText) then
        begin
          OldClipboardText := Clipboard.AsText;
          Main_Socket.Socket.SendText('<|REDIRECT|><|CLIPBOARD|>' + Clipboard.AsText + '<|END|>');
        end;
      end;
    except
    end;
  finally
    Clipboard.Close;
  end;
end;

procedure TFmain.CloseSockets;
begin
   Main_Socket.Close;
  Desktop_Socket.Close;
  Keyboard_Socket.Close;
  Files_Socket.Close;

  Viewer := False;

  // Restore Wallpaper
  if Accessed then
  begin
    Accessed := False;
    // ChangeWallpaper(OldWallpaper);
  end;

  // Show main form and repaint
  if not Visible then
  begin
    Show;
    Repaint;
  end;

  ClearConnection;
end;

procedure TFmain.Connect_BitBtnClick(Sender: TObject);
begin
  if not(TargetID_MaskEdit.Text = '   -   -   ') then
  begin
    if (TargetID_MaskEdit.Text = MyID) then
      MessageBox(0, 'You can not connect with yourself!', 'AllaKore Remote', MB_ICONASTERISK + MB_TOPMOST)
    else
    begin
      Main_Socket.Socket.SendText('<|FINDID|>' + TargetID_MaskEdit.Text + '<|END|>');
      TargetID_MaskEdit.Enabled := False;
      Connect_BitBtn.Enabled := False;
      Status_Image.Picture.Assign(Image1.Picture);
      Status_Label.Caption := 'Finding the ID...';
    end;
  end;
end;

procedure TFmain.Desktop_SocketConnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
    // If connected, then send MyID for identification on Server
  Socket.SendText('<|DESKTOPSOCKET|>' + MyID + '<|END|>');
  Thread_Connection_Desktop := TThread_Connection_Desktop.Create(Socket);
end;

procedure TFmain.Desktop_SocketError(Sender: TObject; Socket: TCustomWinSocket;
  ErrorEvent: TErrorEvent; var ErrorCode: Integer);
begin
    ErrorCode := 0;
end;

procedure TFmain.Files_SocketConnect(Sender: TObject; Socket: TCustomWinSocket);
begin
   Socket.SendText('<|FILESSOCKET|>' + MyID + '<|END|>');
  Thread_Connection_Files := TThread_Connection_Files.Create(Socket);
end;

procedure TFmain.Files_SocketError(Sender: TObject; Socket: TCustomWinSocket;
  ErrorEvent: TErrorEvent; var ErrorCode: Integer);
begin
     ErrorCode := 0;
end;

procedure TFmain.FormCreate(Sender: TObject);

  var
  _Host: AnsiString;
  _Port: Integer;
begin
  // Insert version on Caption of the Form
  Caption := Caption + ' - ' + GetAppVersionStr;

  // Reads two exe params - host and port. If not supplied uses constants. to use: client.exe HOST PORT, for ex. AllaKore_Remote_Client.exe 192.168.16.201 3398
  if (ParamStr(1) <> '') then
    _Host := ParamStr(1)
  else
    _Host := Host;

  if (ParamStr(2) <> '') then
    _Port := StrToIntDef(ParamStr(2), Port)
  else
    _Port := Port;

  // Define Host and Port
  Main_Socket := TClientSocket.Create(self);
  Main_Socket.Active := False;
  Main_Socket.ClientType := ctNonBlocking;
  Main_Socket.OnConnecting := Main_SocketConnecting;
  Main_Socket.OnConnect := Main_SocketConnect;
  Main_Socket.OnDisconnect := Main_SocketDisconnect;
  Main_Socket.OnError := Main_SocketError;
  Main_Socket.Host := _Host;
  Main_Socket.Port := _Port;

  Desktop_Socket := TClientSocket.Create(self);
  Desktop_Socket.Active := False;
  Desktop_Socket.ClientType := ctNonBlocking;
  Desktop_Socket.OnConnect := Desktop_SocketConnect;
  Desktop_Socket.OnError := Desktop_SocketError;
  Desktop_Socket.Host := _Host;
  Desktop_Socket.Port := _Port;

  Keyboard_Socket := TClientSocket.Create(self);
  Keyboard_Socket.Active := False;
  Keyboard_Socket.ClientType := ctNonBlocking;
  Keyboard_Socket.OnConnect := Keyboard_SocketConnect;
  Keyboard_Socket.OnError := Keyboard_SocketError;
  Keyboard_Socket.Host := _Host;
  Keyboard_Socket.Port := _Port;

  Files_Socket := TClientSocket.Create(self);
  Files_Socket.Active := False;
  Files_Socket.ClientType := ctNonBlocking;
  Files_Socket.OnConnect := Files_SocketConnect;
  Files_Socket.OnError := Files_SocketError;
  Files_Socket.Host := _Host;
  Files_Socket.Port := _Port;

  ResolutionTargetWidth := 986;
  ResolutionTargetHeight := 600;

  MyPing := 256;

  SetOffline;
  Reconnect;
end;

procedure TFmain.Keyboard_SocketConnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  Socket.SendText('<|KEYBOARDSOCKET|>' + MyID + '<|END|>');
  Thread_Connection_Keyboard := TThread_Connection_Keyboard.Create(Socket);
end;

procedure TFmain.Keyboard_SocketError(Sender: TObject; Socket: TCustomWinSocket;
  ErrorEvent: TErrorEvent; var ErrorCode: Integer);
begin
    ErrorCode := 0;
end;

procedure TFmain.Main_SocketConnect(Sender: TObject; Socket: TCustomWinSocket);
begin
   Status_Image.Picture.Assign(Image3.Picture);
  Status_Label.Caption := 'You are connected!';
  Timeout := 0;
  Timeout_Timer.Enabled := true;
  Socket.SendText('<|MAINSOCKET|>');
  Thread_Connection_Main := TThread_Connection_Main.Create(Socket);
end;

procedure TFmain.Main_SocketConnecting(Sender: TObject;
  Socket: TCustomWinSocket);
begin
    Status_Image.Picture.Assign(Image1.Picture);
   Status_Label.Caption := 'Connecting to Server...';
end;

procedure TFmain.Main_SocketDisconnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
   if (FRemoteScreen.Visible) then
    FRemoteScreen.Close;

  SetOffline;

  Status_Image.Picture.Assign(Image2.Picture);
  Status_Label.Caption := 'Failed connect to Server.';

  CloseSockets;
end;

procedure TFmain.Main_SocketError(Sender: TObject; Socket: TCustomWinSocket;
  ErrorEvent: TErrorEvent; var ErrorCode: Integer);
begin
    ErrorCode := 0;

  if (FRemoteScreen.Visible) then
    FRemoteScreen.Close;

  SetOffline;

  Status_Image.Picture.Assign(Image2.Picture);
  Status_Label.Caption := 'Failed connect to Server.';

  CloseSockets;
end;

procedure TFmain.Reconnect;
begin
  if not Main_Socket.Active then
    Main_Socket.Active := true;
end;

procedure TFmain.ReconnectSecundarySockets;
begin
   Viewer := False;

  Desktop_Socket.Close;
  Keyboard_Socket.Close;
  Files_Socket.Close;

  // Workaround to wait for disconnection
  Sleep(1000);

  Desktop_Socket.Active := true;
  Keyboard_Socket.Active := true;
  Files_Socket.Active := true;
end;

procedure TFmain.Reconnect_TimerTimer(Sender: TObject);
begin
    Reconnect;
end;

procedure TFmain.SetOffline;
begin
   YourID_Edit.Text := 'Offline';
  YourID_Edit.Enabled := False;

  YourPassword_Edit.Text := 'Offline';
  YourPassword_Edit.Enabled := False;

  TargetID_MaskEdit.Clear;
  TargetID_MaskEdit.Enabled := False;

  Connect_BitBtn.Enabled := False;

  Timeout_Timer.Enabled := False;
  Clipboard_Timer.Enabled := False;
end;

procedure TFmain.SetOnline;
begin
   YourID_Edit.Text := MyID;
  YourID_Edit.Enabled := true;

  YourPassword_Edit.Text := MyPassword;
  YourPassword_Edit.Enabled := true;

  TargetID_MaskEdit.Clear;
  TargetID_MaskEdit.Enabled := true;

  Connect_BitBtn.Enabled := true;
end;

procedure TFmain.TargetID_MaskEditKeyPress(Sender: TObject; var Key: Char);
begin
   if Key = #13 then
  begin
    Connect_BitBtn.Click;
    Key := #0;
  end
end;

procedure TFmain.Timeout_TimerTimer(Sender: TObject);
begin
     if (Timeout > ConnectionTimeout) then
  begin
    if (FRemoteScreen.Visible) then
      FRemoteScreen.Close
    else
    begin
      FMain.SetOffline;
      FMain.CloseSockets;
      FMain.Reconnect;
    end;
  end;
  Inc(Timeout);
end;

procedure TFmain.YourID_EditKeyPress(Sender: TObject; var Key: Char);
begin
    if Key = #13 then
  begin
    Connect_BitBtn.Click;
    Key := #0;
  end
end;

{ TThread_Connection_Desktop }

constructor TThread_Connection_Desktop.Create(aSocket: TCustomWinSocket);
begin
    inherited Create(False);
  Socket := aSocket;
  Accessed := False;
  FreeOnTerminate := true;
end;

procedure TThread_Connection_Desktop.Execute;
var
  Position: Integer;
  Buffer: string;
  TempBuffer: string;
  MyFirstBmp: TMemoryStream;
  PackStream: TMemoryStream;
  MyTempStream: TMemoryStream;
  UnPackStream: TMemoryStream;
  MyCompareBmp: TMemoryStream;
  MySecondBmp: TMemoryStream;
  hDesktop: HDESK;
begin
  inherited;

  MyFirstBmp := TMemoryStream.Create;
  UnPackStream := TMemoryStream.Create;
  MyTempStream := TMemoryStream.Create;
  MySecondBmp := TMemoryStream.Create;
  MyCompareBmp := TMemoryStream.Create;
  PackStream := TMemoryStream.Create;

  while true do
  begin
    Sleep(ProcessingSlack); // Avoids using 100% CPU

    if (Socket = nil) or not(Socket.Connected) then
      Break;

    if Socket.ReceiveLength < 1 then
      Continue;

    Buffer := Buffer + Socket.ReceiveText; // Accommodates in memory all images that are being received and not processed. This helps in smoothing and mapping so that changes in the wrong places do not occur.

    Position := Pos('<|GETFULLSCREENSHOT|>', Buffer);
    if Position > 0 then
    begin
      Delete(Buffer, 1, Position + 20);
      ResolutionWidth := Screen.Width;
      ResolutionHeight := Screen.Height;
      FMain.Main_Socket.Socket.SendText('<|REDIRECT|><|RESOLUTION|>' + IntToStr(Screen.Width) + '<|>' + IntToStr(Screen.Height) + '<|END|>');

      MyFirstBmp.Clear;
      UnPackStream.Clear;
      MyTempStream.Clear;
      MySecondBmp.Clear;
      MyCompareBmp.Clear;
      PackStream.Clear;

      Synchronize(
        procedure
        begin
          GetScreenToMemoryStream(False, MyFirstBmp);
        end);

      MyFirstBmp.Position := 0;
      PackStream.LoadFromStream(MyFirstBmp);
      CompressStreamWithZLib(PackStream);
      PackStream.Position := 0;
      Socket.SendText('<|IMAGE|>' + MemoryStreamToString(PackStream) + '<|END|>');

      while true do
      begin
        Sleep(16);

        if (Socket = nil) or not(Socket.Connected) then
          Break;

        // EUREKA: This is the responsable to interact with UAC. But we need run
        // the software on SYSTEM account to work.
        hDesktop := OpenInputDesktop(0, true, MAXIMUM_ALLOWED);
        if hDesktop <> 0 then
        begin
          SetThreadDesktop(hDesktop);
          CloseHandle(hDesktop);
        end;

        // Workaround to run on change from secure desktop to default.
        try
          GetScreenToMemoryStream(False, MySecondBmp);
        except
          Synchronize(
            procedure
            begin
              GetScreenToMemoryStream(False, MySecondBmp);
            end);
        end;

        // Check if the resolution has been changed
        if MyFirstBmp.Size <> MySecondBmp.Size then
          FMain.Main_Socket.Socket.SendText('<|REDIRECT|><|RESOLUTION|>' + IntToStr(Screen.Width) + '<|>' + IntToStr(Screen.Height) + '<|END|>');

        CompareStream(MyFirstBmp, MySecondBmp, MyCompareBmp);
        MyCompareBmp.Position := 0;
        PackStream.LoadFromStream(MyCompareBmp);
        CompressStreamWithZLib(PackStream);
        PackStream.Position := 0;

        if (Socket <> nil) and (Socket.Connected) then
        begin
          while Socket.SendText('<|IMAGE|>' + MemoryStreamToString(PackStream) + '<|END|>') < 0 do
            Sleep(ProcessingSlack);
        end;
      end;
    end;

    // Processes all Buffer that is in memory.
    while Buffer.Contains('<|END|>') do
    begin
      Delete(Buffer, 1, Pos('<|IMAGE|>', Buffer) + 8);
      Position := Pos('<|END|>', Buffer);
      TempBuffer := Copy(Buffer, 1, Position - 1);
      MyTempStream.Write(AnsiString(TempBuffer)[1], Length(TempBuffer));
      Delete(Buffer, 1, Position + 6); // Clears the memory of the image that was processed.
      MyTempStream.Position := 0;
      UnPackStream.LoadFromStream(MyTempStream);
      DeCompressStreamWithZLib(UnPackStream);

      if (MyFirstBmp.Size = 0) then
      begin
        MyFirstBmp.LoadFromStream(UnPackStream);
        MyFirstBmp.Position := 0;

        Synchronize(
          procedure
          begin
            FRemoteScreen.Screen_Image.Picture.Bitmap.LoadFromStream(MyFirstBmp);

            if (FRemoteScreen.Resize_CheckBox.Checked) then
              ResizeBmp(FRemoteScreen.Screen_Image.Picture.Bitmap, FRemoteScreen.Screen_Image.Width, FRemoteScreen.Screen_Image.Height);

            FRemoteScreen.Caption := 'AllaKore Remote (Ping: ' + IntToStr(FMain.MyPing) + ' ms)';
          end);
      end
      else
      begin
        MyCompareBmp.Clear;
        MySecondBmp.Clear;
        MyCompareBmp.LoadFromStream(UnPackStream);
        ResumeStream(MyFirstBmp, MySecondBmp, MyCompareBmp);

        Synchronize(
          procedure
          begin
            FRemoteScreen.Screen_Image.Picture.Bitmap.LoadFromStream(MySecondBmp);

            if (FRemoteScreen.Resize_CheckBox.Checked) then
              ResizeBmp(FRemoteScreen.Screen_Image.Picture.Bitmap, FRemoteScreen.Screen_Image.Width, FRemoteScreen.Screen_Image.Height);

            FRemoteScreen.Caption := 'AllaKore Remote (Ping: ' + IntToStr(FMain.MyPing) + ' ms)';
          end);
      end;

      UnPackStream.Clear;
      MyTempStream.Clear;
      MySecondBmp.Clear;
      MyCompareBmp.Clear;
      PackStream.Clear;
    end;
  end;

  FreeAndNil(MyFirstBmp);
  FreeAndNil(UnPackStream);
  FreeAndNil(MyTempStream);
  FreeAndNil(MySecondBmp);
  FreeAndNil(MyCompareBmp);
  FreeAndNil(PackStream);

end;

{ TThread_Connection_Keyboard }

constructor TThread_Connection_Keyboard.Create(aSocket: TCustomWinSocket);
begin
     inherited Create(False);
  Socket := aSocket;
  FreeOnTerminate := true;
end;

procedure TThread_Connection_Keyboard.Execute;

  var
  Buffer: string;
  hDesktop: HDESK;
begin
  while true do
  begin
    Sleep(ProcessingSlack); // Avoids using 100% CPU

    if (Socket = nil) or not(Socket.Connected) then
      Break;

    if Socket.ReceiveLength < 1 then
      Continue;

    Buffer := Socket.ReceiveText;

    // EUREKA: This is the responsable to interact with UAC. But we need run
    // the software on SYSTEM account to work.
    hDesktop := OpenInputDesktop(0, true, MAXIMUM_ALLOWED);
    if hDesktop <> 0 then
    begin
      SetThreadDesktop(hDesktop);
      CloseHandle(hDesktop);
    end;

    // Combo Keys
    if Buffer.Contains('<|ALTDOWN|>') then
    begin
      Buffer := StringReplace(Buffer, '<|ALTDOWN|>', '', [rfReplaceAll]);
      keybd_event(18, 0, 0, 0);
    end;

    if Buffer.Contains('<|ALTUP|>') then
    begin
      Buffer := StringReplace(Buffer, '<|ALTUP|>', '', [rfReplaceAll]);
      keybd_event(18, 0, KEYEVENTF_KEYUP, 0);
    end;

    if Buffer.Contains('<|CTRLDOWN|>') then
    begin
      Buffer := StringReplace(Buffer, '<|CTRLDOWN|>', '', [rfReplaceAll]);
      keybd_event(17, 0, 0, 0);
    end;

    if Buffer.Contains('<|CTRLUP|>') then
    begin
      Buffer := StringReplace(Buffer, '<|CTRLUP|>', '', [rfReplaceAll]);
      keybd_event(17, 0, KEYEVENTF_KEYUP, 0);
    end;

    if Buffer.Contains('<|SHIFTDOWN|>') then
    begin
      Buffer := StringReplace(Buffer, '<|SHIFTDOWN|>', '', [rfReplaceAll]);
      keybd_event(16, 0, 0, 0);
    end;

    if Buffer.Contains('<|SHIFTUP|>') then
    begin
      Buffer := StringReplace(Buffer, '<|SHIFTUP|>', '', [rfReplaceAll]);
      keybd_event(16, 0, KEYEVENTF_KEYUP, 0);
    end;

    if Buffer.Contains('?') then
    begin
      if GetKeyState(VK_SHIFT) < 0 then
      begin
        keybd_event(16, 0, KEYEVENTF_KEYUP, 0);
        SendKeys(PWideChar(Buffer), False);
        keybd_event(16, 0, 0, 0);
      end;
    end
    else
      SendKeys(PWideChar(Buffer), False);
  end;

end;

{ TThread_Connection_Files }

constructor TThread_Connection_Files.Create(aSocket: TCustomWinSocket);
begin
     inherited Create(False);
  Socket := aSocket;
  FreeOnTerminate := true;
end;

procedure TThread_Connection_Files.Execute;
var
  Position: Integer;
  FileSize: Int64;
  ReceivingFile: Boolean;
  Buffer: string;
  BufferTemp: string;
  FileStream: TFileStream;
begin
  inherited;

  ReceivingFile := False;
  FileStream := nil;

  while true do
  begin
    Sleep(ProcessingSlack); // Avoids using 100% CPU

    if (Socket = nil) or not(Socket.Connected) then
      Break;

    if Socket.ReceiveLength < 1 then
      Continue;

    Buffer := Socket.ReceiveText;

    if not(ReceivingFile) then
    begin
      Position := Pos('<|DIRECTORYTOSAVE|>', Buffer);
      if Position > 0 then
      begin
        BufferTemp := Buffer;
        Delete(BufferTemp, 1, Position + 18);
        Position := Pos('<|>', BufferTemp);
        BufferTemp := Copy(BufferTemp, 1, Position - 1);
        FShareFiles.DirectoryToSaveFile := BufferTemp;
      end;

      Position := Pos('<|SIZE|>', Buffer);
      if Position > 0 then
      begin
        BufferTemp := Buffer;
        Delete(BufferTemp, 1, Position + 7);
        BufferTemp := Copy(BufferTemp, 1, Pos('<|END|>', BufferTemp) - 1);
        FileSize := StrToInt(BufferTemp);
        FileStream := TFileStream.Create(FShareFiles.DirectoryToSaveFile + '.tmp', fmCreate or fmOpenReadWrite);

        if (FMain.Viewer) then
        begin
          Synchronize(
            procedure
            begin
              FShareFiles.Download_ProgressBar.Max := FileSize;
              FShareFiles.Download_ProgressBar.Position := 0;
              FShareFiles.SizeDownload_Label.Caption := 'Size: ' + GetSize(FileStream.Size) + ' / ' + GetSize(FileSize);
            end);
        end;

        Delete(Buffer, 1, Pos('<|END|>', Buffer) + 6);
        ReceivingFile := true;
      end;
    end;

    if (Length(Buffer) > 0) and (ReceivingFile) then
    begin
      FileStream.Write(AnsiString(Buffer)[1], Length(Buffer));

      if (FMain.Viewer) then
      begin
        Synchronize(
          procedure
          begin
            FShareFiles.Download_ProgressBar.Position := FileStream.Size;
            FShareFiles.SizeDownload_Label.Caption := 'Size: ' + GetSize(FileStream.Size) + ' / ' + GetSize(FileSize);
          end);
      end
      else
      begin
        while FMain.Main_Socket.Socket.SendText('<|REDIRECT|><|UPLOADPROGRESS|>' + IntToStr(FileStream.Size) + '<|END|>') < 0 do
          Sleep(ProcessingSlack);
      end;

      if (FileStream.Size = FileSize) then
      begin
        FreeAndNil(FileStream);

        if (FileExists(FShareFiles.DirectoryToSaveFile)) then
          DeleteFile(FShareFiles.DirectoryToSaveFile);

        RenameFile(FShareFiles.DirectoryToSaveFile + '.tmp', FShareFiles.DirectoryToSaveFile);

        if not(FMain.Viewer) then
          FMain.Main_Socket.Socket.SendText('<|REDIRECT|><|UPLOADCOMPLETE|>')
        else
        begin
          Synchronize(
            procedure
            begin
              FShareFiles.Download_ProgressBar.Position := 0;
              FShareFiles.Download_BitBtn.Enabled := true;
              FShareFiles.SizeDownload_Label.Caption := 'Size: 0 B / 0 B';
              MessageBox(0, 'The download was completed successfully.', 'AllaKore Remote - Share Files', MB_ICONASTERISK + MB_TOPMOST);
            end);
        end;

        ReceivingFile := False;
      end;
    end;
  end;

end;

end.
