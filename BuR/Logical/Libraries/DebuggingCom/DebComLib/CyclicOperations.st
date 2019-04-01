
(* TODO: Hier einen Kommentar eingeben *)
FUNCTION_BLOCK CyclicOperations
	
	IF Instance.b_init THEN
		DebugComConfig.Connection.b_IsClient := FALSE;
		DebugComConfig.Connection.ui_LocalPort := 5000;
		usi_Lfd_Nr_Send := 0;
		i_Send_Versuche := 0;
		i_Rec_Versuche := 0;
		
		Instance.b_init := FALSE;
	END_IF;
	
	CASE e_StepSend OF
                
		STEP_WAIT_FOR_ACTIVATE:
                
			IF b_AbortCommunication THEN
				b_AbortCommunication  := FALSE;
			END_IF;
                    
			b_Acknowledge := FALSE;
			b_Communicate := FALSE;
			usi_Lfd_Nr_Send := 0;
                    
			IF b_Enable AND Instance.b_Connected THEN
				e_StepSend := STEP_WAIT_FOR_SEND_REQ;
			END_IF;
                
		STEP_WAIT_FOR_SEND_REQ:
                
			// Flankenerzeugung
			b_Communicate      := FALSE;
			b_Acknowledge      := FALSE;
                    
			IF NOT b_Enable THEN
				// Kommunikation deaktivieren
                        
				e_StepSend := STEP_WAIT_FOR_ACTIVATE;                    
			ELSIF NOT Instance.b_Connected THEN    
				// Verbindung wurde geschlossen
                        
				e_StepSend := STEP_WAIT_FOR_ACTIVATE;                    
			ELSIF b_AbortCommunication THEN    
				b_AbortCommunication  := FALSE;
				b_Acknowledge := FALSE;
                        
			ELSE
				IF NOT b_Sending AND NOT b_Communicate AND NOT b_Wait_Ack AND Instance.Data.i_SendPointer >= 0 THEN
					MakeData(
					Data := Instance.Data.Data[Instance.Data.i_SendPointer]
					,aby_Result := aby_Temp
					);
                            
					IF Instance.Data.Data[Instance.Data.i_SendPointer].e_DataType = E_STRING THEN
						MakeSendData(
							ui_DataLength := ui_Data_Length_String
							,usi_lfd_Nr := GetNextTelegramNo(usi_Lfd_Nr_Send)
							,i_TelegrammType := 16#3032
							,aby_SourceData := aby_Temp
							,aby_Result := aby_SendBuffer
							);
						u16SendDataLength := ui_SendDataLength_Debug;
					ELSE
						MakeSendData(
							ui_DataLength := ui_Data_Length_Data
							,usi_lfd_Nr := GetNextTelegramNo(usi_Lfd_Nr_Send)
							,i_TelegrammType := 16#3033
							,aby_SourceData := aby_Temp
							,aby_Result := aby_SendBuffer
							);
						u16SendDataLength := ui_SendDataLength_Data;
					END_IF;
                            
					b_Communicate := TRUE;
					b_Wait_Ack := TRUE;
                                
					Instance.Data.i_SendPointer := Instance.Data.i_SendPointer - 1;
                            
					e_StepSend := STEP_WAIT_FOR_ACK;                             
				ELSIF b_Wait_Ack THEN
					b_Communicate := TRUE;
                                
					e_StepSend := STEP_WAIT_FOR_ACK;
				END_IF;
			END_IF;
                
		STEP_WAIT_FOR_ACK:
                
			// Flankenerzeugung
			b_Communicate := FALSE;
                    
			IF ton_SendCycle.Q THEN
				b_Communicate := TRUE;
			END_IF;
                    
			IF NOT b_Enable THEN
				// Kommunikation deaktivieren            
                        
				e_StepSend := STEP_WAIT_FOR_ACTIVATE;
			ELSIF b_AbortCommunication THEN    
				// aktuellen Übertragungsvorgang abbrechen
                        
				e_StepSend := STEP_WAIT_FOR_SEND_REQ;                    
			ELSIF NOT Instance.b_Connected THEN    
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
            
	ton_SendCycle (IN := b_Enable_Timeout AND NOT b_Communicate AND NOT ton_SendCycle.Q, PT := t#2000ms);
	e_OldStepSend := e_StepSend;
            
	// Zähler Sendeversuche 
	rt_Count_Send (CLK := b_Sending AND e_StepSend = STEP_WAIT_FOR_ACK); // Flanke zählen Sendeversuche
            
	// Zähler Rücksetzen     
	IF b_Acknowledge OR NOT b_Enable THEN
		i_Send_Versuche := 0;
	END_IF;           
                
	// Zähler Empfangsversuche 
	IF b_Data_Fail THEN
		i_Rec_Versuche := i_Rec_Versuche + 1;
	END_IF;
            
	// Zähler Rücksetzen     
	IF NOT b_Enable THEN
		i_Rec_Versuche := 0;
	END_IF;
        
	IF Instance.b_Enable_Com AND NOT Instance.b_init AND i_Send_Versuche <= 3 AND i_Rec_Versuche <= 3 AND NOT FB_DebugCom.error THEN
		b_Enable := TRUE ;
	ELSE
		b_Enable := FALSE ;
		ui_pointer_Data_in := 0;
	END_IF ;

	//call communication function block
	FB_DebugCom(
		enable := b_Enable
		,send := b_Communicate
		,sendDataLength := u16SendDataLength
		,receiveDataLength := SIZEOF(aby_ReceiveBuffer)
		,configurations := DebugComConfig
		,sendBuffer := ADR(aby_SendBuffer)
		,receiveBuffer := ADR(aby_ReceiveBuffer)
	);
	u16ReceivedLength := FB_DebugCom.receivedDataLength;
	Instance.b_Connected := FB_DebugCom.connected;       
	b_DataReceived := FB_DebugCom.dataReceived; 
	b_Sending := FB_DebugCom.sending;
            
    
	b_Data_Fail := FALSE;
        
	IF Instance.b_Connected THEN 
		// Wenn richtige Datenlänge empfangen und in Speicher eintragen  
		IF b_DataReceived THEN
			FOR ui_pointer := 0 TO UDINT_TO_DINT(u16ReceivedLength) - 1 DO
                    
				aby_TempBuffer[ui_pointer_Data_in] := aby_ReceiveBuffer[ui_pointer] ;  
				ui_pointer_Data_in := ui_pointer_Data_in + 1;
                    
				IF ui_pointer_Data_in = ui_Header_Length THEN
					FB_ConvertHeader(
						aby_SourceData := aby_TempBuffer
						//,usi_Lfd_Nr_Rec =>
						// ,i_Telegramm_Nr => 
						//,ui_TotalDataLength => 
						// ,b_Data_Ok 
						);
					usi_Lfd_Nr_Rec := FB_ConvertHeader.usi_lfd_Nr_Rec;
					ui_Packet_Length := FB_ConvertHeader.ui_TotalDataLength;
				END_IF;           
                    
				// Unbekannte Telegrammnummer
				IF ui_pointer_Data_in = ui_Header_Length AND NOT FB_ConvertHeader.b_Data_Ok THEN
					b_Data_Fail := TRUE;
					ui_pointer_Data_in := 0;     
				END_IF;
                    
				IF ui_pointer_Data_in = ui_Packet_Length AND ui_pointer_Data_in > ui_Header_Length THEN
					IF aby_TempBuffer[ui_pointer_Data_in - 1] = 16#03 THEN
						// Ende Datenstream
						FB_ConvertReceivedata(
							ui_DataLength := ui_Packet_Length
						,i_Telegramm_Nr := FB_ConvertHeader.i_Telegramm_Nr 
						// ,b_Data_Ok => 
						);
						CASE FB_ConvertReceivedata.i_Telegramm_Nr OF
                                
							11: b_Packet_Quit := FB_ConvertHeader.b_Data_Ok AND FB_ConvertReceivedata.b_Data_Ok;
                                
							12: b_Packet_Quit := FB_ConvertHeader.b_Data_Ok AND FB_ConvertReceivedata.b_Data_Ok;
                                
							13: b_Packet_Quit := FB_ConvertHeader.b_Data_Ok AND FB_ConvertReceivedata.b_Data_Ok;
                               
						END_CASE;
						ui_pointer_Data_in := 0 ;
						i_Rec_Versuche := 0;
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

END_FUNCTION_BLOCK
