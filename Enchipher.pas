unit Enchipher;

interface

const
  ENGLISH_ALPHABET : array[0..25] of char = ('A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P' ,'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z');
  RUSSIAN_ALPHABET : array[0..32] of char = ('�', '�', '�', '�', '�', '�', '�', '�', '�', '�', '�', '�', '�', '�', '�', '�', '�', '�', '�', '�', '�', '�', '�', '�', '�', '�', '�', '�', '�', '�', '�', '�', '�');

type
  TAlphabet = array of char;

function GetEnchipheredText(const alphabet : TAlphabet; sourceText, key : string; needChipher : boolean) : string;
procedure Analize(var enchipheredText : string);

implementation

Uses
  StringProcessing, System.SysUtils;

type
  TStatisticItem = array[1..2] of integer;

  TGCDTempStat = record
    target : string[255];
    staticLeft, scanLeft, gcd : integer;
  end;

  TStatisticTable = record
    gcd : integer;
    frequency : integer;
  end;
var
  statisticTable : array of TStatisticItem;
{//��������� �������� ������������ �������
procedure CreateCipherTable(const key : string);

begin
  SetLength(cipherTable, Length(key));
  FillCipherTable(cipherTable, key);
end;

//��������� ���������� ������������ �������
procedure FillCipherTable(var cipherTable : TCipherTable; const key : string);
var
  i : integer;
begin
  for i := 0 to Length(key) do
    FillCipherString(cipherTable[i], key[i]);
end;

//��������� ���������� ������ ������������ �������
procedure FillCipherString(var cipherString; const symbol : char);
var
  alphabet : array of char;
  position, i, alphabetShift : integer;
begin
  if StringProcessing.languageIsEnglish then
  begin
    alphabet := ENGLISH_ALPHABET;
    alphabetShift := 65

  end else
  begin
    alphabet := RUSSIAN_ALPHABET;
    alphabetShift := 128;
  end;

  position := ord(symbol) - alphabetShift;

  for i := position to StringProcessing.alphabetSize - 1 do
    cipherString[i - position] := alphabet[i];

  for i := 0 to ord(symbol) - 1 do
    cipherString[StringProcessing.alphabetSize - position - 1] := alphabet[i];
end;   }

//������� ���������� ��������������/�������������� �����

procedure FindSubString(const enchipheredText : string; subStringSize : integer); forward;
procedure CheckSubString(const enchipheredText : string; const staticLeft, scanLeft, subStringSize : integer); forward;
procedure SaveResults(const target : string; const staticLeft, scanLeft, gcd : integer); forward;
procedure AddDataToStatisticTable(var buffer : TGCDTempStat); forward;
procedure SortStatisticTable; forward;
procedure SaveStatisticToFile; forward;
function Evklid(a, b : integer) : integer; forward;

function GetEnchipheredText(const alphabet : TAlphabet; sourceText, key : string; needChipher : boolean) : string;
var
  resultText : string;
  i : integer;
begin
  SetLength(resultText, Length(sourceText));
  //������ ���������
  if needChipher then
    for i := 1 to Length(sourceText) do
      resultText[i] := alphabet[(ord(sourceText[i]) + ord(key[i mod Length(key)]) - 129) mod 26]
  //����� �����������
  else
    for i := 1 to Length(sourceText) do
      resultText[i] := alphabet[abs(ord(sourceText[i]) - ord(key[i mod Length(key)]) + 155) mod 26];

  Result := resultText;
end;

procedure Kasiski(const enchipheredText : string);
var
  i : integer;
begin
  for i := 3 to GetAlphabetSize do
    FindSubString(enchipheredText, i);
end;

procedure FindSubString(const enchipheredText : string; subStringSize : integer);
var
  staticLeft, staticRight, scanLeft, scanRight, i, dif, len : integer;
  flag : boolean;
begin
  staticLeft := 0;
  staticRight := staticLeft + subStringSize - 1;
  scanLeft := staticRight + 1;
  scanRight := scanLeft + subStringsize - 1;
  len := Length(enchipheredText);
  flag := true;

  while scanRight <= len - 1 do
  begin
    i := 1;
    for i := 1 to subStringSize - 1 do
      if (ord(enchipheredText[staticLeft]) - ord(enchipheredText[scanLeft]) <>
      ord(enchipheredText[staticLeft + i]) - ord(enchipheredText[scanLeft + i])) then
      begin
        flag := false;
        break;
      end;

    if flag then CheckSubString(enchipheredText, staticLeft, scanLeft, subStringSize);
    inc(scanLeft);
    inc(scanRight);
  end;
end;

procedure CheckSubString(const enchipheredText : string; const staticLeft, scanLeft, subStringSize : integer);
var
  gcd : integer;
  target : string;
begin
  gcd := Evklid(staticLeft, scanLeft);
  target := Copy(enchipheredText, staticLeft, scanLeft - staticLeft + 1);
  if gcd >= 3 then SaveResults(target, staticLeft, scanLeft, gcd);
  //Analize(enchipheredText);
end;

function Evklid(a, b : integer) : integer;
begin
  if a = b then Result := a
  else if (a > b) then Result := Evklid(a - b, b)
  else Result := Evklid(a, b - a);
end;

procedure SaveResults(const target : string; const staticLeft, scanLeft, gcd : integer);
var
  T : file of TGCDTempStat;
  buffer : TGCDTempStat;
begin
  AssignFile(T, 'GCDTempStat.ini');
  Reset(T);
  while not EOF(T) do
    Read(T, buffer);
  buffer.target := target;
  buffer.staticLeft := staticLeft;
  buffer.scanLeft := scanLeft;
  buffer.gcd := gcd;
  write(T, buffer);
  CloseFile(T);
end;

procedure Analize(var enchipheredText : string);
var
  T : file of TGCDTempStat;
  buffer : TGCDTempStat;
  i : integer;
begin
  AssignFile(T, 'GCDTempStat.ini');
  If fileExists('GCDTempStat.ini') then
  begin
    Reset(T);
    while not EOF(T) do
    begin
      Read(T, buffer);
      i := 0;
      AddDataToStatisticTable(buffer);
    end;
    CloseFile(T);
  end else exit;

  SortStatisticTable;
end;

procedure AddDataToStatisticTable(var buffer : TGCDTempStat);
var
  i : integer;
begin
  i := 0;
  while (i <= Length(statisticTable)) and (statisticTable[i, 1] <> buffer.gcd) do
    inc(i);

  if i > Length(statisticTable) then
  begin
    SetLength(statisticTable, i + 1);
    statisticTable[i + 1, 1] := buffer.gcd;
    statisticTable[i + 1, 1] := 1
  end else inc(statisticTable[i, 2]);
end;

procedure SortStatisticTable;
var
  mas : TStatisticItem;
  i, j, len : integer;
begin
  len := Length(statisticTable);
  for i := 0 to len - 2 do
    for j := i + 1 to len - 1 do
      if statisticTable[i, 1] * statisticTable[i, 2] > statisticTable[j, 1] * statisticTable[j, 2] then
      begin
        mas := statisticTable[i];
        statisticTable[i] := statisticTable[j];
        statisticTable[j] := mas;
      end;
  SaveStatisticToFile;
end;

procedure SaveStatisticToFile;
var
  F : file of TStatisticTable;
  i, len : integer;
  target : TStatisticTable;
begin
  AssignFile(F, 'GCDFrequencyStat.ini');
  Rewrite(F);
  len := Length(StatisticTable);
  for i := 0 to len - 1 do
  begin
    target.gcd := statisticTable[i, 1];
    target.frequency := statisticTable[i, 2];
  end;
end;

end.
