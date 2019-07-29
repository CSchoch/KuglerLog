FUNCTION MakeData
	// Reset memory data
	brsmemset(ADR(aby_Result[0]), 0, SIZEOF(aby_Result));
	// Zeit
	tod_Temp := swapTOD(H_TO_NTOD(Data.tod_Time));
	brsmemcpy(ADR(aby_Result[0]), ADR(tod_Temp), SIZEOF(tod_Temp));
	// Trennbyte
	by_Temp := 16#2e;
	brsmemcpy(ADR(aby_Result[4]), ADR(by_Temp), SIZEOF(by_Temp));
	// Datum (convert to days since 01.01.1992)
	udi_Temp := swapUDINT(H_TO_NUDINT((DATE_TO_UDINT(Data.dt_Date) - DATE_TO_UDINT(D#1992-01-01)) / 86400));
	brsmemcpy(ADR(aby_Result[5]), ADR(udi_Temp), SIZEOF(udi_Temp));
	// Trennbyte
	by_Temp := 16#2e;
	brsmemcpy(ADR(aby_Result[9]), ADR(by_Temp), SIZEOF(by_Temp));
	// Text
	brsmemcpy(ADR(aby_Result[10]), ADR(Data.str_Description), brsstrlen(ADR(Data.str_Description)));
        
	IF Data.e_DataType = E_DATA THEN
		// Trennbyte
		by_Temp := 16#2e;
		brsmemcpy(ADR(aby_Result[90]), ADR(by_Temp), SIZEOF(by_Temp));
		// Datentyp
		i_Temp := swapINT(H_TO_NINT(Data.i_DataType));
		brsmemcpy(ADR(aby_Result[91]), ADR(i_Temp), SIZEOF(i_Temp));
		// Trennbyte
		by_Temp := 16#2e;
		brsmemcpy(ADR(aby_Result[93]), ADR(by_Temp), SIZEOF(by_Temp));
		// Daten
		brsmemcpy(ADR(aby_Result[94]), ADR(Data.aby_Data), Data.ui_DataSize);
    END_IF;
    MakeData := 0;
        
END_FUNCTION
    
FUNCTION GetNextTelegramNo

	usi_ActNo := (usi_ActNo MOD 255) + 1;
	GetNextTelegramNo := usi_ActNo;
END_FUNCTION
    
FUNCTION MakeSendData

	// Reset memory data
	brsmemset(ADR(aby_Result[0]), 0, SIZEOF(aby_Result));
	// Startzeichen
	by_Temp := 16#02;
	brsmemcpy(ADR(aby_Result[0]), ADR(by_Temp), SIZEOF(by_Temp));
	// Telegrammlaufnummer
	brsmemcpy(ADR(aby_Result[1]), ADR(usi_lfd_Nr), SIZEOF(usi_lfd_Nr));   
	// Trennbyte
	by_Temp := 16#2E;
	brsmemcpy(ADR(aby_Result[2]), ADR(by_Temp), SIZEOF(by_Temp));  
	// Telegrammtyp    
	i_Temp := H_TO_NINT(i_TelegrammType);
	brsmemcpy(ADR(aby_Result[3]), ADR(i_Temp), SIZEOF(i_TelegrammType));
	// Trennbyte
	by_Temp := 16#2E;
	brsmemcpy(ADR(aby_Result[5]), ADR(by_Temp), SIZEOF(by_Temp));
	// Daten einfügen
	brsmemcpy(ADR(aby_Result[6]), ADR(aby_SourceData), ui_DataLength);
	
	// Endzeichen
    aby_Result[MIN(ui_DataLength + 6, ui_Max_Send_DataSize)] := 16#03;   
    
    MakeSendData := 0;
END_FUNCTION
    
FUNCTION_BLOCK ConvertHeader

	//Telegrammlaufnummer
	brsmemcpy(ADR(usi_lfd_Nr_Rec), ADR(aby_SourceData[1]), SIZEOF(usi_lfd_Nr_Rec));

	// Telegrammnummer
	brsmemcpy(ADR(i_Temp), ADR(aby_SourceData[3]), SIZEOF(i_Temp));
	i_Temp := N_TO_HINT(i_Temp);

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