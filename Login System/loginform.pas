unit LoginForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ZConnection,
  ZDataset, BCrypt;

type
  { TLoginFrm }

  TLoginFrm = class(TForm)
    ButtonExit: TButton;
    ButtonDeleteAccount: TButton;
    ButtonChangeAccount: TButton;
    ButtonRegister: TButton;
    ButtonLogin: TButton;
    EditUsername: TEdit;
    EditPassword: TEdit;
    procedure ButtonChangeAccountClick(Sender: TObject);
    procedure ButtonDeleteAccountClick(Sender: TObject);
    procedure ButtonExitClick(Sender: TObject);
    procedure ButtonLoginClick(Sender: TObject);
    procedure ButtonRegisterClick(Sender: TObject);
  private
    procedure ClearFormFields;
    function ValidateUsername(const AUsername: string): Boolean;
    function ValidatePassword(const APassword: string): Boolean;
    procedure UpdateAccount(const AUsername, APassword: string);
    function ValidateCredentials(const APassword: string): Boolean;
    procedure SetupDatabaseConnection(Connection: TZConnection);
    procedure ExecuteUserQuery(Connection: TZConnection; Query: TZQuery; const Param: string);
    procedure CloseConnection(Connection: TZConnection; Query: TZQuery);
  public

  end;

var
  LoginFrm: TLoginFrm;

implementation

{$R *.lfm}

{ TLoginFrm }

procedure TLoginFrm.SetupDatabaseConnection(Connection: TZConnection);
begin
  Connection.Protocol := 'postgresql';
  Connection.User := 'admin';
  Connection.Password := 'admin';
  Connection.HostName := 'localhost';
  Connection.Port := 5432;
  Connection.Database := 'login';
  Connection.Connect;
end;

procedure TLoginFrm.ExecuteUserQuery(Connection: TZConnection; Query: TZQuery; const Param: string);
begin
  Query.Connection := Connection;
  Query.SQL.Text := 'SELECT ' + Param + ' FROM users WHERE username = :username';
  Query.ParamByName('username').AsString := EditUsername.Text;
  Query.Open;
end;

procedure TLoginFrm.CloseConnection(Connection: TZConnection; Query: TZQuery);
begin
  Query.Free;
  Connection.Disconnect;
  Connection.Free;
end;

procedure TLoginFrm.ButtonLoginClick(Sender: TObject);
var
  Connection: TZConnection;
  Query: TZQuery;
  Username: string;
  LoginAttempts: Integer;
begin
  Connection := TZConnection.Create(nil);
  SetupDatabaseConnection(Connection);

  Query := TZQuery.Create(nil);
  ExecuteUserQuery(Connection, Query, '*');

  if Query.RecordCount > 0 then
  begin
    Username := Query.FieldByName('username').AsString;
    LoginAttempts := Query.FieldByName('login_attempts').AsInteger;

    if (LoginAttempts >= 10) then
    begin
      ShowMessage('Blocked account.');
      Exit;
    end;

    if ValidateCredentials(EditPassword.Text) then
    begin
      ShowMessage('Successful login!');
      Query.SQL.Text := 'UPDATE users SET login_attempts = 0 WHERE username = :username';
      Query.ParamByName('username').AsString := Username;
      Query.ExecSQL;
    end
    else
    begin
      ShowMessage('Invalid credentials.');
      Query.SQL.Text := 'UPDATE users SET login_attempts = login_attempts + 1 WHERE username = :username';
      Query.ParamByName('username').AsString := Username;
      Query.ExecSQL;
    end;
  end
  else
    ShowMessage('Invalid credentials.');

  CloseConnection(Connection, Query);

  ClearFormFields;
end;

procedure TLoginFrm.ButtonRegisterClick(Sender: TObject);
var
  Connection: TZConnection;
  Query: TZQuery;
  HashedPassword: string;
  Username: string;
  NewUsername: string;
  NewPassword: string;
begin
  Connection := TZConnection.Create(nil);
  SetupDatabaseConnection(Connection);

  Query := TZQuery.Create(nil);
  ExecuteUserQuery(Connection, Query, '*');

  if Query.RecordCount > 0 then
  begin
    ShowMessage('Username already exists. Please choose a different username.');
    CloseConnection(Connection, Query);
    Exit;
  end;

  NewUsername := InputBox('New User', 'Enter a username:', '');
  if NewUsername = '' then
  begin
    ShowMessage('Username cannot be empty.');
    Exit;
  end;

  NewPassword := InputBox('New User', 'Enter a password:', '');
  if NewPassword = '' then
  begin
    ShowMessage('Password cannot be empty.');
    Exit;
  end;

  if not ValidateUsername(NewUsername) then
  begin
    ShowMessage('Username must be between 4 and 20 characters.');
    Exit;
  end;

  if not ValidatePassword(NewPassword) then
  begin
    ShowMessage('Password must be at least 6 characters long and contain at least one uppercase letter, one lowercase letter, one digit, and one special character.');
    Exit;
  end;

  Username := NewUsername;
  HashedPassword := TBCrypt.GenerateHash(NewPassword);

  Query.SQL.Text := 'INSERT INTO users (username, password, login_attempts) VALUES (:username, :password, 0)';
  Query.ParamByName('username').AsString := Username;
  Query.ParamByName('password').AsString := HashedPassword;
  Query.ExecSQL;

  ShowMessage('User registered successfully.');

  CloseConnection(Connection, Query);

  ClearFormFields;
end;

procedure TLoginFrm.ButtonChangeAccountClick(Sender: TObject);
var
  Connection: TZConnection;
  Query: TZQuery;
  NewUsername: string;
  NewPassword: string;
begin
  Connection := TZConnection.Create(nil);
  SetupDatabaseConnection(Connection);

  Query := TZQuery.Create(nil);
  ExecuteUserQuery(Connection, Query, '*');

  if Query.RecordCount > 0 then
  begin
    if ValidateCredentials(EditPassword.Text) then
    begin
      NewUsername := InputBox('Change Account', 'Enter a new username:', '');
      if NewUsername = '' then
      begin
        ShowMessage('Username cannot be empty.');
        CloseConnection(Connection, Query);
        Exit;
      end;

      NewPassword := InputBox('Change Account', 'Enter a new password:', '');
      if NewPassword = '' then
      begin
        ShowMessage('Password cannot be empty.');
        CloseConnection(Connection, Query);
        Exit;
      end;

      if not ValidateUsername(NewUsername) then
      begin
        ShowMessage('Username must be between 4 and 20 characters.');
        CloseConnection(Connection, Query);
        Exit;
      end;

      if not ValidatePassword(NewPassword) then
      begin
        ShowMessage('Password must be at least 6 characters long and contain at least one uppercase letter, one lowercase letter, one digit, and one special character.');
        CloseConnection(Connection, Query);
        Exit;
      end;

      UpdateAccount(NewUsername, NewPassword);

      ShowMessage('Account updated successfully.');
    end
    else
      ShowMessage('Invalid credentials.');
  end
  else
    ShowMessage('Invalid credentials.');

  CloseConnection(Connection, Query);

  ClearFormFields;
end;

procedure TLoginFrm.ButtonDeleteAccountClick(Sender: TObject);
var
  Connection: TZConnection;
  Query: TZQuery;
  Username: string;
  Password: string;
begin
  Connection := TZConnection.Create(nil);
  SetupDatabaseConnection(Connection);

  Query := TZQuery.Create(nil);
  ExecuteUserQuery(Connection, Query, 'username, password');

  if not Query.IsEmpty then
  begin
    Username := Query.FieldByName('username').AsString;
    Password := Query.FieldByName('password').AsString;

    if TBCrypt.CompareHash(EditPassword.Text, Password) then
    begin
      if MessageDlg('Confirmation', 'Are you sure you want to delete your account?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        Query.SQL.Text := 'DELETE FROM users WHERE username = :username';
        Query.ParamByName('username').AsString := Username;
        Query.ExecSQL;
        ShowMessage('Account deleted successfully.');
      end;
    end
    else
      ShowMessage('Invalid credentials.');
  end
  else
    ShowMessage('Invalid credentials.');

  CloseConnection(Connection, Query);

  ClearFormFields;
end;

procedure TLoginFrm.ButtonExitClick(Sender: TObject);
begin
  Close;
  Application.Terminate;
end;

procedure TLoginFrm.ClearFormFields;
begin
  EditUsername.Text := '';
  EditPassword.Text := '';
end;

function TLoginFrm.ValidateUsername(const AUsername: string): Boolean;
begin
  Result := (Length(AUsername) >= 4) and (Length(AUsername) <= 20);
end;

function TLoginFrm.ValidatePassword(const APassword: string): Boolean;
var
  HasLowercase: Boolean;
  HasUppercase: Boolean;
  HasDigit: Boolean;
  HasSpecialChar: Boolean;
  CharIndex: Integer;
  CurrentChar: Char;
begin
  Result := False;
  HasLowercase := False;
  HasUppercase := False;
  HasDigit := False;
  HasSpecialChar := False;

  if Length(APassword) < 6 then
    Exit;

  for CharIndex := 1 to Length(APassword) do
  begin
    CurrentChar := APassword[CharIndex];
    if (CurrentChar >= 'a') and (CurrentChar <= 'z') then
      HasLowercase := True
    else if (CurrentChar >= 'A') and (CurrentChar <= 'Z') then
      HasUppercase := True
    else if (CurrentChar >= '0') and (CurrentChar <= '9') then
      HasDigit := True
    else if CurrentChar in ['!', '@', '$', '%', '*', '?', '&'] then
      HasSpecialChar := True;
  end;

  Result := HasLowercase and HasUppercase and HasDigit and HasSpecialChar;
end;

procedure TLoginFrm.UpdateAccount(const AUsername, APassword: string);
var
  Connection: TZConnection;
  Query: TZQuery;
  HashedPassword: string;
  Username: string;
begin
  Connection := TZConnection.Create(nil);
  SetupDatabaseConnection(Connection);

  Query := TZQuery.Create(nil);
  ExecuteUserQuery(Connection, Query, '*');

  if Query.RecordCount > 0 then
  begin
    Username := Query.FieldByName('username').AsString;
    HashedPassword := TBCrypt.GenerateHash(APassword);
    Query.SQL.Text := 'UPDATE users SET username = :newusername, password = :newpassword WHERE username = :username';
    Query.ParamByName('newusername').AsString := AUsername;
    Query.ParamByName('newpassword').AsString := HashedPassword;
    Query.ParamByName('username').AsString := Username;
    Query.ExecSQL;
  end;

  CloseConnection(Connection, Query);
end;

function TLoginFrm.ValidateCredentials(const APassword: string): Boolean;
var
  Connection: TZConnection;
  Query: TZQuery;
  HashedPassword: string;
begin
  Connection := TZConnection.Create(nil);
  SetupDatabaseConnection(Connection);

  Query := TZQuery.Create(nil);
  ExecuteUserQuery(Connection, Query, 'password');

  if Query.RecordCount > 0 then
  begin
    HashedPassword := Query.FieldByName('password').AsString;
    Result := TBCrypt.CompareHash(APassword, HashedPassword);
  end
  else
    Result := False;

  CloseConnection(Connection, Query);
end;

end.
