
FUNCTION_BLOCK CyclicOperations (* *) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		Instance : REFERENCE TO s_DebuggingComType;
	END_VAR
	VAR
		FB_DebugCom : FBCom;
		DebugComConfig : s_FBComConfigType;
		FB_ConvertHeader    : ConvertHeader         ;
		FB_ConvertReceivedata : ConvertReceiveData  ;
		b_Enable           : BOOL                   ;
		b_Communicate       : BOOL  := FALSE        ;
		b_DataReceived       : BOOL                 ;
		b_AbortCommunication: BOOL                  ;
		b_Acknowledge      : BOOL                   ;
		b_Enable_Timeout   : BOOL                   ;
		b_Sending           : BOOL                  ;
		b_Wait_Ack          : BOOL                  ;
		b_Packet_Quit       : BOOL                  ;
		b_Data_Fail         : BOOL                  ;
		u16SendDataLength   : UINT                  ;
		u16ReceivedLength   : UDINT                 ; 
		ui_pointer          : DINT                  ;
		ui_Packet_Length    : UINT                  ;
		ui_pointer_Data_in  : UINT                  ; 
		i_Send_Versuche     : INT                   ;
		i_Rec_Versuche      : INT                   ;
		usi_Lfd_Nr_Send      : USINT                  ;
		usi_Lfd_Nr_Rec       : USINT                  ;
		rt_Count_Send       : R_TRIG                ;
        ton_SendCycle       : TON                   ;
        i_Temp              : INT                   ;
		            
		e_StepSend         : e_DebugStepSend        ;
		e_OldStepSend      : e_DebugStepSend        ;
            
		aby_SendBuffer : ARRAY [0..ui_Max_Send_DataSize] OF BYTE;
		aby_ReceiveBuffer : ARRAY [0..ui_RecDataLength_Quit] OF BYTE;
		aby_TempBuffer : ARRAY [0..ui_RecDataLength_Quit] OF BYTE;  
		aby_Temp : ARRAY[0..ui_Max_Send_DataSize] OF BYTE;
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK Add_Debug_String (*//======= Add_Debug_String ===========================================================
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
//----------------------------------------------------------------------------------------*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		Instance : REFERENCE TO s_DebuggingComType;
		str_Text : STRING[80];
	END_VAR
	VAR
        realtime : DTStructureGetTime;
		ActTime : DTStructure;
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK Add_Debug_Data (*//======= Add_Debug_Data ===========================================================
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
//----------------------------------------------------------------------------------------*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		Instance : REFERENCE TO s_DebuggingComType;
		str_Text : STRING[80];
		i_DataType : INT;
		aby_Data : ARRAY[0..ui_Data_Length_Pure_Data] OF BYTE;
		ui_DataSize : UINT;
	END_VAR
	VAR
        realtime : DTStructureGetTime;
		ActTime : DTStructure;
	END_VAR
END_FUNCTION_BLOCK

FUNCTION MakeData : USINT
	(*//======= MakeData ===========================================================
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
	//----------------------------------------------------------------------------------------*)
        
	VAR_IN_OUT
		Data : s_DebugDataType; (* Datengrundlage *)
		aby_Result : ARRAY[0..ui_Max_Send_DataSize] OF BYTE; (* Ergebnis *)
	END_VAR
        
	VAR
		i_Temp : INT;
		by_Temp : BYTE;
		tod_Temp : TIME_OF_DAY;
		udi_Temp : UDINT;
	END_VAR
        
		END_FUNCTION
    
FUNCTION GetNextTelegramNo : USINT
	VAR_IN_OUT
		usi_ActNo : USINT;
	END_VAR    
		END_FUNCTION
    
FUNCTION MakeSendData : USINT
	(*//======= MakeSendData ===========================================================
	// Funktion         : Diese Funktion setzt den Header und Footer an die Nutdaten 
	//                    
	// Eingansparameter : 
	//               ui_DataLength      : genutzte Übergabedatenlänge (UINT)
	//               usi_lfd_Nr         : Telegrammlaufnummer (USINT)
	//
	// Durchgangsparameter :
	//               aby_SourceData     : Datenarray (ARRAY[0..ui_Max_Send_DataSize] OF BYTE)
	//               aby_Result         : Datenarray (ARRAY[0..ui_Max_Send_DataSize - 1] OF BYTE)
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
	//----------------------------------------------------------------------------------------*)  
	VAR_INPUT
		ui_DataLength : UINT;
		usi_lfd_Nr : USINT;
		i_TelegrammType : INT;
	END_VAR
        
	VAR_IN_OUT
		aby_SourceData : ARRAY[0..ui_Max_Send_DataSize] OF BYTE; 
		aby_Result : ARRAY[0..ui_Max_Send_DataSize] OF BYTE;
	END_VAR
        
	VAR
		by_Temp     : BYTE;
		i_Temp : INT;
	END_VAR
			END_FUNCTION
    
FUNCTION_BLOCK ConvertHeader
	(*//======= ConvertHeader ===========================================================
	// Funktion         : Dieser Funktionsbaustein prüft die empfangenen Headerdaten
	//                 Gibt notwendige Headerdaten aus
	//                    
	// Eingansparameter :
	// 
	// Ein- Ausgansparameter :
	//                   aby_SourceData     : Datenarray (ARRAY[0..ui_RecDataLength_Quit] OF BYTE)              
	//                 
	// Ausgangsparameter: 
	//             usi_lfd_Nr_Rec       : Telegrammlaufnummer (USINT)
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
	//----------------------------------------------------------------------------------------*)
	VAR_IN_OUT 
		aby_SourceData : ARRAY[0..ui_RecDataLength_Quit] OF BYTE; 
	END_VAR
            
	VAR_OUTPUT
		usi_lfd_Nr_Rec : USINT;
		i_Telegramm_Nr : INT;
		ui_TotalDataLength : UINT;
		b_Data_Ok : BOOL;
	END_VAR
        
	VAR
		i_Temp : INT;
	END_VAR
      
		END_FUNCTION_BLOCK
    
FUNCTION_BLOCK ConvertReceiveData
	(*//======= ConvertReceiveData ===========================================================
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
	//----------------------------------------------------------------------------------------*)
	VAR_INPUT
		ui_DataLength : UINT;
		i_Telegramm_Nr : INT;
	END_VAR
        
	VAR_OUTPUT
		b_Data_Ok : BOOL;
	END_VAR         
	
		END_FUNCTION_BLOCK
