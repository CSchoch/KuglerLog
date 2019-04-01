FUNCTION_BLOCK Add_Debug_String
	realtime(enable := TRUE, pDTStructure := ADR(ActTime));
	FOR i := ui_Buffer_Size TO 1 BY -1 DO
		Instance.Data.Data[i] := Instance.Data.Data[i - 1];   
	END_FOR;
	Instance.Data.Data[0].e_DataType := E_STRING;
	Instance.Data.Data[0].ui_DataSize := 0;
	Instance.Data.Data[0].tod_Time := DT_TO_TOD(DTStructure_TO_DT(ADR(ActTime))) + UINT_TO_TIME(ActTime.millisec);
	Instance.Data.Data[0].dt_Date := DT_TO_DATE(DTStructure_TO_DT(ADR(ActTime)));
	Instance.Data.Data[0].str_Description := str_Text;      
	Instance.Data.Data[0].i_DataType := -1;            
	Instance.Data.i_SendPointer :=  MIN(Instance.Data.i_SendPointer + 1, UINT_TO_INT(ui_Buffer_Size));
END_FUNCTION_BLOCK