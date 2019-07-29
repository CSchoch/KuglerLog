FUNCTION_BLOCK Add_Debug_String
    realtime(enable := TRUE, pDTStructure := ADR(ActTime));
    Instance.Data.Data[Instance.Data.Index].e_DataType := E_STRING;
    Instance.Data.Data[Instance.Data.Index].ui_DataSize := 0;
    Instance.Data.Data[Instance.Data.Index].tod_Time := DT_TO_TOD(DTStructure_TO_DT(ADR(ActTime))) + UINT_TO_TIME(ActTime.millisec);
    Instance.Data.Data[Instance.Data.Index].dt_Date := DT_TO_DATE(DTStructure_TO_DT(ADR(ActTime)));
    Instance.Data.Data[Instance.Data.Index].str_Description := str_Text;      
    Instance.Data.Data[Instance.Data.Index].i_DataType := -1;     
    Instance.Data.Index := (Instance.Data.Index + 1) MOD ui_Buffer_Size;
    Instance.Data.Size :=  MIN(Instance.Data.Size + 1, UINT_TO_INT(ui_Buffer_Size));
END_FUNCTION_BLOCK