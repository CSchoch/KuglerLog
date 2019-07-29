TYPE 
	e_DebugDataType : (E_STRING
		,E_DATA
	);
	
	e_DebugStepSend : (STEP_WAIT_FOR_ACTIVATE,
		STEP_WAIT_FOR_SEND_REQ,
		STEP_WAIT_FOR_ACK
	);
	
	s_SendDataType : STRUCT   
		Data : ARRAY [0..ui_Max_Send_DataSize] OF BYTE;
		ui_Size : UINT;
	END_STRUCT;

	s_DebugDataType : STRUCT 
		e_DataType : e_DebugDataType;
		ui_DataSize : UINT;
		(* *)
		tod_Time : TOD;
		dt_Date : DATE;
		str_Description : STRING[80];
		i_DataType : INT;
		aby_Data : ARRAY[0..ui_Data_Length_Pure_Data] OF BYTE;
    END_STRUCT;
        
	s_DebugDataBufferType : STRUCT
		Data : ARRAY[0..ui_Buffer_Size] OF s_DebugDataType;
        Size : INT := 0;
        Index : INT := 0;
	END_STRUCT;

    s_DebuggingComType : STRUCT
        b_init : BOOL := TRUE; (* Initialisierung *)
        b_Connected : BOOL;
        b_Error : BOOL;
        b_Enable_Com : BOOL := TRUE;
        Data : s_DebugDataBufferType;
        AddString : Add_Debug_String;
        AddData : Add_Debug_Data;
        TempStr : STRING[80];
        TempStr2 : STRING[80];
        Internal : s_DebugIternalType;
    END_STRUCT;
	
  s_DebugIternalType : STRUCT
    Cyclic : CyclicOperations;
  END_STRUCT;
END_TYPE
