    
FUNCTION_BLOCK Add_Debug_Data
	realtime(enable := TRUE, pDTStructure := ADR(ActTime));
	DTStructure_TO_DT(ADR(ActTime));
	FOR i := ui_Buffer_Size TO 1 BY -1 DO
		Instance.Data.Data[i] := Instance.Data.Data[i - 1];   
	END_FOR;
	Instance.Data.Data[0].e_DataType := E_DATA;
	Instance.Data.Data[0].ui_DataSize := MIN(ui_DataSize, ui_Data_Length_Pure_Data) ;
	Instance.Data.Data[0].tod_Time := DT_TO_TOD(DTStructure_TO_DT(ADR(ActTime))) + UINT_TO_TIME(ActTime.millisec);
	Instance.Data.Data[0].dt_Date := DT_TO_DATE(DTStructure_TO_DT(ADR(ActTime)));
	Instance.Data.Data[0].str_Description := str_Text;      
	Instance.Data.Data[0].i_DataType := i_DataType;            
	Instance.Data.Data[0].aby_Data := aby_Data;            
	Instance.Data.i_SendPointer :=  MIN(Instance.Data.i_SendPointer + 1, UINT_TO_INT(ui_Buffer_Size));
END_FUNCTION_BLOCK