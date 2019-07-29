    
FUNCTION_BLOCK Add_Debug_Data
	realtime(enable := TRUE, pDTStructure := ADR(ActTime));
    Instance.Data.Data[Instance.Data.Index].e_DataType := E_DATA;
	Instance.Data.Data[Instance.Data.Index].ui_DataSize := MIN(ui_DataSize, ui_Data_Length_Pure_Data) ;
	Instance.Data.Data[Instance.Data.Index].tod_Time := DT_TO_TOD(DTStructure_TO_DT(ADR(ActTime))) + UINT_TO_TIME(ActTime.millisec);
	Instance.Data.Data[Instance.Data.Index].dt_Date := DT_TO_DATE(DTStructure_TO_DT(ADR(ActTime)));
	Instance.Data.Data[Instance.Data.Index].str_Description := str_Text;      
	Instance.Data.Data[Instance.Data.Index].i_DataType := i_DataType;            
	Instance.Data.Data[Instance.Data.Index].aby_Data := aby_Data;            
    Instance.Data.Index := (Instance.Data.Index + 1) MOD ui_Buffer_Size;
    Instance.Data.Size :=  MIN(Instance.Data.Size + 1, UINT_TO_INT(ui_Buffer_Size));
END_FUNCTION_BLOCK