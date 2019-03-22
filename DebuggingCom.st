//======= DebuggingCom =============================================================================
// Funktion         : Diese Quelle realisiert das Loggen eines Textstrings incl. 
//                    dem Senden der geloggten Texte über TCP/IP
//                    
//
// Benötigte Units  :   
// 
// Version          : 1.1
// Aenderungen      : Senden des Simotiondatums hinzugefügt über neuen Telegrammtyp (02) um kompatibel zu bleiben
//                    
// Aenderungsdatum  : 12.11.2012 C.Schoch
//
// Version          : 1.2
// Aenderungen      : Auf LCom Bibliotheksversion 1.2.0 angepasst
//                    
// Aenderungsdatum  : 06.03.2014 C.Schoch
//
// Version          : 1.3
// Aenderungen      : Speichern der Daten auf die Speicherkarte der Steuerung hinzugefügt
//                    Typen und Konstantendeklaration in den Implementationsteil verschoben
//                    Übergabe Telegrammtyp in MakeSendData verschoben damit Datenlänge nicht mehr manipuliert werden muss
//                    
// Aenderungsdatum  : 29.05.2014 C.Schoch
//
// Version          : 1.4
// Aenderungen      : Added posibility to send various data
//                    
// Aenderungsdatum  : 09.01.2017 C.Schoch
//----------------------------------------------------------------------------------------    

INTERFACE
    USELIB  LCom;
    USES GlobData;
     
    FUNCTION Add_Debug_String;
    FUNCTION Add_Debug_Data;
    FUNCTION Format;
    FUNCTION FormatI;
    FUNCTION FormatS;
    FUNCTION StoreData;
    FUNCTION GetStoreDataState;
    (*FUNCTION MakeSendData;
    FUNCTION Init_Stack;
    FUNCTION Add_Stack_Data;
    FUNCTION Get_Stack_Data;
    FUNCTION Delete_Stack_Data;
    FUNCTION_BLOCK ConvertHeader;
    FUNCTION_BLOCK ConvertReciveData;*) // Muss nicht exportiert werden, da nur Intern verwendet   
    PROGRAM ComDebug;

END_INTERFACE

IMPLEMENTATION
    VAR_GLOBAL CONSTANT
        ui_Header_Length            : UINT := 6;          // STX(1) + Laufnummer(1) + Trennbyte(1) + Telegrammtyp(2) + Trennbyte(1) 
        ui_Footer_Length            : UINT := 1;          // ETX(1)
        ui_Data_Length_String       : UINT := 90;         // Zeit(4) + Trennbyte(1) + Datum(4) + Trennbyte(1) + Text(80)
        ui_Data_Length_Data         : UINT := 1449;       // Zeit(4) + Trennbyte(1) + Datum(4) + Trennbyte(1) + Text(80) + Trennbyte(1) + Datentyp(2) + Trennbyte(1) + Daten(1355)
        ui_Data_Length_Pure_Data    : UINT := 1355;       
        
        ui_SendDataLength_Debug     : UINT := ui_Header_Length + ui_Data_Length_String + ui_Footer_Length;
        ui_SendDataLength_Data      : UINT := ui_Header_Length + ui_Data_Length_Data + ui_Footer_Length;
        ui_RecDataLength_Quit       : UINT := ui_Header_Length + ui_Footer_Length; // Quittierung erfolgt über Telegrammnummer
        
        ui_Max_Send_DataSize        : UINT := ui_SendDataLength_Data; // Muss gröster Datenlänge entsprechen die gesendet werden soll
        
        ui_Buffer_Size              : UINT := 200; // Größe des in der Steuerung gehaltenen Logs 
    END_VAR
   
    TYPE 
        e_DebugDataType : (E_STRING
            ,E_DATA
            );
        
        s_DebugDataType : STRUCT 
            e_DataType : e_DebugDataType;
            ui_DataSize : UINT;
            //
            tod_Time : TOD;
            dt_Date : DATE;
            str_Description : STRING[80];
            i_DataType : INT;
            aby_Data : ARRAY[0..ui_Data_Length_Pure_Data] OF BYTE;
        END_STRUCT;
        
        s_DebugDataBufferType : STRUCT
            Data : ARRAY[0..ui_Buffer_Size] OF s_DebugDataType;
            i_SendPointer : INT := -1;
        END_STRUCT;
        
        s_SendStackDataType : STRUCT      
            Data : ARRAY [0..ui_Max_Send_DataSize-1] OF BYTE;
            ui_Size : UINT;
            b_NeedsAck : BOOL;
        END_STRUCT;
        
        s_SendStackType : STRUCT      
            b_Full : BOOL;
            b_Empty : BOOL := TRUE;
            i_FillLevel : INT := -1;
            ui_TotalDataSize : UINT;
            i_SizeOfStack : INT := 150;
            Data : ARRAY [0..150] OF s_SendStackDataType;
        END_STRUCT;
        
        s_SendDataType : STRUCT      
            Data : ARRAY [0..LCOM_SEND_DATA_LENGTH-1] OF BYTE;
            ui_Size : UINT;
        END_STRUCT;
        
        eDebugStepSend : (STEP_WAIT_FOR_ACTIVATE := 1,
            STEP_WAIT_FOR_SEND_REQ := 2,
            STEP_WAIT_FOR_ACK := 3
            );
    END_TYPE

    VAR_GLOBAL
        b_Connected : BOOL;
        b_Error : BOOL;
        b_Enable_Com : BOOL := TRUE;
        b_StoreData : BOOL;
        udt_Debug : s_DebugDataBufferType;
        b_init : BOOL := TRUE; // Initialisierung
        dt_Time : DATE_AND_TIME;
        s_Unit_Data_Set_Cmd : StructRetUnitDataSetCommand;
        //udt_Stack_Send_Data : s_SendStackType;
    END_VAR
    
    VAR_GLOBAL RETAIN
        udi_DataSetIndex : UDINT;
    END_VAR
   
    FUNCTION Format : STRING[80]
//======= Format =============================================================================
// Funktion         : Diese Funktion fügt in eine Text anstelle von Platzhaltern (%s) bis zu 4 STRING-
//                 und bis zu 4 DINT- Werte ein
//                    
// Eingansparameter : 
//               str_Text          : zu schreibender Text (STRING[80])
//               str_Arg_1         : Argument 1 (STRING[80])
//               str_Arg_2         : Argument 2 (STRING[80])
//               str_Arg_3         : Argument 3 (STRING[80])
//               str_Arg_4         : Argument 4 (STRING[80])
//               di_Arg_1          : Argument 5 (DINT)
//               di_Arg_2          : Argument 6 (DINT)
//               di_Arg_3          : Argument 7 (DINT)
//               di_Arg_4          : Argument 8 (DINT)
//
// Rückgabewert : 
//               Format             : Ergebnis (STRING[80])
// 
// Unterprogramme   : keine
//
// Benötigte Units  :   
// 
// Aenderungen      : 
//
// Aenderungsdatum  :
//
//----------------------------------------------------------------------------------------    
        VAR_INPUT
            str_Text : STRING[80];
            str_Arg_1 : STRING[80];
            str_Arg_2 : STRING[80];
            str_Arg_3 : STRING[80];
            str_Arg_4 : STRING[80];
            di_Arg_1 : DINT := 0;
            di_Arg_2 : DINT := 0;
            di_Arg_3 : DINT := 0;
            di_Arg_4 : DINT := 0;
        END_VAR
        
        VAR
            i : INT;
        END_VAR
        
        Format := str_Text;
        i := FIND(in1 := Format ,in2 := '%s');
        IF i <> 0 THEN
            Format := REPLACE(in1 := Format ,in2 := str_Arg_1 ,l := 2 ,p := i);
        END_IF;
        i := FIND(in1 := Format ,in2 := '%s');
        IF i <> 0 THEN
            Format := REPLACE(in1 := Format ,in2 := str_Arg_2 ,l := 2 ,p := i);
        END_IF;
        i := FIND(in1 := Format ,in2 := '%s');
        IF i <> 0 THEN
            Format := REPLACE(in1 := Format ,in2 := str_Arg_3 ,l := 2 ,p := i);
        END_IF;
        i := FIND(in1 := Format ,in2 := '%s');
        IF i <> 0 THEN
            Format := REPLACE(in1 := Format ,in2 := str_Arg_4 ,l := 2 ,p := i);
        END_IF;
        
        i := FIND(in1 := Format ,in2 := '%d');
        IF i <> 0 THEN
            Format := REPLACE(in1 := Format ,in2 := DINT_TO_STRING(di_Arg_1) ,l := 2 ,p := i);
        END_IF;
        i := FIND(in1 := Format ,in2 := '%d');
        IF i <> 0 THEN
            Format := REPLACE(in1 := Format ,in2 := DINT_TO_STRING(di_Arg_2) ,l := 2 ,p := i);
        END_IF;
        i := FIND(in1 := Format ,in2 := '%d');
        IF i <> 0 THEN
            Format := REPLACE(in1 := Format ,in2 := DINT_TO_STRING(di_Arg_3) ,l := 2 ,p := i);
        END_IF;
        i := FIND(in1 := Format ,in2 := '%d');
        IF i <> 0 THEN
            Format := REPLACE(in1 := Format ,in2 := DINT_TO_STRING(di_Arg_4) ,l := 2 ,p := i);
        END_IF;
        
    END_FUNCTION
   
    FUNCTION FormatS : STRING[80]
//======= FormatS =============================================================================
// Funktion         : Diese Funktion fügt in eine Text anstelle von Platzhaltern (%s) bis zu 4 STRING-
//                 Werte ein
//                    
// Eingansparameter : 
//               str_Text           : zu schreibender Text (STRING[80])
//               str_Arg_1          : Argument 1 (STRING[80])
//               str_Arg_2          : Argument 2 (STRING[80])
//               str_Arg_3          : Argument 3 (STRING[80])
//               str_Arg_4          : Argument 4 (STRING[80])
//
// Rückgabewert : 
//               FormatS          : Ergebnis (STRING[80])
// 
// Unterprogramme   : keine
//
// Benötigte Units  :   
// 
// Aenderungen      : 
//
// Aenderungsdatum  :
//
//----------------------------------------------------------------------------------------    
        VAR_INPUT
            str_Text : STRING[80];
            str_Arg_1 : STRING[80];
            str_Arg_2 : STRING[80];
            str_Arg_3 : STRING[80];
            str_Arg_4 : STRING[80];
        END_VAR
        
        VAR
            i : INT;
        END_VAR
        
        FormatS := str_Text;
        i := FIND(in1 := FormatS ,in2 := '%s');
        IF i <> 0 THEN
            FormatS := REPLACE(in1 := FormatS ,in2 := str_Arg_1 ,l := 2 ,p := i);
        END_IF;
        i := FIND(in1 := FormatS ,in2 := '%s');
        IF i <> 0 THEN
            FormatS := REPLACE(in1 := FormatS ,in2 := str_Arg_2 ,l := 2 ,p := i);
        END_IF;
        i := FIND(in1 := FormatS ,in2 := '%s');
        IF i <> 0 THEN
            FormatS := REPLACE(in1 := FormatS ,in2 := str_Arg_3 ,l := 2 ,p := i);
        END_IF;
        i := FIND(in1 := FormatS ,in2 := '%s');
        IF i <> 0 THEN
            FormatS := REPLACE(in1 := FormatS ,in2 := str_Arg_4 ,l := 2 ,p := i);
        END_IF;
        
    END_FUNCTION
    
    FUNCTION FormatI : STRING[80]
//======= FormatI =============================================================================
// Funktion         : Diese Funktion fügt in eine Text anstelle von Platzhaltern (%d) bis zu 4 DINT-
//                 Werte ein
//                    
// Eingansparameter : 
//               str_Text          : zu schreibender Text (STRING[80])
//               di_Arg_1          : Argument 1 (DINT)
//               di_Arg_2          : Argument 2 (DINT)
//               di_Arg_3          : Argument 3 (DINT)
//               di_Arg_4          : Argument 4 (DINT)
//
// Rückgabewert :
//               FormatI            : Ergebnis (STRING[80])
// 
// Unterprogramme   : keine
//
// Benötigte Units  :   
// 
// Aenderungen      : 
//
// Aenderungsdatum  :
//
//----------------------------------------------------------------------------------------    
        VAR_INPUT
            str_Text : STRING[80]; // zu schreibender Text
            di_Arg_1 : DINT := 0; // Argument 1
            di_Arg_2 : DINT := 0; // Argument 2
            di_Arg_3 : DINT := 0; // Argument 3
            di_Arg_4 : DINT := 0; // Argument 4
        END_VAR
        
        VAR
            i : INT;
        END_VAR
        
        FormatI := str_Text;
        i := FIND(in1 := FormatI ,in2 := '%d');
        IF i <> 0 THEN
            FormatI := REPLACE(in1 := FormatI ,in2 := DINT_TO_STRING(di_Arg_1) ,l := 2 ,p := i);
        END_IF;
        i := FIND(in1 := FormatI ,in2 := '%d');
        IF i <> 0 THEN
            FormatI := REPLACE(in1 := FormatI ,in2 := DINT_TO_STRING(di_Arg_2) ,l := 2 ,p := i);
        END_IF;
        i := FIND(in1 := FormatI ,in2 := '%d');
        IF i <> 0 THEN
            FormatI := REPLACE(in1 := FormatI ,in2 := DINT_TO_STRING(di_Arg_3) ,l := 2 ,p := i);
        END_IF;
        i := FIND(in1 := FormatI ,in2 := '%d');
        IF i <> 0 THEN
            FormatI := REPLACE(in1 := FormatI ,in2 := DINT_TO_STRING(di_Arg_4) ,l := 2 ,p := i);
        END_IF;
        
    END_FUNCTION
    
    FUNCTION Add_Debug_String : VOID
//======= Add_Debug_String ===========================================================
// Funktion         : Diese Funktion fügt einen neuen Text und die aktuelle Zeit zum Puffer hinzu 
//                    
// Eingansparameter : 
//               str_Text            : zu schreibender Text (STRING[80])
//
// Rückgabewert : 
// 
// Unterprogramme   : keine
//
// Benötigte Units  :   
// 
// Aenderungen      : 
//
// Aenderungsdatum  :
//
//----------------------------------------------------------------------------------------       
        VAR_INPUT
            str_Text : STRING[80];   
        END_VAR
        
        VAR
            i : UINT;
        END_VAR
        
        FOR i := ui_Buffer_Size TO 1 BY -1 DO
            udt_Debug.data[i] := udt_Debug.data[i - 1];   
        END_FOR;
        udt_Debug.data[0].e_DataType := E_STRING;
        udt_Debug.data[0].ui_DataSize := 0;
        udt_Debug.data[0].tod_Time := DT_TO_TOD(dt_Time);
        udt_Debug.data[0].dt_Date := DT_TO_DATE(dt_Time);
        udt_Debug.data[0].str_description := str_Text;      
        udt_Debug.data[0].i_Datatype := -1;            
        udt_Debug.i_sendpointer :=  MIN(udt_Debug.i_sendpointer + 1, UINT_TO_INT(ui_Buffer_Size));
    END_FUNCTION
    
    FUNCTION Add_Debug_Data : VOID
//======= Add_Debug_Data ===========================================================
// Funktion         : Diese Funktion fügt einen neuen Text, neue Daten und die aktuelle Zeit zum Puffer hinzu 
//                    
// Eingansparameter : 
//               str_Text            : zu schreibender Text (STRING[80])
//               i_DataType          : Datentyp in aby_Data (INT)   
//               aby_Data            : Daten (ARRAY[0..1372] OF BYTE) 
//               ui_DataSize         : Länge der übergebenen Daten (UINT)
//
// Rückgabewert : 
// 
// Unterprogramme   : keine
//
// Benötigte Units  :   
// 
// Aenderungen      : 
//
// Aenderungsdatum  :
//
//----------------------------------------------------------------------------------------       
        VAR_INPUT
            str_Text : STRING[80];   
            i_DataType : INT;   
            aby_Data : ARRAY[0..ui_Data_Length_Pure_Data] OF BYTE;  
            ui_DataSize : UINT;
        END_VAR
        
        VAR
            i : UINT;
        END_VAR
        
        FOR i := ui_Buffer_Size TO 1 BY -1 DO
            udt_Debug.data[i] := udt_Debug.data[i - 1];   
        END_FOR;
        udt_Debug.data[0].e_DataType := E_DATA;
        udt_Debug.data[0].ui_DataSize := MIN(ui_DataSize, ui_Data_Length_Pure_Data) ;
        udt_Debug.data[0].tod_Time := DT_TO_TOD(dt_Time);
        udt_Debug.data[0].dt_Date := DT_TO_DATE(dt_Time);
        udt_Debug.data[0].str_Description := str_Text;      
        udt_Debug.data[0].i_Datatype := i_DataType;            
        udt_Debug.data[0].aby_Data := aby_Data;            
        udt_Debug.i_sendpointer :=  MIN(udt_Debug.i_sendpointer + 1, UINT_TO_INT(ui_Buffer_Size));
    END_FUNCTION
    
    FUNCTION StoreData : VOID
//======= StoreData ======================================================================
// Funktion         : Diese Funktion triggert das Speichern der Daten aus dem Puffer auf der Speicherkarte
//                    
// Eingansparameter : 
//
// Rückgabewert :
// 
// Unterprogramme   : keine
//
// Benötigte Units  :   
// 
// Aenderungen      : 
//
// Aenderungsdatum  :
//
//----------------------------------------------------------------------------------------    
        b_StoreData := TRUE;
        
    END_FUNCTION
    
    FUNCTION GetStoreDataState : EnumDeviceUnitDataSetCommand
//======= GetStoreDataState ======================================================================
// Funktion         : Diese Funktion prüft den Status des Speichervorgangs auf der Steuerung
//                    
// Eingansparameter : 
//
// Rückgabewert : EnumDeviceUnitDataSetCommand
// 
// Unterprogramme   : keine
//
// Benötigte Units  :   
// 
// Aenderungen      : 
//
// Aenderungsdatum  :
//
//----------------------------------------------------------------------------------------    
        
        GetStoreDataState := _getStateOfUnitDataSetCommand(s_Unit_Data_Set_Cmd.handle);
    END_FUNCTION
    
    FUNCTION MakeData : VOID
//======= MakeData ===========================================================
// Funktion         : Diese Funktion konvertiert den Debugtext in ein Bytearray 
//                    
// Eingansparameter : 
//
// Durchgangsparameter : 
//               Data            : Datengrundlage (s_DebugDataType)
//           aby_Result          : Ergebnis (ARRAY[0..ui_Max_Send_DataSize-1] OF BYTE)
//
// Rückgabewert : 
// 
// Unterprogramme   : keine
//
// Benötigte Units  :   
// 
// Aenderungen      : 
//
// Aenderungsdatum  :
//
//---------------------------------------------------------------------------------------- 
        
        VAR_IN_OUT
            Data : s_DebugDataType; // Datengrundlage
            aby_Result : ARRAY[0..ui_Max_Send_DataSize-1] OF BYTE; // Ergebnis
        END_VAR
        
        VAR
            i_Temp : INT;
            by_Temp : BYTE;
        END_VAR
        
        // Zeit
        aby_Result := ANYTYPE_TO_LITTLEBYTEARRAY(anydata := Data.tod_time,
            offset  := 0);
        // Trennbyte
        by_Temp := 16#2e;
        aby_Result := ANYTYPE_TO_LITTLEBYTEARRAY(anydata := by_Temp,
            offset  := 4);
        { _U7_PoeBld_CompilerOption := warning:16013:off } 
        // Datum
        aby_Result := ANYTYPE_TO_LITTLEBYTEARRAY(anydata := Data.dt_Date,
            offset  := 5);
        { _U7_PoeBld_CompilerOption := warning:16013:on } 
        // Trennbyte
        by_Temp := 16#2e;
        aby_Result := ANYTYPE_TO_LITTLEBYTEARRAY(anydata := by_Temp,
            offset  := 9);
        // Text
        FOR i_Temp := 1 TO 80 DO 
            aby_Result[i_Temp + 9] := Data.str_Description[i_Temp];
        END_FOR;
        
        IF Data.e_DataType = E_DATA THEN
            // Trennbyte
            by_Temp := 16#2e;
            aby_Result := ANYTYPE_TO_LITTLEBYTEARRAY(anydata := by_Temp,
                offset  := 90);
            // Datentyp
            aby_Result := ANYTYPE_TO_LITTLEBYTEARRAY(anydata := Data.i_Datatype,
                offset  := 91);
            // Trennbyte
            by_Temp := 16#2e;
            aby_Result := ANYTYPE_TO_LITTLEBYTEARRAY(anydata := by_Temp,
                offset  := 93);
            // Daten
            FOR i_Temp := 0 TO UINT_TO_INT(Data.ui_DataSize) - 1 DO 
                aby_Result[i_Temp + 94] := Data.aby_Data[i_Temp];
            END_FOR;
        END_IF;
        
    END_FUNCTION
    
// *****************************************************************************************************************
    (*FUNCTION Init_Stack : VOID
        VAR_IN_OUT
            Stack : s_SendStackType;    
        END_VAR
         
        Stack.b_Full := Stack.i_FillLevel >= Stack.i_SizeOfStack OR Stack.ui_TotalDataSize >= 1460;
        Stack.b_Empty := Stack.i_FillLevel <= -1;  
    END_FUNCTION
    
// *****************************************************************************************************************
    FUNCTION Add_Stack_Data : BOOL
        
        VAR_INPUT
            Data : s_SendStackDataType; 
        END_VAR
        VAR_IN_OUT
            Stack : s_SendStackType;
        END_VAR
        
        // Daten einstaplen
        stack.i_FillLevel := stack.i_FillLevel + 1;
        stack.i_FillLevel := LIMIT(0, Stack.i_FillLevel, Stack.i_SizeOfStack);
        IF Stack.i_FillLevel <= Stack.i_SizeOfStack THEN
            Stack.Data[Stack.i_FillLevel] := Data;
            Add_Stack_Data := TRUE;
        END_IF;
        
        // Niveaustati setzen
        Stack.b_Full := Stack.i_FillLevel >= (Stack.i_SizeOfStack - 10);
        Stack.b_Empty := FALSE;
        
    END_FUNCTION   
    
    
// *****************************************************************************************************************   
    FUNCTION Get_Stack_Data : VOID
        
        VAR_IN_OUT
            Stack : s_SendStackType;
            Result : s_SendDataType;
        END_VAR
        
        VAR
            i_pointer : INT; 
            ui_TotalSize : UINT;
        END_VAR
        
        
//        Result[10] := ANYTYPE_TO_LITTLEBYTEARRAY(stack.data, 0)
        
        
        
//        := stack.data[0];
        
        FOR i_pointer := 0 TO Stack.i_FillLevel - 1 DO
            Stack.Data[i_pointer] := Stack.Data[i_pointer + 1];         
        END_FOR;
        

        Stack.Data[Stack.i_FillLevel].ui_Size := 0;
        Stack.data[Stack.i_FillLevel].b_NeedsAck := FALSE;
        
        Stack.i_FillLevel := Stack.i_FillLevel - 1;
        Stack.b_Full := Stack.i_FillLevel >= (stack.i_SizeOfStack - 10);
        Stack.b_Empty := Stack.i_FillLevel <= -1;
        
    END_FUNCTION
      
// *****************************************************************************************************************   
    FUNCTION Delete_Stack_Data : VOID
        VAR_IN_OUT
            Stack : s_SendStackType;
        END_VAR
        
        VAR
            i_pointer_inner : INT;   
            i_pointer_outer : INT;   
        END_VAR
        
        FOR i_pointer_outer := 0 TO Stack.i_SizeOfStack DO
            FOR i_pointer_inner := 0 TO UINT_TO_INT(LCOM_SEND_DATA_LENGTH) - 1 DO 
                Stack.Data[i_pointer_outer].Data[i_pointer_inner] := 0;
            END_FOR;
            Stack.Data[i_pointer_outer].ui_Size := 0;
            Stack.Data[i_pointer_outer].b_NeedsAck := FALSE;
        END_FOR;
        
        Stack.i_FillLevel := -1;
        Stack.b_Full := FALSE;
        Stack.b_Empty := TRUE;
    END_FUNCTION*)
    
    FUNCTION GetNextTelegramNo : BYTE
        VAR_IN_OUT
            by_ActNo : BYTE;
        END_VAR    
        by_ActNo := (by_ActNo MOD 255) + 1;
        GetNextTelegramNo := by_ActNo;
    END_FUNCTION
    
    FUNCTION MakeSendData : VOID
//======= MakeSendData ===========================================================
// Funktion         : Diese Funktion setzt den Header und Footer an die Nutdaten 
//                    
// Eingansparameter : 
//               ui_DataLength      : genutzte Übergabedatenlänge (UINT)
//               i_lfd_Nr           : Telegrammlaufnummer (INT)
//
// Durchgangsparameter :
//               aby_SourceData     : Datenarray (ARRAY[0..ui_Max_Send_DataSize] OF BYTE)
//               aby_Result         : Datenarray (ARRAY[0..LCOM_SEND_DATA_LENGTH - 1] OF BYTE)
//
// Rückgabewert : 
// 
// Unterprogramme   : keine
//
// Benötigte Units  :   
// 
// Aenderungen      : 
//
// Aenderungsdatum  :
//
//----------------------------------------------------------------------------------------   
        VAR_INPUT
            ui_DataLength : UINT;
            by_lfd_Nr : BYTE;
            i_TelegrammType : INT;
        END_VAR
        
        VAR_IN_OUT
            aby_SourceData : ARRAY[0..ui_Max_Send_DataSize-1] OF BYTE; 
            aby_Result : ARRAY[0..LCOM_SEND_DATA_LENGTH-1] OF BYTE;
        END_VAR
        
        VAR
            ui_pointer : UINT;
            ui_last_index : UINT;
            by_Temp     : BYTE;
        END_VAR
        // Startzeichen
        by_Temp := 16#02;
        aby_Result := ANYTYPE_TO_BIGBYTEARRAY(anydata := by_Temp,
            offset  := 0);
        // Telegrammlaufnummer
        aby_Result := ANYTYPE_TO_BIGBYTEARRAY(anydata := by_lfd_Nr,
            offset  := 1);                             
        // Trennbyte
        by_Temp := 16#2E;
        aby_Result := ANYTYPE_TO_BIGBYTEARRAY(anydata := by_Temp,
            offset  := 2);
        
        // Telegrammtyp                      
        aby_Result := ANYTYPE_TO_BIGBYTEARRAY(anydata := i_TelegrammType,
            offset  := 3);
        
        // Trennbyte
        by_Temp := 16#2E;
        aby_Result := ANYTYPE_TO_BIGBYTEARRAY(anydata := by_Temp,
            offset  := 5);
       
        // Daten einfügen
        FOR ui_pointer := 0 TO MIN(ui_DataLength, ui_Max_Send_DataSize - 7) - 1 DO 
            aby_Result[ui_pointer + 6] := aby_SourceData[ui_pointer]; 
            ui_last_index := ui_pointer + 6;
        END_FOR;
        // Endzeichen
        ui_last_index := ui_last_index + 1;
        aby_Result[ui_last_index] := 16#03;   
    END_FUNCTION
    
    FUNCTION_BLOCK ConvertHeader
//======= ConvertHeader ===========================================================
// Funktion         : Dieser Funktionsbaustein prüft die empfangenen Headerdaten
//                 Gibt notwendige Headerdaten aus
//                    
// Eingansparameter :
// 
// Ein- Ausgansparameter :
//                   aby_SourceData     : Datenarray (ARRAY[0..LCOM_RECEIVED_DATA_LENGTH] OF BYTE)              
//                 
// Ausgangsparameter: 
//              by_lfd_Nr_Rec       : Telegrammlaufnummer (BYTE)
//             i_Telegramm_Nr       : Nummer des empfangenen Telegramms (INT)
//             ui_TotalDataLength   : erwartete Gesammtdatenmenge (UINT)
//             b_Data_Ok            : Daten Ok (BOOL)
//
// Unterprogramme   : keine
//
// Benötigte Units  :  
// 
// Aenderungen      : 
//
// Aenderungsdatum  :
//
//----------------------------------------------------------------------------------------   
        VAR_IN_OUT 
            aby_SourceData    : ARRAY[0..LCOM_RECEIVED_DATA_LENGTH-1] OF BYTE; 
        END_VAR
            
        VAR_OUTPUT
            by_lfd_Nr_Rec : BYTE;
            i_Telegramm_Nr : INT;
            ui_TotalDataLength : UINT;
            b_Data_Ok : BOOL;
        END_VAR
        
        VAR
            i_Temp : INT;
        END_VAR
        
        // Telegrammlaufnummer
        by_lfd_Nr_Rec := LITTLEBYTEARRAY_TO_ANYTYPE(bytearray := aby_SourceData, 
            offset := 1);
        // Telegrammnummer
        i_Temp := BIGBYTEARRAY_TO_ANYTYPE(bytearray := aby_SourceData, 
            offset := 3);
        i_Telegramm_Nr := 0;
        ui_TotalDataLength := 0;
        
        CASE i_Temp OF
            
            16#3130:
                
                ui_TotalDataLength := ui_RecDataLength_Quit;
                i_Telegramm_Nr := 10;
                b_Data_Ok := TRUE; 
                
            16#3131:
            
                ui_TotalDataLength := ui_RecDataLength_Quit;
                i_Telegramm_Nr := 11;
                b_Data_Ok := TRUE;
                
            16#3132:
            
                ui_TotalDataLength := ui_RecDataLength_Quit;
                i_Telegramm_Nr := 12; 
                b_Data_Ok := TRUE;
                
            16#3133:
            
                ui_TotalDataLength := ui_RecDataLength_Quit;
                i_Telegramm_Nr := 13; 
                b_Data_Ok:= TRUE;
                
        ELSE
                
            b_Data_Ok := FALSE;
            
        END_CASE;
    END_FUNCTION_BLOCK
    
    FUNCTION_BLOCK ConvertReceiveData
//======= ConvertReceiveData ===========================================================
// Funktion         : Dieser Funktionsbaustein prüft die empfangenen Daten
//                 Entfernt Header und Footer
//                 Gibt notwendige Daten aus
//                    
//                    
// Eingansparameter :
//               ui_DataLength      : übergebene Nutzdatenlänge (UINT)
//               i_Telegramm_Nr       : Nummer des empfangenen Telegramms (INT)
// 
// Ein- Ausgansparameter :
//               aby_SourceData     : Datenarray (ARRAY[0..LCOM_RECEIVED_DATA_LENGTH] OF BYTE) 
//                 
// Ausgangsparameter: 
//               b_Data_Ok          : Daten sind ok (BOOL);
//               
//
// Unterprogramme   : keine
//
// Benötigte Units  :  
// 
// Aenderungen      : 
//
// Aenderungsdatum  :
//
//----------------------------------------------------------------------------------------   
        VAR_INPUT
            ui_DataLength : UINT;
            i_Telegramm_Nr : INT;
        END_VAR
        
        (*VAR_IN_OUT
            aby_SourceData : ARRAY[0..LCOM_RECEIVED_DATA_LENGTH-1] OF BYTE; 
        END_VAR*)
        
        VAR_OUTPUT
            b_Data_Ok : BOOL;
        END_VAR         
        
        b_Data_Ok := TRUE;
        CASE i_Telegramm_Nr OF
            
            10: 
            
                b_Data_Ok := b_Data_Ok AND (ui_DataLength = ui_RecDataLength_Quit);
            
            11: 
            
                b_Data_Ok := b_Data_Ok AND (ui_DataLength = ui_RecDataLength_Quit);
            
            12: 
            
                b_Data_Ok := b_Data_Ok AND (ui_DataLength = ui_RecDataLength_Quit);
                
            13: 
            
                b_Data_Ok := b_Data_Ok AND (ui_DataLength = ui_RecDataLength_Quit);
            
        ELSE
            b_Data_Ok := FALSE;   
        END_CASE;
        
    END_FUNCTION_BLOCK

    PROGRAM ComDebug
        VAR
            // Daten von / an PC senden 
            sComParameter       : sLComParameterType    ; //parameter for fb
            FB_DebugCom         : fbLcomMachineCom      ; //instance of fb
            FB_ConvertHeader    : ConvertHeader         ; //instance of fb
            FB_ConvertReceivedata: ConvertReceiveData     ; //instance of fb
            b_Enable           : BOOL                  ; //run direct
            b_Communicate       : BOOL  := FALSE        ; //run direct
            b_DataReceived       : BOOL                  ;
            b_SenderActive      : BOOL                  ;
            b_ReceiverActive   : BOOL                  ;
            b_AbortCommunication: BOOL               ;
            b_Acknowledge      : BOOL               ;
            b_Enable_Timeout   : BOOL               ;
            b_Sending           : BOOL                  ;
            b_Wait_Ack          : BOOL                  ;
            b_Packet_Quit       : BOOL                  ;
            b_Data_Fail         : BOOL                  ;
            b32ErrorId          : DWORD                 ;
            u16ReceivedLength   : UINT                  ; 
            u16SendDataLength   : UINT                  ;
            ui_Packet_Length    : UINT                  ; // Paketlänge des aktuellen Pakets
            ui_pointer_Data_in  : UINT                  ; // Zeiger Empfangdaten zusammenbauen
            ui_pointer          : UINT                  ;
            i_Send_Versuche     : INT                   ;
            i_Rec_Versuche      : INT                   ;
            by_Lfd_Nr_Send      : BYTE                  ;
            by_Lfd_Nr_Rec       : BYTE                  ;
            rt_Count_Send       : R_TRIG                ;
            ton_sendCycle      : TON               ;
            Realtime          : RTC               ;
            
            e_StepSend         : eDebugStepSend            ; // Schrittvariable 
            e_OldStepSend      : eDebugStepSend            ; // Schrittvariable
            
            aby_SendBuffer : ARRAY [0..LCOM_SEND_DATA_LENGTH-1] OF BYTE;
            aby_ReceiveBuffer : ARRAY [0..LCOM_RECEIVED_DATA_LENGTH-1] OF BYTE;
            aby_TempBuffer : ARRAY [0..LCOM_RECEIVED_DATA_LENGTH-1] OF BYTE;  
            // StackData : s_SendStackDataType   ;
            // SendData : s_SendDataType   ;
            aby_Temp : ARRAY[0..ui_Max_Send_DataSize - 1] OF BYTE;
        END_VAR
        
       // VAR_TEMP 
        //    b_Temp : BOOL;
            //Temp_Data : s_SendStackDataType;
      //  END_VAR
        
        IF b_FirstCycle THEN
            b_init := TRUE;    
        END_IF;
        
        // Zeit für Debugstring
        Realtime(Read := TRUE);
        dt_Time := Realtime.cdt;
        
        IF b_init = TRUE THEN
                        
            //connection parameter
            sComParameter.sCfgConnection.boWithLComProtocol     := FALSE;
            sComParameter.sCfgConnection.boAcceptUnknownPartner := TRUE;
            sComParameter.sCfgConnection.u16ComService          := 1    ; //1 = TCP
            sComParameter.sCfgConnection.boIsTcpClient          := FALSE;
            sComParameter.sCfgConnection.u16LocalPort           := 5000 ;
            sComParameter.sCfgConnection.au8RemoteAddress[0]    := 192  ;
            sComParameter.sCfgConnection.au8RemoteAddress[1]    := 168  ;
            sComParameter.sCfgConnection.au8RemoteAddress[2]    := 1  ;
            sComParameter.sCfgConnection.au8RemoteAddress[3]    := 30 ;
            sComParameter.sCfgConnection.u16RemotePort          := 5001;
            sComParameter.sCfgConnection.u16LifeSignCycle       := 300  ; //ms   
            sComParameter.sCfgConnection.boBigEndian            := TRUE;
            
            //sender Parameter
            sComParameter.sCfgSender.u8ComMode                  := 3    ; //1: mode Zyklisch / 3: mode auf Anforderung
            sComParameter.sCfgSender.u16CycleTime               := 0    ; //ms
            sComParameter.sCfgSender.u16AckTimeout              := 500  ; //ms
            sComParameter.sCfgSender.u8SlidingWindow            := 1    ;
            //time synchronisation parameter
            sComParameter.sCfgTimeSync.boUseReceivedTimeStamps := FALSE;
            sComParameter.sCfgTimeSync.u8SendModeTimeSync := 0;
            sComParameter.sCfgTimeSync.u16TimeSyncCycleTime := 0;
            sComParameter.sCfgTimeSync.todTimeSyncAtTime := TOD#00:00:00.0;
            
            by_Lfd_Nr_Send := 0;
            //Init_Stack(udt_stack_send_data);
            b_init                                     := FALSE ;        
        ELSE
            
            CASE e_StepSend OF
                
                STEP_WAIT_FOR_ACTIVATE:
                
                    IF b_AbortCommunication THEN
                        b_AbortCommunication  := FALSE;
                    END_IF;
                    
                    b_Acknowledge := FALSE;
                    b_Communicate := FALSE;
                    by_Lfd_Nr_Send := 0;
                    
                    IF b_Enable AND b_Connected THEN
                        e_StepSend := STEP_WAIT_FOR_SEND_REQ;
                    END_IF;
                
                STEP_WAIT_FOR_SEND_REQ:
                
                    // Flankenerzeugung
                    b_Communicate      := FALSE;
                    b_Acknowledge      := FALSE;
                    
                    IF NOT b_Enable THEN
                        // Kommunikation deaktivieren
                        
                        e_StepSend := STEP_WAIT_FOR_ACTIVATE;                    
                    ELSIF NOT b_Connected THEN    
                        // Verbindung wurde geschlossen
                        
                        e_StepSend := STEP_WAIT_FOR_ACTIVATE;                    
                    ELSIF b_AbortCommunication THEN    
                        b_AbortCommunication  := FALSE;
                        b_Acknowledge := FALSE;
                        
                    ELSE
                        IF NOT b_SenderActive AND NOT b_Sending AND NOT b_Communicate AND NOT b_Wait_Ack AND udt_Debug.i_SendPointer >= 0 THEN
                            MakeData(
                                Data := udt_Debug.Data[udt_Debug.i_SendPointer]
                                ,aby_Result := aby_Temp
                                );
                            
                            IF udt_Debug.Data[udt_Debug.i_SendPointer].e_DataType = E_STRING THEN
                                MakeSendData(
                                    ui_DataLength := ui_Data_Length_String
                                    ,by_lfd_Nr := GetNextTelegramNo(by_Lfd_Nr_Send)
                                    ,i_TelegrammType := 16#3032
                                    ,aby_SourceData := aby_Temp
                                    ,aby_Result := aby_SendBuffer
                                    );
                                u16SendDataLength := ui_SendDataLength_Debug;
                            ELSE
                                MakeSendData(
                                    ui_DataLength := ui_Data_Length_Data
                                    ,by_lfd_Nr := GetNextTelegramNo(by_Lfd_Nr_Send)
                                    ,i_TelegrammType := 16#3033
                                    ,aby_SourceData := aby_Temp
                                    ,aby_Result := aby_SendBuffer
                                    );
                                u16SendDataLength := ui_SendDataLength_Data;
                            END_IF;
                            
                            b_Communicate := TRUE;
                            b_Wait_Ack := TRUE;
                                
                            udt_Debug.i_SendPointer := udt_debug.i_SendPointer - 1;
                            
                            e_StepSend := STEP_WAIT_FOR_ACK;                             
                        ELSIF b_Wait_Ack THEN
                            b_Communicate := TRUE;
                                
                            e_StepSend := STEP_WAIT_FOR_ACK;
                        END_IF;
                    END_IF;
                
                STEP_WAIT_FOR_ACK:
                
                    // Flankenerzeugung
                    b_Communicate := FALSE;
                    
                    IF TON_SendCycle.Q THEN
                        b_Communicate := TRUE;
                    END_IF;
                    
                    IF NOT b_Enable THEN
                        // Kommunikation deaktivieren            
                        
                        e_StepSend := STEP_WAIT_FOR_ACTIVATE;
                    ELSIF b_AbortCommunication THEN    
                        // aktuellen Übertragungsvorgang abbrechen
                        
                        e_StepSend := STEP_WAIT_FOR_SEND_REQ;                    
                    ELSIF NOT b_Connected THEN    
                        // Verbindung wurde geschlossen
                        
                        e_StepSend := STEP_WAIT_FOR_ACTIVATE;                
                    ELSE     
                        // Quittung empfangen -> auswerten
                        IF b_Packet_Quit THEN
                            b_Acknowledge := TRUE;
                            b_Wait_Ack := FALSE;
                            b_Packet_Quit := FALSE;
                            
                            e_StepSend := STEP_WAIT_FOR_SEND_REQ;
                        END_IF;
                        
                    END_IF;           
                
            ELSE
                ;
            END_CASE;
            
            // Timer für zyklisches "Neu-Senden", falls keine Quittung innerhalb der konfigurierten Wartezeit kommt
            
            b_Enable_Timeout := (e_StepSend = STEP_WAIT_FOR_ACK) AND
                e_StepSend = e_OldStepSend;
            
            TON_SendCycle (IN := b_Enable_Timeout AND NOT b_Communicate AND NOT TON_SendCycle.Q, PT := t#2000ms);
            e_OldStepSend := e_StepSend;
            
            // Zähler Sendeversuche 
            rt_count_send (clk := b_SenderActive AND e_StepSend = STEP_WAIT_FOR_ACK); // Flanke zählen Sendeversuche
            //IF TON_SendCycle.Q THEN 
            //    i_Send_versuche := i_Send_versuche + 1;
            //END_IF;
            
            // Zähler Rücksetzen     
            IF b_Acknowledge OR NOT b_Enable OR b_FirstCycle THEN
                i_Send_versuche := 0;
            END_IF;
            
            (*// Time out Senden TCP/IP Kommunikation
            IF i_Send_versuche > 3 THEN 
                 ab_Errors[930] := TRUE ;
            END_IF;
            
            IF b_FpQuitt AND ab_Errors[930] THEN 
                ab_Errors[930] := FALSE ;
            END_IF;*)
                
            // Zähler Empfangsversuche 
            IF b_Data_Fail THEN
                i_Rec_versuche := i_Rec_versuche + 1;
            END_IF;
            
            // Zähler Rücksetzen     
            IF NOT b_Enable OR b_FirstCycle THEN
                i_Rec_versuche := 0;
            END_IF;
            
            (*// Time out Empfangen TCP/IP Kommunikation
            IF i_Rec_versuche > 3 THEN 
                ab_Errors[931] := TRUE ;
            END_IF;
                
            IF b_FpQuitt AND ab_Errors[931] THEN 
                ab_Errors[931] := FALSE ;
            END_IF;*)
                    
        END_IF;
        
        IF b_Enable_com = TRUE AND b_init = FALSE AND i_Send_versuche <= 3 AND i_Rec_versuche <= 3 THEN
            b_Enable := TRUE ;
        ELSE
            b_Enable := FALSE ;
            ui_pointer_Data_in := 0;
        END_IF ;
        
        //call communication function block
        FB_DebugCom(
            enable := b_Enable
            ,communicate := b_Communicate
            ,sendDataLength := u16SendDataLength
            // ,readingLength := 65535
            ,sendData := aby_SendBuffer
            ,receivedData := aby_ReceiveBuffer
            ,parameter := sComParameter
            ,connected => b_Connected
            ,sending => b_Sending
            ,dataReceived => b_DataReceived
            ,error => b_Error
            ,errorId => b32ErrorId
            ,senderActive => b_SenderActive
            ,receiverActive => b_ReceiverActive
            // ,diagnostic => 
            ,receivedDataLength => u16ReceivedLength
            );
        
        b_Data_Fail := FALSE;
        
        IF b_Connected = TRUE THEN 
            // Wenn richtige Datenlänge empfangen und in Speicher eintragen  
            IF b_DataReceived = TRUE THEN
                FOR ui_pointer := 0 TO u16ReceivedLength - 1 DO
                    
                    aby_TempBuffer[ui_pointer_Data_in] := aby_ReceiveBuffer[ui_pointer] ;  
                    ui_pointer_Data_in := ui_pointer_Data_in + 1;
                    
                    IF ui_pointer_Data_in = ui_Header_Length THEN
                        FB_convertheader(
                            aby_SourceData := aby_TempBuffer
                            ,by_lfd_Nr_Rec => by_Lfd_Nr_Rec
                            // ,i_Telegramm_Nr => 
                            ,ui_TotalDataLength => ui_Packet_Length
                            // ,b_Data_Ok 
                            );
                    END_IF;           
                    
                    // Unbekannte Telegrammnummer
                    IF ui_pointer_Data_in = ui_Header_Length AND NOT FB_convertheader.b_Data_Ok THEN
                        b_Data_Fail := TRUE;
                        ui_pointer_Data_in := 0;     
                    END_IF;
                    
                    IF ui_pointer_Data_in = ui_packet_length AND ui_pointer_Data_in > ui_Header_Length THEN
                        IF aby_TempBuffer[ui_pointer_Data_in - 1] = 16#03 THEN
                            // Ende Datenstream
                            FB_ConvertReceivedata(
                                ui_DataLength := ui_Packet_Length
                                ,i_Telegramm_Nr := FB_convertheader.i_Telegramm_Nr 
                                // ,b_Data_Ok => 
                                );
                            CASE FB_ConvertReceivedata.i_telegramm_nr OF
                                
                                11: b_Packet_Quit := FB_convertheader.b_Data_Ok AND FB_ConvertReceivedata.b_Data_Ok;
                                
                                12: b_Packet_Quit := FB_convertheader.b_Data_Ok AND FB_ConvertReceivedata.b_Data_Ok;
                                
                                13: b_Packet_Quit := FB_convertheader.b_Data_Ok AND FB_ConvertReceivedata.b_Data_Ok;
                               
                            END_CASE;
                            ui_pointer_Data_in := 0 ;
                            i_Rec_versuche := 0;
                        ELSE
                            ui_pointer_Data_in := 0 ;
                            b_Data_Fail := TRUE;
                        END_IF;
                    END_IF;     
                END_FOR ;
            END_IF ;
        ELSE
            ui_pointer_Data_in := 0 ;      
        END_IF; 
        
        IF b_StoreData THEN
            udi_DataSetIndex := (udi_DataSetIndex MOD 999999) + 1;
            
            s_Unit_Data_Set_Cmd := _exportunitdataset(
                unitname:='DebuggingCom',
                id := udi_DataSetIndex,
                storagetype := PERMANENT_STORAGE,
                //path:='',    Speicherkarte\USER\SIMOTION\USER_DIR\UPP\UNITDS
                overwrite := TRUE,
                nextcommand := IMMEDIATELY,
                datascope:=_IMPLEMENTATION,
                kindofdata := NO_RETAIN_GLOBAL
                );
            b_StoreData := FALSE;
        END_IF;
               
    END_PROGRAM
      
END_IMPLEMENTATION